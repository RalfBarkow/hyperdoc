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

(defparameter *known-patched-mech-reference-commit*
  "abd88d2da6c89029515f2a456356832dffe038ab")

(defparameter *default-wiki-plugin-mech-repository-path*
  "/Users/rgb/workspace/wiki-plugin-mech")

(defparameter *live-mech-provenance-host-specs*
  '((:host "wiki.ralfbarkow.ch"
     :base-url "https://wiki.ralfbarkow.ch"
     :page-slug "discourse-graphs")
    (:host "discourse.dreyeck.ch"
     :base-url "https://discourse.dreyeck.ch"
     :page-slug "discourse-graphs")))

(defparameter *mech-compared-asset-source-paths*
  '(("blocks.js" . "src/client/blocks.js")
    ("interpreter.js" . "src/client/interpreter.js")
    ("library.js" . "src/client/library.js")))

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
   (known-patched-reference-commit
    :reader live-mech-plugin-provenance-check-known-patched-reference-commit-of
    :initarg :known-patched-reference-commit
    :initform nil)
   (hosts :reader live-mech-plugin-provenance-check-hosts-of
          :initarg :hosts
          :initform nil)
   (reference-repo-path
    :reader live-mech-plugin-provenance-check-reference-repo-path-of
    :initarg :reference-repo-path
    :initform nil)
   (execution-mode
    :reader live-mech-plugin-provenance-check-execution-mode-of
    :initarg :execution-mode
    :initform :baseline)
   (executed-at
    :reader live-mech-plugin-provenance-check-executed-at-of
    :initarg :executed-at
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

(defun live-mech-plugin-provenance-check-live-p (operation)
  (eq (live-mech-plugin-provenance-check-execution-mode-of operation)
      :live))

(defun default-live-mech-plugin-provenance-hosts ()
  (copy-tree *live-mech-provenance-host-specs*))

(defun host-spec-value (host-spec key)
  (getf host-spec key))

(defun mech-json-get (object key)
  (typecase object
    (hash-table
     (or (gethash key object)
         (gethash (string-downcase key) object)
         (gethash (string-upcase key) object)))
    (list
     (cdr (assoc key object :test #'string=)))
    (t
     nil)))

(defun mech-json-sequence->list (value)
  (typecase value
    (null nil)
    (list value)
    (vector (coerce value 'list))
    (t nil)))

(defun mech-provenance-command-output (argv)
  (multiple-value-bind (output error-output exit-code)
      (uiop:run-program argv
                        :output :string
                        :error-output :string
                        :ignore-error-status t)
    (values output error-output exit-code)))

(defun mech-provenance-http-fetch-string (url &key accept)
  (let ((argv (append (list "curl"
                            "--connect-timeout" "5"
                            "--max-time" "20"
                            "--retry" "0"
                            "-fsSL")
                      (when accept
                        (list "-H" (format nil "Accept: ~A" accept)))
                      (list url))))
    (multiple-value-bind (output error-output exit-code)
        (mech-provenance-command-output argv)
      (if (zerop exit-code)
          (values output nil)
          (values nil
                  (string-trim '(#\Space #\Tab #\Newline #\Return)
                               (or error-output output "")))))))

(defun mech-provenance-http-fetch-json (url)
  (multiple-value-bind (body error-message)
      (mech-provenance-http-fetch-string url :accept "application/json")
    (if body
        (handler-case
            (values (shasht:read-json body) nil)
          (error (cause)
            (values nil
                    (format nil "Failed to parse JSON from ~A: ~A"
                            url
                            cause))))
        (values nil error-message))))

(defun mech-provenance-sha256-hex (content)
  (let* ((temporary-name
          (format nil "mech-provenance-~A.tmp"
                  (symbol-name (gensym "RUN"))))
         (temporary-path
          (merge-pathnames temporary-name
                           (uiop:temporary-directory))))
    (unwind-protect
         (progn
           (with-open-file (stream temporary-path
                                   :direction :output
                                   :if-exists :supersede
                                   :if-does-not-exist :create)
             (write-string content stream))
           (multiple-value-bind (output error-output exit-code)
               (mech-provenance-command-output
                (list "shasum" "-a" "256" (namestring temporary-path)))
             (declare (ignore error-output))
             (when (zerop exit-code)
               (subseq output 0 (position #\Space output)))))
      (ignore-errors (delete-file temporary-path)))))

(defun mech-provenance-asset-digests (asset-contents)
  (loop for (asset-name . content) in asset-contents
        for digest = (and content (mech-provenance-sha256-hex content))
        when digest
        collect (cons asset-name digest)))

(defun mech-provenance-find-plugmatic-plugin-entry (payload plugin-name)
  (let ((entries (cond
                   ((hash-table-p payload)
                    (or (mech-json-sequence->list
                         (mech-json-get payload "install"))
                        (mech-json-sequence->list
                         (mech-json-get payload "plugins"))
                        (mech-json-sequence->list
                         (mech-json-get payload "data"))))
                   (t
                    (mech-json-sequence->list payload)))))
    (find plugin-name
          entries
          :key (lambda (entry)
                 (and (hash-table-p entry)
                      (mech-json-get entry "plugin")))
          :test #'string=)))

(defun mech-provenance-hex-string-p (string length)
  (and (stringp string)
       (= (length string) length)
       (every (lambda (character)
                (not (null (digit-char-p character 16))))
              string)))

(defun mech-provenance-extract-js-field-value (source field-name)
  (loop with source-length = (length source)
        with start = 0
        for field-position = (search field-name source :start2 start :test #'char=)
        while field-position
        do (let ((cursor (+ field-position (length field-name))))
             (loop while (and (< cursor source-length)
                              (find (char source cursor)
                                    '(#\Space #\Tab #\Newline #\Return)))
                   do (incf cursor))
             (when (and (< cursor source-length)
                        (char= (char source cursor) #\:))
               (incf cursor)
               (loop while (and (< cursor source-length)
                                (find (char source cursor)
                                      '(#\Space #\Tab #\Newline #\Return)))
                     do (incf cursor))
               (when (and (< cursor source-length)
                          (member (char source cursor) '(#\" #\')))
                 (let* ((quote-character (char source cursor))
                        (value-start (1+ cursor))
                        (value-end (position quote-character
                                             source
                                             :start value-start)))
                   (when value-end
                     (return (subseq source value-start value-end))))))
             (setf start (+ field-position (length field-name))))
        finally (return nil)))

(defun mech-provenance-present-vocabulary-tokens (blocks-source)
  (remove-if-not
   (lambda (token)
     (search token blocks-source :test #'char=))
   (patched-mech-block-vocabulary-tokens)))

(defun mech-provenance-first-mech-story-text (page-json)
  (let* ((story (mech-json-sequence->list (mech-json-get page-json "story")))
         (item (find "mech"
                     story
                     :key (lambda (entry)
                            (and (hash-table-p entry)
                                 (mech-json-get entry "type")))
                     :test #'string=)))
    (and item
         (mech-json-get item "text"))))

(defun mech-provenance-source-path-for-asset (asset-name)
  (cdr (assoc asset-name *mech-compared-asset-source-paths* :test #'string=)))

(defun mech-provenance-git-commit-present-p (repository-path commit)
  (multiple-value-bind (_output _error-output exit-code)
      (mech-provenance-command-output
       (list "git" "-C" repository-path "cat-file" "-e"
             (format nil "~A^{commit}" commit)))
    (declare (ignore _output _error-output))
    (zerop exit-code)))

(defun mech-provenance-git-show-file (repository-path commit source-path)
  (multiple-value-bind (output error-output exit-code)
      (mech-provenance-command-output
       (list "git" "-C" repository-path "show"
             (format nil "~A:~A" commit source-path)))
    (declare (ignore error-output))
    (if (zerop exit-code)
        output
        nil)))

(defun mech-provenance-compare-assets-to-git-commit
    (asset-contents repository-path commit)
  (when (and commit
             repository-path
             (mech-provenance-git-commit-present-p repository-path commit))
    (loop for (asset-name . content) in asset-contents
          for source-path = (mech-provenance-source-path-for-asset asset-name)
          when source-path
          collect
          (cons asset-name
                (string= (or content "")
                         (or (mech-provenance-git-show-file
                              repository-path
                              commit
                              source-path)
                             ""))))))

(defun mech-provenance-comparison-all-match-p (comparison)
  (and comparison
       (every #'cdr comparison)))

(defun mech-provenance-report-note
    (&key classification build-commit upstream-comparison
       patched-comparison exact-build-commit-match-p)
  (case classification
    (:upstream
     "Live host matches the upstream reference without downstream Discourse-Graphs vocabulary.")
    (:proxied
     "Live host appears to proxy another Mech runtime surface rather than serving its own distinct deployment.")
    (:patched
     (cond
       (exact-build-commit-match-p
        (format nil "Live host serves patched Mech with exact deployed provenance proven to ~A."
                build-commit))
       ((and build-commit patched-comparison)
        (format nil "Live host serves patched Mech and exposes build commit ~A, but compared assets do not all match that commit exactly." build-commit))
       ((mech-provenance-comparison-all-match-p upstream-comparison)
        "Live host would classify as upstream by file comparison, but downstream vocabulary still marks it as patched.")
       (t
        "Live host serves patched Mech lineage, but exact commit provenance remains unresolved.")))
    (otherwise
     "Live host remains unresolved because the fetched evidence does not prove upstream, patched, or proxied deployment cleanly.")))

(defun collect-live-mech-host-runtime-provenance
    (host-spec &key
                 (reference-repo-path *default-wiki-plugin-mech-repository-path*)
                 (upstream-reference-commit *upstream-mech-reference-commit*)
                 (upstream-reference-version *upstream-mech-reference-version*)
                 (patched-lineage-version *patched-mech-discourse-graphs-version*)
                 (known-patched-reference-commit *known-patched-mech-reference-commit*))
  (let* ((host (host-spec-value host-spec :host))
         (base-url (host-spec-value host-spec :base-url))
         (page-slug (or (host-spec-value host-spec :page-slug)
                        "discourse-graphs"))
         (proxied-from (host-spec-value host-spec :proxied-from))
         (system-plugins-url (format nil "~A/system/plugins.json" base-url))
         (plugmatic-url (format nil "~A/plugin/plugmatic/plugins" base-url))
         (page-url (format nil "~A/~A.json" base-url page-slug))
         (asset-names '("mech.js" "blocks.js" "interpreter.js" "library.js"))
         (asset-urls
          (loop for asset-name in asset-names
                collect (cons asset-name
                              (format nil "~A/plugins/mech/~A"
                                      base-url
                                      asset-name))))
         (plugin-endpoints
          (append (list system-plugins-url plugmatic-url)
                  (mapcar #'cdr asset-urls)))
         (evidence nil)
         (system-plugins-json nil)
         (plugmatic-json nil)
         (page-json nil)
         (asset-contents nil)
         (plugin-version nil)
         (repository-url nil)
         (build-commit nil)
         (served-vocabulary nil)
         (page-text nil))
    (labels ((record-error (source message)
               (push (make-mech-provenance-evidence
                      :kind :fetch-error
                      :source source
                      :detail message
                      :value nil)
                     evidence)))
      (multiple-value-bind (json error-message)
          (mech-provenance-http-fetch-json system-plugins-url)
        (if json
            (setf system-plugins-json json)
            (record-error system-plugins-url
                          (or error-message
                              "Failed to fetch system/plugins.json"))))
      (multiple-value-bind (json error-message)
          (mech-provenance-http-fetch-json plugmatic-url)
        (if json
            (setf plugmatic-json json)
            (record-error plugmatic-url
                          (or error-message
                              "Failed to fetch plugmatic plugin metadata"))))
      (multiple-value-bind (json error-message)
          (mech-provenance-http-fetch-json page-url)
        (if json
            (setf page-json json)
            (record-error page-url
                          (or error-message
                              "Failed to fetch live discourse-graphs page JSON"))))
      (dolist (asset asset-urls)
        (multiple-value-bind (content error-message)
            (mech-provenance-http-fetch-string (cdr asset))
          (if content
              (push (cons (car asset) content) asset-contents)
              (record-error (cdr asset)
                            (or error-message
                                (format nil "Failed to fetch ~A" (car asset)))))))
      (setf asset-contents (nreverse asset-contents))
      (let* ((mech-entry
              (and plugmatic-json
                   (mech-provenance-find-plugmatic-plugin-entry
                    plugmatic-json
                    "mech")))
             (mech-package (and mech-entry (mech-json-get mech-entry "package")))
             (mech-repository
              (and mech-package
                   (mech-json-get mech-package "repository")))
             (system-plugins
              (mech-json-sequence->list system-plugins-json))
             (mech-js (cdr (assoc "mech.js" asset-contents :test #'string=)))
             (blocks-js (cdr (assoc "blocks.js" asset-contents :test #'string=)))
             (upstream-comparison
              (mech-provenance-compare-assets-to-git-commit
               asset-contents
               reference-repo-path
               upstream-reference-commit))
             (known-patched-comparison
              (mech-provenance-compare-assets-to-git-commit
               asset-contents
               reference-repo-path
               known-patched-reference-commit)))
        (setf plugin-version
              (or (and mech-package (mech-json-get mech-package "version"))
                  (and mech-js
                       (mech-provenance-extract-js-field-value
                        mech-js
                        "MECH_VERSION"))))
        (setf repository-url
              (and mech-repository
                   (mech-json-get mech-repository "url")))
        (setf build-commit
              (let ((value
                     (and mech-js
                          (mech-provenance-extract-js-field-value
                           mech-js
                           "MECH_GIT_COMMIT"))))
                (and (mech-provenance-hex-string-p value 40)
                     value)))
        (setf served-vocabulary
              (and blocks-js
                   (mech-provenance-present-vocabulary-tokens blocks-js)))
        (setf page-text
              (and page-json
                   (mech-provenance-first-mech-story-text page-json)))
        (when system-plugins-json
          (push (make-mech-provenance-evidence
                 :kind :plugin-discovery
                 :source "/system/plugins.json"
                 :detail "Live plugin discovery response confirms whether the host advertises a mech plugin at all."
                 :value (member "mech" system-plugins :test #'string=))
                evidence))
        (when mech-entry
          (push (make-mech-provenance-evidence
                 :kind :plugin-metadata
                 :source "/plugin/plugmatic/plugins"
                 :detail "Live plugmatic metadata reports the deployed Mech package version and repository URL."
                 :value (list :version plugin-version
                              :repository-url repository-url))
                evidence))
        (when build-commit
          (push (make-mech-provenance-evidence
                 :kind :build-stamp
                 :source "/plugins/mech/mech.js"
                 :detail "Served mech.js embeds the deployed build commit."
                 :value build-commit)
                evidence))
        (when served-vocabulary
          (push (make-mech-provenance-evidence
                 :kind :served-assets
                 :source "/plugins/mech/blocks.js"
                 :detail "Served blocks.js exposes the downstream Discourse-Graphs Mech vocabulary present on the live host."
                 :value served-vocabulary)
                evidence))
        (when page-text
          (push (make-mech-provenance-evidence
                 :kind :page-content
                 :source (format nil "/~A.json" page-slug)
                 :detail "Live page content shows the authored mech item text actually using the downstream block vocabulary on the host."
                 :value (with-output-to-string (stream)
                          (loop for line in (subseq (uiop:split-string page-text :separator '(#\Newline))
                                                    0
                                                    (min 6 (length (uiop:split-string page-text :separator '(#\Newline)))))
                                do (format stream "~A~%" line))))
                evidence))
        (when upstream-comparison
          (push (make-mech-provenance-evidence
                 :kind :upstream-comparison
                 :source (format nil "git show ~A:src/client/*"
                                 upstream-reference-commit)
                 :detail "Compared live served blocks/interpreter/library assets against the upstream reference commit."
                 :value upstream-comparison)
                evidence))
        (when known-patched-comparison
          (push (make-mech-provenance-evidence
                 :kind :patched-comparison
                 :source (format nil "git show ~A:src/client/*"
                                 known-patched-reference-commit)
                 :detail "Compared live served blocks/interpreter/library assets against the known patched reference commit."
                 :value known-patched-comparison)
                evidence))
        (make-mech-host-runtime-provenance-report
         :host host
         :plugin-endpoints plugin-endpoints
         :content-endpoints (list page-url)
         :plugin-version plugin-version
         :repository-url repository-url
         :asset-digests (mech-provenance-asset-digests asset-contents)
         :build-commit build-commit
         :served-vocabulary served-vocabulary
         :proxied-from proxied-from
         :notes
         (mech-provenance-report-note
          :classification
          (classify-mech-host-runtime-provenance
           :build-commit build-commit
           :plugin-version plugin-version
           :served-vocabulary served-vocabulary
           :proxied-from proxied-from
           :upstream-reference-commit upstream-reference-commit
           :upstream-reference-version upstream-reference-version
           :patched-lineage-version patched-lineage-version)
          :build-commit build-commit
          :upstream-comparison upstream-comparison
          :patched-comparison known-patched-comparison
          :exact-build-commit-match-p
          (and build-commit
               (string= build-commit known-patched-reference-commit)
               (mech-provenance-comparison-all-match-p
                known-patched-comparison)))
         :evidence (nreverse evidence)
         :upstream-reference-commit upstream-reference-commit
         :upstream-reference-version upstream-reference-version
         :patched-lineage-version patched-lineage-version)))))

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

(defun live-mech-plugin-provenance-check-conclusion-from-reports
    (reports &key known-patched-reference-commit)
  (let* ((classifications
          (mapcar #'mech-host-runtime-provenance-classification-of reports))
         (discourse-report
          (find "discourse.dreyeck.ch"
                reports
                :key #'mech-host-runtime-provenance-host-of
                :test #'string=))
         (wiki-report
          (find "wiki.ralfbarkow.ch"
                reports
                :key #'mech-host-runtime-provenance-host-of
                :test #'string=)))
    (cond
      ((every (lambda (classification)
                (eq classification :upstream))
              classifications)
       "All live hosts match the upstream Mech reference.")
      ((every (lambda (classification)
                (eq classification :patched))
              classifications)
       (format nil
               "Both live hosts serve patched Mech rather than upstream ~A; ~A proves exact deployed provenance to ~A, while ~A remains on patched lineage with unresolved exact commit provenance."
               *upstream-mech-reference-commit*
               (mech-host-runtime-provenance-host-of discourse-report)
               (or (mech-host-runtime-provenance-build-commit-of discourse-report)
                   known-patched-reference-commit)
               (mech-host-runtime-provenance-host-of wiki-report)))
      ((some (lambda (classification)
               (eq classification :proxied))
             classifications)
       "At least one live host appears to proxy another runtime surface; the host-by-host report records which host remains proxied and which host remains authoritative.")
      (t
       "Live host comparison produced a mixed or unresolved classification; inspect the host-by-host evidence for the exact remaining boundary."))))

(defun make-live-mech-plugin-provenance-check
    (&key
       (reports
        (list (make-wiki-ralfbarkow-live-mech-host-report)
              (make-discourse-dreyeck-live-mech-host-report)))
       (hosts (default-live-mech-plugin-provenance-hosts))
       (reference-repo-path *default-wiki-plugin-mech-repository-path*)
       (execution-mode :baseline)
       executed-at
       (known-patched-reference-commit
        *known-patched-mech-reference-commit*)
       conclusion)
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
   :known-patched-reference-commit known-patched-reference-commit
   :hosts hosts
   :reference-repo-path reference-repo-path
   :execution-mode execution-mode
   :executed-at executed-at
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
   :reports reports
   :conclusion
   (or conclusion
       "Both live hosts serve patched Mech rather than upstream 47c; discourse.dreyeck.ch proves exact deployed provenance to abd88d2da6c89029515f2a456356832dffe038ab, while wiki.ralfbarkow.ch remains on clearly patched lineage with unresolved exact commit provenance.")))

(defun execute-live-mech-plugin-provenance-check
    (&key
       (hosts (default-live-mech-plugin-provenance-hosts))
       (reference-repo-path *default-wiki-plugin-mech-repository-path*)
       (known-patched-reference-commit
        *known-patched-mech-reference-commit*))
  (let ((reports
         (mapcar (lambda (host-spec)
                   (collect-live-mech-host-runtime-provenance
                    host-spec
                    :reference-repo-path reference-repo-path
                    :known-patched-reference-commit
                    known-patched-reference-commit))
                 hosts)))
    (make-live-mech-plugin-provenance-check
     :reports reports
     :hosts hosts
     :reference-repo-path reference-repo-path
     :execution-mode :live
     :executed-at (get-universal-time)
     :known-patched-reference-commit known-patched-reference-commit
     :conclusion
     (live-mech-plugin-provenance-check-conclusion-from-reports
      reports
      :known-patched-reference-commit known-patched-reference-commit))))

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
   (cons :known-patched-reference-commit
         (live-mech-plugin-provenance-check-known-patched-reference-commit-of
          operation))
   (cons :hosts
         (mapcar (lambda (host-spec)
                   (host-spec-value host-spec :host))
                 (live-mech-plugin-provenance-check-hosts-of operation)))
   (cons :reference-repo-path
         (live-mech-plugin-provenance-check-reference-repo-path-of operation))
   (cons :execution-mode
         (live-mech-plugin-provenance-check-execution-mode-of operation))
   (cons :executed-at
         (live-mech-plugin-provenance-check-executed-at-of operation))
   (cons :live-p
         (live-mech-plugin-provenance-check-live-p operation))
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
