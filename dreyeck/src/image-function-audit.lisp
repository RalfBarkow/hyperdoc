(defclass dreyeck/image-audit:image-function-audit nil
          ((dreyeck/image-audit::audited-package :reader
            dreyeck/image-audit:image-function-audit-audited-package-of
            :initarg :audited-package :type string)
           (dreyeck/image-audit::reconstruction-systems :reader
            dreyeck/image-audit:image-function-audit-reconstruction-systems-of
            :initarg :reconstruction-systems :type list)
           (dreyeck/image-audit::current-function-coordinates :reader
            dreyeck/image-audit:image-function-audit-current-function-coordinates-of
            :initarg :current-function-coordinates :type list)
           (dreyeck/image-audit::reconstructed-function-coordinates :reader
            dreyeck/image-audit:image-function-audit-reconstructed-function-coordinates-of
            :initarg :reconstructed-function-coordinates :type list)
           (dreyeck/image-audit::image-only-function-coordinates :reader
            dreyeck/image-audit:image-function-audit-image-only-function-coordinates-of
            :initarg :image-only-function-coordinates :type list))
          (:documentation
           "Observed function inventory difference between a running Lisp image and an explicit repository reconstruction recipe."))

(defun dreyeck/image-audit:make-image-function-audit
       (dreyeck/image-audit::audited-package
        dreyeck/image-audit::reconstruction-systems
        dreyeck/image-audit::current-function-coordinates
        dreyeck/image-audit::reconstructed-function-coordinates)
  (make-instance 'dreyeck/image-audit:image-function-audit :audited-package
                 dreyeck/image-audit::audited-package :reconstruction-systems
                 dreyeck/image-audit::reconstruction-systems
                 :current-function-coordinates
                 dreyeck/image-audit::current-function-coordinates
                 :reconstructed-function-coordinates
                 dreyeck/image-audit::reconstructed-function-coordinates
                 :image-only-function-coordinates
                 (set-difference
                  dreyeck/image-audit::current-function-coordinates
                  dreyeck/image-audit::reconstructed-function-coordinates :test
                  #'equal)))

(defun dreyeck/image-audit:package-function-coordinates
       (dreyeck/image-audit::package-designator)
  (let ((package (find-package dreyeck/image-audit::package-designator))
        (dreyeck/image-audit::result nil))
    (when package
      (do-symbols (symbol package)
        (when
            (and (eq (symbol-package symbol) package) (fboundp symbol)
                 (not (ignore-errors (find-class symbol nil))))
          (push
           (list (package-name (symbol-package symbol)) (symbol-name symbol))
           dreyeck/image-audit::result)))
      (sort dreyeck/image-audit::result #'string< :key #'second))))

(defun dreyeck/image-audit::current-lisp-executable ()
  (or (and *runtime-pathname* (namestring *runtime-pathname*))
      (uiop/image:argv0) "sbcl"))

(defun dreyeck/image-audit:reconstructed-package-function-coordinates
       (dreyeck/image-audit::package-designator
        dreyeck/image-audit::reconstruction-systems)
  "Return function coordinates observed after reconstructing the requested systems in a fresh Lisp process."
  (let* ((dreyeck/image-audit::root
          (asdf/system:system-source-directory "dreyeck/image-audit"))
         (dreyeck/image-audit::asd
          (truename (merge-pathnames "dreyeck.asd" dreyeck/image-audit::root)))
         (dreyeck/image-audit::reconstruction-load-source
          (format nil
                  "(let ((*standard-output* (make-broadcast-stream)) (*trace-output* (make-broadcast-stream))) (asdf:load-system \"dreyeck/image-audit\")~{ (asdf:load-system ~S)~})"
                  dreyeck/image-audit::reconstruction-systems))
         (dreyeck/image-audit::reconstruction-observation-source
          (format nil
                  "(prin1 (dreyeck/image-audit:package-function-coordinates ~S))"
                  dreyeck/image-audit::package-designator))
         (dreyeck/image-audit::command
          (list (dreyeck/image-audit::current-lisp-executable) "--noinform"
                "--no-userinit" "--disable-debugger" "--non-interactive"
                "--eval" "(require :asdf)" "--eval"
                (format nil "(asdf:load-asd #P~S)"
                        (namestring dreyeck/image-audit::asd))
                "--eval" dreyeck/image-audit::reconstruction-load-source
                "--eval"
                dreyeck/image-audit::reconstruction-observation-source)))
    (values
     (read-from-string
      (uiop/run-program:run-program dreyeck/image-audit::command :directory
                                    dreyeck/image-audit::root :output :string
                                    :error-output :string)))))

(defun dreyeck/image-audit:audit-package-functions
       (dreyeck/image-audit::package-designator
        dreyeck/image-audit::reconstruction-systems)
  (dreyeck/image-audit:make-image-function-audit
   dreyeck/image-audit::package-designator
   dreyeck/image-audit::reconstruction-systems
   (dreyeck/image-audit:package-function-coordinates
    dreyeck/image-audit::package-designator)
   (dreyeck/image-audit:reconstructed-package-function-coordinates
    dreyeck/image-audit::package-designator
    dreyeck/image-audit::reconstruction-systems)))
