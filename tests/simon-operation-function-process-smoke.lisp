;;;; Focused smoke tests for source-grounded Simon term senses.

(in-package :hyperdoc/tests)

(defparameter *simon-source-grounded-ids*
  '("simon-2018:1.2:observer"
    "simon-2018:1.3:second-order-observing"
    "simon-2018:1.4:reflexive-observation"
    "simon-2018:2.1:observing"
    "simon-2018:2.2:distinguishing"
    "simon-2018:2.2.2:inside-and-outside"
    "simon-2018:2.3:indicating"
    "simon-2018:2.5:boundary"
    "simon-2018:2.6:observation"
    "simon-2018:3.1:operation"
    "simon-2018:3.2:function-of-operation"
    "simon-2018:3.2.1:operation-consumes-time"
    "simon-2018:3.2.2:change-as-function"
    "simon-2018:3.2.3:preservation-as-function"
    "simon-2018:3.3:process"
    "simon-2018:3.4:effect-durability"
    "simon-2018:3.4.1:event-momentariness"
    "simon-2018:3.4.2:process-duration"))

(defparameter *simon-technical-homonym-ids*
  '("common-lisp:function"
    "asdf:operation"
    "asdf:action"
    "scxml:state"
    "scxml:transition"
    "scxml:event"
    "scxml:action-description"
    "hyperdoc:state-machine-run"
    "hyperdoc:event-record"
    "inspector:action-thunk"
    "operating-system:process"))

(defparameter *simon-expected-term-sense-ids*
  (append (copy-list *simon-source-grounded-ids*)
          (copy-list *simon-technical-homonym-ids*)))

(defun simon-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun simon-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun simon-assert-not-equal (left right message)
  (when (equal left right)
    (error "~A -- both values: ~S" message left)))

(defun simon-assert-signals-error (thunk message)
  (handler-case
      (progn
        (funcall thunk)
        (error "~A -- no error was signalled" message))
    (error () t)))

(defun simon-sense (id)
  (hyperdoc::simon-formen-term-sense id :signal-error-p t))

(defun simon-source-reference (id)
  (hyperdoc::source-grounded-term-sense-source-reference-of
   (simon-sense id)))

(defun simon-sense-hypothesis (id hypothesis-id)
  (find hypothesis-id
        (hyperdoc::source-grounded-term-sense-application-hypotheses-of
         (simon-sense id))
        :key (lambda (hypothesis) (getf hypothesis :id))
        :test #'string=))

(defun simon-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

;; Invariant 1: source senses and technical homonyms retain separate identities.
(defun simon-no-homonym-merging-smoke-test ()
  (dolist (pair '(("simon-2018:3.1:operation" "asdf:operation")
                  ("simon-2018:3.2:function-of-operation"
                   "common-lisp:function")
                  ("simon-2018:3.3:process" "operating-system:process")))
    (let ((source (simon-sense (first pair)))
          (technical (simon-sense (second pair))))
      (simon-assert-true
       (not (eq source technical))
       (format nil "Source and technical senses must be distinct: ~S" pair))
      (simon-assert-not-equal
       (hyperdoc::id-of source)
       (hyperdoc::id-of technical)
       "Source and technical senses must have distinct ids")
      (simon-assert-not-equal
       (hyperdoc::source-grounded-term-sense-domain-of source)
       (hyperdoc::source-grounded-term-sense-domain-of technical)
       "Source and technical senses must have distinct domains")))
  (dolist (pair '(("asdf:action" "asdf:operation")
                  ("scxml:state" "scxml:transition")
                  ("scxml:action-description" "inspector:action-thunk")
                  ("hyperdoc:state-machine-run" "hyperdoc:event-record")))
    (let ((left (simon-sense (first pair)))
          (right (simon-sense (second pair))))
      (simon-assert-true
       (not (eq left right))
       (format nil "Neighboring technical senses must be distinct: ~S" pair))
      (simon-assert-not-equal
       (hyperdoc::id-of left)
       (hyperdoc::id-of right)
       "Neighboring technical senses must have distinct ids")
      (simon-assert-not-equal
       (hyperdoc::source-grounded-term-sense-normalized-sense-of left)
       (hyperdoc::source-grounded-term-sense-normalized-sense-of right)
       "Neighboring technical senses must retain distinct meanings")))
  t)

;; Invariant 2: an ASDF operation description is not an operation event.
(defun simon-operation-description-is-not-operation-event-smoke-test ()
  (let ((asdf-sense (simon-sense "asdf:operation"))
        (simon-sense (simon-sense "simon-2018:3.1:operation")))
    (simon-assert-equal
     :technical-contract
     (hyperdoc::source-grounded-term-sense-definition-status-of asdf-sense)
     "ASDF operation must retain its technical definition status")
    (simon-assert-equal
     :normalized-source-sense
     (hyperdoc::source-grounded-term-sense-definition-status-of simon-sense)
     "Simon operation must retain its source-sense status")
    (simon-assert-equal
     nil
     (hyperdoc::source-grounded-term-sense-application-hypotheses-of asdf-sense)
     "An ASDF operation description must not fabricate an operation event"))
  t)

;; Invariant 3: an event type is not an event occurrence or its record.
(defun simon-event-type-is-not-event-occurrence-smoke-test ()
  (let ((event-type (simon-sense "scxml:event"))
        (event-record (simon-sense "hyperdoc:event-record")))
    (simon-assert-true
     (not (eq event-type event-record))
     "SCXML event type and HyperDoc event record must be distinct objects")
    (simon-assert-not-equal
     (hyperdoc::source-grounded-term-sense-normalized-sense-of event-type)
     (hyperdoc::source-grounded-term-sense-normalized-sense-of event-record)
     "Event type and event record must retain different meanings"))
  t)

;; Invariant 4: effect-as-function is not a Lisp function.
(defun simon-function-is-not-common-lisp-function-smoke-test ()
  (let ((effect (simon-sense "simon-2018:3.2:function-of-operation"))
        (lisp-function (simon-sense "common-lisp:function")))
    (simon-assert-true
     (member "common-lisp:function"
             (hyperdoc::source-grounded-term-sense-technical-homonym-ids-of
              effect)
             :test #'string=)
     "Simon function must name Common Lisp function only as a homonym")
    (simon-assert-true
     (not (eq effect lisp-function))
     "Simon function and Common Lisp function must be distinct objects"))
  t)

;; Invariant 5: a process requires ordering and a coupling criterion.
(defun simon-process-requires-order-and-coupling-smoke-test ()
  (simon-assert-signals-error
   (lambda ()
     (hyperdoc::make-source-grounded-process-description
      :operations '("op-a")
      :coupling-criterion "same maintained state"))
   "A process without temporal order must be rejected")
  (simon-assert-signals-error
   (lambda ()
     (hyperdoc::make-source-grounded-process-description
      :operations '("op-a")
      :temporal-order '((:single "op-a"))))
   "A process without coupling criterion must be rejected")
  (simon-assert-equal
   :simon-process-description
   (getf (hyperdoc::make-source-grounded-process-description
          :operations '("op-a")
          :temporal-order '((:single "op-a"))
          :coupling-criterion "same maintained state")
         :kind)
   "A process with order and coupling must be representable")
  t)

;; Invariant 6: concurrency is preserved rather than forcibly linearized.
(defun simon-concurrency-is-not-forced-linear-smoke-test ()
  (let* ((order '((:simultaneous "op-a" "op-b")
                  (:before "op-b" "op-c")))
         (process
           (hyperdoc::make-source-grounded-process-description
            :operations '("op-a" "op-b" "op-c")
            :temporal-order order
            :coupling-criterion "same larger unit")))
    (simon-assert-equal
     order
     (getf process :temporal-order)
     "Process description must retain simultaneous and partial order"))
  t)

;; Invariant 7: event, process, and effect time dimensions stay separate.
(defun simon-time-dimensions-remain-separate-smoke-test ()
  (let ((profile
          (hyperdoc::make-source-grounded-temporal-profile
           :event-duration :momentary
           :process-duration '(:interval 10 20)
           :effect-durability :persistent)))
    (simon-assert-equal :momentary (getf profile :event-duration)
                        "Event duration must be separately addressable")
    (simon-assert-equal '(:interval 10 20) (getf profile :process-duration)
                        "Process duration must be separately addressable")
    (simon-assert-equal :persistent (getf profile :effect-durability)
                        "Effect durability must be separately addressable")
    (simon-assert-true
     (not (member :duration profile))
     "A generic duration field must not be introduced"))
  t)

;; Invariant 8: observer attribution and general roles remain visible.
(defun simon-observer-attribution-remains-visible-smoke-test ()
  (let* ((hypothesis
           (simon-sense-hypothesis
            "simon-2018:3.1:operation"
            "hyperdoc:runtime-coherence-as-application-hypothesis"))
         (roles (getf hypothesis :roles)))
    (simon-assert-true hypothesis
                       "Runtime-coherence application hypothesis must exist")
    (dolist (role hyperdoc::+source-grounded-observation-roles+)
      (simon-assert-true
       (assoc role roles)
       (format nil "Application hypothesis must expose role ~S" role)))
    (simon-assert-true
     (every (lambda (entry)
              (hyperdoc::source-grounded-observation-role-p (car entry)))
            roles)
     "Runtime-specific actors must be values of general role keys"))
  t)

;; Invariant 9: source metadata and normalized wording stay precise.
(defun simon-source-provenance-remains-precise-smoke-test ()
  (dolist (id *simon-source-grounded-ids*)
    (let* ((sense (simon-sense id))
           (source (hyperdoc::source-grounded-term-sense-source-reference-of
                    sense)))
      (simon-assert-equal
       :human-review-of-direct-page-scan
       (getf source :verification-kind)
       (format nil "Simon sense ~A must retain the verification kind" id))
      (simon-assert-equal
       :normalized-paraphrase
       (getf source :wording-status)
       (format nil "Simon sense ~A must identify normalized wording" id))
      (simon-assert-equal
       nil
       (hyperdoc::source-grounded-term-sense-source-wording-of sense)
       (format nil "Simon sense ~A must not fabricate source wording" id))))
  t)

;; Invariant 10: application hypotheses are not emitted as source quotations.
(defun simon-application-hypotheses-are-not-quotes-smoke-test ()
  (let ((hypothesis
          (simon-sense-hypothesis
           "simon-2018:3.1:operation"
           "hyperdoc:runtime-coherence-as-application-hypothesis")))
    (simon-assert-equal
     :application-hypothesis
     (getf hypothesis :kind)
     "Runtime-coherence mapping must be marked as application hypothesis")
    (simon-assert-equal
     t
     (getf (getf hypothesis :evidence) :not-a-source-quotation)
     "Application hypothesis must state that it is not a source quotation"))
  t)

;; Invariant 11: a changing operation can be attributed a preserving function.
(defun simon-changing-operation-can-have-preserving-function-smoke-test ()
  (let ((operation
          (hyperdoc::make-source-grounded-operation-observation
           :observed-referent "gate signal"
           :boundary "outside/inside of a maintained room"
           :before :outside
           :after :inside
           :crossing-direction :outside-to-inside))
        (function
          (hyperdoc::make-source-grounded-function-attribution
           :function-form :preservation
           :observed-referent "maintained room state"
           :attributing-observer "reviewer")))
    (simon-assert-equal
     :outside-to-inside
     (getf operation :crossing-direction)
     "Operation must retain its direction of change")
    (simon-assert-equal
     :preservation
     (getf function :function-form)
     "The attributed function may be preservation"))
  t)

;; Invariant 12: change and preservation are different sense identities.
(defun simon-change-and-preservation-have-distinct-identities-smoke-test ()
  (let ((change (simon-sense "simon-2018:3.2.2:change-as-function"))
        (preservation
          (simon-sense "simon-2018:3.2.3:preservation-as-function")))
    (simon-assert-true
     (not (eq change preservation))
     "Change and preservation must be distinct objects")
    (simon-assert-not-equal
     (hyperdoc::id-of change)
     (hyperdoc::id-of preservation)
     "Change and preservation must have distinct stable ids"))
  t)

(defun simon-dependency-closure-has-no-dangling-reference-smoke-test ()
  (let ((senses (hyperdoc::simon-formen-source-grounded-senses)))
    (dolist (required-id *simon-source-grounded-ids*)
      (simon-assert-true
       (find required-id senses :key #'hyperdoc::id-of :test #'string=)
       (format nil "Required Simon foundation must be materialized: ~A"
               required-id)))
    (dolist (sense senses)
      (dolist (referenced-id
               (hyperdoc::source-grounded-term-sense-referenced-sense-ids
                sense))
        (simon-assert-true
         (find referenced-id senses :key #'hyperdoc::id-of :test #'string=)
         (format nil "Sense ~A has dangling reference ~A"
                 (hyperdoc::id-of sense)
                 referenced-id)))))
  t)

(defun simon-concept-ids-are-strings-smoke-test ()
  (dolist (sense (hyperdoc::simon-formen-source-grounded-senses))
    (simon-assert-true
     (stringp (hyperdoc::id-of sense))
     (format nil "Concept id must be a string, got ~S"
             (hyperdoc::id-of sense))))
  t)

(defun simon-exact-source-pages-smoke-test ()
  (dolist (pair '(("simon-2018:1.2:observer" 13)
                  ("simon-2018:1.3:second-order-observing" 13)
                  ("simon-2018:1.4:reflexive-observation" 13)
                  ("simon-2018:3.1:operation" 19)
                  ("simon-2018:3.2:function-of-operation" 19)
                  ("simon-2018:3.2.1:operation-consumes-time" 19)
                  ("simon-2018:3.2.2:change-as-function" 19)
                  ("simon-2018:3.2.3:preservation-as-function" 19)
                  ("simon-2018:3.3:process" 19)
                  ("simon-2018:3.4:effect-durability" 19)
                  ("simon-2018:3.4.1:event-momentariness" 20)
                  ("simon-2018:3.4.2:process-duration" 20)))
    (simon-assert-equal
     (second pair)
     (getf (simon-source-reference (first pair)) :page)
     (format nil "Source page must be exact for ~A" (first pair))))
  (dolist (id '("simon-2018:2.1:observing"
                "simon-2018:2.2:distinguishing"
                "simon-2018:2.2.2:inside-and-outside"
                "simon-2018:2.3:indicating"
                "simon-2018:2.5:boundary"
                "simon-2018:2.6:observation"))
    (let ((source (simon-source-reference id)))
      (simon-assert-equal nil (getf source :page)
                          "Unknown Chapter 2 page must not be guessed")
      (simon-assert-equal :not-recorded-in-current-slice
                          (getf source :page-status)
                          "Unknown Chapter 2 page must be explicit")))
  t)

(defun simon-invalid-function-form-is-rejected-smoke-test ()
  (simon-assert-signals-error
   (lambda ()
     (hyperdoc::make-source-grounded-function-attribution
      :function-form :change-or-preservation
      :observed-referent "state"
      :attributing-observer "reviewer"))
   ":change-or-preservation must be rejected")
  (dolist (valid '(:change :preservation :undetermined))
    (simon-assert-true
     (hyperdoc::source-grounded-function-form-p valid)
     (format nil "Required function form must be accepted: ~S" valid)))
  t)

(defun simon-operation-without-crossing-direction-is-rejected-smoke-test ()
  (simon-assert-signals-error
   (lambda ()
     (hyperdoc::make-source-grounded-operation-observation
      :observed-referent "technical state"
      :boundary "hypothetical boundary"
      :before :old
      :after :new))
   "A Simon-operation hypothesis without crossing direction must be rejected")
  t)

(defun simon-topic-and-inspector-handle-smoke-test ()
  (dolist (id *simon-expected-term-sense-ids*)
    (let* ((sense (simon-sense id))
           (views (simon-load-inspector-views-for-object sense)))
      (simon-assert-true
       (typep sense 'hyperdoc::source-grounded-term-sense)
       (format nil "Sense ~A must be inspectable as source-grounded-term-sense"
               id))
      (simon-assert-true
       (typep sense 'hyperdoc::topic)
       (format nil "Sense ~A must reuse the topic object contract" id))
      (simon-assert-true
       (hyperbook:find-page hyperdoc::*topics*
                            (hyperdoc::title-of sense)
                            :signal-error? t)
       (format nil "Sense ~A must resolve through the Topics hyperbook" id))
      (simon-assert-true
       (consp views)
       (format nil "Sense ~A must produce a non-empty inspector view list" id))))
  t)

(defun simon-technical-source-paths-exist-smoke-test ()
  (let ((root (asdf:system-source-directory :hyperdoc)))
    (dolist (sense (hyperdoc::simon-formen-source-grounded-senses))
      (when (eq :technical-homonym
                (hyperdoc::source-grounded-term-sense-domain-of sense))
        (let* ((reference
                 (hyperdoc::source-grounded-term-sense-source-reference-of
                  sense))
               (relative-path (getf reference :pathname))
               (pathname (merge-pathnames relative-path root)))
          (simon-assert-true
           (uiop:file-exists-p pathname)
           (format nil "Technical sense ~A must reference an existing file: ~A"
                   (hyperdoc::id-of sense)
                   pathname))
          (simon-assert-true
           (and (stringp (getf reference :symbol))
                (plusp (length (getf reference :symbol))))
           (format nil "Technical sense ~A must carry non-empty symbol metadata"
                   (hyperdoc::id-of sense)))))))
  t)

(defun simon-exact-materialized-id-set-smoke-test ()
  (let ((expected (sort (copy-list *simon-expected-term-sense-ids*)
                        #'string<))
        (actual
          (sort (mapcar #'hyperdoc::id-of
                        (hyperdoc::simon-formen-source-grounded-senses))
                #'string<)))
    (simon-assert-equal
     29
     (length expected)
     "The expected inventory must contain 18 Simon and 11 technical ids")
    (simon-assert-equal
     expected
     actual
     "The materialized inventory must equal the complete expected id set"))
  t)

(defparameter *simon-smoke-tests*
  (list
   (cons "01-no-homonym-merging"
         #'simon-no-homonym-merging-smoke-test)
   (cons "02-operation-description-not-event"
         #'simon-operation-description-is-not-operation-event-smoke-test)
   (cons "03-event-type-not-occurrence"
         #'simon-event-type-is-not-event-occurrence-smoke-test)
   (cons "04-effect-not-lisp-function"
         #'simon-function-is-not-common-lisp-function-smoke-test)
   (cons "05-process-order-and-coupling"
         #'simon-process-requires-order-and-coupling-smoke-test)
   (cons "06-concurrency-not-linearized"
         #'simon-concurrency-is-not-forced-linear-smoke-test)
   (cons "07-separated-time-dimensions"
         #'simon-time-dimensions-remain-separate-smoke-test)
   (cons "08-observer-attribution-visible"
         #'simon-observer-attribution-remains-visible-smoke-test)
   (cons "09-source-provenance-precise"
         #'simon-source-provenance-remains-precise-smoke-test)
   (cons "10-hypotheses-not-quotes"
         #'simon-application-hypotheses-are-not-quotes-smoke-test)
   (cons "11-changing-operation-preserving-function"
         #'simon-changing-operation-can-have-preserving-function-smoke-test)
   (cons "12-change-preservation-distinct"
         #'simon-change-and-preservation-have-distinct-identities-smoke-test)
   (cons "13-no-dangling-simon-reference"
         #'simon-dependency-closure-has-no-dangling-reference-smoke-test)
   (cons "14-string-concept-ids"
         #'simon-concept-ids-are-strings-smoke-test)
   (cons "15-exact-source-pages"
         #'simon-exact-source-pages-smoke-test)
   (cons "16-invalid-function-form-rejected"
         #'simon-invalid-function-form-is-rejected-smoke-test)
   (cons "17-crossing-direction-required"
         #'simon-operation-without-crossing-direction-is-rejected-smoke-test)
   (cons "18-topic-and-inspector-handle"
         #'simon-topic-and-inspector-handle-smoke-test)
   (cons "19-technical-source-paths-exist"
         #'simon-technical-source-paths-exist-smoke-test)
   (cons "20-exact-materialized-id-set"
         #'simon-exact-materialized-id-set-smoke-test)))

(defun run-simon-operation-function-process-smoke-tests ()
  (dolist (entry *simon-smoke-tests*)
    (format t "~&SIMON-TEST START ~A~%" (car entry))
    (funcall (cdr entry))
    (format t "SIMON-TEST PASS  ~A~%" (car entry)))
  (format t "SIMON-TESTS PASS count=~D~%" (length *simon-smoke-tests*))
  t)
