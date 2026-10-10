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
  (assert (= 22 (length (hyperbook:hyperbooks-of hyperbook:*catalog*))))
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

(defun run-tests ()
  (check-configuration)
  (check-start)
  (check-mech-host-startup)
  (check-lifecycle)
  (format t "~&Catalog application tests passed: graph, configuration, routes, lifecycle.~%")
  t)
