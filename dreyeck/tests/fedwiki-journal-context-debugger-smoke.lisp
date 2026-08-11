;;;; Deterministic tests for the executable FedWiki journal-context debugger.

(defpackage #:dreyeck/fedwiki-journal-context-debugger/tests
  (:use #:cl)
  (:export #:run-fedwiki-journal-context-debugger-tests))

(in-package #:dreyeck/fedwiki-journal-context-debugger/tests)

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun make-journal-entry (site date &key attribution-p)
  (let ((data (make-hash-table :test #'equal)))
    (setf (gethash "type" data) "fork"
          (gethash "date" data) date)
    (if attribution-p
        (let ((attribution (make-hash-table :test #'equal)))
          (setf (gethash "site" attribution) site
                (gethash "attribution" data) attribution))
        (setf (gethash "site" data) site))
    (hyperbook/fedwiki::make-journal-entry data)))

(defun make-ordering-journal ()
  (vector
   (make-journal-entry "alpha.example" 1000)
   (make-journal-entry "beta.example" 2000)
   (make-journal-entry "alpha.example" 3000)
   (make-journal-entry "gamma.example" 4000 :attribution-p t)
   (make-journal-entry "beta.example" 5000)))

(defun run-context-site-references-test ()
  (let ((references
          (hyperbook/fedwiki::context-site-references
           (make-ordering-journal))))
    (check
     (equal '("beta.example" "gamma.example" "alpha.example")
            references)
     "Context reference ordering or deduplication changed: ~S."
     references))
  t)

(defun run-resolution-boundary-test ()
  (let* ((references
           (hyperbook/fedwiki::context-site-references
            (make-ordering-journal)))
         (remaining references)
         (received nil)
         (outcome
           (hyperbook/fedwiki::resolve-context-site-references
            references
            (lambda (site-reference)
              (check (eq site-reference (pop remaining))
                     "Resolver did not receive the exact reference object ~S."
                     site-reference)
              (push site-reference received)
              (list :resolved site-reference)))))
    (check (null remaining)
           "Resolver did not receive every reference: ~S."
           remaining)
    (check (equal references (nreverse received))
           "Resolver inputs differ from references: ~S."
           received)
    (check
     (equal '((:resolved "beta.example")
              (:resolved "gamma.example")
              (:resolved "alpha.example"))
            outcome)
     "Resolution outcome differs: ~S."
     outcome))
  t)

(defun make-initialized-wiki (site-reference)
  (let ((wiki
          (make-instance 'hyperbook/fedwiki::fedwiki
                         :id (concatenate
                              'string "fedwiki:" site-reference))))
    (setf (hyperbook/fedwiki::status-of wiki) t)
    wiki))

(defun make-network-condition ()
  (make-condition 'usocket:ns-host-not-found-error))

(defun make-page-json-with-context (&rest site-references)
  (let ((json (make-hash-table :test #'equal))
        (story-item (make-hash-table :test #'equal))
        (journal
          (map 'vector
               (lambda (site-reference)
                 (let ((entry (make-hash-table :test #'equal)))
                   (setf (gethash "type" entry) "fork"
                         (gethash "date" entry) 1000
                         (gethash "site" entry) site-reference)
                   entry))
               site-references)))
    (setf (gethash "type" story-item) "paragraph"
          (gethash "id" story-item) "local-story-item"
          (gethash "text" story-item) "Local page content"
          (gethash "title" json) "Local page"
          (gethash "story" json) (vector story-item)
          (gethash "journal" json) journal)
    json))

(defun run-domain-name-preservation-test ()
  (let ((with-port
          (make-instance 'hyperbook/fedwiki::fedwiki
                         :id "fedwiki:localhost:3000"))
        (ordinary
          (make-instance 'hyperbook/fedwiki::fedwiki
                         :id "fedwiki:wiki.khinsen.net")))
    (check (string= "localhost:3000"
                    (hyperbook/fedwiki::domain-name-of with-port))
           "DOMAIN-NAME-OF discarded the port: ~S."
           (hyperbook/fedwiki::domain-name-of with-port))
    (check (string= "wiki.khinsen.net"
                    (hyperbook/fedwiki::domain-name-of ordinary))
           "DOMAIN-NAME-OF changed an ordinary domain: ~S."
           (hyperbook/fedwiki::domain-name-of ordinary)))
  t)

(defun make-story-item-fixture (type text &key url width height size)
  (let ((data (make-hash-table :test #'equal)))
    (when url
      (setf (gethash "url" data) url))
    (when width
      (setf (gethash "width" data) width))
    (when height
      (setf (gethash "height" data) height))
    (when size
      (setf (gethash "size" data) size))
    (make-instance 'hyperbook/fedwiki::story-item
                   :item-type type
                   :id "story-item-fixture"
                   :text text
                   :data data)))

(defun inline-style-property (element property)
  (loop for declaration
          in (uiop:split-string (or (plump:attribute element "style") "")
                                :separator '(#\;))
        for separator = (position #\: declaration)
        when (and separator
                  (string-equal property
                                (string-trim '(#\Space #\Tab)
                                             (subseq declaration 0 separator))))
          return (string-trim '(#\Space #\Tab)
                              (subseq declaration (1+ separator)))))

(defun run-story-item-url-resolution-test ()
  (let* ((origin (make-initialized-wiki "hyperdoc.dreyeck.ch"))
         (local-page
           (hyperbook/fedwiki::make-fedwiki-page
            origin "local-page" "Local page"))
         (stored-url "/assets/plugins/image/test.jpg")
         (absolute-url "https://example.org/image.jpg"))
    (check
     (string= "https://hyperdoc.dreyeck.ch/assets/plugins/image/test.jpg"
              (hyperbook/fedwiki::resolve-story-item-url
               stored-url local-page))
     "Site-relative story-item URL did not resolve against its page origin.")
    (check (string= absolute-url
                    (hyperbook/fedwiki::resolve-story-item-url
                     absolute-url local-page))
           "Absolute story-item URL changed during resolution."))
  t)

(defun run-remote-story-item-url-resolution-test ()
  (let* ((containing-wiki (make-initialized-wiki "dreyeck.ch"))
         (origin-wiki (make-initialized-wiki "hyperdoc.dreyeck.ch"))
         (remote-page
           (make-instance 'hyperbook/fedwiki::remote-fedwiki-page
                          :hyperbook containing-wiki
                          :id "hyperdoc.dreyeck.ch/wiki-links"
                          :title "Wiki Links"
                          :origin origin-wiki
                          :origin-id "wiki-links"))
         (resolved
           (hyperbook/fedwiki::resolve-story-item-url
            "/assets/plugins/image/test.jpg"
            remote-page)))
    (check
     (string= "https://hyperdoc.dreyeck.ch/assets/plugins/image/test.jpg"
              resolved)
     "Remote story-item URL used the containing wiki instead of ORIGIN-OF: ~S."
     resolved)
    (check
     (not (string= "https://dreyeck.ch/assets/plugins/image/test.jpg"
                   resolved))
     "Remote story-item URL retained the containing HyperBook host: ~S."
     resolved))
  t)

(defun run-image-story-item-rendering-test ()
  (let* ((origin (make-initialized-wiki "hyperdoc.dreyeck.ch"))
         (page
           (hyperbook/fedwiki::make-fedwiki-page
            origin "wiki-links" "Wiki Links"))
         (item
           (make-story-item-fixture
            :image
            "[https://example.org/change diff]"
            :url "/assets/plugins/image/test.jpg"
            :width 399
            :height 129
            :size "wide")))
    (multiple-value-bind (html references assets)
        (html-inspector-views:html-and-references
          (hyperbook/fedwiki::render-story-item :image item page))
      (declare (ignore references assets))
      (let* ((dom (plump:parse html))
             (figures (plump:get-elements-by-tag-name dom "figure"))
             (images (plump:get-elements-by-tag-name dom "img"))
             (captions (plump:get-elements-by-tag-name dom "figcaption"))
             (links (plump:get-elements-by-tag-name dom "a")))
        (check (= 1 (length figures))
               "Image story-item rendered ~D FIGURE elements."
               (length figures))
        (check (= 1 (length images))
               "Image story-item rendered ~D IMG elements."
               (length images))
        (check (= 1 (length captions))
               "Image story-item rendered ~D FIGCAPTION elements."
               (length captions))
        (check
         (string=
          "https://hyperdoc.dreyeck.ch/assets/plugins/image/test.jpg"
          (plump:attribute (first images) "src"))
         "Image renderer emitted the wrong SRC: ~S."
         (plump:attribute (first images) "src"))
        (check (string= "399" (plump:attribute (first images) "width"))
               "Image renderer did not retain stored width 399: ~S."
               (plump:attribute (first images) "width"))
        (check (string= "129" (plump:attribute (first images) "height"))
               "Image renderer did not retain stored height 129: ~S."
               (plump:attribute (first images) "height"))
        (check (string= "wide"
                        (plump:attribute (first figures)
                                         "data-fedwiki-size"))
               "Image renderer did not retain the FedWiki size hook: ~S."
               (plump:attribute (first figures) "data-fedwiki-size"))
        (check (string= "100%"
                        (inline-style-property (first figures) "max-width"))
               "Image figure lacks its pane-width bound: ~S."
               (plump:attribute (first figures) "style"))
        (check (string= "100%"
                        (inline-style-property (first images) "max-width"))
               "Image lacks its container-width bound: ~S."
               (plump:attribute (first images) "style"))
        (check (string= "auto"
                        (inline-style-property (first images) "height"))
               "Responsive image height is not automatic: ~S."
               (plump:attribute (first images) "style"))
        (check (string= "100%"
                        (inline-style-property (first images) "width"))
               "FedWiki WIDE did not request full container width: ~S."
               (plump:attribute (first images) "style"))
        (check (= 1 (length links))
               "Image caption rendered ~D links instead of one."
               (length links))
        (check (string= "https://example.org/change"
                        (plump:attribute (first links) "href"))
               "Image caption link target changed: ~S."
               (plump:attribute (first links) "href"))
        (check (string= "diff" (plump:text (first links)))
               "Image caption link text changed: ~S."
               (plump:text (first links))))))
  t)

(defun run-image-story-item-defensive-dimensions-test ()
  (let* ((origin (make-initialized-wiki "fixture.example"))
         (page
           (hyperbook/fedwiki::make-fedwiki-page
            origin "fixture-page" "Fixture page")))
    (dolist (spec `((:label :small
                     :item ,(make-story-item-fixture
                             :image "Small"
                             :url "https://example.org/small.jpg"
                             :width 64 :height 32 :size "thumbnail")
                     :expected-width "64"
                     :expected-height "32"
                     :expected-size "thumbnail")
                    (:label :missing
                     :item ,(make-story-item-fixture
                             :image "Missing dimensions"
                             :url "https://example.org/missing.jpg"))
                    (:label :malformed
                     :item ,(make-story-item-fixture
                             :image "Malformed dimensions"
                             :url "https://example.org/malformed.jpg"
                             :width "not-a-number" :height -12 :size 42))))
      (let ((label (getf spec :label))
            (item (getf spec :item)))
        (multiple-value-bind (html references assets)
            (html-inspector-views:html-and-references
              (hyperbook/fedwiki::render-story-item :image item page))
          (declare (ignore references assets))
          (let* ((dom (plump:parse html))
                 (figure (first (plump:get-elements-by-tag-name dom "figure")))
                 (image (first (plump:get-elements-by-tag-name dom "img"))))
            (check figure "~S image fixture did not render a FIGURE." label)
            (check image "~S image fixture did not render an IMG." label)
            (check (string= "100%"
                            (inline-style-property image "max-width"))
                   "~S image fixture lacks its responsive width bound."
                   label)
            (check (string= "auto"
                            (inline-style-property image "height"))
                   "~S image fixture lacks automatic responsive height."
                   label)
            (check (null (inline-style-property image "width"))
                   "~S image fixture was unnecessarily forced to full width."
                   label)
            (if (getf spec :expected-width)
                (check (string= (getf spec :expected-width)
                                (plump:attribute image "width"))
                       "~S image width changed: ~S."
                       label (plump:attribute image "width"))
                (check (null (plump:attribute image "width"))
                       "~S image retained an invalid width: ~S."
                       label (plump:attribute image "width")))
            (if (getf spec :expected-height)
                (check (string= (getf spec :expected-height)
                                (plump:attribute image "height"))
                       "~S image height changed: ~S."
                       label (plump:attribute image "height"))
                (check (null (plump:attribute image "height"))
                       "~S image retained an invalid height: ~S."
                       label (plump:attribute image "height")))
            (if (getf spec :expected-size)
                (check (string= (getf spec :expected-size)
                                (plump:attribute figure "data-fedwiki-size"))
                       "~S image size hook changed: ~S."
                       label
                       (plump:attribute figure "data-fedwiki-size"))
                (check (null (plump:attribute figure "data-fedwiki-size"))
                       "~S image retained a non-string size hook: ~S."
                       label
                       (plump:attribute figure "data-fedwiki-size"))))))))
  t)

(defun run-story-item-link-extraction-preservation-test ()
  (let* ((wiki (make-initialized-wiki "fixture.example"))
         (page
           (hyperbook/fedwiki::make-fedwiki-page
            wiki "fixture-page" "Fixture page"))
         (text "[https://example.org/image.jpg source]")
         (expected-url "https://example.org/image.jpg"))
    (dolist (type '(:paragraph :reference :image))
      (let* ((raw-links
               (hyperbook/fedwiki::extract-links-from-story-item
                type
                (make-story-item-fixture type text)
                page))
             (links (remove nil raw-links)))
        (check (= 1 (length links))
               "~S link extraction returned ~D non-NIL links instead of one."
               type (length links))
        (check (typep (first links) 'hyperbook:web-link)
               "~S link extraction returned ~S instead of a WEB-LINK."
               type (first links))
        (check (string= expected-url (hyperbook:url-of (first links)))
               "~S link extraction changed the URL to ~S."
               type (hyperbook:url-of (first links))))))
  t)

(defun run-initialization-worker-containment-test ()
  (let ((lock (bt:make-lock "FedWiki initialization test lock"))
        (gate (bt:make-condition-variable))
        (probe-entered-p nil)
        (release-probe-p nil)
        (sitemap-fetch-count 0)
        (plugin-fetch-count 0)
        (network-condition (make-network-condition))
        wiki
        worker)
    (flet ((failing-probe (domain-name)
             (declare (ignore domain-name))
             (bt:with-lock-held (lock)
               (setf probe-entered-p t)
               (bt:condition-notify gate)
               (loop until release-probe-p
                     do (bt:condition-wait gate lock)))
             (error network-condition))
           (fetch-sitemap (wiki)
             (declare (ignore wiki))
             (incf sitemap-fetch-count))
           (fetch-plugin-data (wiki)
             (declare (ignore wiki))
             (incf plugin-fetch-count)))
      (setf wiki
            (hyperbook/fedwiki::make-fedwiki
             "localhost:3000"
             :protocol-probe #'failing-probe
             :sitemap-fetcher #'fetch-sitemap
             :plugin-data-fetcher #'fetch-plugin-data))
      (bt:with-lock-held (lock)
        (loop until probe-entered-p
              do (bt:condition-wait gate lock)))
      (setf worker (hyperbook/fedwiki::status-of wiki))
      (check (typep worker 'bt:thread)
             "STATUS-OF did not expose the loading thread: ~S."
             worker)
      (bt:with-lock-held (lock)
        (setf release-probe-p t)
        (bt:condition-notify gate))
      (let ((join-outcome
              (handler-case
                  (progn
                    (bt:join-thread worker)
                    :normal)
                (error (condition)
                  condition))))
        (check (eq :normal join-outcome)
               "The initialization worker re-signaled ~S."
               join-outcome))
      (check (not (bt:thread-alive-p worker))
             "The failed initialization worker is still alive.")
      (check (eq network-condition
                 (hyperbook/fedwiki::status-of wiki))
             "STATUS-OF did not preserve the identical low-level condition.")
      (check (zerop sitemap-fetch-count)
             "Sitemap fetching continued after the failed probe.")
      (check (zerop plugin-fetch-count)
             "Plugin fetching continued after the failed probe.")))
  t)

(defun run-local-page-with-failed-context-test ()
  (let* ((hyperbook/fedwiki::*neighborhood*
           (make-hash-table :test #'equal))
         (source (make-initialized-wiki "source.example"))
         (failed (make-initialized-wiki "localhost:3000"))
         (reachable (make-initialized-wiki "wiki.khinsen.net"))
         (failure (make-network-condition))
         (source-page
           (hyperbook/fedwiki::make-fedwiki-page
            source "local-page" "Local page"))
         (target-page
           (hyperbook/fedwiki::make-fedwiki-page
            reachable "reachable-target" "Reachable target"))
         (json
           (make-page-json-with-context
            "wiki.khinsen.net"
            "localhost:3000")))
    (setf (hyperbook/fedwiki::status-of failed) failure
          (gethash "localhost:3000" hyperbook/fedwiki::*neighborhood*) failed
          (gethash "wiki.khinsen.net" hyperbook/fedwiki::*neighborhood*) reachable
          (gethash "reachable-target"
                   (hyperbook/fedwiki::pages-of reachable)) target-page)
    (hyperbook/fedwiki::set-page-data source-page json)
    (check (= 1 (length (hyperbook/fedwiki::story-of source-page)))
           "SET-PAGE-DATA did not retain the local story.")
    (check (= 2 (length (hyperbook/fedwiki::journal-of source-page)))
           "SET-PAGE-DATA did not retain the local journal.")
    (check (equal (list failed reachable)
                  (hyperbook/fedwiki::context-of source-page))
           "SET-PAGE-DATA did not retain the ordered context: ~S."
           (hyperbook/fedwiki::context-of source-page))
    (check (eq failure (hyperbook/fedwiki::status-of failed))
           "Context extraction changed the failed proxy status.")
    (let ((resolved
            (hyperbook/fedwiki::lookup-slug-in-page-context
             "reachable-target"
             source-page
             :plugin-page-resolver (lambda (wiki slug)
                                     (declare (ignore wiki slug))
                                     nil))))
      (check (typep resolved 'hyperbook/fedwiki::remote-fedwiki-page)
             "Lookup did not continue to the reachable context: ~S."
             resolved)
      (check (eq reachable (hyperbook/fedwiki::origin-of resolved))
             "Lookup resolved through the wrong context wiki: ~S."
             (hyperbook/fedwiki::origin-of resolved))
      (check (string= "reachable-target"
                      (hyperbook/fedwiki::origin-id-of resolved))
             "Lookup returned the wrong remote target: ~S."
             (hyperbook/fedwiki::origin-id-of resolved))))
  t)

(defun run-extract-context-composition-test ()
  (let* ((journal (make-ordering-journal))
         (references
           (hyperbook/fedwiki::context-site-references journal))
         (hyperbook/fedwiki::*neighborhood*
           (make-hash-table :test #'equal))
         (expected
           (loop for reference in references
                 for wiki = (make-initialized-wiki reference)
                 do (setf (gethash reference
                                   hyperbook/fedwiki::*neighborhood*)
                          wiki)
                 collect wiki))
         (composed
           (hyperbook/fedwiki::resolve-context-site-references references))
         (extracted
           (hyperbook/fedwiki::extract-context journal)))
    (check (equal expected composed)
           "Explicit context composition differs: ~S."
           composed)
    (check (equal composed extracted)
           "EXTRACT-CONTEXT no longer has the helper composition contract: ~S."
           extracted))
  t)

(defun debug-step-outcome (step)
  (dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step-outcome step))

(defun run-deterministic-examples-test ()
  (let ((journal-reference
          (dreyeck/fedwiki-journal-context-debugger:fedwiki-journal-reference-example))
        (context-references
          (dreyeck/fedwiki-journal-context-debugger:fedwiki-context-references-example))
        (resolution-boundary
          (dreyeck/fedwiki-journal-context-debugger:fedwiki-context-resolution-boundary-example)))
    (dolist (step (list journal-reference
                        context-references
                        resolution-boundary))
      (check
       (typep step
              'dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step)
       "Example returned ~S rather than a FEDWIKI-DEBUG-STEP."
       step))
    (check
     (typep
      (dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step-input
       journal-reference)
      'hyperbook/fedwiki::journal-entry)
     "Journal-reference input is not a real JOURNAL-ENTRY.")
    (check (string= "localhost:3000"
                    (debug-step-outcome journal-reference))
           "SITE-OF outcome differs: ~S."
           (debug-step-outcome journal-reference))
    (check (equal '("localhost:3000")
                  (debug-step-outcome context-references))
           "Context-reference example differs: ~S."
           (debug-step-outcome context-references))
    (check (equal '("localhost:3000")
                  (debug-step-outcome resolution-boundary))
           "Resolution-boundary example differs: ~S."
           (debug-step-outcome resolution-boundary))
    (check
     (equal '("localhost:3000")
            (dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step-input
             resolution-boundary))
     "Resolution-boundary recorder inputs differ: ~S."
     (dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step-input
      resolution-boundary))
    (check
     (equal (debug-step-outcome journal-reference)
            (debug-step-outcome
             (dreyeck/fedwiki-journal-context-debugger:fedwiki-journal-reference-example)))
     "Journal-reference example is not deterministic.")
    (check
     (equal (debug-step-outcome context-references)
            (debug-step-outcome
             (dreyeck/fedwiki-journal-context-debugger:fedwiki-context-references-example)))
     "Context-reference example is not deterministic.")
    (check
     (equal (debug-step-outcome resolution-boundary)
            (debug-step-outcome
             (dreyeck/fedwiki-journal-context-debugger:fedwiki-context-resolution-boundary-example)))
     "Resolution-boundary example is not deterministic."))
  t)

(defun run-raw-outcome-retention-test ()
  (let* ((slot-names
           (mapcar
            (lambda (slot)
              (intern
               (symbol-name (closer-mop:slot-definition-name slot))
               :keyword))
            (closer-mop:class-slots
             (find-class
              'dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step))))
         (raw-outcome (list :unclassified :raw))
         (step
           (dreyeck/fedwiki-journal-context-debugger:make-fedwiki-debug-step
            :step :test
            :input nil
            :operation 'identity
            :outcome raw-outcome)))
    (check (equal '(:step :input :operation :outcome) slot-names)
           "FEDWIKI-DEBUG-STEP stores facts beyond its four fields: ~S."
           slot-names)
    (check (eq raw-outcome (debug-step-outcome step))
           "FEDWIKI-DEBUG-STEP did not retain the raw outcome object."))
  t)

(defun run-protocol-probe-example-test ()
  (let ((escaped-condition nil)
        (step nil))
    (handler-case
        (setf step
              (dreyeck/fedwiki-journal-context-debugger:fedwiki-protocol-probe-example))
      (error (condition)
        (setf escaped-condition condition)))
    (check (null escaped-condition)
           "Protocol-probe example signaled ~S instead of retaining it."
           escaped-condition)
    (check
     (typep step
            'dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step)
     "Protocol-probe example did not return a FEDWIKI-DEBUG-STEP: ~S."
     step)
    (let ((outcome (debug-step-outcome step)))
      (check (or (typep outcome 'condition)
                 (member outcome '("https" "http") :test #'string=))
             "Protocol-probe outcome is neither a condition nor protocol: ~S."
             outcome)))
  t)

(defun run-initialization-containment-example-test ()
  (let* ((steps
           (dreyeck/fedwiki-journal-context-debugger:fedwiki-initialization-containment-example))
         (probe-step (first steps))
         (containment-step (second steps))
         (probe-outcome (debug-step-outcome probe-step))
         (containment-outcome (debug-step-outcome containment-step)))
    (check (= 2 (length steps))
           "Initialization containment example returned ~D steps."
           (length steps))
    (check (typep probe-outcome 'usocket:ns-host-not-found-error)
           "The simulated probe outcome has the wrong type: ~S."
           probe-outcome)
    (check (eq probe-outcome containment-outcome)
           "Production containment did not preserve the probe condition object."))
  t)

(defun run-inspector-view-test ()
  (let* ((outcome
           (make-condition 'simple-error
                           :format-control "Inspectable raw outcome"))
         (step
           (dreyeck/fedwiki-journal-context-debugger:make-fedwiki-debug-step
            :step :inspector-test
            :input "input"
            :operation 'identity
            :outcome outcome))
         (titles
           (mapcar #'html-inspector-views:view-title
                   (html-inspector-views:all-views step)))
         (view
           (find "FedWiki failure trace step"
                 (html-inspector-views:all-views step)
                 :key #'html-inspector-views:view-title
                 :test #'string=)))
    (check (member "FedWiki failure trace step" titles :test #'string=)
           "FEDWIKI-DEBUG-STEP lacks its specialized inspector view: ~S."
           titles)
    (html-inspector-views:view-html view)
    (check (find outcome
                 (html-inspector-views:view-references view)
                 :key #'cdr
                 :test #'eq)
           "Inspector view does not retain OUTCOME as a clickable object."))
  t)

(defun run-fedwiki-journal-context-debugger-tests ()
  (run-domain-name-preservation-test)
  (run-story-item-url-resolution-test)
  (run-remote-story-item-url-resolution-test)
  (run-image-story-item-rendering-test)
  (run-image-story-item-defensive-dimensions-test)
  (run-story-item-link-extraction-preservation-test)
  (run-initialization-worker-containment-test)
  (run-local-page-with-failed-context-test)
  (run-context-site-references-test)
  (run-resolution-boundary-test)
  (run-extract-context-composition-test)
  (run-deterministic-examples-test)
  (run-raw-outcome-retention-test)
  (run-protocol-probe-example-test)
  (run-initialization-containment-example-test)
  (run-inspector-view-test)
  (format t "FedWiki journal-context debugger tests passed.~%")
  t)
