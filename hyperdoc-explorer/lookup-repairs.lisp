;;;; Repair and probe objects for lookup issues
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(defclass fedwiki-publication-probe ()
  ((domain :reader fedwiki-publication-probe-domain-of
           :initarg :domain
           :type string)
   (slug :reader fedwiki-publication-probe-slug-of
         :initarg :slug
         :type string)
   (protocol :reader fedwiki-publication-probe-protocol-of
             :initarg :protocol
             :initform "https"
             :type string)
   (local-path :reader fedwiki-publication-probe-local-path-of
               :initarg :local-path
               :initform nil)
   (local-page-exists-p :reader fedwiki-publication-probe-local-page-exists-p
                        :initarg :local-page-exists-p
                        :initform nil)
   (sitemap-has-slug-p :reader fedwiki-publication-probe-sitemap-has-slug-p
                       :initarg :sitemap-has-slug-p
                       :initform nil)
   (fetch-status :reader fedwiki-publication-probe-fetch-status-of
                 :initarg :fetch-status
                 :initform :unknown)
   (fetch-error :reader fedwiki-publication-probe-fetch-error-of
                :initarg :fetch-error
                :initform nil)
   (classification :reader fedwiki-publication-probe-classification-of
                   :initarg :classification
                   :initform :publication-boundary)))

(defclass hyperdoc-authoring-scaffold-plan ()
  ((mode :reader hyperdoc-authoring-scaffold-mode-of
         :initarg :mode)
   (target-hyperbook-id :reader hyperdoc-authoring-scaffold-target-hyperbook-id-of
                        :initarg :target-hyperbook-id)
   (page-id :reader hyperdoc-authoring-scaffold-page-id-of
            :initarg :page-id)
   (file-path :reader hyperdoc-authoring-scaffold-file-path-of
              :initarg :file-path
              :initform nil)
   (topic-id :reader hyperdoc-authoring-scaffold-topic-id-of
             :initarg :topic-id
             :initform nil)
   (topic-function-name :reader hyperdoc-authoring-scaffold-topic-function-name-of
                        :initarg :topic-function-name
                        :initform nil)
   (summary :reader hyperdoc-authoring-scaffold-summary-of
            :initarg :summary)
   (template :reader hyperdoc-authoring-scaffold-template-of
             :initarg :template)))

(defun local-fedwiki-pages-directory ()
  (article-allegation-default-fedwiki-pages-directory))

(defun local-fedwiki-repo-root ()
  (uiop:pathname-parent-directory-pathname
   (uiop:ensure-directory-pathname
    (local-fedwiki-pages-directory))))

(defun local-fedwiki-domain-name ()
  (let ((directory-components
          (pathname-directory
           (uiop:pathname-parent-directory-pathname
            (local-fedwiki-pages-directory)))))
    (string-downcase
     (princ-to-string (car (last directory-components))))))

(defun local-fedwiki-path-for-slug (slug)
  (merge-pathnames slug
                   (uiop:ensure-directory-pathname
                    (local-fedwiki-pages-directory))))

(defun localhost-like-fedwiki-domain-p (domain)
  (member (string-downcase domain)
          '("localhost" "127.0.0.1")
          :test #'string=))

(defun make-fedwiki-publication-probe (domain slug)
  (let* ((local-path (and (string= (string-downcase domain)
                                   (local-fedwiki-domain-name))
                          (local-fedwiki-path-for-slug slug)))
         (local-exists-p (and local-path
                              (not (null (uiop:file-exists-p local-path)))))
         (wiki (hyperbook/fedwiki::get-fedwiki domain nil t))
         (sitemap-has-slug-p (not (null (hb:find-page wiki slug))))
         (protocol (hyperbook/fedwiki::protocol-of wiki))
         (fetch-status :unknown)
         (fetch-error nil))
    (handler-case
        (progn
          (hyperbook/fedwiki::fetch-page-json domain protocol slug)
          (setf fetch-status :ok))
      (error (c)
        (setf fetch-status :error
              fetch-error c)))
    (make-instance 'fedwiki-publication-probe
                   :domain domain
                   :slug slug
                   :protocol protocol
                   :local-path local-path
                   :local-page-exists-p local-exists-p
                   :sitemap-has-slug-p sitemap-has-slug-p
                   :fetch-status fetch-status
                   :fetch-error fetch-error
                   :classification
                   (cond
                     ((and local-exists-p
                           (eq fetch-status :error)
                           (not sitemap-has-slug-p))
                      :publication-boundary)
                     ((and (not local-exists-p)
                           (eq fetch-status :error)
                           (not sitemap-has-slug-p))
                      :remote-page-missing)
                     ((and (eq fetch-status :error)
                           sitemap-has-slug-p)
                      :lookup-path-fetch-format-failure)
                     (t
                      :resolved)))))

(defmethod views:text-representation ((probe fedwiki-publication-probe))
  (format nil "FedWiki publication probe ~A/~A (~A)"
          (fedwiki-publication-probe-domain-of probe)
          (fedwiki-publication-probe-slug-of probe)
          (string-downcase
           (symbol-name (fedwiki-publication-probe-classification-of probe)))))

(views:defview 👀overview (probe fedwiki-publication-probe)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Domain"))
                   (:td (views:esc (fedwiki-publication-probe-domain-of probe))))
              (:tr (:td (views:esc "Slug"))
                   (:td (:tt (views:esc (fedwiki-publication-probe-slug-of probe)))))
              (:tr (:td (views:esc "Protocol"))
                   (:td (:tt (views:esc (fedwiki-publication-probe-protocol-of probe)))))
              (:tr (:td (views:esc "Local page path"))
                   (:td (:code (views:esc
                                (or (and (fedwiki-publication-probe-local-path-of probe)
                                         (namestring
                                          (fedwiki-publication-probe-local-path-of probe)))
                                    "")))))
              (:tr (:td (views:esc "Local page exists"))
                   (:td (:tt (views:esc
                              (if (fedwiki-publication-probe-local-page-exists-p probe)
                                  "yes"
                                  "no")))))
              (:tr (:td (views:esc "Sitemap has slug"))
                   (:td (:tt (views:esc
                              (if (fedwiki-publication-probe-sitemap-has-slug-p probe)
                                  "yes"
                                  "no")))))
              (:tr (:td (views:esc "Direct JSON fetch"))
                   (:td (:tt (views:esc
                              (string-downcase
                               (symbol-name
                                (fedwiki-publication-probe-fetch-status-of probe)))))))
              (:tr (:td (views:esc "Classification"))
                   (:td (:tt (views:esc
                              (string-downcase
                               (substitute #\Space #\- (symbol-name
                                                        (fedwiki-publication-probe-classification-of probe))))))))))))

(views:defview 👀details (probe fedwiki-publication-probe)
  (views:html-view :title "Details" :priority 2
    (views:html
      (:p
       (views:esc
        "Use this probe to distinguish a missing twin from a publication/resolution boundary on the served FedWiki site."))
      (when-let (error (fedwiki-publication-probe-fetch-error-of probe))
        (views:html
          (:table :class "inspector-table"
                  (:tr (:td (views:esc "Fetch error"))
                       (:td (views:object-ref error)))))))))

(defun hyperdoc-page-template (title)
  (format nil "<h1>~A</h1>~%~%<in-package>hyperdoc</in-package>~%~%<p>~%  Placeholder page scaffolded from a lookup-repair plan. Replace this text with durable documentation content.~%</p>~%~%<h2>Inspectable objects</h2>~%~%<ul>~%  <li><a hyperbook=\"topics\" page=\"~A\"><tt>~A</tt></a></li>~%</ul>~%"
          title title title))

(defun topic-id-from-title (title)
  (hyperbook/fedwiki::slug title))

(defun topic-function-name-from-title (title)
  (format nil "~A-topic" (topic-id-from-title title)))

(defun plan-hyperdoc-authoring-scaffold (target-hyperbook-id page-id)
  (let* ((mode (if (string= target-hyperbook-id "topics")
                   :topic
                   :page))
         (file-path (and (eq mode :page)
                         (merge-pathnames
                          (format nil "hyperdoc/~A.html" page-id)
                          (asdf:system-source-directory :hyperdoc))))
         (topic-id (topic-id-from-title page-id))
         (topic-function-name (topic-function-name-from-title page-id))
         (summary
           (if (eq mode :topic)
               "Scaffold the missing topic constructor and matching durable page without inventing content strength."
               "Scaffold the missing HyperDoc page file and keep the authored content boundary explicit."))
         (template
           (if (eq mode :topic)
               (format nil "(defun ~A ()~%  (make-topic~%   :id ~S~%   :title ~S~%   :summary \"TODO\"~%   :references '(~S)))~%"
                       topic-function-name
                       topic-id
                       page-id
                       page-id)
               (hyperdoc-page-template page-id))))
    (make-instance 'hyperdoc-authoring-scaffold-plan
                   :mode mode
                   :target-hyperbook-id target-hyperbook-id
                   :page-id page-id
                   :file-path file-path
                   :topic-id topic-id
                   :topic-function-name topic-function-name
                   :summary summary
                   :template template)))

(defun hyperdoc-hyperbook-id ()
  (or (ignore-errors (hb:id-of *hyperdoc*))
      "hyperdoc"))

(defun lookup-issue-expected-title (issue)
  (or (hb:lookup-issue-expected-page-id-of issue)
      (hb:lookup-issue-link-text-of issue)))

(defun route-hyperdoc-authoring-lookup-issue!
    (issue &key target-kind classification suggested-repair repair-description)
  (let ((target-hyperbook-id (hb:lookup-issue-target-hyperbook-id-of issue))
        (page-id (hb:lookup-issue-expected-page-id-of issue)))
    (hb::configure-lookup-issue!
     issue
     :target-kind target-kind
     :classification classification
     :suggested-repair suggested-repair
     :repair-description repair-description
     :repair-thunk (lambda ()
                     (plan-hyperdoc-authoring-scaffold
                      target-hyperbook-id
                      page-id)))))

(defun route-hyperdoc-topic-lookup-issue! (issue)
  (hb::configure-lookup-issue!
   issue
   :target-kind :hyperdoc-topic-page
   :classification :missing-hyperdoc-topic-page))

(defun route-hyperdoc-page-authoring-lookup-issue! (issue)
  (route-hyperdoc-authoring-lookup-issue!
   issue
   :target-kind :hyperdoc-page
   :classification :missing-hyperdoc-page
   :suggested-repair :scaffold-hyperdoc-page
   :repair-description
   "Scaffold the missing HyperDoc page from the repair flow, then add durable content deliberately."))

(defun route-fedwiki-page-lookup-issue! (issue)
  (let* ((target-hyperbook-id (hb:lookup-issue-target-hyperbook-id-of issue))
         (slug (hb:lookup-issue-expected-page-id-of issue))
         (domain (subseq target-hyperbook-id (length "fedwiki:")))
         (pages-directory (local-fedwiki-pages-directory))
         (repo-root (local-fedwiki-repo-root))
         (local-domain-p (string= (string-downcase domain)
                                  (local-fedwiki-domain-name)))
         (local-path (and local-domain-p
                          (local-fedwiki-path-for-slug slug)))
         (local-page-exists-p (and local-path
                                   (not (null (uiop:file-exists-p local-path)))))
         (materialization-plan
           (and local-domain-p
                (ignore-errors
                  (plan-fedwiki-page-materialization
                   slug
                   :fedwiki-pages-directory pages-directory
                   :fedwiki-repo-root repo-root
                   :expected-fedwiki-branch nil))))
         (probe (make-fedwiki-publication-probe domain slug)))
    (hb::append-lookup-issue-details!
     issue
     (list :target-domain domain
           :local-domain-p local-domain-p
           :local-path local-path
           :local-page-exists-p local-page-exists-p
           :sitemap-has-slug-p
           (fedwiki-publication-probe-sitemap-has-slug-p probe)
           :fetch-status
           (fedwiki-publication-probe-fetch-status-of probe)
           :publication-classification
           (fedwiki-publication-probe-classification-of probe)))
    (cond
      ((and local-domain-p
            local-page-exists-p
            (eq (fedwiki-publication-probe-classification-of probe)
                :publication-boundary))
       (hb::configure-lookup-issue!
        issue
        :target-kind :remote-fedwiki-page
        :classification :publication-boundary
        :suggested-repair :inspect-publication-probe
        :repair-description
        "The local FedWiki page exists, but the served site does not currently resolve it. Inspect the publication probe instead of recreating the page."
        :repair-thunk (lambda ()
                        (make-fedwiki-publication-probe domain slug))))
      ((and local-domain-p
            (not local-page-exists-p)
            materialization-plan)
       (hb::append-lookup-issue-details!
        issue
        (list :fedwiki-pages-directory pages-directory
              :fedwiki-repo-root repo-root))
       (hb::configure-lookup-issue!
        issue
        :target-kind :local-fedwiki-twin
        :classification :missing-local-fedwiki-twin))
      ((eq (fedwiki-publication-probe-classification-of probe)
           :remote-page-missing)
       (hb::configure-lookup-issue!
        issue
        :target-kind :remote-fedwiki-page
        :classification :remote-page-missing
        :suggested-repair :inspect-publication-probe
        :repair-description
        "The remote FedWiki page does not currently resolve. Inspect the probe before deciding whether authoring or publication work is required."
        :repair-thunk (lambda ()
                        (make-fedwiki-publication-probe domain slug))))
      (t
       (hb::configure-lookup-issue!
        issue
        :target-kind :remote-fedwiki-page
        :classification :lookup-path-fetch-format-failure
        :suggested-repair :inspect-publication-probe
        :repair-description
        "Inspect the publication probe to determine whether the remote lookup failure is caused by sitemap lag, fetch-format drift, or another resolution-path problem."
        :repair-thunk (lambda ()
                        (make-fedwiki-publication-probe domain slug)))))
    issue))

(defun route-hyperdoc-page-lookup-issue! (issue)
  (let ((target-hyperbook-id (hb:lookup-issue-target-hyperbook-id-of issue)))
    (cond
      ((null target-hyperbook-id)
       issue)
      ((string= target-hyperbook-id "topics")
       (route-hyperdoc-topic-lookup-issue! issue))
      ((uiop:string-prefix-p "fedwiki:" target-hyperbook-id)
       (route-fedwiki-page-lookup-issue! issue))
      ((string= target-hyperbook-id (hyperdoc-hyperbook-id))
       (route-hyperdoc-page-authoring-lookup-issue! issue))
      (t
       (hb::classify-generic-page-lookup-issue! issue)))))

(defun write-hyperdoc-authoring-scaffold-plan! (plan)
  (unless (eq (hyperdoc-authoring-scaffold-mode-of plan) :page)
    (error "Only page-mode scaffold plans can write files directly."))
  (let ((path (hyperdoc-authoring-scaffold-file-path-of plan)))
    (when (and path (uiop:file-exists-p path))
      (error "Refusing to overwrite existing HyperDoc page ~A" path))
    (ensure-directories-exist path)
    (with-open-file (stream path
                            :direction :output
                            :external-format :utf-8
                            :if-exists :error
                            :if-does-not-exist :create)
      (write-string (hyperdoc-authoring-scaffold-template-of plan) stream))
    plan))

(defmethod views:text-representation ((plan hyperdoc-authoring-scaffold-plan))
  (format nil "HyperDoc scaffold ~A ~A"
          (string-downcase
           (symbol-name (hyperdoc-authoring-scaffold-mode-of plan)))
          (hyperdoc-authoring-scaffold-page-id-of plan)))

(defmethod views:title-bar-action-buttons ((plan hyperdoc-authoring-scaffold-plan))
  (when (eq (hyperdoc-authoring-scaffold-mode-of plan) :page)
    (views:html
      (views:action-button
       "Write page stub"
       (views:thunk
         (write-hyperdoc-authoring-scaffold-plan! plan)
         plan)
       "Create the missing HyperDoc page file from this scaffold plan without touching topics.lisp."))))

(views:defview 👀overview (plan hyperdoc-authoring-scaffold-plan)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Mode"))
                   (:td (:tt (views:esc
                              (string-downcase
                               (symbol-name
                                (hyperdoc-authoring-scaffold-mode-of plan)))))))
              (:tr (:td (views:esc "Target HyperBook"))
                   (:td (:tt (views:esc
                              (hyperdoc-authoring-scaffold-target-hyperbook-id-of plan)))))
              (:tr (:td (views:esc "Page id"))
                   (:td (:tt (views:esc
                              (hyperdoc-authoring-scaffold-page-id-of plan)))))
              (:tr (:td (views:esc "File path"))
                   (:td (:code (views:esc
                                (or (and (hyperdoc-authoring-scaffold-file-path-of plan)
                                         (namestring
                                          (hyperdoc-authoring-scaffold-file-path-of plan)))
                                    "")))))
              (:tr (:td (views:esc "Topic id"))
                   (:td (:tt (views:esc
                              (or (hyperdoc-authoring-scaffold-topic-id-of plan)
                                  "")))))
              (:tr (:td (views:esc "Topic function"))
                   (:td (:tt (views:esc
                              (or (hyperdoc-authoring-scaffold-topic-function-name-of plan)
                                  "")))))
              (:tr (:td (views:esc "Summary"))
                   (:td (views:esc
                         (hyperdoc-authoring-scaffold-summary-of plan))))))))

(views:defview 👀template (plan hyperdoc-authoring-scaffold-plan)
  (views:html-view :title "Template" :priority 2
    (views:html
      (:pre (views:esc (hyperdoc-authoring-scaffold-template-of plan))))))

(defmethod issue-target-chunk ((issue hb:lookup-issue))
  (when (string= (or (hb:lookup-issue-target-hyperbook-id-of issue) "")
                 "topics")
    (make-topic-page-availability-chunk
     (lookup-issue-expected-title issue))))

(defun topic-page-lookup-issue-target-chunk (issue)
  (when (string= (or (hb:lookup-issue-target-hyperbook-id-of issue) "")
                 "topics")
    (issue-target-chunk issue)))

(defun missing-local-fedwiki-twin-lookup-issue-p (issue)
  (and (eq (hb:lookup-issue-target-kind-of issue)
           :local-fedwiki-twin)
       (eq (hb:lookup-issue-classification-of issue)
           :missing-local-fedwiki-twin)))

(defun missing-local-fedwiki-twin-lookup-issue-pages-directory (issue)
  (uiop:ensure-directory-pathname
   (or (getf (hb::lookup-issue-static-details-of issue)
             :fedwiki-pages-directory)
       (local-fedwiki-pages-directory))))

(defun missing-local-fedwiki-twin-lookup-issue-repo-root (issue)
  (uiop:ensure-directory-pathname
   (or (getf (hb::lookup-issue-static-details-of issue)
             :fedwiki-repo-root)
       (local-fedwiki-repo-root))))

(defun missing-local-fedwiki-twin-lookup-issue-runtime-state (issue)
  (when (missing-local-fedwiki-twin-lookup-issue-p issue)
    (let* ((slug (hb:lookup-issue-expected-page-id-of issue))
           (pages-directory
             (missing-local-fedwiki-twin-lookup-issue-pages-directory issue))
           (repo-root
             (missing-local-fedwiki-twin-lookup-issue-repo-root issue))
           (local-path (and slug
                            (merge-pathnames slug pages-directory)))
           (local-page-exists-p (and local-path
                                     (not (null (uiop:file-exists-p local-path)))))
           (materialization-plan
             (and slug
                  (not local-page-exists-p)
                  (ignore-errors
                    (plan-fedwiki-page-materialization
                     slug
                     :fedwiki-pages-directory pages-directory
                     :fedwiki-repo-root repo-root
                     :expected-fedwiki-branch nil))))
           (entry (and materialization-plan
                       (first
                        (fedwiki-materialization-entries-of
                         materialization-plan)))))
      (list :slug slug
            :pages-directory pages-directory
            :repo-root repo-root
            :local-path local-path
            :local-page-exists-p local-page-exists-p
            :materialization-plan materialization-plan
            :materialization-action
            (and entry
                 (fedwiki-materialization-entry-action-of entry))))))

(defun missing-local-fedwiki-twin-repair-description (issue)
  (let ((state (missing-local-fedwiki-twin-lookup-issue-runtime-state issue)))
    (cond
      ((null state)
       nil)
      ((getf state :local-page-exists-p)
       "No repair is needed. The local FedWiki twin now exists in the current pages directory.")
      ((getf state :materialization-plan)
       "Materialize the missing FedWiki twin into the localhost pages repo through the existing materialization helper.")
      (t
       "The local FedWiki twin is still missing, but HyperDoc could not derive a current materialization plan from the current runtime context."))))

(defun topic-page-lookup-issue-runtime-details (issue)
  (when-let (chunk (topic-page-lookup-issue-target-chunk issue))
    (let ((status (topic-page-lookup-chunk-state chunk)))
      (list :target-chunk chunk
            :derived-status status
            :status-reason (topic-page-lookup-status-reason chunk)
            :repair-hint (topic-page-lookup-repair-hint chunk)
            :freshness-mode (topic-page-lookup-freshness-mode chunk)))))

(defun page-lookup-issue-repair-path-label (issue)
  (cond
    ((topic-page-lookup-issue-target-chunk issue)
     "Ensure target chunk")
    ((when-let (state (missing-local-fedwiki-twin-lookup-issue-runtime-state issue))
       (when (getf state :materialization-plan)
         t))
     "Materialize local FedWiki twin")
    ((when-let (repair (hb:lookup-issue-suggested-repair-of issue))
       (hb::issue-label repair)))
    (t
     "No bounded repair operation is currently attached.")))

(defun render-page-lookup-issue-runtime-summary-rows
    (issue &key include-target-chunk)
  (let* ((details (hb:lookup-issue-details-of issue))
         (chunk (topic-page-lookup-issue-target-chunk issue))
         (status-reason (or (getf details :status-reason)
                            (hb:lookup-issue-repair-description-of issue)))
         (freshness-mode (getf details :freshness-mode)))
    (views:html
      (when include-target-chunk
        (views:html
          (:tr (:td (views:esc "Target chunk"))
               (:td (if chunk
                        (views:object-ref chunk)
                        (views:esc ""))))))
      (:tr (:td (views:esc "Current-state reason"))
           (:td (views:esc (or status-reason ""))))
      (:tr (:td (views:esc "Repair path on click"))
           (:td (views:esc (page-lookup-issue-repair-path-label issue))))
      (when freshness-mode
        (views:html
          (:tr (:td (views:esc "Freshness mode"))
               (:td (:tt (views:esc
                          (hb::issue-label freshness-mode))))))))))

(defmethod hb:bounded-lookup-issue-current-status-of ((issue hb:page-lookup-issue))
  (or (when-let (chunk (topic-page-lookup-issue-target-chunk issue))
        (topic-page-lookup-chunk-state chunk))
      (when-let (state (missing-local-fedwiki-twin-lookup-issue-runtime-state issue))
        (when (getf state :local-page-exists-p)
          :fixed))))

(defmethod hb:bounded-lookup-issue-current-suggested-repair-of ((issue hb:page-lookup-issue))
  (or (when (topic-page-lookup-issue-target-chunk issue)
        :ensure-target-chunk)
      (when-let (state (missing-local-fedwiki-twin-lookup-issue-runtime-state issue))
        (when (getf state :materialization-plan)
          :materialize-local-fedwiki-twin))))

(defmethod hb:bounded-lookup-issue-current-repair-description-of ((issue hb:page-lookup-issue))
  (or (when-let (chunk (topic-page-lookup-issue-target-chunk issue))
        (topic-page-lookup-repair-description chunk))
      (missing-local-fedwiki-twin-repair-description issue)))

(defmethod hb:bounded-lookup-issue-current-repair-thunk-of ((issue hb:page-lookup-issue))
  (or (when (topic-page-lookup-issue-target-chunk issue)
        (lambda ()
          (issue-target-chunk issue)))
      (when-let (state (missing-local-fedwiki-twin-lookup-issue-runtime-state issue))
        (when (getf state :materialization-plan)
          (lambda ()
            (or (getf (missing-local-fedwiki-twin-lookup-issue-runtime-state issue)
                      :materialization-plan)
                (error "No current FedWiki materialization plan is available for ~A."
                       (hb:lookup-issue-expected-page-id-of issue))))))))

(defmethod hb:bounded-lookup-issue-current-details-of ((issue hb:page-lookup-issue))
  (or (topic-page-lookup-issue-runtime-details issue)
      (when-let (state (missing-local-fedwiki-twin-lookup-issue-runtime-state issue))
        (list :current-fedwiki-pages-directory
              (getf state :pages-directory)
              :current-fedwiki-repo-root
              (getf state :repo-root)
              :current-local-path
              (getf state :local-path)
              :current-local-page-exists-p
              (getf state :local-page-exists-p)
              :current-materialization-action
              (getf state :materialization-action)))))

(defmethod hb::bounded-lookup-issue-overview-extra-rows
    ((issue hb:page-lookup-issue))
  (render-page-lookup-issue-runtime-summary-rows
   issue
   :include-target-chunk t))

(defmethod hb::bounded-lookup-issue-repair-button-label-of
    ((issue hb:page-lookup-issue))
  (page-lookup-issue-repair-path-label issue))

(defmethod hb::bounded-lookup-issue-repair-extra-content
    ((issue hb:page-lookup-issue))
  (views:html
    (:table :class "inspector-table"
            (render-page-lookup-issue-runtime-summary-rows
             issue
             :include-target-chunk t))
    (when (topic-page-lookup-issue-target-chunk issue)
      (views:html
        (:p (views:esc
             "This repair path is chunk-first: clicking repair ensures the target chunk and its basis chain."))))))

(defmethod views:text-representation ((chunk page-lookup-target-chunk))
  (title-of chunk))

(defmethod views:text-representation ((chunk authored-topic-factory-chunk))
  (format nil "Authored topic factory ~A (~A)"
          (page-lookup-topic-title-of chunk)
          (if (chunk-satisfied-p chunk) "present" "missing")))

(defmethod views:text-representation ((chunk topic-page-availability-chunk))
  (format nil "Topic page ~A (~A)"
          (page-lookup-topic-title-of chunk)
          (hb::issue-label (topic-page-lookup-chunk-state chunk))))

(views:defview 👀overview (chunk authored-topic-factory-chunk)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Chunk"))
                   (:td (:tt (views:esc "authored-topic-factory"))))
              (:tr (:td (views:esc "Topic title"))
                   (:td (:tt (views:esc
                              (page-lookup-topic-title-of chunk)))))
              (:tr (:td (views:esc "Satisfied"))
                   (:td (:tt (views:esc
                              (if (chunk-satisfied-p chunk) "yes" "no")))))
              (:tr (:td (views:esc "Source signature token"))
                   (:td (:tt (views:esc
                              (format nil "~A"
                                      (topic-page-authored-signature-token
                                       (page-lookup-topic-title-of chunk)))))))
              (:tr (:td (views:esc "Summary"))
                   (:td (views:esc (summary-of chunk))))))))

(views:defview 👀freshness (chunk authored-topic-factory-chunk)
  (views:html-view :title "Freshness" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Authored factory in source"))
                   (:td (:tt (views:esc
                              (if (authored-topic-factory-defined-in-source-p
                                   (page-lookup-topic-title-of chunk))
                                  "yes"
                                  "no")))))
              (:tr (:td (views:esc "Source signature token"))
                   (:td (:tt (views:esc
                              (format nil "~A"
                                      (topic-page-authored-signature-token
                                       (page-lookup-topic-title-of chunk))))))))
      (if-let (signature
               (authored-topic-factory-source-signature
                (page-lookup-topic-title-of chunk)))
        (views:html
          (:p (views:esc "Authored topic factory signature"))
          (:pre (views:esc signature)))
        (views:html
          (:p (views:esc
               "No authored topic factory signature is available yet for this title.")))))))

(views:defview 👀materialization (chunk authored-topic-factory-chunk)
  (views:html-view :title "Materialization" :priority 3
    (views:html
      (:p (views:esc
           "Ensuring this chunk appends a placeholder topic factory to topics.lisp when no authored factory exists, then loads the updated source into the running image."))
      (:pre (views:esc
             (page-lookup-placeholder-topic-form
              (page-lookup-topic-title-of chunk)))))))

(views:defview 👀overview (chunk topic-page-availability-chunk)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Chunk"))
                   (:td (:tt (views:esc "topic-page-availability"))))
              (:tr (:td (views:esc "Topic title"))
                   (:td (:tt (views:esc
                              (page-lookup-topic-title-of chunk)))))
              (:tr (:td (views:esc "Derived issue state"))
                   (:td (:tt (views:esc
                              (hb::issue-label
                               (topic-page-lookup-chunk-state chunk))))))
              (:tr (:td (views:esc "Status reason"))
                   (:td (views:esc
                         (topic-page-lookup-status-reason chunk))))
              (:tr (:td (views:esc "Repair hint"))
                   (:td (views:esc
                         (topic-page-lookup-repair-hint chunk))))
              (:tr (:td (views:esc "Freshness mode"))
                   (:td (:tt (views:esc
                              (hb::issue-label
                               (topic-page-lookup-freshness-mode chunk))))))
              (:tr (:td (views:esc "Topic index state"))
                   (:td (:tt (views:esc
                              (hb::issue-label *topic-index-state*)))))
              (:tr (:td (views:esc "Page resolves"))
                   (:td (:tt (views:esc
                              (if (topic-page-resolves-p
                                   (page-lookup-topic-title-of chunk))
                                  "yes"
                                  "no")))))
              (:tr (:td (views:esc "Summary"))
                   (:td (views:esc (summary-of chunk))))))))

(views:defview 👀basis (chunk topic-page-availability-chunk)
  (views:html-view :title "Basis" :priority 2
    (let ((basis (chunk-basis chunk)))
      (views:html
        (:table :class "inspector-table"
                (dolist (basis-chunk basis)
                  (views:html
                    (:tr (:td (views:esc "Required chunk"))
                         (:td (views:object-ref basis-chunk))))))))))

(views:defview 👀freshness (chunk topic-page-availability-chunk)
  (views:html-view :title "Freshness" :priority 3
    (let* ((title (page-lookup-topic-title-of chunk))
           (source-signature (authored-topic-factory-source-signature title))
           (materialized-signature (topic-page-materialization-signature title)))
      (views:html
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Authored factory in source"))
                     (:td (:tt (views:esc
                                (if (authored-topic-factory-defined-in-source-p
                                     title)
                                    "yes"
                                    "no")))))
                (:tr (:td (views:esc "Freshness mode"))
                     (:td (:tt (views:esc
                                (hb::issue-label
                                 (topic-page-lookup-freshness-mode chunk))))))
                (:tr (:td (views:esc "Authored signature token"))
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (topic-page-authored-signature-token
                                         title))))))
                (:tr (:td (views:esc "Materialization signature token"))
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (topic-page-materialization-signature-token
                                         title))))))
                (:tr (:td (views:esc "Per-topic signatures match"))
                     (:td (:tt (views:esc
                                (if (topic-page-signatures-match-p title)
                                    "yes"
                                    "no")))))
                (:tr (:td (views:esc "Topics source write date"))
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (page-lookup-topic-source-write-date))))))
                (:tr (:td (views:esc "Topic index derived at"))
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (or *topic-index-derived-at*
                                            +no-info-date+)))))))
        (if source-signature
            (views:html
              (:p (views:esc "Authored topic factory signature"))
              (:pre (views:esc source-signature)))
            (views:html
              (:p (views:esc
                   "No authored topic factory signature is available for this title."))))
        (if materialized-signature
            (views:html
              (:p (views:esc "Materialized topic signature"))
              (:pre (views:esc materialized-signature)))
            (views:html
              (:p (views:esc
                   "No materialized topic signature is available yet for this title."))))))))

(views:defview 👀repair (chunk topic-page-availability-chunk)
  (views:html-view :title "Repair" :priority 4
    (views:html
      (:p (views:esc
           (topic-page-lookup-repair-description chunk)))
      (:p (views:esc
           "Repair for this issue class delegates to ensure-chunk on the target chunk."))
      (when (eq (topic-page-lookup-chunk-state chunk)
                :needs-topic-creation)
        (views:html
          (:p (views:esc
               "This repair path first ensures the authored-topic-factory basis chunk so the missing topic definition is added before the Topics page is rebuilt."))))
      (when (eq (topic-page-lookup-chunk-state chunk)
                :needs-local-materialization)
        (views:html
          (:p (views:esc
               "This repair path keeps the authored topic factory and refreshes only the running Topics materialization.")))))))
