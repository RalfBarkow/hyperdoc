;;;; Application policy shared by interactive Lisp and the packaged executable.
(defpackage #:dreyeck/catalog-application
  (:use #:cl)
  (:export #:start-catalog #:main))
(in-package #:dreyeck/catalog-application)

(defun %port (value)
  (let ((port (if (and (stringp value) (plusp (length value))
                       (every (lambda (c) (find c "0123456789")) value))
                  (parse-integer value)
                  value)))
    (unless (and (integerp port) (<= 1 port 65535))
      (error "Port must be an integer between 1 and 65535: ~S" value))
    port))

(defun %configuration (arguments &optional (getenv #'uiop:getenv))
  (when (> (length arguments) 1)
    (error "Usage: hyperdoc-catalog [PORT]"))
  (list :port (%port (or (first arguments)
                        (funcall getenv "HYPERDOC_CATALOG_PORT") "8080"))
        :host (or (funcall getenv "HYPERDOC_CATALOG_HOST") "0.0.0.0")
        :catalog-system (or (funcall getenv "HYPERDOC_CATALOG_SYSTEM")
                            "dreyeck/catalog")))

(defun start-catalog (&key (port 8080) (host "0.0.0.0")
                          (site-root (dreyeck/local-fedwiki-view:configured-site-root))
                          (catalog-system "dreyeck/catalog")
                          (pane-width "700px") (development nil))
  "Start Catalog and local /view and /gesture routes; return to the caller.
ASDF loads the default Catalog through LOCAL-FEDWIKI-VIEW. CATALOG-SYSTEM
can add trusted books; it does not replace that default membership.
Interactive callers own shutdown. MAIN owns executable lifetime."
  (let ((port (%port port)))
    ;; The default membership is already a static ASDF dependency.
    (unless (equal catalog-system "dreyeck/catalog")
      (asdf:load-system catalog-system))
    (dreyeck/local-fedwiki-view:serve-catalog-with-local-fedwiki-view
     :port port :host host :site-root site-root :pane-width pane-width
     :development development)))

(define-condition stop-requested (condition) ())

(defun %wait ()
  (loop (sleep 3600)))

(defun main (&optional (arguments (uiop:command-line-arguments)))
  "Run the foreground application; return a process exit status.
PORT overrides HYPERDOC_CATALOG_PORT. SIGINT and SIGTERM stop the server.
The executable never enables development tools."
  (when (equal arguments '("--help"))
    (format t "Usage: hyperdoc-catalog [PORT]~%~
Environment: HYPERDOC_CATALOG_PORT, HYPERDOC_CATALOG_HOST,~%~
HYPERDOC_CATALOG_SYSTEM (additive), HYPERDOC_FEDWIKI_SITE_ROOT.~%")
    (return-from main 0))
  (handler-case
      (let ((configuration (%configuration arguments)))
        ;; The executable uses SBCL. Keep signals at this process adapter,
        ;; outside START-CATALOG so a SLY image retains its own handlers.
        #+sbcl
        (let ((thread sb-thread:*current-thread*))
          (sb-sys:enable-interrupt
           sb-unix:sigterm
           (lambda (&rest ignored)
             (declare (ignore ignored))
             (sb-thread:interrupt-thread
              thread (lambda () (signal 'stop-requested))))))
        (unwind-protect
             (progn
               (apply #'start-catalog configuration)
               (format t "~&HyperBook Catalog listening on ~A:~D~%~
Local FedWiki /view route installed from ~A~%"
                       (getf configuration :host) (getf configuration :port)
                       (dreyeck/local-fedwiki-view:configured-site-root))
               (finish-output)
               (%wait)
               0)
          (clog:shutdown)))
    (stop-requested ()
      (format t "~&Stopping HyperBook Catalog~%")
      0)
    #+sbcl
    (sb-sys:interactive-interrupt ()
      (format t "~&Stopping HyperBook Catalog~%")
      0)
    (error (condition)
      (format *error-output* "~&Catalog startup failed: ~A~%" condition)
      1)))
