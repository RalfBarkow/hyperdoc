;;;; Compat shim: njson API subset

(in-package #:njson)

(defun %jzon-parse (input)
  (let* ((pkg (or (find-package "COM.INUOE.JZON")
                  (find-package "JZON")))
         (sym (and pkg (find-symbol "PARSE" pkg))))
    (unless (and sym (fboundp sym))
      (error "Could not resolve JSON parser in COM.INUOE.JZON/JZON package."))
    (funcall sym input)))

(defun decode (json &key (as :any))
  "Decode JSON using com.inuoe.jzon.
AS is accepted for compatibility but currently ignored."
  (declare (ignore as))
  (etypecase json
    (string (%jzon-parse json))
    (pathname (%jzon-parse (uiop:read-file-string json)))))

(defun jget (obj key &optional default)
  "Best-effort JSON 'get' compatible with common njson usage."
  (cond
    ((hash-table-p obj)
     (multiple-value-bind (v present?) (gethash key obj)
       (if present? v default)))
    ((and (listp obj) (consp (first obj)))
     (let ((cell (assoc key obj :test #'equal)))
       (if cell (cdr cell) default)))
    ((vectorp obj)
     (typecase key
       (integer (if (and (<= 0 key) (< key (length obj))) (aref obj key) default))
       (t default)))
    (t default)))
