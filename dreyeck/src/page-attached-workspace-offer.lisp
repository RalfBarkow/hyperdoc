(DEFPACKAGE #:DREYECK/PAGE-ATTACHED-WORKSPACE-OFFER
  (:USE #:CL)
  (:EXPORT #:PAGE-ATTACHED-WORKSPACE-OFFER #:PAGE-ATTACHED-WORKSPACE-OF
   #:MATERIALIZE-PAGE-ATTACHED-WORKSPACE #:PAGE-SLUG-OF))

(IN-PACKAGE #:DREYECK/PAGE-ATTACHED-WORKSPACE-OFFER)



(DEFCLASS PAGE-ATTACHED-WORKSPACE-OFFER (HYPERBOOK:HYPERBOOK)
          ((TITLE :INITARG :TITLE :READER HYPERBOOK:TITLE-OF)
           (WORKSPACE :INITARG :WORKSPACE :READER PAGE-ATTACHED-WORKSPACE-OF)))

(DEFUN PAGE-SLUG-OF (OFFER)
  (LET* ((ID (HYPERBOOK:ID-OF OFFER))
         (PREFIX "workspace:")
         (PREFIX-LENGTH (LENGTH PREFIX)))
    (UNLESS
        (AND (STRINGP ID) (<= PREFIX-LENGTH (LENGTH ID))
             (STRING= PREFIX ID :END2 PREFIX-LENGTH))
      (ERROR "Not a page-attached workspace subject ID: ~S" ID))
    (LET ((SLUG (SUBSEQ ID PREFIX-LENGTH)))
      (WHEN (ZEROP (LENGTH SLUG))
        (ERROR "Empty page slug in workspace subject ID: ~S" ID))
      SLUG)))

(defun materialize-page-attached-workspace (offer)
  "Take OFFER from offered to materialized, once.

The one way an offer changes state. It used to be reachable only
through LOOKUP-PATH, so a second route — an inspector action calling
reconstruction directly — built a workspace without the offer noticing,
and built another on the next press. Two ways into one state
transition, with different results.

Returns the offer's workspace, reconstructing it on the first call and
returning the same object afterwards. Refusal lives in reconstruction
itself, so a runtime that does not run page-attached code refuses here
too, before anything is evaluated.

An already materialized offer is answered from the slot without asking
the policy, because handing back an object that exists executes
nothing. That is not a way around the refusal: a runtime that refuses
can never reach the state where the slot is bound."
  (if (slot-boundp offer 'workspace)
      (page-attached-workspace-of offer)
      (let* ((slug (page-slug-of offer))
             (witness
               (dreyeck/page-attached-system-projection:reconstruct-page-attached-workspace
                slug))
             (workspace (getf witness :workspace)))
        (unless workspace
          (error "Workspace reconstruction returned no workspace for ~S." slug))
        (setf (slot-value offer 'workspace) workspace)
        workspace)))

(DEFMETHOD HYPERBOOK:LOOKUP-PATH ((OFFER PAGE-ATTACHED-WORKSPACE-OFFER) PATH)
  (UNLESS (NULL PATH)
    (ERROR "Only root lookup is defined for ~S; got path ~S." OFFER PATH))
  ;; Delegates rather than repeating the transition.
  (materialize-page-attached-workspace OFFER))

;;;; The offer as something to read
;;
;; A catalog click inspects this object; it does not follow LOOKUP-PATH,
;; which stays what it has always been — the operator that materializes
;; a workspace from a path. So the offer needed something to show, and
;; showing it must not evaluate what it offers.
;;
;; Everything below is derived from the subject id by string surgery and
;; the layout convention. No ASDF, no probing, no reconstruction.

(defun page-attached-relative-asd (offer)
  "Where the offered artifact sits, relative to a site root."
  (let ((slug (page-slug-of offer)))
    (format nil "assets/pages/~A/~A.asd" slug slug)))

(html-inspector-views:defview page-attached-offer-overview
    (offer page-attached-workspace-offer)
  (html-inspector-views:html-view
      :title "Page-attached Workspace offer" :priority 1
    (let ((materialized (slot-boundp offer 'workspace))
          (permitted
            (uiop:symbol-call :dreyeck/page-attached-system-projection
                              :execution-permitted-p)))
      (html-inspector-views:html
        (:h2 (html-inspector-views:esc (hyperbook:title-of offer)))
        (:p (html-inspector-views:esc
             "A page carries an ASDF artifact. That is all this says. Whether a system can be built from it is a later question, and building one is a separate operation."))
        (:table :class "inspector-table"
          (:tr (:th "subject")
               (:td (html-inspector-views:esc (hyperbook:id-of offer))))
          (:tr (:th "page")
               (:td (html-inspector-views:esc (page-slug-of offer))))
          (:tr (:th "ASDF artifact")
               (:td (html-inspector-views:esc
                     (page-attached-relative-asd offer))))
          (:tr (:th "state")
               (:td (html-inspector-views:esc
                     (if materialized "materialized" "offered"))))
          (:tr (:th "workspace")
               (:td (html-inspector-views:esc
                     (if materialized "built in this image" "not materialized"))))
          (:tr (:th "reconstruction")
               (:td (html-inspector-views:esc
                     (if permitted
                         "available in this runtime"
                         "not available in this runtime")))))
        (when materialized
          (html-inspector-views:html
            (:p "Workspace: "
                (html-inspector-views:object-ref
                 (page-attached-workspace-of offer)))))
        (:p (html-inspector-views:esc
             (if permitted
                 "Reading this offer has evaluated nothing. Materializing would: it registers the system with ASDF, which runs the page's own definition file."
                 "Reading this offer has evaluated nothing, and this runtime would refuse to materialize it. The refusal is in the operation, not only in the absence of a button.")))))))
