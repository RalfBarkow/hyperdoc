;;;; Materialize authored HTML pages into HyperDoc's page directory.

(in-package #:hyperdoc-graham-roots-of-lisp)

(defparameter *roots-page-files*
  '("The Roots of Lisp.html"
    "The Roots of Lisp reconstruction layers.html"
    "The Surprise as an evaluation trace.html"
    "Which bugs did Graham correct?.html"
    "Dynamic capture in MAPLIST and DIFF.html"
    "Stanford Lisp interpreter crosswalk.html"
    "What Made Lisp Different crosswalk.html"
    "Roots of Lisp runner comparison.html"))

(defun roots-relative-file-pathname (relative directory)
  "Resolve RELATIVE below DIRECTORY without treating question marks as wildcards."
  (let* ((slash (position #\/ relative :from-end t))
         (directory-part (and slash (subseq relative 0 (1+ slash))))
         (file-part (subseq relative (if slash (1+ slash) 0)))
         (dot (position #\. file-part :from-end t))
         (parent (if directory-part
                     (merge-pathnames directory-part directory)
                     directory)))
    (make-pathname :name (if dot (subseq file-part 0 dot) file-part)
                   :type (and dot (subseq file-part (1+ dot)))
                   :defaults parent)))

(defun roots-system-relative-pathname (relative)
  (roots-relative-file-pathname
   relative
   (asdf:component-pathname
    (asdf:find-system :hyperdoc-graham-roots-of-lisp))))

(defun roots-copy-file-octets (source target)
  (ensure-directories-exist target)
  (with-open-file
      (input source
             :direction :input
             :element-type '(unsigned-byte 8))
    (with-open-file
        (output target
                :direction :output
                :if-exists :supersede
                :if-does-not-exist :create
                :element-type '(unsigned-byte 8))
      (let ((buffer
              (make-array 8192 :element-type '(unsigned-byte 8))))
        (loop for count = (read-sequence buffer input)
              while (plusp count)
              do (write-sequence buffer output :end count))))))

(defun materialize-roots-hyperdoc-pages
    (&key (destination #P"hyperdoc/"))
  "Copy the authored pages to DESTINATION and return an evidence report."
  (let ((results nil))
    (dolist (file *roots-page-files*)
      (let* ((source
               (roots-system-relative-pathname
                (format nil "pages/~A" file)))
             (target (roots-relative-file-pathname file destination)))
        (roots-copy-file-octets source target)
        (push (list :source source
                    :target target
                    :status :copied)
              results)))
    (list :status :materialized
          :destination destination
          :count (length results)
          :files (nreverse results))))
