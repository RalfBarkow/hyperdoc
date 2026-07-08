(:TASK
 (#A((59) BASE-CHAR
     . "COMMON-LISP-USER::!REPAIR-PRINT-NOT-READABLE-AFTER-FILE-OUT")
  :REPO #A((26) BASE-CHAR . "COMMON-LISP-USER::HYPERDOC"))
 :ZETTEL 9124 :DIAGNOSIS
 #A((71) BASE-CHAR
    . "COMMON-LISP-USER::PRINT-NOT-READABLE-DURING-RESULT-OR-EVIDENCE-PRINTING")
 :SOURCE-FILE
 #A((67) BASE-CHAR
    . "/Users/rgb/workspace/hyperdoc/hyperdoc/fedwiki-materialization.lisp")
 :ILLEGAL-DECLARE-PRESENT-BEFORE-P NIL :SOURCE-WRITTEN-P NIL
 :FUNCTIONALITY-PRESENT-IN-SOURCE-P T :LIVE-VALIDATION
 (:MAKE-ACTION-FBOUND-P
  "#<FUNCTION HYPERDOC::FEDWIKI-MATERIALIZATION-MAKE-EXPLICIT-FORK-ACTION>"
  :APPEND-FORK-FBOUND-P
  "#<FUNCTION HYPERDOC::FEDWIKI-MATERIALIZATION-PAGE-WITH-APPENDED-FORK-ACTION>"
  :STORY-IDS-FBOUND-P
  "#<FUNCTION HYPERDOC::FEDWIKI-MATERIALIZATION-PAGE-STORY-ITEM-IDS>"
  :CANONICAL-P-FBOUND-P
  "#<FUNCTION HYPERDOC::FEDWIKI-MATERIALIZATION-CANONICAL-FORK-ACTION-P>"
  :TITLE-PRESERVED-P T :STORY-IDS-PRESERVED-P T :JOURNAL-COUNT 3
  :JOURNAL-COUNT-VALID-P T :LAST-ACTION-IS-CANONICAL-FORK-P T
  :NO-HYPERDOC-SOURCE-SLUG-IN-PAGE-JSON-P T
  :NO-HYPERDOC-TARGET-SITE-IN-PAGE-JSON-P T :LIVE-VALIDATION-SUCCEEDED-P T)
 :GIT-DIFF-CHECK
 (:COMMAND ("diff" "--check" "--" "hyperdoc/fedwiki-materialization.lisp")
  :STDOUT "\"HyperDoc Nix dev shell ready.

Check system:
  sbcl --no-userinit --non-interactive \\\\
    --eval '(require :asdf)' \\\\
    --eval '(asdf:find-system :hyperbook/server)' \\\\
    --eval '(format t \\\"OK~%\\\")' \\\\
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
\""
  :STDERR
  "\"warning: Git tree '/Users/rgb/workspace/hyperdoc' has uncommitted changes
\""
  :EXIT-CODE 0)
 :GIT-DIFF-STAT
 (:COMMAND ("diff" "--stat" "--" "hyperdoc/fedwiki-materialization.lisp")
  :STDOUT "\"HyperDoc Nix dev shell ready.

Check system:
  sbcl --no-userinit --non-interactive \\\\
    --eval '(require :asdf)' \\\\
    --eval '(asdf:find-system :hyperbook/server)' \\\\
    --eval '(format t \\\"OK~%\\\")' \\\\
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
 hyperdoc/fedwiki-materialization.lisp | 267 ++++++++++++++++++++++++++++++++++
 1 file changed, 267 insertions(+)
\""
  :STDERR
  "\"warning: Git tree '/Users/rgb/workspace/hyperdoc' has uncommitted changes
\""
  :EXIT-CODE 0)
 :GIT-STATUS
 (:COMMAND ("status" "--short" "--" "hyperdoc/fedwiki-materialization.lisp")
  :STDOUT "\"HyperDoc Nix dev shell ready.

Check system:
  sbcl --no-userinit --non-interactive \\\\
    --eval '(require :asdf)' \\\\
    --eval '(asdf:find-system :hyperbook/server)' \\\\
    --eval '(format t \\\"OK~%\\\")' \\\\
    --eval '(uiop:quit 0)'

Start server:
  LISP_IDE=slime ./dev.sh
  LISP_IDE=sly   ./dev.sh

Matching editor clients:
  hyperdoc-slime-connect 127.0.0.1 <printed-swank-port>
  hyperdoc-sly-connect   127.0.0.1 <printed-slynk-port>

URL:
  http://localhost:8080/boot.html
 M hyperdoc/fedwiki-materialization.lisp
\""
  :STDERR
  "\"warning: Git tree '/Users/rgb/workspace/hyperdoc' has uncommitted changes
\""
  :EXIT-CODE 0)
 :ACCEPTANCE
 ((#A((54) BASE-CHAR
      . "COMMON-LISP-USER::PRINT-NOT-READABLE-EVIDENCE-REPAIRED")
   T)
  (#A((49) BASE-CHAR . "COMMON-LISP-USER::ILLEGAL-DECLARE-POSITION-ABSENT") T)
  (#A((62) BASE-CHAR
      . "COMMON-LISP-USER::FORMS-READ-AND-EVALUATED-IN-HYPERDOC-PACKAGE")
   T)
  (#A((43) BASE-CHAR . "COMMON-LISP-USER::LIVE-VALIDATION-SUCCEEDED") T)
  (#A((48) BASE-CHAR . "COMMON-LISP-USER::PAGE-ATTACHED-ASDF-NOT-WRITTEN") T)
  (#A((36) BASE-CHAR . "COMMON-LISP-USER::SQLITE-NOT-CREATED") T)
  (#A((38) BASE-CHAR . "COMMON-LISP-USER::COMMIT-NOT-PERFORMED") T))
 :NEXT-TASK
 (#A((82) BASE-CHAR
     . "COMMON-LISP-USER::!COMMIT-FILED-OUT-LIVE-REMOTE-FORK-MATERIALIZATION-FUNCTIONALITY")
  :REPO #A((26) BASE-CHAR . "COMMON-LISP-USER::HYPERDOC")))
