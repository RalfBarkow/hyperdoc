;;;; An operation and the Lisp source definition it is for, before anything runs.
;;;;
;;;; A Binding answers which operation. It does not answer on what: its
;;;; TARGET-TYPE is a criterion, never an instance. The instance belongs to
;;;; the view in which an affordance was used. An OPERATION-REQUEST is the
;;;; two together, reified so that it can be inspected before anything
;;;; executes it, and so that different affordances can be seen to mean
;;;; the same thing.
;;;;
;;;; A definition name is not an occurrence: one page can contain two DEFUNs
;;;; with the same FORM-KEY. Keep the page, parser source snapshot and CST
;;;; character range together. A range addresses only that observed snapshot;
;;;; changing the source invalidates it rather than moving it to a namesake.

(defpackage #:dreyeck/gesture/operation-request
  (:use #:cl)
  (:local-nicknames (#:w #:dreyeck/gesture-binding-witness)
                    (#:wf #:dreyeck/workflow)
                    (#:hv #:html-inspector-views/standard)
                    (#:views #:html-inspector-views))
  (:export #:operation-request
           #:operation-request-operation
           #:operation-request-page
           #:operation-request-form-key
           #:operation-request-system
           #:operation-request-path
           #:source-occurrence
           #:occurrence-page #:occurrence-form-key #:occurrence-source
           #:occurrence-range #:page-occurrences #:occurrence-status
           #:resolve-occurrence #:stale-source-occurrence
           #:operation-request-occurrence
           #:page-definitions
           #:ensure-operation-request
           #:request-through-binding
           #:inspector-binding
           #:request-from-gesture
           #:gesture-target-view))

(in-package #:dreyeck/gesture/operation-request)

(defclass source-occurrence ()
  ((page :initarg :page :reader occurrence-page)
   (form-key :initarg :form-key :reader occurrence-form-key)
   (source :initarg :source :reader occurrence-source)
   (range :initarg :range :reader occurrence-range))
  (:documentation "One code-page top-level form in an observed source string.
RANGE is a half-open pair of CHARACTER OFFSETS into SOURCE, as produced by
CST:SOURCE on the parser's string stream, not byte offsets. Treat these
observations as immutable. FORM-KEY is consistency evidence, not a locator."))

(define-condition stale-source-occurrence (error)
  ((occurrence :initarg :occurrence :reader stale-occurrence))
  (:report (lambda (condition stream)
             (declare (ignore condition))
             (write-string "Stale authority: observe the code page again." stream))))

(defun %parse-page (page)
  (check-type page hyperdoc::code-page)
  (multiple-value-bind (code recovered)
      (hv:parse-lisp-code (hyperdoc::source-code-pathname page))
    (when recovered (error "Source required reader recovery."))
    code))

(defun page-occurrences (page)
  "Observe once. Both the snapshot and every range come from this parse result."
  (let* ((code (%parse-page page))
         (source (hv::source-of code)))
    (loop for form in (hv:top-level-forms-of code)
          for key = (wf:form-key (hv:s-exp form))
          when (and key (eq :definition (first key)))
            collect (make-instance 'source-occurrence :page page :form-key key
                                   :source source
                                   :range (copy-tree (concrete-syntax-tree:source
                                                      (hv:cst-of form)))))))

(defun page-definitions (page)
  "Compatibility enumeration of (FORM-KEY . TOPLEVEL-FORM), not an address."
  (loop for form in (hv:top-level-forms-of (%parse-page page))
        for key = (wf:form-key (hv:s-exp form))
        when (and key (eq :definition (first key))) collect (cons key form)))

(defun %current-source (occurrence)
  (alexandria:read-file-into-string
   (hyperdoc::source-code-pathname (occurrence-page occurrence))))

(defun occurrence-status (occurrence)
  "Read-only freshness check. An unavailable authority is also stale."
  (check-type occurrence source-occurrence)
  (if (handler-case (string= (%current-source occurrence)
                             (occurrence-source occurrence))
        (file-error () nil))
      :current :stale-authority))

(defun resolve-occurrence (occurrence)
  "Resolve the exact recorded range only while the entire snapshot is current.
No name search, relocation or replacement observation is permitted."
  (check-type occurrence source-occurrence)
  (unless (eq :current (occurrence-status occurrence))
    (error 'stale-source-occurrence :occurrence occurrence))
  (let ((source (occurrence-source occurrence))
        (range (occurrence-range occurrence)))
    (unless (and (consp range) (integerp (car range)) (integerp (cdr range))
                 (<= 0 (car range)) (< (car range) (cdr range))
                 (<= (cdr range) (length source)))
      (error "Invalid occurrence character range: ~S." range))
    (multiple-value-bind (code recovered) (hv:parse-lisp-code source)
      (when recovered (error "Occurrence snapshot required reader recovery."))
      (let ((matches
              (remove-if-not
               (lambda (form)
                 (equal range (concrete-syntax-tree:source (hv:cst-of form))))
               (hv:top-level-forms-of code))))
        (unless (= 1 (length matches))
          (error "Occurrence range must denote exactly one top-level form."))
        (unless (equal (occurrence-form-key occurrence)
                       (wf:form-key (hv:s-exp (first matches))))
          (error "Occurrence FORM-KEY does not match its recorded range."))
        (first matches)))))

(defclass operation-request ()
  ((operation :initarg :operation :reader operation-request-operation)
   (occurrence :initarg :occurrence :reader operation-request-occurrence))
  (:documentation "One operation on one observed source occurrence; no executor."))

(defun operation-request-page (request)
  (occurrence-page (operation-request-occurrence request)))

(defun operation-request-form-key (request)
  (occurrence-form-key (operation-request-occurrence request)))

(defmethod print-object ((request operation-request) stream)
  (print-unreadable-object (request stream :type t)
    (format stream "~A on ~S at ~S"
            (w:semantic-operation-identity-id (operation-request-operation request))
            (operation-request-form-key request)
            (occurrence-range (operation-request-occurrence request)))))

(defvar *requests* (make-hash-table :test #'equal)
  "EQUAL over operation, page, FORM-KEY, snapshot string and character range.
Operation and page compare by EQ; reparsed CST identity never participates.")

(defun %request-key (operation occurrence)
  (list operation (occurrence-page occurrence) (occurrence-form-key occurrence)
        (occurrence-source occurrence) (occurrence-range occurrence)))

(defun %as-occurrence (target form-key)
  "Legacy page/key callers may observe only an unambiguous definition.
Rendered affordances always pass their already captured occurrence instead."
  (if (typep target 'source-occurrence)
      target
      (let ((matches (remove form-key (page-occurrences target)
                             :key #'occurrence-form-key :test-not #'equal)))
        (unless (= 1 (length matches))
          (error "A page/key request requires exactly one definition: ~S." form-key))
        (first matches))))

(defun ensure-operation-request (operation target &optional form-key)
  (check-type operation w:semantic-operation-identity)
  (let ((occurrence (%as-occurrence target form-key)))
    (resolve-occurrence occurrence)
    (let ((key (%request-key operation occurrence)))
      (or (gethash key *requests*)
          (setf (gethash key *requests*)
                (make-instance 'operation-request
                               :operation operation :occurrence occurrence))))))

(defun request-through-binding (binding target &optional form-key)
  (unless (w:gesture-binding-enabled-p binding)
    (error "Binding ~A is not enabled." (w:gesture-binding-id binding)))
  (unless (eq :lisp-source-definition (w:gesture-binding-target-type binding))
    (error "Binding ~A does not apply to a Lisp source definition."
           (w:gesture-binding-id binding)))
  (ensure-operation-request (w:gesture-binding-operation binding) target form-key))

(defun inspector-binding ()
  (find "binding/inspector-insert-defexample" (w:make-gesture-binding-catalog)
        :key #'w:gesture-binding-id :test #'string=))

(defun operation-request-system (request)
  (asdf:component-name
   (asdf:component-system (hyperdoc:file-of (operation-request-page request)))))

(defun operation-request-path (request)
  (asdf:component-pathname (hyperdoc:file-of (operation-request-page request))))

(defun request-from-gesture (window)
  "The request a completed gesture asks for: its Binding's Operation on
the subject the gesture was pressed on. The Binding says which operation;
the subject, which the surface was given by its view, says on what."
  (multiple-value-bind (binding subject)
      (dreyeck/gesture/clog:gesture-window-selection window)
    (unless binding (error "The gesture has not completed with a Binding."))
    (request-through-binding binding (getf subject :occurrence))))

(defun %open-request (pane request)
  "Open REQUEST beside PANE, as an Inspector eval button would."
  (let ((inspector (clog-moldable-inspector::inspector pane)))
    (clog-moldable-inspector::close-panes-after inspector pane)
    (clog-moldable-inspector::create-pane inspector request)))

(defun gesture-target-view (occurrence)
  "The surface and the ordinary button share the row's exact observation."
  (make-instance 'clog-moldable-inspector:clog-view :title "Gesture" :priority 1
    :create-fn
    (lambda (pane parent)
      (dreyeck/gesture/clog:create-gesture-surface
       parent :subject (list :type :lisp-source-definition :occurrence occurrence)
       :width "224px" :height "32px"
       :on-completed (lambda (window)
                       (%open-request pane (request-from-gesture window)))))))

(views:defview code-page-operations (page hyperdoc::code-page)
  (views:html-view :title "Operations" :priority 12
    (let* ((binding (inspector-binding))
           (title (w:semantic-operation-identity-title
                   (w:gesture-binding-operation binding))))
      (views:html
        ;; A button in a view body gets none of the title bar's styling
        ;; and reads as a label; these rules make it look like the action
        ;; it is.
        (:style ".dreyeck-operation-requests button.inspector-action { border: 1px solid #777; border-radius: 3px; padding: 2px 8px; background: #fff; cursor: pointer; }
.dreyeck-operation-requests button.inspector-action:hover { background: #eee; }")
        (:p (views:esc "Each button asks for an operation on one definition and opens the request. A secondary-button gesture on the strip beside it asks for the same request: press and wait for the menu, or move at once to mark. Nothing is executed and no source is changed."))
        (:table :class "inspector-table dreyeck-operation-requests"
          (dolist (occurrence (page-occurrences page))
            (let ((key (occurrence-form-key occurrence)))
              (views:html
                (:tr (:td :colspan "2" (:tt (views:esc (prin1-to-string (second key))))))
                ;; Two cells, two pointer regions: a click on the button
                ;; and a press on the strip never reach each other.
                (:tr (:td (views:eval-button
                           title
                           (views:thunk (request-through-binding binding occurrence))))
                     (:td (views:transclusion (gesture-target-view occurrence))))))))))))

(views:defview operation-request-overview (request operation-request)
  (views:html-view :title "Request" :priority 1
    (let* ((operation (operation-request-operation request))
           (page (operation-request-page request))
           (occurrence (operation-request-occurrence request))
           (status (occurrence-status occurrence))
           (range (occurrence-range occurrence)))
      (views:html
        (:table :class "inspector-table"
          (:tr (:td "Operation")
               (:td (:tt (views:esc (w:semantic-operation-identity-id operation)))))
          (:tr (:td "Definition / FORM-KEY")
               (:td (:tt (views:esc (prin1-to-string (operation-request-form-key request))))))
          (:tr (:td "Code page") (:td (views:esc (hyperbook:path-item-of page))))
          (:tr (:td "Occurrence character range [start, end)")
               (:td (:tt (views:esc (prin1-to-string range)))))
          (:tr (:td "Status") (:td (views:esc (symbol-name status))))
          (:tr (:td "Executed") (:td "no -- a request holds no executor")))
        (when (eq :current status)
          (resolve-occurrence occurrence)
          (views:html
            (:pre (views:esc (subseq (occurrence-source occurrence)
                                    (car range) (cdr range))))))))))
