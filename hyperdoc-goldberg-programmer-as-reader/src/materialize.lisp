;;;; Materialization helpers for authored HyperDoc pages.

(in-package #:hyperdoc-goldberg-programmer-as-reader)

(defparameter *goldberg-page-files*
  '("Goldberg Programmer as Reader.html"
    "Goldberg Programmer as Reader topic arrangement.html"
    "Goldberg reading comprehension questions.html"
    "Goldberg reader operations.html"
    "Goldberg Smalltalk to HyperDoc crosswalk.html"))

(defun system-relative-pathname (relative)
  (asdf:system-relative-pathname :hyperdoc-goldberg-programmer-as-reader relative))

(defun ensure-directory (pathname)
  (ensure-directories-exist pathname)
  pathname)

(defun copy-file-octets (source target)
  (ensure-directory target)
  (with-open-file (in source :direction :input :element-type '(unsigned-byte 8))
    (with-open-file (out target
                         :direction :output
                         :if-exists :supersede
                         :if-does-not-exist :create
                         :element-type '(unsigned-byte 8))
      (let ((buffer (make-array 8192 :element-type '(unsigned-byte 8))))
        (loop for count = (read-sequence buffer in)
              while (plusp count)
              do (write-sequence buffer out :end count))))))

(defun materialize-goldberg-hyperdoc-pages (&key (destination #P"hyperdoc/"))
  "Copy the authored HTML page templates into DESTINATION.

DESTINATION is a directory pathname. The function returns a materialization
report and does not edit topic registries. Use REGISTER-GOLDBERG-TOPICS-INTO-HYPERDOC
separately when loading inside a HyperDoc image."
  (let ((results '()))
    (dolist (file *goldberg-page-files*)
      (let* ((source (system-relative-pathname (format nil "pages/~A" file)))
             (target (merge-pathnames file destination)))
        (copy-file-octets source target)
        (push (list :source source :target target :status :copied) results)))
    (list :status :materialized
          :destination destination
          :count (length results)
          :files (nreverse results))))
