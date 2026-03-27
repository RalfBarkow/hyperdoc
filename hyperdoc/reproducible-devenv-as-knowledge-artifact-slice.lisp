;;;; Narrow chunk-driven slice for Reproducible DevEnv as Knowledge Artifact
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *reproducible-devenv-as-knowledge-artifact-topic-asset*
  "assets/reproducible-devenv-as-knowledge-artifact-topic.lisp")

(defparameter *reproducible-devenv-as-knowledge-artifact-page-path*
  "hyperdoc/Reproducible DevEnv as Knowledge Artifact.html")

(defparameter *reproducible-devenv-as-knowledge-artifact-fedwiki-site*
  "wiki.ralfbarkow.ch")

(defparameter *reproducible-devenv-as-knowledge-artifact-fedwiki-slug*
  "reproducible-devenv-as-knowledge-artifact")

(defparameter *reproducible-devenv-as-knowledge-artifact-fedwiki-html-url*
  "https://hyperdoc.wiki.khinsen.net/view/reproducible-devenv-as-knowledge-artifact")

(defparameter +reproducible-devenv-as-knowledge-artifact-topic-extraction-specs+
  '((:id "reproducible-devenv-as-knowledge-artifact"
     :title "Reproducible DevEnv as Knowledge Artifact"
     :summary "Reproducible development environments become knowledge artifacts when they stay inspectable as first-class topics and remain linked to the work they support."
     :fragment-selections ((:item-index 0 :whole-item t)
                           (:item-index 1 :whole-item t))
     :topic-kind :umbrella
     :references ("Reproducible DevEnv as Knowledge Artifact"
                  "The Life Cycle of Collective Knowledge"
                  "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact")
     :derivation-note
     "Derived by grouping two whole localhost FedWiki story items about treating reproducible development environments as knowledge artifacts and tracing their use across work surfaces.")
    (:id "devenv-as-knowledge-artifact"
     :title "Dev environment as knowledge artifact"
     :summary "A Nix flake or devShell can be treated as a knowledge artifact because it carries dependencies, platform assumptions, and other operational context as one inspectable unit."
     :fragment-selections ((:item-index 0 :whole-item t))
     :topic-kind :subtopic
     :references ("Reproducible DevEnv as Knowledge Artifact"
                  "The Life Cycle of Collective Knowledge"
                  "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact")
     :derivation-note
     "Derived from the first whole localhost FedWiki story item.")
    (:id "environment-topic-traceability"
     :title "Environment topic traceability"
     :summary "Linking environment topics to projects, FedWiki pages, and notebooks keeps shell requirements queryable across onboarding and maintenance work."
     :fragment-selections ((:item-index 1 :whole-item t))
     :topic-kind :subtopic
     :references ("Reproducible DevEnv as Knowledge Artifact"
                  "The Life Cycle of Collective Knowledge"
                  "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact")
     :derivation-note
     "Derived from the second whole localhost FedWiki story item.")))

(defun reproducible-devenv-as-knowledge-artifact-topic-asset-path ()
  (asdf:system-relative-pathname
   :hyperdoc
   *reproducible-devenv-as-knowledge-artifact-topic-asset*))

(defun reproducible-devenv-as-knowledge-artifact-page-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   *reproducible-devenv-as-knowledge-artifact-page-path*))

(defun reproducible-devenv-as-knowledge-artifact-source-claim-from-pipeline
    (source-data story-items primary-item)
  (or (and (second story-items)
           (localhost-fedwiki-item-data-text (second story-items)))
      (default-localhost-fedwiki-source-claim
       source-data
       story-items
       primary-item)))

(defun reproducible-devenv-as-knowledge-artifact-page-pipeline-spec ()
  (make-localhost-fedwiki-page-pipeline-spec
   :id *reproducible-devenv-as-knowledge-artifact-fedwiki-slug*
   :page-title "Reproducible DevEnv as Knowledge Artifact"
   :site *reproducible-devenv-as-knowledge-artifact-fedwiki-site*
   :slug *reproducible-devenv-as-knowledge-artifact-fedwiki-slug*
   :html-url *reproducible-devenv-as-knowledge-artifact-fedwiki-html-url*
   :source-claim-function
   #'reproducible-devenv-as-knowledge-artifact-source-claim-from-pipeline
   :source-chunk-id
   "reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-source"
   :source-chunk-title
   "Reproducible DevEnv as Knowledge Artifact localhost FedWiki source"
   :source-summary-fallback
   "Localhost FedWiki source page for Reproducible DevEnv as Knowledge Artifact."))

(defun reproducible-devenv-as-knowledge-artifact-page-pipeline ()
  (run-localhost-fedwiki-page-pipeline
   (reproducible-devenv-as-knowledge-artifact-page-pipeline-spec)
   +reproducible-devenv-as-knowledge-artifact-topic-extraction-specs+))

(defun reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-page ()
  (copy-tree
   (localhost-fedwiki-page-pipeline-result-raw-page
    (reproducible-devenv-as-knowledge-artifact-page-pipeline))))

(defun reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-source-chunk ()
  (localhost-fedwiki-source-data->chunk
   (localhost-fedwiki-page-pipeline-result-source
    (reproducible-devenv-as-knowledge-artifact-page-pipeline))))

(defun reproducible-devenv-as-knowledge-artifact-umbrella-topic-chunk ()
  (localhost-fedwiki-promoted-topic-data->chunk
   (localhost-fedwiki-page-pipeline-result-umbrella-topic
    (reproducible-devenv-as-knowledge-artifact-page-pipeline))))

(defun reproducible-devenv-as-knowledge-artifact-subtopic-chunks ()
  (mapcar #'localhost-fedwiki-promoted-topic-data->chunk
          (localhost-fedwiki-page-pipeline-result-subtopics
           (reproducible-devenv-as-knowledge-artifact-page-pipeline))))

(defun reproducible-devenv-as-knowledge-artifact-topic-chunks ()
  (mapcar #'localhost-fedwiki-promoted-topic-data->chunk
          (localhost-fedwiki-page-pipeline-result-topic-chunks
           (reproducible-devenv-as-knowledge-artifact-page-pipeline))))

(defun find-reproducible-devenv-as-knowledge-artifact-topic-chunk (topic-id
                                                                   &key signal-error?)
  (or (find topic-id
            (reproducible-devenv-as-knowledge-artifact-topic-chunks)
            :key #'id-of
            :test #'equal)
      (and signal-error?
           (error "Unknown Reproducible DevEnv as Knowledge Artifact topic id ~S."
                  topic-id))))

(defun reproducible-devenv-topic-list-entries (chunks)
  (mapcar (lambda (chunk)
            (list :title (title-of chunk)
                  :summary (summary-of chunk)))
          chunks))

(defun reproducible-devenv-as-knowledge-artifact-default-topic-factory-metadata ()
  (make-localhost-fedwiki-topic-factory-metadata-from-pipeline
   (reproducible-devenv-as-knowledge-artifact-page-pipeline)
   :id "reproducible-devenv-as-knowledge-artifact-topic-set"
   :source-file *reproducible-devenv-as-knowledge-artifact-topic-asset*
   :related-hyperdoc-page-title "Reproducible DevEnv as Knowledge Artifact"
   :related-topic-id "reproducible-devenv-as-knowledge-artifact"
   :fragment-selections '((:item-index 0 :whole-item t)
                          (:item-index 1 :whole-item t))
   :note
   "Dry-run-first DMX snippet twin for authored HyperDoc topic factories derived from two whole localhost FedWiki story items."))

(defun normalize-reproducible-devenv-as-knowledge-artifact-topic-factory-metadata
    (metadata)
  (let ((defaults
          (reproducible-devenv-as-knowledge-artifact-default-topic-factory-metadata)))
    (list :id (or (getf metadata :id)
                  (getf defaults :id))
          :source-file (or (getf metadata :source-file)
                           (getf defaults :source-file))
          :source-origin-id (or (getf metadata :source-origin-id)
                                (getf defaults :source-origin-id))
          :source-origin-path (or (getf metadata :source-origin-path)
                                  (getf defaults :source-origin-path))
          :related-hyperdoc-page-title
          (or (getf metadata :related-hyperdoc-page-title)
              (getf defaults :related-hyperdoc-page-title))
          :related-topic-id (or (getf metadata :related-topic-id)
                                (getf defaults :related-topic-id))
          :related-topic-ids (or (copy-list (getf metadata :related-topic-ids))
                                 (copy-list (getf defaults :related-topic-ids)))
          :provenance
          (copy-tree
           (or (getf metadata :provenance)
               (getf defaults :provenance))))))

(defun reproducible-devenv-as-knowledge-artifact-topic-factory-metadata ()
  (let ((path (reproducible-devenv-as-knowledge-artifact-topic-asset-path)))
    (if (uiop:file-exists-p path)
        (with-open-file (stream path
                                :direction :input
                                :external-format :utf-8)
          (let ((form (read stream nil nil)))
            (unless (and (consp form)
                         (eq (first form) :topic-factory-snippet))
              (error "Topic-factory asset must start with a :topic-factory-snippet plist."))
            (normalize-reproducible-devenv-as-knowledge-artifact-topic-factory-metadata
             (rest form))))
        (reproducible-devenv-as-knowledge-artifact-default-topic-factory-metadata))))

(defun render-topic-factory-form-from-chunk (chunk)
  (with-output-to-string (stream)
    (format stream
            "(defun ~A ()~%  (make-topic~%   :id ~S~%   :title ~S~%   :summary ~S~%   :references '~S))"
            (format nil "~A-TOPIC" (string-upcase (id-of chunk)))
            (id-of chunk)
            (title-of chunk)
            (summary-of chunk)
            (references-of chunk))))

(defun reproducible-devenv-as-knowledge-artifact-topic-definition-chunk ()
  (let* ((metadata
           (reproducible-devenv-as-knowledge-artifact-topic-factory-metadata))
         (snippet-path
           (reproducible-devenv-as-knowledge-artifact-topic-asset-path))
         (source-file
           (or (getf metadata :source-file)
               *reproducible-devenv-as-knowledge-artifact-topic-asset*)))
    (make-instance 'topic-definition-chunk
                   :id (getf metadata :id)
                   :title
                   "Reproducible DevEnv as Knowledge Artifact topic-definition chunk"
                   :summary
                   "Topic-factory snippet bundle for the authored Reproducible DevEnv as Knowledge Artifact topic set."
                   :source-path source-file
                   :references
                   (list (getf metadata :source-origin-id)
                         *reproducible-devenv-as-knowledge-artifact-page-path*)
                   :snippet-id (getf metadata :id)
                   :snippet-text (if (uiop:file-exists-p snippet-path)
                                     (read-utf8-file-string snippet-path)
                                     "")
                   :source-origin-id (getf metadata :source-origin-id)
                   :source-origin-path (getf metadata :source-origin-path)
                   :related-hyperdoc-page-title
                   (getf metadata :related-hyperdoc-page-title)
                   :related-topic-id (getf metadata :related-topic-id)
                   :related-topic-ids (copy-list (getf metadata :related-topic-ids))
                   :provenance (copy-tree (getf metadata :provenance)))))

(defun reproducible-devenv-as-knowledge-artifact-dmx-snippet-chunk ()
  (let ((definition
          (reproducible-devenv-as-knowledge-artifact-topic-definition-chunk)))
    (make-instance 'dmx-snippet-chunk
                   :id (format nil "~A-dmx" (snippet-id-of definition))
                   :title
                   "Reproducible DevEnv as Knowledge Artifact DMX snippet chunk"
                   :summary
                   "DMX twin/snippet chunk for the Reproducible DevEnv as Knowledge Artifact topic-factory bundle."
                   :source-path (source-path-of definition)
                   :references
                   (list (source-origin-id-of definition)
                         "DMX FedWiki Write Model"
                         "Runtime write live-proof gate")
                   :snippet-id (snippet-id-of definition)
                   :snippet-uri
                   (format nil "hyperdoc:topic-factory-snippet/~A"
                           (snippet-id-of definition))
                   :snippet-text (snippet-text-of definition)
                   :related-hyperdoc-page-title
                   (related-hyperdoc-page-title-of definition)
                   :related-topic-id (related-topic-id-of definition)
                   :related-topic-ids (copy-list (related-topic-ids-of definition))
                   :provenance (copy-tree (provenance-of definition)))))

(defun render-reproducible-devenv-as-knowledge-artifact-topic-factory-snippet ()
  (let* ((definition
           (reproducible-devenv-as-knowledge-artifact-topic-definition-chunk))
         (metadata
           (list :topic-factory-snippet
                 :id (snippet-id-of definition)
                 :source-file
                 *reproducible-devenv-as-knowledge-artifact-topic-asset*
                 :source-origin-id (source-origin-id-of definition)
                 :source-origin-path (source-origin-path-of definition)
                 :related-hyperdoc-page-title
                 (related-hyperdoc-page-title-of definition)
                 :related-topic-id (related-topic-id-of definition)
                 :related-topic-ids (related-topic-ids-of definition)
                 :provenance (provenance-of definition)))
         (topic-forms
           (mapcar #'render-topic-factory-form-from-chunk
                   (reproducible-devenv-as-knowledge-artifact-topic-chunks))))
    (with-output-to-string (stream)
      (pprint metadata stream)
      (terpri stream)
      (terpri stream)
      (format stream
              ";; Topic-factory snippet bundle for Reproducible DevEnv as Knowledge Artifact.~%~%")
      (loop for form in topic-forms
            for first? = t then nil
            do (unless first?
                 (terpri stream)
                 (terpri stream))
               (write-string form stream))
      (terpri stream))))

(defun render-reproducible-devenv-as-knowledge-artifact-page ()
  (let* ((source
           (reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-source-chunk))
         (umbrella
           (reproducible-devenv-as-knowledge-artifact-umbrella-topic-chunk))
         (subtopics
           (reproducible-devenv-as-knowledge-artifact-subtopic-chunks))
         (definition
           (reproducible-devenv-as-knowledge-artifact-topic-definition-chunk))
         (dmx-snippet
           (reproducible-devenv-as-knowledge-artifact-dmx-snippet-chunk))
         (story-items (story-items-of source))
         (topic-list (cons umbrella subtopics))
         (whole-item-topics
           (remove "multi-item-derived"
                   topic-list
                   :key (lambda (chunk)
                          (getf (provenance-of chunk) :provenance-granularity))
                   :test #'equal))
         (intro-blocks
           (list
            (format nil
                    "<p>~%  This authored HyperDoc page is composed from FedWiki-derived chunks read from the~%  localhost page <tt>~A</tt> at repo-relative source path <tt>~A</tt>.~%</p>"
                    (fedwiki-page-id-of source)
                    (fedwiki-relative-path-of source))
            (format nil
                    "<p>~%  The local composition path stays usable without DMX. The topic-factory snippet asset~%  <tt>~A</tt> remains a separate derived artifact, and the DMX writer stays a~%  separate, explicit, dry-run-first twin path rather than a live proxy for this~%  authored page.~%</p>"
                    *reproducible-devenv-as-knowledge-artifact-topic-asset*)))
         (section-blocks
           (list
            (list :title "Source claim"
                  :body-html
                  (format nil "<p>~%  ~A~% </p>~%~%<p>~%  ~A~% </p>"
                          (claim-of source)
                          (body-of umbrella)))
            (list :title "Reusable topic chunks"
                  :body-html
                  (render-topic-list-html
                   (reproducible-devenv-topic-list-entries topic-list)))
            (list
             :title "Local composition path"
             :body-html
             (with-output-to-string (stream)
               (format stream "<p>~%")
               (format stream "  This page promotes one reusable topic from each whole paragraph story item.~%")
               (format stream "  The two subtopics therefore keep <tt>story-item</tt> provenance, while the umbrella~%")
               (format stream "  topic explicitly records <tt>multi-item-derived</tt> provenance across both items.~%")
               (format stream "</p>~%~%")
               (format stream "<ul>~%")
               (format stream "  <li><a expr=\"(hyperdoc::reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-source-chunk)\"><tt>Localhost FedWiki source chunk</tt></a></li>~%")
               (format stream "  <li><a expr=\"(hyperdoc::reproducible-devenv-as-knowledge-artifact-topic-definition-chunk)\"><tt>Topic-definition chunk</tt></a></li>~%")
               (format stream "  <li><a expr=\"(hyperdoc::reproducible-devenv-as-knowledge-artifact-subtopic-chunks)\"><tt>Subtopic chunks</tt></a></li>~%")
               (format stream "  <li><a expr=\"(hyperdoc::reproducible-devenv-as-knowledge-artifact-topic-page-chunk)\"><tt>Topic-page chunk</tt></a></li>~%")
               (format stream "</ul>")))
            (list
             :title "DMX snippet twin"
             :body-html
             (with-output-to-string (stream)
               (format stream "<p>~%")
               (format stream "  The DMX twin/snippet chunk writes the topic-factory bundle under the stable URI~%")
               (format stream "  <tt>~A</tt>. It carries snippet text, canonical source-file provenance, the~%"
                       (snippet-uri-of dmx-snippet))
               (format stream "  related HyperDoc page title, and the related umbrella topic id <tt>~A</tt>.~%"
                       (related-topic-id-of definition))
               (format stream "</p>~%~%")
               (format stream "<ul>~%")
               (format stream "  <li><a expr=\"(hyperdoc::reproducible-devenv-as-knowledge-artifact-dmx-snippet-chunk)\"><tt>DMX twin/snippet chunk</tt></a></li>~%")
               (format stream "  <li><tt>plan-topic-factory-snippet-dmx-write</tt> for plan-only inspection.</li>~%")
               (format stream "  <li><tt>execute-topic-factory-snippet-dmx-write</tt> for explicit dry-run or live execution.</li>~%")
               (format stream "  <li><a page=\"DMX FedWiki Write Model\">DMX FedWiki Write Model</a></li>~%")
               (format stream "  <li><a hyperbook=\"topics\" page=\"Runtime write live-proof gate\"><tt>Runtime write live-proof gate</tt></a></li>~%")
               (format stream "</ul>")))
            (list
             :title "FedWiki source"
             :body-html
             (with-output-to-string (stream)
               (format stream "<p>~%")
               (format stream "  Source FedWiki page id: <tt>~A</tt>. Repo-relative page path: <tt>~A</tt>.~%"
                       (fedwiki-page-id-of source)
                       (fedwiki-relative-path-of source))
               (format stream "</p>~%~%")
               (format stream "<p>~%")
               (format stream "  External source URL: <a href=\"~A\"><tt>~A</tt></a>. Parsed story items: <tt>~D</tt>.~%"
                       (fedwiki-url-of source)
                       (fedwiki-url-of source)
                       (length story-items))
               (format stream "</p>~%~%")
               (format stream "<p>~%")
               (format stream "  The individual reusable topics are derived from <tt>~D</tt> whole paragraph story items,~%"
                       (length whole-item-topics))
               (format stream "  and the umbrella topic records multi-item provenance across both source items.~%")
               (format stream "</p>")))
            (list
             :title "Promotion workflow"
             :body-html
             (render-localhost-fedwiki-promotion-workflow-section-html
              :promotion-plan-expression
              "(hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan)"
              :source-expression
              "(hyperdoc::reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-source-chunk)"
              :source-page-id
              (fedwiki-page-id-of source)
              :source-page-path
              (fedwiki-relative-path-of source)))
            (list
             :title "Inspectable objects"
             :body-html
             (with-output-to-string (stream)
               (format stream "~A~%"
                       (render-topic-list-html
                        (reproducible-devenv-topic-list-entries topic-list)))
               (format stream "<ul>~%")
               (format stream "  <li><a expr=\"(hyperdoc::reproducible-devenv-as-knowledge-artifact-topic-definition-chunk)\"><tt>~A</tt></a></li>~%"
                       (title-of definition))
               (format stream "  <li><a expr=\"(hyperdoc::reproducible-devenv-as-knowledge-artifact-dmx-snippet-chunk)\"><tt>~A</tt></a></li>~%"
                       (title-of dmx-snippet))
               (format stream "</ul>"))))))
    (render-hyperdoc-page-shell
     "Reproducible DevEnv as Knowledge Artifact"
     intro-blocks
     section-blocks)))

(defun reproducible-devenv-as-knowledge-artifact-topic-page-chunk ()
  (make-instance 'topic-page-chunk
                 :id "reproducible-devenv-as-knowledge-artifact-topic-page"
                 :title
                 "Reproducible DevEnv as Knowledge Artifact topic-page chunk"
                 :summary
                 "Composed HyperDoc page chunk for Reproducible DevEnv as Knowledge Artifact."
                 :source-path *reproducible-devenv-as-knowledge-artifact-page-path*
                 :references '("Reproducible DevEnv as Knowledge Artifact")
                 :page-path *reproducible-devenv-as-knowledge-artifact-page-path*
                 :page-html
                 (render-reproducible-devenv-as-knowledge-artifact-page)
                 :composed-from
                 (list
                  (fedwiki-page-id-of
                   (reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-source-chunk))
                  *reproducible-devenv-as-knowledge-artifact-topic-asset*)))

(defun parse-reproducible-devenv-as-knowledge-artifact-chunks ()
  (list :source-fedwiki-page
        (reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-source-chunk)
        :topic-definition
        (reproducible-devenv-as-knowledge-artifact-topic-definition-chunk)
        :umbrella-topic
        (reproducible-devenv-as-knowledge-artifact-umbrella-topic-chunk)
        :subtopics
        (reproducible-devenv-as-knowledge-artifact-subtopic-chunks)
        :topic-page
        (reproducible-devenv-as-knowledge-artifact-topic-page-chunk)
        :dmx-snippet
        (reproducible-devenv-as-knowledge-artifact-dmx-snippet-chunk)))

(defun write-reproducible-devenv-as-knowledge-artifact-artifacts ()
  (let* ((source
           (reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-source-chunk))
         (snippet-path (reproducible-devenv-as-knowledge-artifact-topic-asset-path))
         (page-path (reproducible-devenv-as-knowledge-artifact-page-pathname)))
    (write-utf8-file-string
     snippet-path
     (render-localhost-fedwiki-topic-snippet-artifact-with-source-snapshot
      (render-reproducible-devenv-as-knowledge-artifact-topic-factory-snippet)
      source))
    (write-utf8-file-string
     page-path
     (render-localhost-fedwiki-page-artifact-with-source-snapshot
      (render-reproducible-devenv-as-knowledge-artifact-page)
      source))
    (list :topic-asset (hyperdoc-relative-path-string snippet-path)
          :page (hyperdoc-relative-path-string page-path))))
