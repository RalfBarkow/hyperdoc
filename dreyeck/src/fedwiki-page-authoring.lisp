;;;; Capability-scoped edits of one local Federated Wiki page (M0)
;;;;
;;;; One operation: replace one Item of one page with an ordinary FedWiki
;;;; edit Action, if the page still holds exactly the Item the caller
;;;; observed. It is reachable only from trusted Lisp code. There is no HTTP
;;;; route, no session and no owner here; how an authenticated principal
;;;; would come to hold a capability is a later question.
;;;;
;;;; What is guaranteed, and no more:
;;;;
;;;;   - Authority: a FEDWIKI-PAGE-AUTHORING-CAPABILITY names a site root, a
;;;;     set of page slugs and the Action types it permits. Holding one is
;;;;     the authorization for the edits it names; nothing else is.
;;;;   - Address: a slug names exactly one direct child of the site's pages/
;;;;     directory (FEDWIKI-ASSETS). Nothing here takes a relative pathname.
;;;;   - Serialization: every edit of one page in this Lisp process runs its
;;;;     whole read, check, apply, persist and verify sequence under one lock
;;;;     for that (site root, slug). Another OS process, a Node wiki-server or
;;;;     an operator writing the file directly is not serialized.
;;;;   - Effect: the Journal gains the Action if and only if the Item changed.
;;;;     A refused edit changes no page byte.
;;;;   - Persistence: the new page is written to a fresh file beside the page
;;;;     and renamed over it, then read back and verified. Readers see the old
;;;;     page or the new one. Nothing is synced to the disk, so surviving a
;;;;     crash or power loss is NOT established.
;;;;
;;;; The expected Item is HyperDoc's validation evidence. It is compared and
;;;; never stored: the page keeps title, story and journal, and the journal
;;;; keeps the ordinary Action (type, id, item, date).

(in-package #:dreyeck/fedwiki-page-authoring)

;;; The capability

(defparameter +permitted-actions+ '("edit")
  "The FedWiki Action types this operation can apply at all.")

(defclass fedwiki-page-authoring-capability ()
  ((site-root :initarg :site-root :reader capability-site-root)
   (slugs :initarg :slugs :reader capability-slugs)
   (actions :initarg :actions :reader capability-actions))
  (:documentation "Authorization to apply ACTIONS to the pages SLUGS of the
local FedWiki site at SITE-ROOT, and nothing else. Made only by trusted Lisp
code; it is not a login, a session or an owner."))

(defun make-fedwiki-page-authoring-capability (site-root slugs &key (actions '("edit")))
  "A capability for SLUGS of the existing site SITE-ROOT. Every slug must be a
page slug and every action one this operation applies."
  (let ((root (truename (uiop:ensure-directory-pathname site-root))))
    (dolist (slug slugs) (fa:check-fedwiki-page-slug slug))
    (dolist (action actions)
      (unless (member action +permitted-actions+ :test #'equal)
        (error "~S is not an Action type this operation applies." action)))
    (make-instance 'fedwiki-page-authoring-capability
                   :site-root root
                   :slugs (remove-duplicates (copy-list slugs) :test #'equal)
                   :actions (remove-duplicates (copy-list actions) :test #'equal))))

(defmethod print-object ((capability fedwiki-page-authoring-capability) stream)
  (print-unreadable-object (capability stream :type t)
    (format stream "~A ~{~A~^ ~} [~{~A~^ ~}]" (namestring (capability-site-root capability))
            (capability-slugs capability) (capability-actions capability))))

(defun %check-capability (capability slug type)
  "Refuse unless CAPABILITY is one, SLUG is a page slug, and CAPABILITY covers
that page and the Action TYPE."
  (unless (typep capability 'fedwiki-page-authoring-capability)
    (%refuse :no-capability "~S is not a FedWiki page-authoring capability" capability))
  (fa:check-fedwiki-page-slug slug)
  (unless (member slug (capability-slugs capability) :test #'equal)
    (%refuse :outside-capability "the capability does not cover the page ~A" slug))
  (unless (member type (capability-actions capability) :test #'equal)
    (%refuse :action-not-permitted "the capability does not permit ~S" type)))

;;; The page lock

(defvar *page-locks* (make-hash-table :test #'equal)
  "One lock per canonical (site root, slug), made on first use and kept.")

(defvar *page-locks-lock* (bt:make-lock "FedWiki page lock table"))

(defun %page-lock (site-root slug)
  (let ((key (list (namestring site-root) slug)))
    (bt:with-lock-held (*page-locks-lock*)
      (or (gethash key *page-locks*)
          (setf (gethash key *page-locks*)
                (bt:make-lock (format nil "FedWiki page ~A" slug)))))))

(defun %call-with-page-lock (site-root slug thunk)
  (bt:with-lock-held ((%page-lock site-root slug))
    (funcall thunk)))

;;; The result

(defclass fedwiki-page-edit ()
  ((capability :initarg :capability :reader page-edit-capability)
   (slug :initarg :slug :reader page-edit-slug)
   (item-id :initarg :item-id :reader page-edit-item-id)
   (previous-item :initarg :previous-item :reader page-edit-previous-item)
   (action :initarg :action :reader page-edit-action))
  (:documentation "One applied and verified edit: the Item as it was and the
ordinary Action that replaced it, as the reread page showed it."))

(defmethod print-object ((edit fedwiki-page-edit) stream)
  (print-unreadable-object (edit stream :type t)
    (format stream "~A item ~A" (page-edit-slug edit) (page-edit-item-id edit))))

;;; The transaction

(defun edit-fedwiki-page-item (capability slug expected-item action)
  "Replace the Item ACTION names on the page SLUG with ACTION's item, if the
page holds that id exactly once and its Item equals EXPECTED-ITEM, and append
ACTION to the page's journal. Signals FEDWIKI-PAGE-EDIT-REFUSED, or
INVALID-FEDWIKI-PAGE-SLUG, without writing when anything does not hold.
Returns a FEDWIKI-PAGE-EDIT. The caller's objects are copied, never changed."
  (%check-capability capability slug (and (hash-table-p action) (%json-field action "type")))
  (let* ((site-root (capability-site-root capability))
         (path (fa:local-fedwiki-page-pathname site-root slug))
         (action (%copy-json action))
         (expected-item (%copy-json expected-item)))
    (%check-edit-action action expected-item)
    (%call-with-page-lock
     site-root slug
     (lambda ()
       (unless (probe-file path)
         (%refuse :no-page "there is no page ~A" slug))
       (let ((page (fa:read-local-fedwiki-page site-root slug))
             (id (%json-field action "id"))
             (item (%json-field action "item")))
         (multiple-value-bind (next index current) (%plan-edit page expected-item action)
           (mat:materialize-fedwiki-page-json next site-root slug :if-exists :supersede)
           (let* ((after (fa:read-local-fedwiki-page site-root slug))
                  (journal (coerce (or (%json-field after "journal") (vector)) 'list)))
             (unless (and (= (length (%story after)) (length (%story page)))
                          (%json-equal (nth index (%story after)) item)
                          (every (lambda (old new)
                                   (or (equal id (%json-field old "id")) (%json-equal old new)))
                                 (%story page) (%story after))
                          (= (length journal) (1+ (length (coerce (or (%json-field page "journal") (vector)) 'list))))
                          (%json-equal (car (last journal)) action))
               (%refuse :verification "the reread page ~A does not show exactly this edit" slug))
             (make-instance 'fedwiki-page-edit
                            :capability capability :slug slug :item-id id
                            :previous-item current :action action))))))))

;;; Inspection: what the objects say, with nothing to press and no pathnames
;;; to follow.

(defun %row (label value)
  (views:html (:tr (:td (views:esc label)) (:td (:code (views:esc value))))))

(views:defview fedwiki-page-authoring-capability-view
    (capability fedwiki-page-authoring-capability)
  (views:html-view :title "FedWiki page-authoring capability" :priority 1
    (views:html
      (:table :class "inspector-table"
        (%row "Site root" (namestring (capability-site-root capability)))
        (%row "Pages" (format nil "~{~A~^, ~}" (capability-slugs capability)))
        (%row "Allowed Actions" (format nil "~{~A~^, ~}" (capability-actions capability))))
      (:p (views:esc "Holding this object authorizes these edits and nothing else. It is not a login or an owner session.")))))

(views:defview fedwiki-page-edit-view (edit fedwiki-page-edit)
  (views:html-view :title "FedWiki page edit" :priority 1
    (let ((before (page-edit-previous-item edit))
          (after (%json-field (page-edit-action edit) "item")))
      (views:html
        (:table :class "inspector-table"
          (%row "Page" (page-edit-slug edit))
          (%row "Item id" (page-edit-item-id edit))
          (%row "Action" (format nil "~A, date ~A" (%json-field (page-edit-action edit) "type")
                                 (%json-field (page-edit-action edit) "date")))
          (%row "Verified" "reread: the Item equals the replacement, every other Item and the order are unchanged, the last journal entry is this Action"))
        (:h4 "Changed fields")
        (:table :class "inspector-table"
          (loop for field being the hash-keys of after
                unless (%json-equal (%json-field before field) (%json-field after field))
                  do (views:html
                       (:tr (:td (:code (views:esc field)))
                            (:td (:code (views:esc (princ-to-string (%json-field before field)))))
                            (:td (views:esc "→"))
                            (:td (:code (views:esc (princ-to-string (%json-field after field)))))))))))))
