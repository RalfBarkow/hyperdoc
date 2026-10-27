;;;; Recorded Evidence: What Ran, When, and What It Said
(in-package #:topic-maps-deployment-review)

;;; Every record here is a file of the candidate under docs/topic-maps-deployment/evidence/, written by a run on
;;; 2026-10-26 after the last change to a program or test file. Showing a record reads that file; it runs nothing.
;;; A record names the procedure that produced it, as objects where the procedure is Lisp or a candidate file.

(defclass recorded-evidence ()
  ((file :initarg :file :reader evidence-file :documentation "Path under docs/topic-maps-deployment/evidence/.")
   (kind :initarg :kind :reader evidence-kind)
   (when :initarg :when :reader evidence-when :documentation "UTC times of the run, as the record or its run log states them.")
   (environment :initarg :environment :reader evidence-environment)
   (procedure :initarg :procedure :reader evidence-procedure :documentation "Objects: functions, candidate files, excerpts.")
   (procedure-note :initarg :procedure-note :initform nil :reader evidence-procedure-note)
   (outcome-pattern :initarg :outcome-pattern :reader evidence-outcome-pattern
                    :documentation "Substrings that mark the lines stating the outcome."))
  (:documentation "One recorded run of a test procedure, as a file of the candidate."))
(defmethod v:text-representation ((e recorded-evidence)) (evidence-kind e))

(defun evidence-pathname (evidence) (root-path (concatenate 'string "docs/topic-maps-deployment/evidence/" (evidence-file evidence))))
(defun evidence-text (evidence) (uiop:read-file-string (evidence-pathname evidence)))
(defun evidence-outcomes (evidence)
  "The lines of the record that state its outcome, in order."
  (remove-if-not (lambda (line) (some (lambda (pattern) (search pattern line)) (evidence-outcome-pattern evidence)))
                 (uiop:split-string (evidence-text evidence) :separator '(#\Newline))))
(defun evidence-candidate-file (evidence)
  (file-named (concatenate 'string "docs/topic-maps-deployment/evidence/" (evidence-file evidence))))

(defun test-procedure (system-package) (symbol-function (find-symbol "RUN-TESTS" system-package)))

(defvar *evidence* nil)
(defun all-evidence ()
  (or *evidence*
      (setf *evidence*
            (flet ((record (file kind when environment procedure patterns &optional note)
                     (make-instance 'recorded-evidence :file file :kind kind :when when :environment environment
                                    :procedure procedure :outcome-pattern patterns :procedure-note note)))
              (list
               (record "archive-verification.json" "Archive verified against the commit (Git, Nix)"
                       "2026-10-26 11:06:36–11:06:40 UTC" "Python 3.14, Git 2.50.1, Determinate Nix 3.11.2; reads the topic-maps repository only"
                       (list (file-named "scripts/topic-maps-snapshot.py") (excerpt "snapshot:attributes"))
                       '("\"success\"" "\"files\"" "\"narHash\"" "\"commit\"" "\"rootTree\"" "\"excluded\"" "=set\"" "=unset\"" "=lf\""))
               (record "archive-controls.log" "The archive verifier refuses altered archives"
                       "2026-10-26, after 11:06:40 UTC" "Python 3.14; altered copies in a temporary directory"
                       (list (file-named "tests/test_topic_maps_snapshot.py")) '("... ok" "Ran " "OK" "FAIL"))
               (record "package-check/lisp.log" "Package contract: Lisp suites in the build sandbox"
                       "2026-10-26 11:05:14–11:07:38 UTC (checks.x86_64-darwin.catalog-topic-maps)"
                       "Nix build sandbox, SBCL 2.4.10, empty HOME and XDG_CACHE_HOME, the package's own registry"
                       (list (excerpt "nix:check") (file-named "scripts/test-catalog-topic-maps.lisp")
                             (test-procedure :dreyeck/catalog-topic-maps/tests) (test-procedure :dreyeck/source-snapshot/tests)
                             (test-procedure :dreyeck/work/topic-maps-project-example/tests)
                             (test-procedure :dreyeck/work/topic-maps-ctm-review/tests))
                       '("ASDF-ORIGIN" "FASL-CACHE" "-PASS" "RUN-STARTED" "RUN-FINISHED"))
               (record "package-check/executable.log" "Package contract: the built executable"
                       "2026-10-26 11:05:14–11:07:38 UTC" "the built hyperdoc-catalog-topic-maps, poisoned PATH and ASDF configuration"
                       (list (file-named "tests/test_catalog_topic_maps_executable.py")) '("... ok" "Ran " "OK" "FAIL"))
               (record "package-check/topic-maps-asd" "Package contract: every topic-maps.asd in the registry"
                       "2026-10-26 11:05:14–11:07:38 UTC" "the check's shell, over every registry tree" (list (excerpt "nix:check")) '("topic-maps.asd"))
               (record "package-check/nix-build.log" "Package contract: the Nix build" "2026-10-26 11:05:14–11:07:38 UTC"
                       "nix build on x86_64-darwin" (list (excerpt "flake:check")) '("derivations will be built" "not valid" "error"))
               (record "production-check.log" "Production startup check on the candidate tree"
                       "2026-10-26 11:07:38–11:09:59 UTC (checks.x86_64-darwin.catalog)" "Nix build sandbox, x86_64-darwin"
                       (list (excerpt "flake:production") (excerpt "nix:production-wrapper")) '("Ran " "OK" "FAIL")
                       "The check is nix/catalog-check.nix, unchanged by the candidate.")
               (record "catalog-unchanged-x86_64-linux.json" "hyperdoc-catalog unchanged, x86_64-linux (evaluated)"
                       "2026-10-26 11:07:53 UTC" "nix derivation show --offline; nothing built"
                       (list (file-named "scripts/compare-catalog-derivation.py")) '("equalExcept" "inputDrvsEqual" "\"built\"" "\"drv\""))
               (record "catalog-unchanged-x86_64-darwin.json" "hyperdoc-catalog unchanged, x86_64-darwin (evaluated)"
                       "2026-10-26 11:08:09 UTC" "nix derivation show --offline; nothing built"
                       (list (file-named "scripts/compare-catalog-derivation.py")) '("equalExcept" "inputDrvsEqual" "\"built\"" "\"drv\""))
               (record "catalog-control-changed-wrapper.json" "Positive control: a changed wrapper is detected"
                       "2026-10-26, after 11:08:09 UTC" "a scratch clone of the base with one flag added to nix/catalog.nix"
                       (list (file-named "scripts/compare-catalog-derivation.py")) '("equalExcept" "inputDrvsEqual"))
               (record "checkout-review-22u.log" "Review and 22U suites from the Git checkout" "2026-10-26 11:05:39–11:06:36 UTC"
                       "fresh SBCL 2.4.10, XDG_CACHE_HOME in the scratchpad, Topic Maps from the clean checkout"
                       (list (test-procedure :dreyeck/work/topic-maps-ctm-review/tests) (test-procedure :dreyeck/work/topic-maps-project-example/tests))
                       '("-PASS"))
               (record "checkout-source-snapshot.log" "Snapshot verifier from the Git checkout" "2026-10-26 11:05:39–11:06:36 UTC"
                       "fresh SBCL 2.4.10, HyperDoc from the checkout, the snapshot from the local store"
                       (list (test-procedure :dreyeck/source-snapshot/tests)) '("-PASS"))
               (record "browser-review-checkout.json" "CTM review in a browser, Topic Maps from the checkout"
                       "2026-10-26 11:00:54–11:01:46 UTC" "headless Chrome, sandboxed loopback server"
                       (list (file-named "scripts/test-topic-maps-ctm-review-browser.mjs"))
                       '("\"success\"" "\"topicMapsSourceKind\"" "\"startedAtUTC\"" "\"finishedAtUTC\"" "Claim" "Run "))
               (record "browser-review-snapshot.json" "CTM review in a browser, Topic Maps from the store snapshot"
                       "2026-10-26 11:01:46–11:02:34 UTC" "headless Chrome, sandboxed loopback server"
                       (list (file-named "scripts/test-topic-maps-ctm-review-browser.mjs"))
                       '("\"success\"" "\"topicMapsSourceKind\"" "\"startedAtUTC\"" "\"finishedAtUTC\"" "Claim" "Run "))
               (record "browser-22u-checkout.json" "22U navigation in a browser, from the checkout" "2026-10-26 11:02:57–11:03:38 UTC"
                       "headless Chrome, sandboxed loopback server" nil '("\"success\"" "\"startedAtUTC\"" "→")
                       "Its procedure is scripts/test-topic-maps-project-browser.mjs, unchanged by the candidate.")
               (record "mutants.log" "Mutants: the tests can fail" "2026-10-26 11:04:38 UTC (file written)"
                       "fresh SBCL 2.4.10, Topic Maps from the checkout" nil '("MUTANT")
                       "The mutant script is a scratch file of the session, not part of the candidate: this record says what was killed, but its procedure is not inspectable here.")
               (record "tested-files-sha256.txt" "The SHA-256 of every program and test file as tested"
                       "computed 2026-10-26 11:05:14 UTC, before the final runs" "shasum -a 256" nil '("  "))
               ;; The corrected guard (2026-10-27). The first runs' records above describe the first version and are unchanged.
               (record "after-guard-correction/contract-lisp.log" "Package contract Lisp suites, corrected candidate (by hand)"
                       "2026-10-27 15:54:33–15:55:54 UTC"
                       "pinned SBCL 2.4.10, the candidate's source as a store copy without .git, the verified snapshot, empty HOME and cache; NOT a Nix sandbox build"
                       (list (file-named "scripts/test-catalog-topic-maps.lisp") (test-procedure :dreyeck/catalog-topic-maps/tests)
                             (test-procedure :dreyeck/source-snapshot/tests) (test-procedure :dreyeck/work/topic-maps-project-example/tests)
                             (test-procedure :dreyeck/work/topic-maps-ctm-review/tests))
                       '("NOT A NIX" "-PASS" "RUN-STARTED" "RUN-FINISHED"))
               (record "after-guard-correction/asdf-methods.log" "ASDF method preservation, fresh process, before and after the guard"
                       "2026-10-27 15:55:54–15:56:12 UTC" "pinned SBCL 2.4.10, a store copy of the source, empty HOME and cache; NOT a Nix sandbox build"
                       (list (file-named "scripts/test-asdf-method-preservation.lisp"))
                       '("NOT A NIX" "ASDF-METHOD-PRESERVATION-PASS" "Counts" "behaviour after"))
               (record "after-guard-correction/executable.log" "Executable contract, corrected candidate (by hand)"
                       "2026-10-27 15:56:12–15:57:44 UTC" "a wrapper mirroring nix/catalog-topic-maps.nix, poisoned PATH and ASDF configuration; NOT a Nix sandbox build"
                       (list (file-named "tests/test_catalog_topic_maps_executable.py")) '("NOT A NIX" "... ok" "Ran " "OK" "FAIL"))
               (record "after-guard-correction/derivations-unchanged-x86_64-linux.json" "hyperdoc-catalog unchanged, x86_64-linux (evaluated), corrected candidate"
                       "2026-10-27 15:58 UTC" "nix derivation show --offline; nothing built"
                       (list (file-named "scripts/compare-catalog-derivation.py")) '("equalExcept" "inputDrvsEqual" "\"built\"" "\"drv\""))
               (record "after-guard-correction/derivations-unchanged-x86_64-darwin.json" "hyperdoc-catalog unchanged, x86_64-darwin (evaluated), corrected candidate"
                       "2026-10-27 15:58 UTC" "nix derivation show --offline; nothing built"
                       (list (file-named "scripts/compare-catalog-derivation.py")) '("equalExcept" "inputDrvsEqual" "\"built\"" "\"drv\""))
               (record "after-guard-correction/module-evaluation.json" "The staging module, evaluated in a minimal NixOS configuration"
                       "2026-10-27" "nix eval --offline --impure over nixpkgs from flake.lock; nothing built or started"
                       (list (file-named "nix/nixos-staging.nix")) '("wantedBy" "firewallPorts" "nginxEnabled" "HYPERDOC_CATALOG_HOST" "IPAddress"))
               (record "after-guard-correction/nix-darwin-blocker.log" "The Darwin Nix check did not build: an environment blocker"
                       "2026-10-27 15:59–16:13 UTC" "nix build --offline on the Darwin host: the stdenv bootstrap was garbage-collected from the local store and its sources return 404"
                       nil '("will be built" "error: Cannot build" "cannot download" "exit status")
                       "Not a result of the candidate: the failing derivations are the Darwin bootstrap. The by-hand runs of the corrected candidate are not a substitute and are not reported as a Nix build.")
               ;; x86_64-linux, in a local Docker builder (not the production server) with the Nix sandbox off.
               (record "after-guard-correction/x86_64-linux/nix-build.log" "The Nix build of the package and its check, x86_64-linux"
                       "2026-10-27 16:44:18–16:46:42 UTC" "a local Docker Desktop Linux VM (nixos/nix:2.31.1), Nix sandbox off; tree a2db814640299db0f0550a5d1ee2769d25128ea5"
                       (list (excerpt "flake:variant") (file-named "nix/catalog-topic-maps-check.nix"))
                       '("derivations will be built" "building" "nix build exit status" "start 20" "end 20"))
               (record "after-guard-correction/x86_64-linux/contract-lisp.log" "Package contract Lisp suites, x86_64-linux (kept by the Nix check)"
                       "2026-10-27, within the build above" "the Nix check's own environment on the Linux builder"
                       (list (file-named "scripts/test-catalog-topic-maps.lisp") (test-procedure :dreyeck/catalog-topic-maps/tests))
                       '("-PASS" "ASDF-ORIGIN topic-maps " "FASL-CACHE" "RUN-STARTED" "RUN-FINISHED"))
               (record "after-guard-correction/x86_64-linux/asdf-methods.log" "ASDF method preservation inside the Linux Nix check"
                       "2026-10-27, within the build above" "the Nix check's own environment on the Linux builder"
                       (list (file-named "scripts/test-asdf-method-preservation.lisp")) '("ASDF-METHOD-PRESERVATION-PASS" "Counts"))
               (record "after-guard-correction/x86_64-linux/executable.log" "Executable contract inside the Linux Nix check"
                       "2026-10-27, within the build above" "the Nix check's own environment on the Linux builder"
                       (list (file-named "tests/test_catalog_topic_maps_executable.py")) '("... ok" "Ran " "OK" "FAIL"))
               (record "after-guard-correction/x86_64-linux/builder-and-snapshot.txt" "The Linux builder, and the snapshot reconstructed there"
                       "2026-10-27" "the builder container; the archive added to its store by content, nothing published"
                       nil '("Builder:" "Nix sandbox" "Tree built" "sha256-" "octets" "x86_64-linux"))
               (record "after-guard-correction/x86_64-linux/packaged-reading.log" "This reading in the Linux package: suites, loopback start, shutdown"
                       "2026-10-27 16:56:32–17:00:30 UTC" "the built package's own wrapper environment; the source is a store path with no .git"
                       (list (file-named (concatenate 'string "docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/" "linux-validate.sh"))
                             (file-named "docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/reading-suites.lisp"))
                       '("PASS" "Project Workspace loaded" "listening" "0100007F" "HTTP 200" "shutdown exit status"))
               (record "after-guard-correction/x86_64-linux/browser-walk.json" "A browser walk through the Linux-served reading"
                       "2026-10-27" "Chrome and Playwright on the Mac, through a forwarder to a published port of the Linux builder; the executable stayed on its loopback"
                       (list (file-named "docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/walk-linux.mjs"))
                       '("\"success\"" "\"finishedAtUTC\"" "→"))
               ;; The same on the exact tree of commit 7080162b (git tree 057d303f7c79d0163b8a3ddf6876e990955093cf).
               (record "after-guard-correction/x86_64-linux/of-commit-7080162b/nix-build.log" "The Nix build on x86_64-linux of the exact tree of commit 7080162b"
                       "2026-10-27 17:11:55–17:14:50 UTC" "the local Docker Linux builder, Nix sandbox off; tree 057d303f7c79d0163b8a3ddf6876e990955093cf, reproduced by the builder's own git write-tree"
                       (list (excerpt "flake:variant") (file-named "nix/catalog-topic-maps-check.nix"))
                       '("derivations will be built" "building" "nix build exit status" "start 20" "end 20" "tree 057d303f"))
               (record "after-guard-correction/x86_64-linux/of-commit-7080162b/contract-lisp.log" "Package contract Lisp suites, the commit's own tree, x86_64-linux"
                       "2026-10-27, within the build above" "the Nix check's own environment on the Linux builder"
                       (list (file-named "scripts/test-catalog-topic-maps.lisp")) '("-PASS" "ASDF-ORIGIN topic-maps " "RUN-STARTED" "RUN-FINISHED"))
               (record "after-guard-correction/x86_64-linux/of-commit-7080162b/asdf-methods.log" "ASDF method preservation inside the Linux Nix check, the commit's own tree"
                       "2026-10-27, within the build above" "the Nix check's own environment on the Linux builder"
                       (list (file-named "scripts/test-asdf-method-preservation.lisp")) '("ASDF-METHOD-PRESERVATION-PASS" "Counts"))
               (record "after-guard-correction/x86_64-linux/of-commit-7080162b/executable.log" "Executable contract inside the Linux Nix check, the commit's own tree"
                       "2026-10-27, within the build above" "the Nix check's own environment on the Linux builder"
                       (list (file-named "tests/test_catalog_topic_maps_executable.py")) '("... ok" "Ran " "OK" "FAIL"))
               (record "after-guard-correction/x86_64-linux/of-commit-7080162b/packaged-reading.log" "This reading in the Linux package of the commit's own tree"
                       "2026-10-27 17:15:09–17:32:54 UTC" "the built package's own wrapper environment; the source is a store path with no .git"
                       (list (file-named "docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/linux-validate.sh"))
                       '("PASS" "Project Workspace loaded" "listening" "0100007F" "HTTP 200" "shutdown exit status"))
               (record "after-guard-correction/x86_64-linux/of-commit-7080162b/browser-walk.json" "A browser walk through the Linux-served reading of the commit's own tree"
                       "2026-10-27" "Chrome and Playwright on the Mac, through a forwarder to a published port; the executable stayed on its loopback"
                       (list (file-named "docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/walk-linux.mjs"))
                       '("\"success\"" "\"finishedAtUTC\"" "→"))
               (record "after-guard-correction/tested-files-sha256.txt" "The SHA-256 of every tested file, corrected candidate"
                       "computed 2026-10-27 before the runs, and equal after them" "shasum -a 256" nil '("  ")))))))
(defun evidence (file) (or (find file (all-evidence) :key #'evidence-file :test #'string=) (error "No evidence ~S." file)))

(v:defview recorded-evidence-view (evidence recorded-evidence)
  (v:html-view :title "Record" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (evidence-kind evidence)))
       (:p (:strong "Recorded run. ") (v:esc (format nil "~A; ~A. Showing this record runs nothing." (evidence-when evidence) (evidence-environment evidence))))
       (:p "Record: " (v:object-ref (evidence-candidate-file evidence) :select "Candidate file"))
       (:h3 "Procedure")
       (if (evidence-procedure evidence)
           (v:html (:ul (dolist (object (evidence-procedure evidence))
                          (v:html (:li (v:object-ref object :select (typecase object (function "Source code") (source-excerpt "Source excerpt")
                                                                      (candidate-file "Candidate file") (t nil))))))))
           (v:html (:p "No inspectable procedure.")))
       (when (evidence-procedure-note evidence) (v:html (:p (v:esc (evidence-procedure-note evidence)))))
       (:h3 "What it states")
       (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc (format nil "~{~A~^~%~}" (evidence-outcomes evidence))))
       (:details (:summary "The whole record")
                 (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere;max-height:40em;overflow:auto" (v:esc (evidence-text evidence))))
       (reading-links)))))
