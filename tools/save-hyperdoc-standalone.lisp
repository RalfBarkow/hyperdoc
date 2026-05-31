(require :asdf)

(defparameter *hyperdoc-root*
  (or (and (boundp 'cl-user::*hyperdoc-root*) cl-user::*hyperdoc-root*)
      (uiop:getcwd)))

(defparameter *hyperdoc-output*
  (or (and (boundp 'cl-user::*hyperdoc-output*) cl-user::*hyperdoc-output*)
      (merge-pathnames #p"bundle-deploy/hyperdoc-standalone/hyperdoc"
                       *hyperdoc-root*)))

(defparameter *hyperdoc-system*
  (or (and (boundp 'cl-user::*hyperdoc-system*) cl-user::*hyperdoc-system*)
      :hyperdoc/server))

(defun hyperdoc-standalone-truthy (value)
  (and value
       (member (string-downcase value)
               '("1" "true" "yes" "on")
               :test #'string=)))

(defun hyperdoc-standalone-serve-catalog (port development)
  (let* ((package (or (find-package "HYPERBOOK/SERVER")
                      (error "Package HYPERBOOK/SERVER does not exist after loading ~S."
                             *hyperdoc-system*)))
         (symbol (or (find-symbol "SERVE-CATALOG" package)
                     (error "SERVE-CATALOG is not present in package HYPERBOOK/SERVER."))))
    (funcall (symbol-function symbol)
             :port port
             :development development)))

(defun hyperdoc-standalone-main ()
  (handler-case
      (let* ((port (parse-integer (or (uiop:getenv "HYPERDOC_PORT") "8080")
                                  :junk-allowed t))
             (development (hyperdoc-standalone-truthy
                           (uiop:getenv "HYPERDOC_DEVELOPMENT"))))
        (format t "~&HyperDoc standalone executable~%")
        (format t "Port: ~D~%" port)
        (format t "URL: http://127.0.0.1:~D/boot.html~%" port)
        (finish-output)
        (hyperdoc-standalone-serve-catalog port development)
        (loop (sleep 3600)))
    (error (condition)
      (format *error-output* "~&FATAL: ~A~%" condition)
      (uiop:print-condition-backtrace condition :stream *error-output*)
      (uiop:quit 1))))

(uiop:chdir *hyperdoc-root*)

(pushnew (truename *hyperdoc-root*)
         asdf:*central-registry*
         :test #'equal)

(asdf:load-system *hyperdoc-system*)

(ensure-directories-exist *hyperdoc-output*)

#+sbcl
(sb-ext:save-lisp-and-die
 *hyperdoc-output*
 :toplevel #'hyperdoc-standalone-main
 :executable t)

#-sbcl
(error "This standalone builder currently expects SBCL.")
