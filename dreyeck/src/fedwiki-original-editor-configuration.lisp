;;;; Explicit configuration of the Original Wiki Editor demonstration. Plain CL and UIOP only.
;;;;
;;;; Three decisions stay apart:
;;;;  1. Loading: dreyeck/catalog depends on dreyeck/fedwiki-original-editor-demo, so the HyperBook is in every Catalog.
;;;;     Loading reads no variable below and offers no editor.
;;;;  2. Wiki connection: HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT names the one site directory read back (never written),
;;;;     HYPERDOC_FEDWIKI_EDITOR_TEST_ORIGIN the origin of an original Wiki server for that site. Neither has a default,
;;;;     and neither falls back to HYPERDOC_FEDWIKI_SITE_ROOT or any other site.
;;;;  3. Embedding the editor: only HYPERDOC_FEDWIKI_EDITOR_TEST_MODE=isolated-loopback, and only for an origin
;;;;     http://127.0.0.1:PORT. This only decides whether HyperDoc offers the frame. Whether a write succeeds is decided
;;;;     by the original Wiki server's own security module; HyperDoc never writes and holds no Wiki credential.
;;;;     No mode for a Wiki farm exists: that needs an authorization decision (docs/fedwiki-original-editor-farm/README.md).
(defpackage #:dreyeck/fedwiki-original-editor-configuration
  (:use #:cl)
  (:export #:+site+ #:+slug+ #:+code-item-id+ #:+paragraph-slug+ #:+paragraph-item-id+ #:embedded-item-editor-url
           #:+root-variable+ #:+origin-variable+ #:+mode-variable+
           #:editor-configuration #:read-editor-configuration
           #:configuration-root #:configuration-origin #:configuration-requested-mode #:configuration-mode
           #:configuration-problems #:configuration-site #:configuration-slug #:configuration-code-item-id
           #:configuration-root-variable-value #:configuration-origin-variable-value
           #:editor-offered-p #:client-url #:embedded-editor-url #:loopback-origin-p #:mode-description))
(in-package #:dreyeck/fedwiki-original-editor-configuration)

;;; The fixed coordinates of the one isolated target. They are the demonstration's declared target, not configuration:
;;; a different site would be a different, separately reviewed target.
(defparameter +site+ "fedwiki:original-editor-test.invalid")
(defparameter +slug+ "original-editor-test")
(defparameter +code-item-id+ "2222222222222222")
;;; The second declared target, on the same disposable site: the Paragraph Item that is the Wiki counterpart of the
;;; introductory paragraph of "Assessing an Upstream Commit" (docs/fedwiki-paragraph-association.md). The original server
;;; adapter (tests/fedwiki-original-editor/server.mjs) holds the same pair and refuses any other.
(defparameter +paragraph-slug+ "assessing-an-upstream-commit")
(defparameter +paragraph-item-id+ "5555555555555555")

(defparameter +root-variable+ "HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT")
(defparameter +origin-variable+ "HYPERDOC_FEDWIKI_EDITOR_TEST_ORIGIN")
(defparameter +mode-variable+ "HYPERDOC_FEDWIKI_EDITOR_TEST_MODE")

(defclass editor-configuration ()
  ((site :initform +site+ :reader configuration-site)
   (slug :initform +slug+ :reader configuration-slug)
   (code-item-id :initform +code-item-id+ :reader configuration-code-item-id)
   (root-variable-value :initarg :root-variable-value :reader configuration-root-variable-value
                        :documentation "The value of HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT as read, or NIL.")
   (origin-variable-value :initarg :origin-variable-value :reader configuration-origin-variable-value
                          :documentation "The value of HYPERDOC_FEDWIKI_EDITOR_TEST_ORIGIN as read, or NIL.")
   (root :initarg :root :reader configuration-root
         :documentation "The existing site directory, a truename, or NIL when absent or unusable.")
   (origin :initarg :origin :reader configuration-origin
           :documentation "The accepted Wiki origin, scheme://host[:port] without a trailing slash, or NIL.")
   (requested-mode :initarg :requested-mode :reader configuration-requested-mode
                   :documentation "The value of HYPERDOC_FEDWIKI_EDITOR_TEST_MODE as read, or NIL.")
   (mode :initarg :mode :reader configuration-mode
         :documentation ":UNCONFIGURED (no readable site), :READ-ONLY, or :ISOLATED-LOOPBACK-EDITOR.")
   (problems :initarg :problems :reader configuration-problems
             :documentation "Readable reasons, one string each, why something configured is not used."))
  (:documentation "One reading of the demonstration's environment. Making it reads the environment and probes one
directory; it writes nothing and opens no connection."))

(defun %value (getenv name)
  (let ((value (funcall getenv name)))
    (and (stringp value) (plusp (length value)) value)))

(defun %origin (value)
  "VALUE as an origin, scheme://host[:port] with an http or https scheme and nothing after the authority, or NIL."
  (let* ((value (if (and (> (length value) 1) (char= #\/ (char value (1- (length value)))))
                    (subseq value 0 (1- (length value)))
                    value))
         (scheme (find-if (lambda (prefix) (uiop:string-prefix-p prefix value)) '("http://" "https://")))
         (authority (and scheme (subseq value (length scheme)))))
    (and authority (plusp (length authority))
         (every (lambda (c) (or (alphanumericp c) (find c ".-:[]"))) authority)
         (not (char= #\: (char authority 0)))
         value)))

(defun loopback-origin-p (origin)
  "Whether ORIGIN is http://127.0.0.1:PORT, the only origin the isolated test's original server listens on."
  (let ((prefix "http://127.0.0.1:"))
    (and (stringp origin) (uiop:string-prefix-p prefix origin)
         (let ((port (subseq origin (length prefix))))
           (and (<= 1 (length port) 5) (every #'digit-char-p port)
                (<= 1 (parse-integer port) 65535))))))

(defun %directory (value problems)
  (cond ((not (uiop:absolute-pathname-p (uiop:parse-native-namestring value)))
         (push (format nil "~A is not an absolute directory: ~S. No site is read." +root-variable+ value) (car problems))
         nil)
        (t (let ((directory (ignore-errors (uiop:directory-exists-p (uiop:ensure-directory-pathname
                                                                     (uiop:parse-native-namestring value))))))
             (or (and directory (truename directory))
                 (progn (push (format nil "~A names no existing directory: ~S. No site is read." +root-variable+ value)
                              (car problems))
                        nil))))))

(defun read-editor-configuration (&optional (getenv #'uiop:getenv))
  "The demonstration's configuration from GETENV, a function of a variable name returning its value or NIL. Never
signals for a missing or unusable value: the reason is in CONFIGURATION-PROBLEMS and the mode falls back to read-only
or unconfigured."
  (let* ((problems (list '()))
         (root-value (%value getenv +root-variable+))
         (origin-value (%value getenv +origin-variable+))
         (requested (%value getenv +mode-variable+))
         (root (and root-value (%directory root-value problems)))
         (origin (and origin-value
                      (or (%origin origin-value)
                          (progn (push (format nil "~A is not an http(s) origin without path: ~S. No Wiki client is linked."
                                               +origin-variable+ origin-value)
                                       (car problems))
                                 nil))))
         (mode
           (cond ((null root)
                  (unless root-value
                    (push (format nil "~A is not set: this Catalog has no isolated test site." +root-variable+) (car problems)))
                  :unconfigured)
                 ((or (null requested) (string= requested "read-only")) :read-only)
                 ((string= requested "isolated-loopback")
                  (cond ((loopback-origin-p origin) :isolated-loopback-editor)
                        (t (push (format nil "~A=isolated-loopback needs ~A of the form http://127.0.0.1:PORT; got ~S. The editor is not offered."
                                         +mode-variable+ +origin-variable+ (or origin-value "nothing"))
                                 (car problems))
                           :read-only)))
                 (t (push (format nil "~A=~S is not a known mode (read-only, isolated-loopback). Editing through a Wiki farm is not decided. The editor is not offered."
                                  +mode-variable+ requested)
                          (car problems))
                    :read-only))))
    (make-instance 'editor-configuration
                   :root-variable-value root-value :origin-variable-value origin-value
                   :root root :origin origin :requested-mode requested :mode mode
                   :problems (reverse (car problems)))))

(defun editor-configuration () (read-editor-configuration))

(defun editor-offered-p (configuration)
  (eq :isolated-loopback-editor (configuration-mode configuration)))

(defun client-url (configuration)
  "The original Wiki client's view of the target page at the configured origin, or NIL. A link only: whoever follows it
meets the Wiki server's own authorization."
  (let ((origin (configuration-origin configuration)))
    (and origin (configuration-root configuration)
         (format nil "~A/view/~A" origin (configuration-slug configuration)))))

(defun embedded-editor-url (configuration revision)
  "The frame URL of the item-specific original editor for REVISION, the observed SHA-256, or NIL unless the editor is offered."
  (and (editor-offered-p configuration) (stringp revision)
       (format nil "~A/view/~A?hyperdocCodeItem=~A&revision=~A" (configuration-origin configuration)
               (configuration-slug configuration) (configuration-code-item-id configuration) revision)))

(defun embedded-item-editor-url (configuration slug item-id revision)
  "The frame URL of the original editor of the one declared Item ITEM-ID of page SLUG for REVISION, or NIL unless the
editor is offered. Only the pair (+PARAGRAPH-SLUG+, +PARAGRAPH-ITEM-ID+) is a target here; the server adapter refuses
every other pairing as well."
  (and (editor-offered-p configuration) (stringp revision)
       (equal slug +paragraph-slug+) (equal item-id +paragraph-item-id+)
       (format nil "~A/view/~A?hyperdocItem=~A&revision=~A" (configuration-origin configuration) slug item-id revision)))

(defun mode-description (configuration)
  (ecase (configuration-mode configuration)
    (:unconfigured "Not configured: no isolated test site is read, no Wiki client is linked and no editor is offered.")
    (:read-only "Read-only: the configured site is read back; no editor is embedded.")
    (:isolated-loopback-editor "Isolated loopback test: the original editor of the loopback Wiki server is embedded for the one Code Item; that server authorizes and performs every write.")))
