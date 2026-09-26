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

(define-condition fedwiki-page-edit-refused (error)
  ((reason :initarg :reason :reader page-edit-refusal-reason)
   (detail :initarg :detail :reader page-edit-refusal-detail))
  (:report (lambda (condition stream)
             (format stream "FedWiki page edit refused (~(~A~)): ~A"
                     (page-edit-refusal-reason condition)
                     (page-edit-refusal-detail condition))))
  (:documentation "Nothing was written, unless REASON is :VERIFICATION: then
the page was replaced and its reread did not show exactly this edit."))

(defun %refuse (reason control &rest arguments)
  (error 'fedwiki-page-edit-refused
         :reason reason :detail (apply #'format nil control arguments)))

;;; Parsed JSON, as shasht reads it: objects are EQUAL hash tables, arrays vectors.

(defun %json-field (object name)
  (multiple-value-bind (value present) (gethash name object)
    (and present (not (eq value :null)) value)))

(defun %json-array-p (value)
  (or (consp value) (and (vectorp value) (not (stringp value)))))

(defun %copy-json (value)
  (cond ((hash-table-p value)
         (let ((copy (make-hash-table :test (hash-table-test value))))
           (maphash (lambda (key item) (setf (gethash key copy) (%copy-json item))) value)
           copy))
        ((%json-array-p value) (map (if (listp value) 'list 'vector) #'%copy-json value))
        (t value)))

(defun %json-equal (a b)
  (cond ((and (hash-table-p a) (hash-table-p b))
         (and (= (hash-table-count a) (hash-table-count b))
              (loop for key being the hash-keys of a using (hash-value value)
                    always (multiple-value-bind (other present) (gethash key b)
                             (and present (%json-equal value other))))))
        ((and (%json-array-p a) (%json-array-p b))
         (and (= (length a) (length b)) (every #'%json-equal a b)))
        (t (equal a b))))

(defun %story (page) (coerce (or (%json-field page "story") (vector)) 'list))

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

(defun %check-edit-action (action expected-item)
  (unless (and (hash-table-p action) (equal "edit" (%json-field action "type")))
    (%refuse :malformed "only an ordinary FedWiki edit Action is applied"))
  (unless (and (stringp (%json-field action "id")) (hash-table-p (%json-field action "item")))
    (%refuse :malformed "an edit Action needs an id and an item"))
  (unless (hash-table-p expected-item)
    (%refuse :malformed "the expected Item is missing")))

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
       (let* ((page (fa:read-local-fedwiki-page site-root slug))
              (id (%json-field action "id"))
              (item (%json-field action "item"))
              (positions (loop for each in (%story page)
                               for index from 0
                               when (equal id (%json-field each "id")) collect index)))
         (unless (= 1 (length positions))
           (%refuse (if positions :duplicate-id :absent-id)
                    "the item id ~A occurs ~D times" id (length positions)))
         (let* ((index (first positions))
                (current (nth index (%story page))))
           (unless (%json-equal current expected-item)
             (%refuse :stale "the Item ~A is not the expected Item" id))
           (unless (equal id (%json-field item "id"))
             (%refuse :id-mismatch "the replacement has id ~S, the Action ~S"
                      (%json-field item "id") id))
           (when (%json-equal item current)
             (%refuse :no-change "the replacement equals the current Item"))
           (let ((next (%copy-json page)))
             (setf (gethash "story" next)
                   (let ((story (coerce (%story next) 'vector)))
                     (setf (aref story index) (%copy-json item))
                     story)
                   (gethash "journal" next)
                   (concatenate 'vector (or (%json-field next "journal") (vector))
                                (vector (%copy-json action))))
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
                              :previous-item current :action action)))))))))

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
