(:TASK
 (!RERUN-ZETTEL-9122-CLEAN-SMOKE-WITH-TAIL-CAPTURE :SYSTEM
  :HYPERDOC/FEDWIKI-ASDF-ASSETS)
 :ZETTEL 9123 :PARENT-TASK
 (!INSPECT-ZETTEL-9122-CLEAN-SMOKE-TAIL :SYSTEM :HYPERDOC/FEDWIKI-ASDF-ASSETS)
 :STAGE-BOUNDARY
 ((MAY-RERUN-CLEAN-OUT-OF-PROCESS-NIX-SBCL-LOAD-SMOKE T)
  (MAY-WRITE-TEMPORARY-SMOKE-SCRIPT T) (MAY-CAPTURE-FULL-STDOUT-TO-FILE T)
  (MAY-CAPTURE-FULL-STDERR-TO-FILE T)
  (MAY-WRITE-TAIL-CAPTURE-EVIDENCE-ARTIFACT T)
  (MAY-WRITE-PAGE-ATTACHED-ASDF NIL) (MAY-CREATE-SQLITE NIL) (MAY-COMMIT NIL))
 :PREVIOUS-DIAGNOSIS :CLEAN-SMOKE-OUTPUT-TRUNCATED-BEFORE-LISP-RESULT
 :CLEAN-OUT-OF-PROCESS-SMOKE
 (:COMMAND
  ("nix" "develop" "-c" "sh" "-lc"
   #A((335) BASE-CHAR
      . "sbcl --no-userinit --script '/tmp/nix-shell.OE15UR/wgd-zettel-9123-clean-writer-load-smoke.lisp' > '/tmp/nix-shell.OE15UR/wgd-zettel-9123-clean-writer-load-smoke.stdout' 2> '/tmp/nix-shell.OE15UR/wgd-zettel-9123-clean-writer-load-smoke.stderr'; printf '%s' $? > '/tmp/nix-shell.OE15UR/wgd-zettel-9123-clean-writer-load-smoke.exit-code'"))
  :SCRIPT-PATH
  #A((66) BASE-CHAR
     . "/tmp/nix-shell.OE15UR/wgd-zettel-9123-clean-writer-load-smoke.lisp")
  :STDOUT-PATH
  #A((68) BASE-CHAR
     . "/tmp/nix-shell.OE15UR/wgd-zettel-9123-clean-writer-load-smoke.stdout")
  :STDERR-PATH
  #A((68) BASE-CHAR
     . "/tmp/nix-shell.OE15UR/wgd-zettel-9123-clean-writer-load-smoke.stderr")
  :EXIT-CODE-PATH
  #A((71) BASE-CHAR
     . "/tmp/nix-shell.OE15UR/wgd-zettel-9123-clean-writer-load-smoke.exit-code")
  :WRAPPER-RUN-RETURNED-P T :WRAPPER-STDOUT-TAIL "HyperDoc Nix dev shell ready.

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
  :WRAPPER-STDERR-TAIL "" :WRAPPER-EXIT-CODE 0 :SBCL-EXIT-CODE-TEXT "42"
  :STDOUT-LENGTH 1003 :STDERR-LENGTH 0 :STDOUT-TAIL
  "This is SBCL 2.6.4, an implementation of ANSI Common Lisp.
More information about SBCL is available at <http://www.sbcl.org/>.

SBCL is free software, provided as is, with absolutely no warranty.
It is mostly in the public domain; some portions are provided under
BSD-style licenses.  See the CREDITS and COPYING files in the
distribution for more information.
WGD-SMOKE-START
ASDF-VERSION 3.3.1
WGD-SMOKE-RESULT (:CLEAN-SBCL-LOAD-RESULT
                  (:LOAD-SUCCEEDED-P NIL :CONDITION-TYPE-NAME
                   \"ASDF/PLAN:SYSTEM-OUT-OF-DATE\" :CONDITION-MESSAGE
                   \"system hyperdoc is out of date\")
                  :SYMBOLS
                  ((:NAME \"MAKE-PAGE-ASDF-ASSET-SPEC\" :PRESENT-P NIL :FBOUND-P
                    NIL)
                   (:NAME \"WRITE-PAGE-ASDF-SYSTEM\" :PRESENT-P NIL :FBOUND-P
                    NIL)
                   (:NAME \"LOAD-PAGE-ASDF-SYSTEM\" :PRESENT-P NIL :FBOUND-P
                    NIL))
                  :SUCCESS-P NIL)
WGD-SMOKE-END
"
  :STDERR-TAIL "" :SCRIPT-START-VISIBLE-P T :SCRIPT-RESULT-VISIBLE-P T
  :SCRIPT-END-VISIBLE-P T :SUCCESS-TEXT-PRESENT-P NIL :FAILURE-TEXT-PRESENT-P T
  :ASDF-SYSTEM-OUT-OF-DATE-VISIBLE-P T :ASDF-CONDITION-VISIBLE-P T
  :COMBINED-TAIL
  #A((1004) BASE-CHAR
     . "This is SBCL 2.6.4, an implementation of ANSI Common Lisp.
More information about SBCL is available at <http://www.sbcl.org/>.

SBCL is free software, provided as is, with absolutely no warranty.
It is mostly in the public domain; some portions are provided under
BSD-style licenses.  See the CREDITS and COPYING files in the
distribution for more information.
WGD-SMOKE-START
ASDF-VERSION 3.3.1
WGD-SMOKE-RESULT (:CLEAN-SBCL-LOAD-RESULT
                  (:LOAD-SUCCEEDED-P NIL :CONDITION-TYPE-NAME
                   \"ASDF/PLAN:SYSTEM-OUT-OF-DATE\" :CONDITION-MESSAGE
                   \"system hyperdoc is out of date\")
                  :SYMBOLS
                  ((:NAME \"MAKE-PAGE-ASDF-ASSET-SPEC\" :PRESENT-P NIL :FBOUND-P
                    NIL)
                   (:NAME \"WRITE-PAGE-ASDF-SYSTEM\" :PRESENT-P NIL :FBOUND-P
                    NIL)
                   (:NAME \"LOAD-PAGE-ASDF-SYSTEM\" :PRESENT-P NIL :FBOUND-P
                    NIL))
                  :SUCCESS-P NIL)
WGD-SMOKE-END

"))
 :DIAGNOSIS :CLEAN-DEV-SHELL-LOAD-FAILS-WITH-VISIBLE-SCRIPT-RESULT :ACCEPTANCE
 ((CLEAN-SMOKE-RERUN-WITH-TAIL-CAPTURE-ATTEMPTED T)
  (FULL-STDOUT-FILE-CAPTURED T) (FULL-STDERR-FILE-CAPTURED T)
  (NO-PAGE-ATTACHED-ASDF-WRITTEN T) (NO-SQLITE-CREATED T)
  (NO-COMMIT-PERFORMED T))
 :NEXT-TASK
 (!CLASSIFY-VISIBLE-CLEAN-SMOKE-FAILURE :SYSTEM :HYPERDOC/FEDWIKI-ASDF-ASSETS))
