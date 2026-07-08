(:TASK
 (!REPAIR-LOCALIZED-FILED-OUT-FORK-SOURCE-PARENS-DEFECT :REPO :HYPERDOC :FILE
  "hyperdoc/fedwiki-materialization.lisp")
 :ZETTEL 9124 :DIAGNOSIS
 DUPLICATE-FILED-OUT-BLOCK-LEFT-MALFORMED-FIRST-BLOCK-IN-SOURCE :REPAIR
 REPLACE-FROM-FIRST-REMOTE-FORK-MARKER-TO-EOF-WITH-SINGLE-CLEAN-BLOCK
 :SOURCE-SHAPE-BEFORE
 (:REMOTE-FORK-MARKER-COUNT 2 :PAGE-WITH-APPENDED-FORK-ACTION-DEFUN-COUNT 1
  :FIRST-MARKER-FOUND-P T)
 :SOURCE-SHAPE-AFTER
 (:REMOTE-FORK-MARKER-COUNT 1 :PAGE-WITH-APPENDED-FORK-ACTION-DEFUN-COUNT 1)
 :READER-VALIDATION (:READABLE-P T :FORM-COUNT 50) :SOURCE-WRITTEN-P T
 :CHECK-PARENS
 (:COMMAND
  ("nix" "develop" "-c" "tools/check-lisp-parens.sh"
   "hyperdoc/fedwiki-materialization.lisp")
  :STDOUT "HyperDoc Nix dev shell ready.

Check system:
  sbcl --no-userinit --non-interactive \\
    --eval '(require :asdf)' \\
    --eval '(asdf:find-system :hyperbook/server)' \\
    --eval '(format t \"OK~%\")' \\
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
[check-lisp-parens] hyperdoc/fedwiki-materialization.lisp
[check-lisp-parens] emacsclient unavailable; falling back to batch Emacs: hyperdoc/fedwiki-materialization.lisp
[check-lisp-parens] hyperdoc/zettel-9124-file-out-live-remote-fork-materialization.safe.evidence.sexp
[check-lisp-parens] emacsclient unavailable; falling back to batch Emacs: hyperdoc/zettel-9124-file-out-live-remote-fork-materialization.safe.evidence.sexp
"
  :STDERR
  "warning: Git tree '/Users/rgb/workspace/hyperdoc' has uncommitted changes
/nix/store/8wnpl9s8r8w66xpbvm9ypfgd98164549-emacs-30.1/bin/emacsclient: can't find socket; have you started the server?
/nix/store/8wnpl9s8r8w66xpbvm9ypfgd98164549-emacs-30.1/bin/emacsclient: To start the server in Emacs, type \"M-x server-start\".
/nix/store/8wnpl9s8r8w66xpbvm9ypfgd98164549-emacs-30.1/bin/emacsclient: No socket or alternate editor.  Please use:

	--socket-name
	--server-file      (or environment variable EMACS_SERVER_FILE)
	--alternate-editor (or environment variable ALTERNATE_EDITOR)
balanced: /Users/rgb/workspace/hyperdoc/hyperdoc/fedwiki-materialization.lisp
/nix/store/8wnpl9s8r8w66xpbvm9ypfgd98164549-emacs-30.1/bin/emacsclient: can't find socket; have you started the server?
/nix/store/8wnpl9s8r8w66xpbvm9ypfgd98164549-emacs-30.1/bin/emacsclient: To start the server in Emacs, type \"M-x server-start\".
/nix/store/8wnpl9s8r8w66xpbvm9ypfgd98164549-emacs-30.1/bin/emacsclient: No socket or alternate editor.  Please use:

	--socket-name
	--server-file      (or environment variable EMACS_SERVER_FILE)
	--alternate-editor (or environment variable ALTERNATE_EDITOR)
balanced: /Users/rgb/workspace/hyperdoc/hyperdoc/zettel-9124-file-out-live-remote-fork-materialization.safe.evidence.sexp
"
  :EXIT-CODE 0)
 :DIFF-CHECK
 (:COMMAND
  (#1="nix" #2="develop" #3="-c" #4="git" "diff" "--check" "--"
   "hyperdoc/fedwiki-materialization.lisp")
  :STDOUT "HyperDoc Nix dev shell ready.

Check system:
  sbcl --no-userinit --non-interactive \\
    --eval '(require :asdf)' \\
    --eval '(asdf:find-system :hyperbook/server)' \\
    --eval '(format t \"OK~%\")' \\
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
"
  :STDERR
  "warning: Git tree '/Users/rgb/workspace/hyperdoc' has uncommitted changes
"
  :EXIT-CODE 0)
 :GIT-STATUS
 (:COMMAND
  (#1# #2# #3# #4# "status" "--short" "--"
   "hyperdoc/fedwiki-materialization.lisp"
   "hyperdoc/zettel-9124-file-out-live-remote-fork-materialization.safe.evidence.sexp"
   "hyperdoc/zettel-9124-repair-filed-out-fork-source-parens.evidence.sexp"
   "hyperdoc/zettel-9124-localize-filed-out-fork-source-parens-defect.evidence.sexp"
   "hyperdoc/zettel-9124-repair-first-marker-filed-out-fork-block.evidence.sexp")
  :STDOUT "HyperDoc Nix dev shell ready.

Check system:
  sbcl --no-userinit --non-interactive \\
    --eval '(require :asdf)' \\
    --eval '(asdf:find-system :hyperbook/server)' \\
    --eval '(format t \"OK~%\")' \\
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
MM hyperdoc/fedwiki-materialization.lisp
A  hyperdoc/zettel-9124-file-out-live-remote-fork-materialization.safe.evidence.sexp
?? hyperdoc/zettel-9124-localize-filed-out-fork-source-parens-defect.evidence.sexp
?? hyperdoc/zettel-9124-repair-filed-out-fork-source-parens.evidence.sexp
"
  :STDERR
  "warning: Git tree '/Users/rgb/workspace/hyperdoc' has uncommitted changes
"
  :EXIT-CODE 0)
 :ACCEPTANCE
 ((DUPLICATE-REMOTE-FORK-BLOCK-REMOVED T)
  (SINGLE-PAGE-WITH-APPENDED-FORK-ACTION-DEFINITION T)
  (SOURCE-READABLE-BY-COMMON-LISP-READER T) (CHECK-LISP-PARENS-EXIT-CODE 0)
  (DIFF-CHECK-EXIT-CODE 0) (COMMIT-NOT-PERFORMED T)
  (PAGE-ATTACHED-ASDF-NOT-WRITTEN T) (SQLITE-NOT-CREATED T))
 :NEXT-TASK
 (!RETRY-COMMIT-FILED-OUT-LIVE-REMOTE-FORK-MATERIALIZATION-FUNCTIONALITY :REPO
  :HYPERDOC))
