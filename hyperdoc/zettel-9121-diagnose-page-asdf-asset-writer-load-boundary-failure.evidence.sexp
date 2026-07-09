(:TASK
 "(!DIAGNOSE-PAGE-ASDF-ASSET-WRITER-LOAD-BOUNDARY-FAILURE :SYSTEM :HYPERDOC/FEDWIKI-ASDF-ASSETS)"
 :ZETTEL 9121 :REPAIRS-FORM-BUG
 "Previous diagnostic form had COMMAND outside the LET* binding list and an unmatched close parenthesis."
 :PARENT-TASK
 "(!REPAIR-PAGE-ASDF-ASSET-WRITER-LOAD-BOUNDARY :SYSTEM :HYPERDOC/FEDWIKI-ASDF-ASSETS :STALE-DEPENDENCY :ALEXANDRIA)"
 :STAGE-BOUNDARY
 ((MAY-DIAGNOSE-LIVE-IMAGE-ASDF-STATE T)
  (MAY-RUN-CLEAN-OUT-OF-PROCESS-NIX-SBCL-LOAD-SMOKE T)
  (MAY-WRITE-DIAGNOSTIC-EVIDENCE-ARTIFACT T) (MAY-WRITE-PAGE-ATTACHED-ASDF NIL)
  (MAY-CREATE-SQLITE NIL) (MAY-COMMIT NIL))
 :PREVIOUS-LOAD-FAILURES
 ((:SYSTEM "ALEXANDRIA" :CONDITION-TYPE-NAME "ASDF/PLAN:SYSTEM-OUT-OF-DATE"
   :CONDITION-MESSAGE "system alexandria is out of date")
  (:SYSTEM "TRIVIAL-PACKAGE-LOCAL-NICKNAMES" :CONDITION-TYPE-NAME
   "ASDF/PLAN:SYSTEM-OUT-OF-DATE" :CONDITION-MESSAGE
   "system trivial-package-local-nicknames is out of date"))
 :IN-IMAGE
 (:ASDF-VERSION #A((5) BASE-CHAR . "3.3.1") :SYSTEM-DESCRIPTORS
  ((:SYSTEM-NAME #1=#A((28) BASE-CHAR . "HYPERDOC/FEDWIKI-ASDF-ASSETS")
    :FINDABLE-P T :SYSTEM-TYPE-NAME #A((18) BASE-CHAR . "ASDF/SYSTEM:SYSTEM")
    :COMPONENT-PATHNAME #A((30) BASE-CHAR . "/Users/rgb/workspace/hyperdoc/")
    :COMPONENT-VERSION #A((5) BASE-CHAR . "0.0.1"))
   (:SYSTEM-NAME #2=#A((10) BASE-CHAR . "ALEXANDRIA") :FINDABLE-P T
    :SYSTEM-TYPE-NAME #A((18) BASE-CHAR . "ASDF/SYSTEM:SYSTEM")
    :COMPONENT-PATHNAME
    #A((51) BASE-CHAR . "/nix/store/i6nnd3amy08a3f3v8q76nh9kw9434z29-source/")
    :COMPONENT-VERSION #A((5) BASE-CHAR . "1.0.1"))
   (:SYSTEM-NAME #3=#A((31) BASE-CHAR . "TRIVIAL-PACKAGE-LOCAL-NICKNAMES")
    :FINDABLE-P T :SYSTEM-TYPE-NAME #A((18) BASE-CHAR . "ASDF/SYSTEM:SYSTEM")
    :COMPONENT-PATHNAME
    #A((51) BASE-CHAR . "/nix/store/qpaznjvjiv3m0b74rm5d2viwbsrxbgq2-source/")
    :COMPONENT-VERSION #A((3) BASE-CHAR . "0.2")))
  :REQUIRED-SYMBOLS-BEFORE-LOAD-PROBES
  ((:REQUIRED-SYMBOL-NAME #4="MAKE-PAGE-ASDF-ASSET-SPEC" :HYPERDOC
    (:PACKAGE-NAME #5="HYPERDOC" :PACKAGE-PRESENT-P T :SYMBOL-NAME #4#
     :SYMBOL-PRESENT-P T :SYMBOL-STATUS-NAME #6=#A((8) BASE-CHAR . "EXTERNAL")
     :SYMBOL-DESIGNATOR
     #A((35) BASE-CHAR . "HYPERDOC::MAKE-PAGE-ASDF-ASSET-SPEC") :FBOUND-P NIL)
    :HYPERDOC-FEDWIKI-ASDF-ASSETS
    (:PACKAGE-NAME #7="HYPERDOC/FEDWIKI-ASDF-ASSETS" :PACKAGE-PRESENT-P NIL
     :SYMBOL-NAME #4# :SYMBOL-PRESENT-P NIL :SYMBOL-STATUS-NAME NIL
     :SYMBOL-DESIGNATOR NIL :FBOUND-P NIL)
    :ANY-FBOUND-P NIL)
   (:REQUIRED-SYMBOL-NAME #8="WRITE-PAGE-ASDF-SYSTEM" :HYPERDOC
    (:PACKAGE-NAME #5# :PACKAGE-PRESENT-P T :SYMBOL-NAME #8# :SYMBOL-PRESENT-P
     T :SYMBOL-STATUS-NAME #6# :SYMBOL-DESIGNATOR
     #A((32) BASE-CHAR . "HYPERDOC::WRITE-PAGE-ASDF-SYSTEM") :FBOUND-P NIL)
    :HYPERDOC-FEDWIKI-ASDF-ASSETS
    (:PACKAGE-NAME #7# :PACKAGE-PRESENT-P NIL :SYMBOL-NAME #8#
     :SYMBOL-PRESENT-P NIL :SYMBOL-STATUS-NAME NIL :SYMBOL-DESIGNATOR NIL
     :FBOUND-P NIL)
    :ANY-FBOUND-P NIL)
   (:REQUIRED-SYMBOL-NAME #9="LOAD-PAGE-ASDF-SYSTEM" :HYPERDOC
    (:PACKAGE-NAME #5# :PACKAGE-PRESENT-P T :SYMBOL-NAME #9# :SYMBOL-PRESENT-P
     T :SYMBOL-STATUS-NAME #6# :SYMBOL-DESIGNATOR
     #A((31) BASE-CHAR . "HYPERDOC::LOAD-PAGE-ASDF-SYSTEM") :FBOUND-P NIL)
    :HYPERDOC-FEDWIKI-ASDF-ASSETS
    (:PACKAGE-NAME #7# :PACKAGE-PRESENT-P NIL :SYMBOL-NAME #9#
     :SYMBOL-PRESENT-P NIL :SYMBOL-STATUS-NAME NIL :SYMBOL-DESIGNATOR NIL
     :FBOUND-P NIL)
    :ANY-FBOUND-P NIL))
  :LOAD-PROBES
  (:ALEXANDRIA-NORMAL
   (:SYSTEM-NAME #2# :LOAD-SUCCEEDED-P NIL :CONDITION
    (:CONDITION-TYPE-NAME
     #A((33) BASE-CHAR . "SB-KERNEL:REDEFINITION-WITH-DEFUN")
     :CONDITION-MESSAGE
     #A((52) BASE-CHAR
        . "redefining ALEXANDRIA::%REEVALUATE-CONSTANT in DEFUN")))
   :TRIVIAL-PACKAGE-LOCAL-NICKNAMES-NORMAL
   (:SYSTEM-NAME #3# :LOAD-SUCCEEDED-P NIL :CONDITION
    (:CONDITION-TYPE-NAME
     #A((36) BASE-CHAR . "SB-KERNEL:REDEFINITION-WITH-DEFMACRO")
     :CONDITION-MESSAGE
     #A((67) BASE-CHAR
        . "redefining TRIVIAL-PACKAGE-LOCAL-NICKNAMES::DEFINE-TEST in DEFMACRO")))
   :WRITER-NORMAL
   (:SYSTEM-NAME #1# :LOAD-SUCCEEDED-P NIL :CONDITION
    (:CONDITION-TYPE-NAME #A((28) BASE-CHAR . "ASDF/PLAN:SYSTEM-OUT-OF-DATE")
     :CONDITION-MESSAGE
     #A((32) BASE-CHAR . "system trivial-do is out of date"))))
  :REQUIRED-SYMBOLS-AFTER-LOAD-PROBES
  ((:REQUIRED-SYMBOL-NAME #4# :HYPERDOC
    (:PACKAGE-NAME #5# :PACKAGE-PRESENT-P T :SYMBOL-NAME #4# :SYMBOL-PRESENT-P
     T :SYMBOL-STATUS-NAME #6# :SYMBOL-DESIGNATOR
     #A((35) BASE-CHAR . "HYPERDOC::MAKE-PAGE-ASDF-ASSET-SPEC") :FBOUND-P NIL)
    :HYPERDOC-FEDWIKI-ASDF-ASSETS
    (:PACKAGE-NAME #7# :PACKAGE-PRESENT-P NIL :SYMBOL-NAME #4#
     :SYMBOL-PRESENT-P NIL :SYMBOL-STATUS-NAME NIL :SYMBOL-DESIGNATOR NIL
     :FBOUND-P NIL)
    :ANY-FBOUND-P NIL)
   (:REQUIRED-SYMBOL-NAME #8# :HYPERDOC
    (:PACKAGE-NAME #5# :PACKAGE-PRESENT-P T :SYMBOL-NAME #8# :SYMBOL-PRESENT-P
     T :SYMBOL-STATUS-NAME #6# :SYMBOL-DESIGNATOR
     #A((32) BASE-CHAR . "HYPERDOC::WRITE-PAGE-ASDF-SYSTEM") :FBOUND-P NIL)
    :HYPERDOC-FEDWIKI-ASDF-ASSETS
    (:PACKAGE-NAME #7# :PACKAGE-PRESENT-P NIL :SYMBOL-NAME #8#
     :SYMBOL-PRESENT-P NIL :SYMBOL-STATUS-NAME NIL :SYMBOL-DESIGNATOR NIL
     :FBOUND-P NIL)
    :ANY-FBOUND-P NIL)
   (:REQUIRED-SYMBOL-NAME #9# :HYPERDOC
    (:PACKAGE-NAME #5# :PACKAGE-PRESENT-P T :SYMBOL-NAME #9# :SYMBOL-PRESENT-P
     T :SYMBOL-STATUS-NAME #6# :SYMBOL-DESIGNATOR
     #A((31) BASE-CHAR . "HYPERDOC::LOAD-PAGE-ASDF-SYSTEM") :FBOUND-P NIL)
    :HYPERDOC-FEDWIKI-ASDF-ASSETS
    (:PACKAGE-NAME #7# :PACKAGE-PRESENT-P NIL :SYMBOL-NAME #9#
     :SYMBOL-PRESENT-P NIL :SYMBOL-STATUS-NAME NIL :SYMBOL-DESIGNATOR NIL
     :FBOUND-P NIL)
    :ANY-FBOUND-P NIL)))
 :CLEAN-OUT-OF-PROCESS-SMOKE
 (:SCRIPT-PATH
  #10=#A((57) BASE-CHAR
         . "/tmp/nix-shell.OE15UR/wgd-clean-writer-load-smoke-v2.lisp")
  :COMMAND ("nix" "develop" "-c" "sbcl" "--no-userinit" "--script" #10#)
  :RUN-PROGRAM-RETURNED-P T :STDOUT-TYPE-NAME
  #A((30) BASE-CHAR . "(SIMPLE-ARRAY CHARACTER (836))") :STDOUT-FRAGMENT
  "HyperDoc Nix dev shell ready.

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
This is SBCL 2.4.10, an implementation of ANSI Common Lisp.
More information about SBCL is available at <http://www.sbcl.org/>.

SBCL is free software, provided as is, with absolutely no warranty.
It is mostly in the public domain; some portions are provided under
BSD-style licenses.  See the CREDITS and COPYING files in the
distribution for more information.
"
  :STDERR-TYPE-NAME #A((32) BASE-CHAR . "(SIMPLE-ARRAY CHARACTER (26386))")
  :STDERR-FRAGMENT
  "copying path '/nix/store/c95myqjsrrmhs0f722q2ly6nacg44pp6-gnused-4.9' from 'https://install.determinate.systems'...
copying path '/nix/store/cw7i8bvxip0wsjp7ara46vl68ypxmd24-perl5.40.0-Digest-HMAC-1.04' from 'https://install.determinate.systems'...
copying path '/nix/store/ycimrm22c0dj16yifk1qvzxbhsc33sbr-perl5.40.0-TermReadKey-2.38' from 'https://install.determinate.systems'...
copying path '/nix/store/m7fii150471wky9br605fgzclzzrk6p3-source' from 'https://cache.nixos.org'...
copying path '/nix/store/1kykw1cszjvdk17q712pcs1y1ik5r3nj-file-5.45' from 'https://install.determinate.systems'...
copying path '/nix/store/2am5w50kyf1kdl5wq1j5b18jv47zfkdp-icu4c-74.2' from 'https://install.determinate.systems'...
copying path '/nix/store/cbiqxbz30i66zvqlca1yjphs6r4ni4ni-perl5.40.0-Mozilla-CA-20230821' from 'https://install.determinate.systems'...
copying path '/nix/store/8h9r8mc8v1ym038m6dxy4qbnw3wn7pc5-sqlite-3.46.1-bin' from 'https://install.determinate.systems'...
copying path '/nix/store/zzqrrfmkblxd075vkwjvwjjjbbsgvcik-findutils-4.10.0' from 'https://install.determinate.systems'...
copying path '/nix/store/mnmzrrnx295dsk71n046kjg6gmj9g51j-gnugrep-3.11' from 'https://install.determinate.systems'...
copying path '/nix/store/fq5h5rl03ci0bkd5id254784m86k6ykr-openssl-3.3.3-bin' from 'https://install.determinate.systems'...
copying path '/nix/store/p3p65m81cxyqyssbzw6ja87v0p5bhsl3-perl5.40.0-Net-HTTP-6.23' from 'https://install.determinate.systems'...
copying path '/nix/store/2vykk0j1sk0i03yz1zn49af18xnc0c8f-xz-5.6.3-bin' from 'https://install.determinate.systems'...
copying path '/nix/store/wx5lmyr34a0mkzl6vx28b6bhjdh6g7qi-compiler-rt-libc-16.0.6' from 'https://install.determinate.systems'...
copying path '/nix/store/wwawiyk2jhipbz7hw9kabby2s0i23lbs-die-hook' from 'https://cache.nixos.org'...
copying path '/nix/store/mb5i9r8wy0afprs0c1d3xp86s7yi9plm-sbcl-swank-2.29.1-build' from 'https://cache.nixos.org'...
copying path '/nix/store/aa5fpap0rp5p5k47mf5v8i724j7ggiwb-CoreFoundation-10.12' from 'https://install.determinate.systems'...
copying path '/nix/store/nf6vfc3g9r0r1am90f09rch4awhld5mm-CoreServices-10.12' from 'https://install.determinate.systems'...
copying path '/nix/store/938g1151rwn63zxxmw5xcaivmszv9v8l-ShellCheck-0.10.0' from 'https://cache.nixos.org'...
copying path '/nix/store/mn7bwpf258i3lh6mmy5vi50risvq7b3q-openssl-3.3.3' from 'https://cache.nixos.org'...
copying path '/nix/store/ar3fs7mkcnaz4xvwfhc3j7qw21dynjz1-perl5.40.0-Authen-SASL-2.1700' from 'https://install.determinate.systems'...
copying path '/nix/store/zd57592sp4y2dfiw7zzv02xnyza882qh-sbcl-array-utils-20241012-git' from 'https://cache.nixos.org'...
copying path '/nix/store/97bfk4knnwiayd7phdbsmrkg076wfb71-sbcl-arrows-20181018-git' from 'https://cache.nixos.org'...
copying path '/nix/store/hy8hsbzgzklk9pqblifb13fnr41lllsj-perl5.40.0-IO-Socket-SSL-2.083' from 'https://install.determinate.systems'...
copying path '/nix/store/pnd4sb22f1s913qz4wk42h83r7x6r56s-sbcl-chipz-20230618-git' from 'https://cache.nixos.org'...
copying path '/nix/store/wlziwmhj0ndhwimicghgngc61a3knbi0-sbcl-cl-isaac-20231021-git' from 'https://cache.nixos.org'...
copying path '/nix/store/8c6bb5r2y26a1pkrrs1zbb1r86rr2ggc-sbcl-cl-ppcre-20241012-git' from 'https://cache.nixos.org'...
copying path '/nix/store/rp24q9k06wxn34nwcy4wxwq9sp990iw1-sbcl-cl-utilities-1.2.4' from 'https://cache.nixos.org'...
copying path '/nix/store/7kwvfxhgrx9d2nnainzdflxrd76c1aj3-sbcl-cl-who-20241012-git' from 'https://cache.nixos.org'...
copying path '/nix/store/9wsmnm6l4adihbb6nz1ar5ynbdh4cb0c-sbcl-clack-socket-20241012-git' from 'https://cache.nixos.org'...
copying path '/nix/store/4361x0jvnga72w5zmr5hxmhx2agd66jb-sbcl-closer-mop-20241012-git' from 'https://cache.nixos.org'...
copying path '/nix/store/hr5d5y1n3azx60vnrrqn2gbvv3q46z09-openssl-3.3.3-dev' from 'https://install.determinate.systems'...
copying path '/nix/store/hdscpmzcr93yjfwy890zr1k4kvc9rkb3-sbcl-concrete-syntax-tree-base-20230618-git' from 'https://cache.nixos.org'...
copying path '/nix/store/g70ws1g0s9ll284d821lxg4m27pfnr7m-sbcl-dissect-20241012-git' from 'https://cache.nixos.org'...
copying path '/nix/store/drh08jbq1j24n7hlvyj6jbkmksxqn0lg-sbcl-global-vars-20141106-git' from 'https://cache.nixos.org'...
copying path '/nix/store/nkq6qljb8r6a1x7apv4dh43j98l9w8b9-sbcl-iterate-release-b0f9a9c6-git' from 'https://cache.nixos.org'...
copying path '/nix/store/zmagxicd3wrw9xgqgmypsj4plqwf5y90-sbcl-lack-component-20241012-git' from 'https://cache.nixos.org'...
copying path '/nix/store/aql538vwbxzignlzwribi19q1w4qwrah-compiler-rt-libc-16.0.6-dev' from 'https://install.determinate.systems'...
copying path '/nix/store/35mgfmlzhpj9rvyhzv46kzzgsz4khi1a-sbcl-mgl-pax.asdf-20241012-git' from 'https://cache.nixos.org'...
copying path '/nix/store/6n7xwakwzhv0c9qaa3x8amqrds7kc1fk-sbcl-plump-20241012-git' from 'https://cache.nixos.org'...
copying path '/nix/store/4qig2k6n45nj2y1hjv1w58dqni3hd0rs-libssh2-1.11.1' from 'https://cache.nixos.org'...
copying path '/nix/store/89fimgrddfdf81jw7ck3i8kyvhkmgzwl-openssl-3.3.3-bin' from 'https://cache.nixos.org'...
copying path '/nix/store/dg73wlm88d1pkczw3jibkpq6cnjzn5hb-sbcl-puri-20201016-git' from 'https://cache.nixos.org'...
copying path '/nix/store/x9b6gqdzhqv4c1v3r4gx72p1fajbz61h-sbcl-random-state-20241012-git' from 'https://cache.nixos.org'...
copying path '/nix/store/cizvark6mqc9f47sksy2smdixrmhcfwk-sbcl-concrete-syntax-tree-lambda-list-20230618-git' from 'https://cache.nixos.org'...
copying path '/nix/store/kyama85q17rzl47wxwf93gm00rhna7r1-perl5.40.0-Net-SMTP-SSL-1.04' from 'https://install.determinate.systems'...
copying path '/nix/store/7z57j1jq9rnb9ni6r93sicwiyb3psjgi-sbcl-rfc2388-20180831-git' from 'https://cache.nixos.org'...
copying path '/nix/store/v5bklmdrr3cs900h9yw5v8xkrihhmqrg-sbcl-slynk-trunk' from 'https://cache.nixos.org'...
copying path '/nix/store/rwa1krvlq2ch8a8j0qbh1cixa3d23pw9-sbcl-swank-2.29.1' from 'https://cache.nixos.org'...
copying path '/nix/store/nf8403qwk39ki115i6c2"
  :EXIT-CODE 1 :SUCCESS-TEXT-PRESENT-P NIL)
 :DIAGNOSIS
 (:DIAGNOSIS :CLEAN-DEV-SHELL-LOAD-ALSO-FAILS :CLEAN-SMOKE-SUCCEEDED-P NIL
  :IN-IMAGE-WRITER-LOAD-SUCCEEDED-P NIL
  :DO-NOT-ADVANCE-TO-SYMBOL-VALIDATION-UNLESS-LOAD-BOUNDARY-CROSSED T)
 :ACCEPTANCE-FOR-CURRENT-TASK
 ((LOAD-BOUNDARY-FAILURE-DIAGNOSED T) (DIAGNOSTIC-FORM-READER-BUG-REPAIRED T)
  (NO-PAGE-ATTACHED-ASDF-WRITTEN T) (NO-SQLITE-CREATED T)
  (NO-COMMIT-PERFORMED T))
 :NEXT-TASK
 (!REPAIR-DEVELOPMENT-SHELL-DEPENDENCY-STATE-FOR-PAGE-ASDF-ASSET-WRITER :SYSTEM
  :HYPERDOC/FEDWIKI-ASDF-ASSETS))
