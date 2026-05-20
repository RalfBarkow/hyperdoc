;;;; Native source artifact and content-target protocol.

(in-package :hyperdoc)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro %defgeneric-unless-present (name lambda-list &body options)
    `(eval-when (:compile-toplevel :load-toplevel :execute)
       (unless (fboundp ',name)
         (defgeneric ,name ,lambda-list ,@options)))))

(%defgeneric-unless-present relative-path-of (object))
(%defgeneric-unless-present root-of (object))
(%defgeneric-unless-present pathname-of (object))
(%defgeneric-unless-present exists-p (object))
(%defgeneric-unless-present size-of (object))
(%defgeneric-unless-present content-of (object))
(%defgeneric-unless-present content-target-of (object)
  (:documentation "Return the object whose existing content view should answer OBJECT."))

(%defgeneric-unless-present source-target-of (object))
(%defgeneric-unless-present source-title-of (object))
(%defgeneric-unless-present source-text-of (object))

(defclass file-artifact ()
  ((relative-path :initarg :relative-path :reader relative-path-of)
   (root :initarg :root :reader root-of)))

(defclass source-content ()
  ((target :initarg :target :reader source-target-of)
   (title :initarg :title :reader source-title-of)
   (text :initarg :text :reader source-text-of)))

(defun default-file-artifact-root ()
  (asdf:system-source-directory :hyperdoc))

(defun make-file-artifact (relative-path &key root)
  (make-instance 'file-artifact
                 :relative-path relative-path
                 :root (or root (default-file-artifact-root))))

(defun ensure-file-artifact (value &key root)
  (etypecase value
    (file-artifact value)
    ((or string pathname)
     (make-file-artifact value :root root))))

(defun file-artifact-relative-label (artifact)
  (let ((relative-path (relative-path-of artifact)))
    (etypecase relative-path
      (string relative-path)
      (pathname (namestring relative-path)))))

(defmethod pathname-of ((artifact file-artifact))
  (merge-pathnames (relative-path-of artifact)
                   (uiop:ensure-directory-pathname (root-of artifact))))

(defmethod content-target-of ((artifact file-artifact))
  (pathname-of artifact))

(defmethod exists-p ((artifact file-artifact))
  (and (uiop:file-exists-p (pathname-of artifact)) t))

(defmethod size-of ((artifact file-artifact))
  (when (exists-p artifact)
    (with-open-file (stream (pathname-of artifact)
                            :direction :input
                            :element-type '(unsigned-byte 8))
      (file-length stream))))

(defmethod content-of ((artifact file-artifact))
  (when (exists-p artifact)
    (uiop:read-file-string (pathname-of artifact))))

(defmethod title-of ((artifact file-artifact))
  (file-artifact-relative-label artifact))

(defmethod summary-of ((artifact file-artifact))
  (format nil "~A~:[ missing~; present~], ~:[unknown size~;~:*~D bytes~]"
          (file-artifact-relative-label artifact)
          (exists-p artifact)
          (size-of artifact)))

(defmethod print-object ((artifact file-artifact) stream)
  (print-unreadable-object (artifact stream :type t :identity nil)
    (format stream "~A~:[ missing~;~]"
            (file-artifact-relative-label artifact)
            (exists-p artifact))))

(defun source-content-from-pathname (pathname)
  (unless (and pathname (uiop:file-exists-p pathname))
    (error "Not an existing file pathname: ~A" pathname))
  (make-instance 'source-content
                 :target pathname
                 :title (file-namestring pathname)
                 :text (uiop:read-file-string pathname)))

(defun source-content-from-artifact (artifact)
  (source-content-from-pathname (pathname-of artifact)))

(defun source-content-from-object (object &key title text)
  (make-instance 'source-content
                 :target object
                 :title (or title (princ-to-string (type-of object)))
                 :text (or text
                           (with-output-to-string (stream)
                             (let ((*print-pretty* t)
                                   (*print-circle* t)
                                   (*print-level* 5)
                                   (*print-length* 40))
                               (prin1 object stream))))))
