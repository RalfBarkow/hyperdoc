;;;; Topic enrichment route definitions
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *topic-enrichment-route-definitions-source-pathname* nil)

(defparameter *topic-enrichment-route-definitions*
  '())

(defun topic-enrichment-route-definitions-source-pathname ()
  (or *topic-enrichment-route-definitions-source-pathname*
      (asdf:system-relative-pathname
       :hyperdoc
       "hyperdoc/topic-enrichment-route-data.lisp")))

(defun topic-enrichment-route-definition-by-id (id)
  (find id *topic-enrichment-route-definitions*
        :key (lambda (entry) (getf entry :id))))

(defun topic-enrichment-route-definition-entries-for-topic-id (topic-id)
  (remove-if-not (lambda (entry)
                   (string= topic-id (getf entry :topic-id)))
                 *topic-enrichment-route-definitions*))

(defun topic-enrichment-route-entry-for-topic-source (topic-id source-id)
  (find-if (lambda (entry)
             (and (string= topic-id (getf entry :topic-id))
                  (string= source-id (getf entry :source-id))))
           *topic-enrichment-route-definitions*))

(defun topic-enrichment-route-definition-form-p (form)
  (and (consp form)
       (symbolp (first form))
       (string= (symbol-name (first form)) "DEFPARAMETER")
       (symbolp (second form))
       (string= (symbol-name (second form))
                "*TOPIC-ENRICHMENT-ROUTE-DEFINITIONS*")))

(defun topic-enrichment-route-definition-bounds (&optional pathname)
  (let ((pathname (or pathname
                      (topic-enrichment-route-definitions-source-pathname))))
    (with-open-file (stream pathname :direction :input :external-format :utf-8)
      (loop with eof = (gensym "EOF")
            for start = (file-position stream)
            for form = (read stream nil eof)
            until (eq form eof)
            for end = (file-position stream)
            when (topic-enrichment-route-definition-form-p form)
              return (list :start start :end end :form form)
            finally
               (error "No *topic-enrichment-route-definitions* form found in ~A."
                      pathname)))))

(defun topic-enrichment-route-definition-entries-from-form (form)
  (let ((value-form (third form)))
    (cond
      ((and (consp value-form)
            (symbolp (first value-form))
            (string= (symbol-name (first value-form)) "QUOTE"))
       (copy-tree (second value-form)))
      (t
       (error "Unsupported route-definition value form ~S." value-form)))))

(defun reload-topic-enrichment-route-definitions! (&optional pathname)
  (let* ((pathname (or pathname
                       (topic-enrichment-route-definitions-source-pathname)))
         (bounds (topic-enrichment-route-definition-bounds pathname)))
    (setf *topic-enrichment-route-definitions*
          (topic-enrichment-route-definition-entries-from-form
           (getf bounds :form)))))

(defun topic-enrichment-route-definitions-form-string (entries)
  (with-output-to-string (stream)
    (let ((*print-pretty* t)
          (*print-right-margin* 90))
      (pprint `(defparameter *topic-enrichment-route-definitions*
                 ',entries)
              stream))
    (terpri stream)))

(defun topic-enrichment-replace-range (content start end replacement)
  (concatenate 'string
               (subseq content 0 start)
               replacement
               (subseq content end)))

(defun write-topic-enrichment-route-definitions! (entries &optional pathname)
  (let* ((pathname (or pathname
                       (topic-enrichment-route-definitions-source-pathname)))
         (bounds (topic-enrichment-route-definition-bounds pathname))
         (content (uiop:read-file-string pathname))
         (replacement (topic-enrichment-route-definitions-form-string entries))
         (updated (topic-enrichment-replace-range
                   content
                   (getf bounds :start)
                   (getf bounds :end)
                   replacement)))
    (with-open-file (stream pathname
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
      (write-string updated stream))
    (setf *topic-enrichment-route-definitions* entries)
    pathname))
