;;;; Thin CLI for HyperDoc's localhost FedWiki journal commit gate

(require :asdf)
(asdf:load-system :hyperdoc)

(defun keywordize-json-key (key)
  (etypecase key
    (keyword key)
    (symbol (intern (string-upcase (string key)) :keyword))
    (string (intern (string-upcase key) :keyword))))

(defun json-object-alist-p (value)
  (and (listp value)
       (every #'(lambda (entry)
                  (and (consp entry)
                       (or (stringp (car entry))
                           (symbolp (car entry))
                           (keywordp (car entry)))))
              value)))

(defun normalize-journal-json (value &optional key)
  (labels ((normalize-type (type-value)
             (if (stringp type-value)
                 (intern (string-upcase type-value) :keyword)
                 type-value)))
    (cond
      ((hash-table-p value)
       (loop for json-key being each hash-key of value
             using (hash-value json-value)
             for normalized-key = (keywordize-json-key json-key)
             append (list normalized-key
                          (normalize-journal-json json-value normalized-key))))
      ((json-object-alist-p value)
       (loop for (json-key . json-value) in value
             for normalized-key = (keywordize-json-key json-key)
             append (list normalized-key
                          (normalize-journal-json json-value normalized-key))))
      ((stringp value)
       (if (eql key :type)
           (normalize-type value)
           value))
      ((vectorp value)
       (map 'list #'normalize-journal-json value))
      ((listp value)
       (mapcar #'normalize-journal-json value))
      (t value))))

(defun read-fedwiki-page-file (path)
  (with-open-file (stream path :direction :input :external-format :utf-8)
    (normalize-journal-json (shasht:read-json stream))))

(defun journal-gate-result (page)
  (let ((findings (hyperdoc::journalmatic-commit-gate-findings page)))
    (list :findings findings
          :pass? (hyperdoc::journalmatic-commit-gate-pass-p page))))

(defun main ()
  (let ((paths (uiop:command-line-arguments))
        (blocked nil))
    (when (null paths)
      (format *error-output*
              "Usage: sbcl --script tools/journal-gate.lisp <page.json> [<page.json> ...]~%")
      (uiop:quit 2))
    (dolist (path paths)
      (handler-case
          (let ((result (journal-gate-result (read-fedwiki-page-file path))))
            (format t "~&JOURNAL_GATE ~A ~S~%" path result)
            (unless (getf result :pass?)
              (setf blocked t)))
        (error (condition)
          (setf blocked t)
          (format t "~&JOURNAL_GATE ~A ~S~%"
                  path
                  (list :findings (list :script-error)
                        :pass? nil
                        :error (princ-to-string condition))))))
    (uiop:quit (if blocked 1 0))))

(main)
