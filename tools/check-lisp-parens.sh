#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"

files=()

while IFS= read -r -d '' file; do
  files+=("$file")
done < <(
  git diff --name-only --cached -z -- \
    '*.lisp' '*.asd' '*.sexp' '*.cl'
)

if [ "${#files[@]}" -eq 0 ]; then
  echo "[check-lisp-parens] no staged Lisp files"
  exit 0
fi

client="${EMACSCLIENT:-emacsclient}"
emacs="${EMACS:-emacs}"

emacsclient_args=()

if [ -n "${EMACS_SERVER_FILE:-}" ]; then
  emacsclient_args+=(--server-file="$EMACS_SERVER_FILE")
elif [ -n "${EMACS_SOCKET_NAME:-}" ]; then
  emacsclient_args+=(--socket-name="$EMACS_SOCKET_NAME")
elif [ "$(uname -s)" = "Darwin" ]; then
  darwin_tmp="$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || true)"

  if [ -n "$darwin_tmp" ]; then
    emacs_socket="${darwin_tmp}emacs$(id -u)/server"
    emacsclient_args+=(--socket-name="$emacs_socket")
  fi
fi

emacsclient_ready=false

if command -v "$client" >/dev/null 2>&1 &&
   "$client" "${emacsclient_args[@]}" \
     --eval '(emacs-pid)' >/dev/null 2>&1
then
  emacsclient_ready=true
else
  echo "[check-lisp-parens] no reachable Emacs server; using batch Emacs"
fi

elisp_string() {
  local value="$1"

  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"

  printf '"%s"' "$value"
}

check_with_emacsclient() {
  local file="$1"
  local absolute_file="$repo_root/$file"
  local quoted_file
  local form

  quoted_file="$(elisp_string "$absolute_file")"

  form="
(let ((file $quoted_file))
  (with-temp-buffer
    (insert-file-contents file)
    (set-visited-file-name file)
    (lisp-mode)
    (check-parens)
    (message \"balanced: %s\" file)))
"

  "$client" "${emacsclient_args[@]}" \
    --eval "$form" >/dev/null
}

check_with_batch_emacs() {
  local file="$1"
  local absolute_file="$repo_root/$file"

  "$emacs" -Q --batch "$absolute_file" \
    --eval '(progn
              (lisp-mode)
              (check-parens)
              (message "balanced: %s" buffer-file-name))'
}

for file in "${files[@]}"; do
  if [ ! -f "$file" ]; then
    continue
  fi

  echo "[check-lisp-parens] $file"

  if [ "$emacsclient_ready" = true ]; then
    check_with_emacsclient "$file"
    echo "[check-lisp-parens] checked via emacsclient: $file"
  else
    check_with_batch_emacs "$file"
  fi
done
