;;;; The demonstration's configuration, in plain CL and UIOP: which variables are read, what each mode offers, and that
;;;; nothing falls back to another site. Runs without the Catalog, from a bare SBCL:
;;;;   sbcl --non-interactive --eval '(require :asdf)' --load dreyeck/src/fedwiki-original-editor-configuration.lisp \
;;;;        --load dreyeck/tests/fedwiki-original-editor-configuration.lisp \
;;;;        --eval '(dreyeck/fedwiki-original-editor-configuration/tests:run-tests)'
(defpackage #:dreyeck/fedwiki-original-editor-configuration/tests
  (:use #:cl)
  (:local-nicknames (#:cfg #:dreyeck/fedwiki-original-editor-configuration))
  (:export #:run-tests #:call-with-site-directory))
(in-package #:dreyeck/fedwiki-original-editor-configuration/tests)

(defun %environment (alist)
  "A GETENV of ALIST, ((name . value) ...); every other variable is unset."
  (lambda (name) (cdr (assoc name alist :test #'equal))))

(defun call-with-site-directory (function)
  "Call FUNCTION with the native namestring of a fresh, empty directory, removed afterwards."
  (let ((directory (uiop:ensure-directory-pathname
                    (merge-pathnames (format nil "hyperdoc-editor-configuration-~36R/" (random (expt 36 8) (make-random-state t)))
                                     (uiop:temporary-directory)))))
    (ensure-directories-exist directory)
    (unwind-protect (funcall function (uiop:native-namestring directory))
      (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore))))

(defun configuration (&rest alist)
  (cfg:read-editor-configuration (%environment alist)))

(defun check-unset ()
  "Nothing set: unconfigured, nothing offered, and the reason names the variable."
  (let ((c (configuration)))
    (assert (eq :unconfigured (cfg:configuration-mode c)))
    (assert (null (cfg:configuration-root c)))
    (assert (null (cfg:configuration-origin c)))
    (assert (null (cfg:client-url c)))
    (assert (null (cfg:embedded-editor-url c "abc")))
    (assert (not (cfg:editor-offered-p c)))
    (assert (some (lambda (p) (search cfg:+root-variable+ p)) (cfg:configuration-problems c))))
  ;; Empty values are unset values.
  (let ((c (configuration (cons cfg:+root-variable+ "") (cons cfg:+origin-variable+ "") (cons cfg:+mode-variable+ ""))))
    (assert (eq :unconfigured (cfg:configuration-mode c)))
    (assert (null (cfg:configuration-requested-mode c))))
  t)

(defun check-no-fallback-to-other-sites ()
  "The Catalog's own site root, or any other site variable, is never used for this demonstration."
  (call-with-site-directory
   (lambda (site)
     (let ((c (configuration (cons "HYPERDOC_FEDWIKI_SITE_ROOT" site)
                             (cons cfg:+origin-variable+ "http://127.0.0.1:3000")
                             (cons cfg:+mode-variable+ "isolated-loopback"))))
       (assert (eq :unconfigured (cfg:configuration-mode c)))
       (assert (null (cfg:configuration-root c)))
       (assert (null (cfg:client-url c)))
       (assert (null (cfg:embedded-editor-url c "abc"))))))
  t)

(defun check-unusable-root ()
  (dolist (value '("relative/site/" "/nonexistent/hyperdoc-editor-test-site/"))
    (let ((c (configuration (cons cfg:+root-variable+ value) (cons cfg:+origin-variable+ "http://127.0.0.1:3000")
                            (cons cfg:+mode-variable+ "isolated-loopback"))))
      (assert (eq :unconfigured (cfg:configuration-mode c)))
      (assert (null (cfg:configuration-root c)))
      (assert (equal value (cfg:configuration-root-variable-value c)))
      (assert (not (cfg:editor-offered-p c)))
      (assert (= 1 (length (cfg:configuration-problems c))))))
  t)

(defun check-read-only ()
  "A site without a mode, or with read-only, is read back; the client is linked only for a valid origin; no editor."
  (call-with-site-directory
   (lambda (site)
     (dolist (mode '(nil "read-only"))
       (let ((c (apply #'configuration (cons cfg:+root-variable+ site) (cons cfg:+origin-variable+ "https://wiki.example.invalid")
                       (and mode (list (cons cfg:+mode-variable+ mode))))))
         (assert (eq :read-only (cfg:configuration-mode c)))
         (assert (equal (truename site) (cfg:configuration-root c)))
         (assert (equal "https://wiki.example.invalid/view/original-editor-test" (cfg:client-url c)))
         (assert (null (cfg:embedded-editor-url c "abc")))
         (assert (null (cfg:configuration-problems c)))))
     ;; Without an origin: read back, nothing linked.
     (let ((c (configuration (cons cfg:+root-variable+ site))))
       (assert (eq :read-only (cfg:configuration-mode c)))
       (assert (null (cfg:client-url c))))
     ;; An origin with a path, query or other scheme is refused and named, not repaired.
     (dolist (origin '("http://127.0.0.1:3000/view/x" "http://127.0.0.1:3000?x=1" "javascript:alert(1)" "file:///etc"
                       "http://" "http://a b" "http://127.0.0.1:3000\"><script>" "//127.0.0.1:3000"))
       (let ((c (configuration (cons cfg:+root-variable+ site) (cons cfg:+origin-variable+ origin)
                               (cons cfg:+mode-variable+ "isolated-loopback"))))
         (assert (eq :read-only (cfg:configuration-mode c)) () "~S" origin)
         (assert (null (cfg:configuration-origin c)) () "~S" origin)
         (assert (null (cfg:client-url c)))
         (assert (null (cfg:embedded-editor-url c "abc")))
         (assert (some (lambda (p) (search cfg:+origin-variable+ p)) (cfg:configuration-problems c)))))))
  t)

(defun check-isolated-loopback ()
  "Only isolated-loopback with an http://127.0.0.1:PORT origin embeds the editor, for the one fixed Item."
  (call-with-site-directory
   (lambda (site)
     (let ((c (configuration (cons cfg:+root-variable+ site) (cons cfg:+origin-variable+ "http://127.0.0.1:41234/")
                             (cons cfg:+mode-variable+ "isolated-loopback"))))
       (assert (eq :isolated-loopback-editor (cfg:configuration-mode c)))
       (assert (cfg:editor-offered-p c))
       (assert (equal "http://127.0.0.1:41234" (cfg:configuration-origin c)))
       (assert (equal "http://127.0.0.1:41234/view/original-editor-test?hyperdocCodeItem=2222222222222222&revision=abc"
                      (cfg:embedded-editor-url c "abc")))
       (assert (null (cfg:embedded-editor-url c nil))))
     ;; Not loopback, not http, no port, another loopback spelling: read-only, with the reason.
     (dolist (origin '("https://dreyeck.ch" "https://original-editor-test.dreyeck.ch" "http://localhost:3000"
                       "https://127.0.0.1:3000" "http://127.0.0.1" "http://127.0.0.1:0" "http://127.0.0.1:65536"
                       "http://127.0.0.2:3000" "http://[::1]:3000"))
       (let ((c (configuration (cons cfg:+root-variable+ site) (cons cfg:+origin-variable+ origin)
                               (cons cfg:+mode-variable+ "isolated-loopback"))))
         (assert (eq :read-only (cfg:configuration-mode c)) () "~S" origin)
         (assert (not (cfg:editor-offered-p c)))
         (assert (null (cfg:embedded-editor-url c "abc")))
         (assert (some (lambda (p) (search "isolated-loopback" p)) (cfg:configuration-problems c)) () "~S" origin)))
     ;; A loopback origin alone embeds nothing: the mode is a separate decision.
     (assert (eq :read-only (cfg:configuration-mode (configuration (cons cfg:+root-variable+ site)
                                                                   (cons cfg:+origin-variable+ "http://127.0.0.1:41234")))))
     ;; Unknown modes, including any spelling of a farm or write mode, are refused and named.
     (dolist (mode '("wiki-farm" "write" "true" "ISOLATED-LOOPBACK" "isolated-loopback "))
       (let ((c (configuration (cons cfg:+root-variable+ site) (cons cfg:+origin-variable+ "http://127.0.0.1:41234")
                               (cons cfg:+mode-variable+ mode))))
         (assert (eq :read-only (cfg:configuration-mode c)) () "~S" mode)
         (assert (equal mode (cfg:configuration-requested-mode c)))
         (assert (some (lambda (p) (search "not a known mode" p)) (cfg:configuration-problems c)) () "~S" mode)))))
  t)

(defun check-coordinates-are-fixed ()
  "The target is the declared one, whatever the environment says."
  (let ((c (configuration (cons "HYPERDOC_FEDWIKI_EDITOR_TEST_SITE" "fedwiki:dreyeck.ch")
                          (cons "HYPERDOC_FEDWIKI_EDITOR_TEST_SLUG" "welcome-visitors"))))
    (assert (equal "fedwiki:original-editor-test.invalid" (cfg:configuration-site c)))
    (assert (equal "original-editor-test" (cfg:configuration-slug c)))
    (assert (equal "2222222222222222" (cfg:configuration-code-item-id c))))
  t)

(defun run-tests ()
  (check-unset)
  (check-no-fallback-to-other-sites)
  (check-unusable-root)
  (check-read-only)
  (check-isolated-loopback)
  (check-coordinates-are-fixed)
  (format t "~&FEDWIKI-ORIGINAL-EDITOR-CONFIGURATION-PASS: unset and unusable values give an unconfigured, read-only demonstration with the reason; no other site variable is used; only isolated-loopback with http://127.0.0.1:PORT embeds the editor; unknown modes and malformed origins are refused and named; the target coordinates are fixed.~%")
  t)
