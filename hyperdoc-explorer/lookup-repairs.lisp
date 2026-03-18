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
         (local-exists-p (and local-path (uiop:file-exists-p local-path)))
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

