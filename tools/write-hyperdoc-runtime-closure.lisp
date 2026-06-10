;;;; Generate HyperDoc standalone runtime closure manifests.
;;;;
;;;; This file is intentionally usable from the build image without requiring
;;;; the saved standalone executable to start.

(require :asdf)
(require :uiop)

(defpackage :hyperdoc/runtime-closure
  (:use :cl)
  (:export
   #:hyperdoc-runtime-closure
   #:hyperdoc-runtime-closure-p
   #:make-hyperdoc-runtime-closure
   #:write-hyperdoc-runtime-closure
   #:read-hyperdoc-runtime-closure
   #:preflight-hyperdoc-runtime-closure
   #:generate-hyperdoc-runtime-closure
   #:*last-hyperdoc-runtime-closure*))

(in-package :hyperdoc/runtime-closure)

(defstruct preflight-finding
  name
  status
  detail)

(defstruct hyperdoc-runtime-closure
  bundle-root
  repo-root
  server-executable
  frame-executable
  runtime-library-path
  required-native-libraries
  static-roots
  boot-path
  title
  width
  height
  pid-file
  port-file
  log-file
  environment
  preflight-results)

(defparameter *last-hyperdoc-runtime-closure* nil)

(defun truthy-env-p (name)
  (let ((value (uiop:getenv name)))
    (and value
         (member (string-downcase value)
                 '("1" "true" "yes" "on")
                 :test #'string=))))

(defun path-string (pathname)
  (namestring (uiop:native-namestring pathname)))

(defun shell-single-quote (string)
  (with-output-to-string (out)
    (write-char #\' out)
    (loop for ch across string
          do (if (char= ch #\')
                 (write-string "'\\''" out)
                 (write-char ch out)))
    (write-char #\' out)))

(defun write-env-binding (stream name value)
  (format stream "~A=~A~%" name (shell-single-quote (princ-to-string value))))

(defun executable-file-p (pathname)
  (and (probe-file pathname)
       (not (uiop:directory-pathname-p pathname))))

(defun directory-present-p (pathname)
  (and (probe-file pathname)
       (uiop:directory-pathname-p (uiop:ensure-directory-pathname pathname))))

(defun find-library-in-directories (library directories)
  (loop for directory in directories
        for candidate = (merge-pathnames library
                                         (uiop:ensure-directory-pathname directory))
        when (probe-file candidate)
          return candidate))

(defun native-library-requirement-label (requirement)
  (etypecase requirement
    (string requirement)
    (cons
     (string-downcase
      (string (first requirement))))))

(defun native-library-requirement-candidates (requirement)
  (etypecase requirement
    (string (list requirement))
    (cons (mapcar #'princ-to-string (rest requirement)))))

(defun find-library-requirement-in-directories (requirement directories)
  (loop for library in (native-library-requirement-candidates requirement)
        for match = (find-library-in-directories library directories)
        when match
          return (values match library)))

(defun nix-package-lib-dir (repo-root package-name)
  (let* ((expr
           (format nil
                   "let flake = builtins.getFlake \"git+file://~A\"; pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; }; in \"${pkgs.~A.out}/lib\""
                   (string-right-trim '(#\/) (path-string repo-root))
                   package-name))
         (output
           (uiop:run-program
            (list "nix" "eval" "--raw" "--impure" "--expr" expr)
            :output :string
            :error-output :string
            :ignore-error-status t)))
    (string-trim '(#\Space #\Tab #\Newline #\Return) output)))

(defun maybe-nix-package-lib-dir (repo-root package-name)
  (handler-case
      (let ((path (nix-package-lib-dir repo-root package-name)))
        (and (plusp (length path))
             (probe-file path)
             (uiop:ensure-directory-pathname path)))
    (error () nil)))

(defun default-runtime-library-directories (repo-root)
  (remove nil
          (list
           (maybe-nix-package-lib-dir repo-root "openssl")
           (maybe-nix-package-lib-dir repo-root "sqlite")
           (maybe-nix-package-lib-dir repo-root "zlib")
           (maybe-nix-package-lib-dir repo-root "libffi"))
          :test #'equal))

(defun default-static-roots (repo-root)
  (remove nil
          (list
           (merge-pathnames #P"assets/" repo-root)
           (merge-pathnames #P"nix/vendor/clog/static-files/" repo-root)
           (merge-pathnames #P"bundle-deploy/hyperdoc-frame/" repo-root))
          :test #'equal))

(defun make-default-hyperdoc-runtime-closure
    (&key
       (repo-root
        (uiop:ensure-directory-pathname
         (or (and (boundp 'cl-user::*hyperdoc-root*) cl-user::*hyperdoc-root*)
             (uiop:getcwd))))
       (bundle-root (merge-pathnames #P"bundle-deploy/" repo-root))
       (server-executable
        (merge-pathnames #P"hyperdoc-standalone/hyperdoc" bundle-root))
       (frame-executable
        (merge-pathnames #P"hyperdoc-frame/clogframe" bundle-root))
       (frame-root
        (merge-pathnames #P"hyperdoc-frame/" bundle-root))
       (runtime-library-path
        (default-runtime-library-directories repo-root))
       (required-native-libraries
        '((:openssl-crypto
           "libcrypto.so.3" "libcrypto.3.dylib" "libcrypto.dylib")
          (:openssl-ssl
           "libssl.so.3" "libssl.3.dylib" "libssl.dylib")
          (:sqlite
           "libsqlite3.so.0" "libsqlite3.0.dylib" "libsqlite3.dylib")))
       (static-roots
        (default-static-roots repo-root))
       (boot-path "/boot.html")
       (title "HyperDoc")
       (width "1280")
       (height "900")
       (pid-file (merge-pathnames #P"hyperdoc-server.pid" frame-root))
       (port-file (merge-pathnames #P"hyperdoc-server.port" frame-root))
       (log-file (merge-pathnames #P"hyperdoc-server.log" frame-root)))
  (make-hyperdoc-runtime-closure
   :bundle-root bundle-root
   :repo-root repo-root
   :server-executable server-executable
   :frame-executable frame-executable
   :runtime-library-path runtime-library-path
   :required-native-libraries required-native-libraries
   :static-roots static-roots
   :boot-path boot-path
   :title title
   :width width
   :height height
   :pid-file pid-file
   :port-file port-file
   :log-file log-file
   :environment `(("HYPERDOC_SERVER" . ,(path-string server-executable))
                  ("HYPERDOC_FRAME" . ,(path-string frame-executable))
                  ("HYPERDOC_RUNTIME_LIBRARY_PATH" .
                   ,(format nil "~{~A~^:~}"
                            (mapcar #'path-string runtime-library-path)))
                  ("HYPERDOC_BOOT_PATH" . ,boot-path)
                  ("HYPERDOC_FRAME_TITLE" . ,title)
                  ("HYPERDOC_FRAME_WIDTH" . ,width)
                  ("HYPERDOC_FRAME_HEIGHT" . ,height)
                  ("HYPERDOC_PID_FILE" . ,(path-string pid-file))
                  ("HYPERDOC_PORT_FILE" . ,(path-string port-file))
                  ("HYPERDOC_LOG_FILE" . ,(path-string log-file))
                  ("HYPERDOC_FRAME_LOG_FILE" .
                   ,(path-string
                     (merge-pathnames #P"hyperdoc-frame.log"
                                      frame-root))))))

(defun preflight-hyperdoc-runtime-closure (closure)
  (let ((findings '()))
    (flet ((record (name status detail)
             (push (make-preflight-finding
                    :name name
                    :status status
                    :detail detail)
                   findings)))
      (record "server-executable"
              (if (executable-file-p
                   (hyperdoc-runtime-closure-server-executable closure))
                  :ok
                  :fail)
              (path-string
               (hyperdoc-runtime-closure-server-executable closure)))
      (record "frame-executable"
              (if (executable-file-p
                   (hyperdoc-runtime-closure-frame-executable closure))
                  :ok
                  :fail)
              (path-string
               (hyperdoc-runtime-closure-frame-executable closure)))
      (dolist (directory (hyperdoc-runtime-closure-runtime-library-path closure))
        (record "runtime-library-directory"
                (if (directory-present-p directory) :ok :fail)
                (path-string directory)))
      (dolist (requirement
                (hyperdoc-runtime-closure-required-native-libraries closure))
        (multiple-value-bind (match chosen-library)
            (find-library-requirement-in-directories
             requirement
             (hyperdoc-runtime-closure-runtime-library-path closure))
          (record (format nil "native-library:~A"
                          (native-library-requirement-label requirement))
                  (if match :ok :fail)
                  (or (and match
                           (format nil "~A (~A)"
                                   (path-string match)
                                   chosen-library))
                      (format nil "none of ~{~A~^, ~} found in runtime-library-path"
                              (native-library-requirement-candidates
                               requirement))))))
      (dolist (root (hyperdoc-runtime-closure-static-roots closure))
        (record "static-root"
                (if (directory-present-p root) :ok :fail)
                (path-string root)))
      (record "state-directory"
              (if (directory-present-p
                   (uiop:pathname-directory-pathname
                    (hyperdoc-runtime-closure-pid-file closure)))
                  :ok
                  :fail)
              (path-string
               (uiop:pathname-directory-pathname
                (hyperdoc-runtime-closure-pid-file closure)))))
    (let ((results (nreverse findings)))
      (setf (hyperdoc-runtime-closure-preflight-results closure) results)
      results)))

(defun preflight-ok-p (closure)
  (every (lambda (finding)
           (eq (preflight-finding-status finding) :ok))
         (or (hyperdoc-runtime-closure-preflight-results closure)
             (preflight-hyperdoc-runtime-closure closure))))

(defun closure-sexp (closure)
  `(:hyperdoc-runtime-closure
    :bundle-root ,(path-string
                   (hyperdoc-runtime-closure-bundle-root closure))
    :repo-root ,(path-string
                 (hyperdoc-runtime-closure-repo-root closure))
    :server-executable ,(path-string
                         (hyperdoc-runtime-closure-server-executable closure))
    :frame-executable ,(path-string
                        (hyperdoc-runtime-closure-frame-executable closure))
    :runtime-library-path ,(mapcar #'path-string
                                   (hyperdoc-runtime-closure-runtime-library-path
                                    closure))
    :required-native-libraries
    ,(hyperdoc-runtime-closure-required-native-libraries closure)
    :static-roots ,(mapcar #'path-string
                           (hyperdoc-runtime-closure-static-roots closure))
    :boot-path ,(hyperdoc-runtime-closure-boot-path closure)
    :title ,(hyperdoc-runtime-closure-title closure)
    :width ,(hyperdoc-runtime-closure-width closure)
    :height ,(hyperdoc-runtime-closure-height closure)
    :pid-file ,(path-string
                (hyperdoc-runtime-closure-pid-file closure))
    :port-file ,(path-string
                 (hyperdoc-runtime-closure-port-file closure))
    :log-file ,(path-string
                (hyperdoc-runtime-closure-log-file closure))
    :environment ,(hyperdoc-runtime-closure-environment closure)
    :preflight-results
    ,(mapcar
      (lambda (finding)
        (list :name (preflight-finding-name finding)
              :status (preflight-finding-status finding)
              :detail (preflight-finding-detail finding)))
      (or (hyperdoc-runtime-closure-preflight-results closure)
          (preflight-hyperdoc-runtime-closure closure)))))

(defun write-hyperdoc-runtime-closure
    (closure &key env-path sexp-path)
  (when env-path
    (ensure-directories-exist env-path)
    (with-open-file (out env-path
                         :direction :output
                         :if-exists :supersede
                         :if-does-not-exist :create)
      (format out "# Generated by tools/write-hyperdoc-runtime-closure.lisp.~%")
      (dolist (binding (hyperdoc-runtime-closure-environment closure))
        (write-env-binding out (car binding) (cdr binding)))))
  (when sexp-path
    (ensure-directories-exist sexp-path)
    (with-open-file (out sexp-path
                         :direction :output
                         :if-exists :supersede
                         :if-does-not-exist :create)
      (let ((*print-pretty* t)
            (*print-circle* t))
        (prin1 (closure-sexp closure) out)
        (terpri out))))
  closure)

(defun read-hyperdoc-runtime-closure (sexp-path)
  (with-open-file (in sexp-path)
    (read in)))

(defun print-preflight-report (closure &optional (stream *standard-output*))
  (format stream "~&HyperDoc runtime closure preflight~%")
  (dolist (finding (or (hyperdoc-runtime-closure-preflight-results closure)
                       (preflight-hyperdoc-runtime-closure closure)))
    (format stream "  ~A  ~A  ~A~%"
            (preflight-finding-status finding)
            (preflight-finding-name finding)
            (preflight-finding-detail finding)))
  (format stream "~&Overall: ~A~%" (if (preflight-ok-p closure) :ok :fail)))

(defun generate-hyperdoc-runtime-closure
    (&key
       (repo-root
        (uiop:ensure-directory-pathname
         (or (and (boundp 'cl-user::*hyperdoc-root*) cl-user::*hyperdoc-root*)
             (uiop:getcwd))))
       (env-path
        (or (and (boundp 'cl-user::*hyperdoc-runtime-env*)
                 cl-user::*hyperdoc-runtime-env*)
            (merge-pathnames
             #P"bundle-deploy/hyperdoc-frame/hyperdoc-runtime-closure.env"
             repo-root)))
       (sexp-path
        (or (and (boundp 'cl-user::*hyperdoc-runtime-sexp*)
                 cl-user::*hyperdoc-runtime-sexp*)
            (merge-pathnames
             #P"bundle-deploy/hyperdoc-frame/hyperdoc-runtime-closure.sexp"
             repo-root))))
  (let ((closure (make-default-hyperdoc-runtime-closure :repo-root repo-root)))
    (preflight-hyperdoc-runtime-closure closure)
    (write-hyperdoc-runtime-closure closure
                                    :env-path env-path
                                    :sexp-path sexp-path)
    (setf *last-hyperdoc-runtime-closure* closure)
    (print-preflight-report closure)
    (unless (preflight-ok-p closure)
      (when (truthy-env-p "HYPERDOC_RUNTIME_CLOSURE_STRICT")
        (error "HyperDoc runtime closure preflight failed.")))
    closure))

(generate-hyperdoc-runtime-closure)
