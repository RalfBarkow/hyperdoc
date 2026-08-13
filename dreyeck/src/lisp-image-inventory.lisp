(in-package #:dreyeck/lisp-image)

(defclass lisp-image-entry ()
  ((kind
    :initarg :kind
    :reader lisp-image-entry-kind)
   (symbol
    :initarg :symbol
    :reader lisp-image-entry-symbol
    :type symbol)
   (package-name
    :initarg :package-name
    :reader lisp-image-entry-package-name
    :type string)
   (symbol-status
    :initarg :symbol-status
    :reader lisp-image-entry-symbol-status)
   (page-id
    :initarg :page-id
    :reader lisp-image-entry-page-id
    :type string)))

(defmethod print-object ((entry lisp-image-entry) stream)
  (print-unreadable-object (entry stream :type t)
    (format stream "~A ~A"
            (lisp-image-entry-kind entry)
            (lisp-image-entry-page-id entry))))

(defclass lisp-image-inventory ()
  ((function-entries
    :initarg :function-entries
    :reader lisp-image-function-entries
    :initform nil)
   (class-entries
    :initarg :class-entries
    :reader lisp-image-class-entries
    :initform nil)))

(defmethod print-object ((inventory lisp-image-inventory) stream)
  (print-unreadable-object (inventory stream :type t)
    (format stream "~D function names, ~D class names"
            (length (lisp-image-function-entries inventory))
            (length (lisp-image-class-entries inventory)))))

(defun reader-token-escaped (string)
  (with-output-to-string (stream)
    (write-char #\| stream)
    (loop
      for character across string
      do (when (or (char= character #\\)
                   (char= character #\|))
           (write-char #\\ stream))
         (write-char character stream))
    (write-char #\| stream)))

(defun page-id-reads-as-symbol-p (page-id symbol)
  (handler-case
      (let ((*package* (find-package "CL")))
        (multiple-value-bind (object position)
            (read-from-string page-id)
          (and (= position (length page-id))
               (eq object symbol))))
    (error ()
      nil)))

(defun package-separator (status)
  (ecase status
    (:external ":")
    (:internal "::")))

(defun package-qualified-symbol-page-id (symbol)
  (let ((package (symbol-package symbol)))
    (when package
      (multiple-value-bind (found status)
          (find-symbol (symbol-name symbol) package)
        (when (and (eq found symbol)
                   (member status '(:external :internal)))
          (let* ((separator
                   (package-separator status))
                 (raw-page-id
                   (format nil "~A~A~A"
                           (package-name package)
                           separator
                           (symbol-name symbol)))
                 (page-id
                   (if (page-id-reads-as-symbol-p
                        raw-page-id
                        symbol)
                       raw-page-id
                       (format nil "~A~A~A"
                               (reader-token-escaped
                                (package-name package))
                               separator
                               (reader-token-escaped
                                (symbol-name symbol))))))
            (unless (page-id-reads-as-symbol-p
                     page-id
                     symbol)
              (error
               "Cannot construct a reader-safe page identifier for ~S."
               symbol))
            (values page-id status)))))))

(defun make-lisp-image-entry (kind symbol)
  (multiple-value-bind (page-id status)
      (package-qualified-symbol-page-id symbol)
    (when page-id
      (make-instance
       'lisp-image-entry
       :kind kind
       :symbol symbol
       :package-name (package-name (symbol-package symbol))
       :symbol-status status
       :page-id page-id))))

(defun collect-lisp-image-entries (kind predicate)
  (let (entries)
    (dolist (package
             (sort (copy-list (list-all-packages))
                   #'string<
                   :key #'package-name))
      (do-symbols (symbol package)
        (when (and
               ;; DO-SYMBOLS also sees inherited symbols.
               ;; Count a symbol only in its home package.
               (eq (symbol-package symbol) package)
               (funcall predicate symbol))
          (let ((entry
                  (make-lisp-image-entry kind symbol)))
            (when entry
              (push entry entries))))))
    (sort entries
          #'string<
          :key #'lisp-image-entry-page-id)))

(defun collect-lisp-function-entries ()
  (collect-lisp-image-entries
   :function
   #'fboundp))

(defun collect-lisp-class-entries ()
  (collect-lisp-image-entries
   :class
   (lambda (symbol)
     (find-class symbol nil))))

(defun make-lisp-image-inventory ()
  "Return a fresh inventory of function-bound and class-bound symbols in the running Lisp image."
  (make-instance
   'lisp-image-inventory
   :function-entries
   (collect-lisp-function-entries)
   :class-entries
   (collect-lisp-class-entries)))

(defun find-lisp-image-entry (page-id entries)
  (find page-id
        entries
        :test #'string=
        :key #'lisp-image-entry-page-id))

(defun lisp-image-entry-hyperbook (entry)
  (hyperbook:find-hyperbook
   (ecase (lisp-image-entry-kind entry)
     (:function "lisp-functions")
     (:class "lisp-classes"))
   :signal-error? t))

(defun project-lisp-image-entry-to-page (entry)
  "Resolve ENTRY through its existing Lisp HyperBook and return the resulting page."
  (hyperbook:find-page
   (lisp-image-entry-hyperbook entry)
   (lisp-image-entry-page-id entry)
   :signal-error? t))

(defclass lisp-image-page-collection ()
  ((kind
    :initarg :kind
    :reader lisp-image-page-collection-kind)
   (hyperbook
    :initarg :hyperbook
    :reader lisp-image-page-collection-hyperbook)
   (entries
    :initarg :entries
    :reader lisp-image-page-collection-entries)
   (pages
    :initarg :pages
    :reader lisp-image-page-collection-pages)))

(defmethod print-object ((collection lisp-image-page-collection) stream)
  (print-unreadable-object (collection stream :type t)
    (format stream "~A ~D pages"
            (lisp-image-page-collection-kind collection)
            (length
             (lisp-image-page-collection-pages collection)))))

(defun project-lisp-image-entries-to-pages (entries hyperbook)
  (mapcar
   (lambda (entry)
     (hyperbook:find-page
      hyperbook
      (lisp-image-entry-page-id entry)
      :signal-error? t))
   entries))

(defun make-lisp-image-page-collection (kind inventory)
  (multiple-value-bind (entries hyperbook)
      (ecase kind
        (:function
         (values
          (lisp-image-function-entries inventory)
          (hyperbook:find-hyperbook
           "lisp-functions"
           :signal-error? t)))
        (:class
         (values
          (lisp-image-class-entries inventory)
          (hyperbook:find-hyperbook
           "lisp-classes"
           :signal-error? t))))
    (make-instance
     'lisp-image-page-collection
     :kind kind
     :hyperbook hyperbook
     :entries entries
     :pages
     (project-lisp-image-entries-to-pages
      entries
      hyperbook))))
