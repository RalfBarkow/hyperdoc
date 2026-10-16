;;;; What one FedWiki edit Action would make of a page: checks and result only
;;;;
;;;; The checks of the page-authoring writer (M0) that need only the page, the
;;;; expected Item and the Action. They read no file, write nothing and hold
;;;; no capability, so a reading runtime can load them without the writer.
;;;; DREYECK/FEDWIKI-PAGE-AUTHORING imports these definitions and performs
;;;; the edit; nothing here does.

(defpackage #:dreyeck/fedwiki-page-edit-plan
  (:use #:cl)
  (:export #:plan-fedwiki-page-edit
           #:fedwiki-page-edit-refused
           #:page-edit-refusal-reason #:page-edit-refusal-detail))

(in-package #:dreyeck/fedwiki-page-edit-plan)

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

(defun %check-edit-action (action expected-item)
  (unless (and (hash-table-p action) (equal "edit" (%json-field action "type")))
    (%refuse :malformed "only an ordinary FedWiki edit Action is applied"))
  (unless (and (stringp (%json-field action "id")) (hash-table-p (%json-field action "item")))
    (%refuse :malformed "an edit Action needs an id and an item"))
  (unless (hash-table-p expected-item)
    (%refuse :malformed "the expected Item is missing")))

(defun %plan-edit (page expected-item action)
  "PAGE as ACTION would leave it, the replaced Item's index and the Item it
replaces, as three values; or a refusal. PAGE is not changed. Every check
that needs the page, and none that needs the capability or the file."
  (let* ((id (%json-field action "id"))
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
        (values next index current)))))

(defun plan-fedwiki-page-edit (page expected-item action)
  "What EDIT-FEDWIKI-PAGE-ITEM would make of PAGE, a page's parsed JSON: the
next page JSON, the replaced Item's index and the Item it replaces, as three
values. The same checks of ACTION, EXPECTED-ITEM and PAGE, and only those:
it holds no capability, reads and writes no file, and permits nothing.
Signals FEDWIKI-PAGE-EDIT-REFUSED. The caller's objects are not changed."
  (let ((action (%copy-json action))
        (expected-item (%copy-json expected-item)))
    (%check-edit-action action expected-item)
    (%plan-edit (%copy-json page) expected-item action)))
