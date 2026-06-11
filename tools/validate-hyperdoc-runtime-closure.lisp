;;;; Validate a generated HyperDoc runtime closure manifest.
;;;;
;;;; Reads bundle-deploy/hyperdoc-frame/hyperdoc-runtime-closure.sexp,
;;;; proves native-library loadability, runs a saved-image dynamic-port
;;;; smoke test, and emits an inspectable S-expression plus plain HTML report.

(require :asdf)
(require :uiop)

(defpackage #:hyperdoc/runtime-closure-validation
  (:use #:cl)
  (:export #:validate-hyperdoc-runtime-closure))

(in-package #:hyperdoc/runtime-closure-validation)

(defun now-utc-string ()
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time (get-universal-time) 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ"
            year month day hour min sec)))

(defun read-file-string/safe (path)
  (if (probe-file path)
      (uiop:read-file-string path)
      ""))

(defun path-directory (path)
  (uiop:ensure-directory-pathname
   (make-pathname :directory (pathname-directory path)
                  :defaults path
                  :name nil
                  :type nil)))

(defun run/status (argv &key (directory (uiop:getcwd)))
  (multiple-value-bind (stdout stderr exit-code)
      (uiop:run-program
       argv
       :directory directory
       :output :string
       :error-output :string
       :ignore-error-status t)
    (values exit-code stdout stderr)))

(defun git-string (repo &rest args)
  (multiple-value-bind (status stdout stderr)
      (run/status (append (list "git" "-C" repo) args))
    (declare (ignore stderr))
    (if (zerop status)
        (string-trim '(#\Space #\Tab #\Newline #\Return) stdout)
        "")))

(defun read-runtime-closure (path)
  (with-open-file (in path)
    (let ((form (read in)))
      (unless (and (consp form)
                   (eq (first form) :hyperdoc-runtime-closure))
        (error "Not a HyperDoc runtime closure sexp: ~A" path))
      (rest form))))

(defun closure-get (closure key)
  (getf closure key))

(defun requirement-label (requirement)
  (etypecase requirement
    (string requirement)
    (cons (string-downcase (string (first requirement))))))

(defun requirement-candidates (requirement)
  (etypecase requirement
    (string (list requirement))
    (cons (mapcar #'princ-to-string (rest requirement)))))

(defun find-library-in-directories (candidate directories)
  (loop for directory in directories
        for path = (merge-pathnames candidate
                                    (uiop:ensure-directory-pathname directory))
        when (probe-file path)
          return path))

(defun find-library-requirement (requirement directories)
  (loop for candidate in (requirement-candidates requirement)
        for path = (find-library-in-directories candidate directories)
        when path
          return (values path candidate)))

(defun load-shared-object* (path)
  (let* ((package (find-package "SB-ALIEN"))
         (symbol (and package
                      (find-symbol "LOAD-SHARED-OBJECT" package))))
    (unless (and symbol (fboundp symbol))
      (error "SB-ALIEN:LOAD-SHARED-OBJECT is unavailable."))
    (funcall (symbol-function symbol) (namestring path))))

(defun finding (name status detail &rest rest)
  (append (list :name name :status status :detail detail) rest))

(defun validate-native-library-loadability (closure)
  (let ((directories (closure-get closure :runtime-library-path))
        (requirements (closure-get closure :required-native-libraries)))
    (loop for requirement in requirements
          collect
          (multiple-value-bind (path chosen)
              (find-library-requirement requirement directories)
            (cond
              ((null path)
               (finding
                (format nil "native-library/load:~A"
                        (requirement-label requirement))
                :fail
                (format nil "none of ~{~A~^, ~} found in runtime-library-path"
                        (requirement-candidates requirement))))
              (t
               (handler-case
                   (progn
                     (load-shared-object* path)
                     (finding
                      (format nil "native-library/load:~A"
                              (requirement-label requirement))
                      :ok
                      (format nil "loaded ~A (~A)" (namestring path) chosen)
                      :path (namestring path)
                      :candidate chosen))
                 (error (condition)
                   (finding
                    (format nil "native-library/load:~A"
                            (requirement-label requirement))
                    :fail
                    (format nil "found ~A, but load failed: ~A"
                            (namestring path)
                            condition)
                    :path (namestring path)
                    :candidate chosen)))))))))

(defun choose-validation-port ()
  (+ 49152 (random 12000 (make-random-state t))))

(defun curl-ok-p (url)
  (multiple-value-bind (status stdout stderr)
      (run/status (list "curl" "-fsS" "--max-time" "2" url))
    (declare (ignore stdout stderr))
    (zerop status)))

(defun runtime-library-env (closure)
  (format nil "~{~A~^:~}"
          (closure-get closure :runtime-library-path)))

(defun server-smoke-log-path (validation-sexp-path)
  (merge-pathnames #P"hyperdoc-runtime-closure-validation-server.log"
                   (path-directory validation-sexp-path)))

(defun saved-image-dynamic-port-smoke (closure validation-sexp-path)
  (let* ((server (closure-get closure :server-executable))
         (boot-path (or (closure-get closure :boot-path) "/boot.html"))
         (library-path (runtime-library-env closure))
         (log-path (server-smoke-log-path validation-sexp-path))
         (port (choose-validation-port))
         (url (format nil "http://127.0.0.1:~D~A" port boot-path))
         (argv (list "env"
                     (format nil "HYPERDOC_PORT=~D" port)
                     "HYPERDOC_DEVELOPMENT=0"
                     (format nil "HYPERDOC_RUNTIME_LIBRARY_PATH=~A" library-path)
                     (format nil "LD_LIBRARY_PATH=~A" library-path)
                     (format nil "DYLD_LIBRARY_PATH=~A" library-path)
                     (format nil "DYLD_FALLBACK_LIBRARY_PATH=~A" library-path)
                     server)))
    (ensure-directories-exist log-path)
    (with-open-file (log-stream log-path
                                :direction :output
                                :if-exists :supersede
                                :if-does-not-exist :create
                                :external-format :utf-8)
      (let ((process nil)
            (ready nil))
        (unwind-protect
             (progn
               (setf process
                     (uiop:launch-program
                      argv
                      :output log-stream
                      :error-output log-stream
                      :input :interactive))
               (loop repeat 120
                     do (progn
                          (finish-output log-stream)
                          (when (curl-ok-p url)
                            (setf ready t)
                            (return))
                          (sleep 0.25)))
               (finish-output log-stream)
               (let ((log-text (read-file-string/safe log-path)))
                 (cond
                   ((not ready)
                    (list
                     (finding "saved-image/dynamic-port"
                              :fail
                              (format nil "server did not become ready at ~A" url)
                              :port port
                              :url url
                              :log-file (namestring log-path)
                              :log-tail (if (> (length log-text) 2000)
                                            (subseq log-text (- (length log-text) 2000))
                                            log-text))))
                   ((not (search (format nil "Port: ~D" port) log-text :test #'char=))
                    (list
                     (finding "saved-image/dynamic-port"
                              :fail
                              (format nil "server responded at ~A, but log did not prove HYPERDOC_PORT=~D"
                                      url port)
                              :port port
                              :url url
                              :log-file (namestring log-path)
                              :log-tail (if (> (length log-text) 2000)
                                            (subseq log-text (- (length log-text) 2000))
                                            log-text))))
                   (t
                    (list
                     (finding "saved-image/dynamic-port"
                              :ok
                              (format nil "served ~A and logged Port: ~D" url port)
                              :port port
                              :url url
                              :log-file (namestring log-path)))))))
          (when process
            (ignore-errors (uiop:terminate-process process))
            (ignore-errors (uiop:wait-process process))))))))

(defun closure-preflight-findings (closure)
  (mapcar
   (lambda (entry)
     (finding
      (format nil "closure/preflight:~A" (getf entry :name))
      (getf entry :status)
      (princ-to-string (getf entry :detail))))
   (or (closure-get closure :preflight-results) nil)))

(defun audit-findings (closure repo-root closure-sexp-path)
  (let* ((repo (or repo-root (closure-get closure :repo-root)))
         (branch (git-string repo "branch" "--show-current"))
         (head (git-string repo "rev-parse" "--short" "HEAD"))
         (status (git-string repo "status" "--short"))
         (dirty (plusp (length status))))
    (list
     (finding "manifest/read"
              (if (probe-file closure-sexp-path) :ok :fail)
              (namestring closure-sexp-path))
     (finding "audit/git-head"
              :ok
              (format nil "~A ~A dirty=~A" branch head dirty)
              :branch branch
              :head head
              :dirty dirty)
     (finding "audit/sbcl"
              :ok
              (lisp-implementation-version)))))

(defun html-escape (value)
  (let ((string (princ-to-string value)))
    (with-output-to-string (out)
      (loop for ch across string
            do (case ch
                 (#\& (write-string "&amp;" out))
                 (#\< (write-string "&lt;" out))
                 (#\> (write-string "&gt;" out))
                 (#\" (write-string "&quot;" out))
                 (otherwise (write-char ch out)))))))

(defun report-ok-p (report)
  (every
   (lambda (finding)
     (eq (getf finding :status) :ok))
   (getf report :findings)))

(defun write-report-sexp (report path)
  (ensure-directories-exist path)
  (with-open-file (out path
                       :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create
                       :external-format :utf-8)
    (let ((*print-pretty* t)
          (*print-circle* t))
      (prin1 report out)
      (terpri out)))
  path)

(defun write-report-html (report path)
  (ensure-directories-exist path)
  (with-open-file (out path
                       :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create
                       :external-format :utf-8)
    (format out "<!doctype html>~%")
    (format out "<html><head><meta charset=\"utf-8\"><title>HyperDoc Runtime Closure Validation Report</title></head><body>~%")
    (format out "<h1>HyperDoc Runtime Closure Validation Report</h1>~%")
    (format out "<p>Generated: ~A</p>~%"
            (html-escape (getf report :generated-at)))
    (format out "<p>Overall: <strong>~A</strong></p>~%"
            (html-escape (getf report :overall-status)))
    (format out "<h2>Findings</h2>~%")
    (format out "<table><thead><tr><th>Name</th><th>Status</th><th>Detail</th></tr></thead><tbody>~%")
    (dolist (finding (getf report :findings))
      (format out "<tr><td><code>~A</code></td><td><code>~A</code></td><td><pre>~A</pre></td></tr>~%"
              (html-escape (getf finding :name))
              (html-escape (getf finding :status))
              (html-escape (getf finding :detail))))
    (format out "</tbody></table>~%")
    (format out "<h2>Report S-expression</h2><pre>~A</pre>~%"
            (html-escape report))
    (format out "</body></html>~%"))
  path)

(defun validate-hyperdoc-runtime-closure
    (&key closure-sexp-path validation-sexp-path validation-html-path repo-root)
  (let* ((closure (read-runtime-closure closure-sexp-path))
         (findings
           (append
            (audit-findings closure repo-root closure-sexp-path)
            (closure-preflight-findings closure)
            (validate-native-library-loadability closure)
            (saved-image-dynamic-port-smoke closure validation-sexp-path)))
         (overall (if (every (lambda (f) (eq (getf f :status) :ok)) findings)
                      :ok
                      :fail))
         (report
           (list
            :hyperdoc-runtime-closure-validation-report t
            :title "HyperDoc Runtime Closure Validation Report"
            :generated-at (now-utc-string)
            :closure-sexp (namestring closure-sexp-path)
            :validation-sexp (namestring validation-sexp-path)
            :validation-html (namestring validation-html-path)
            :overall-status overall
            :findings findings)))
    (write-report-sexp report validation-sexp-path)
    (write-report-html report validation-html-path)
    (format t "~&HyperDoc Runtime Closure Validation Report~%")
    (format t "  closure: ~A~%" closure-sexp-path)
    (format t "  report:  ~A~%" validation-sexp-path)
    (format t "  html:    ~A~%" validation-html-path)
    (format t "  overall: ~A~%" overall)
    (dolist (finding findings)
      (format t "  ~A  ~A  ~A~%"
              (getf finding :status)
              (getf finding :name)
              (getf finding :detail)))
    report))

;;;; Runtime closure validation teardown classification overrides.
;;;; These definitions intentionally appear before the command-line entrypoint
;;;; so the validator can distinguish loadability failure from probe shutdown noise.

(defun proof-log-tail (log-text &optional (limit 2000))
  (if (> (length log-text) limit)
      (subseq log-text (- (length log-text) limit))
      log-text))

(defun proof-log-has-teardown-noise-p (log-text)
  (or (search "JOIN-THREAD-ERROR" log-text :test #'char=)
      (search "thread failed" log-text :test #'char=)
      (search "unhandled condition in --disable-debugger mode, quitting"
              log-text
              :test #'char=)))

(defun validation-finding-fail-p (finding)
  (eq (getf finding :status) :fail))

(defun validation-finding-warn-p (finding)
  (eq (getf finding :status) :warn))

(defun validation-overall-status (findings)
  (cond
    ((some #'validation-finding-fail-p findings)
     :fail)
    ((some #'validation-finding-warn-p findings)
     :warn)
    (t
     :ok)))

(defun report-ok-p (report)
  "Return true when REPORT has no hard failures.

A :WARN finding is still a successful proof run. It marks a condition that is
worth inspecting, but does not invalidate loadability."
  (notany #'validation-finding-fail-p
          (getf report :findings)))

(defun saved-image-dynamic-port-smoke (closure validation-sexp-path)
  (let* ((server (closure-get closure :server-executable))
         (boot-path (or (closure-get closure :boot-path) "/boot.html"))
         (library-path (runtime-library-env closure))
         (log-path (server-smoke-log-path validation-sexp-path))
         (port (choose-validation-port))
         (url (format nil "http://127.0.0.1:~D~A" port boot-path))
         (argv (list "env"
                     (format nil "HYPERDOC_PORT=~D" port)
                     "HYPERDOC_DEVELOPMENT=0"
                     (format nil "HYPERDOC_RUNTIME_LIBRARY_PATH=~A" library-path)
                     (format nil "LD_LIBRARY_PATH=~A" library-path)
                     (format nil "DYLD_LIBRARY_PATH=~A" library-path)
                     (format nil "DYLD_FALLBACK_LIBRARY_PATH=~A" library-path)
                     server))
         (process nil)
         (ready nil)
         (readiness-finding nil))
    (ensure-directories-exist log-path)
    (with-open-file (log-stream log-path
                                :direction :output
                                :if-exists :supersede
                                :if-does-not-exist :create
                                :external-format :utf-8)
      (unwind-protect
           (progn
             (setf process
                   (uiop:launch-program
                    argv
                    :output log-stream
                    :error-output log-stream
                    :input :interactive))
             (loop repeat 120
                   do (progn
                        (finish-output log-stream)
                        (when (curl-ok-p url)
                          (setf ready t)
                          (return))
                        (sleep 0.25)))
             (finish-output log-stream)
             (let ((log-text (read-file-string/safe log-path)))
               (setf readiness-finding
                     (cond
                       ((not ready)
                        (finding "saved-image/dynamic-port"
                                 :fail
                                 (format nil "server did not become ready at ~A" url)
                                 :port port
                                 :url url
                                 :log-file (namestring log-path)
                                 :log-tail (proof-log-tail log-text)))
                       ((not (search (format nil "Port: ~D" port)
                                     log-text
                                     :test #'char=))
                        (finding "saved-image/dynamic-port"
                                 :fail
                                 (format nil "server responded at ~A, but log did not prove HYPERDOC_PORT=~D"
                                         url port)
                                 :port port
                                 :url url
                                 :log-file (namestring log-path)
                                 :log-tail (proof-log-tail log-text)))
                       (t
                        (finding "saved-image/dynamic-port"
                                 :ok
                                 (format nil "served ~A and logged Port: ~D" url port)
                                 :port port
                                 :url url
                                 :log-file (namestring log-path)))))))
        (when process
          (ignore-errors (uiop:terminate-process process))
          (sleep 0.5)
          (ignore-errors (uiop:wait-process process)))
        (finish-output log-stream)))
    (let* ((post-log-text (read-file-string/safe log-path))
           (teardown-finding
             (if (proof-log-has-teardown-noise-p post-log-text)
                 (finding
                  "saved-image/probe-teardown"
                  :warn
                  "saved image served the requested boot URL, but forced probe teardown logged Hunchentoot/SBCL thread shutdown noise"
                  :port port
                  :url url
                  :log-file (namestring log-path)
                  :log-tail (proof-log-tail post-log-text))
                 (finding
                  "saved-image/probe-teardown"
                  :ok
                  "probe process terminated without recognized teardown noise"
                  :port port
                  :url url
                  :log-file (namestring log-path)))))
      (list readiness-finding teardown-finding))))

(defun validate-hyperdoc-runtime-closure
    (&key closure-sexp-path validation-sexp-path validation-html-path repo-root)
  (let* ((closure (read-runtime-closure closure-sexp-path))
         (findings
           (append
            (audit-findings closure repo-root closure-sexp-path)
            (closure-preflight-findings closure)
            (validate-native-library-loadability closure)
            (saved-image-dynamic-port-smoke closure validation-sexp-path)))
         (overall (validation-overall-status findings))
         (report
           (list
            :hyperdoc-runtime-closure-validation-report t
            :title "HyperDoc Runtime Closure Validation Report"
            :generated-at (now-utc-string)
            :closure-sexp (namestring closure-sexp-path)
            :validation-sexp (namestring validation-sexp-path)
            :validation-html (namestring validation-html-path)
            :overall-status overall
            :findings findings)))
    (write-report-sexp report validation-sexp-path)
    (write-report-html report validation-html-path)
    (format t "~&HyperDoc Runtime Closure Validation Report~%")
    (format t "  closure: ~A~%" closure-sexp-path)
    (format t "  report:  ~A~%" validation-sexp-path)
    (format t "  html:    ~A~%" validation-html-path)
    (format t "  overall: ~A~%" overall)
    (dolist (finding findings)
      (format t "  ~A  ~A  ~A~%"
              (getf finding :status)
              (getf finding :name)
              (getf finding :detail)))
    report))

(let* ((repo-root
         (uiop:ensure-directory-pathname
          (or (and (boundp 'cl-user::*hyperdoc-root*)
                   cl-user::*hyperdoc-root*)
              (uiop:getcwd))))
       (closure-sexp
         (or (and (boundp 'cl-user::*hyperdoc-runtime-closure-sexp*)
                  cl-user::*hyperdoc-runtime-closure-sexp*)
             (merge-pathnames #P"bundle-deploy/hyperdoc-frame/hyperdoc-runtime-closure.sexp"
                              repo-root)))
       (validation-sexp
         (or (and (boundp 'cl-user::*hyperdoc-runtime-validation-sexp*)
                  cl-user::*hyperdoc-runtime-validation-sexp*)
             (merge-pathnames #P"bundle-deploy/hyperdoc-frame/hyperdoc-runtime-closure-validation.sexp"
                              repo-root)))
       (validation-html
         (or (and (boundp 'cl-user::*hyperdoc-runtime-validation-html*)
                  cl-user::*hyperdoc-runtime-validation-html*)
             (merge-pathnames #P"bundle-deploy/hyperdoc-frame/hyperdoc-runtime-closure-validation.html"
                              repo-root)))
       (report
         (validate-hyperdoc-runtime-closure
          :closure-sexp-path closure-sexp
          :validation-sexp-path validation-sexp
          :validation-html-path validation-html
          :repo-root (namestring repo-root))))
  (uiop:quit (if (report-ok-p report) 0 1)))
