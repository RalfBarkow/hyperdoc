;;;; Source-backed CTM merge into native TMDM, with an optional HyperDoc reading.
;;;; No independent Topic/Association model, no network fetch, no source mutation.
(defpackage #:dreyeck/work/paul-2026
  (:use #:cl)
  (:local-nicknames (#:ctm #:topic-maps.ctm)
                    (#:m #:topic-maps.tmdm)
                    (#:v #:html-inspector-views))
  (:export #:read-source-maps #:read-merged-map #:find-subject
           #:inspect-paul-workflows #:+shared-shop3-subject+))
(in-package #:dreyeck/work/paul-2026)

(defparameter +shared-shop3-subject+ "urn:hyperdoc:subject:shop3")
(defparameter +context-document-iri+
  "https://dreyeck.ch/topic-maps/paul-2026/hyperdoc-context.ctm")
(defparameter +paul-document-iri+
  "https://dreyeck.ch/topic-maps/paul-2026/paul-2026.ctm")

(defun ctm-path (name)
  (asdf:system-relative-pathname
   "dreyeck/work/paul-2026"
   (format nil "dreyeck/work/paul-2026/~A" name)))

(defun find-subject (map subject-identifier)
  "Find a native TMDM Topic by Subject Identifier; no second identity index."
  (find-if (lambda (topic)
             (member subject-identifier
                     (m:topic-subject-identifiers topic)
                     :test #'string=))
           (m:topic-map-topics map)))

(defun read-source-maps ()
  "Read both authored, versioned CTM sources into separate native TMDM Maps."
  (values
   (ctm:deserialize-file (ctm-path "hyperdoc-context.ctm")
                         :document-iri +context-document-iri+
                         :source-name "hyperdoc-context.ctm")
   (ctm:deserialize-file (ctm-path "paul-2026.ctm")
                         :document-iri +paul-document-iri+
                         :source-name "paul-2026.ctm")))

(defun read-merged-map ()
  "Return TARGET, SOURCE, and source-to-target resolver from a real TMDM import.
The previous target SHOP3 handle resolves through CANONICAL-TOPIC to the
current merged Topic; the independent Paul Topic resolves there through RESOLVE.
TMDM 6.2 can replace both target and copied Topic objects when merging.
This is a fresh in-memory reading; neither CTM source is modified."
  (multiple-value-bind (target source) (read-source-maps)
    (let ((context-shop3 (find-subject target +shared-shop3-subject+))
          (paul-shop3 (find-subject source +shared-shop3-subject+)))
      (unless (and context-shop3 paul-shop3)
        (error "Both sources must identify the shared SHOP3 subject."))
      (multiple-value-bind (merged resolve)
          (m:import-map-content target source)
        (let ((current-shop3
                (find-subject merged +shared-shop3-subject+)))
          (unless (and (eq merged target)
                       current-shop3
                       (eq current-shop3
                           (m:canonical-topic context-shop3))
                       (eq current-shop3 (funcall resolve paul-shop3))
                       (not (eq paul-shop3 context-shop3))
                       (find-subject merged
                         "urn:hyperdoc:paul-2026:domain:worksworld-2h"))
            (error "Native TMDM canonical subject merge contract was not met.")))
        (values merged source resolve)))))

(hyperdoc:defexample inspect-paul-workflows
  "Read a fresh merged TMDM Map from the two versioned CTM sources."
  (read-merged-map))

(v:defview paul-2026-merged-map-entry (page hyperbook:page)
  (when (and (equal "dreyeck/work/paul-2026"
                    (hyperbook:id-of (hyperbook:hyperbook-of page)))
             (equal "Reading Paul 2026 with Topic Maps"
                    (hyperbook:id-of page)))
    (v:html-view :title "Native Topic Map" :priority 140
      (v:html
        (:h2 "Read the native TMDM merge")
        (:p "Explicit local reading. The imported source and HyperDoc context remain separate CTM files.")
        (:p (dreyeck/authority-policy:run-button
             "Read and merge CTM sources"
             (v:thunk (inspect-paul-workflows))
             "Run an in-memory native Topic Maps import"))
        (:p (v:object-ref #'inspect-paul-workflows
                          :display "Read/merge definition"
                          :select "Source code"))))))

(hyperdoc:defhyperdoc *paul-2026-reading*
  :title "Paul 2026: Workflow Planning as Topic Maps"
  :id "dreyeck/work/paul-2026"
  :asdf-system-name "dreyeck/work/paul-2026"
  :subdirectory "dreyeck/pages/paul-2026"
  :code-subdirectory "dreyeck/work/paul-2026"
  :main-page-id "Reading Paul 2026 with Topic Maps")
