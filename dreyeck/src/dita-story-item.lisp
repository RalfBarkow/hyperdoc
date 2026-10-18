;;;; Story Items of type "dita": a DITA topic, read as documentation
;;
;; A Federated Wiki Story Item of type "dita" holds one DITA 1.3 topic (concept, reference or task) as the XML text of the Item. The Item keeps the
;; ordinary conventions: "type", "id" and "text" are the Item's own, and two further fields name what the text is: "ditaVersion" and "infoType" (the
;; root element, stated explicitly so that no reader has to guess). Nothing here writes, validates or edits: the Inspector reads the Item.
;;
;;   Story item     the generic view of LOCAL-STORY-ITEM: the XML text and the Item JSON, as the file holds them (the source)
;;   DITA topic     this file's view: the same text as a structured reading (the topic, not the markup)
;;
;; The structured reading knows the elements the topics of this repository use. An element it does not know is shown by name, marked as unsupported,
;; and never dropped silently. A cross reference (xref) whose href has the scheme "hyperdoc:" names an Inspector object, not a URL; see
;; DEFINE-HYPERDOC-REFERENCE. Anything else is a link or plain text. A later DITA editor would be a plugin of the type; this file is only the reading.

(in-package #:dreyeck/dita-story-item)

(defclass dita-story-item (lp:local-story-item) ()
  (:documentation "A Story Item of type \"dita\": one DITA topic as XML text."))

(setf (gethash "dita" lp:*story-item-classes*) 'dita-story-item)

(defun dita-item-xml (item) (lp:story-item-text item))
(defun dita-item-info-type (item) (gethash "infoType" (lp:story-item-json item)))
(defun dita-item-version (item) (gethash "ditaVersion" (lp:story-item-json item)))

(define-condition dita-topic-unreadable (error)
  ((reason :initarg :reason :reader dita-topic-unreadable-reason))
  (:report (lambda (condition stream) (format stream "The DITA topic cannot be read: ~A" (dita-topic-unreadable-reason condition)))))

;;; Parsing

(defun parse-dita-topic (xml)
  "The root element of the DITA topic XML, a PLUMP node. Well-formedness and the DITA grammar are checked by the validation of the Items (see the tests),
not here; this refuses only what it cannot read at all."
  (let* ((document (let ((plump:*tag-dispatchers* plump:*xml-tags*)) (plump:parse xml)))
         (root (find-if #'plump:element-p (plump:children document))))
    (unless root (error 'dita-topic-unreadable :reason "the text has no root element"))
    root))

(defun %decode (text)
  (let ((result text))
    (loop for (entity character) in '(("&lt;" "<") ("&gt;" ">") ("&quot;" "\"") ("&apos;" "'") ("&amp;" "&"))
          do (setf result (str:replace-all entity character result)))
    result))

(defun %elements (node name)
  (coerce (remove-if-not (lambda (child) (and (plump:element-p child) (string= name (plump:tag-name child)))) (plump:children node)) 'list))
(defun %element (node name) (first (%elements node name)))
(defun %text (node)
  (cond ((plump:text-node-p node) (%decode (plump:text node)))
        ((plump:element-p node) (apply #'concatenate 'string (map 'list #'%text (plump:children node))))
        (t "")))

(defun dita-topic-title (root)
  "The title of the topic ROOT."
  (let ((title (%element root "title"))) (if title (string-trim '(#\Space #\Newline #\Tab) (%text title)) "")))

;;; References to Inspector objects: href="hyperdoc:KIND:ARGUMENT"

(defvar *hyperdoc-references* (make-hash-table :test #'equal)
  "KIND -> a function of the ARGUMENT string and the CONTEXT (a function of an Item id, or NIL) that returns the object or, where this image does not have it, a
string that says so. A hyperdoc: reference opens that object; it never evaluates anything the document supplies.")

(defmacro define-hyperdoc-reference (kind (argument context) &body body)
  `(setf (gethash ,kind *hyperdoc-references*) (lambda (,argument ,context) (declare (ignorable ,argument ,context)) ,@body)))

(defun resolve-hyperdoc-reference (href &optional context)
  "The object the hyperdoc: reference HREF names, or a string that says why this image has none."
  (let* ((rest (subseq href (length "hyperdoc:")))
         (colon (position #\: rest))
         (kind (subseq rest 0 colon))
         (argument (if colon (subseq rest (1+ colon)) ""))
         (resolver (gethash kind *hyperdoc-references*)))
    (if resolver
        (handler-case (funcall resolver argument context)
          (error (condition) (format nil "The reference ~A could not be resolved here: ~A" href condition)))
        (format nil "The reference ~A names no known kind of object (~{~A~^, ~})." href
                (sort (loop for key being the hash-keys of *hyperdoc-references* collect key) #'string<)))))

(defun %package-symbol (argument)
  "The symbol of ARGUMENT, \"PACKAGE:NAME\", if this image has both; otherwise NIL and the reason."
  (let* ((colon (position #\: argument :from-end t))
         (package (and colon (find-package (string-upcase (subseq argument 0 colon)))))
         (symbol (and package (find-symbol (string-upcase (subseq argument (1+ colon))) package))))
    (if symbol
        (values symbol nil)
        (values nil (format nil "~A is not in this image: the system that defines it is not loaded in this Catalog." argument)))))

(define-hyperdoc-reference "class" (argument context)
  (multiple-value-bind (symbol reason) (%package-symbol argument)
    (or (and symbol (find-class symbol nil)) reason (format nil "~A names no class." argument))))
(define-hyperdoc-reference "function" (argument context)
  (multiple-value-bind (symbol reason) (%package-symbol argument)
    (or (and symbol (fboundp symbol) (fdefinition symbol)) reason (format nil "~A names no function." argument))))
(define-hyperdoc-reference "variable" (argument context)
  (multiple-value-bind (symbol reason) (%package-symbol argument)
    (if (and symbol (boundp symbol)) (symbol-value symbol) (or reason (format nil "~A names no variable." argument)))))
(define-hyperdoc-reference "operation" (argument context)
  ;; The identity of a gesture Operation, by the name of its constructor in the Gesture/Binding witness: inspect-topicmap-sign, ...
  (let ((symbol (find-symbol (string-upcase (format nil "~A-OPERATION" argument)) "DREYECK/GESTURE-BINDING-WITNESS")))
    (if (and symbol (fboundp symbol)) (funcall symbol) (format nil "No Operation ~A is defined by the Gesture/Binding witness of this image." argument))))
(define-hyperdoc-reference "system" (argument context)
  (or (asdf:find-system argument nil) (format nil "No ASDF system ~A is known to this image." argument)))
(define-hyperdoc-reference "item" (argument context)
  ;; Another Item of the same page, by id.
  (or (and context (funcall context argument)) (format nil "No Item ~A on the page of this topic." argument)))

(defvar *dita-examples* (make-hash-table :test #'equal)
  "NAME -> a function of no arguments that returns the object of the worked example NAME, or a string that says why this image has none. The systems that can
build an example register it (see DEFINE-DITA-EXAMPLE); a Catalog without that system gets the explanation.")

(defmacro define-dita-example (name () &body body)
  `(setf (gethash ,name *dita-examples*) (lambda () ,@body)))

(define-hyperdoc-reference "example" (argument context)
  (let ((example (gethash argument *dita-examples*)))
    (if example
        (funcall example)
        (format nil "The example ~A is not available in this Catalog: the system that builds it (dreyeck/item-edit-ctm, a local review system) is not loaded." argument))))

;;; Reading a topic as HTML

(defmacro html-string (&body body)
  "The HTML that BODY writes, as a string. V:HTML writes to the stream of the view being built; the pieces of a topic are composed as strings."
  `(with-output-to-string (stream)
     (let ((v::*html-stream* stream))
       (v:html ,@body))))

(defparameter +supported-elements+
  '("concept" "reference" "task" "topic" "title" "shortdesc" "conbody" "refbody" "taskbody" "body" "section" "example" "context" "prereq" "postreq"
    "result" "steps" "step" "cmd" "info" "stepresult" "p" "ul" "ol" "li" "dl" "dlentry" "dt" "dd" "codeblock" "codeph" "b" "i" "ph" "term" "keyword"
    "apiname" "filepath" "cmdname" "varname" "note" "xref" "simpletable" "sthead" "strow" "stentry")
  "The elements the structured reading knows. Any other element is shown by name and marked, and DITA-UNSUPPORTED-ELEMENTS lists it.")

(defun dita-unsupported-elements (xml)
  "The names of the elements of the topic XML that the structured reading does not support, in the order met, once each."
  (let ((found nil))
    (labels ((walk (node)
               (when (plump:element-p node)
                 (unless (member (plump:tag-name node) +supported-elements+ :test #'string=)
                   (pushnew (plump:tag-name node) found :test #'string=))
                 (map nil #'walk (plump:children node)))))
      (walk (parse-dita-topic xml)))
    (reverse found)))

(defun %kids (node context) (apply #'concatenate 'string (map 'list (lambda (child) (%node child context)) (plump:children node))))

(defun %inline (class node context)
  (html-string (:span :class class (v:str (%kids node context)))))

(defun %xref (node context)
  (let ((href (plump:attribute node "href")) (label (string-trim '(#\Space #\Newline #\Tab) (%text node))))
    (cond ((and href (str:starts-with? "hyperdoc:" href))
           (html-string (:span :class "dita-xref" :style "text-decoration:underline" :title href (v:object-ref (resolve-hyperdoc-reference href context) :display label))))
          ((and href (or (str:starts-with? "https://" href) (str:starts-with? "http://" href)))
           (html-string (:a :href href :target "_blank" (v:esc label))))
          (t (html-string (:span :class "dita-xref" :title (or href "") (v:esc label)))))))

(defun %simple-table (node context)
  (let ((header (%element node "sthead")))
    (html-string
      (:table :class "inspector-table dita-simpletable"
        (when header
          (v:html (:tr (dolist (cell (%elements header "stentry")) (v:html (:th (v:str (%kids cell context))))))))
        (dolist (row (%elements node "strow"))
          (v:html (:tr (dolist (cell (%elements row "stentry")) (v:html (:td (v:str (%kids cell context))))))))))))

(defun %node (node context)
  (cond
    ((plump:text-node-p node) (cl-who:escape-string (%decode (plump:text node))))
    ((not (plump:element-p node)) "")
    (t
     (let ((name (plump:tag-name node)) (kids (%kids node context)))
       (cond
         ((member name '("concept" "reference" "task" "topic") :test #'string=) (html-string (:article :class (format nil "dita-topic dita-~A" name) (v:str kids))))
         ((string= name "title") (html-string (:h3 :class "dita-title" (v:str kids))))
         ((string= name "shortdesc") (html-string (:p :class "dita-shortdesc" (:em (v:str kids)))))
         ((member name '("conbody" "refbody" "taskbody" "body") :test #'string=) (html-string (:div :class (format nil "dita-~A" name) (v:str kids))))
         ((string= name "steps") (html-string (:ol :class "dita-steps" (v:str kids))))
         ((member name '("section" "example" "context" "prereq" "postreq" "result" "info" "stepresult") :test #'string=)
          (html-string (:section :class (format nil "dita-~A" name) (v:str kids))))
         ((string= name "p") (html-string (:p (v:str kids))))
         ((string= name "ul") (html-string (:ul (v:str kids))))
         ((string= name "ol") (html-string (:ol (v:str kids))))
         ((string= name "li") (html-string (:li (v:str kids))))
         ((string= name "dl") (html-string (:dl (v:str kids))))
         ((string= name "dlentry") kids)
         ((string= name "dt") (html-string (:dt (v:str kids))))
         ((string= name "dd") (html-string (:dd (v:str kids))))
         ((string= name "step") (html-string (:li :class "dita-step" (v:str kids))))
         ((string= name "cmd") (html-string (:strong :class "dita-cmd" (v:str kids))))
         ((string= name "codeblock") (html-string (:pre :class "dita-codeblock" (v:str kids))))
         ((string= name "codeph") (html-string (:code (v:str kids))))
         ((string= name "b") (html-string (:strong (v:str kids))))
         ((string= name "i") (html-string (:em (v:str kids))))
         ((member name '("filepath" "apiname" "cmdname" "varname") :test #'string=) (html-string (:code :class (format nil "dita-~A" name) (v:str kids))))
         ((member name '("ph" "term" "keyword") :test #'string=) (%inline (format nil "dita-~A" name) node context))
         ((string= name "note") (html-string (:div :class "dita-note" (:strong (v:esc (format nil "~:(~A~): " (or (plump:attribute node "type") "note")))) (v:str kids))))
         ((string= name "xref") (%xref node context))
         ((string= name "simpletable") (%simple-table node context))
         ((member name '("sthead" "strow" "stentry") :test #'string=) kids)
         (t (html-string (:span :class "dita-unsupported" :style "background:#fdd"
                                (v:esc (format nil "<~A> is not supported by the structured reading: " name)) (v:str kids)))))))))

(defun render-dita-topic (xml &optional context)
  "The structured reading of the DITA topic XML as an HTML string. CONTEXT, a function of an Item id, resolves hyperdoc:item: references to the Items of the
same page. Call it while a view is being built: the object references belong to it."
  (%node (parse-dita-topic xml) context))

;;; Views

(defun %item-context (item)
  (let ((source (lp:story-item-source item)))
    (lambda (id) (lp:find-story-item source id))))

(v:defview dita-topic-view (item dita-story-item)
  (v:html-view :title "DITA topic" :priority -2
    (let ((xml (dita-item-xml item)))
      (v:html
        (:table :class "inspector-table"
          (:tr (:td "Information type") (:td (v:esc (or (dita-item-info-type item) "not stated"))))
          (:tr (:td "DITA version") (:td (v:esc (or (dita-item-version item) "not stated"))))
          (:tr (:td "Item id") (:td (:code (v:esc (lp:story-item-id item))))))
        (:p "The structured reading of this Item. The XML text is the " (v:object-ref item :display "Story item" :select "Story item")
            " view; the reading is of the text as it stands, nothing is validated here.")
        (handler-case (v:str (render-dita-topic xml (%item-context item)))
          (dita-topic-unreadable (condition) (v:html (:p (v:esc (princ-to-string condition))))))))))

;; The page's own Content view: a Story Item of type dita is read as the topic, not as a block of text.
(defmethod hyperbook/fedwiki::render-story-item ((type (eql :dita)) item page)
  (v:html
    (:div :class "dita-story-item"
          (:p (:small (v:esc (format nil "DITA ~A, Item ~A" (or (let ((data (hyperbook/fedwiki::data-of item))) (and data (gethash "infoType" data))) "topic") (hyperbook/fedwiki::id-of item)))))
          (handler-case (v:str (render-dita-topic (hyperbook/fedwiki::text-of item)
                                                  (let ((source (and (typep page 'lp:local-fedwiki-page) (ignore-errors (lp:local-fedwiki-page-source-of page)))))
                                                    (and source (lambda (id) (lp:find-story-item source id))))))
            (dita-topic-unreadable (condition) (v:html (:p (v:esc (princ-to-string condition)))))))))
