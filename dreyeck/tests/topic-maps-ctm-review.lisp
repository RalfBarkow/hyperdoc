(defpackage #:dreyeck/work/topic-maps-ctm-review/tests
  (:use #:cl)
  (:local-nicknames (#:m #:topic-maps.tmdm) (#:ctm #:topic-maps.ctm) (#:r #:dreyeck/work/topic-maps-ctm-review)
                    (#:v #:html-inspector-views) (#:nav #:dreyeck/inspector/tmdm) (#:ev #:dreyeck/evaluation-record)
                    (#:ex #:dreyeck/work/topic-maps-project-example))
  (:export #:run-tests))
(in-package #:dreyeck/work/topic-maps-ctm-review/tests)
(defvar *checks* nil)
(defmacro check (label form)
  `(progn (unless ,form (error "CTM review check failed: ~A" ,label)) (push ,label *checks*)))
(defun view (object title)
  (let ((view (find title (v:all-views object) :key #'v:view-title :test #'equal)))
    (unless view (error "Missing Inspector view ~S on ~S" title object))
    (v:view-html view) view))
(defun refs (object title) (mapcar #'cdr (v:view-references (view object title))))
(defun html (object title) (v:view-html (view object title)))
(defun reviewed-file-digests ()
  "The SHA-256 of every file of the reviewed checkout that a claim names, read from the checkout's working tree."
  (loop for claim in (r:claims)
        append (loop for path in (dreyeck/work/topic-maps-ctm-review::claim-files claim)
                     collect (cons path (ironclad:byte-array-to-hex-string
                                         (ironclad:digest-file :sha256 (asdf:system-relative-pathname "topic-maps/ctm" path)))))))
(defun expected-source-kind ()
  "The source kind this run must find, stated by the caller and never inferred: a Git checkout unless
HYPERDOC_EXPECTED_TOPIC_MAPS_SOURCE says nix-store-snapshot."
  (let ((stated (uiop:getenv "HYPERDOC_EXPECTED_TOPIC_MAPS_SOURCE")))
    (cond ((member stated '(nil "" "git-checkout") :test #'equal) :git-checkout)
          ((equal stated "nix-store-snapshot") :nix-store-snapshot)
          (t (error "Unknown HYPERDOC_EXPECTED_TOPIC_MAPS_SOURCE ~S." stated)))))
(defun source-changes (system)
  "What would show the reviewed source changed: Git's status of the checkout, or a refusal of a fresh verification of the
store snapshot (which signals; a verified snapshot has no changes)."
  (let ((root (asdf:system-source-directory system)))
    (ecase (expected-source-kind)
      (:git-checkout (dreyeck/git:git-run-string root "status" "--porcelain"))
      (:nix-store-snapshot (dreyeck/source-snapshot:verify-store-snapshot root ex:+source-revision+) ""))))
(defun input (role label text) (make-instance 'r:review-input :role role :label label :text text :expected "test input"))

(defun run-tests ()
  (let* ((*checks* nil) (claim (r:claim-named "scheme-plus")) (digests (reviewed-file-digests))
         (topic-maps-status (source-changes "topic-maps/ctm")) (page-book "dreyeck/work/topic-maps-ctm-review")
         (page (hyperbook:find-page (hyperbook:find-hyperbook page-book :signal-error? t) "Reviewing the CTM Reader" :signal-error? t)))
    ;; The reviewed source: every Topic Maps system from the one pinned, clean checkout or its verified store snapshot,
    ;; and the kind is the one the caller stated.
    (check :topic-maps-source-kind-as-stated
           (eq (expected-source-kind) (dreyeck/source-snapshot:source-kind (asdf:system-source-directory "topic-maps/ctm"))))
    (check :source-evidence-of-the-stated-kind
           (eq (ex:source-evidence-kind (ex:checked-source-evidence))
               (if (eq :git-checkout (expected-source-kind)) :git-checkout :verified-nix-store-snapshot)))
    (check :topic-maps-systems-from-one-checkout
           (every (lambda (s) (equal (truename (asdf:system-source-directory s)) (truename (asdf:system-source-directory "topic-maps/ctm"))))
                  '("topic-maps" "topic-maps/tmdm" "topic-maps/cxtm" "topic-maps/project-work-example")))
    (check :reviewed-checkout-clean-before (zerop (length topic-maps-status)))
    ;; Rendering runs, registers and writes nothing: the page and every claim view, with the experiment instrumented.
    (let ((saved (symbol-function 'r:run-claim-experiment)) (calls 0) (runs (mapcar #'r:claim-runs (r:claims))))
      (unwind-protect
           (progn
             (setf (symbol-function 'r:run-claim-experiment) (lambda (c) (incf calls) (funcall saved c)))
             (dolist (view (v:all-views page)) (when (typep view 'v::html-view) (v:view-html view)))
             (dolist (c (r:claims)) (html c "Claim")))
        (setf (symbol-function 'r:run-claim-experiment) saved))
      (check :rendering-does-not-execute (zerop calls))
      (check :rendering-adds-no-run (equal runs (mapcar #'r:claim-runs (r:claims)))))
    ;; The Catalog page leads to the three claims through expressions that only name them.
    (let ((text (uiop:read-file-string (asdf:system-relative-pathname page-book "dreyeck/pages/topic-maps-ctm-review/Reviewing the CTM Reader.html"))))
      (check :page-names-every-claim
             (every (lambda (id) (search (format nil "claim-named &quot;~A&quot;" id) text)) '("scheme-plus" "percent-identity" "closing-parenthesis")))
      (check :page-separates-observed-and-derived (and (search "<strong>observed</strong>" text) (search "<strong>derived</strong>" text))))
    ;; The claim view: each of the eight parts, the loaded definitions as the actual function objects, the explicit button.
    (let ((text (html claim "Claim")) (references (refs claim "Claim")))
      (dolist (part '("1. Claim" "2. Normative basis" "3. Implementation" "4. Counterexample" "5. Expected" "6. Observed" "7. Evaluation" "8. Provenance"))
        (check (intern (format nil "CLAIM-PART-~A" (subseq part 0 1)) :keyword) (search part text)))
      (check :normative-source-and-uncertainty
             (and (search "https://www.isotopicmaps.org/ctm/ctm.html" text) (search "3.3.3" text) (search "[6] schema-name" text)
                  (search "published ISO edition was not consulted" text) (search "Production [6] is unambiguous" text)))
      (check :normative-source-is-a-link-to-section-3-3-3
             (some (lambda (quote) (search (format nil "href=~Ahttps://www.isotopicmaps.org/ctm/ctm.html#sec-creating-iris~A" quote quote) text))
                   '("'" "\"")))
      (check :registration-statement-accurate
             (and (search "no corpus test case is registered or changed" text)
                  (search "Runtime-local execution provenance is registered deliberately" text)
                  (not (search "nothing is registered" text))
                  (member #'nav:register-execution references :test #'eq)))
      (check :definitions-are-the-loaded-functions
             (every (lambda (s) (member (symbol-function s) references :test #'eq))
                    '(topic-maps.ctm::next-token topic-maps.ctm::scan-name topic-maps.ctm::name-part-p topic-maps.ctm::scheme-p)))
      (check :explicit-run-control-present
             (and (search "Run the experiment" text) (member #'r:run-scheme-plus-experiment references :test #'eq)))
      (check :unexecuted-claim-says-so (or (r:claim-runs claim) (search "Not executed in this image." text))))
    ;; Proposed investigations: no button, no run, and a run of them is refused.
    (dolist (id '("percent-identity" "closing-parenthesis"))
      (let* ((c (r:claim-named id)) (text (html c "Claim")))
        (check :proposed-has-no-run-control (not (search "Run the experiment" text)))
        (check :proposed-says-not-executed (search "Proposed investigation: not executed, no finding." text))
        (check :proposed-has-no-run (null (r:claim-runs c)))
        (check :proposed-run-refused (handler-case (progn (r:run-claim-experiment c) nil) (error () t)))))
    ;; The explicit run: expected against actual, the reader's own objects, and the evaluation.
    (let* ((run (r:run-scheme-plus-experiment)) (observations (r:run-observations run))
           (by-role (lambda (role) (remove role observations :key #'r:observation-input-role :test-not #'eq)))
           (experiment (first (funcall by-role :experiment))) (control (first (funcall by-role :positive-control)))
           (condition (r:observation-condition experiment)))
      (check :run-recorded-on-the-claim (eq run (first (r:claim-runs claim))))
      (check :control-read-as-expected
             (and (typep (r:observation-map control) 'm:topic-map)
                  (equal '(("svn+ssh://example.org/x")) (dreyeck/work/topic-maps-ctm-review::observation-subject-identifiers control))
                  (equal '(("A")) (dreyeck/work/topic-maps-ctm-review::observation-names control))))
      (check :experiment-rejected-with-the-original-condition
             (and (null (r:observation-map experiment)) (typep condition 'ctm:ctm-rejection)
                  (eq :invalid-occurrence-literal (ctm:error-code condition)) (= 3 (ctm:error-position condition))
                  (= 1 (ctm:error-line condition)) (= 4 (ctm:error-column condition))))
      (check :contrasts-read-their-own-iris
             (equal '((("http://example.org/x")) (("my-scheme://example.org/x")) (("a.b://example.org/x")))
                    (mapcar #'dreyeck/work/topic-maps-ctm-review::observation-subject-identifiers (funcall by-role :contrast))))
      (check :evaluated-refuted (eq :refuted (r:run-evaluation run)))
      (check :evaluation-record-protocol
             (and (eq claim (ev:evaluation-specification-of run)) (eq :refuted (ev:evaluation-status-of run))
                  (equal observations (ev:evaluation-result-of run)) (eq condition (ev:evaluation-result-of experiment))
                  (eq (r:observation-map control) (ev:evaluation-result-of control))
                  (string= ex:+source-revision+ (getf (ev:evaluation-evidence-of run) :topic-maps-revision))))
      (check :observed-and-derived-kept-apart
             (let ((annotation (ev:evaluation-annotation-of run)))
               (and (eq :reader-results (getf annotation :observed)) (getf annotation :derived))))
      ;; Navigation by the actual Inspector references: run → condition and Map; Map → its observation; claim → run.
      (let ((references (refs run "Execution")) (text (html run "Execution")))
        (check :run-view-holds-the-condition (member condition references :test #'eq))
        (check :run-view-holds-the-control-map (member (r:observation-map control) references :test #'eq))
        (check :run-view-leads-back-to-the-claim (member claim references :test #'eq))
        (check :run-view-separates-derived-assessment
               (and (search "Observed: what the reader returned or signalled" text) (search "Derived: conformance assessment" text)
                    (search "not observed" text)))
        (check :run-view-holds-each-observation (every (lambda (o) (member o references :test #'eq)) observations))
        (check :run-view-holds-the-evaluation-rule (member #'r:evaluate-observations references :test #'eq))
        ;; The run says how its sources are known, and a snapshot's verification is the object it refers to.
        (let ((evidence (ev:evaluation-evidence-of run)))
          (check :run-records-its-source-evidence
                 (if (eq :git-checkout (expected-source-kind))
                     (and (eq :git-checkout (getf evidence :topic-maps-source-evidence)) (search "clean Git checkout, checked by Git" text))
                     (and (eq :verified-nix-store-snapshot (getf evidence :topic-maps-source-evidence))
                          (search "verified /nix/store snapshot without .git, reports/ excluded" text)
                          (some (lambda (o) (typep o 'dreyeck/source-snapshot:snapshot-verification)) references))))
          (check :run-records-how-hyperdoc-is-known
                 (member (getf evidence :hyperdoc-revision-evidence) '(:git-checkout :asserted-by-nix-package))))
        ;; Each observation reads as Input, Expected, Observed and Evidence; the full digest and report are kept under Evidence.
        (flet ((occurrences (needle)
                 (loop for start = 0 then (1+ found) for found = (search needle text :start2 start) while found count t)))
          (check :run-view-observation-parts
                 (every (lambda (part) (= (length observations) (occurrences (format nil "<strong>~A</strong>" part))))
                        '("Input" "Expected" "Observed" "Evidence")))
          (check :run-view-full-evidence-collapsed
                 (and (= (length observations) (occurrences "<details"))
                      (every (lambda (o) (search (r:observation-input-sha256 o) text)) observations)
                      (search (cl-who:escape-string (princ-to-string condition)) text)))))
      (check :control-map-evidence-leads-to-its-observation
             (and (member control (nav:executions-of (r:observation-map control)) :test #'eq)
                  (member control (refs (r:observation-map control) "Evidence") :test #'eq)))
      (check :claim-view-leads-to-the-run (member run (refs claim "Claim") :test #'eq))
      (check :no-corpus-registration (eq :review-not-corpus-registration (getf (ev:evaluation-annotation-of run) :scope)))
      ;; A later change of an input object rewrites no observation: its text, digest and evaluation are those read.
      (let* ((input (r:observation-input experiment)) (original (copy-seq (r:input-text input)))
             (digest (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets original :external-format :utf-8))))
             (evidence (copy-tree (getf (ev:evaluation-evidence-of run) :input-sha256))) (string (r:input-text input)))
        (check :observation-text-and-digest-as-read
               (and (string= original (r:observation-input-text experiment)) (string= digest (r:observation-input-sha256 experiment))
                    (equal digest (cdr (assoc (r:observation-input-label experiment) evidence :test #'string=)))
                    (not (eq string (r:observation-input-text experiment)))))
        (unwind-protect
             (progn
               (setf (char string 0) #\X)                                           ; the input's own string, changed in place
               (check :in-place-change-not-in-the-observation (string= original (r:observation-input-text experiment)))
               (setf (slot-value input 'dreyeck/work/topic-maps-ctm-review::text) "http://example.org/changed - \"Z\"."
                     (slot-value input 'dreyeck/work/topic-maps-ctm-review::role) :contrast)
               (let ((text (html run "Execution")))
                 (check :changed-input-rewrites-no-observation
                        (and (string= original (r:observation-input-text experiment)) (string= digest (r:observation-input-sha256 experiment))
                             (eq :experiment (r:observation-input-role experiment))
                             (equal evidence (getf (ev:evaluation-evidence-of run) :input-sha256))
                             (eq :refuted (r:evaluate-observations observations))
                             ;; The view escapes the quotes of the text; its unquoted part and its digest are found as read.
                             (search (subseq original 0 (position #\" original)) text) (search digest text)
                             (not (search "http://example.org/changed" text))))))
          (setf (slot-value input 'dreyeck/work/topic-maps-ctm-review::text) original
                (slot-value input 'dreyeck/work/topic-maps-ctm-review::role) :experiment))))
    ;; The evaluation rule is not constant: real reader results that corroborate, and a broken control that leaves it open.
    (check :rule-can-corroborate
           (eq :corroborated (r:evaluate-observations
                              (list (r:observe-input (input :experiment "http undelimited" "http://example.org/x - \"A\"."))
                                    (r:observe-input (input :positive-control "http delimited" "<http://example.org/x> - \"A\"."))))))
    (check :rule-open-without-a-read-control
           (eq :open (r:evaluate-observations
                      (list (r:observe-input (input :experiment "svn+ssh undelimited" "svn+ssh://example.org/x - \"A\"."))
                            (r:observe-input (input :positive-control "unterminated" "<svn+ssh://example.org/x - \"A\"."))))))
    ;; Nothing written: the reviewed files and the reviewed checkout are unchanged.
    (check :reviewed-files-unchanged (equal digests (reviewed-file-digests)))
    (check :reviewed-checkout-clean-after (zerop (length (source-changes "topic-maps/ctm"))))
    (check :no-persistence-writer-loaded (not (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
    (format t "~&TOPIC-MAPS-CTM-REVIEW-PASS: ~D assertions; scheme-plus refuted by the reader's own condition, its control read, proposed claims unexecuted.~%"
            (length *checks*))
    t))
