#!/usr/bin/env bash
set -u

usage() {
  cat <<'USAGE'
Usage:
  tools/validate-documentation-slice.sh \
    --page <hyperdoc-page-path> \
    [--topic <topic-function-name> ...] \
    [--fedwiki <fedwiki-page-file> ...]

Examples:
  tools/validate-documentation-slice.sh \
    --page "hyperdoc/Documentation Architecture in HyperDoc.html" \
    --topic documentation-architecture-in-hyperdoc-topic \
    --topic documentation-cluster-reading-order-topic \
    --topic documentation-governance-topic

  tools/validate-documentation-slice.sh \
    --page "hyperdoc/Documentation Architecture in HyperDoc.html" \
    --fedwiki /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/documentation-architecture-in-hyperdoc
USAGE
}

page=""
declare -a topics
declare -a fedwiki_pages

while [[ $# -gt 0 ]]; do
  case "$1" in
    --page)
      page="${2:-}"
      shift 2
      ;;
    --topic)
      topics+=("${2:-}")
      shift 2
      ;;
    --fedwiki)
      fedwiki_pages+=("${2:-}")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$page" ]]; then
  echo "Missing required --page argument" >&2
  usage >&2
  exit 2
fi

if [[ ! -f "$page" ]]; then
  echo "HyperDoc page not found: $page" >&2
  exit 2
fi

passes=0
fails=0
skips=0

if command -v sbcl >/dev/null 2>&1; then
  SBCL_CMD=(sbcl)
elif command -v nix >/dev/null 2>&1; then
  SBCL_CMD=(nix develop --command sbcl)
else
  echo "Missing sbcl (or nix fallback) for Lisp checks." >&2
  exit 2
fi

pass() {
  echo "PASS  $1"
  passes=$((passes + 1))
}

fail() {
  echo "FAIL  $1"
  fails=$((fails + 1))
}

skip() {
  echo "SKIP  $1"
  skips=$((skips + 1))
}

# 1) asdf load gate
if "${SBCL_CMD[@]}" --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system :hyperdoc)' \
  --quit >/tmp/doc-slice-asdf.log 2>&1; then
  pass "asdf:load-system :hyperdoc"
else
  fail "asdf:load-system :hyperdoc"
  sed -n '1,120p' /tmp/doc-slice-asdf.log
fi

# 2) fboundp topic gate
if [[ ${#topics[@]} -eq 0 ]]; then
  skip "topic fboundp checks (no --topic provided)"
else
  for topic in "${topics[@]}"; do
    if [[ "$topic" == *::* ]]; then
      symbol="$topic"
    else
      symbol="hyperdoc::$topic"
    fi

    if "${SBCL_CMD[@]}" --no-userinit --non-interactive \
      --eval '(require :asdf)' \
      --eval '(asdf:load-system :hyperdoc)' \
      --eval "(uiop:quit (if (fboundp '$symbol) 0 1))" \
      --quit >/tmp/doc-slice-topic.log 2>&1; then
      pass "fboundp $symbol"
    else
      fail "fboundp $symbol"
      sed -n '1,80p' /tmp/doc-slice-topic.log
    fi
  done
fi

# 3) topic coverage gate for one page
if "${SBCL_CMD[@]}" --no-userinit --non-interactive \
  --load tools/check-topic-coverage.lisp -- "$page" \
  >/tmp/doc-slice-coverage.log 2>&1; then
  pass "topic coverage $page"
else
  fail "topic coverage $page"
  sed -n '1,160p' /tmp/doc-slice-coverage.log
fi

# 4) FedWiki json syntax gate
if [[ ${#fedwiki_pages[@]} -eq 0 ]]; then
  skip "FedWiki json.tool checks (no --fedwiki provided)"
else
  for fedwiki_page in "${fedwiki_pages[@]}"; do
    if python3 -m json.tool "$fedwiki_page" >/tmp/doc-slice-json-tool.out 2>/tmp/doc-slice-json-tool.err; then
      pass "json.tool $fedwiki_page"
    else
      fail "json.tool $fedwiki_page"
      sed -n '1,80p' /tmp/doc-slice-json-tool.err
    fi
  done
fi

echo "----"
echo "SUMMARY passes=$passes fails=$fails skips=$skips"

if [[ $fails -eq 0 ]]; then
  echo "DOC_SLICE_VALIDATION_OK"
  exit 0
else
  echo "DOC_SLICE_VALIDATION_FAIL"
  exit 1
fi
