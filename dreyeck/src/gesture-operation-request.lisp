;;;; An operation and the Lisp source definition it is for, before anything runs.
;;;;
;;;; A Binding answers which operation. It does not answer on what: its
;;;; TARGET-TYPE is a criterion, never an instance. The instance belongs to
;;;; the view in which an affordance was used. An OPERATION-REQUEST is the
;;;; two together, reified so that it can be inspected before anything
;;;; executes it, and so that different affordances can be seen to mean
;;;; the same thing.
;;;;
;;;; The target is one top-level definition on a HyperDoc code page. No
;;;; existing object carries both halves of that address. The CODE-PAGE is
;;;; stable -- the HyperDoc returns the same page every time -- and knows
;;;; its ASDF component, hence system and path. The TOPLEVEL-FORM a Parse
;;;; tree row shows knows the definition, but a new one is made on every
;;;; parse, so it cannot carry identity. The request therefore holds the
;;;; page itself and the definition's FORM-KEY, the address by which an
;;;; insertion is later anchored.
;;;;
;;;; The identity is the operation and the target, and nothing else. Which
;;;; Binding was used is how the request was reached, not what was asked.

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
           #:page-definitions
           #:ensure-operation-request
           #:request-through-binding
           #:inspector-binding
           #:request-from-gesture
           #:gesture-target-view))

(in-package #:dreyeck/gesture/operation-request)

(defclass operation-request ()
  ((operation :initarg :operation :reader operation-request-operation)
   (page :initarg :page :reader operation-request-page)
   (form-key :initarg :form-key :reader operation-request-form-key))
  (:documentation
   "One operation asked of one Lisp source definition, and not yet executed.
There is no executor here and no slot that could hold one."))

(defmethod print-object ((request operation-request) stream)
  (print-unreadable-object (request stream :type t)
    (format stream "~A on ~S"
            (w:semantic-operation-identity-id (operation-request-operation request))
            (operation-request-form-key request))))

(defvar *requests* (make-hash-table :test #'equal)
  "Every request made in this image, by operation, page and form key.
EQUAL compares the operation and the page by EQ, which is their identity.")

(defun page-definitions (page)
  "The function definitions of code page PAGE, each as (FORM-KEY . TOPLEVEL-FORM).
Only DEFUN forms: an executable example exercises a function, and no
other kind of definition has been given an example yet."
  (loop for form in (hyperdoc::parsed-toplevel-forms page)
        for key = (wf:form-key (hv:s-exp form))
        when (and key (eq :definition (first key)))
          collect (cons key form)))

(defun ensure-operation-request (operation page form-key)
  "The request for OPERATION on the definition FORM-KEY of PAGE, made once.
A definition the page does not have is refused rather than requested."
  (check-type operation w:semantic-operation-identity)
  (check-type page hyperdoc::code-page)
  (unless (assoc form-key (page-definitions page) :test #'equal)
    (error "~S is not a function definition on ~A."
           form-key (hyperbook:path-item-of page)))
  (let ((key (list operation page form-key)))
    (or (gethash key *requests*)
        (setf (gethash key *requests*)
              (make-instance 'operation-request
                             :operation operation :page page
                             :form-key form-key)))))

(defun request-through-binding (binding page form-key)
  "What an affordance contributes: its Binding, and of that only the Operation.
The Binding's target type is checked as the criterion it is; the target
itself is PAGE's definition, supplied by whatever shows the page."
  (unless (w:gesture-binding-enabled-p binding)
    (error "Binding ~A is not enabled." (w:gesture-binding-id binding)))
  (unless (eq :lisp-source-definition (w:gesture-binding-target-type binding))
    (error "Binding ~A does not apply to a Lisp source definition."
           (w:gesture-binding-id binding)))
  (ensure-operation-request (w:gesture-binding-operation binding) page form-key))

(defun inspector-binding ()
  (find "binding/inspector-insert-defexample" (w:make-gesture-binding-catalog)
        :key #'w:gesture-binding-id :test #'string=))

(defun operation-request-system (request)
  (asdf:component-name
   (asdf:component-system (hyperdoc:file-of (operation-request-page request)))))

(defun operation-request-path (request)
  (asdf:component-pathname (hyperdoc:file-of (operation-request-page request))))

(defun %definition-text (page form)
  (destructuring-bind (start . end) (concrete-syntax-tree:source (hv:cst-of form))
    (subseq (alexandria:read-file-into-string (hyperdoc::source-code-pathname page))
            start end)))

(defun request-from-gesture (window)
  "The request a completed gesture asks for: its Binding's Operation on
the subject the gesture was pressed on. The Binding says which operation;
the subject, which the surface was given by its view, says on what."
  (multiple-value-bind (binding subject)
      (dreyeck/gesture/clog:gesture-window-selection window)
    (unless binding (error "The gesture has not completed with a Binding."))
    (request-through-binding binding (getf subject :page)
                             (getf subject :form-key))))

(defun %open-request (pane request)
  "Open REQUEST beside PANE, as an Inspector eval button would."
  (let ((inspector (clog-moldable-inspector::inspector pane)))
    (clog-moldable-inspector::close-panes-after inspector pane)
    (clog-moldable-inspector::create-pane inspector request)))

(defun gesture-target-view (page form-key)
  "A gesture surface for FORM-KEY on PAGE, to be transcluded into a row.
Each surface gets a subject of its own: the page and the key, as the view
that renders it has them."
  (make-instance 'clog-moldable-inspector:clog-view :title "Gesture" :priority
                 1 :create-fn
                 (lambda (pane parent)
                   (dreyeck/gesture/clog:create-gesture-surface parent :subject
                                                                (list :type
                                                                      :lisp-source-definition
                                                                      :page
                                                                      page
                                                                      :form-key
                                                                      form-key)
                                                                :width "224px"
                                                                :height "32px"
                                                                :on-completed
                                                                (lambda
                                                                    (window)
                                                                  (%open-request
                                                                   pane
                                                                   (request-from-gesture
                                                                    window)))))))

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
          (dolist (entry (page-definitions page))
            (let ((key (car entry)))
              (views:html
                (:tr (:td :colspan "2" (:tt (views:esc (prin1-to-string (second key))))))
                ;; Two cells, two pointer regions: a click on the button
                ;; and a press on the strip never reach each other.
                (:tr (:td (views:eval-button
                           title
                           (views:thunk (request-through-binding binding page key))))
                     (:td (views:transclusion (gesture-target-view page key))))))))))))

(views:defview operation-request-overview (request operation-request)
  (views:html-view :title "Request" :priority 1
    (let* ((operation (operation-request-operation request))
           (page (operation-request-page request))
           (entry (assoc (operation-request-form-key request)
                         (page-definitions page) :test #'equal)))
      (views:html
        (:table :class "inspector-table"
          (:tr (:td "Operation")
               (:td (:tt (views:esc (w:semantic-operation-identity-id operation)))))
          (:tr (:td "Definition")
               (:td (:tt (views:esc (prin1-to-string
                                     (operation-request-form-key request))))))
          (:tr (:td "Code page") (:td (views:esc (hyperbook:path-item-of page))))
          (:tr (:td "System") (:td (:tt (views:esc (operation-request-system request)))))
          (:tr (:td "Path")
               (:td (:tt (views:esc (namestring (operation-request-path request))))))
          (:tr (:td "Executed") (:td "no -- a request holds no executor")))
        (when entry
          (views:html
            (:pre (views:esc (%definition-text page (cdr entry))))))))))
