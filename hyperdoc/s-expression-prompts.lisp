;;;; Executable prompt split-view programs.

(in-package :hyperdoc)

(defparameter *s-expression-prompt-kept-tags*
  '("h1" "h2" "h3" "h4" "h5" "h6"
    "p" "ul" "ol" "li" "pre" "code" "blockquote"
    "table" "tr" "th" "td"
    "section" "article" "header" "nav" "details" "summary"
    "a" "in-package" "value-of" "html-expr" "html-generator"
    "view-transclusion" "source-of-function" "source-of-class"))

(defparameter *s-expression-prompt-dangerous-tags*
  '("script" "style"))

(defclass executable-prompt ()
  ((knowledge
    :initarg :knowledge
    :initform nil
    :reader executable-prompt-knowledge-of)
   (input
    :initarg :input
    :initform nil
    :reader executable-prompt-input-of)
   (output-contract
    :initarg :output-contract
    :initform nil
    :reader executable-prompt-output-contract-of)
   (topicmap-program
    :initarg :topicmap-program
    :initform nil
    :accessor executable-prompt-topicmap-program-of)))

(defclass split-view-response ()
  ((fedwiki-story-items
    :initarg :fedwiki-story-items
    :initform nil
    :reader split-view-response-fedwiki-story-items-of)
   (topicmap-program
    :initarg :topicmap-program
    :reader split-view-response-topicmap-program-of)
   (validation-result
    :initarg :validation-result
    :initform nil
    :accessor split-view-response-validation-result-of)))

(defmethod print-object ((prompt executable-prompt) stream)
  (print-unreadable-object (prompt stream :type t :identity nil)
    (format stream "~:[no program~;program~]"
            (executable-prompt-topicmap-program-of prompt))))

(defmethod print-object ((response split-view-response) stream)
  (print-unreadable-object (response stream :type t :identity nil)
    (let ((validation (split-view-response-validation-result-of response)))
      (format stream "~A"
              (or (getf validation :status) :unvalidated)))))

(defun make-executable-prompt (&key knowledge input output-contract
                                    topicmap-program)
  (make-instance 'executable-prompt
                 :knowledge knowledge
                 :input input
                 :output-contract output-contract
                 :topicmap-program topicmap-program))

(defun make-split-view-response (&key fedwiki-story-items topicmap-program
                                      (validate t))
  (let ((response
          (make-instance 'split-view-response
                         :fedwiki-story-items fedwiki-story-items
                         :topicmap-program topicmap-program)))
    (when validate
      (setf (split-view-response-validation-result-of response)
            (validate-split-view-response response)))
    response))

(defun executable-prompt-program-form (prompt)
  `(:executable-prompt
    :version 1
    :layers
    (:knowledge ,(executable-prompt-knowledge-of prompt)
     :input ,(executable-prompt-input-of prompt)
     :output-contract ,(executable-prompt-output-contract-of prompt))
    :topicmap-program ,(executable-prompt-topicmap-program-of prompt)))

(defun s-expression-prompt-trim (string)
  (string-trim '(#\Space #\Tab #\Newline #\Return #\Page)
               (or string "")))

(defun s-expression-prompt-normalize-space (text)
  (let ((raw (s-expression-prompt-trim text)))
    (with-output-to-string (stream)
      (loop with emitted-p = nil
            with pending-space-p = nil
            for char across raw
            do (cond
                 ((find char '(#\Space #\Tab #\Newline #\Return #\Page))
                  (setf pending-space-p t))
                 (t
                  (when (and pending-space-p emitted-p)
                    (write-char #\Space stream))
                  (write-char char stream)
                  (setf emitted-p t
                        pending-space-p nil)))))))

(defun s-expression-prompt-short-text (text &key (limit 120))
  (let ((normalized (s-expression-prompt-normalize-space text)))
    (if (> (length normalized) limit)
        (concatenate 'string (subseq normalized 0 (- limit 3)) "...")
        normalized)))

(defun s-expression-prompt-slug (string)
  (let* ((text (string-downcase (s-expression-prompt-normalize-space string)))
         (chars
           (loop for char across text
                 collect (cond
                           ((or (alphanumericp char) (char= char #\-))
                            char)
                           ((find char " _/:.,()[]{}")
                            #\-)
                           (t nil)))))
    (let ((slug (string-trim '(#\-) (coerce (remove nil chars) 'string))))
      (if (string= slug "") "untitled" slug))))

(defun s-expression-prompt-keyword (string)
  (intern (string-upcase string) :keyword))

(defun s-expression-prompt-plump-symbol (name)
  (let ((package (find-package "PLUMP")))
    (and package (find-symbol name package))))

(defun s-expression-prompt-call-plump (name &rest args)
  (let ((symbol (s-expression-prompt-plump-symbol name)))
    (unless (and symbol (fboundp symbol))
      (error "PLUMP:~A is not loaded. Load a Plump-backed system before parsing HTML."
             name))
    (apply (symbol-function symbol) args)))

(defun s-expression-prompt-call-plump/soft (name &rest args)
  (let ((symbol (s-expression-prompt-plump-symbol name)))
    (when (and symbol (fboundp symbol))
      (ignore-errors
        (apply (symbol-function symbol) args)))))

(defun s-expression-prompt-plump-node-p (object)
  (let ((node-symbol (s-expression-prompt-plump-symbol "NODE")))
    (and node-symbol
         (ignore-errors (typep object node-symbol)))))

(defun s-expression-prompt-parse-html-source (source)
  (s-expression-prompt-call-plump "PARSE" source))

(defun s-expression-prompt-plump-children (node)
  (let ((children (s-expression-prompt-call-plump/soft "CHILDREN" node)))
    (cond
      ((vectorp children)
       (loop for child across children collect child))
      ((listp children)
       children)
      (t nil))))

(defun s-expression-prompt-plump-text (node)
  (or (s-expression-prompt-call-plump/soft "TEXT" node) ""))

(defun s-expression-prompt-plump-tag-name (node)
  (s-expression-prompt-call-plump/soft "TAG-NAME" node))

(defun s-expression-prompt-plump-attribute (node name)
  (s-expression-prompt-call-plump/soft "GET-ATTRIBUTE" node name))

(defun s-expression-prompt-custom-tag-p (tag-name)
  (or (find #\- tag-name)
      (string-equal tag-name "in-package")))

(defun s-expression-prompt-kept-tag-p (tag-name)
  (or (member tag-name *s-expression-prompt-kept-tags* :test #'string-equal)
      (s-expression-prompt-custom-tag-p tag-name)))

(defun s-expression-prompt-dangerous-tag-p (tag-name)
  (member tag-name *s-expression-prompt-dangerous-tags* :test #'string-equal))

(defun s-expression-prompt-link-target (node)
  (let ((hyperbook (s-expression-prompt-plump-attribute node "hyperbook"))
        (page (s-expression-prompt-plump-attribute node "page")))
    (or (and hyperbook page
             (format nil "~A/~A" hyperbook page))
        page
        (s-expression-prompt-plump-attribute node "href")
        (s-expression-prompt-plump-attribute node "expr"))))

(defun s-expression-prompt-node-title (node tag-name)
  (let* ((text (s-expression-prompt-short-text
                (s-expression-prompt-plump-text node)))
         (target (and (string-equal tag-name "a")
                      (s-expression-prompt-link-target node)))
         (identity (or (s-expression-prompt-plump-attribute node "id")
                       (s-expression-prompt-plump-attribute node "data-dm6-slug"))))
    (cond
      ((and target (> (length text) 0))
       (format nil "~A -> ~A" text
               (s-expression-prompt-short-text target :limit 80)))
      (target
       (s-expression-prompt-short-text target :limit 120))
      ((> (length text) 0)
       text)
      (identity
       (s-expression-prompt-short-text identity :limit 120))
      (t
       tag-name))))

(defun s-expression-prompt-source-path (source source-path)
  (or source-path
      (and (pathnamep source) (namestring source))
      (ignore-errors
        (let ((file (file-of source)))
          (and file (namestring file))))))

(defun s-expression-prompt-source-title (source dom source-title)
  (or source-title
      (ignore-errors (title-of source))
      (let ((h1 (first (s-expression-prompt-call-plump/soft
                        "GET-ELEMENTS-BY-TAG-NAME" dom "h1"))))
        (and h1
             (s-expression-prompt-short-text
              (s-expression-prompt-plump-text h1)
              :limit 160)))
      "Untitled executable prompt source"))

(defun s-expression-prompt-page-dom (page)
  (or (let ((dom-symbol (find-symbol "DOM-OF" :hyperdoc)))
        (and dom-symbol
             (fboundp dom-symbol)
             (ignore-errors (funcall (symbol-function dom-symbol) page))))
      (let ((dom-symbol (find-symbol "DOM-OF" :hyperbook)))
        (and dom-symbol
             (fboundp dom-symbol)
             (ignore-errors (funcall (symbol-function dom-symbol) page))))))

(defun s-expression-prompt-source-dom (source)
  (cond
    ((s-expression-prompt-plump-node-p source)
     source)
    ((pathnamep source)
     (s-expression-prompt-parse-html-source source))
    ((stringp source)
     (s-expression-prompt-parse-html-source source))
    (t
     (or (s-expression-prompt-page-dom source)
         (let ((file (ignore-errors (file-of source))))
           (and file
                (uiop:file-exists-p file)
                (s-expression-prompt-parse-html-source file)))
         (error "Cannot derive a Plump DOM from ~S." source)))))

(defun s-expression-prompt-program-get (program key)
  (getf (rest program) key))

(defun topicmap-program-topics (program)
  (copy-tree (s-expression-prompt-program-get program :topics)))

(defun topicmap-program-relations (program)
  (copy-tree (s-expression-prompt-program-get program :relations)))

(defun s-expression-prompt-html-escape (value)
  (with-output-to-string (stream)
    (loop for char across (princ-to-string (or value ""))
          do (case char
               (#\& (write-string "&amp;" stream))
               (#\< (write-string "&lt;" stream))
               (#\> (write-string "&gt;" stream))
               (#\" (write-string "&quot;" stream))
               (t (write-char char stream))))))

(defun s-expression-prompt-sexp-string (object)
  (with-output-to-string (stream)
    (let ((*print-pretty* t)
          (*print-right-margin* 96)
          (*print-readably* t))
      (write object :stream stream))))

(defun s-expression-prompt-read-sexp (text label)
  (let ((*read-eval* nil))
    (multiple-value-bind (object position)
        (read-from-string (or text "") nil :eof)
      (when (eq object :eof)
        (error "Missing embedded S-expression payload for ~A." label))
      (let ((trailing (subseq text position)))
        (unless (string= "" (s-expression-prompt-trim trailing))
          (error "Trailing unreadable payload after embedded ~A: ~S"
                 label trailing)))
      object)))

(defun s-expression-prompt-find-node-by-attribute
    (node attribute &optional expected-value)
  (labels ((matches-p (candidate)
             (let ((value (s-expression-prompt-plump-attribute
                           candidate attribute)))
               (and value
                    (or (null expected-value)
                        (string= value expected-value)))))
           (walk (candidate)
             (or (and (matches-p candidate) candidate)
                 (loop for child in (s-expression-prompt-plump-children
                                     candidate)
                       for found = (walk child)
                       when found return found))))
    (walk node)))

(defun s-expression-prompt-embedded-sexp
    (dom attribute label &optional expected-value)
  (let ((node (s-expression-prompt-find-node-by-attribute
               dom attribute expected-value)))
    (and node
         (s-expression-prompt-read-sexp
          (s-expression-prompt-plump-text node)
          label))))

(defun s-expression-prompt-prompt-layers (prompt)
  (and prompt
       (list :knowledge (executable-prompt-knowledge-of prompt)
             :input (executable-prompt-input-of prompt)
             :output-contract
             (executable-prompt-output-contract-of prompt))))

(defun s-expression-prompt-replay-path-form (path)
  (if path
      (format nil "#P~A"
              (s-expression-prompt-sexp-string
               (namestring (pathname path))))
      "#P\"/path/to/generated-s-expression-prompt.html\""))

(defun s-expression-prompt-path-designator-p (object)
  (or (stringp object)
      (pathnamep object)
      (streamp object)))

(defun s-expression-prompt-add-story-metadata (plist key value)
  (if value
      (append plist (list key value))
      plist))

(defun s-expression-prompt-story-item (&key id text topic-id relation-id)
  (s-expression-prompt-add-story-metadata
   (s-expression-prompt-add-story-metadata
    (list :id id :type :paragraph :text text)
    :topic-id topic-id)
   :relation-id relation-id))

(defun plump-dom-to-topicmap-program
    (dom &key source source-path source-title selected-story-items
              source-evidence operator-task)
  (let* ((title (s-expression-prompt-source-title source dom source-title))
         (path (s-expression-prompt-source-path source source-path))
         (root-id "source-page")
         (topics (list (list :id root-id
                             :kind :source-page
                             :title title
                             :path path
                             :evidence source-evidence)))
         (relations nil)
         (target-topic-ids (make-hash-table :test #'equal))
         (topic-index 0)
         (relation-index 0))
    (labels ((next-topic-id (tag title)
               (incf topic-index)
               (format nil "~A-~D"
                       (s-expression-prompt-slug
                        (format nil "~A ~A" tag title))
                       topic-index))
             (add-topic (kind title &key tag target depth evidence)
               (let ((id (next-topic-id (or tag kind) title)))
                 (push (list :id id
                             :kind kind
                             :title title
                             :target target
                             :depth depth
                             :evidence evidence)
                       topics)
                 id))
             (add-relation (kind from to &key evidence)
               (incf relation-index)
               (let ((id (format nil "~A-~D"
                                 (s-expression-prompt-slug
                                  (symbol-name kind))
                                 relation-index)))
                 (push (list :id id
                             :kind kind
                             :from from
                             :to to
                             :evidence evidence)
                       relations)
                 id))
             (ensure-target-topic (target depth)
               (or (gethash target target-topic-ids)
                   (setf (gethash target target-topic-ids)
                         (add-topic :link-target
                                    (s-expression-prompt-short-text target)
                                    :tag "link-target"
                                    :target target
                                    :depth depth
                                    :evidence (list :target target)))))
             (walk (node parent-id depth)
               (let ((tag-name (s-expression-prompt-plump-tag-name node)))
                 (unless (and tag-name
                              (s-expression-prompt-dangerous-tag-p tag-name))
                   (let ((current-parent parent-id)
                         (current-depth depth))
                     (when (and tag-name
                                (s-expression-prompt-kept-tag-p tag-name))
                       (let* ((title (s-expression-prompt-node-title node tag-name))
                              (target (and (string-equal tag-name "a")
                                           (s-expression-prompt-link-target node)))
                              (topic-id
                                (add-topic
                                 (s-expression-prompt-keyword tag-name)
                                 title
                                 :tag tag-name
                                 :target target
                                 :depth depth
                                 :evidence (list :tag tag-name
                                                 :text title
                                                 :target target))))
                         (add-relation :contains parent-id topic-id
                                       :evidence (list :source-title title
                                                       :depth depth))
                         (when target
                           (add-relation :links-to
                                         topic-id
                                         (ensure-target-topic target (1+ depth))
                                         :evidence (list :target target)))
                         (setf current-parent topic-id
                               current-depth (1+ depth))))
                     (dolist (child (s-expression-prompt-plump-children node))
                       (walk child current-parent current-depth)))))))
      (dolist (child (s-expression-prompt-plump-children dom))
        (walk child root-id 1)))
    `(:topicmap-program
      :version 1
      :source (:type :html
               :path ,path
               :title ,title)
      :input (:selected-story-items ,selected-story-items
              :source-evidence ,source-evidence
              :operator-task ,operator-task)
      :topics ,(nreverse topics)
      :relations ,(nreverse relations)
      :output-contract (:views (:fedwiki-story-view :topic-map-program-view)
                        :validation (:same-topic-ids :same-relation-ids)
                        :replay (:program-is-durable
                                  :story-json-is-projection
                                  :html-is-projection)))))

(defun html-page-to-topicmap-program
    (source &key source-path source-title selected-story-items
                 source-evidence operator-task)
  (let ((dom (s-expression-prompt-source-dom source)))
    (plump-dom-to-topicmap-program
     dom
     :source source
     :source-path source-path
     :source-title source-title
     :selected-story-items selected-story-items
     :source-evidence source-evidence
     :operator-task operator-task)))

(defun hyperdoc-html-to-topicmap-program
    (source &key source-path source-title selected-story-items
                 source-evidence operator-task)
  (let ((dom (s-expression-prompt-source-dom source)))
    (or (s-expression-prompt-embedded-sexp
         dom
         "data-hyperdoc-topicmap-program"
         "topicmap program"
         "true")
        (plump-dom-to-topicmap-program
         dom
         :source source
         :source-path source-path
         :source-title source-title
         :selected-story-items selected-story-items
         :source-evidence source-evidence
         :operator-task operator-task))))

(defun topicmap-program-to-fedwiki-story-items (program)
  (let ((source (s-expression-prompt-program-get program :source))
        (topics (topicmap-program-topics program))
        (relations (topicmap-program-relations program)))
    (append
     (list
      (s-expression-prompt-story-item
       :id "split-view-source"
       :text (format nil "Source: ~A"
                     (or (getf source :path)
                         (getf source :title)
                         "unspecified"))))
     (loop for topic in topics
           collect
           (s-expression-prompt-story-item
            :id (format nil "topic-~A" (getf topic :id))
            :topic-id (getf topic :id)
            :text (format nil "Topic ~A (~A): ~A"
                          (getf topic :id)
                          (getf topic :kind)
                          (getf topic :title))))
     (loop for relation in relations
           collect
           (s-expression-prompt-story-item
            :id (format nil "relation-~A" (getf relation :id))
            :relation-id (getf relation :id)
            :text (format nil "Relation ~A (~A): ~A -> ~A"
                          (getf relation :id)
                          (getf relation :kind)
                          (getf relation :from)
                          (getf relation :to)))))))

(defun s-expression-prompt-story-item-anchor (item position)
  (s-expression-prompt-slug
   (format nil "story ~A"
           (or (getf item :id)
               (getf item :topic-id)
               (getf item :relation-id)
               position))))

(defun s-expression-prompt-write-embedded-form
    (stream id attribute object &key hidden-p)
  (format stream
          "<pre id=\"~A\" data-hyperdoc-embedded-form=\"true\" ~A=\"true\"~:[~; hidden=\"hidden\"~]>~A</pre>~%"
          (s-expression-prompt-html-escape id)
          attribute
          hidden-p
          (s-expression-prompt-html-escape
           (s-expression-prompt-sexp-string object))))

(defun s-expression-prompt-write-story-html (stream story-items)
  (write-string "<ol class=\"s-expression-prompt-story-items\">" stream)
  (loop for item in story-items
        for position from 1
        for item-id = (getf item :id)
        for topic-id = (getf item :topic-id)
        for relation-id = (getf item :relation-id)
        do (format stream
                   "<li id=\"~A\" data-story-item-id=\"~A\"~@[ data-topic-id=\"~A\"~]~@[ data-relation-id=\"~A\"~]>~A</li>~%"
                   (s-expression-prompt-story-item-anchor item position)
                   (s-expression-prompt-html-escape item-id)
                   (and topic-id (s-expression-prompt-html-escape topic-id))
                   (and relation-id
                        (s-expression-prompt-html-escape relation-id))
                   (s-expression-prompt-html-escape (getf item :text))))
  (write-string "</ol>" stream))

(defun s-expression-prompt-sly-mrepl-replay-string (path)
  (format nil
          "(require :asdf)
(asdf:load-system :hyperdoc/s-expression-prompts)

(defparameter *prompt-page-path* ~A)

(defparameter *prompt-program*
  (hyperdoc:hyperdoc-html-to-topicmap-program *prompt-page-path*))

(defparameter *prompt-result*
  (hyperdoc:hyperdoc-html-to-split-view-response *prompt-page-path*))

(defparameter *prompt-materialization*
  (hyperdoc:materialize-s-expression-prompt-page
   *prompt-page-path*
   *prompt-result*
   :if-exists :supersede))

(defparameter *prompt-reloaded-program*
  (hyperdoc:hyperdoc-html-to-topicmap-program *prompt-page-path*))

(defparameter *prompt-reloaded-result*
  (hyperdoc:hyperdoc-html-to-split-view-response *prompt-page-path*))

(defparameter *prompt-program-validation*
  (hyperdoc:validate-topicmap-program-equivalence
   *prompt-program*
   *prompt-reloaded-program*))

(defparameter *prompt-roundtrip-validation*
  (hyperdoc:validate-split-view-response-roundtrip
   *prompt-result*
   *prompt-reloaded-result*))

(assert (getf *prompt-materialization* :success-p))
(assert (getf *prompt-program-validation* :success-p))
(assert (getf *prompt-roundtrip-validation* :success-p))

(format t \"~~&~~S ~~S~~%\"
        (type-of *prompt-reloaded-result*)
        *prompt-roundtrip-validation*)"
          (s-expression-prompt-replay-path-form path)))

(defun s-expression-prompt-inspector-replay-string ()
  "(handler-case
     (progn
       (asdf:load-system :hyperdoc/inspector)
       (format t \"~&Optional HyperDoc inspector loaded.~%\"))
   (condition (condition)
     (format t \"~&Optional HyperDoc inspector load failed; pure split-view replay remains valid: ~A~%\"
             condition)))

(defun i (object)
  \"Safe inspector helper for SLY mREPL.
Prefer CLOG only if it is already loaded; otherwise use CL:INSPECT.
Never calls SLYNK:INSPECT-IN-EMACS directly.\"
  (let* ((clog-package (find-package \"CLOG-MOLDABLE-INSPECTOR\"))
         (clog-symbol
           (and clog-package
                (find-symbol \"CLOG-INSPECT\" clog-package))))
    (cond
      ((and clog-symbol (fboundp clog-symbol))
       (handler-case
           (progn
             (funcall (symbol-function clog-symbol) :object object)
             object)
         (condition (condition)
           (format t \"~&CLOG inspector failed; falling back to CL:INSPECT: ~A~%\"
                   condition)
           (inspect object)
           object)))
      (t
       (inspect object)
       object))))

(i *prompt-reloaded-result*)")

(defun s-expression-prompt-write-pane (stream title class body)
  (format stream
          "<section class=\"s-expression-prompt-pane ~A\"><h2>~A</h2>~A</section>~%"
          (s-expression-prompt-html-escape class)
          (s-expression-prompt-html-escape title)
          body))

(defun topicmap-program-to-hyperdoc-html
    (program &key story-items prompt title validation-result
                  replay-source-path)
  (let* ((story-items (or story-items
                          (topicmap-program-to-fedwiki-story-items program)))
         (source (s-expression-prompt-program-get program :source))
         (title (or title
                    (getf source :title)
                    "S-Expression Prompt Split View"))
         (validation-result
           (or validation-result
               (validate-split-view-response story-items program)))
         (layers (s-expression-prompt-prompt-layers prompt)))
    (with-output-to-string (stream)
      (format stream
              "<h1>~A</h1>~%~%<article class=\"s-expression-prompt-split-view\" data-hyperdoc-s-expression-prompt=\"split-view-response\" data-hyperdoc-materialization-version=\"1\">~%"
              (s-expression-prompt-html-escape title))
      (s-expression-prompt-write-pane
       stream
       "FedWiki story pane"
       "fedwiki-story-pane"
       (with-output-to-string (pane-stream)
         (s-expression-prompt-write-story-html pane-stream story-items)))
      (s-expression-prompt-write-pane
       stream
       "Topicmap program pane"
       "topicmap-program-pane"
       (with-output-to-string (pane-stream)
         (s-expression-prompt-write-embedded-form
          pane-stream
          "s-expression-prompt-topicmap-program"
          "data-hyperdoc-topicmap-program"
          program)))
      (s-expression-prompt-write-pane
       stream
       "Validation pane"
       "validation-pane"
       (with-output-to-string (pane-stream)
         (s-expression-prompt-write-embedded-form
          pane-stream
          "s-expression-prompt-validation-result"
          "data-hyperdoc-validation-result"
          validation-result)))
      (s-expression-prompt-write-pane
       stream
       "SLY mREPL replay pane"
       "sly-mrepl-replay-pane"
       (format nil "<pre><code>~A</code></pre>"
               (s-expression-prompt-html-escape
                (s-expression-prompt-sly-mrepl-replay-string
                 replay-source-path))))
      (s-expression-prompt-write-pane
       stream
       "Optional inspector replay pane"
       "optional-inspector-replay-pane"
       (format nil "<pre><code>~A</code></pre>"
               (s-expression-prompt-html-escape
                (s-expression-prompt-inspector-replay-string))))
      (s-expression-prompt-write-embedded-form
       stream
       "s-expression-prompt-fedwiki-story-items"
       "data-hyperdoc-fedwiki-story-items"
       story-items
       :hidden-p t)
      (when layers
        (s-expression-prompt-write-embedded-form
         stream
         "s-expression-prompt-executable-prompt-layers"
         "data-hyperdoc-executable-prompt-layers"
         layers
         :hidden-p t))
      (write-string "</article>" stream))))

(defun split-view-response-to-hyperdoc-html
    (response &key prompt title replay-source-path)
  (topicmap-program-to-hyperdoc-html
   (split-view-response-topicmap-program-of response)
   :story-items (split-view-response-fedwiki-story-items-of response)
   :prompt prompt
   :title title
   :replay-source-path replay-source-path
   :validation-result (or (split-view-response-validation-result-of response)
                          (validate-split-view-response response))))

(defun executable-prompt-to-hyperdoc-html
    (prompt &key response title replay-source-path)
  (let* ((program (executable-prompt-topicmap-program-of prompt))
         (response (or response
                       (make-split-view-response
                        :fedwiki-story-items
                        (topicmap-program-to-fedwiki-story-items program)
                        :topicmap-program program))))
    (split-view-response-to-hyperdoc-html
     response
     :prompt prompt
     :title title
     :replay-source-path replay-source-path)))

(defun materialize-s-expression-prompt-page
    (pathname response &key prompt title (if-exists :supersede))
  "Materialize RESPONSE as a split-view HyperDoc HTML page at PATHNAME.

Lambda list:
  (materialize-s-expression-prompt-page pathname response
   &key prompt title (if-exists :supersede))

Canonical SLY mREPL call:
  (hyperdoc:materialize-s-expression-prompt-page
   *prompt-page-path*
  *prompt-result*
  :if-exists :supersede)"
  (unless (s-expression-prompt-path-designator-p pathname)
    (error "MATERIALIZE-S-EXPRESSION-PROMPT-PAGE expects the first argument to be a string, pathname, or file stream path designator and the second argument to be a HYPERDOC:SPLIT-VIEW-RESPONSE. Got first argument ~S of type ~S and second argument ~S of type ~S. Did you swap the arguments? Canonical call: (hyperdoc:materialize-s-expression-prompt-page *prompt-page-path* *prompt-result* :if-exists :supersede)."
           pathname
           (type-of pathname)
           response
           (type-of response)))
  (unless (typep response 'split-view-response)
    (if (typep response 'executable-prompt)
        (error "MATERIALIZE-S-EXPRESSION-PROMPT-PAGE expects the second argument to be a HYPERDOC:SPLIT-VIEW-RESPONSE. Got an EXECUTABLE-PROMPT instead. This is the old replay shape; construct or reload the split-view response as *prompt-result* first, then call (hyperdoc:materialize-s-expression-prompt-page *prompt-page-path* *prompt-result* :if-exists :supersede).")
        (error "MATERIALIZE-S-EXPRESSION-PROMPT-PAGE expects the second argument to be a HYPERDOC:SPLIT-VIEW-RESPONSE. Got ~S of type ~S. Did you swap the arguments? Canonical call: (hyperdoc:materialize-s-expression-prompt-page *prompt-page-path* *prompt-result* :if-exists :supersede)."
               response
               (type-of response))))
  (let* ((path (pathname pathname))
         (html
           (split-view-response-to-hyperdoc-html
            response
            :prompt prompt
            :title title
            :replay-source-path path)))
    (ensure-directories-exist path)
    (with-open-file (stream path
                            :direction :output
                            :if-exists if-exists
                            :if-does-not-exist :create
                            :external-format :utf-8)
      (write-string html stream))
    (let* ((reloaded-program (hyperdoc-html-to-topicmap-program path))
           (reloaded-response (hyperdoc-html-to-split-view-response path))
           (program-validation
             (validate-topicmap-program-equivalence
              (split-view-response-topicmap-program-of response)
              reloaded-program))
           (roundtrip-validation
             (validate-split-view-response-roundtrip
              response
              reloaded-response))
           (success-p
             (and (getf program-validation :success-p)
                  (getf roundtrip-validation :success-p))))
      (list :status (if success-p :success :failure)
            :success-p success-p
            :path path
            :program-validation program-validation
            :roundtrip-validation roundtrip-validation
            :shape (if success-p
                       '(:success :materialized-hyperdoc-page
                         :embedded-topicmap-program
                         :reload-equivalent)
                       '(:failure :materialized-hyperdoc-page
                         :reload-mismatch))))))

(defun hyperdoc-html-to-split-view-response (source &key (validate t))
  (let* ((dom (s-expression-prompt-source-dom source))
         (program (hyperdoc-html-to-topicmap-program dom))
         (story-items
           (or (s-expression-prompt-embedded-sexp
                dom
                "data-hyperdoc-fedwiki-story-items"
                "FedWiki story items"
                "true")
               (topicmap-program-to-fedwiki-story-items program))))
    (make-split-view-response
     :fedwiki-story-items story-items
     :topicmap-program program
     :validate validate)))

(defun hyperdoc-html-to-executable-prompt (source)
  (let* ((dom (s-expression-prompt-source-dom source))
         (program (hyperdoc-html-to-topicmap-program dom))
         (layers
           (or (s-expression-prompt-embedded-sexp
                dom
                "data-hyperdoc-executable-prompt-layers"
                "executable prompt layers"
                "true")
               (list :knowledge nil
                     :input (s-expression-prompt-program-get program :input)
                     :output-contract
                     (s-expression-prompt-program-get program
                                                      :output-contract)))))
    (make-executable-prompt
     :knowledge (getf layers :knowledge)
     :input (getf layers :input)
     :output-contract (getf layers :output-contract)
     :topicmap-program program)))

(defun s-expression-prompt-sorted-ids (ids)
  (sort (copy-list (remove nil ids :test #'equal)) #'string<))

(defun s-expression-prompt-id-difference (a b)
  (set-difference a b :test #'equal))

(defun s-expression-prompt-story-topic-ids (story-items)
  (s-expression-prompt-sorted-ids
   (loop for item in story-items
         for topic-id = (getf item :topic-id)
         when topic-id collect topic-id)))

(defun s-expression-prompt-story-relation-ids (story-items)
  (s-expression-prompt-sorted-ids
   (loop for item in story-items
         for relation-id = (getf item :relation-id)
         when relation-id collect relation-id)))

(defun s-expression-prompt-program-topic-ids (program)
  (s-expression-prompt-sorted-ids
   (loop for topic in (topicmap-program-topics program)
         collect (getf topic :id))))

(defun s-expression-prompt-program-relation-ids (program)
  (s-expression-prompt-sorted-ids
   (loop for relation in (topicmap-program-relations program)
         collect (getf relation :id))))

(defun validate-split-view-response (response-or-story-items
                                     &optional topicmap-program)
  (let* ((response (and (typep response-or-story-items 'split-view-response)
                        response-or-story-items))
         (story-items (if response
                          (split-view-response-fedwiki-story-items-of response)
                          response-or-story-items))
         (program (or topicmap-program
                      (and response
                           (split-view-response-topicmap-program-of response))))
         (program-topic-ids (s-expression-prompt-program-topic-ids program))
         (story-topic-ids (s-expression-prompt-story-topic-ids story-items))
         (program-relation-ids (s-expression-prompt-program-relation-ids program))
         (story-relation-ids (s-expression-prompt-story-relation-ids story-items))
         (missing-story-topics
           (s-expression-prompt-id-difference program-topic-ids story-topic-ids))
         (extra-story-topics
           (s-expression-prompt-id-difference story-topic-ids program-topic-ids))
         (missing-story-relations
           (s-expression-prompt-id-difference program-relation-ids
                                              story-relation-ids))
         (extra-story-relations
           (s-expression-prompt-id-difference story-relation-ids
                                              program-relation-ids))
         (topic-pass-p (and (null missing-story-topics)
                            (null extra-story-topics)))
         (relation-pass-p (and (null missing-story-relations)
                               (null extra-story-relations)))
         (success-p (and topic-pass-p relation-pass-p)))
    (list :status (if success-p :success :failure)
          :success-p success-p
          :topic-ids-match-p topic-pass-p
          :relation-ids-match-p relation-pass-p
          :program-topic-ids program-topic-ids
          :story-topic-ids story-topic-ids
          :missing-story-topics missing-story-topics
          :extra-story-topics extra-story-topics
          :program-relation-ids program-relation-ids
          :story-relation-ids story-relation-ids
          :missing-story-relations missing-story-relations
          :extra-story-relations extra-story-relations
          :shape (if success-p
                     '(:success :fedwiki-story-view :topic-map-program-view
                       :validated-crosswalk)
                     '(:failure :crosswalk-mismatch
                       :missing-story-topics :extra-story-topics
                       :missing-story-relations :extra-story-relations)))))

(defun validate-topicmap-program-equivalence (expected actual)
  (let* ((source-pass-p
           (equal (s-expression-prompt-program-get expected :source)
                  (s-expression-prompt-program-get actual :source)))
         (input-pass-p
           (equal (s-expression-prompt-program-get expected :input)
                  (s-expression-prompt-program-get actual :input)))
         (output-contract-pass-p
           (equal (s-expression-prompt-program-get expected :output-contract)
                  (s-expression-prompt-program-get actual :output-contract)))
         (topics-pass-p
           (equal (topicmap-program-topics expected)
                  (topicmap-program-topics actual)))
         (relations-pass-p
           (equal (topicmap-program-relations expected)
                  (topicmap-program-relations actual)))
         (success-p
           (and source-pass-p
                input-pass-p
                output-contract-pass-p
                topics-pass-p
                relations-pass-p)))
    (list :status (if success-p :success :failure)
          :success-p success-p
          :source-match-p source-pass-p
          :input-match-p input-pass-p
          :output-contract-match-p output-contract-pass-p
          :topics-match-p topics-pass-p
          :relations-match-p relations-pass-p
          :expected-topic-ids (s-expression-prompt-program-topic-ids expected)
          :actual-topic-ids (s-expression-prompt-program-topic-ids actual)
          :expected-relation-ids
          (s-expression-prompt-program-relation-ids expected)
          :actual-relation-ids
          (s-expression-prompt-program-relation-ids actual)
          :shape (if success-p
                     '(:success :topicmap-program-equivalent
                       :layers-preserved :topics-preserved
                       :relations-preserved :relation-evidence-preserved)
                     '(:failure :topicmap-program-mismatch
                       :source :input :output-contract
                       :topics :relations)))))

(defun validate-split-view-response-roundtrip (original reloaded)
  (let* ((program-validation
           (validate-topicmap-program-equivalence
            (split-view-response-topicmap-program-of original)
            (split-view-response-topicmap-program-of reloaded)))
         (story-order-pass-p
           (equal (split-view-response-fedwiki-story-items-of original)
                  (split-view-response-fedwiki-story-items-of reloaded)))
         (reloaded-crosswalk
           (validate-split-view-response reloaded))
         (success-p
           (and (getf program-validation :success-p)
                story-order-pass-p
                (getf reloaded-crosswalk :success-p))))
    (list :status (if success-p :success :failure)
          :success-p success-p
          :program-validation program-validation
          :story-order-match-p story-order-pass-p
          :reloaded-crosswalk reloaded-crosswalk
          :shape (if success-p
                     '(:success :split-view-roundtrip
                       :topicmap-program-equivalent
                       :story-item-order-preserved)
                     '(:failure :split-view-roundtrip-mismatch
                       :program-validation
                       :story-order
                       :reloaded-crosswalk)))))

(defun split-view-response-valid-p (response)
  (getf (or (split-view-response-validation-result-of response)
            (validate-split-view-response response))
        :success-p))

(defun topicmap-program-pretty-string (program)
  (with-output-to-string (stream)
    (let ((*print-pretty* t)
          (*print-right-margin* 96))
      (write program :stream stream))))

(defun split-view-response-story-view (response)
  (split-view-response-fedwiki-story-items-of response))

(defun split-view-response-program-view (response)
  (topicmap-program-pretty-string
   (split-view-response-topicmap-program-of response)))
