(DEFPACKAGE #:DREYECK/PAGE-ATTACHED-WORKSPACE-OFFER
  (:USE #:CL)
  (:EXPORT #:PAGE-ATTACHED-WORKSPACE-OFFER #:PAGE-ATTACHED-WORKSPACE-OF))

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

(DEFMETHOD HYPERBOOK:LOOKUP-PATH ((OFFER PAGE-ATTACHED-WORKSPACE-OFFER) PATH)
  (UNLESS (NULL PATH)
    (ERROR "Only root lookup is defined for ~S; got path ~S." OFFER PATH))
  (IF (SLOT-BOUNDP OFFER 'WORKSPACE)
      (PAGE-ATTACHED-WORKSPACE-OF OFFER)
      (LET* ((SLUG (PAGE-SLUG-OF OFFER))
             (WITNESS
              (DREYECK/PAGE-ATTACHED-SYSTEM-PROJECTION::RECONSTRUCT-PAGE-ATTACHED-WORKSPACE
               SLUG))
             (WORKSPACE (GETF WITNESS :WORKSPACE)))
        (UNLESS WORKSPACE
          (ERROR "Workspace reconstruction returned no workspace for ~S."
                 SLUG))
        (SETF (SLOT-VALUE OFFER 'WORKSPACE) WORKSPACE)
        WORKSPACE)))

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
