#!/usr/bin/env bash
set -euo pipefail

repository="$(git rev-parse --show-toplevel)"
manifest_script="${repository}/tools/repomix-snapshot-manifest.sh"
source_state_schema='hyperdoc-repomix-source-state/v1'
temporary_root="${TMPDIR:-/tmp}"
fixture="$(mktemp -d "${temporary_root%/}/hyperdoc-repomix-source-state.XXXXXX")"
fixture_parent="${temporary_root%/}"
wrapper=''

cleanup() {
  if [[ -n "${fixture:-}" && "${fixture}" == "${fixture_parent}/hyperdoc-repomix-source-state."* ]]; then
    rm -rf -- "${fixture}"
  else
    echo "Refusing to remove unexpected fixture path: ${fixture:-<empty>}" >&2
    return 1
  fi
}
trap cleanup EXIT

fail() {
  echo "not ok - $*" >&2
  exit 1
}

pass() {
  echo "ok - $*"
}

run_fixture_command() {
  (
    cd "${fixture}"
    REPOMIX_MANIFEST_SCRIPT="${manifest_script}" \
      bash "${wrapper}" "$@"
  )
}

expect_success() {
  local description="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    pass "${description}"
  else
    fail "${description}"
  fi
}

expect_failure() {
  local description="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    fail "${description}"
  else
    pass "${description}"
  fi
}

git -C "${fixture}" init --quiet
git -C "${fixture}" config user.name "HyperDoc source-state regression"
git -C "${fixture}" config user.email "source-state-regression@example.invalid"
git -C "${fixture}" config commit.gpgsign false
git -C "${fixture}" config core.autocrlf false

cat > "${fixture}/.gitignore" <<'EOF'
.fixture/
.ignored/
EOF

printf '%s\n' 'committed source' > "${fixture}/tracked.txt"
git -C "${fixture}" add -- .gitignore tracked.txt
git -C "${fixture}" commit --quiet --no-verify --no-gpg-sign -m "fixture baseline"

printf '%s\n' 'first dirty source state' > "${fixture}/tracked.txt"
mkdir -p "${fixture}/.fixture"
wrapper="${fixture}/.fixture/run-manifest-function.sh"

cat > "${wrapper}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

mode="$1"
shift

# Load the production functions without executing a mutation command.
# shellcheck source=/dev/null
source "${REPOMIX_MANIFEST_SCRIPT:?}" --help 2>/dev/null

# The regression isolates repository source-state behavior. Existing
# Repomix-part validation has its own production coverage.
required_files_for_pack() { return 0; }
complete_markdown_boundary() { return 0; }
file_section_count() { printf '%s\n' 1; }
assert_no_duplicate_file_sections() { return 0; }
parts_contain_file() { return 1; }

case "${mode}" in
  create)
    create_manifest "$@"
    ;;
  verify)
    verify_manifest "$@"
    ;;
  sha256)
    sha256_file "$@"
    ;;
  *)
    echo "Unknown fixture wrapper mode: ${mode}" >&2
    exit 2
    ;;
esac
EOF

config="${fixture}/.fixture/config.json"
part="${fixture}/.fixture/part.md"
manifest="${fixture}/.fixture/pack.manifest.json"
bundle="${fixture}/.fixture/bundle.manifest.json"

cat > "${config}" <<'EOF'
{
  "output": {
    "filePath": ".fixture/part.md",
    "splitOutput": 0
  }
}
EOF

cat > "${part}" <<'EOF'
# Repomix fixture

## File: tracked.txt

```text
fixture
```
EOF

run_fixture_command create fixture test-version "${config}" "${manifest}" "${part}" \
  >/dev/null

[[ "$(jq -r '.repository.source_state.schema' "${manifest}")" == "${source_state_schema}" ]] \
  || fail "manifest records source-state schema"
[[ "$(jq -r '.repository.source_state.fingerprint | length' "${manifest}")" -gt 0 ]] \
  || fail "manifest records source-state fingerprint"
pass "manifest records source-state schema and fingerprint"

expect_success \
  "unchanged state verifies" \
  run_fixture_command verify "${manifest}"

tracked_status_before="$(git -C "${fixture}" status --short --untracked-files=all)"
printf '%s\n' 'second dirty source state' > "${fixture}/tracked.txt"
tracked_status_after="$(git -C "${fixture}" status --short --untracked-files=all)"
[[ "${tracked_status_before}" == "${tracked_status_after}" ]] \
  || fail "tracked status remains unchanged"
expect_failure \
  "tracked content change with status still M is rejected" \
  run_fixture_command verify "${manifest}"

printf '%s\n' 'first dirty source state' > "${fixture}/tracked.txt"
expect_success \
  "restored tracked content verifies" \
  run_fixture_command verify "${manifest}"


# Isolate an index-only content change. The worktree bytes and the
# short status remain unchanged while the staged blob changes.
printf '%s\n' 'first staged index state' > "${fixture}/tracked.txt"
git -C "${fixture}" add -- tracked.txt
printf '%s\n' 'shared staged worktree state' > "${fixture}/tracked.txt"

run_fixture_command create fixture test-version "${config}" "${manifest}" "${part}" \
  >/dev/null

expect_success \
  "unchanged staged state verifies" \
  run_fixture_command verify "${manifest}"

staged_status_before="$(
  git -C "${fixture}" status --short --untracked-files=all
)"
staged_index_hash_before="$(
  git -C "${fixture}" rev-parse :tracked.txt
)"
staged_worktree_hash_before="$(
  git -C "${fixture}" hash-object --no-filters -- tracked.txt
)"

printf '%s\n' 'second staged index state' > "${fixture}/tracked.txt"
git -C "${fixture}" add -- tracked.txt
printf '%s\n' 'shared staged worktree state' > "${fixture}/tracked.txt"

staged_status_after="$(
  git -C "${fixture}" status --short --untracked-files=all
)"
staged_index_hash_after="$(
  git -C "${fixture}" rev-parse :tracked.txt
)"
staged_worktree_hash_after="$(
  git -C "${fixture}" hash-object --no-filters -- tracked.txt
)"

[[ "${staged_status_before}" == "${staged_status_after}" ]] \
  || fail "staged status remains unchanged"
[[ "${staged_index_hash_before}" != "${staged_index_hash_after}" ]] \
  || fail "staged index content changes"
[[ "${staged_worktree_hash_before}" == "${staged_worktree_hash_after}" ]] \
  || fail "staged worktree content remains unchanged"

expect_failure \
  "staged content change with status and worktree unchanged is rejected" \
  run_fixture_command verify "${manifest}"

printf '%s\n' 'first staged index state' > "${fixture}/tracked.txt"
git -C "${fixture}" add -- tracked.txt
printf '%s\n' 'shared staged worktree state' > "${fixture}/tracked.txt"

expect_success \
  "restored staged index content verifies" \
  run_fixture_command verify "${manifest}"

# Return to the earlier unstaged tracked-file state.
git -C "${fixture}" reset --quiet HEAD -- tracked.txt
printf '%s\n' 'first dirty source state' > "${fixture}/tracked.txt"

printf '%s\n' 'first untracked source state' > "${fixture}/untracked.txt"
run_fixture_command create fixture test-version "${config}" "${manifest}" "${part}" \
  >/dev/null
expect_success \
  "unchanged state with untracked file verifies" \
  run_fixture_command verify "${manifest}"

untracked_status_before="$(git -C "${fixture}" status --short --untracked-files=all)"
printf '%s\n' 'second untracked source state' > "${fixture}/untracked.txt"
untracked_status_after="$(git -C "${fixture}" status --short --untracked-files=all)"
[[ "${untracked_status_before}" == "${untracked_status_after}" ]] \
  || fail "untracked status remains unchanged"
expect_failure \
  "untracked content change with status still ?? is rejected" \
  run_fixture_command verify "${manifest}"

printf '%s\n' 'first untracked source state' > "${fixture}/untracked.txt"
expect_success \
  "restored untracked content verifies" \
  run_fixture_command verify "${manifest}"

mkdir -p "${fixture}/.ignored"
printf '%s\n' 'first ignored state' > "${fixture}/.ignored/ignored.txt"
expect_success \
  "created ignored content is excluded" \
  run_fixture_command verify "${manifest}"
printf '%s\n' 'second ignored state' > "${fixture}/.ignored/ignored.txt"
expect_success \
  "edited ignored content is excluded" \
  run_fixture_command verify "${manifest}"

child_sha="$(run_fixture_command sha256 "${manifest}")"
jq -n \
  --arg child_path "${manifest}" \
  --arg child_sha "${child_sha}" \
  --slurpfile child "${manifest}" \
  '{
    schema: "hyperdoc-repomix-snapshot-bundle-manifest/v1",
    pack_manifests: [{
      path: $child_path,
      sha256: $child_sha
    }],
    parts: [
      $child[0] as $pack |
      $pack.parts[] + {pack_name: $pack.pack_name}
    ],
    required_files: [
      $child[0] as $pack |
      $pack.required_files[] + {pack_name: $pack.pack_name}
    ],
    checks: {
      all_pack_manifests_present: true,
      pack_manifest_hashes_match: true,
      all_parts_present: true,
      part_hashes_match: true,
      required_file_coverage: true,
      complete_repomix_boundaries: true,
      part_sizes_within_limits: true
    },
    completion_status: "complete"
  }' > "${bundle}"

expect_success \
  "bundle with current child manifest verifies" \
  run_fixture_command verify "${bundle}"

printf '%s\n' 'third dirty source state' > "${fixture}/tracked.txt"
expect_failure \
  "bundle rejects recursively stale child manifest" \
  run_fixture_command verify "${bundle}"

printf '%s\n' 'first dirty source state' > "${fixture}/tracked.txt"
expect_success \
  "bundle verifies after source state is restored" \
  run_fixture_command verify "${bundle}"

cleanup
trap - EXIT
[[ ! -e "${fixture}" ]] || fail "isolated fixture cleaned up"
pass "isolated fixture cleaned up"
pass "repomix source-state fingerprint regression"
