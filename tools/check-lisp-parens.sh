#!/usr/bin/env bash
set -euo pipefail

files="$(
  git diff --name-only --cached -- \
    '*.lisp' '*.asd' '*.sexp' '*.cl' \
  | grep -v '^$' || true
)"

if [ -z "$files" ]; then
  echo "[check-lisp-parens] no staged Lisp files"
  exit 0
fi

check_with_emacsclient() {
  file="$1"
  client="${EMACSCLIENT:-emacsclient}"

  if ! command -v "$client" >/dev/null 2>&1; then
    return 127
  fi

  FILE="$file" "$client" --eval '
(let ((file (getenv "FILE")))
  (with-temp-buffer
    (insert-file-contents file)
    (set-visited-file-name file)
    (lisp-mode)
    (check-parens)
    (message "balanced: %s" file)))
' >/dev/null
}

check_with_batch_emacs() {
  file="$1"
  emacs="${EMACS:-emacs}"

  "$emacs" -Q --batch "$file" \
    --eval '(progn
              (lisp-mode)
              (check-parens)
              (message "balanced: %s" buffer-file-name))'
}

for file in $files; do
  if [ ! -f "$file" ]; then
    continue
  fi

  echo "[check-lisp-parens] $file"

  if check_with_emacsclient "$file"; then
    echo "[check-lisp-parens] checked via emacsclient: $file"
  else
    echo "[check-lisp-parens] emacsclient unavailable; falling back to batch Emacs: $file"
    check_with_batch_emacs "$file"
  fi
done
