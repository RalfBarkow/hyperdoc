#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  tools/repomix-snapshot-manifest.sh create PACK REPOMIX_VERSION CONFIG MANIFEST PART...
  tools/repomix-snapshot-manifest.sh bundle BUNDLE_NAME MANIFEST PACK_MANIFEST...
  tools/repomix-snapshot-manifest.sh verify MANIFEST

Create records and verifies one Repomix pack. A manifest is marked complete only
after every part is present, below its configured split limit, closed at a full
Repomix Markdown boundary, covered by hashes, and complete for required files.
USAGE
}

source_state_fingerprint() {
  local repo_root
  repo_root="$(git rev-parse --show-toplevel)"
  (
    cd "${repo_root}"
    {
      printf '%s\0' 'hyperdoc-repomix-source-state/v1'
      git status --porcelain=v2 -z --untracked-files=all
      printf '\0'
      git ls-files -z --cached --others --exclude-standard -- |
        while IFS= read -r -d '' path; do
          printf '%s\0' "${path}"
          if [[ -f "${path}" || -L "${path}" ]]; then
            printf 'present\0'
            git hash-object --no-filters -- "${path}"
            printf '\0'
          elif [[ -d "${path}" ]]; then
            printf 'directory\0'
          else
            printf 'missing\0'
          fi
        done
    } | git hash-object --stdin
  )
}

sha256_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${path}" | awk '{print $1}'
  else
    shasum -a 256 "${path}" | awk '{print $1}'
  fi
}

byte_count() {
  wc -c < "$1" | tr -d '[:space:]'
}

line_count() {
  wc -l < "$1" | tr -d '[:space:]'
}

file_section_count() {
  awk '/^## File: / { count += 1 } END { print count + 0 }' "$1"
}

complete_markdown_boundary() {
  awk 'NF { line = $0 } END { exit(line ~ /^`{3,}$/ ? 0 : 1) }' "$1"
}

part_contains_file() {
  local part="$1"
  local required="$2"
  grep -Fqx -- "## File: ${required}" "${part}"
}

parts_contain_file() {
  local required="$1"
  shift
  local part
  for part in "$@"; do
    if part_contains_file "${part}" "${required}"; then
      return 0
    fi
  done
  return 1
}

required_files_for_pack() {
  local pack="$1"
  case "${pack}" in
    core)
      printf '%s\n' \
        "AGENTS.md" \
        "README.md" \
        "repomix.config.core.json" \
        "tools/repomix-pack.sh" \
        "tools/repomix-snapshot-manifest.sh" \
        "hyperdoc/Codex handover for HyperDoc.html" \
        "hyperdoc/Best handover to Codex for HyperDoc.html"
      ;;
    roots)
      printf '%s\n' \
        "AGENTS.md" \
        "README.md" \
        ".gitignore" \
        "Makefile" \
        "repomix.config.core.json" \
        "repomix.config.roots.json" \
        "tools/repomix-pack.sh" \
        "tools/repomix-snapshot-manifest.sh" \
        "hyperdoc/Codex handover for HyperDoc.html" \
        "hyperdoc/Best handover to Codex for HyperDoc.html" \
        "hyperbook.asd" \
        "hyperdoc.asd" \
        "hyperdoc-graham-roots-of-lisp.asd" \
        "dev.sh" \
        "flake.nix" \
        "flake.lock" \
        "package.json" \
        "package-lock.json" \
        "nix/roots-of-lisp-lynn-assets.nix" \
        "nix/release/package.nix" \
        "hyperdoc/package.lisp" \
        "hyperdoc/core.lisp" \
        "hyperdoc/defining.lisp" \
        "hyperdoc/check-runner.lisp" \
        "hyperdoc/example-core.lisp" \
        "hyperdoc/example-source-artifacts.lisp" \
        "hyperdoc/topics/registry.lisp" \
        "hyperdoc-explorer/package.lisp" \
        "hyperdoc-explorer/source-surfaces.lisp" \
        "hyperdoc-explorer/explorer.lisp" \
        "hyperdoc-explorer/code-pages.lisp" \
        "hyperdoc-explorer/example-core.lisp" \
        "tests/playwright/playwright.config.js" \
        "tests/playwright/hyperdoc-inspector.js" \
        "tests/playwright/roots-of-lisp-lynn-runner.spec.js"
      git ls-files --cached --others --exclude-standard -- \
        'hyperdoc-graham-roots-of-lisp/**' | LC_ALL=C sort
      ;;
    *)
      printf '%s\n' "AGENTS.md"
      ;;
  esac
}

assert_no_duplicate_file_sections() {
  local duplicates
  duplicates="$({
    local part
    for part in "$@"; do
      awk '/^## File: / { print }' "${part}"
    done
  } | LC_ALL=C sort | uniq -d)"
  if [[ -n "${duplicates}" ]]; then
    echo "Duplicate file sections across generated parts:" >&2
    echo "${duplicates}" >&2
    return 1
  fi
}

create_manifest() {
  if [[ "$#" -lt 5 ]]; then
    usage
    return 2
  fi

  local pack="$1"
  local repomix_version="$2"
  local config="$3"
  local manifest="$4"
  shift 4
  local parts=("$@")
  local repo_root
  repo_root="$(git rev-parse --show-toplevel)"
  cd "${repo_root}"

  if [[ ! -f "${config}" ]]; then
    echo "Missing Repomix config: ${config}" >&2
    return 1
  fi
  if [[ "${#parts[@]}" -eq 0 ]]; then
    echo "No generated Repomix parts supplied." >&2
    return 1
  fi

  local configured_output configured_limit config_path config_sha head status_json
  local source_state_schema source_state_fingerprint_value
  configured_output="$(jq -er '.output.filePath' "${config}")"
  configured_limit="$(jq -er '.output.splitOutput // 0' "${config}")"
  config_path="$(python_path_relative_to_repo "${config}" "${repo_root}")"
  config_sha="$(sha256_file "${config}")"
  head="$(git rev-parse HEAD)"
  status_json="$(git status --short --untracked-files=all | jq -R -s 'split("\n") | map(select(length > 0))')"
  source_state_schema='hyperdoc-repomix-source-state/v1'
  source_state_fingerprint_value="$(source_state_fingerprint)"

  local parts_json='[]'
  local part part_path bytes lines sha sections boundary
  for part in "${parts[@]}"; do
    if [[ ! -f "${part}" ]]; then
      echo "Missing generated part: ${part}" >&2
      return 1
    fi
    bytes="$(byte_count "${part}")"
    lines="$(line_count "${part}")"
    sha="$(sha256_file "${part}")"
    sections="$(file_section_count "${part}")"
    if complete_markdown_boundary "${part}"; then
      boundary=true
    else
      echo "Incomplete Repomix Markdown boundary: ${part}" >&2
      return 1
    fi
    if (( configured_limit > 0 && bytes > configured_limit )); then
      echo "Generated part exceeds configured split limit: ${part} (${bytes} > ${configured_limit})" >&2
      return 1
    fi
    if (( sections == 0 )); then
      echo "Generated part has no file sections: ${part}" >&2
      return 1
    fi
    part_path="$(python_path_relative_to_repo "${part}" "${repo_root}")"
    parts_json="$(jq -cn \
      --argjson parts "${parts_json}" \
      --arg path "${part_path}" \
      --argjson bytes "${bytes}" \
      --argjson lines "${lines}" \
      --arg sha256 "${sha}" \
      --argjson file_sections "${sections}" \
      --argjson complete_boundary "${boundary}" \
      '$parts + [{path: $path, bytes: $bytes, lines: $lines, sha256: $sha256, file_sections: $file_sections, complete_repomix_boundary: $complete_boundary}]')"
  done

  assert_no_duplicate_file_sections "${parts[@]}"

  if [[ "${pack}" != "dm6" ]] && parts_contain_file "assets/dm6-elm/app.js" "${parts[@]}"; then
    echo "Generated DM6 app bundle leaked into non-DM6 pack: ${pack}" >&2
    return 1
  fi

  local required_json='[]'
  local required found
  while IFS= read -r required; do
    [[ -n "${required}" ]] || continue
    if parts_contain_file "${required}" "${parts[@]}"; then
      found=true
    else
      found=false
    fi
    required_json="$(jq -cn \
      --argjson required_files "${required_json}" \
      --arg path "${required}" \
      --argjson found "${found}" \
      '$required_files + [{path: $path, found: $found}]')"
    if [[ "${found}" != true ]]; then
      echo "Required file is absent from generated parts: ${required}" >&2
      return 1
    fi
  done < <(required_files_for_pack "${pack}")

  local temporary_manifest
  temporary_manifest="$(mktemp "${manifest}.incomplete.XXXXXX")"
  trap 'rm -f "${temporary_manifest}"' RETURN
  jq -n \
    --arg schema "hyperdoc-repomix-snapshot-manifest/v1" \
    --arg pack_name "${pack}" \
    --arg repomix_version "${repomix_version}" \
    --arg generated_at_utc "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    --arg head "${head}" \
    --argjson git_status_short "${status_json}" \
    --arg source_state_schema "${source_state_schema}" \
    --arg source_state_fingerprint "${source_state_fingerprint_value}" \
    --arg config_path "${config_path}" \
    --arg config_sha256 "${config_sha}" \
    --arg configured_output "${configured_output}" \
    --argjson configured_part_limit_bytes "${configured_limit}" \
    --argjson observed_delivery_boundary_bytes 741376 \
    --argjson parts "${parts_json}" \
    --argjson required_files "${required_json}" \
    '{
      schema: $schema,
      pack_name: $pack_name,
      repomix_version: $repomix_version,
      generated_at_utc: $generated_at_utc,
      repository: {
        head: $head,
        git_status_short: $git_status_short,
        source_state: {
          schema: $source_state_schema,
          fingerprint: $source_state_fingerprint
        }
      },
      configuration: {
        path: $config_path,
        sha256: $config_sha256,
        output_path: $configured_output,
        split_limit_bytes: $configured_part_limit_bytes,
        observed_delivery_boundary_bytes: $observed_delivery_boundary_bytes
      },
      parts: $parts,
      required_files: $required_files,
      checks: {
        all_parts_present: true,
        hashes_recorded: true,
        required_file_coverage: true,
        complete_repomix_boundaries: true,
        part_sizes_within_limit: true,
        duplicate_file_sections: false,
        forbidden_dm6_app_absent: ($pack_name != "dm6")
      },
      completion_status: "complete"
    }' > "${temporary_manifest}"
  jq -e '.completion_status == "complete"' "${temporary_manifest}" >/dev/null
  mv "${temporary_manifest}" "${manifest}"
  trap - RETURN
  echo "Wrote complete snapshot manifest: ${manifest}"
}

python_path_relative_to_repo() {
  local path="$1"
  local repo_root="$2"
  case "${path}" in
    "${repo_root}"/*)
      printf '%s\n' "${path#"${repo_root}"/}"
      ;;
    *)
      printf '%s\n' "${path}"
      ;;
  esac
}

create_bundle_manifest() {
  if [[ "$#" -lt 4 ]]; then
    usage
    return 2
  fi

  local bundle_name="$1"
  local manifest="$2"
  shift 2
  local pack_manifests=("$@")
  local repo_root
  repo_root="$(git rev-parse --show-toplevel)"
  cd "${repo_root}"

  local packs_json='[]'
  local pack_manifest pack_manifest_path pack_manifest_sha pack_json
  for pack_manifest in "${pack_manifests[@]}"; do
    verify_manifest "${pack_manifest}"
    jq -e '.schema == "hyperdoc-repomix-snapshot-manifest/v1"' \
      "${pack_manifest}" >/dev/null
    pack_manifest_path="$(python_path_relative_to_repo "${pack_manifest}" "${repo_root}")"
    pack_manifest_sha="$(sha256_file "${pack_manifest}")"
    pack_json="$(jq -c \
      --arg manifest_path "${pack_manifest_path}" \
      --arg manifest_sha256 "${pack_manifest_sha}" \
      '{
        pack_name,
        repomix_version,
        repository,
        configuration,
        manifest: {
          path: $manifest_path,
          sha256: $manifest_sha256
        },
        parts,
        required_files
      }' "${pack_manifest}")"
    packs_json="$(jq -cn \
      --argjson packs "${packs_json}" \
      --argjson pack "${pack_json}" \
      '$packs + [$pack]')"
  done

  local repository_count version_count
  repository_count="$(jq '[.[].repository] | unique | length' <<< "${packs_json}")"
  version_count="$(jq '[.[].repomix_version] | unique | length' <<< "${packs_json}")"
  if [[ "${repository_count}" != 1 ]]; then
    echo "Pack manifests do not describe one repository state." >&2
    return 1
  fi
  if [[ "${version_count}" != 1 ]]; then
    echo "Pack manifests do not use one Repomix version." >&2
    return 1
  fi

  local temporary_manifest
  temporary_manifest="$(mktemp "${manifest}.incomplete.XXXXXX")"
  trap 'rm -f "${temporary_manifest}"' RETURN
  jq -n \
    --arg schema "hyperdoc-repomix-snapshot-bundle-manifest/v1" \
    --arg bundle_name "${bundle_name}" \
    --arg generated_at_utc "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    --argjson packs "${packs_json}" \
    '{
      schema: $schema,
      bundle_name: $bundle_name,
      pack_name: ([ $packs[].pack_name ] | join("+")),
      repomix_version: $packs[0].repomix_version,
      generated_at_utc: $generated_at_utc,
      repository: $packs[0].repository,
      configurations: [
        $packs[] |
        .configuration + {pack_name: .pack_name}
      ],
      pack_manifests: [
        $packs[] |
        .manifest + {pack_name: .pack_name}
      ],
      parts: [
        $packs[] as $pack |
        $pack.parts[] + {pack_name: $pack.pack_name}
      ],
      required_files: [
        $packs[] as $pack |
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
    }' > "${temporary_manifest}"
  jq -e '.completion_status == "complete"' "${temporary_manifest}" >/dev/null
  mv "${temporary_manifest}" "${manifest}"
  trap - RETURN
  echo "Wrote complete handover bundle manifest: ${manifest}"
}

verify_bundle_manifest() {
  local manifest="$1"
  jq -e '
    .schema == "hyperdoc-repomix-snapshot-bundle-manifest/v1" and
    .completion_status == "complete" and
    .checks.all_pack_manifests_present == true and
    .checks.pack_manifest_hashes_match == true and
    .checks.all_parts_present == true and
    .checks.part_hashes_match == true and
    .checks.required_file_coverage == true and
    .checks.complete_repomix_boundaries == true and
    .checks.part_sizes_within_limits == true
  ' "${manifest}" >/dev/null

  local child_json child_path child_sha packs_json='[]' pack_json
  while IFS= read -r child_json; do
    child_path="$(jq -r '.path' <<< "${child_json}")"
    child_sha="$(jq -r '.sha256' <<< "${child_json}")"
    [[ -f "${child_path}" ]]
    [[ "$(sha256_file "${child_path}")" == "${child_sha}" ]]
    verify_manifest "${child_path}"
    pack_json="$(jq -c '{pack_name, parts, required_files}' "${child_path}")"
    packs_json="$(jq -cn \
      --argjson packs "${packs_json}" \
      --argjson pack "${pack_json}" \
      '$packs + [$pack]')"
  done < <(jq -c '.pack_manifests[]' "${manifest}")

  local expected_parts actual_parts expected_required actual_required
  expected_parts="$(jq -Sc '[.[] as $pack | $pack.parts[] + {pack_name: $pack.pack_name}]' <<< "${packs_json}")"
  actual_parts="$(jq -Sc '.parts' "${manifest}")"
  expected_required="$(jq -Sc '[.[] as $pack | $pack.required_files[] + {pack_name: $pack.pack_name}]' <<< "${packs_json}")"
  actual_required="$(jq -Sc '.required_files' "${manifest}")"
  [[ "${actual_parts}" == "${expected_parts}" ]]
  [[ "${actual_required}" == "${expected_required}" ]]
  echo "Snapshot bundle manifest valid: ${manifest}"
}

verify_manifest() {
  if [[ "$#" -ne 1 ]]; then
    usage
    return 2
  fi

  local manifest="$1"
  local schema
  schema="$(jq -er '.schema' "${manifest}")"
  if [[ "${schema}" == "hyperdoc-repomix-snapshot-bundle-manifest/v1" ]]; then
    verify_bundle_manifest "${manifest}"
    return
  fi
  jq -e '.schema == "hyperdoc-repomix-snapshot-manifest/v1" and .completion_status == "complete"' \
    "${manifest}" >/dev/null

  local repo_root pack config config_sha configured_limit manifest_head current_head
  repo_root="$(git rev-parse --show-toplevel)"
  cd "${repo_root}"
  pack="$(jq -er '.pack_name' "${manifest}")"
  config="$(jq -er '.configuration.path' "${manifest}")"
  config_sha="$(jq -er '.configuration.sha256' "${manifest}")"
  configured_limit="$(jq -er '.configuration.split_limit_bytes' "${manifest}")"
  manifest_head="$(jq -er '.repository.head' "${manifest}")"
  current_head="$(git rev-parse HEAD)"

  [[ -f "${config}" ]]
  [[ "$(sha256_file "${config}")" == "${config_sha}" ]]
  [[ "${current_head}" == "${manifest_head}" ]]

  local recorded_status current_status recorded_source_state_schema
  local recorded_source_state_fingerprint current_source_state_fingerprint
  recorded_status="$(jq -c '.repository.git_status_short' "${manifest}")"
  current_status="$(git status --short --untracked-files=all | jq -R -s -c 'split("\n") | map(select(length > 0))')"
  [[ "${current_status}" == "${recorded_status}" ]]
  recorded_source_state_schema="$(jq -er '.repository.source_state.schema' "${manifest}")"
  [[ "${recorded_source_state_schema}" == "hyperdoc-repomix-source-state/v1" ]]
  recorded_source_state_fingerprint="$(jq -er '.repository.source_state.fingerprint' "${manifest}")"
  current_source_state_fingerprint="$(source_state_fingerprint)"
  [[ "${current_source_state_fingerprint}" == "${recorded_source_state_fingerprint}" ]]

  local parts=()
  local part_path
  while IFS= read -r part_path; do
    parts+=("${part_path}")
  done < <(jq -r '.parts[].path' "${manifest}")
  (( ${#parts[@]} > 0 ))

  local index=0 part_json expected_bytes expected_lines expected_sha expected_sections
  while IFS= read -r part_json; do
    part_path="${parts[${index}]}"
    [[ -f "${part_path}" ]]
    expected_bytes="$(jq -r '.bytes' <<< "${part_json}")"
    expected_lines="$(jq -r '.lines' <<< "${part_json}")"
    expected_sha="$(jq -r '.sha256' <<< "${part_json}")"
    expected_sections="$(jq -r '.file_sections' <<< "${part_json}")"
    [[ "$(byte_count "${part_path}")" == "${expected_bytes}" ]]
    [[ "$(line_count "${part_path}")" == "${expected_lines}" ]]
    [[ "$(sha256_file "${part_path}")" == "${expected_sha}" ]]
    [[ "$(file_section_count "${part_path}")" == "${expected_sections}" ]]
    complete_markdown_boundary "${part_path}"
    if (( configured_limit > 0 )); then
      (( expected_bytes <= configured_limit ))
    fi
    index=$((index + 1))
  done < <(jq -c '.parts[]' "${manifest}")

  assert_no_duplicate_file_sections "${parts[@]}"
  if [[ "${pack}" != "dm6" ]] && parts_contain_file "assets/dm6-elm/app.js" "${parts[@]}"; then
    echo "Generated DM6 app bundle leaked into non-DM6 pack: ${pack}" >&2
    return 1
  fi

  local required manifest_found actual_found
  while IFS=$'\t' read -r required manifest_found; do
    if parts_contain_file "${required}" "${parts[@]}"; then
      actual_found=true
    else
      actual_found=false
    fi
    [[ "${manifest_found}" == true ]]
    [[ "${actual_found}" == true ]]
  done < <(jq -r '.required_files[] | [.path, (.found | tostring)] | @tsv' "${manifest}")

  jq -e '
    .checks.all_parts_present == true and
    .checks.hashes_recorded == true and
    .checks.required_file_coverage == true and
    .checks.complete_repomix_boundaries == true and
    .checks.part_sizes_within_limit == true and
    .checks.duplicate_file_sections == false
  ' "${manifest}" >/dev/null
  echo "Snapshot manifest valid: ${manifest}"
}

command="${1:-}"
case "${command}" in
  create)
    shift
    create_manifest "$@"
    ;;
  bundle)
    shift
    create_bundle_manifest "$@"
    ;;
  verify)
    shift
    verify_manifest "$@"
    ;;
  ""|-h|--help)
    usage
    ;;
  *)
    echo "Unknown command: ${command}" >&2
    usage
    exit 2
    ;;
esac
