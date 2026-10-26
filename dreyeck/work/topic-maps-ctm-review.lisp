;;;; Optional local review: one falsifiable claim about the independent CTM reader, read, executed on request and inspected.
;;;; The claim, its inputs and the run are review objects. Topic Maps, Topics and conditions stay the reader's own objects.
(defpackage #:dreyeck/work/topic-maps-ctm-review
  (:use #:cl)
  (:local-nicknames (#:m #:topic-maps.tmdm) (#:ctm #:topic-maps.ctm) (#:cxtm #:topic-maps.cxtm)
                    (#:v #:html-inspector-views) (#:nav #:dreyeck/inspector/tmdm) (#:ev #:dreyeck/evaluation-record)
                    (#:git #:dreyeck/git) (#:ex #:dreyeck/work/topic-maps-project-example))
  (:export #:review-claim #:claim-named #:claims #:claim-id #:claim-status #:claim-runs
           #:review-input #:input-label #:input-role #:input-text
           #:review-observation #:observation-input #:observation-map #:observation-condition #:observation-cxtm
           #:observation-input-text #:observation-input-sha256 #:observation-input-role #:observation-input-label
           #:review-run #:run-claim #:run-observations #:run-evaluation #:run-reason #:run-topic-maps-revision
           #:observe-input #:evaluate-observations #:run-claim-experiment #:run-scheme-plus-experiment
           #:+document-iri+))
(in-package #:dreyeck/work/topic-maps-ctm-review)
(hyperdoc:see (hyperdoc:page "Reviewing the CTM Reader" :hyperbook "dreyeck/work/topic-maps-ctm-review"))

(defparameter +document-iri+ "http://review.invalid/topic-maps-ctm-review/scheme-plus.ctm"
  "The Document IRI of every review input. A review address, not a corpus case.")

;;; What is claimed, on which basis, and what would refute it

(defclass review-input ()
  ((label :initarg :label :reader input-label)
   (role :initarg :role :reader input-role)                      ; :experiment, :positive-control or :contrast
   (text :initarg :text :reader input-text)
   (expected :initarg :expected :reader input-expected))         ; the expected outcome, as a sentence
  (:documentation "One CTM text given to the reader. Kept in HyperDoc, apart from the CTM corpus."))
(defmethod v:text-representation ((input review-input)) (format nil "~(~A~) ~A" (input-role input) (input-label input)))

(defclass review-claim ()
  ((id :initarg :id :reader claim-id)
   (status :initarg :status :reader claim-status)                ; :executable or :proposed
   (statement :initarg :statement :reader claim-statement)
   (normative :initarg :normative :reader claim-normative)       ; plist: :source :section :productions :quote :retrieved :uncertainty
   (definitions :initarg :definitions :reader claim-definitions) ; symbols of the reader's own functions
   (files :initarg :files :reader claim-files)                   ; repository paths in the reviewed checkout
   (inputs :initarg :inputs :reader claim-inputs)
   (expected :initarg :expected :reader claim-expected)
   (refutation :initarg :refutation :reader claim-refutation)
   (runs :initform nil :accessor claim-runs))
  (:documentation "A claim about CTM correctness: its normative basis, the implementing definitions, a minimal counterexample
with controls, the expected behaviour and what would refute it. A proposed claim has no execution."))
(defmethod v:text-representation ((claim review-claim))
  (format nil "Review claim ~A (~(~A~))" (claim-id claim) (claim-status claim)))

(defparameter +ctm-html+ "https://www.isotopicmaps.org/ctm/ctm.html")
(defparameter +ctm-section-3-3-3+ "https://www.isotopicmaps.org/ctm/ctm.html#sec-creating-iris"
  "The anchor <a name=\"sec-creating-iris\"> of §3.3.3 in the consulted HTML.")
(defparameter +uncertainty+
  "Consulted on 2026-10-26 in the public HTML text of ISO/IEC 13250-6:2010 (100,227 octets, SHA-256 814194accd807fac4cb4cecdc38ee1c8edc6a969f4683d7990708baa5f83c9fd).
The published ISO edition was not consulted; its errata and any difference from the HTML are unknown. Production [6] is unambiguous in
the HTML; the character class of production [7] reads [^#x20#x9#xD#xA;].()] there, which is ambiguous.")

(defparameter *claims*
  (list
   (make-instance 'review-claim
     :id "scheme-plus" :status :executable
     :statement "Every iri-undelimited of production [7] is accepted as an IRI reference and denotes the same IRI as its delimited form; in particular a scheme containing +."
     :normative (list :source +ctm-html+ :link +ctm-section-3-3-3+ :section "3.3.3 Creating IRIs from strings"
                      :productions '("[6] schema-name: [a-zA-Z]+ [a-zA-Z0-9+-.]*"
                                     "[7] iri-undelimited: schema-name '://' ([;.)]* [^#x20#x9#xD#xA;].()]+ )+"
                                     "[8] iri-delimited: '<' ([^<>\"{}|^`\\] - [#x00-#x20])+ '>'")
                      :quote "The delimiters < and > are removed from iri-delimited"
                      :retrieved "2026-10-26"
                      :independent "RFC 3986 §3.1 also permits + in a scheme: ALPHA *( ALPHA / DIGIT / \"+\" / \"-\" / \".\" )."
                      :uncertainty +uncertainty+)
     :definitions '(topic-maps.ctm::next-token topic-maps.ctm::scan-name topic-maps.ctm::name-part-p topic-maps.ctm::scheme-p)
     :files '("src/ctm/lexer.lisp" "src/ctm/iri.lisp")
     :inputs (list (make-instance 'review-input :label "svn+ssh, undelimited" :role :experiment
                                  :text "svn+ssh://example.org/x - \"A\"."
                                  :expected "Read: one Topic with subject identifier svn+ssh://example.org/x named A, with the CXTM of the positive control.")
                   (make-instance 'review-input :label "svn+ssh, delimited" :role :positive-control
                                  :text "<svn+ssh://example.org/x> - \"A\"."
                                  :expected "Read: one Topic with subject identifier svn+ssh://example.org/x named A.")
                   (make-instance 'review-input :label "http, undelimited" :role :contrast
                                  :text "http://example.org/x - \"A\"." :expected "Read: subject identifier http://example.org/x.")
                   (make-instance 'review-input :label "hyphen in the scheme, undelimited" :role :contrast
                                  :text "my-scheme://example.org/x - \"A\"." :expected "Read: subject identifier my-scheme://example.org/x.")
                   (make-instance 'review-input :label "dot in the scheme, undelimited" :role :contrast
                                  :text "a.b://example.org/x - \"A\"." :expected "Read: subject identifier a.b://example.org/x."))
     :expected "The experiment and the positive control give the same Topic Map: equal CXTM octets."
     :refutation "The positive control is read and the experiment is rejected: the reader refuses an input the grammar admits.")
   (make-instance 'review-claim
     :id "percent-identity" :status :proposed
     :statement "Delimited IRIs that differ only in %2F against / denote different subject identifiers."
     :normative (list :source +ctm-html+ :link +ctm-section-3-3-3+ :section "3.3.3 Creating IRIs from strings"
                      :quote "unescape the string by replacing %HH escape sequences"
                      :retrieved "2026-10-26"
                      :independent "RFC 3986 §6.2.2.2 and RFC 3987 §3.2 keep reserved percent escapes distinct, which conflicts with the CTM text."
                      :uncertainty +uncertainty+)
     :definitions '(topic-maps.ctm::unescape-iri topic-maps.ctm::resolve-iri)
     :files '("src/ctm/unicode.lisp" "src/ctm/iri.lisp")
     :inputs (list (make-instance 'review-input :label "%2F and /" :role :experiment
                                  :text "<http://ex.org/a%2Fb> - \"A\". <http://ex.org/a/b> - \"B\"."
                                  :expected "By the consulted CTM text, one merged Topic; by RFC 3986, two Topics."))
     :expected "A normative conflict to settle first: the implementation follows the consulted CTM text, and its tests assert the decoding."
     :refutation "Not stated: which claim an observation refutes depends on the norm that is chosen.")
   (make-instance 'review-claim
     :id "closing-parenthesis" :status :proposed
     :statement "An undelimited IRI may contain ) followed by further IRI characters, as production [7] appears to allow."
     :normative (list :source +ctm-html+ :link +ctm-section-3-3-3+ :section "3.3.3 Creating IRIs from strings"
                      :productions '("[7] iri-undelimited: schema-name '://' ([;.)]* [^#x20#x9#xD#xA;].()]+ )+")
                      :retrieved "2026-10-26"
                      :uncertainty (concatenate 'string +uncertainty+ " This candidate depends on exactly the garbled character class."))
     :definitions '(topic-maps.ctm::next-token)
     :files '("src/ctm/lexer.lisp")
     :inputs (list (make-instance 'review-input :label ") inside, undelimited" :role :experiment
                                  :text "http://example.org/a)b - \"A\"." :expected "Read: subject identifier http://example.org/a)b, if [7] reads as consulted."))
     :expected "Requires the ISO text of production [7] first."
     :refutation "Not stated until the production is settled.")))
(defun claims () (copy-list *claims*))
(defun claim-named (id) (find id *claims* :key #'claim-id :test #'string=))

;;; One input given to the reader: the reader's own result, or its own condition

(defclass review-observation ()
  ((input :initarg :input :reader observation-input)                 ; the input object, for navigation only
   (input-text :initarg :input-text :reader observation-input-text)   ; its text, copied when it was read
   (input-sha256 :initarg :input-sha256 :reader observation-input-sha256)
   (input-label :initarg :input-label :reader observation-input-label)
   (input-role :initarg :input-role :reader observation-input-role)
   (input-expected :initarg :input-expected :reader observation-input-expected)
   (map :initarg :map :initform nil :reader observation-map)
   (condition :initarg :condition :initform nil :reader observation-condition)
   (cxtm :initarg :cxtm :initform nil :reader observation-cxtm)
   (subject-identifiers :initarg :subject-identifiers :initform nil :reader observation-subject-identifiers)
   (names :initarg :names :initform nil :reader observation-names)
   (started :initarg :started :reader observation-started) (finished :initarg :finished :reader observation-finished)
   (identity :initform (gensym "CTM-REVIEW-OBSERVATION-") :reader observation-identity))
  (:documentation "What the reader did with one review input: the Topic Map it returned or the condition it signalled, both
retained as the original objects. The input's text, label, role and expectation are copied when it is read, with the SHA-256 of the
text's UTF-8 octets, so that a later change of the input object rewrites no observation. SUBJECT-IDENTIFIERS and NAMES are copied at
reading time, per named Topic."))
(defmethod v:text-representation ((o review-observation))
  (format nil "~A: ~:[~A~;Topic Map read~*~]" (observation-input-label o) (observation-map o)
          (and (observation-condition o) (type-of (observation-condition o)))))
(defun %sha256-of-text (text)
  (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets text :external-format :utf-8))))
(defun observe-input (input)
  "Copy the text, label, role and expectation of INPUT, give the copied text to the reader once, and keep its digest.
Signals nothing for a CTM-ERROR: the condition is the observation."
  (let* ((text (copy-seq (input-text input))) (label (copy-seq (input-label input)))
         (captured (list :input input :input-text text :input-sha256 (%sha256-of-text text) :input-label label
                         :input-role (input-role input) :input-expected (copy-seq (input-expected input))))
         (started (get-universal-time)))
    (handler-case
        (let* ((map (ctm:deserialize-string text :document-iri +document-iri+ :source-name label))
               (named (remove-if-not #'m:topic-names (m:topic-map-topics map))))
          (apply #'make-instance 'review-observation :map map :started started :finished (get-universal-time)
                 :cxtm (cxtm:canonicalize-octets map :base-locator +document-iri+)
                 :subject-identifiers (mapcar (lambda (tp) (mapcar #'copy-seq (m:topic-subject-identifiers tp))) named)
                 :names (mapcar (lambda (tp) (mapcar (lambda (n) (copy-seq (m:topic-name-value n))) (m:topic-names tp))) named)
                 captured))
      (ctm:ctm-error (condition)
        (apply #'make-instance 'review-observation :condition condition :started started :finished (get-universal-time) captured)))))
(defmethod ev:evaluation-specification-of ((o review-observation)) (observation-input o))
(defmethod ev:evaluation-input-of ((o review-observation)) (observation-input-text o))
(defmethod ev:evaluation-result-of ((o review-observation)) (or (observation-map o) (observation-condition o)))
(defmethod ev:evaluation-status-of ((o review-observation)) (if (observation-map o) :read :condition))
(defmethod ev:evaluation-trace-of ((o review-observation)) (if (observation-map o) '(:deserialized :canonicalized) '(:condition-signalled)))
(defmethod ev:evaluation-evidence-of ((o review-observation))
  (list :document-iri +document-iri+ :input-sha256 (observation-input-sha256 o) :cxtm (observation-cxtm o)))
(defmethod ev:evaluation-failure-of ((o review-observation)) (observation-condition o))
(defmethod ev:evaluation-started-at-of ((o review-observation)) (observation-started o))
(defmethod ev:evaluation-finished-at-of ((o review-observation)) (observation-finished o))
(defmethod ev:evaluation-identity-of ((o review-observation)) (observation-identity o))
(defmethod ev:evaluation-annotation-of ((o review-observation)) '(:scope :review-input-not-corpus-registration))

;;; The rule that turns observations into an evaluation, stated once

(defun %role (observations role) (find role observations :key #'observation-input-role))
(defun evaluate-observations (observations)
  "The evaluation of a run, from its observations alone, and the reason as a sentence:
:REFUTED   the positive control is read and the experiment is rejected (a CTM-REJECTION);
:CORROBORATED  both are read and their CXTM octets are equal;
:OPEN      anything else: the control is not read, the experiment is unsupported or reads differently.
Never PASS: an evaluation is about one claim and one input, not about conformance."
  (let ((experiment (%role observations :experiment)) (control (%role observations :positive-control)))
    (cond ((not (and experiment control (observation-map control)))
           (values :open "The positive control was not read, so the experiment cannot be interpreted."))
          ((and (observation-condition experiment) (typep (observation-condition experiment) 'ctm:ctm-rejection))
           (values :refuted "The positive control is read and the experiment is rejected: an input the grammar admits is refused."))
          ((and (observation-map experiment) (equalp (observation-cxtm experiment) (observation-cxtm control)))
           (values :corroborated "Experiment and positive control give equal CXTM octets."))
          (t (values :open "The experiment is neither rejected nor read to the control's Topic Map.")))))

;;; A run: every input of a claim, once, on explicit request

(defclass review-run ()
  ((claim :initarg :claim :reader run-claim)
   (observations :initarg :observations :reader run-observations)
   (evaluation :initarg :evaluation :reader run-evaluation) (reason :initarg :reason :reader run-reason)
   (topic-maps-revision :initarg :topic-maps-revision :reader run-topic-maps-revision)
   (hyperdoc-revision :initarg :hyperdoc-revision :reader run-hyperdoc-revision)
   (hyperdoc-dirty :initarg :hyperdoc-dirty :reader run-hyperdoc-dirty)
   (lisp :initform (format nil "~A ~A" (lisp-implementation-type) (lisp-implementation-version)) :reader run-lisp)
   (started :initarg :started :reader run-started) (finished :initarg :finished :reader run-finished)
   (identity :initform (gensym "CTM-REVIEW-RUN-") :reader run-identity))
  (:documentation "One explicit execution of a claim's inputs in this image, with the revisions it ran against."))
(defmethod v:text-representation ((run review-run))
  (format nil "Run of ~A: ~(~A~)" (claim-id (run-claim run)) (run-evaluation run)))
(defun %hyperdoc-state ()
  (let ((root (asdf:system-source-directory "dreyeck")))
    (values (git:trim-git-output (git:git-run-string root "rev-parse" "HEAD"))
            (plusp (length (git:git-run-string root "status" "--porcelain"))))))
(defun run-claim-experiment (claim)
  "Give each input of the executable CLAIM to the reader once, register each read Topic Map with its observation, and record the run.
Refuses a proposed claim and a Topic Maps checkout other than the pinned clean one."
  (unless (eq :executable (claim-status claim)) (error "~A is a proposed investigation, not an executable experiment." (claim-id claim)))
  (ex:checked-source-path)
  (multiple-value-bind (revision dirty) (%hyperdoc-state)
    (let* ((started (get-universal-time)) (observations (mapcar #'observe-input (claim-inputs claim))))
      (dolist (o observations) (when (observation-map o) (nav:register-execution (observation-map o) o)))
      (multiple-value-bind (evaluation reason) (evaluate-observations observations)
        (let ((run (make-instance 'review-run :claim claim :observations observations :evaluation evaluation :reason reason
                                  :topic-maps-revision ex:+source-revision+ :hyperdoc-revision revision :hyperdoc-dirty dirty
                                  :started started :finished (get-universal-time))))
          (push run (claim-runs claim))
          run)))))
(hyperdoc:defexample run-scheme-plus-experiment
  "Explicitly give the scheme-plus inputs to the pinned CTM reader once. Writes nothing."
  (run-claim-experiment (claim-named "scheme-plus")))
(defmethod ev:evaluation-specification-of ((run review-run)) (run-claim run))
(defmethod ev:evaluation-input-of ((run review-run)) (claim-inputs (run-claim run)))
(defmethod ev:evaluation-result-of ((run review-run)) (run-observations run))
(defmethod ev:evaluation-status-of ((run review-run)) (run-evaluation run))
(defmethod ev:evaluation-trace-of ((run review-run)) '(:checkout-checked :inputs-read :maps-registered :evaluated))
(defmethod ev:evaluation-evidence-of ((run review-run))
  (list :topic-maps-revision (run-topic-maps-revision run) :hyperdoc-revision (run-hyperdoc-revision run)
        :hyperdoc-dirty (run-hyperdoc-dirty run) :lisp (run-lisp run)
        :input-sha256 (mapcar (lambda (o) (cons (observation-input-label o) (observation-input-sha256 o))) (run-observations run))))
(defmethod ev:evaluation-failure-of ((run review-run)) nil)
(defmethod ev:evaluation-started-at-of ((run review-run)) (run-started run))
(defmethod ev:evaluation-finished-at-of ((run review-run)) (run-finished run))
(defmethod ev:evaluation-identity-of ((run review-run)) (run-identity run))
(defmethod ev:evaluation-annotation-of ((run review-run))
  (list :observed :reader-results :derived :conformance-assessment-on-the-consulted-text :scope :review-not-corpus-registration))

;;; Views. Rendering reads the claim and its runs; it executes, registers and writes nothing.

(defun %file-at-revision (path)
  (git:make-git-file-at-commit
   :commit (git:make-git-commit :repository (make-instance 'git:git-repository-checkout
                                                           :root (asdf:system-source-directory "topic-maps/ctm")
                                                           :root-source :asdf-system-source)
                                :commit-ish ex:+source-revision+)
   :path path))
(v:defview review-claim-view (claim review-claim)
  (v:html-view :title "Claim" :priority -10
    (let ((normative (claim-normative claim)) (run (first (claim-runs claim))))
      (v:html
        (:h2 (v:esc (format nil "Claim ~A" (claim-id claim))))
        (:p (:strong (v:esc (if (eq :proposed (claim-status claim))
                                "Proposed investigation: not executed, no finding."
                                "Executable experiment: runs only when its button is pressed."))))
        (:h3 "1. Claim") (:p (v:esc (claim-statement claim)))
        (:h3 "2. Normative basis")
        (:p (:a :href (getf normative :link) :target "_blank" :rel "noopener noreferrer" :class "ctm-review-normative-source"
                (v:esc (format nil "ISO/IEC 13250-6:2010 (public HTML), §~A" (getf normative :section))))
            (v:esc (format nil " — ~A, retrieved ~A." (getf normative :link) (getf normative :retrieved))))
        (dolist (production (getf normative :productions)) (v:html (:p (:code (v:esc production)))))
        (when (getf normative :quote) (v:html (:p (v:esc (format nil "Quoted: “~A”." (getf normative :quote))))))
        (when (getf normative :independent) (v:html (:p (v:esc (getf normative :independent)))))
        (:p (:em (v:esc (getf normative :uncertainty))))
        (:h3 "3. Implementation: loaded definitions")
        (:ul (dolist (symbol (claim-definitions claim))
               (v:html (:li (v:object-ref (symbol-function symbol) :display (string-downcase (symbol-name symbol)) :select "Source code")))))
        (:p "The same files at the reviewed revision:")
        (:ul (dolist (path (claim-files claim))
               (v:html (:li (v:object-ref (%file-at-revision path) :display (format nil "~A at ~A" path (subseq ex:+source-revision+ 0 8)) :select "Contents")))))
        (:p (v:object-ref (asdf:find-system "topic-maps/ctm") :display "ASDF system topic-maps/ctm"))
        (:h3 "4. Counterexample and controls")
        (:ul (dolist (input (claim-inputs claim))
               (v:html (:li (v:esc (format nil "~(~A~): " (input-role input))) (:code (v:esc (input-text input)))
                            (v:esc (format nil " — expected: ~A" (input-expected input)))))))
        (:h3 "5. Expected behaviour") (:p (v:esc (claim-expected claim)))
        (:p (v:esc (format nil "Refuted when: ~A" (claim-refutation claim))))
        (:h3 "6. Observed behaviour")
        (cond ((eq :proposed (claim-status claim)) (v:html (:p "No execution exists for a proposed investigation.")))
              (run (v:html (:p (v:object-ref run :display (format nil "Latest run in this image: ~(~A~)" (run-evaluation run)) :select "Execution"))))
              (t (v:html (:p "Not executed in this image."))))
        (when (eq :executable (claim-status claim))
          (v:html (:p (v:eval-button "Run the experiment" (v:thunk (run-scheme-plus-experiment)) "Run DEFEXAMPLE"))
                  (:p (v:object-ref #'run-scheme-plus-experiment :display "Example definition" :select "Source code"))))
        (:h3 "7. Evaluation")
        (:p (v:esc (if run (format nil "~(~A~) — observed in this image: ~A" (run-evaluation run) (run-reason run)) "Open: no execution in this image.")))
        (:p (v:object-ref #'evaluate-observations :display "The evaluation rule" :select "Source code"))
        (:h3 "8. Provenance")
        (:p (v:esc (format nil "Reviewed checkout: topic-maps at ~A, checked clean before every run. Review inputs are HyperDoc objects, not corpus cases: no corpus test case is registered or changed."
                           ex:+source-revision+)))
        (:p (v:esc "Runtime-local execution provenance is registered deliberately: each Topic Map a run reads is bound to its observation with register-execution, in this image only, and leads back to it through its Evidence view."))
        (:p (v:object-ref #'nav:register-execution :display "register-execution" :select "Source code"))))))
(v:defview review-run-view (run review-run)
  (v:html-view :title "Execution" :priority -10
    (v:html
     (:div :class "ctm-review-execution" :style "max-width:100%;overflow-wrap:anywhere"
      (:h2 (v:esc (format nil "Run of claim ~A" (claim-id (run-claim run)))))
      (:p (v:object-ref (run-claim run) :display "The claim" :select "Claim"))
      (:h3 "Observed: what the reader returned or signalled")
      ;; One block per observation. The full digest and the condition's report stay under Evidence, collapsed.
      (dolist (o (run-observations run))
        (let ((c (observation-condition o)))
          (v:html
            (:section :class "ctm-review-observation" :style "border-left:3px solid #ccc;padding-left:.8em;margin:1em 0"
              (:h4 (v:esc (format nil "~@(~A~): ~A" (substitute #\Space #\- (symbol-name (observation-input-role o))) (observation-input-label o))))
              (:dl
                (:dt (:strong "Input"))
                (:dd (:code :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc (observation-input-text o))))
                (:dt (:strong "Expected"))
                (:dd (v:esc (observation-input-expected o)))
                (:dt (:strong "Observed"))
                (:dd (if (observation-map o)
                         (v:html (v:object-ref (observation-map o) :display "Topic Map read" :select "Topics")
                                 (:br) (v:esc (format nil "Subject identifiers: ~{~{~A~^, ~}~^; ~}" (observation-subject-identifiers o)))
                                 (:br) (v:esc (format nil "Names: ~{~{~A~^, ~}~^; ~}" (observation-names o))))
                         (v:html (v:object-ref c :display (format nil "~A ~S" (type-of c) (ctm:error-code c)))
                                 (v:esc (format nil " at character ~D (line ~D, column ~D)." (ctm:error-position c) (ctm:error-line c)
                                                (ctm:error-column c))))))
                (:dt (:strong "Evidence"))
                (:dd (v:object-ref o :display "The observation")
                     (v:esc (format nil " — input SHA-256 ~A… of the UTF-8 octets as read" (subseq (observation-input-sha256 o) 0 12)))
                     (:details
                       (:summary "Full digest and diagnostic")
                       (:p "SHA-256 of the input text as read: " (:code (v:esc (observation-input-sha256 o))))
                       (if (observation-map o)
                           (v:html (:p (v:esc (format nil "Canonical CXTM: ~D octets." (length (observation-cxtm o))))))
                           (v:html (:p "The condition's report:")
                                   (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc (princ-to-string c))))))))))))
      (:h3 "Evaluation of this run")
      (:p (:strong (v:esc (format nil "~(~A~)" (run-evaluation run)))) (v:esc (format nil " — ~A" (run-reason run))))
      (:p (v:object-ref #'evaluate-observations :display "The evaluation rule" :select "Source code"))
      (:h3 "Derived: conformance assessment")
      (:p (v:esc (if (eq :refuted (run-evaluation run))
                     "Given productions [6] and [7] of §3.3.3 as published in the consulted HTML, the reader does not conform for this input. This is derived from the text, not observed; the published ISO edition was not consulted."
                     "No conformance assessment follows from this run.")))
      (:h3 "Provenance")
      (:p (v:esc (format nil "topic-maps ~A (clean, checked); HyperDoc ~A~:[~; with uncommitted changes~]; ~A; ~A to ~A (universal time)."
                         (run-topic-maps-revision run) (run-hyperdoc-revision run) (run-hyperdoc-dirty run) (run-lisp run)
                         (run-started run) (run-finished run))))))))

(hyperdoc:defhyperdoc *topic-maps-ctm-review*
  :title "Topic Maps CTM Review (22U)"
  :id "dreyeck/work/topic-maps-ctm-review"
  :asdf-system-name "dreyeck/work/topic-maps-ctm-review"
  :subdirectory "dreyeck/pages/topic-maps-ctm-review"
  :code-subdirectory "dreyeck/work/topic-maps-ctm-review"
  :main-page-id "Reviewing the CTM Reader")
