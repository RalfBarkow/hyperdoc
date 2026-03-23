;;;; HTML pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; An HTML page stores the page contents as the parse tree
;; returned by the plump parser.
;;

(defclass html-page (text-page)
  ((parse-tree :reader dom-of :initform nil)
   (counterpart-section-issues
    :reader counterpart-section-issues-of
    :initform nil)))

;;
;; The page class for file type "html" is html-page.
;;

(defmethod page-class ((filetype (eql :html)))
  (find-class 'html-page))

;;
;; Load an HTML page, parse it, set the title, and compile a
;; list of the links it contains.
;;
;; The title is given by a TITLE tag, if one exists, or else as the text
;; of the highest-level header tag in the page. If neither TITLE
;; nor any header tag exists, return "Untitled".
;;

(defmethod load-page ((page html-page))
  (with-slots (links file parse-tree title) page
    (let ((plump:*tag-dispatchers* plump:*html-tags*))
      (setf parse-tree (plump:parse file))
      (set-title page)
      (setf (slot-value page 'counterpart-section-issues)
            (normalize-fedwiki-counterpart-sections! page parse-tree))
      (setf links (hb:extract-links page))))
  page)

(defun set-title (page)
  (with-slots (parse-tree id) page
    (setf id (or (loop for tag in '("title" "h1" "h2" "h3" "h4" "h5" "h6")
                          do (let ((elements (-> (dom-of page)
                                               (plump:get-elements-by-tag-name tag))))
                               (when elements
                                 (return (-> elements first plump:text str:trim)))))
                    "Untitled"))))

(defun copy-plump-attributes! (from to)
  (maphash #'(lambda (key value)
               (plump:set-attribute to key value))
           (plump:attributes from))
  to)

(defun replace-element-text! (element new-text)
  (let* ((root (plump:make-root))
         (replacement (plump:make-element root (plump:tag-name element))))
    (copy-plump-attributes! element replacement)
    (plump:make-text-node replacement new-text)
    (plump:replace-child element replacement)
    replacement))

(defun normalize-fedwiki-counterpart-link! (anchor domain)
  (let* ((current-text (or (hb::trimmed-node-text anchor)
                           (plump:get-attribute anchor "page")
                           domain))
         (labelled-text
           (if (and current-text
                    (uiop:string-prefix-p "[" current-text))
               current-text
               (format nil "[~A] ~A" domain current-text))))
    (replace-element-text! anchor labelled-text)))

(defun fedwiki-counterpart-heading-p (text)
  (member text
          '("Localhost FedWiki twin"
            "Localhost FedWiki twins")
          :test #'string-equal))

(defun fedwiki-counterpart-section-title (domains)
  (cond
    ((null domains)
     "FedWiki counterparts")
    ((every #'localhost-like-fedwiki-domain-p domains)
     "Local FedWiki counterparts")
    ((= 1 (length domains))
     "FedWiki counterparts")
    (t
     "FedWiki counterpart targets")))

(defun fedwiki-links-in-section (nodes)
  (loop for node in nodes
        when (typep node 'plump:element)
          append (loop for element across (lquery:$ node "a[hyperbook]")
                       for hyperbook = (plump:get-attribute element "hyperbook")
                       when (and hyperbook
                                 (uiop:string-prefix-p "fedwiki:" hyperbook))
                         collect element)))

(defun node-vector-to-list (vector)
  (loop for node across vector
        collect node))

(defun normalize-fedwiki-counterpart-sections! (page dom)
  (let* ((children (node-vector-to-list (plump:children dom)))
         (page-hyperbook-id (hb:id-of (hb:hyperbook-of page)))
         (page-id (hb:id-of page))
         (page-title (title-of page))
         (issues nil))
    (loop for index from 0 below (length children)
          for node = (nth index children)
          when (and (typep node 'plump:element)
                    (member (plump:tag-name node)
                            '("h2" "h3" "h4" "h5" "h6")
                            :test #'string-equal))
            do (let ((heading-text (hb::trimmed-node-text node)))
                 (when (fedwiki-counterpart-heading-p heading-text)
                   (let* ((section-nodes
                            (loop for section-index from (1+ index) below (length children)
                                  for section-node = (nth section-index children)
                                  while (not (and (typep section-node 'plump:element)
                                                  (member (plump:tag-name section-node)
                                                          '("h1" "h2" "h3" "h4" "h5" "h6")
                                                          :test #'string-equal)))
                                  collect section-node))
                          (anchors (fedwiki-links-in-section section-nodes))
                          (domains
                            (remove-duplicates
                             (loop for anchor in anchors
                                   for hyperbook = (plump:get-attribute anchor "hyperbook")
                                   collect (subseq hyperbook (length "fedwiki:")))
                             :test #'string-equal))
                          (replacement-title
                            (fedwiki-counterpart-section-title domains)))
                     (when (or (not (string= heading-text replacement-title))
                               (some #'(lambda (domain)
                                         (not (localhost-like-fedwiki-domain-p domain)))
                                     domains))
                       (push
                        (hb:make-target-grouping-issue
                         :source-object page
                         :source-hyperbook page-hyperbook-id
                         :source-page-id page-id
                         :source-page-title page-title
                         :source-section heading-text
                         :target-hyperbook-id (and (= 1 (length domains))
                                                   (format nil "fedwiki:~A"
                                                           (first domains)))
                         :target-kind (if (> (length domains) 1)
                                          :unknown
                                          :remote-fedwiki-page)
                         :classification :mislabelled-target-grouping
                         :status :mislabelled-target
                         :suggested-repair :normalize-fedwiki-counterpart-labels
                         :repair-description
                         "Render FedWiki counterpart sections with truthful scope labels rather than a flat Localhost heading."
                         :details (list :original-heading heading-text
                                        :replacement-heading replacement-title
                                        :domains domains))
                        issues))
                     (replace-element-text! node replacement-title)
                     (loop for anchor in anchors
                           for hyperbook = (plump:get-attribute anchor "hyperbook")
                           for domain = (subseq hyperbook (length "fedwiki:"))
                           do (normalize-fedwiki-counterpart-link! anchor domain))))))
    (nreverse issues)))

(defmethod hb:enrich-lookup-issue ((issue hb:page-lookup-issue))
  (route-hyperdoc-page-lookup-issue! issue))

(defun render-time-safe-page-link-p (page link)
  (let ((source-hyperbook-id (and page
                                  (-> page hb:hyperbook-of hb:id-of)))
        (target-hyperbook-id (and link
                                  (ignore-errors
                                    (hb:target-hyperbook-of link)))))
    ;; Keep passive page-open checks local. Cross-book targets can route into
    ;; live or optional surfaces whose realization belongs on explicit click,
    ;; not on view discovery while an authored page is opening.
    (or (equal target-hyperbook-id source-hyperbook-id)
        (equal target-hyperbook-id "topics"))))

(defun render-time-page-link-result (link)
  (handler-case
      (-> link hb:thunk-of views:eval-thunk)
    (error (condition)
      condition)))

(defmethod hb:lookup-issues-of ((page html-page))
  (let ((issues (copy-list (counterpart-section-issues-of page))))
    (dolist (link (or (-> page hb:links-of hb:page-links-of) '()))
      (when (render-time-safe-page-link-p page link)
        (let ((result (render-time-page-link-result link)))
          (when (typep result 'condition)
            (push
             (hb:enrich-lookup-issue
              (hb:make-page-lookup-issue
               result
               :source-object page
               :source-hyperbook (hb:source-hyperbook-of link)
               :source-page-id (hb:source-page-of link)
               :source-page-title (title-of page)
               :source-section (hb:source-section-of link)
               :link-text (hb:link-text-of link)
               :target-hyperbook-id (hb:target-hyperbook-of link)
               :expected-page-id (hb:target-page-of link)
               :link link
               :classification :lookup-failure
               :details (list :condition-type (type-of result))))
             issues)))))
    (remove-duplicates issues
                       :test #'equal
                       :key #'hb:lookup-issue-signature)))

;;
;; Render HTML pages
;;

;; The tags with special treatment in serialization

(defvar *hyperdoc-tags* hb::*hyperbook-tags*)

;; A special variable holding the current package

(defvar *current-package* nil)

(defclass authored-expression-reference ()
  ((kind :reader authored-expression-kind-of
         :initarg :kind)
   (expression :reader authored-expression-expression-of
               :initarg :expression)
   (raw-source :reader authored-expression-raw-source-of
               :initarg :raw-source
               :initform nil)
   (package-name :reader authored-expression-package-name-of
                 :initarg :package-name
                 :initform "CL-USER")
   (view-title :reader authored-expression-view-title-of
               :initarg :view-title
               :initform nil)
   (label :reader authored-expression-label-of
          :initarg :label
          :initform nil)
   (source-page-id :reader authored-expression-source-page-id-of
                   :initarg :source-page-id
                   :initform nil)
   (source-page-title :reader authored-expression-source-page-title-of
                      :initarg :source-page-title
                      :initform nil)
   (source-tag :reader authored-expression-source-tag-of
               :initarg :source-tag
               :initform nil)))

(defclass authored-expression-evaluation-issue ()
  ((reference :reader authored-expression-issue-reference-of
              :initarg :reference)
   (condition :reader authored-expression-issue-condition-of
              :initarg :condition)
   (phase :reader authored-expression-issue-phase-of
          :initarg :phase
          :initform :evaluation)))

(define-condition authored-expression-unexpected-result (error)
  ((reference-kind :reader authored-expression-unexpected-result-kind-of
                   :initarg :reference-kind)
   (expected-description :reader authored-expression-unexpected-result-expected-description-of
                         :initarg :expected-description)
   (actual-value :reader authored-expression-unexpected-result-actual-value-of
                 :initarg :actual-value))
  (:report
   (lambda (condition stream)
     (format stream
             "Authored expression kind ~A expected ~A but got ~S."
             (authored-expression-unexpected-result-kind-of condition)
             (authored-expression-unexpected-result-expected-description-of condition)
             (authored-expression-unexpected-result-actual-value-of condition)))))

(defun authored-expression-kind-label (kind)
  (case kind
    (:expr-link "Expression link")
    (:value-of "Computed value")
    (:html-expr "Computed HTML")
    (:html-generator "HTML generator")
    (:view-transclusion "View transclusion")
    (:source-of-class "Source of class")
    (:source-of-function "Source of function")
    (t (string-capitalize
        (str:replace-all "-" " "
                         (string-downcase (symbol-name kind)))))))

(defun current-authored-package-name ()
  (or (and *current-package*
           (package-name *current-package*))
      "CL-USER"))

(defun current-authored-page ()
  (and (boundp 'hb::*current-page*)
       hb::*current-page*))

(defun current-authored-page-id ()
  (when-let (page (current-authored-page))
    (hb:id-of page)))

(defun current-authored-page-title ()
  (when-let (page (current-authored-page))
    (title-of page)))

(defun normalize-authored-reference-label (label fallback)
  (let ((trimmed (and label
                      (string-trim '(#\Space #\Tab #\Newline #\Return)
                                   label))))
    (if (and trimmed (> (length trimmed) 0))
        trimmed
        fallback)))

(defun make-authored-expression-reference
    (&key kind expression raw-source view-title label source-tag)
  (make-instance 'authored-expression-reference
                 :kind kind
                 :expression expression
                 :raw-source raw-source
                 :view-title view-title
                 :label label
                 :package-name (current-authored-package-name)
                 :source-page-id (current-authored-page-id)
                 :source-page-title (current-authored-page-title)
                 :source-tag source-tag))

(defun authored-expression-package (reference)
  (or (and (authored-expression-package-name-of reference)
           (find-package (authored-expression-package-name-of reference)))
      (find-package "CL-USER")))

(defun authored-expression-summary (reference)
  (let ((kind (authored-expression-kind-label
               (authored-expression-kind-of reference)))
        (label (authored-expression-label-of reference)))
    (if label
        (format nil "~A: ~A" kind label)
        kind)))

(defun authored-expression-title (reference)
  (format nil
          "~A~%Expression: ~A~%Rendering the page does not execute this reference. Click Evaluate or the rendered reference to run it in the current image; Alt-click inspects it without evaluation."
          (authored-expression-summary reference)
          (authored-expression-expression-of reference)))

(defun authored-expression-tag-label (tag-name)
  (format nil "<~A>" tag-name))

(defun make-authored-expression-issue (reference condition &key (phase :evaluation))
  (make-instance 'authored-expression-evaluation-issue
                 :reference reference
                 :condition condition
                 :phase phase))

(defun make-authored-expression-unexpected-result (reference expected-description actual-value)
  (make-condition 'authored-expression-unexpected-result
                  :reference-kind (authored-expression-kind-of reference)
                  :expected-description expected-description
                  :actual-value actual-value))

(defun force-view-or-issue (reference value)
  (cond
    ((typep value 'condition)
     (make-authored-expression-issue reference value :phase :evaluation))
    ((typep value 'views:view)
     (handler-case
         (progn
           ;; Force lazy view construction while the click is still inside
           ;; the bounded deferred-evaluation path.
           (views:view-html value)
           (views:view-references value)
           (views:view-assets value)
           value)
       (error (condition)
         (make-authored-expression-issue
          reference condition :phase :view-materialization))))
    (t
     (make-authored-expression-issue
      reference
      (make-authored-expression-unexpected-result
       reference
       "an html-inspector-views:view"
       value)
      :phase :unexpected-result))))

(defun make-precomputed-html-view (title html references assets)
  (let ((view (views:make-html-view
               (views:thunk (values html references assets))
               :title title
               :priority 1)))
    (setf (views:view-html view) html
          (views:view-references view) references
          (views:view-assets view) assets)
    view))

(defun evaluate-authored-expression-as-html-view (reference title renderer)
  (handler-case
      (multiple-value-bind (html references assets)
          (funcall renderer)
        (make-precomputed-html-view title html references assets))
    (error (condition)
      (make-authored-expression-issue reference condition :phase :evaluation))))

(defun evaluate-authored-expression-reference (reference)
  (let ((*package* (authored-expression-package reference)))
    (case (authored-expression-kind-of reference)
      (:expr-link
       (let ((value (parse-and-eval (authored-expression-expression-of reference))))
         (if (typep value 'condition)
             (make-authored-expression-issue reference value :phase :evaluation)
             value)))
      (:value-of
       (let ((value (parse-and-eval (authored-expression-expression-of reference))))
         (if (typep value 'condition)
             (make-authored-expression-issue reference value :phase :evaluation)
             value)))
      (:html-expr
       (let ((value (parse-and-eval (authored-expression-expression-of reference))))
         (if (typep value 'condition)
             (make-authored-expression-issue reference value :phase :evaluation)
             (evaluate-authored-expression-as-html-view
              reference
              "Computed HTML"
              #'(lambda ()
                  (views:html-and-references
                    (views:html
                      (views:str value))))))))
      (:html-generator
       (let ((form (parse (authored-expression-expression-of reference))))
         (if (typep form 'condition)
             (make-authored-expression-issue reference form :phase :parse)
             (evaluate-authored-expression-as-html-view
              reference
              "Generated HTML"
              #'(lambda ()
                  (views:html-and-references
                    (eval form)))))))
      (:view-transclusion
       (force-view-or-issue
        reference
        (parse-and-eval (authored-expression-expression-of reference))))
      (:source-of-class
       (let ((class (parse-and-eval (authored-expression-expression-of reference))))
         (if (typep class 'condition)
             (make-authored-expression-issue reference class :phase :evaluation)
             (force-view-or-issue
              reference
              (views/standard:source-code-view class)))))
      (:source-of-function
       (let ((fn (parse-and-eval (authored-expression-expression-of reference))))
         (if (typep fn 'condition)
             (make-authored-expression-issue reference fn :phase :evaluation)
             (force-view-or-issue
              reference
              (views/standard:source-code-view fn)))))
      (t
       (make-authored-expression-issue
        reference
        (make-authored-expression-unexpected-result
         reference
         "a supported authored expression kind"
         (authored-expression-kind-of reference))
        :phase :unexpected-kind)))))

(defmethod views:eval-thunk ((reference authored-expression-reference))
  (handler-case
      (evaluate-authored-expression-reference reference)
    (error (condition)
      (make-authored-expression-issue reference condition :phase :evaluation))))

(defmethod views:text-representation ((reference authored-expression-reference))
  (authored-expression-summary reference))

(defmethod views:title-bar-representation ((reference authored-expression-reference))
  (authored-expression-summary reference))

(defmethod views:title-bar-action-buttons ((reference authored-expression-reference))
  (let ((html-id (views:html-id "eval-"
                                reference
                                :select (authored-expression-view-title-of reference))))
    (views:html
      (:button :id html-id
               :class "inspector-action"
               :title "Evaluate this authored expression reference."
               "Evaluate"))))

(defmethod views:text-representation ((issue authored-expression-evaluation-issue))
  (format nil "Authored expression failure: ~A"
          (authored-expression-summary
           (authored-expression-issue-reference-of issue))))

(defmethod views:title-bar-representation ((issue authored-expression-evaluation-issue))
  "Authored expression failure")

(defun render-authored-expression-metadata-value (value)
  (typecase value
    (null
     (views:html
       (:span :class "inspector-index" "none")))
    (string
     (views:html
       (views:esc value)))
    (symbol
     (views:html
       (views:esc (string-downcase (symbol-name value)))))
    (t
     (views:html
       (views:object-ref value)))))

(defun render-authored-expression-metadata-row (label value)
  (views:html
    (:tr
     (:th (views:esc label))
     (:td
      (render-authored-expression-metadata-value value)))))

(views:defview 👀overview (reference authored-expression-reference)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:p
       "Deferred authored expression. Normal page rendering stores this reference without executing it. Click the rendered reference or the Evaluate action to run it in the current image; Alt-click opens the reference without evaluation.")
      (:table :class "inspector-table"
              (render-authored-expression-metadata-row
               "Kind"
               (authored-expression-kind-label
                (authored-expression-kind-of reference)))
              (render-authored-expression-metadata-row
               "Expression"
               (authored-expression-expression-of reference))
              (render-authored-expression-metadata-row
               "Package"
               (authored-expression-package-name-of reference))
              (render-authored-expression-metadata-row
               "Selected view"
               (authored-expression-view-title-of reference))
              (render-authored-expression-metadata-row
               "Source page"
               (authored-expression-source-page-title-of reference))
              (render-authored-expression-metadata-row
               "Source tag"
               (authored-expression-source-tag-of reference))))))

(views:defview 👀source (reference authored-expression-reference)
  (views:lisp-code-view
   (views:thunk (authored-expression-expression-of reference))
   :title "Expression"
   :priority 2))

(views:defview 👀overview (issue authored-expression-evaluation-issue)
  (let* ((reference (authored-expression-issue-reference-of issue))
         (condition (authored-expression-issue-condition-of issue)))
    (views:html-view :title "Overview" :priority 1
      (views:html
        (:p :class "hyperdoc-error"
            "Deferred authored-expression evaluation failed. The render path stayed intact and returned this issue object instead of crashing the pane.")
        (:table :class "inspector-table"
                (render-authored-expression-metadata-row
                 "Reference"
                 reference)
                (render-authored-expression-metadata-row
                 "Phase"
                 (authored-expression-issue-phase-of issue))
                (render-authored-expression-metadata-row
                 "Condition type"
                 (type-of condition))
                (render-authored-expression-metadata-row
                 "Condition"
                 condition))))))

(views:defview 👀condition (issue authored-expression-evaluation-issue)
  (views:html-view :title "Condition" :priority 2
    (views:html
      (views:object-ref (authored-expression-issue-condition-of issue)))))

(views:defview 👀reference (issue authored-expression-evaluation-issue)
  (views:html-view :title "Reference" :priority 3
    (views:html
      (views:object-ref (authored-expression-issue-reference-of issue)))))

(defun render-authored-expression-reference
    (reference renderer
     &key (classes "hyperbook-reference hyperdoc-deferred-reference"))
  (let ((html-id (views:html-id "eval-"
                                reference
                                :select (authored-expression-view-title-of reference))))
    (views:html
      (:span :id html-id
             :class classes
             :tabindex 0
             :title (authored-expression-title reference)
             :data-hyperdoc-deferred-expression "true"
             :data-hyperdoc-expression-kind
             (string-downcase
              (symbol-name (authored-expression-kind-of reference)))
             :data-hyperdoc-expression-source
             (authored-expression-expression-of reference)
             :data-hyperdoc-expression-package
             (authored-expression-package-name-of reference)
             :data-hyperdoc-expression-view
             (or (authored-expression-view-title-of reference) "")
             :data-hyperdoc-expression-source-page
             (or (authored-expression-source-page-title-of reference) "")
             (funcall renderer)))))

(defun render-authored-expression-text (reference text
                                        &key (classes "hyperbook-reference hyperdoc-deferred-reference"))
  (render-authored-expression-reference
   reference
   #'(lambda ()
       (views:html
         (views:esc text)))
   :classes classes))

(defun render-authored-expression-children (reference children
                                            &key (classes "hyperbook-reference hyperdoc-deferred-reference"))
  (render-authored-expression-reference
   reference
   #'(lambda ()
       (loop for child across children
             do (plump:serialize-object child)))
   :classes classes))

;;
;; Process special tags
;;

;; in-package: set the current package, no not render

(plump:define-tag-dispatcher (in-package-tag *hyperdoc-tags*) (name)
  (string-equal name "in-package"))

(plump:define-tag-printer in-package-tag (element)
  (setf *current-package*
        (-> element plump:text string-upcase find-package))
  t)

;; value-of: keep the computed value latent during normal page rendering

(plump:define-tag-dispatcher (value-of *hyperdoc-tags*) (name)
  (string-equal name "value-of"))

(plump:define-tag-printer value-of (element)
  (let* ((text (-> element plump:text))
         (reference
           (make-authored-expression-reference
            :kind :value-of
            :expression text
            :raw-source text
            :label (normalize-authored-reference-label text "computed value")
            :source-tag "value-of")))
    (render-authored-expression-text
     reference
     text
     :classes "hyperbook-reference hyperdoc-reference hyperdoc-computed-value hyperdoc-deferred-reference"))
  t)

;; html-expr: preserve the expression as a deferred HTML reference

(plump:define-tag-dispatcher (html-expr *hyperdoc-tags*) (name)
  (string-equal name "html-expr"))

(plump:define-tag-printer html-expr (element)
  (let* ((text (-> element plump:text))
         (reference
           (make-authored-expression-reference
            :kind :html-expr
            :expression text
            :raw-source text
            :label (normalize-authored-reference-label text "computed HTML")
            :source-tag "html-expr")))
    (render-authored-expression-reference
     reference
     #'(lambda ()
         (views:html
           (:span :class "hyperdoc-executable-tag"
                  (views:esc (authored-expression-tag-label "html-expr")))
           " "
           (:tt (views:esc text))))
     :classes "hyperbook-reference hyperdoc-deferred-reference"))
  t)

;; html-generator: preserve the generator as a deferred executable reference

(plump:define-tag-dispatcher (html-generator *hyperdoc-tags*) (name)
  (string-equal name "html-generator"))

(plump:define-tag-printer html-generator (element)
  (let* ((expr (plump:text element))
         (reference
           (make-authored-expression-reference
            :kind :html-generator
            :expression expr
            :raw-source expr
            :label (normalize-authored-reference-label expr "HTML generator")
            :source-tag "html-generator")))
    (render-authored-expression-reference
     reference
     #'(lambda ()
         (views:html
           (:span :class "hyperdoc-executable-tag"
                  (views:esc (authored-expression-tag-label "html-generator")))
           " "
           (:tt (views:esc expr))))
     :classes "hyperbook-reference hyperdoc-deferred-reference"))
  t)

;; view-transclusion: preserve the transclusion expression as deferred

(plump:define-tag-dispatcher (view-transclusion *hyperdoc-tags*) (name)
  (string-equal name "view-transclusion"))

(plump:define-tag-printer view-transclusion (element)
  (let* ((expr (plump:text element))
         (reference
           (make-authored-expression-reference
            :kind :view-transclusion
            :expression expr
            :raw-source expr
            :label (normalize-authored-reference-label expr "view transclusion")
            :source-tag "view-transclusion")))
    (render-authored-expression-reference
     reference
     #'(lambda ()
         (views:html
           (:span :class "hyperdoc-executable-tag"
                  (views:esc (authored-expression-tag-label "view-transclusion")))
           " "
           (:tt (views:esc expr))))
     :classes "hyperbook-reference hyperdoc-deferred-reference"))
  t)

;; source-of-class: preserve the lookup as a deferred source reference

(plump:define-tag-dispatcher (source-of-class *hyperdoc-tags*) (name)
  (string-equal name "source-of-class"))

(plump:define-tag-printer source-of-class (element)
  (let* ((name (plump:text element))
         (expression (format nil "(find-class '~a)" name))
         (reference
           (make-authored-expression-reference
            :kind :source-of-class
            :expression expression
            :raw-source name
            :label (normalize-authored-reference-label name "source of class")
            :source-tag "source-of-class")))
    (render-authored-expression-reference
     reference
     #'(lambda ()
         (views:html
           (:span :class "hyperdoc-executable-tag"
                  (views:esc (authored-expression-tag-label "source-of-class")))
           " "
           (:tt (views:esc name))))
     :classes "hyperbook-reference hyperdoc-deferred-reference"))
  t)

;; source-of-function: preserve the lookup as a deferred source reference

(plump:define-tag-dispatcher (source-of-function *hyperdoc-tags*) (name)
  (string-equal name "source-of-function"))

(plump:define-tag-printer source-of-function (element)
  (let* ((name (plump:text element))
         (expression (format nil "(function ~a)" name))
         (reference
           (make-authored-expression-reference
            :kind :source-of-function
            :expression expression
            :raw-source name
            :label (normalize-authored-reference-label name "source of function")
            :source-tag "source-of-function")))
    (render-authored-expression-reference
     reference
     #'(lambda ()
         (views:html
           (:span :class "hyperdoc-executable-tag"
                  (views:esc (authored-expression-tag-label "source-of-function")))
           " "
           (:tt (views:esc name))))
     :classes "hyperbook-reference hyperdoc-deferred-reference"))
  t)

;; lisp-code: parse text as Lisp, render with syntax highlighting

(plump:define-tag-dispatcher (lisp-code *hyperdoc-tags*) (name)
  (string-equal name "lisp-code"))

(plump:define-tag-printer lisp-code (element)
  (let* ((package-name (plump:attribute element "package"))
         (package (or (and package-name
                           (find-package (str:upcase package-name)))
                      *current-package*)))
    (-> element
        plump:text
        str:trim
        (views/standard:parse-lisp-code package)
        views/standard:render-as-html))
  t)


(plump:define-tag-dispatcher (img *hyperdoc-tags*) (name)
  (string-equal name "img"))

(plump:define-tag-printer img (element)
  (let* ((src (plump:attribute element "src"))
         (uri (handler-case (and src (puri:parse-uri src))
                (error () nil))))
    ;; If the src has a URI scheme, leave as a img element.  If the
    ;; src starts with "/", do the same.  Otherwise, it's a local file
    ;; that a browser cannot access, replace it with a data URL.
    (unless (or (and uri (puri:uri-scheme uri))
                (and src (str:starts-with? "/" src)))
      (let* ((page-base-directory
               (ignore-errors
                 (let ((file-of-symbol (find-symbol "FILE-OF" :hyperbook)))
                   (when (and (boundp 'hb::*current-page*)
                              hb::*current-page*
                              file-of-symbol
                              (fboundp file-of-symbol))
                     (uiop:pathname-directory-pathname
                      (funcall file-of-symbol hb::*current-page*))))))
             (hyperdoc-base-directory
               (ignore-errors
                 (when (and (boundp 'hb::*current-page*)
                            hb::*current-page*)
                   (-> hb::*current-page*
                       (slot-value 'hyperbook)
                       directory-of))))
             (candidate
               (cond ((and src page-base-directory)
                      (merge-pathnames src page-base-directory))
                     ((and src hyperdoc-base-directory)
                      (merge-pathnames src hyperdoc-base-directory))
                     (src
                      (ignore-errors (pathname src)))))
             (existing (and candidate (probe-file candidate))))
        (when existing
          (let* ((bytes (alexandria:read-file-into-byte-vector existing))
                 (encoded (base64:usb8-array-to-base64-string bytes))
                 (image-type (-> existing pathname-type str:downcase))
                 (mime-type (if (equal image-type "jpg") "jpeg" image-type))
                 (data-url (str:concat "data:image/" mime-type ";base64," encoded)))
            (plump:set-attribute element "src" data-url)
            (hb:render-node element))))))
  t)

(defmethod hb:serialize-a-element ((attr (eql ':expr)) element)
  (serialize-a-expr-element element))

(defmethod hb:serialize-a-element ((attr (eql ':expr.view)) element)
  (serialize-a-expr-element element))

(defun serialize-a-expr-element (element)
  (let* ((expr-attr (plump:attribute element "expr"))
         (view-attr (plump:attribute element "view"))
         (render-children (let ((children (plump:children element)))
                            (unless (zerop (length children))
                              children)))
         (label (normalize-authored-reference-label
                 (and render-children
                      (hb::trimmed-node-text element))
                 expr-attr))
         (reference
           (make-authored-expression-reference
            :kind :expr-link
            :expression expr-attr
            :raw-source expr-attr
            :view-title view-attr
            :label label
            :source-tag "a")))
    (if render-children
        (render-authored-expression-children reference render-children)
        (render-authored-expression-reference
         reference
         #'(lambda ()
             (views:html (:tt (views:esc expr-attr))))
         :classes "hyperbook-reference hyperdoc-deferred-reference"))))

;;
;; Content view on HTML pages
;;

(views:defview views:👀content (page html-page)
  (views:html-view :title "Content" :priority 1
    (views:add-asset-path "/hyperbook/"
                          (asdf:system-relative-pathname
                           :hyperbook
                           "assets/hyperbook/"))
    (views:add-asset-path "/hyperdoc/"
                          (asdf:system-relative-pathname
                           :hyperdoc
                           "assets/hyperdoc/"))
    (views:include-css "/hyperbook/css/hyperbook.css")
    (views:include-css "/hyperdoc/css/hyperdoc.css")
    (let ((hb::*current-page* page)
          (*current-package* (find-package "CL-USER")))
      (when-let (dom (dom-of page))
        (render-dom-connect-surface
         page
         "Content"
         #'(lambda ()
             (views:html
               (:div :class "hyperbook-page"
                     (let ((plump:*tag-dispatchers* *hyperdoc-tags*))
                       (plump:serialize dom views::*html-stream*))
                     (:br)))))))))

;;
;; Parse tree view
;;

(views:defview 👀parse-tree (page html-page)
  (-> (dom-of page)
      plump-inspector-views::👀children
      (views:rename :title "Parse tree" :priority 11)))
