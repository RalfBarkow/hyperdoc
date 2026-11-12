#!/bin/sh
# The command the retained logs were made with, with this environment's paths
# given as variables. A fresh SBCL process, no user or system init file, an
# explicit source registry, and a compilation cache outside the repository.
#
#   WORKTREE      the checkout under test
#   LISP_SOURCES  a directory whose subdirectories hold the Lisp dependencies
#                 (here: the sbcl-* packages of the Nix store)
#   CACHE         an empty directory for the compilation cache
#   SBCL          the SBCL binary (here: SBCL 2.4.10)
#
#   run-tests.sh '(asdf:test-system "dreyeck/lisp-critic/text-criticism")'
: "${WORKTREE:?}" "${LISP_SOURCES:?}" "${CACHE:?}"
SBCL=${SBCL:-sbcl}
DIRS=$(ls -d "$LISP_SOURCES"/*-sbcl-*/ | grep -v '\.drv' | sed 's/^/(:tree "/; s/$/")/' | tr '\n' ' ')
env -i PATH="$PATH" HOME="$CACHE" XDG_CACHE_HOME="$CACHE/.cache" LANG=C.UTF-8 \
  "$SBCL" --no-userinit --no-sysinit --non-interactive \
  --eval '(require :asdf)' \
  --eval "(asdf:initialize-source-registry '(:source-registry (:directory \"$WORKTREE/\") $DIRS :ignore-inherited-configuration))" \
  --eval "(handler-case (progn $1 (format t \"~&EXIT-OK~%\")) (error (c) (format t \"~&TEST-ERROR: ~A~%\" c) (uiop:quit 1)))"
