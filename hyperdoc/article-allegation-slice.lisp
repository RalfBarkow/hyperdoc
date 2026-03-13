;;;; Article allegation slice scaffolding helper
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defparameter +article-allegation-default-section-headings+
  '(:claimed-sequence "Claimed sequence of events"
    :reported-attribution "Reported attribution"
    :forensic-claims "Investigative or forensic claims"
    :accountability "Accountability questions"
    :ai-boundary "Human/AI decision boundary"
    :uncertainties "Open uncertainties"
    :related "Related concepts"))

(defparameter +article-allegation-supported-kinds+
  '(:concept
    :failure-mode
    :process-failure
    :accountability-model
    :review-doctrine
    :attribution-method
    :human-ai-boundary))

(defparameter +article-allegation-section-order+
  '(:claimed-sequence
    :reported-attribution
    :forensic-claims
    :accountability
    :uncertainties
    :related))

(defparameter +article-allegation-section-order-with-ai+
  '(:claimed-sequence
    :reported-attribution
    :forensic-claims
    :accountability
    :ai-boundary
    :uncertainties
    :related))

(defun article-allegation-source-root ()
  (asdf:system-source-directory :hyperdoc))

(defun article-allegation-default-hyperdoc-pages-directory ()
  (merge-pathnames "hyperdoc/" (article-allegation-source-root)))

(defun article-allegation-default-fedwiki-repo-root ()
  (uiop:ensure-directory-pathname "/Users/rgb/.wiki/wiki.ralfbarkow.ch/"))

(defun article-allegation-default-fedwiki-pages-directory ()
  (merge-pathnames "pages/" (article-allegation-default-fedwiki-repo-root)))

(defun article-allegation-trimmed-string (value)
  (etypecase value
    (string (string-trim '(#\Space #\Tab #\Newline #\Return) value))
    (pathname (article-allegation-trimmed-string (namestring value)))))

(defun article-allegation-non-empty-string (value)
  (let ((trimmed (article-allegation-trimmed-string value)))
    (unless (plusp (length trimmed))
      (error "Expected non-empty string, got ~S" value))
    trimmed))

(defun article-allegation-required (plist key)
  (or (getf plist key)
      (error "Missing required key ~S in article allegation slice input" key)))

(defun article-allegation-plist-p (value)
  (and (listp value)
       (evenp (length value))
       (loop for key in value by #'cddr
             always (keywordp key))))

(defun article-allegation-copy-strings (values)
  (loop for value in (or values '())
        collect (article-allegation-non-empty-string value)))

(defun article-allegation-symbol-or-string (value)
  (etypecase value
    (symbol (string-downcase (symbol-name value)))
    (string (article-allegation-trimmed-string value))))

(defun article-allegation-ensure-unique (values label)
  (let ((seen (make-hash-table :test #'equal)))
    (dolist (value values)
      (when (gethash value seen)
        (error "Duplicate ~A ~S in article allegation slice input" label value))
      (setf (gethash value seen) t)))
  values)

(defun article-allegation-normalize-status (status)
  (let ((name (string-downcase
               (etypecase status
                 (keyword (symbol-name status))
                 (string status)))))
    (cond
      ((string= name "reported")
       :reported)
      ((string= name "alleged")
       :alleged)
      ((string= name "disputed")
       :disputed)
      ((or (string= name "preliminarily-reconstructed")
           (string= name "preliminarily reconstructed"))
       :preliminarily-reconstructed)
      ((or (string= name "independently-verified")
           (string= name "independently verified"))
       :independently-verified)
      (t
       (error "Unsupported attribution status ~S" status)))))

(defun article-allegation-normalize-kind (kind)
  (let ((name (string-downcase
               (etypecase kind
                 (keyword (symbol-name kind))
                 (string kind)))))
    (cond
      ((or (string= name "concept")
           (string= name "generic"))
       :concept)
      ((or (string= name "failure-mode")
           (string= name "failure mode"))
       :failure-mode)
      ((or (string= name "process-failure")
           (string= name "process failure"))
       :process-failure)
      ((or (string= name "accountability")
           (string= name "accountability-model")
           (string= name "accountability model"))
       :accountability-model)
      ((or (string= name "review-doctrine")
           (string= name "review doctrine"))
       :review-doctrine)
      ((or (string= name "attribution-method")
           (string= name "attribution method"))
       :attribution-method)
      ((or (string= name "human-ai-boundary")
           (string= name "human ai boundary"))
       :human-ai-boundary)
      (t
       (error "Unsupported concept kind ~S" kind)))))

(defun article-allegation-normalize-mode (mode)
  (let ((name (article-allegation-symbol-or-string mode)))
    (unless (string= name "article-allegation")
      (error "Unsupported article allegation slice mode ~S" mode))
    :article-allegation))

(defun article-allegation-normalize-source-type (source-type)
  (intern (string-upcase (article-allegation-symbol-or-string source-type))
          :keyword))

(defun article-allegation-normalize-slice-id (slice-id incident-title)
  (article-allegation-slugify
   (or (and slice-id (article-allegation-symbol-or-string slice-id))
       incident-title)))

(defun article-allegation-string-suffix-p (suffix string)
  (let ((suffix-length (length suffix))
        (string-length (length string)))
    (and (<= suffix-length string-length)
         (string= suffix string :start1 0 :start2 (- string-length suffix-length)))))

(defun article-allegation-topic-handle-name (topic-handle)
  (let ((name (article-allegation-symbol-or-string topic-handle)))
    (unless (article-allegation-string-suffix-p "-topic" name)
      (error "Topic handle must end in -topic, got ~S" topic-handle))
    name))

(defun article-allegation-topic-id-from-handle (topic-handle-name)
  (subseq topic-handle-name
          0
          (- (length topic-handle-name)
             (length "-topic"))))

(defun article-allegation-normalize-section-headings (sections)
  (let ((headings (article-allegation-copy-strings sections)))
    (cond
      ((null headings)
       '())
      ((= (length headings) (length +article-allegation-section-order+))
       (loop for key in +article-allegation-section-order+
             for heading in headings
             append (list key heading)))
      ((= (length headings) (length +article-allegation-section-order-with-ai+))
       (loop for key in +article-allegation-section-order-with-ai+
             for heading in headings
             append (list key heading)))
      (t
       (error "Incident section list must contain 6 or 7 headings, got ~D"
              (length headings))))))

(defun article-allegation-verified-p (status)
  (eq status :independently-verified))

(defun article-allegation-headings (input)
  (let ((headings (getf input :suggested-section-headings)))
    (if (article-allegation-plist-p headings)
        headings
        '())))

(defun article-allegation-section-heading (input key)
  (or (getf (article-allegation-headings input) key)
      (getf +article-allegation-default-section-headings+ key)))

(defun article-allegation-html-escape (text)
  (with-output-to-string (stream)
    (loop for char across (article-allegation-trimmed-string text)
          do (case char
               (#\& (write-string "&amp;" stream))
               (#\< (write-string "&lt;" stream))
               (#\> (write-string "&gt;" stream))
               (#\" (write-string "&quot;" stream))
               (t (write-char char stream))))))

(defun article-allegation-slugify (text)
  (let ((downcased (string-downcase (article-allegation-trimmed-string text))))
    (with-output-to-string (stream)
      (loop with pending-hyphen = nil
            for char across downcased
            do (cond
                 ((or (alpha-char-p char) (digit-char-p char))
                  (when pending-hyphen
                    (write-char #\- stream)
                    (setf pending-hyphen nil))
                  (write-char char stream))
                 (t
                  (setf pending-hyphen t)))))))

(defun article-allegation-page-filename (title)
  (format nil "~A.html" title))

(defun article-allegation-topic-function-name (topic-id)
  (format nil "~A-topic" (article-allegation-non-empty-string topic-id)))

(defun article-allegation-topic-link (title &optional (label title))
  (format nil "<a hyperbook=\"topics\" page=\"~A\"><tt>~A</tt></a>"
          (article-allegation-html-escape title)
          (article-allegation-html-escape label)))

(defun article-allegation-page-link (title &optional (label title))
  (format nil "<a page=\"~A\">~A</a>"
          (article-allegation-html-escape title)
          (article-allegation-html-escape label)))

(defun article-allegation-fedwiki-link (site slug &optional (label slug))
  (format nil "<a hyperbook=\"fedwiki:~A\" page=\"~A\">~A</a>"
          (article-allegation-html-escape site)
          (article-allegation-html-escape slug)
          (article-allegation-html-escape label)))

(defun article-allegation-fedwiki-reference (reference)
  (if (or (search "://" reference) (search "http://" reference))
      (format nil "[~A ~A]" reference reference)
      (format nil "[[~A]]" reference)))

(defun article-allegation-status-label (status)
  (case status
    (:reported "reported")
    (:alleged "alleged")
    (:disputed "disputed")
    (:preliminarily-reconstructed "preliminarily reconstructed")
    (:independently-verified "independently verified")
    (otherwise (string-downcase (symbol-name status)))))

(defun article-allegation-uncertainties (input)
  (or (copy-list (or (getf input :known-uncertainties) '()))
      (remove nil
              (list
               (unless (article-allegation-verified-p (getf input :attribution-status))
                 "Responsibility remains a reported or disputed claim unless stronger verification metadata is supplied.")
               (unless (getf input :verified-legal-attribution-p)
                 "This scaffold does not emit flat legal conclusions such as war-crime attribution by default.")
               (when (getf input :ai-involvement-p)
                 "AI references remain at the level of decision support, review acceleration, automation-bias risk, and human responsibility unless direct verified causation is supplied.")))
      (list
       "The incident remains allegation-qualified unless stronger source metadata is explicitly supplied.")))

(defun article-allegation-derived-concept-summary (title kind)
  (case kind
    (:failure-mode
     (format nil "~A is scaffolded here as a reusable failure mode for allegation-qualified incident documentation."
             title))
    (:process-failure
     (format nil "~A is scaffolded here as a reusable process-check concept for allegation-qualified incident documentation."
             title))
    (:accountability-model
     (format nil "~A is scaffolded here as a reusable accountability concept for allegation-qualified incident documentation."
             title))
    (:review-doctrine
     (format nil "~A is scaffolded here as a reusable review-doctrine concept for allegation-qualified incident documentation."
             title))
    (:attribution-method
     (format nil "~A is scaffolded here as a reusable attribution-method concept for allegation-qualified incident documentation."
             title))
    (:human-ai-boundary
     (format nil "~A is scaffolded here as a reusable human/AI decision-boundary concept for allegation-qualified incident documentation."
             title))
    (otherwise
     (format nil "~A is scaffolded here as a reusable concept for allegation-qualified incident documentation."
             title))))

(defun article-allegation-normalize-concept (concept)
  (unless (listp concept)
    (error "Concept spec must be a property list, got ~S" concept))
  (let* ((title (article-allegation-non-empty-string
                 (article-allegation-required concept :title)))
         (topic-handle (and (getf concept :topic-handle)
                            (article-allegation-topic-handle-name
                             (getf concept :topic-handle))))
         (topic-id (article-allegation-non-empty-string
                    (or (getf concept :topic-id)
                        (and topic-handle
                             (article-allegation-topic-id-from-handle topic-handle))
                        (error "Concept ~S must supply :topic-id or :topic-handle" title))))
         (kind (article-allegation-normalize-kind
                (or (getf concept :kind) :concept)))
         (summary (if (getf concept :summary)
                      (article-allegation-non-empty-string
                       (getf concept :summary))
                      (article-allegation-derived-concept-summary title kind))))
    (unless (member kind +article-allegation-supported-kinds+)
      (error "Unsupported concept kind ~S" kind))
    (list :title title
          :topic-id topic-id
          :summary summary
          :kind kind
          :topic-function-name (or topic-handle
                                   (article-allegation-topic-function-name topic-id))
          :fedwiki-slug (article-allegation-non-empty-string
                         (or (getf concept :fedwiki-slug)
                             (getf concept :slug)
                             topic-id))
          :references (article-allegation-copy-strings
                       (getf concept :references))
          :related-titles (article-allegation-copy-strings
                           (getf concept :related-titles)))))

(defun article-allegation-normalize-input (input &key source-path)
  (unless (listp input)
    (error "Article allegation slice input must be a property list, got ~S" input))
  (let* ((source (and (article-allegation-plist-p (getf input :source))
                      (getf input :source)))
         (incident (and (article-allegation-plist-p (getf input :incident))
                        (getf input :incident)))
         (output (and (article-allegation-plist-p (getf input :output))
                      (getf input :output)))
         (rules (and (article-allegation-plist-p (getf input :rules))
                     (getf input :rules)))
         (flags (and (article-allegation-plist-p (getf input :flags))
                     (getf input :flags)))
         (repo-branching (and (article-allegation-plist-p (getf input :repo-branching))
                              (getf input :repo-branching)))
         (incident-title (article-allegation-non-empty-string
                          (or (getf input :incident-page-title)
                              (getf incident :title)
                              (article-allegation-required input :incident-title))))
         (incident-summary (article-allegation-non-empty-string
                            (or (getf incident :summary)
                                (getf input :incident-summary)
                                (article-allegation-required input :summary))))
         (source-description (article-allegation-non-empty-string
                              (or (getf input :source-description)
                                  (getf source :label)
                                  (getf input :source-label)
                                  (error "Missing source description/label"))))
         (source-label (article-allegation-non-empty-string
                        (or (getf source :label)
                            (getf input :source-label)
                            source-description)))
         (mode (article-allegation-normalize-mode
                (or (getf input :mode) :article-allegation)))
         (slice-id (article-allegation-normalize-slice-id
                    (getf input :slice-id)
                    incident-title))
         (epistemic-status (article-allegation-normalize-status
                            (or (getf incident :epistemic-status)
                                (getf input :epistemic-status)
                                :alleged)))
         (concepts (mapcar #'article-allegation-normalize-concept
                           (copy-list (article-allegation-required input :concepts)))))
    (unless concepts
      (error "Article allegation slice input must include at least one reusable concept"))
    (article-allegation-ensure-unique
     (mapcar #'(lambda (concept) (getf concept :title)) concepts)
     "concept title")
    (article-allegation-ensure-unique
     (mapcar #'(lambda (concept) (getf concept :topic-id)) concepts)
     "topic id")
    (article-allegation-ensure-unique
     (mapcar #'(lambda (concept) (getf concept :topic-function-name)) concepts)
     "topic function name")
    (article-allegation-ensure-unique
     (mapcar #'(lambda (concept) (getf concept :fedwiki-slug)) concepts)
     "FedWiki slug")
    (list :source-path source-path
          :slice-id slice-id
          :mode mode
          :incident-title incident-title
          :incident-summary incident-summary
          :source-label source-label
          :source-description source-description
          :source-type (article-allegation-normalize-source-type
                        (or (getf source :type)
                            (getf input :source-type)
                            :news-article))
          :source-provenance (or (getf source :provenance)
                                 (getf input :source-provenance))
          :article-date (or (getf input :article-date)
                            (getf source :date))
          :incident-date (or (getf incident :date)
                             (getf input :incident-date))
          :incident-fedwiki-slug (or (getf input :incident-fedwiki-slug)
                                     (article-allegation-slugify incident-title))
          :epistemic-status epistemic-status
          :attribution-status (article-allegation-normalize-status
                               (or (getf input :attribution-status)
                                   (getf rules :default-claim-mode)
                                   epistemic-status))
          :legal-status-sensitive-p
          (if (or (getf input :legal-status-sensitive-p)
                  (getf flags :legal-conclusions-conditional)
                  (getf rules :forbid-flat-legal-conclusions))
              t
              nil)
          :verified-legal-attribution-p (if (getf input :verified-legal-attribution-p) t nil)
          :ai-involvement-p (if (getf input :ai-involvement-p) t nil)
          :command-accountability-p (if (getf input :command-accountability-p) t nil)
          :include-incident-topic-p (if (getf input :include-incident-topic-p) t nil)
          :incident-page-reference? (if (getf input :incident-page-reference?) t nil)
          :known-uncertainties (article-allegation-copy-strings
                                (getf input :known-uncertainties))
          :suggested-section-headings
          (copy-list
           (or (getf input :suggested-section-headings)
               (article-allegation-normalize-section-headings
                (or (getf incident :sections)
                    (getf input :incident-sections)))
               '()))
          :require-open-uncertainties-p
          (if (or (getf flags :require-open-uncertainties)
                  (getf rules :require-open-uncertainties))
              t
              nil)
          :generate-fedwiki-twins-p
          (if (or (null flags)
                  (getf flags :generate-fedwiki-twins))
              t
              nil)
          :generate-daily-anchor-p
          (if (or (null flags)
                  (getf flags :generate-daily-anchor))
              t
              nil)
          :daily-anchor-date (or (getf input :daily-anchor-date)
                                 (getf output :anchor-date)
                                 (getf input :anchor-date))
          :daily-anchor-heading (or (getf input :daily-anchor-heading)
                                    (format nil "~A article-allegation slice" incident-title))
          :daily-anchor-note (or (getf input :daily-anchor-note)
                                 "Kept article-derived claims allegation-qualified and split reusable concepts into separate topic twins.")
          :dry-run-start-date (or (getf input :dry-run-start-date) 1773393295339)
          :expected-hyperdoc-branch
          (or (getf input :expected-hyperdoc-branch)
              (getf repo-branching :hyperdoc)
              "hauptsache")
          :expected-fedwiki-branch
          (or (getf input :expected-fedwiki-branch)
              (getf repo-branching :fedwiki)
              "localhost")
          :hyperdoc-repo-root (uiop:ensure-directory-pathname
                               (or (getf input :hyperdoc-repo-root)
                                   (article-allegation-source-root)))
          :hyperdoc-pages-directory (uiop:ensure-directory-pathname
                                     (or (getf input :hyperdoc-pages-directory)
                                         (article-allegation-default-hyperdoc-pages-directory)))
          :fedwiki-repo-root (uiop:ensure-directory-pathname
                              (or (getf input :fedwiki-repo-root)
                                  (article-allegation-default-fedwiki-repo-root)))
          :fedwiki-pages-directory (uiop:ensure-directory-pathname
                                    (or (getf input :fedwiki-pages-directory)
                                        (article-allegation-default-fedwiki-pages-directory)))
          :fedwiki-site-id (article-allegation-non-empty-string
                            (or (getf output :fedwiki-site)
                                (getf input :fedwiki-site-id)
                                "wiki.ralfbarkow.ch"))
          :concepts concepts)))

(defun read-article-allegation-slice-input (path)
  (with-open-file (stream path :direction :input :external-format :utf-8)
    (article-allegation-normalize-input (read stream nil nil)
                                        :source-path path)))

(defun article-allegation-concept-by-title (input title)
  (find title
        (getf input :concepts)
        :key #'(lambda (concept) (getf concept :title))
        :test #'equal))

(defun article-allegation-related-concept-links (input titles)
  (loop for title in titles
        for concept = (article-allegation-concept-by-title input title)
        when concept
          collect (article-allegation-topic-link (getf concept :title))))

(defun article-allegation-concept-references (input concept)
  (remove-duplicates
   (append (list (getf concept :title))
           (copy-list (or (getf concept :references) '()))
           (when (getf input :incident-page-reference?)
             (list (getf input :incident-title))))
   :test #'equal))

(defun article-allegation-write-list (stream items)
  (format stream "<ul>~%")
  (dolist (item items)
    (format stream "  <li>~A</li>~%" item))
  (format stream "</ul>~%"))

(defun article-allegation-write-related-section (stream titles)
  (format stream "<ul>~%")
  (dolist (title titles)
    (format stream "  <li>~A</li>~%" (article-allegation-page-link title)))
  (format stream "</ul>~%"))

(defun article-allegation-incident-introduction (input)
  (with-output-to-string (stream)
    (format stream
            "<p>~%  This page scaffolds an allegation-qualified documentation slice from ~A. HyperDoc keeps the concrete event claims here at the level of reported, alleged, or cited claims unless stronger verification metadata is explicitly supplied to the routine.~%</p>~%"
            (article-allegation-html-escape (getf input :source-description)))
    (when-let (article-date (getf input :article-date))
      (format stream
              "<p>~%  Article date carried in the input: <tt>~A</tt>. That date is preserved as provenance context, not as a claim-strength upgrade by itself.~%</p>~%"
              (article-allegation-html-escape article-date)))))

(defun article-allegation-incident-inspectable-links (input)
  (append (when (getf input :include-incident-topic-p)
            (list (article-allegation-topic-link (getf input :incident-title))))
          (loop for concept in (getf input :concepts)
                collect (article-allegation-topic-link (getf concept :title)))))

(defun article-allegation-render-incident-page (input)
  (with-output-to-string (stream)
    (format stream "<h1>~A</h1>~%~%<in-package>hyperdoc</in-package>~%~%"
            (article-allegation-html-escape (getf input :incident-title)))
    (write-string (article-allegation-incident-introduction input) stream)
    (format stream "<h2>Inspectable objects</h2>~%~%")
    (article-allegation-write-list stream
                                   (article-allegation-incident-inspectable-links input))
    (format stream "<h2>~A</h2>~%~%"
            (article-allegation-html-escape
             (article-allegation-section-heading input :claimed-sequence)))
    (format stream
            "<p>~%  According to the cited account, ~A. This scaffold preserves that sequence as article-reported reconstruction rather than silently upgrading it into settled repository fact.~%</p>~%"
            (article-allegation-html-escape (getf input :incident-summary)))
    (format stream "<h2>~A</h2>~%~%"
            (article-allegation-html-escape
             (article-allegation-section-heading input :reported-attribution)))
    (format stream
            "<p>~%  The input marks the incident's epistemic status as <tt>~A</tt>. The incident page therefore uses formulations such as <i>the article reports</i>, <i>according to the cited account</i>, and <i>the case is presented as</i> unless stronger verification metadata is explicitly supplied.~%</p>~%"
            (article-allegation-html-escape
             (article-allegation-status-label (getf input :epistemic-status))))
    (format stream "<h2>~A</h2>~%~%"
            (article-allegation-html-escape
             (article-allegation-section-heading input :forensic-claims)))
    (format stream
            "<p>~%  If the reported reconstruction is correct, the case may turn on forensic or investigative materials such as video, imagery, fragment analysis, launch-envelope reasoning, or inventory knowledge. This section exists to separate evidentiary reconstruction from immediate public narrative.~%</p>~%")
    (format stream "<h2>~A</h2>~%~%"
            (article-allegation-html-escape
             (article-allegation-section-heading input :accountability)))
    (format stream
            "<p>~%  The incident raises questions about target validation, civilian-harm review, organizational mitigation capacity, and command responsibility. ~A~%</p>~%"
            (if (getf input :verified-legal-attribution-p)
                "The input explicitly allows verified legal attribution language where supported."
                "This scaffold does not emit flat legal conclusions such as <i>war crime</i> by default."))
    (when (or (getf input :ai-involvement-p)
              (find :human-ai-boundary
                    (mapcar #'(lambda (concept) (getf concept :kind))
                            (getf input :concepts))))
      (format stream "<h2>~A</h2>~%~%"
              (article-allegation-html-escape
               (article-allegation-section-heading input :ai-boundary)))
      (format stream
              "<p>~%  The input marks AI or automation discourse as relevant. This scaffold therefore keeps AI language at the level of decision support, review acceleration, automation-bias risk, and human final responsibility, not as a flat claim that AI caused the incident.~%</p>~%"))
    (format stream "<h2>~A</h2>~%~%"
            (article-allegation-html-escape
             (article-allegation-section-heading input :uncertainties)))
    (article-allegation-write-list
     stream
     (mapcar #'article-allegation-html-escape
             (article-allegation-uncertainties input)))
    (format stream "<h2>~A</h2>~%~%"
            (article-allegation-html-escape
             (article-allegation-section-heading input :related)))
    (article-allegation-write-related-section
     stream
     (mapcar #'(lambda (concept) (getf concept :title))
             (getf input :concepts)))
    (when (getf input :generate-fedwiki-twins-p)
      (format stream "<h2>Localhost FedWiki twin</h2>~%~%")
      (format stream "<p>~%  Twin page:~%  ~A.~%</p>~%"
              (article-allegation-fedwiki-link (getf input :fedwiki-site-id)
                                               (getf input :incident-fedwiki-slug))))))

(defun article-allegation-assert-incident-page-invariants (input content)
  (when (getf input :require-open-uncertainties-p)
    (let ((heading (format nil "<h2>~A</h2>"
                           (article-allegation-html-escape
                            (article-allegation-section-heading input :uncertainties)))))
      (unless (search heading content :test #'char=)
        (error "Incident page for ~S must contain the Open uncertainties section"
               (getf input :incident-title)))))
  content)

(defun article-allegation-concept-kind-description (concept)
  (case (getf concept :kind)
    (:failure-mode
     "HyperDoc uses this page for a reusable failure mode rather than for a one-off incident verdict.")
    (:process-failure
     "HyperDoc uses this page to separate a process failure from any one article's reconstruction.")
    (:accountability-model
     "HyperDoc uses this page to keep accountability questions visible without forcing premature legal closure.")
    (:review-doctrine
     "HyperDoc uses this page to capture review doctrine and mitigation capacity as reusable operational concepts.")
    (:attribution-method
     "HyperDoc uses this page for a reusable attribution method, not for a single fixed political narrative.")
    (:human-ai-boundary
     "HyperDoc uses this page for the human/AI decision boundary and the difference between formal approval and substantive accountability.")
    (otherwise
     "HyperDoc uses this page as a reusable concept rather than as an incident-specific claim.")))

(defun article-allegation-concept-default-list (concept)
  (case (getf concept :kind)
    (:failure-mode
     '("stale or obsolete target data persists into a later strike package"
       "a system remains precise in delivery while wrong in target representation"
       "upstream classification or mapping assumptions survive longer than the underlying site reality"))
    (:process-failure
     '("current site status is not rechecked before launch"
       "older intelligence handoff is trusted without fresh validation"
       "review gates exist formally but do not surface or stop the mismatch"))
    (:accountability-model
     '("what should have been checked before authorization"
       "who had authority to slow, stop, or review the strike package"
       "whether organizational practice created foreseeable civilian-harm risk"))
    (:review-doctrine
     '("review current civilian presence and site status"
       "test whether mitigation staff and escalation paths are still real in practice"
       "record why approval under uncertainty was considered acceptable"))
    (:attribution-method
     '("video, imagery, or fragment evidence"
       "inventory and launch-envelope reasoning"
       "separation of public accusation from forensic confidence"))
    (:human-ai-boundary
     '("decision support and ranking do not remove human responsibility"
       "compressed review windows can amplify automation bias"
       "human in the loop must mean more than a final signature"))
    (otherwise
     '("reusable concept boundary"
       "operational distinction"
       "non-incident-specific framing"))))

(defun article-allegation-concept-secondary-paragraph (concept)
  (case (getf concept :kind)
    (:failure-mode
     "A system can therefore look precise while remaining dangerously wrong about what the coordinates represent.")
    (:process-failure
     "The process layer matters because stale information becomes operational only when later actors inherit it without adequate challenge.")
    (:accountability-model
     "Unintended harm does not end accountability analysis when the harm may have followed preventable review, staffing, or doctrine failures.")
    (:review-doctrine
     "Reduced staffing, shorter timelines, or weaker institutional emphasis can turn review into a checkbox rather than a real constraint on action.")
    (:attribution-method
     "Public certainty and evidentiary confidence are different things; this page exists to keep them distinct.")
    (:human-ai-boundary
     "Formal human approval does not by itself prove meaningful human oversight if time pressure, opaque rankings, or organizational incentives dominate the workflow.")
    (otherwise
     "This concept remains reusable beyond any single article-derived incident.")))

(defun article-allegation-concept-boundary (concept)
  (case (getf concept :kind)
    (:failure-mode
     "This page does not imply weapon malfunction. It distinguishes a wrong target representation from a guidance failure.")
    (:process-failure
     "This page does not claim that every disputed strike reflects a process failure. It records where process review would matter if stale or mistaken data is alleged.")
    (:accountability-model
     "This page does not declare liability by default. It preserves the questions that should remain visible when civilian harm is reported.")
    (:review-doctrine
     "This page does not claim that more staffing alone solves targeting mistakes. It records mitigation and review capacity as a real operational variable.")
    (:attribution-method
     "This page does not promise certainty in every case. It preserves the method boundary between rhetoric and reconstruction.")
    (:human-ai-boundary
     "This page does not claim that software autonomously caused a strike unless that stronger verified input is explicitly supplied.")
    (otherwise
     "This page preserves the concept boundary instead of collapsing it into one incident.")))

(defun article-allegation-concept-inspectable-links (input concept)
  (remove nil
          (append (list (article-allegation-topic-link (getf concept :title)))
                  (article-allegation-related-concept-links
                   input
                   (getf concept :related-titles)))))

(defun article-allegation-render-concept-page (input concept)
  (with-output-to-string (stream)
    (format stream "<h1>~A</h1>~%~%<in-package>hyperdoc</in-package>~%~%"
            (article-allegation-html-escape (getf concept :title)))
    (format stream
            "<p>~%  ~A ~A~%</p>~%"
            (article-allegation-html-escape (getf concept :summary))
            (article-allegation-html-escape
             (article-allegation-concept-kind-description concept)))
    (format stream "<h2>Inspectable objects</h2>~%~%")
    (article-allegation-write-list
     stream
     (article-allegation-concept-inspectable-links input concept))
    (format stream "<h2>Core distinction</h2>~%~%")
    (format stream "<p>~%  ~A~%</p>~%"
            (article-allegation-html-escape (getf concept :summary)))
    (format stream "<h2>Operational notes</h2>~%~%")
    (article-allegation-write-list
     stream
     (mapcar #'article-allegation-html-escape
             (article-allegation-concept-default-list concept)))
    (format stream "<h2>Why this remains reusable</h2>~%~%")
    (format stream "<p>~%  ~A~%</p>~%"
            (article-allegation-html-escape
             (article-allegation-concept-secondary-paragraph concept)))
    (format stream "<h2>Boundary</h2>~%~%")
    (format stream "<p>~%  ~A~%</p>~%"
            (article-allegation-html-escape
             (article-allegation-concept-boundary concept)))
    (when (getf input :generate-fedwiki-twins-p)
      (format stream "<h2>Localhost FedWiki twin</h2>~%~%")
      (format stream "<p>~%  Twin page:~%  ~A.~%</p>~%"
              (article-allegation-fedwiki-link (getf input :fedwiki-site-id)
                                               (getf concept :fedwiki-slug))))
    (format stream "<h2>Related</h2>~%~%")
    (article-allegation-write-related-section
     stream
     (remove-duplicates
      (append (copy-list (getf concept :related-titles))
              (list (getf input :incident-title)))
      :test #'equal))))

(defun article-allegation-topic-snippet (input)
  (with-output-to-string (stream)
    (format stream ";; Article allegation slice topics for ~A.~%~%"
            (getf input :incident-title))
    (dolist (concept (getf input :concepts))
      (format stream "(defun ~A ()~%"
              (getf concept :topic-function-name))
      (format stream "  (make-topic~%")
      (format stream "   :id ~S~%" (getf concept :topic-id))
      (format stream "   :title ~S~%" (getf concept :title))
      (format stream "   :summary ~S~%" (getf concept :summary))
      (format stream "   :references '~S))~%~%"
              (article-allegation-concept-references input concept)))))

(defun article-allegation-story-item-id (page-index item-index)
  (format nil "~16,'0x" (+ (ash page-index 32) item-index)))

(defun article-allegation-page-story-items (page-index summary references)
  (list
   (list :type :paragraph
         :id (article-allegation-story-item-id page-index 1)
         :text summary)
   (list :type :markdown
         :id (article-allegation-story-item-id page-index 2)
         :text (with-output-to-string (stream)
                 (format stream "### References~%")
                 (dolist (reference references)
                   (format stream "- ~A~%" reference))))))

(defun article-allegation-make-page-with-journal (title story-items &key start-date)
  (let* ((date (or start-date (journalmatic-current-epoch-millis)))
         (journal (list (list :type :create
                              :item (list :title title :story '())
                              :date date)))
         (after nil))
    (dolist (item story-items)
      (setf date (journalmatic-next-date-like-wiki-client journal :now date))
      (let ((action (list :type :add
                          :id (getf item :id)
                          :item (copy-tree item)
                          :date date)))
        (when after
          (setf action (append action (list :after after))))
        (setf journal (append journal (list action)))
        (setf after (getf item :id))))
    (list :title title
          :story (copy-tree story-items)
          :journal journal)))

(defun article-allegation-incident-fedwiki-page (input)
  (let* ((references (mapcar #'article-allegation-fedwiki-reference
                             (append (list (getf input :incident-title))
                                     (mapcar #'(lambda (concept) (getf concept :title))
                                             (getf input :concepts)))))
         (items (article-allegation-page-story-items
                 1
                 (getf input :incident-summary)
                 references)))
    (article-allegation-make-page-with-journal
     (getf input :incident-title)
     items
     :start-date (getf input :dry-run-start-date))))

(defun article-allegation-concept-fedwiki-page (input concept page-index)
  (let ((items (article-allegation-page-story-items
                page-index
                (getf concept :summary)
                (mapcar #'article-allegation-fedwiki-reference
                        (article-allegation-concept-references input concept)))))
    (article-allegation-make-page-with-journal
     (getf concept :title)
     items
     :start-date (+ (getf input :dry-run-start-date) page-index))))

(defun article-allegation-daily-anchor-text (input)
  (with-output-to-string (stream)
    (format stream "### ~A~%" (getf input :daily-anchor-heading))
    (format stream "- [[~A]]~%" (getf input :incident-title))
    (dolist (concept (getf input :concepts))
      (format stream "- [[~A]]~%" (getf concept :title)))
    (format stream "- ~A" (getf input :daily-anchor-note))))

(defun article-allegation-daily-anchor-item (input &key id)
  (list :type :markdown
        :id (or id
                (format nil "~16,'0x" (journalmatic-current-epoch-millis)))
        :text (article-allegation-daily-anchor-text input)))

(defun article-allegation-generated-daily-page (input)
  (when-let (title (getf input :daily-anchor-date))
    (article-allegation-make-page-with-journal
     title
     (list (article-allegation-daily-anchor-item
            input
            :id (article-allegation-story-item-id 99 1)))
     :start-date (+ (getf input :dry-run-start-date) 99))))

(defun article-allegation-json-keyword (key)
  (etypecase key
    (keyword key)
    (symbol (intern (string-upcase (string key)) :keyword))
    (string (intern (string-upcase key) :keyword))))

(defun article-allegation-json-object-p (value)
  (and (listp value)
       (every #'(lambda (entry)
                  (and (consp entry)
                       (or (stringp (car entry))
                           (symbolp (car entry))
                           (keywordp (car entry)))))
              value)))

(defun article-allegation-normalize-json (value &optional key)
  (labels ((normalize-type (type-value)
             (if (stringp type-value)
                 (intern (string-upcase type-value) :keyword)
                 type-value)))
    (cond
      ((hash-table-p value)
       (loop for json-key being each hash-key of value
               using (hash-value json-value)
             for normalized-key = (article-allegation-json-keyword json-key)
             append (list normalized-key
                          (article-allegation-normalize-json json-value normalized-key))))
      ((article-allegation-json-object-p value)
       (loop for (json-key . json-value) in value
             for normalized-key = (article-allegation-json-keyword json-key)
             append (list normalized-key
                          (article-allegation-normalize-json json-value normalized-key))))
      ((stringp value)
       (if (eql key :type)
           (normalize-type value)
           value))
      ((vectorp value)
       (map 'list #'article-allegation-normalize-json value))
      ((listp value)
       (mapcar #'article-allegation-normalize-json value))
      (t
       value))))

(defun article-allegation-read-json-file (path)
  (with-open-file (stream path :direction :input :external-format :utf-8)
    (article-allegation-normalize-json (shasht:read-json stream))))

(defun article-allegation-plist->json (value &optional key)
  (cond
    ((article-allegation-plist-p value)
     (let ((table (make-hash-table :test #'equal)))
       (loop for (plist-key plist-value) on value by #'cddr
             do (setf (gethash (string-downcase (symbol-name plist-key)) table)
                      (article-allegation-plist->json plist-value plist-key)))
       table))
    ((and (keywordp value) (eql key :type))
     (string-downcase (symbol-name value)))
    ((listp value)
     (mapcar #'article-allegation-plist->json value))
    (t
     value)))

(defun article-allegation-write-json-file (path data)
  (ensure-directories-exist path)
  (with-open-file (stream path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :external-format :utf-8)
    (shasht:write-json (article-allegation-plist->json data) stream)))

(defun article-allegation-append-item-to-page (page item)
  (let* ((page (copy-tree page))
         (story (copy-list (or (getf page :story) '())))
         (journal (copy-list (or (getf page :journal) '())))
         (last-id (and story (getf (car (last story)) :id)))
         (date (journalmatic-next-date-like-wiki-client journal))
         (action (list :type :add
                       :id (getf item :id)
                       :item (copy-tree item)
                       :date date)))
    (when last-id
      (setf action (append action (list :after last-id))))
    (setf (getf page :story) (append story (list item))
          (getf page :journal) (append journal (list action)))
    page))

(defun article-allegation-topic-definitions (input)
  (loop for concept in (getf input :concepts)
        collect (list :function-name (getf concept :topic-function-name)
                      :title (getf concept :title)
                      :topic-id (getf concept :topic-id))))

(defun article-allegation-slice-metadata (bundle)
  (let* ((input (getf bundle :input))
         (hyperdoc-files (getf bundle :hyperdoc-files))
         (fedwiki-files (getf bundle :fedwiki-files))
         (daily-page (getf bundle :daily-page)))
    (list :slice-id (getf input :slice-id)
          :mode (getf input :mode)
          :generated-by :article-allegation-slice
          :source-type (getf input :source-type)
          :source-label (getf input :source-label)
          :epistemic-status (getf input :epistemic-status)
          :incident-page-title (getf input :incident-title)
          :incident-page (getf (first hyperdoc-files) :relative-path)
          :concept-page-titles (loop for concept in (getf input :concepts)
                                     collect (getf concept :title))
          :concept-pages (loop for page in (rest hyperdoc-files)
                               collect (getf page :relative-path))
          :topic-handles (loop for topic in (getf bundle :topic-definitions)
                               collect (getf topic :function-name))
          :incident-fedwiki-slug (getf input :incident-fedwiki-slug)
          :concept-fedwiki-slugs (loop for concept in (getf input :concepts)
                                       collect (getf concept :fedwiki-slug))
          :fedwiki-pages (loop for page in fedwiki-files
                               collect (format nil "fedwiki-pages/~A"
                                               (getf page :slug)))
          :daily-anchor-target (and daily-page
                                    (getf daily-page :title))
          :daily-anchor (and daily-page
                             (format nil "fedwiki-pages/~A"
                                     (getf daily-page :title))))))

(defun article-allegation-asdf-bootstrap-command ()
  "nix develop --command sbcl --no-userinit --non-interactive --eval '(require :asdf)' --eval '(let* ((root (uiop:ensure-directory-pathname (uiop:getcwd))) (flake-deps (uiop:ensure-directory-pathname (merge-pathnames \".flake-deps/\" root))) (cache (uiop:ensure-directory-pathname (merge-pathnames \".cache/asdf/\" root))) (src-pattern (list root #P\"**/*.*\")) (dst-pattern (list cache #P\"**/*.*\"))) (ensure-directories-exist cache) (asdf:initialize-source-registry (list :source-registry (list :tree root) (list :tree flake-deps) :inherit-configuration)) (asdf:initialize-output-translations (list :output-translations (list src-pattern dst-pattern) :ignore-inherited-configuration)))' --eval '(asdf:load-asd (truename \"hyperbook.asd\"))' --eval '(asdf:load-asd (truename \"hyperdoc.asd\"))'")

(defun article-allegation-validation-commands (input)
  (let* ((page-paths
           (append
            (list (format nil "hyperdoc/~A"
                          (article-allegation-page-filename
                           (getf input :incident-title))))
            (loop for concept in (getf input :concepts)
                  collect (format nil "hyperdoc/~A"
                                  (article-allegation-page-filename
                                   (getf concept :title))))))
         (topic-symbols
           (loop for concept in (getf input :concepts)
                 collect (format nil "hyperdoc::~A"
                                 (getf concept :topic-function-name))))
         (fedwiki-paths
           (when (getf input :generate-fedwiki-twins-p)
             (append
              (list (format nil "~Apages/~A"
                            (namestring (getf input :fedwiki-repo-root))
                            (getf input :incident-fedwiki-slug)))
              (loop for concept in (getf input :concepts)
                    collect (format nil "~Apages/~A"
                                    (namestring (getf input :fedwiki-repo-root))
                                    (getf concept :fedwiki-slug)))
              (when (and (getf input :generate-daily-anchor-p)
                         (getf input :daily-anchor-date))
                (list (format nil "~Apages/~A"
                              (namestring (getf input :fedwiki-repo-root))
                              (getf input :daily-anchor-date)))))))
         (bootstrap (article-allegation-asdf-bootstrap-command)))
    (append
     (list
      (format nil "~A --eval '(asdf:load-system :hyperdoc)' --quit"
              bootstrap)
      (format nil "~A --eval '(asdf:load-system :hyperdoc)' --eval '(uiop:quit (if (every #'fboundp (list ~{(quote ~A)~^ ~})) 0 1))' --quit"
              bootstrap
              topic-symbols)
      (format nil "nix develop --command sbcl --no-userinit --non-interactive --load tools/check-topic-coverage.lisp -- ~{~S~^ ~}"
              page-paths))
     (loop for fedwiki-path in (or fedwiki-paths '())
           collect (format nil "python3 -m json.tool ~A >/tmp/~A.json"
                           fedwiki-path
                           (article-allegation-slugify
                            (file-namestring fedwiki-path))))
     (when fedwiki-paths
       (list
        (format nil "nix develop --command sbcl --script tools/journal-gate.lisp ~{~A~^ ~}"
                fedwiki-paths))))))

(defun render-article-allegation-slice-bundle (input &key dry-run-directory)
  (let* ((normalized (if (or (pathnamep input) (stringp input))
                         (read-article-allegation-slice-input input)
                         (article-allegation-normalize-input input)))
         (dry-run-root (and dry-run-directory
                            (uiop:ensure-directory-pathname dry-run-directory)))
         (incident-title (getf normalized :incident-title))
         (incident-content
           (article-allegation-assert-incident-page-invariants
            normalized
            (article-allegation-render-incident-page normalized)))
         (hyperdoc-files
           (append
            (list (list :title incident-title
                        :relative-path (format nil "hyperdoc/~A"
                                               (article-allegation-page-filename incident-title))
                        :target-path (merge-pathnames
                                      (article-allegation-page-filename incident-title)
                                      (getf normalized :hyperdoc-pages-directory))
                        :content incident-content))
            (loop for concept in (getf normalized :concepts)
                  collect (list :title (getf concept :title)
                                :relative-path (format nil "hyperdoc/~A"
                                                       (article-allegation-page-filename
                                                        (getf concept :title)))
                                :target-path (merge-pathnames
                                              (article-allegation-page-filename
                                               (getf concept :title))
                                              (getf normalized :hyperdoc-pages-directory))
                                :content (article-allegation-render-concept-page
                                          normalized concept)))))
         (fedwiki-files
           (if (getf normalized :generate-fedwiki-twins-p)
               (append
                (list (list :title incident-title
                            :slug (getf normalized :incident-fedwiki-slug)
                            :target-path (merge-pathnames
                                          (getf normalized :incident-fedwiki-slug)
                                          (getf normalized :fedwiki-pages-directory))
                            :page (article-allegation-incident-fedwiki-page normalized)))
                (loop for concept in (getf normalized :concepts)
                      for page-index from 2
                      collect (list :title (getf concept :title)
                                    :slug (getf concept :fedwiki-slug)
                                    :target-path (merge-pathnames
                                                  (getf concept :fedwiki-slug)
                                                  (getf normalized :fedwiki-pages-directory))
                                    :page (article-allegation-concept-fedwiki-page
                                           normalized concept page-index))))
               '()))
         (bundle (list :input normalized
                       :dry-run-root dry-run-root
                       :hyperdoc-files hyperdoc-files
                       :topics-target-path (merge-pathnames "hyperdoc/topics.lisp"
                                                            (getf normalized :hyperdoc-repo-root))
                       :topics-snippet (article-allegation-topic-snippet normalized)
                       :topic-definitions (article-allegation-topic-definitions normalized)
                       :fedwiki-files fedwiki-files
                       :daily-page (and (getf normalized :generate-fedwiki-twins-p)
                                        (getf normalized :generate-daily-anchor-p)
                                        (getf normalized :daily-anchor-date)
                                        (list :title (getf normalized :daily-anchor-date)
                                              :target-path (merge-pathnames
                                                            (getf normalized :daily-anchor-date)
                                                            (getf normalized :fedwiki-pages-directory))
                                              :page (article-allegation-generated-daily-page normalized)))
                       :validation-commands (article-allegation-validation-commands normalized))))
    (append bundle
            (list :slice-metadata (article-allegation-slice-metadata bundle)))))

(defun article-allegation-write-string-file (path content)
  (ensure-directories-exist path)
  (with-open-file (stream path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :external-format :utf-8)
    (write-string content stream)))

(defun article-allegation-git-branch (repo-root)
  (article-allegation-trimmed-string
   (uiop:run-program (list "git" "-C" (namestring repo-root) "branch" "--show-current")
                     :output :string)))

(defun article-allegation-assert-live-branches (bundle)
  (let* ((input (getf bundle :input))
         (hyperdoc-branch (article-allegation-git-branch
                           (getf input :hyperdoc-repo-root)))
         (fedwiki-branch (article-allegation-git-branch
                          (getf input :fedwiki-repo-root))))
    (unless (string= hyperdoc-branch (getf input :expected-hyperdoc-branch))
      (error "HyperDoc repo branch mismatch: expected ~S, got ~S"
             (getf input :expected-hyperdoc-branch)
             hyperdoc-branch))
    (unless (string= fedwiki-branch (getf input :expected-fedwiki-branch))
      (error "FedWiki repo branch mismatch: expected ~S, got ~S"
             (getf input :expected-fedwiki-branch)
             fedwiki-branch))))

(defun article-allegation-assert-new-path (path)
  (when (uiop:file-exists-p path)
    (error "Refusing to overwrite existing path ~A" path)))

(defun article-allegation-update-topics-file (bundle)
  (let* ((topics-path (getf bundle :topics-target-path))
         (content (uiop:read-file-string topics-path))
         (snippet (getf bundle :topics-snippet))
         (marker "(eval-when (:load-toplevel :execute)")
         (position (search marker content :from-end t)))
    (unless position
      (error "Could not find install-topic-proxy-wrappers marker in ~A" topics-path))
    (dolist (topic (getf bundle :topic-definitions))
      (let ((needle (format nil "(defun ~A" (getf topic :function-name))))
        (when (search needle content)
          (error "Topic function ~A already exists in ~A"
                 (getf topic :function-name)
                 topics-path))))
    (article-allegation-write-string-file
     topics-path
     (concatenate 'string
                  (subseq content 0 position)
                  "\n"
                  snippet
                  (subseq content position)))))

(defun article-allegation-ensure-daily-page (bundle)
  (when-let (daily (getf bundle :daily-page))
    (let* ((target-path (getf daily :target-path))
           (input (getf bundle :input))
           (item-text (article-allegation-daily-anchor-text input)))
      (if (uiop:file-exists-p target-path)
          (let* ((page (article-allegation-read-json-file target-path))
                 (existing (find item-text
                                 (getf page :story)
                                 :key #'(lambda (item) (getf item :text))
                                 :test #'equal)))
            (unless existing
              (let* ((item (article-allegation-daily-anchor-item
                            input
                            :id (format nil "~16,'0x"
                                        (journalmatic-next-date-like-wiki-client
                                         (getf page :journal)))))
                     (updated (article-allegation-append-item-to-page page item)))
                (article-allegation-write-json-file target-path updated))))
          (article-allegation-write-json-file target-path (getf daily :page))))))

(defun article-allegation-write-dry-run-bundle (bundle)
  (let ((root (or (getf bundle :dry-run-root)
                  (error "Dry-run bundle requires :dry-run-root"))))
    (dolist (page (getf bundle :hyperdoc-files))
      (article-allegation-write-string-file
       (merge-pathnames (getf page :relative-path) root)
       (getf page :content)))
    (article-allegation-write-string-file
     (merge-pathnames "hyperdoc/topics.generated.lisp" root)
     (getf bundle :topics-snippet))
    (dolist (page (getf bundle :fedwiki-files))
      (article-allegation-write-json-file
       (merge-pathnames (format nil "fedwiki-pages/~A" (getf page :slug)) root)
       (getf page :page)))
    (when-let (daily (getf bundle :daily-page))
      (article-allegation-write-json-file
       (merge-pathnames (format nil "fedwiki-pages/~A" (getf daily :title)) root)
       (getf daily :page)))
    (article-allegation-write-string-file
     (merge-pathnames "slice-metadata.lisp" root)
     (with-output-to-string (stream)
       (let ((*print-right-margin* 100)
             (*print-pretty* t))
         (pprint (getf bundle :slice-metadata) stream))))
    (article-allegation-write-string-file
     (merge-pathnames "manifest.lisp" root)
     (with-output-to-string (stream)
       (let ((*print-right-margin* 100)
             (*print-pretty* t))
         (pprint bundle stream)))))
  bundle)

(defun article-allegation-write-live-bundle (bundle)
  (article-allegation-assert-live-branches bundle)
  (dolist (page (getf bundle :hyperdoc-files))
    (article-allegation-assert-new-path (getf page :target-path))
    (article-allegation-write-string-file
     (getf page :target-path)
     (getf page :content)))
  (article-allegation-update-topics-file bundle)
  (dolist (page (getf bundle :fedwiki-files))
    (article-allegation-assert-new-path (getf page :target-path))
    (article-allegation-write-json-file
     (getf page :target-path)
     (getf page :page)))
  (article-allegation-ensure-daily-page bundle)
  bundle)

(defun write-article-allegation-slice-bundle (bundle &key live-write-p)
  (if live-write-p
      (article-allegation-write-live-bundle bundle)
      (article-allegation-write-dry-run-bundle bundle)))
