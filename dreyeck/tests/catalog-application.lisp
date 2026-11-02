(defpackage #:dreyeck/catalog-application/tests
  (:use #:cl)
  (:export #:run-tests))
(in-package #:dreyeck/catalog-application/tests)

(defun rejects (thunk)
  (handler-case (progn (funcall thunk) nil) (error () t)))

(defun check-configuration ()
  (flet ((environment (name)
           (cdr (assoc name '(("HYPERDOC_CATALOG_PORT" . "8099")
                              ("HYPERDOC_CATALOG_HOST" . "127.0.0.1")
                              ("HYPERDOC_CATALOG_SYSTEM" . "hyperdoc")
                              ("HYPERDOC_MECH_PLUGIN_HOST_URL" . "https://mech.dreyeck.ch/assets/hyperdoc-mech/"))
                       :test #'equal))))
    (let ((configuration
            (dreyeck/catalog-application::%configuration nil #'environment)))
      (assert (= 8099 (getf configuration :port)))
      (assert (equal "127.0.0.1" (getf configuration :host)))
      (assert (equal "hyperdoc" (getf configuration :catalog-system)))
      (assert (equal "https://mech.dreyeck.ch/assets/hyperdoc-mech/"
                     (getf configuration :mech-plugin-host-url))))
    (assert (= 8100 (getf (dreyeck/catalog-application::%configuration
                           '("8100") #'environment) :port))))
  (let ((configuration (dreyeck/catalog-application::%configuration
                        nil (constantly nil))))
    (assert (= 8080 (getf configuration :port)))
    (assert (equal "0.0.0.0" (getf configuration :host)))
    (assert (equal "dreyeck/catalog" (getf configuration :catalog-system)))
    (assert (null (getf configuration :mech-plugin-host-url))))
  (assert (null (getf (dreyeck/catalog-application::%configuration
                       nil (lambda (name)
                             (when (equal name "HYPERDOC_MECH_PLUGIN_HOST_URL") "")))
                     :mech-plugin-host-url)))
  (dolist (bad '("" "0" "65536" "-1" "+80" " 80" "80 " "1.5" "abc"))
    (assert (rejects (lambda ()
                      (dreyeck/catalog-application::%configuration (list bad))))))
  (assert (rejects (lambda ()
                    (dreyeck/catalog-application::%configuration '("80" "81"))))))

(defun check-start ()
  ;; A single ASDF load must materialize all books, server and the dynamically
  ;; selected Clack backend. No script-ordered prerequisite loads are needed.
  (dolist (system '("hyperdoc" "hyperbook/server" "dreyeck/catalog"
                    "dreyeck/local-fedwiki-view" "clack-handler-hunchentoot"))
    (assert (asdf:component-loaded-p (asdf:find-system system))))
  (assert (hyperbook:find-hyperbook "dreyeck/authority/reading"))
  (assert (hyperbook:find-hyperbook "dreyeck/clog-tutorial/reading"))
  (assert (hyperbook:find-hyperbook "dreyeck/nested-actions/reading"))
  ;; Function, not admission: every admitted HyperBook is materialized, each
  ;; once. Which books are admitted is checked as a closed set by the fresh
  ;; Catalog startup test; here a further registered book is no failure.
  (let ((problems (dreyeck/catalog/tests:admitted-membership-problems
                   (dreyeck/catalog/tests:catalog-hyperbook-ids))))
    (assert (null (getf problems :missing)))
    (assert (null (getf problems :duplicated))))
  (assert (null (find-package :dreyeck/workflow/authoring)))
  (let* ((hyperbook:*catalog* (make-instance 'hyperbook:catalog))
         (observed
           (dreyeck/local-fedwiki-view/tests::call-recording-clog
            (lambda ()
              (dreyeck/catalog-application:start-catalog
               :port 8099 :host "127.0.0.1"
               :site-root (dreyeck/local-fedwiki-view/tests::fixture-site-root)
               :pane-width "650px" :development t :catalog-system "hyperdoc")))))
    (assert (= 8099 (getf (getf observed :clog) :port)))
    (assert (equal "127.0.0.1" (getf (getf observed :clog) :host)))
    (assert (equal '("650px" t) (getf observed :server-parameters)))
    (assert (assoc "/view" (getf observed :routes) :test #'equal))
    (assert (assoc "/gesture" (getf observed :routes) :test #'equal))))

(defun check-mech-host-startup ()
  ;; Use the actual original-page Story view, without opening a browser/server.
  (let ((hyperbook/fedwiki::*mech-plugin-host-url* "https://manual.fixture.test/")
        (page (hyperbook/fedwiki/tests::original-page)))
    (dolist (host '(nil "" "https://mech.dreyeck.ch/assets/hyperdoc-mech/"))
      (let ((configuration
              (dreyeck/catalog-application::%configuration
               nil (lambda (name)
                     (when (equal name "HYPERDOC_MECH_PLUGIN_HOST_URL") host)))))
        (dreyeck/local-fedwiki-view/tests::call-recording-clog
         (lambda ()
           (apply #'dreyeck/catalog-application:start-catalog
                  :site-root (dreyeck/local-fedwiki-view/tests::fixture-site-root)
                  configuration)))
        (let* ((expected (unless (equal host "") host))
               (html (html-inspector-views:view-html
                      (hyperbook/fedwiki/tests::story-view page))))
          (assert (equal expected hyperbook/fedwiki::*mech-plugin-host-url*))
          (assert (search "No Code item has run" html))
          (assert (if expected
                      (search expected html)
                      (search "Wiki plugin host is not configured" html))))))))

(defun check-lifecycle ()
  (let ((start (fdefinition 'dreyeck/catalog-application:start-catalog))
        (wait (fdefinition 'dreyeck/catalog-application::%wait))
        (shutdown (fdefinition 'clog:shutdown))
        (events nil))
    (unwind-protect
         (progn
           (setf (fdefinition 'dreyeck/catalog-application:start-catalog)
                 (lambda (&rest config) (push (cons :start config) events)))
           (setf (fdefinition 'dreyeck/catalog-application::%wait)
                 (lambda () (push :wait events)
                   (signal 'dreyeck/catalog-application::stop-requested)))
           (setf (fdefinition 'clog:shutdown)
                 (lambda () (push :shutdown events)))
           (assert (= 0 (dreyeck/catalog-application:main '("8099"))))
           (assert (equal '(:start :wait :shutdown)
                          (mapcar (lambda (event) (if (consp event) (car event) event))
                                  (reverse events))))
           (assert (= 8099 (getf (cdr (third events)) :port)))
           (assert (null (getf (cdr (third events)) :development)))
           ;; Cleanup must also run when startup fails after opening a listener.
           (setf events nil
                 (fdefinition 'dreyeck/catalog-application:start-catalog)
                 (lambda (&rest ignored) (declare (ignore ignored))
                   (push :partial-start events) (error "Startup witness")))
           (assert (= 1 (dreyeck/catalog-application:main '("8099"))))
           (assert (equal '(:shutdown :partial-start) events))
           (setf events nil)
           (assert (= 1 (dreyeck/catalog-application:main '("invalid"))))
           (assert (null events)))
      (setf (fdefinition 'dreyeck/catalog-application:start-catalog) start
            (fdefinition 'dreyeck/catalog-application::%wait) wait
            (fdefinition 'clog:shutdown) shutdown)
      #+sbcl (sb-sys:enable-interrupt sb-unix:sigterm :default))))

(defun check-start-with-another-hyperbook ()
  "A further, properly registered HyperBook extends the Catalog; it does not
make the checks of what the Catalog does fail. The admission check, given
the same ids, names exactly that book: the extension is visible, only
judged elsewhere."
  ;; An id without a scheme: FIND-HYPERBOOK would hand an absent "fedwiki:" id
  ;; to that scheme's factory, which registers a remote wiki for it.
  (let ((before (copy-list (hyperbook:hyperbooks-of hyperbook:*catalog*)))
        (id "dreyeck/catalog-extension-test"))
    (assert (not (member id (dreyeck/catalog/tests:catalog-hyperbook-ids) :test #'string=)))
    (unwind-protect
         (let ((book (dreyeck/local-fedwiki-page:register-local-fedwiki
                      (dreyeck/local-fedwiki-view/tests::fixture-site-root) id)))
           (assert (eq book (hyperbook:find-hyperbook id)))
           ;; Other registered books may already be present (starting the
           ;; Catalog registers its local wiki); this one is now among the extras.
           (let ((problems (dreyeck/catalog/tests:admitted-membership-problems
                            (dreyeck/catalog/tests:catalog-hyperbook-ids))))
             (assert (member id (getf problems :extra) :test #'string=))
             (assert (null (getf problems :missing)))
             (assert (null (getf problems :duplicated))))
           (check-start))
      (setf (hyperbook:hyperbooks-of hyperbook:*catalog*) before))
    (assert (equal before (hyperbook:hyperbooks-of hyperbook:*catalog*)))))

;;; A name-resolution failure of a remote FedWiki site must not end the process (RalfBarkow/hyperdoc#13).
;;; MAKE-FEDWIKI starts a thread for every site. The packaged hyperdoc-catalog runs with the debugger disabled (sbcl --script), where a
;;; condition that escapes such a thread ends the whole process. So the checks run in a fresh SBCL with the debugger disabled, and
;;; look at its exit status and at what it reports after WAIT-FOR-SITEMAP has returned.

(defun %fresh-sbcl-command (forms &optional prefix)
  (append prefix
          (list (namestring sb-ext:*runtime-pathname*) "--core" (namestring sb-ext:*core-pathname*)
                "--noinform" "--no-sysinit" "--no-userinit" "--non-interactive"
                "--eval" "(require :asdf)"
                "--eval" "(let ((*error-output* (make-broadcast-stream)) (*standard-output* (make-broadcast-stream))) (asdf:load-system \"hyperbook/fedwiki\"))")
          (loop for form in forms append (list "--eval" form))))

(defun %run-fresh-sbcl (forms &optional prefix)
  "Run FORMS in a fresh SBCL with the debugger disabled. Returns the exit status and the output."
  (multiple-value-bind (output error-output status)
      (uiop:run-program (%fresh-sbcl-command forms prefix) :output :string :error-output :string :ignore-error-status t)
    (values status (format nil "~A~A" output error-output))))

(defparameter +site-outcome-form+
  "(defun site-outcome (label wiki)
     ;; Called after WAIT-FOR-SITEMAP has returned: the thread of the site is finished.
     (let ((status (hyperbook/fedwiki::status-of wiki)))
       (format t \"~&OUTCOME ~A ~A ns-error=~A snapshot=~A~%\" label (type-of status) (typep status 'usocket:ns-error)
               (gethash \"state\" (hyperbook/fedwiki::sitemap-snapshot wiki)))
       (finish-output)))"
  "Defined in the child process: what a site reports once its initialization has finished.")

(defun %injected-resolution-failures-form ()
  "A child form: one site per name-resolution condition the SBCL backend of usocket can signal (it maps exactly these three), the probe
signalling it, then the site's outcome. USOCKET:NS-UNKNOWN-ERROR is not among them: the backend never raises it, and it cannot even be printed."
  "(handler-case
  (sb-ext:with-timeout 240
    (dolist (class '(usocket:ns-host-not-found-error usocket:ns-try-again-error usocket:ns-no-recovery-error))
      (let ((wiki (hyperbook/fedwiki::make-fedwiki (format nil \"~(~A~).test-host.invalid\" (symbol-name class))
                    :protocol-probe (lambda (host) (error class :socket nil :host-or-ip host)))))
        (hyperbook/fedwiki::wait-for-sitemap wiki)
        (site-outcome class wiki)))
    (format t \"~&ALL-SITES-FINISHED~%\"))
  (sb-ext:timeout () (format t \"~&TIMEOUT~%\") (sb-ext:exit :code 3 :abort t)))")

(defun %real-resolution-failure-form ()
  "A child form: one site whose probe is the real one, its host name not resolvable, then its outcome."
  "(handler-case
  (sb-ext:with-timeout 240
    (let ((wiki (hyperbook/fedwiki::make-fedwiki \"wiki.test-host.invalid\")))
      (hyperbook/fedwiki::wait-for-sitemap wiki)
      (site-outcome :real-resolver wiki))
    (format t \"~&ALL-SITES-FINISHED~%\"))
  (sb-ext:timeout () (format t \"~&TIMEOUT~%\") (sb-ext:exit :code 3 :abort t)))")

(defun %network-interface-names ()
  "The names of the network interfaces this process sees, from /proc/net/dev: NIL where that file is not there (macOS, for one) or lists none.
/proc is what a Nix build sandbox shows (/sys is not mounted in it), and /proc/net is that process's own network namespace."
  (let ((file #p"/proc/net/dev"))
    (when (probe-file file)
      (with-open-file (in file)
        (read-line in nil) (read-line in nil)   ; the two header lines
        (loop for line = (read-line in nil)
              for colon = (and line (position #\: line))
              while line
              when colon collect (string-trim " " (subseq line 0 colon)))))))

(defun %isolated-p ()
  "Whether this process can reach nothing beyond the machine: it sees no network interface but loopback. Then no resolver setting, route or
stub can lead to a DNS server outside it. A missing route to some address does not say that: a loopback or an internal resolver answers
without a default route. Where the interfaces cannot be read the process is not known to be isolated."
  (let ((names (%network-interface-names)))
    (and names (every (lambda (name) (string= name "lo")) names))))

(defun %offline-prefix ()
  "A command prefix under which the real resolver can reach no network, and why: NIL when this process is isolated already (a Nix build
sandbox), a list for `unshare` where it can make an empty network namespace, and :NONE when neither holds. The real resolver is run only
under one of these two, so a machine with a network is never asked."
  (cond ((%isolated-p) (values nil "this process sees no network interface but loopback"))
        ((ignore-errors (zerop (nth-value 2 (uiop:run-program '("unshare" "-rn" "true") :ignore-error-status t))))
         (values '("unshare" "-rn") "an empty network namespace (unshare -rn)"))
        (t (values :none "this process can reach a network and no empty network namespace can be made"))))

(defun %initialization-outcome (probe)
  "What INITIALIZE-FEDWIKI does with a PROBE (a function of the host name), run here with no network: :ESCAPED when a condition leaves it,
else the site's status and protocol. The sitemap and plugin-data fetchers are replaced by no-ops."
  (let ((wiki (make-instance 'hyperbook/fedwiki::fedwiki :id "fedwiki:matrix.test-host.invalid")))
    (handler-case
        (progn (hyperbook/fedwiki::initialize-fedwiki wiki "matrix.test-host.invalid" :protocol-probe probe
                                                      :sitemap-fetcher #'identity :plugin-data-fetcher #'identity)
               (list :status (let ((status (hyperbook/fedwiki::status-of wiki))) (if (typep status 'condition) (type-of status) status))
                     :protocol (hyperbook/fedwiki::protocol-of wiki)))
      (error () :escaped))))

(defun check-fedwiki-initialization-outcomes ()
  "The handler's whole behaviour in one table: the two success paths and the failures it already kept are as before, the two name-resolution
conditions are new, and an error that is none of them still leaves INITIALIZE-FEDWIKI (the handler is a list of operational failures, not a blanket)."
  (flet ((signalling (condition-type &rest initargs) (lambda (host) (declare (ignore host)) (error (apply #'make-condition condition-type initargs)))))
    (dolist (case `(;; the success paths: the initial HTTPS stays; a refused connection (probe answers "http") sets HTTP
                    (,(constantly "https") (:status t :protocol "https"))
                    (,(constantly "http") (:status t :protocol "http"))
                    ;; failures kept as the status before this change
                    (,(signalling 'usocket:ns-host-not-found-error :socket nil :host-or-ip "h")
                     (:status usocket:ns-host-not-found-error :protocol "https"))
                    (,(signalling 'usocket:timeout-error :socket nil) (:status usocket:timeout-error :protocol "https"))
                    (,(signalling 'stream-error :stream *standard-input*) (:status stream-error :protocol "https"))
                    ;; new: the other conditions the SBCL backend of usocket raises for a host name
                    (,(signalling 'usocket:ns-try-again-error :socket nil :host-or-ip "h")
                     (:status usocket:ns-try-again-error :protocol "https"))
                    (,(signalling 'usocket:ns-no-recovery-error :socket nil :host-or-ip "h")
                     (:status usocket:ns-no-recovery-error :protocol "https"))
                    ;; still not kept: anything else, such as a programming error
                    (,(signalling 'simple-error :format-control "a programming error" :format-arguments nil) :escaped)))
      (destructuring-bind (probe expected) case
        (let ((outcome (%initialization-outcome probe)))
          (assert (equal expected outcome) () "INITIALIZE-FEDWIKI gave ~S, expected ~S." outcome expected)))))
  t)

(defun check-fedwiki-name-resolution-failure ()
  "A site whose host name cannot be resolved keeps the process alive: the condition is the site's status and WAIT-FOR-SITEMAP returns."
  ;; Injected: deterministic everywhere. Each condition of usocket's name-resolution family is signalled by the probe.
  (multiple-value-bind (status output) (%run-fresh-sbcl (list +site-outcome-form+ (%injected-resolution-failures-form)))
    (assert (and (eql 0 status) (search "ALL-SITES-FINISHED" output)) ()
            "A name-resolution failure of a FedWiki site ended the process (exit ~A):~%~A" status
            (subseq output (max 0 (- (length output) 700))))
    (dolist (class '("NS-HOST-NOT-FOUND-ERROR" "NS-TRY-AGAIN-ERROR" "NS-NO-RECOVERY-ERROR"))
      (let ((expected (format nil "OUTCOME ~A ~A ns-error=T snapshot=failed" class class)))
        (assert (search expected output) ()
                "The condition ~A was not kept as the site's status (expected ~S):~%~A" class expected output))))
  ;; Real: the platform's resolver, where it can be made to fail without touching a network.
  (multiple-value-bind (prefix reason) (%offline-prefix)
    (cond ((eq prefix :none)
           (format t "~&FEDWIKI-NAME-RESOLUTION-FAILURE: real resolver not exercised: ~A.~%" reason))
          (t (multiple-value-bind (status output) (%run-fresh-sbcl (list +site-outcome-form+ (%real-resolution-failure-form)) prefix)
               (assert (and (eql 0 status) (search "ALL-SITES-FINISHED" output)) ()
                       "The platform resolver's failure ended the process (exit ~A):~%~A" status
                       (subseq output (max 0 (- (length output) 700))))
               (assert (search "ns-error=T" output) () "The real resolver's failure was not kept as a name-resolution condition:~%~A" output)
               (format t "~&FEDWIKI-NAME-RESOLUTION-FAILURE: real resolver exercised under ~A: ~A~%" reason
                       (string-trim '(#\Newline) (subseq output (search "OUTCOME" output) (position #\Newline output :start (search "OUTCOME" output)))))))))
  t)

(defun run-tests ()
  (check-fedwiki-initialization-outcomes)
  (check-fedwiki-name-resolution-failure)
  (check-configuration)
  (check-start)
  (check-start-with-another-hyperbook)
  (check-mech-host-startup)
  (check-lifecycle)
  (format t "~&Catalog application tests passed: graph, configuration, routes, lifecycle; a further registered HyperBook is tolerated by these checks and named by the admission check.~%")
  t)
