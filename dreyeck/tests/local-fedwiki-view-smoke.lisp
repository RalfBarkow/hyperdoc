(in-package #:dreyeck/local-fedwiki-view/tests)

(defparameter *fixture-slug*
  "reading-java-source-as-data")

(defparameter *fixture-wiki-id*
  "fedwiki:dreyeck.ch")

(defparameter *fixture-view-path*
  (format nil "/view/~A" *fixture-slug*))

(defun fixture-site-root ()
  (asdf:system-relative-pathname
   "dreyeck/local-fedwiki-view/tests"
   "dreyeck/tests/fixtures/local-fedwiki-view-site/"))

(defun story-view-html (page)
  (let ((view
          (find
           "Story"
           (html-inspector-views:all-views page)
           :key #'html-inspector-views:view-title
           :test #'string=)))
    (unless view
      (error
       "No Story view found for ~S."
       page))
    (html-inspector-views:view-html
     view)))

(defun url-view-html (page)
  (let ((view
          (find
           "URL"
           (html-inspector-views:all-views page)
           :key #'html-inspector-views:view-title
           :test #'string=)))
    (unless view
      (error
       "No URL view found for ~S."
       page))
    (html-inspector-views:view-html
     view)))

(defun call-recording-clog (thunk)
  "Run THUNK with CLOG's server entry points replaced by recorders.

No socket is opened. What is under test is which arguments reach
CLOG:INITIALIZE, not whether a server comes up, and starting a real
listener in a unit test would bind a port and change global state."
  (let ((initialize (fdefinition 'clog:initialize))
        (set-on-new-window (fdefinition 'clog:set-on-new-window))
        (parameters (when (boundp 'hyperbook/server::*server-parameters*)
                      hyperbook/server::*server-parameters*))
        (recorded nil))
    (unwind-protect
         (progn
           (setf (fdefinition 'clog:initialize)
                 (lambda (handler &rest arguments)
                   (declare (ignore handler))
                   (setf recorded arguments)
                   nil))
           (setf (fdefinition 'clog:set-on-new-window)
                 (lambda (handler &key path)
                   (declare (ignore handler path))
                   nil))
           (funcall thunk)
           ;; Both what reached CLOG and what the server recorded, read
           ;; before the unwind restores the latter.
           (list :clog recorded
                 :server-parameters hyperbook/server::*server-parameters*))
      (setf (fdefinition 'clog:initialize) initialize)
      (setf (fdefinition 'clog:set-on-new-window) set-on-new-window)
      (setf hyperbook/server::*server-parameters* parameters))))

(defun run-bind-address-tests ()
  "An explicitly given bind address must reach CLOG, and only then.

DEVELOPMENT enables evaluating arbitrary code, so a development server
that binds every interface is private only by luck. The address is now
a parameter; it was not one, and CLOG's own default — every interface
— was what every caller got."
  ;; Explicit loopback reaches CLOG.
  (let ((clog (getf (call-recording-clog
                     (lambda ()
                       (hyperbook/server:serve-catalog
                        :port 8099 :host "127.0.0.1" :development t)))
                    :clog)))
    (assert (equal "127.0.0.1" (getf clog :host)))
    (assert (= 8099 (getf clog :port))))
  ;; Omitting it preserves what callers got before: every interface.
  (let ((clog (getf (call-recording-clog
                     (lambda () (hyperbook/server:serve-catalog :port 8080)))
                    :clog)))
    (assert (equal "0.0.0.0" (getf clog :host))))
  ;; The two choices are independent: a bound address does not imply
  ;; development, and development does not imply a public address.
  (let ((observed (call-recording-clog
                   (lambda ()
                     (hyperbook/server:serve-catalog :host "127.0.0.1")))))
    (assert (equal "127.0.0.1" (getf (getf observed :clog) :host)))
    (assert (null (second (getf observed :server-parameters)))))
  (let ((observed (call-recording-clog
                   (lambda () (hyperbook/server:serve-catalog :development t)))))
    (assert (equal "0.0.0.0" (getf (getf observed :clog) :host)))
    (assert (second (getf observed :server-parameters))))
  (format t "~&BIND-ADDRESS-PASS: an explicit host reaches CLOG, omitting it ~
keeps every interface, and host and development stay independent.~%")
  t)

(defun run-local-fedwiki-view-tests ()
  (assert
   (string=
    *fixture-slug*
    (dreyeck/local-fedwiki-view:view-slug-from-pathname
     *fixture-view-path*)))

  (assert
   (null
    (dreyeck/local-fedwiki-view:view-slug-from-pathname
     (format nil "/not-view/~A" *fixture-slug*))))

  ;; The authored HyperDoc page names the same executable contracts that
  ;; this smoke test exercises below.
  (let* ((demo-page
           (asdf:system-relative-pathname
            "dreyeck/local-fedwiki-view/tests"
            "dreyeck/pages/HyperDoc and a Page-attached FedWiki ASDF System.html"))
         (source
           (uiop:read-file-string
            (truename demo-page))))

    (dolist
        (needle
         '("hyperbook=\"fedwiki:dreyeck.ch\""
           "page=\"reading-java-source-as-data\""
           "hyperbook:find-page"
           "view=\"Story\""
           "local-fedwiki-page-asdf-discovery"
           "/view/reading-java-source-as-data"))
      (assert
       (search needle source :test #'char=)
       ()
       "HyperDoc demonstration page must declare ~S."
       needle)))

  (let ((hyperbook:*catalog*
          (make-instance
           'hyperbook:catalog)))

    (let* ((fetch-symbol
             (find-symbol
              "FETCH-PAGE-JSON"
              "HYPERBOOK/FEDWIKI"))
           (original-fetch
             (symbol-function
              fetch-symbol))
           (fetch-called-p nil))

      (unwind-protect
           (progn
             (setf
              (symbol-function fetch-symbol)
              (lambda (&rest arguments)
                (declare
                 (ignore arguments))
                (setf fetch-called-p t)
                (error
                 "Network FedWiki fetch attempted while resolving a local page.")))

             (let* ((wiki
        (dreyeck/local-fedwiki-page:register-local-fedwiki (fixture-site-root)
                                                           *fixture-wiki-id*))
       (page-from-semantic-link-contract
        (hyperbook:find-page *fixture-wiki-id* *fixture-slug* :signal-error?
                             t))
       (page-from-view-route
        (dreyeck/local-fedwiki-view:make-local-fedwiki-view-page
         (fixture-site-root) *fixture-slug* :wiki-id *fixture-wiki-id*))
       (discovery
        (dreyeck/local-fedwiki-page:local-fedwiki-page-asdf-discovery
         page-from-semantic-link-contract))
       (html (story-view-html page-from-semantic-link-contract))
       (url-html (url-view-html page-from-semantic-link-contract)))
  (assert (typep wiki 'dreyeck/local-fedwiki-page:local-fedwiki))
  (assert
   (equal (truename (fixture-site-root))
          (dreyeck/local-fedwiki-page:local-fedwiki-site-root-of wiki)))
  (assert
   (typep page-from-semantic-link-contract
          'dreyeck/local-fedwiki-page:local-fedwiki-page))
  (assert (eq page-from-semantic-link-contract page-from-view-route))
  (assert (eq wiki (hyperbook:hyperbook-of page-from-semantic-link-contract)))
  (assert
   (string= "Reading Java Source as Data"
            (hyperbook:title-of page-from-semantic-link-contract)))
  (assert (null (hyperbook:find-page *fixture-wiki-id* "does-not-exist")))
  (assert (not fetch-called-p))
  (assert
   (equal '("pages/reading-java-source-as-data")
          (getf discovery :assets-references)))
  (let* ((asdf-files (getf discovery :asdf-files))
         (expected-asd
          (asdf/system:system-relative-pathname
           "dreyeck/local-fedwiki-view/tests"
           "dreyeck/tests/fixtures/local-fedwiki-view-site/assets/pages/reading-java-source-as-data/reading-java-source-as-data.asd")))
    (assert (= 1 (length asdf-files)))
    (assert (equal (truename expected-asd) (truename (first asdf-files)))))
  (let* ((workspace-id (format nil "workspace:~A" *fixture-slug*))
         (offer-count-before
          (count workspace-id (hyperbook:hyperbooks-of hyperbook:*catalog*)
                 :key #'hyperbook:id-of :test #'string=))
         (first-offer
          (dreyeck/local-fedwiki-view::ensure-page-attached-workspace-offer
           page-from-semantic-link-contract))
         (offer-count-after-first
          (count workspace-id (hyperbook:hyperbooks-of hyperbook:*catalog*)
                 :key #'hyperbook:id-of :test #'string=))
         (second-offer
          (dreyeck/local-fedwiki-view::ensure-page-attached-workspace-offer
           page-from-semantic-link-contract))
         (offer-count-after-second
          (count workspace-id (hyperbook:hyperbooks-of hyperbook:*catalog*)
                 :key #'hyperbook:id-of :test #'string=)))
    (assert (= 0 offer-count-before))
    (assert first-offer)
    (assert (string= workspace-id (hyperbook:id-of first-offer)))
    (assert (= 1 offer-count-after-first))
    (assert (eq first-offer second-offer))
    (assert (= 1 offer-count-after-second)))
  ;; Offering must not evaluate what it offers. This used to call
  ;; REGISTER-ASD-SYSTEMS, whose docstring begins "Evaluate trusted
  ;; ASD-PATHNAME": ASDF:LOAD-ASD runs the file. Since the offer is made
  ;; on every /view/<slug> request, visiting a page ran the code attached
  ;; to it, before anything was clicked.
  (let ((registered-before (length (asdf:registered-systems)))
        (fixture-registered-before
          (and (asdf:registered-system *fixture-slug*) t)))
    (dreyeck/local-fedwiki-view::ensure-page-attached-workspace-offer
     page-from-semantic-link-contract)
    (assert (= registered-before (length (asdf:registered-systems))))
    (assert (eq fixture-registered-before
                (and (asdf:registered-system *fixture-slug*) t))))

  (assert (search "Reading Java Source as Data" html :test #'char-equal))
  (assert
   (search "This page treats Java source as inspectable" html :test
           #'char-equal))
  (assert
   (search (format nil "pages/~A" *fixture-slug*) html :test #'char-equal))
  (assert
   (search (string-left-trim "/" *fixture-view-path*) url-html :test
           #'char-equal))))

        (setf
         (symbol-function fetch-symbol)
         original-fetch))))

  t)
