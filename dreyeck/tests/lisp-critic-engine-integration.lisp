;;;; The trusted integration tests of the real Riesbeck/Beane Lisp Critic engine.
;;;;
;;;; The engine is not part of this repository. It is Zach Beane's 2004 archive of Chris Riesbeck's Lisp Critic, kept in a source station: the
;;;; assets of a wiki page, outside every checkout (dreyeck/tests/fixtures/lisp-critic/README.md says what the station must hold). The regular
;;;; tests, the Catalog test among them, therefore run without it and prove what can be proved without it: the book reports the absent engine
;;;; as absent, the recorded critiques are readable, the runtime refuses to load code that arrived with a page.
;;;;
;;;; What can only be proved with the engine is proved here, by running it, and nowhere else. These tests REFUSE to start without a station, with
;;;; a message that says why and how to provide one. They do not skip, and they do not stand in for the engine: a station that is missing,
;;;; incomplete, or an engine that runs but says nothing, fails them.
;;;;
;;;;   RUN-TESTS                        the engine itself: it is the one the committed records were made with (file digests), a CAR-CDR run
;;;;                                    completes with one critique that recommends CADR, the committed recorded run is still what the engine
;;;;                                    says, the three outcomes, source-backed transclusion, the engine reproduces both committed example
;;;;                                    evaluations, and the policy boundary with the engine behind it.
;;;;   RUN-PAGE-STATION-LAYOUT-TESTS    what the reading says about the wiki page's own station layout (its wrapper, definition, dependencies).
;;;;                                    These describe that page's files and need that page's station, not merely an engine.
;;;;   RUN-NEGATIVE-CONTROLS            RUN-TESTS shown to fail: without a station, with an empty one, and with an engine that runs and says nothing.
(defpackage #:dreyeck/lisp-critic/engine-integration/tests
  (:use #:cl)
  (:local-nicknames (#:reading #:dreyeck/lisp-critic/reading)
                    (#:rt #:dreyeck/lisp-critic/reading/tests)
                    (#:rec-tests #:dreyeck/lisp-critic/recorded/tests)
                    (#:critic #:dreyeck/lisp-critic)
                    (#:er #:dreyeck/evaluation-record)
                    (#:views #:html-inspector-views))
  (:export #:run-tests #:run-page-station-layout-tests #:run-negative-controls #:require-station
           #:check-the-engine-is-the-recorded-one #:check-the-real-car-cdr-run #:check-the-recorded-run-is-what-the-engine-says))
(in-package #:dreyeck/lisp-critic/engine-integration/tests)

(defun check (value control &rest arguments)
  (unless value (error (apply #'format nil control arguments)))
  value)

(defun require-station ()
  "A source station holding the engine, or an error that says what is missing. Never a skip."
  (multiple-value-bind (root source candidates) (reading::resolve-engine-asset-root)
    (unless root
      (error "ENGINE-INTEGRATION-REQUIRES-A-SOURCE-STATION: no source station was found, so the real engine cannot run and this test cannot pass. ~
It is not skipped. Looked in: ~{~A~^, ~}. Provide one: DREYECK_LISP_CRITIC_ROOT=<directory holding a-critic-for-lisp.asd and vendor/lisp-critic/> ~
(see dreyeck/tests/fixtures/lisp-critic/README.md)."
             (mapcar (lambda (candidate) (format nil "~A (~(~A~))" (cdr candidate) (car candidate))) candidates)))
    (let ((missing (reading::engine-station-files-missing)))
      (when missing
        (error "ENGINE-INTEGRATION-REQUIRES-A-SOURCE-STATION: the station ~A exists (~(~A~)) but lacks ~{~A~^, ~}; the engine cannot be loaded from it. This test is not skipped."
               root source missing)))
    root))

;;; The engine is the one the records were made with

(defun %committed-engine-digests ()
  "The file digests that the two committed example evaluations record for the engine, as an alist; the two records must agree."
  (flet ((digests (name)
           (with-open-file (stream (asdf:system-relative-pathname "dreyeck" (concatenate 'string "dreyeck/pages/lisp-critic/evaluations/" name))
                                   :external-format :utf-8)
             (let ((data (shasht:read-json stream)))
               (sort (map 'list (lambda (file) (cons (gethash "file" file) (gethash "sha256" file)))
                          (gethash "files" (gethash "engine" data)))
                     #'string< :key #'car)))))
    (let ((a (digests "setf-push-reading-plan.json")) (b (digests "x-plus-1-reading-outstanding-changes.json")))
      (check (equal a b) "The two committed evaluations disagree about the engine's files.")
      a)))

(defun %file-sha256 (pathname)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 pathname)))

(defun check-the-engine-is-the-recorded-one ()
  "Every engine file the committed records name is in the station, byte for byte. A station with another engine could run and still not be the
one whose output the records, and the reading, are about."
  (dolist (entry (%committed-engine-digests))
    (let ((pathname (reading::vendored-engine-file (car entry))))
      (check pathname "The station lacks the engine file ~A." (car entry))
      (check (equal (cdr entry) (%file-sha256 pathname))
             "The station's ~A is not the file the committed records were made with." (car entry))))
  t)

;;; The engine runs

(defun check-the-real-car-cdr-run ()
  "The CAR-CDR rule, run by the engine on (CAR (CDR ITEMS)): the book reports the engine executable, the run is completed, there is exactly one
critique, and it is the engine's recommendation CADR. Nothing here reads a record or stands in for the run."
  (let* ((match (reading:critic-match-example))
         (record (getf match :record)))
    (check (getf match :engine-available-p) "The book does not report the engine as reachable.")
    (check (eq :completed (er:evaluation-status-of record))
           "The CAR-CDR run did not complete: ~A" (er:evaluation-failure-of record))
    (check (= 1 (length (er:evaluation-result-of record)))
           "The CAR-CDR run produced ~D critiques instead of one." (length (er:evaluation-result-of record)))
    (check (search "CADR" (critic:critique-explanation-of (first (er:evaluation-result-of record))))
           "The engine's critique does not recommend CADR.")
    ;; :EXECUTABLE is what a completed run shows; it is checked after the run, which is what justifies it.
    (check (eq :executable (getf match :evidence-status)) "The status is ~S, not :EXECUTABLE." (getf match :evidence-status))
    (check (eq :executable (reading::runtime-evidence-status)) "The runtime's status is ~S, not :EXECUTABLE." (reading::runtime-evidence-status)))
  t)

(defun check-the-recorded-run-is-what-the-engine-says ()
  "The committed CAR-CDR record, which the regular tests read in place of the engine, is what the engine says now: rule, pattern, response and critiques."
  (flet ((parse (string) (with-input-from-string (stream string) (critic:read-critic-run-snapshot stream))))
    (let ((recorded (parse (rt:car-cdr-fixture-text)))
          (fresh (parse (critic:critic-run-snapshot-string (critic:car-cdr-critique-example)))))
      (flet ((rule (data) (let ((rule (gethash "rule" data)))
                            (list (gethash "name" rule) (gethash "pattern" rule) (coerce (gethash "response" rule) 'list))))
             (explanations (data) (map 'list (lambda (critique) (gethash "explanation" critique)) (gethash "critiques" data))))
        (check (equal (rule recorded) (rule fresh)) "The committed record's rule is not what the engine holds: ~S against ~S." (rule recorded) (rule fresh))
        (check (equal (explanations recorded) (explanations fresh))
               "The committed record's critiques are not what the engine says: ~S against ~S." (explanations recorded) (explanations fresh)))))
  t)

;;; The tiers

(defun run-tests ()
  "The real engine, in a runtime that has a station. Fails, visibly and at once, in one that has not."
  (let ((root (require-station)))
    (format t "~&ENGINE-INTEGRATION-STATION ~A~%" root)
    (check-the-engine-is-the-recorded-one)
    (check-the-real-car-cdr-run)
    (check-the-recorded-run-is-what-the-engine-says)
    (rt:check-outcomes)
    (rt:check-source-backing)
    (rec-tests:check-records-reproduce)
    (rt:check-policy-in-a-clean-image))
  (format t "~&ENGINE-INTEGRATION-PASS: the station holds the engine the records were made with; a real CAR-CDR run completed with one critique recommending CADR; the committed record is what the engine says; the three outcomes and the source-backed transclusion hold; the engine reproduced both committed example evaluations; the policy boundary holds with the engine behind it.~%")
  t)

(defun run-page-station-layout-tests ()
  "What the reading says about the wiki page's own station: its wrapper, its ASDF definition and dependencies, its files. Needs that page's station."
  (require-station)
  (rt:check-workspace-section)
  (rt:check-source-declaration)
  (rt:check-execution-policy)
  (rt:check-source-structure-projection)
  (format t "~&PAGE-STATION-LAYOUT-PASS: the reading's account of the page-attached station matches the station.~%")
  t)

;;; The integration test is shown to fail

(defun %write (pathname text)
  (ensure-directories-exist pathname)
  (with-open-file (out pathname :direction :output :if-exists :supersede :external-format :utf-8) (write-string text out)))

(defun %broken-engine-station (directory)
  "A station whose wrapper loads and whose engine files are present and say nothing: an engine that runs and finds nothing. The negative
control's input; it evaluates nothing and stands in for no engine."
  (%write (merge-pathnames "a-critic-for-lisp.asd" directory) "(asdf:defsystem \"a-critic-for-lisp\" :components ((:file \"wrapper\")))")
  (%write (merge-pathnames "wrapper.lisp" directory)
          "(defpackage :a-critic-for-lisp (:use :cl) (:export #:load-lisp-critic))
(in-package :a-critic-for-lisp)
(defun load-lisp-critic () (pushnew (merge-pathnames \"vendor/lisp-critic/\" (asdf:system-source-directory \"a-critic-for-lisp\")) asdf:*central-registry* :test #'equal) (asdf:load-system \"lisp-critic\"))")
  (%write (merge-pathnames "vendor/lisp-critic/lisp-critic.asd" directory) "(asdf:defsystem :lisp-critic)")
  (dolist (name '("tables.lisp" "write-wrap.lisp" "extend-match.lisp" "lisp-critic.lisp" "lisp-rules.lisp"))
    (%write (merge-pathnames name (merge-pathnames "vendor/lisp-critic/" directory)) "")))

(defun %run-in-a-child (root form)
  "Run FORM in a fresh image whose station is ROOT (NIL: none, with HOME and the site root empty). Returns (values exit-code output)."
  (let ((empty (uiop:ensure-directory-pathname (merge-pathnames (format nil "dreyeck-child-~36R/" (random (expt 36 8) (make-random-state t))) (uiop:temporary-directory)))))
    (ensure-directories-exist empty)
    (unwind-protect
         (let ((output (make-string-output-stream)))
           (multiple-value-bind (out err code)
               (uiop:run-program
                (list (namestring sb-ext:*runtime-pathname*) "--no-userinit" "--non-interactive"
                      "--eval" "(require :asdf)"
                      "--eval" (format nil "(asdf:load-asd ~S)" (asdf:system-source-file "dreyeck"))
                      "--eval" "(asdf:load-system \"dreyeck/lisp-critic/engine-integration/tests\")"
                      "--eval" form)
                :environment (append (list (format nil "DREYECK_LISP_CRITIC_ROOT=~A" (if root (uiop:native-namestring root) ""))
                                           (format nil "HOME=~A" (uiop:native-namestring empty))
                                           (format nil "HYPERDOC_FEDWIKI_SITE_ROOT=~A" (uiop:native-namestring empty)))
                                     (remove-if (lambda (entry) (or (uiop:string-prefix-p "DREYECK_LISP_CRITIC_ROOT=" entry) (uiop:string-prefix-p "HOME=" entry)
                                                                    (uiop:string-prefix-p "HYPERDOC_FEDWIKI_SITE_ROOT=" entry)))
                                                (sb-ext:posix-environ)))
                :output :string :error-output :output :ignore-error-status t)
             (declare (ignore err))
             (write-string out output)
             (values code (get-output-stream-string output))))
      (uiop:delete-directory-tree empty :validate t :if-does-not-exist :ignore))))

(defun run-negative-controls ()
  "RUN-TESTS must fail where it should: with no station, with an empty one, and with an engine that runs and says nothing. Each is run in a
fresh image and must end in failure with the message that names the cause."
  (let ((empty (uiop:ensure-directory-pathname (merge-pathnames (format nil "dreyeck-empty-~36R/" (random (expt 36 8) (make-random-state t))) (uiop:temporary-directory))))
        (broken (uiop:ensure-directory-pathname (merge-pathnames (format nil "dreyeck-broken-~36R/" (random (expt 36 8) (make-random-state t))) (uiop:temporary-directory))))
        (run "(dreyeck/lisp-critic/engine-integration/tests:run-tests)")
        (car-cdr "(progn (dreyeck/lisp-critic/engine-integration/tests:require-station) (dreyeck/lisp-critic/engine-integration/tests:check-the-real-car-cdr-run))"))
    (ensure-directories-exist empty)
    (%broken-engine-station broken)
    (unwind-protect
         (flet ((must-fail (label root form fragment)
                  (multiple-value-bind (code output) (%run-in-a-child root form)
                    (check (and code (/= 0 code)) "The integration test passed for: ~A.~%~A" label output)
                    (check (search fragment output) "The integration test failed for ~A, but not by ~S:~%~A" label fragment output))))
           ;; 1. no station: it refuses to start, and says so, rather than skipping
           (must-fail "no source station" nil run "ENGINE-INTEGRATION-REQUIRES-A-SOURCE-STATION")
           ;; 2. a station directory with nothing in it
           (must-fail "an empty station directory" empty run "lacks")
           ;; 3. an engine that is present, loads, and gives no critique: the CAR-CDR run is what must fail
           (must-fail "an engine that says nothing" broken car-cdr "did not complete"))
      (uiop:delete-directory-tree empty :validate t :if-does-not-exist :ignore)
      (uiop:delete-directory-tree broken :validate t :if-does-not-exist :ignore)))
  (format t "~&ENGINE-INTEGRATION-NEGATIVE-CONTROLS-PASS: the integration test fails with no station, with an empty one, and with an engine that says nothing.~%")
  t)
