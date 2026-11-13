#!/bin/sh
# The command the retained logs were made with, with the reviewer's paths given
# as variables. A fresh SBCL process, no user or system init file, an explicit
# source registry, and a compilation cache outside the repository.
#
#   WORKTREE      a clean checkout of the commit under test
#   A1_REVISION   a label printed into the log (the commit's short id)
#   LISP_SOURCES  a directory whose subdirectories hold the Lisp dependencies
#                 (the reviewer used the sbcl-* packages of a Nix store)
#   CACHE         an empty directory for the compilation cache
#   SBCL          the SBCL binary (the reviewer used SBCL 2.4.10)
#
#   run-probes.sh '(asdf:load-system "dreyeck/lisp-critic/text-criticism") (load "probes.lisp")'
#   run-probes.sh '(asdf:test-system "dreyeck/lisp-critic/text-criticism")'
: "${WORKTREE:?}" "${A1_REVISION:?}" "${LISP_SOURCES:?}" "${CACHE:?}"
SBCL=${SBCL:-sbcl}
DIRS=$(ls -d "$LISP_SOURCES"/*-sbcl-*/ | grep -v '\.drv' | sed 's/^/(:tree "/; s/$/")/' | tr '\n' ' ')
cd "$WORKTREE" || exit 2
env -i A1_REVISION="$A1_REVISION" PATH="$PATH" HOME="$CACHE" XDG_CACHE_HOME="$CACHE/.cache" LANG=C.UTF-8 \
  "$SBCL" --no-userinit --no-sysinit --non-interactive \
  --eval '(require :asdf)' \
  --eval "(asdf:initialize-source-registry '(:source-registry (:directory \"$WORKTREE/\") $DIRS :ignore-inherited-configuration))" \
  --eval "(handler-case (progn $1 (format t \"~&EXIT-OK~%\")) (error (c) (format t \"~&TEST-ERROR: ~A~%\" c) (uiop:quit 1)))"
