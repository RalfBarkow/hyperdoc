;;;; A name-service failure while initializing a FedWiki proxy is retained in
;;;; its status; it must not escape the initializer thread.
;;;;
;;;; An unhandled condition in a thread invokes the debugger.  Under
;;;; --disable-debugger (sbcl --script, the packaged hyperdoc-catalog) that ends
;;;; the whole process.  USOCKET:NS-TRY-AGAIN-ERROR (EAI_AGAIN, a transient
;;;; resolver failure) used to escape that way.

(defpackage #:dreyeck/fedwiki-name-service/tests
  (:use #:cl)
  (:export #:run-fedwiki-name-service-tests))

(in-package #:dreyeck/fedwiki-name-service/tests)

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defparameter *domain* "ward.voices.ustawi.wiki"
  "The site whose lookup failed in the network-less build sandbox.")

(defun name-service-conditions ()
  "One instance of every USOCKET name-service error class."
  (mapcar (lambda (type) (make-condition type :host-or-ip *domain*))
          '(usocket:ns-try-again-error
            usocket:ns-host-not-found-error
            usocket:ns-no-recovery-error
            usocket:ns-unknown-error)))

(defun never-called (name)
  (lambda (&rest arguments)
    (declare (ignore arguments))
    (error "~A must not run after a failed protocol probe." name)))

(defun failing-probe (condition)
  (lambda (domain-name)
    (check (string= domain-name *domain*) "Unexpected domain ~S." domain-name)
    (error condition)))

(defun run-status-retention-test ()
  "INITIALIZE-FEDWIKI retains each name-service error and stops there."
  (dolist (condition (name-service-conditions))
    (let ((wiki (make-instance 'hyperbook/fedwiki::fedwiki
                               :id (concatenate 'string "fedwiki:" *domain*)))
          (escaped nil))
      (handler-case
          (hyperbook/fedwiki::initialize-fedwiki
           wiki *domain*
           :protocol-probe (failing-probe condition)
           :sitemap-fetcher (never-called "sitemap fetcher")
           :plugin-data-fetcher (never-called "plugin data fetcher"))
        (error (c) (setf escaped c)))
      (check (null escaped)
             "~S escaped INITIALIZE-FEDWIKI as ~S." (type-of condition) escaped)
      (check (eq condition (hyperbook/fedwiki::status-of wiki))
             "~S was not retained in the status: ~S."
             (type-of condition) (hyperbook/fedwiki::status-of wiki))
      ;; A resolver failure is no evidence about HTTPS: the protocol stays.
      (check (string= "https" (hyperbook/fedwiki::protocol-of wiki))
             "~S changed the protocol to ~S."
             (type-of condition) (hyperbook/fedwiki::protocol-of wiki))))
  t)

(defun run-other-errors-still-escape-test ()
  "Only name-service errors are added; any other operational error still escapes."
  (let ((wiki (make-instance 'hyperbook/fedwiki::fedwiki
                             :id (concatenate 'string "fedwiki:" *domain*)))
        (marker (make-condition 'simple-error :format-control "unrelated")))
    (check (eq marker
               (handler-case
                   (hyperbook/fedwiki::initialize-fedwiki
                    wiki *domain* :protocol-probe (failing-probe marker))
                 (simple-error (c) c)))
           "An unrelated error no longer escapes INITIALIZE-FEDWIKI.")
    (check (not (typep (hyperbook/fedwiki::status-of wiki) 'condition))
           "An unrelated error was retained in the status."))
  t)

(defun child-sbcl-form (condition-type)
  "The form the child evaluates once HYPERBOOK/FEDWIKI is loaded."
  (format nil "(let ((wiki (hyperbook/fedwiki::make-fedwiki ~S
                        :protocol-probe
                        (lambda (domain-name)
                          (error '~A :host-or-ip domain-name))
                        :sitemap-fetcher (constantly nil)
                        :plugin-data-fetcher (constantly nil))))
             (hyperbook/fedwiki::wait-for-sitemap wiki)
             (format t \"~~&STATUS-RETAINED ~~A~~%\"
                     (type-of (hyperbook/fedwiki::status-of wiki))))"
          *domain*
          (let ((*package* (find-package :cl-user)))
            (prin1-to-string condition-type))))

(defun tail (string &optional (count 700))
  (subseq string (max 0 (- (length string) count))))

(defun run-process-survives-test ()
  "With the debugger disabled, as in sbcl --script, the process outlives the failure."
  (dolist (type '(usocket:ns-try-again-error usocket:ns-host-not-found-error))
    (let (output error-output status)
      (multiple-value-setq (output error-output status)
        (uiop:run-program
         (list (namestring sb-ext:*runtime-pathname*)
               "--core" (namestring sb-ext:*core-pathname*)
               "--noinform" "--disable-debugger" "--no-sysinit" "--no-userinit"
               ;; Separate forms: each is read after the previous one ran.
               "--eval" "(require :asdf)"
               "--eval" "(asdf:load-system \"hyperbook/fedwiki\")"
               "--eval" (child-sbcl-form type)
               "--eval" "(sb-ext:exit :code 0)")
         :input nil :output :string :error-output :string
         :ignore-error-status t))
      (check (and (eql 0 status)
                  (search (format nil "STATUS-RETAINED ~A" (symbol-name type))
                          output :test #'char-equal))
             "~S ended the process (exit ~S): ~A~A" type status
             (tail output) (tail error-output))))
  t)

(defun run-fedwiki-name-service-tests ()
  (run-status-retention-test)
  (run-other-errors-still-escape-test)
  (run-process-survives-test)
  (format t "~&FEDWIKI-NAME-SERVICE-PASS~%")
  t)
