#!/usr/bin/env bash
set -euo pipefail

FULL_GATE_SYSTEM="${HYPERDOC_PRE_COMMIT_FULL_GATE_SYSTEM:-:hyperbook/server}"
DRY_RUN="${HYPERDOC_PRE_COMMIT_GATE_DRY_RUN:-0}"

declare -a STAGED_STATUSES=()
declare -a STAGED_PATHS=()
declare -a STATIC_HTML_PATHS=()
declare -a FULL_GATE_REASONS=()

add_full_gate_reason() {
  FULL_GATE_REASONS+=("$1")
}

read_staged_paths() {
  local status
  local path
  local old_path

  while IFS= read -r -d '' status; do
    case "$status" in
      R*|C*)
        IFS= read -r -d '' old_path
        IFS= read -r -d '' path
        ;;
      *)
        IFS= read -r -d '' path
        ;;
    esac
    STAGED_STATUSES+=("${status:0:1}")
    STAGED_PATHS+=("$path")
  done < <(git diff --cached --name-status -z)
}

is_direct_hyperdoc_html_page() {
  local path="$1"
  [[ "$path" == hyperdoc/*.html && "$path" != hyperdoc/*/* ]]
}

is_static_html_status() {
  local status="$1"
  [[ "$status" == "A" || "$status" == "M" ]]
}

path_forces_full_gate() {
  local path="$1"

  case "$path" in
    *.lisp|*.asd|*.sexp|*.cl|*.nix|flake.nix|flake.lock|Makefile|makefile)
      return 0
      ;;
    dev.sh|start.sh)
      return 0
      ;;
    nix/*|tests/*|hyperbook-server/*|hyperdoc-inspector/*|hyperdoc-explorer/*)
      return 0
      ;;
    hyperbook-explorer/*|hyperbook-fedwiki/*|hyperbook-wikipedia/*)
      return 0
      ;;
    tools/check-*|tools/validate-*|tools/pre-commit-gate.sh)
      return 0
      ;;
    tools/journal-gate.lisp|tools/save-hyperdoc-standalone.lisp)
      return 0
      ;;
    assets/*)
      return 0
      ;;
  esac

  return 1
}

html_has_executable_or_runtime_marker() {
  local path="$1"

  grep -Eiq \
    'expr=|<html-expr|<html-generator|<view-transclusion|<source-of-function|<source-of-class|<lisp-code|<script|javascript:|asdf:load-system|load-system|defsystem' \
    -- "$path"
}

classify_staged_paths() {
  local index
  local status
  local path
  local html_only=1

  if [ "${#STAGED_PATHS[@]}" -eq 0 ]; then
    echo "[pre-commit-gate] no staged files"
    return 2
  fi

  for index in "${!STAGED_PATHS[@]}"; do
    status="${STAGED_STATUSES[$index]}"
    path="${STAGED_PATHS[$index]}"

    if path_forces_full_gate "$path"; then
      add_full_gate_reason "$path: full-gate path"
      html_only=0
      continue
    fi

    if is_direct_hyperdoc_html_page "$path" && is_static_html_status "$status"; then
      STATIC_HTML_PATHS+=("$path")
      continue
    fi

    add_full_gate_reason "$path: outside static HyperDoc HTML page-only gate"
    html_only=0
  done

  if [ "$html_only" -eq 1 ] && [ "${#STATIC_HTML_PATHS[@]}" -gt 0 ]; then
    for path in "${STATIC_HTML_PATHS[@]}"; do
      if html_has_executable_or_runtime_marker "$path"; then
        add_full_gate_reason "$path: executable/runtime HyperDoc marker"
        return 1
      fi
    done
    return 0
  fi

  return 1
}

print_full_gate_reasons() {
  local reason

  for reason in "${FULL_GATE_REASONS[@]}"; do
    echo "[pre-commit-gate] full gate: $reason"
  done
}

run_static_html_gate() {
  echo "[pre-commit-gate] selected light static HyperDoc HTML page gate"
  tools/check-hyperdoc-html-page-gate.py "${STATIC_HTML_PATHS[@]}"
  git diff --cached --check
  git status --short
  echo "[pre-commit-gate] static HyperDoc HTML gate passed"
}

run_full_gate() {
  echo "[pre-commit-gate] selected full Lisp/Nix/server load gate"
  print_full_gate_reasons
  tools/check-lisp-load-gate.sh "$FULL_GATE_SYSTEM"
  echo "[pre-commit-gate] Lisp shape/load gate passed"
}

main() {
  local classification

  tools/check-lisp-parens.sh
  read_staged_paths

  if classify_staged_paths; then
    classification="static-html"
  else
    case "$?" in
      2)
        classification="empty"
        ;;
      *)
        classification="full"
        ;;
    esac
  fi

  case "$classification" in
    empty)
      exit 0
      ;;
    static-html)
      if [ "$DRY_RUN" = "1" ]; then
        echo "[pre-commit-gate] dry-run selected light static HyperDoc HTML page gate"
        printf '[pre-commit-gate] static page: %s\n' "${STATIC_HTML_PATHS[@]}"
        exit 0
      fi
      run_static_html_gate
      ;;
    full)
      if [ "$DRY_RUN" = "1" ]; then
        echo "[pre-commit-gate] dry-run selected full Lisp/Nix/server load gate"
        print_full_gate_reasons
        exit 0
      fi
      run_full_gate
      ;;
  esac
}

main "$@"
