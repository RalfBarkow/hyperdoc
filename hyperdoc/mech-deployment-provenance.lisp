;;;; Inspectable deployment-provenance objects for live Mech runtime evidence
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *upstream-mech-reference-commit*
  "47cba6d57bef6db43e237abcbad60829d78b691c")

(defparameter *upstream-mech-reference-version*
  "0.1.42-0")

(defparameter *patched-mech-discourse-graphs-version*
  "0.1.32-dev.1")

(defparameter *patched-mech-discourse-graphs-block-vocabulary*
  '("EXTRACT"
    "EDGES"
    "questions"
    "claims"
    "renderEdgesHtml"
    "parse_walk_command"))

(defclass mech-provenance-evidence ()
  ((kind :reader mech-provenance-evidence-kind-of
         :initarg :kind)
   (source :reader mech-provenance-evidence-source-of
           :initarg :source)
   (detail :reader mech-provenance-evidence-detail-of
           :initarg :detail)
   (value :reader mech-provenance-evidence-value-of
          :initarg :value
          :initform nil)))

(defclass mech-host-runtime-provenance-report ()
  ((host :reader mech-host-runtime-provenance-host-of
         :initarg :host)
   (plugin-endpoints
    :reader mech-host-runtime-provenance-plugin-endpoints-of
    :initarg :plugin-endpoints
    :initform nil)
   (content-endpoints
    :reader mech-host-runtime-provenance-content-endpoints-of
    :initarg :content-endpoints
    :initform nil)
   (plugin-version
    :reader mech-host-runtime-provenance-plugin-version-of
    :initarg :plugin-version
    :initform nil)
   (repository-url
    :reader mech-host-runtime-provenance-repository-url-of
    :initarg :repository-url
    :initform nil)
   (asset-digests
    :reader mech-host-runtime-provenance-asset-digests-of
    :initarg :asset-digests
    :initform nil)
   (build-commit
    :reader mech-host-runtime-provenance-build-commit-of
    :initarg :build-commit
    :initform nil)
   (served-vocabulary
    :reader mech-host-runtime-provenance-served-vocabulary-of
    :initarg :served-vocabulary
    :initform nil)
   (proxied-from
    :reader mech-host-runtime-provenance-proxied-from-of
    :initarg :proxied-from
    :initform nil)
   (classification
    :reader mech-host-runtime-provenance-classification-of
    :initarg :classification)
   (notes :reader summary-of
          :reader mech-host-runtime-provenance-notes-of
          :initarg :notes
          :initform nil)
   (evidence
    :reader mech-host-runtime-provenance-evidence-of
    :initarg :evidence
    :initform nil)))

(defclass live-plugin-provenance-skill ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (purpose :reader summary-of
            :reader live-plugin-provenance-skill-purpose-of
            :initarg :purpose)
   (inputs :reader live-plugin-provenance-skill-inputs-of
           :initarg :inputs
           :initform nil)
   (evidence-sources
    :reader live-plugin-provenance-skill-evidence-sources-of
    :initarg :evidence-sources
    :initform nil)
   (steps :reader live-plugin-provenance-skill-steps-of
          :initarg :steps
          :initform nil)
   (host-comparison-method
    :reader live-plugin-provenance-skill-host-comparison-method-of
    :initarg :host-comparison-method
    :initform nil)
   (acceptance-criteria
    :reader live-plugin-provenance-skill-acceptance-criteria-of
    :initarg :acceptance-criteria
    :initform nil)
   (classification-outcomes
    :reader live-plugin-provenance-skill-classification-outcomes-of
    :initarg :classification-outcomes
    :initform nil)
   (operation-factory
    :reader live-plugin-provenance-skill-operation-factory-of
    :initarg :operation-factory
    :initform nil)
   (canonical-page
    :reader live-plugin-provenance-skill-canonical-page-of
    :initarg :canonical-page
    :initform nil)))

(defclass live-mech-plugin-provenance-check ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (read-only-p
    :reader live-mech-plugin-provenance-check-read-only-p-of
    :initarg :read-only-p
    :initform t)
   (upstream-reference-commit
    :reader live-mech-plugin-provenance-check-upstream-reference-commit-of
    :initarg :upstream-reference-commit)
   (upstream-reference-version
    :reader live-mech-plugin-provenance-check-upstream-reference-version-of
    :initarg :upstream-reference-version)
   (patched-lineage-version
    :reader live-mech-plugin-provenance-check-patched-lineage-version-of
    :initarg :patched-lineage-version
    :initform nil)
   (evidence-sources
    :reader live-mech-plugin-provenance-check-evidence-sources-of
    :initarg :evidence-sources
    :initform nil)
   (reports :reader live-mech-plugin-provenance-check-reports-of
            :initarg :reports
            :initform nil)
   (conclusion
    :reader live-mech-plugin-provenance-check-conclusion-of
    :initarg :conclusion
    :initform nil)))

(defmethod print-object ((object mech-provenance-evidence) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A"
            (mech-provenance-evidence-kind-of object)
            (mech-provenance-evidence-source-of object))))

(defmethod print-object ((object mech-host-runtime-provenance-report) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A"
            (mech-host-runtime-provenance-host-of object)
            (mech-host-runtime-provenance-classification-of object))))

(defmethod print-object ((object live-plugin-provenance-skill) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object live-mech-plugin-provenance-check) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun make-mech-provenance-evidence (&key kind source detail value)
  (make-instance 'mech-provenance-evidence
                 :kind kind
                 :source source
                 :detail detail
                 :value value))

(defun mech-provenance-evidence-summary-alist (evidence)
  (list (cons :kind (mech-provenance-evidence-kind-of evidence))
        (cons :source (mech-provenance-evidence-source-of evidence))
        (cons :detail (mech-provenance-evidence-detail-of evidence))
        (cons :value (mech-provenance-evidence-value-of evidence))))

(defun patched-mech-block-vocabulary-tokens ()
  (copy-list *patched-mech-discourse-graphs-block-vocabulary*))

(defun patched-mech-block-vocabulary-present-p (served-vocabulary)
  (let ((vocabulary (copy-list served-vocabulary)))
    (every (lambda (token)
             (member token vocabulary :test #'string=))
           (patched-mech-block-vocabulary-tokens))))

(defun host-matches-upstream-mech-p
    (&key build-commit plugin-version served-vocabulary
       (upstream-reference-commit *upstream-mech-reference-commit*)
       (upstream-reference-version *upstream-mech-reference-version*))
  (and (string= (or build-commit "") upstream-reference-commit)
       (string= (or plugin-version "") upstream-reference-version)
       (not (patched-mech-block-vocabulary-present-p served-vocabulary))))

(defun host-matches-patched-mech-lineage-p
    (&key build-commit plugin-version served-vocabulary
       (upstream-reference-commit *upstream-mech-reference-commit*)
       (patched-lineage-version *patched-mech-discourse-graphs-version*))
  (or (patched-mech-block-vocabulary-present-p served-vocabulary)
      (string= (or plugin-version "") patched-lineage-version)
      (and build-commit
           (not (string= build-commit upstream-reference-commit)))))

(defun classify-mech-host-runtime-provenance
    (&key build-commit plugin-version served-vocabulary proxied-from
       (upstream-reference-commit *upstream-mech-reference-commit*)
       (upstream-reference-version *upstream-mech-reference-version*)
       (patched-lineage-version *patched-mech-discourse-graphs-version*))
  (cond
    (proxied-from :proxied)
    ((host-matches-upstream-mech-p
      :build-commit build-commit
      :plugin-version plugin-version
      :served-vocabulary served-vocabulary
      :upstream-reference-commit upstream-reference-commit
      :upstream-reference-version upstream-reference-version)
     :upstream)
    ((host-matches-patched-mech-lineage-p
      :build-commit build-commit
      :plugin-version plugin-version
      :served-vocabulary served-vocabulary
      :upstream-reference-commit upstream-reference-commit
      :patched-lineage-version patched-lineage-version)
     :patched)
    (t :unresolved)))

(defun make-mech-host-runtime-provenance-report
    (&key host plugin-endpoints content-endpoints plugin-version repository-url
       asset-digests build-commit served-vocabulary proxied-from notes evidence
       (upstream-reference-commit *upstream-mech-reference-commit*)
       (upstream-reference-version *upstream-mech-reference-version*)
       (patched-lineage-version *patched-mech-discourse-graphs-version*))
  (make-instance
   'mech-host-runtime-provenance-report
   :host host
   :plugin-endpoints plugin-endpoints
   :content-endpoints content-endpoints
   :plugin-version plugin-version
   :repository-url repository-url
   :asset-digests asset-digests
   :build-commit build-commit
   :served-vocabulary served-vocabulary
   :proxied-from proxied-from
   :classification
   (classify-mech-host-runtime-provenance
    :build-commit build-commit
    :plugin-version plugin-version
    :served-vocabulary served-vocabulary
    :proxied-from proxied-from
    :upstream-reference-commit upstream-reference-commit
    :upstream-reference-version upstream-reference-version
    :patched-lineage-version patched-lineage-version)
   :notes notes
   :evidence evidence))

(defun mech-host-runtime-provenance-report-summary-alist (report)
  (list
   (cons :host (mech-host-runtime-provenance-host-of report))
   (cons :classification
         (mech-host-runtime-provenance-classification-of report))
   (cons :plugin-endpoints
         (mech-host-runtime-provenance-plugin-endpoints-of report))
   (cons :content-endpoints
         (mech-host-runtime-provenance-content-endpoints-of report))
   (cons :plugin-version
         (mech-host-runtime-provenance-plugin-version-of report))
   (cons :repository-url
         (mech-host-runtime-provenance-repository-url-of report))
   (cons :asset-digests
         (mech-host-runtime-provenance-asset-digests-of report))
   (cons :build-commit
         (mech-host-runtime-provenance-build-commit-of report))
   (cons :served-vocabulary
         (mech-host-runtime-provenance-served-vocabulary-of report))
   (cons :proxied-from
         (mech-host-runtime-provenance-proxied-from-of report))
   (cons :notes (mech-host-runtime-provenance-notes-of report))
   (cons :evidence
         (mapcar #'mech-provenance-evidence-summary-alist
                 (mech-host-runtime-provenance-evidence-of report)))))

(defun make-wiki-ralfbarkow-live-mech-host-report ()
  (make-mech-host-runtime-provenance-report
   :host "wiki.ralfbarkow.ch"
   :plugin-endpoints
   '("https://wiki.ralfbarkow.ch/system/plugins.json"
     "https://wiki.ralfbarkow.ch/plugin/plugmatic/plugins"
     "https://wiki.ralfbarkow.ch/plugins/mech/mech.js"
     "https://wiki.ralfbarkow.ch/plugins/mech/blocks.js"
     "https://wiki.ralfbarkow.ch/plugins/mech/interpreter.js"
     "https://wiki.ralfbarkow.ch/plugins/mech/library.js")
   :content-endpoints
   '("https://wiki.ralfbarkow.ch/discourse-graphs.json")
   :plugin-version "0.1.32-dev.1"
   :repository-url "https://github.com/wardcunningham/wiki-plugin-mech.git"
   :asset-digests
   '(("mech.js"
      . "d25151ef5170779de50e13e819b950277b99aa7a6591ef097eaef5c0043d71c7")
     ("blocks.js"
      . "6ca7ad52fa35ef655990e2c2d2304db795df70401b15af7d830723d0e217556f")
     ("interpreter.js"
      . "f0a0b360496ee520072421e1b4cc9584b6e46b47df455fcd5c8406e9baa5e90f")
     ("library.js"
      . "e5eb6f3300fa06e872bc2fcc3ed1dfda14d983e91b71b9c7f7c2417f697b39bb"))
   :served-vocabulary
   (patched-mech-block-vocabulary-tokens)
   :notes
   "Live host serves patched Mech lineage with downstream Discourse-Graphs block vocabulary, but its mech.js omits a build stamp so the exact commit remains unresolved."
   :evidence
   (list
    (make-mech-provenance-evidence
     :kind :plugin-metadata
     :source "/plugin/plugmatic/plugins"
     :detail "Live plugmatic metadata reports Mech package version 0.1.32-dev.1 from the Ward wiki-plugin-mech repository."
     :value "0.1.32-dev.1")
    (make-mech-provenance-evidence
     :kind :served-assets
     :source "/plugins/mech/blocks.js"
     :detail "Served blocks.js contains EXTRACT, EDGES, questions, claims, renderEdgesHtml, and parse_walk_command, which are absent from upstream 47c."
     :value (patched-mech-block-vocabulary-tokens))
    (make-mech-provenance-evidence
     :kind :page-content
     :source "/discourse-graphs.json"
     :detail "Live discourse-graphs page contains a mech story item using EXTRACT, EDGES, WALK 60 questions, and WALK 30 claims."
     :value "CLICK / EXTRACT / EDGES / WALK 60 questions / WALK 30 claims")
    (make-mech-provenance-evidence
     :kind :comparison
     :source "Local wiki-plugin-mech history"
     :detail "Served hashes match older patched commits in local history, proving patched lineage without pinning one exact commit."
     :value "patched-lineage"))))

(defun make-discourse-dreyeck-live-mech-host-report ()
  (make-mech-host-runtime-provenance-report
   :host "discourse.dreyeck.ch"
   :plugin-endpoints
   '("https://discourse.dreyeck.ch/system/plugins.json"
     "https://discourse.dreyeck.ch/plugin/plugmatic/plugins"
     "https://discourse.dreyeck.ch/plugins/mech/mech.js"
     "https://discourse.dreyeck.ch/plugins/mech/blocks.js"
     "https://discourse.dreyeck.ch/plugins/mech/interpreter.js"
     "https://discourse.dreyeck.ch/plugins/mech/library.js")
   :content-endpoints
   '("https://discourse.dreyeck.ch/discourse-graphs.json")
   :plugin-version "0.1.32-dev.1"
   :repository-url "https://github.com/wardcunningham/wiki-plugin-mech.git"
   :asset-digests
   '(("mech.js"
      . "5a2005522b6bb8d7ae0c4c30e2c8b6b049044315728a0c49846b0a417a5da1b7")
     ("blocks.js"
      . "1b69037fda8c89a0c06f333e3b8a3bb11925b1371daf8c1dfda32835d757652b")
     ("interpreter.js"
      . "f0a0b360496ee520072421e1b4cc9584b6e46b47df455fcd5c8406e9baa5e90f")
     ("library.js"
      . "bf1e1a2f3438d7cba322c90d4410ba4be353552256459ad32bc338050bb5e319"))
   :build-commit "abd88d2da6c89029515f2a456356832dffe038ab"
   :served-vocabulary
   (patched-mech-block-vocabulary-tokens)
   :notes
   "Live host serves patched Mech with exact deployed provenance proven by the embedded build stamp and matching local-history hashes."
   :evidence
   (list
    (make-mech-provenance-evidence
     :kind :plugin-metadata
     :source "/plugin/plugmatic/plugins"
     :detail "Live plugmatic metadata reports Mech package version 0.1.32-dev.1 from the Ward wiki-plugin-mech repository."
     :value "0.1.32-dev.1")
    (make-mech-provenance-evidence
     :kind :build-stamp
     :source "/plugins/mech/mech.js"
     :detail "Served mech.js embeds a build stamp naming MECH_GIT_COMMIT abd88d2da6c89029515f2a456356832dffe038ab."
     :value "abd88d2da6c89029515f2a456356832dffe038ab")
    (make-mech-provenance-evidence
     :kind :served-assets
     :source "/plugins/mech/blocks.js"
     :detail "Served blocks.js contains EXTRACT, EDGES, questions, claims, renderEdgesHtml, and parse_walk_command, which are absent from upstream 47c."
     :value (patched-mech-block-vocabulary-tokens))
    (make-mech-provenance-evidence
     :kind :comparison
     :source "Local wiki-plugin-mech history"
     :detail "Served blocks.js, interpreter.js, and library.js hashes match local commit abd88d2da6c89029515f2a456356832dffe038ab."
     :value "abd88d2da6c89029515f2a456356832dffe038ab"))))

(defun mech-plugin-provenance-check-host-classifications (operation)
  (mapcar (lambda (report)
            (cons (mech-host-runtime-provenance-host-of report)
                  (mech-host-runtime-provenance-classification-of report)))
          (live-mech-plugin-provenance-check-reports-of operation)))

(defun make-live-mech-plugin-provenance-check ()
  (make-instance
   'live-mech-plugin-provenance-check
   :id "operation/live-mech-plugin-provenance-check"
   :title "Live Mech plugin provenance check"
   :summary
   "Read-only operational object for proving host-by-host Mech deployment provenance from served plugin metadata, served assets, hashes, and live page content."
   :read-only-p t
   :upstream-reference-commit *upstream-mech-reference-commit*
   :upstream-reference-version *upstream-mech-reference-version*
   :patched-lineage-version *patched-mech-discourse-graphs-version*
   :evidence-sources
   '("/system/plugins.json"
     "/plugin/plugmatic/plugins"
     "/plugins/mech/mech.js"
     "/plugins/mech/blocks.js"
     "/plugins/mech/interpreter.js"
     "/plugins/mech/library.js"
     "/discourse-graphs.json"
     "Local wiki-plugin-mech commit history"
     "Local mech.patch candidate")
   :reports
   (list (make-wiki-ralfbarkow-live-mech-host-report)
         (make-discourse-dreyeck-live-mech-host-report))
   :conclusion
   "Both live hosts serve patched Mech rather than upstream 47c; discourse.dreyeck.ch proves exact deployed provenance to abd88d2da6c89029515f2a456356832dffe038ab, while wiki.ralfbarkow.ch remains on clearly patched lineage with unresolved exact commit provenance."))

(defun live-mech-plugin-provenance-check-summary-alist (operation)
  (list
   (cons :id (id-of operation))
   (cons :title (title-of operation))
   (cons :summary (summary-of operation))
   (cons :read-only-p
         (live-mech-plugin-provenance-check-read-only-p-of operation))
   (cons :upstream-reference-commit
         (live-mech-plugin-provenance-check-upstream-reference-commit-of
          operation))
   (cons :upstream-reference-version
         (live-mech-plugin-provenance-check-upstream-reference-version-of
          operation))
   (cons :patched-lineage-version
         (live-mech-plugin-provenance-check-patched-lineage-version-of
          operation))
   (cons :evidence-sources
         (live-mech-plugin-provenance-check-evidence-sources-of operation))
   (cons :host-classifications
         (mech-plugin-provenance-check-host-classifications operation))
   (cons :reports
         (mapcar #'mech-host-runtime-provenance-report-summary-alist
                 (live-mech-plugin-provenance-check-reports-of operation)))
   (cons :conclusion
         (live-mech-plugin-provenance-check-conclusion-of operation))))

(defun make-live-mech-deployment-provenance-skill ()
  (make-instance
   'live-plugin-provenance-skill
   :id "skill/live-mech-deployment-provenance"
   :title "Host-by-host deployed plugin provenance proof"
   :purpose
   "Evidence-first skill for proving what a live host actually serves for Mech, rather than inferring activation from nearby repos, patches, or page lore."
   :inputs
   '("Host list"
     "Plugin discovery endpoints"
     "Served Mech asset URLs"
     "Upstream reference commit"
     "Known patched candidate or lineage")
   :evidence-sources
   '("Served /system/plugins.json"
     "Served /plugin/plugmatic/plugins"
     "Served /plugins/mech/* assets"
     "Served discourse-graphs page content"
     "Checksums or byte comparison against local history"
     "Embedded build stamps when present")
   :steps
   '("Identify plugin endpoints for each host."
     "Fetch plugin metadata and served Mech assets."
     "Extract build stamps, package version, hashes, and downstream vocabulary."
     "Compare served bytes against upstream 47c and any known patched lineage."
     "Classify each host as upstream, patched, proxied, or unresolved."
     "Emit a host-by-host report that records evidence and unresolved boundaries explicitly.")
   :host-comparison-method
   "Keep each host as its own evidence bundle first, then compare classifications, asset hashes, build stamps, and live page content without collapsing the hosts into one blended runtime story."
   :acceptance-criteria
   "The result names the exact served endpoints, the host-by-host classification, and the concrete evidence basis for each conclusion, with unresolved boundaries stated explicitly."
   :classification-outcomes
   '(:upstream :patched :proxied :unresolved)
   :operation-factory 'make-live-mech-plugin-provenance-check
   :canonical-page "FedWiki Graphviz story item render trace"))

(defun live-plugin-provenance-skill-summary-alist (skill)
  (list
   (cons :id (id-of skill))
   (cons :title (title-of skill))
   (cons :purpose (live-plugin-provenance-skill-purpose-of skill))
   (cons :inputs (live-plugin-provenance-skill-inputs-of skill))
   (cons :evidence-sources
         (live-plugin-provenance-skill-evidence-sources-of skill))
   (cons :steps (live-plugin-provenance-skill-steps-of skill))
   (cons :host-comparison-method
         (live-plugin-provenance-skill-host-comparison-method-of skill))
   (cons :acceptance-criteria
         (live-plugin-provenance-skill-acceptance-criteria-of skill))
   (cons :classification-outcomes
         (live-plugin-provenance-skill-classification-outcomes-of skill))
   (cons :operation-factory
         (live-plugin-provenance-skill-operation-factory-of skill))
   (cons :canonical-page
         (live-plugin-provenance-skill-canonical-page-of skill))))
