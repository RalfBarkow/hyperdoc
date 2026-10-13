;;;; Source definitions only. Runtime reads checked data; no parser or JS execution.
(in-package #:dreyeck/work/trails-rendered-reading)

(defclass javascript-source-definition (trail-source-fragment)
  ((identity :initarg :identity :reader javascript-definition-identity)
   (parent :initform nil :accessor javascript-definition-parent)
   (children :initform nil :accessor javascript-definition-children)))

(defvar *how-trails-definitions* nil)

(defun javascript-utf16-length (string)
  (loop for char across string sum (if (> (char-code char) #xffff) 2 1)))

(defun validate-how-trails-definitions (record bytes)
  "Validate retained extraction against bytes and the bounded source authority."
  (let* ((source (gethash "source" record))
         (script (gethash "script" record))
         (definitions (gethash "definitions" record)))
    (assert (= 1 (gethash "schema" record)))
    (assert (equal (list (gethash "repository" source) (gethash "oid" source))
                   (dreyeck/git:git-revision-identity *how-trails-revision*)))
    (assert (equal (gethash "path" source) (dreyeck/git:git-file-path-of *how-trails-file*)))
    (assert (equal (gethash "sha256" source)
                   "5a513f70546ced3e2af7f83c4f14fb73d30e27f22a295558cbff4b078871aed8"))
    (assert (equal (gethash "sha256" source)
                   (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 bytes))))
    (assert (equal (gethash "version" (gethash "parser" record)) "8.16.0"))
    (assert (equal (gethash "sha256" (gethash "parser" record))
                   "efb0124a960b34d53f9928c4926bfcfd300bb6a3d7ab64ee949b3a8bed1c7e5f"))
    (assert (= 4 (gethash "ordinal" script)))
    (assert (zerop (gethash "ordinalBase" script)))
    (assert (equal "module" (gethash "type" script)))
    (assert (= 1348 (gethash "startByte" script) (gethash "startUtf16" script)))
    (assert (= 19719 (gethash "endByte" script)))
    (assert (= 19715 (gethash "endUtf16" script)))
    (assert (equal (gethash "sha256" script)
                   (ironclad:byte-array-to-hex-string
                    (ironclad:digest-sequence :sha256 (subseq bytes 1348 19719)))))
    (assert (= 3 (length definitions)))
    (loop for def across definitions
          for key in '("composite" "composite/merge" "composite/merge/mergeprops")
          for name in '("composite" "merge" "mergeprops")
          for scope in '("module" "composite" "composite/merge")
          for start-line in '(318 328 330) for end-line in '(378 377 349)
          for parent = nil then previous for previous = def do
      (assert (equal key (gethash "key" def)))
      (assert (equal name (gethash "name" def)))
      (assert (equal scope (gethash "scope" def)))
      (assert (equal (if parent (gethash "key" parent) :null) (gethash "parent" def)))
      (assert (equal "FunctionDeclaration" (gethash "nodeType" def)))
      (let ((start (gethash "fileStartByte" def)) (end (gethash "fileEndByte" def)))
        (assert (and (integerp start) (integerp end) (<= 1348 start) (< start end) (<= end 19719)))
        (assert (equal (gethash "text" def) (babel:octets-to-string (subseq bytes start end) :encoding :utf-8)))
        (when parent
          (assert (< (gethash "fileStartByte" parent) start end (gethash "fileEndByte" parent))))
        (loop for offset in (list start end)
              for file-key in '("fileStartUtf16" "fileEndUtf16")
              for ast-key in '("astStart" "astEnd")
              for line-key in '("startLine" "endLine")
              for column-key in '("startColumn" "endColumn") do
          (let* ((prefix (babel:octets-to-string (subseq bytes 0 offset) :encoding :utf-8))
                 (units (javascript-utf16-length prefix)))
            (assert (= units (gethash file-key def)))
            (assert (= (- units 1348) (gethash ast-key def)))
            (assert (= (1+ (count #\Newline prefix)) (gethash line-key def)))
            (assert (= (javascript-utf16-length (subseq prefix (1+ (or (position #\Newline prefix :from-end t) -1))))
                       (gethash column-key def)))))
        (assert (= start-line (gethash "startLine" def)))
        (assert (= end-line (gethash "endLine" def)))))
    record))

(defun how-trails-composite-definition ()
  (or (first *how-trails-definitions*)
      (let* ((path (following-path "dreyeck/work/how-trails-definitions.json"))
             (digest (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path))))
        (unless (equal digest "fda681aef0844fb25a3050a4d54a7b9e96e32e40f5f82aa62a9e060ec714cdda")
          (error "JavaScript definition data changed; regenerate and review before use."))
        (let* ((record (validate-how-trails-definitions
                        (read-observation "dreyeck/work/how-trails-definitions.json")
                        (alexandria:read-file-into-byte-vector
                         (following-path "assets/hyperbook/fedwiki/mech-host/plugins/solo/dialog/index.html"))))
               (definitions
                 (loop for def across (gethash "definitions" record) collect
                   (make-instance 'javascript-source-definition
                     :identity (append (dreyeck/git:git-revision-identity *how-trails-revision*)
                                       (list (dreyeck/git:git-file-path-of *how-trails-file*)
                                             (gethash "ordinal" (gethash "script" record))
                                             (gethash "astStart" def) (gethash "astEnd" def)))
                     :revision-file *how-trails-file*
                     :metadata (alexandria:plist-hash-table
                                (list "definition" def "script" (gethash "script" record)
                                      "parser" (gethash "parser" record) "source" (gethash "source" record)) :test 'equal)
                     :text (gethash "text" def)))))
          (loop for (parent child) on definitions while child do
            (setf (javascript-definition-children parent) (list child)
                  (javascript-definition-parent child) parent))
          (setf *how-trails-definitions* definitions)
          (first definitions)))))

(defun how-trails-composite-references ()
  (loop for pair being the hash-values of *how-trails-sources*
        append (remove-if-not (lambda (source)
                                (equal "fcbf4b3a2dcbe81b" (hyperbook/fedwiki::id-of (how-source-item source))))
                              (cdr pair))))

(html-inspector-views:defview javascript-definition-view (definition javascript-source-definition)
  (let* ((metadata (fragment-metadata definition))
         (data (gethash "definition" metadata))
         (parent (javascript-definition-parent definition)))
    (html-inspector-views:html-view :title "Function definition" :priority -1
      (html-inspector-views:html
        (:h2 (cl-who:esc (format nil "JavaScript definition: ~A" (gethash "key" data))))
        (:p "Source definition, not an executable function. AST offsets are UTF-16 code units, end exclusive; file bytes are UTF-8. Lines are one-based, columns zero-based. Script ordinal 4 is the fifth script element, a module.")
        (:p (cl-who:esc (format nil "FunctionDeclaration; lexical scope ~A; original lines ~D–~D."
                                (gethash "scope" data) (gethash "startLine" data) (gethash "endLine" data))))
        (:p (html-inspector-views:object-ref (javascript-definition-identity definition) :display "Definition identity")
            " / " (html-inspector-views:object-ref metadata :display "AST spans and extraction provenance"))
        (:p (html-inspector-views:object-ref *how-trails-revision* :select "Evidence revision" :display "Pinned Git revision")
            " / " (html-inspector-views:object-ref (fragment-revision-file definition) :select "Evidence locations" :display "Source file"))
        (when parent
          (html-inspector-views:html
            (:p (html-inspector-views:object-ref parent :select "Function definition" :display "Enclosing definition"))
            (:p "The retained composite witness is not an isolated test of this nested definition.")))
        (:ul (dolist (child (javascript-definition-children definition))
               (html-inspector-views:html
                 (:li (html-inspector-views:object-ref child :select "Function definition"
                        :display (gethash "name" (gethash "definition" (fragment-metadata child))))))))
        (dolist (source (how-trails-composite-references))
          (html-inspector-views:html
            (:p (html-inspector-views:object-ref source :select "Source reference" :display "Ward's referenced range")
                " / " (html-inspector-views:object-ref (how-source-item source) :select "Plan step" :display "Ward's original story item")
                " / " (html-inspector-views:object-ref (how-source-page source) :select "Story" :display "Ward's original page"))))
        (unless parent
          (html-inspector-views:html
            (:p "Retained execution of composite in the original witness; no new execution here. "
                (html-inspector-views:object-ref (how-trails-execution) :display "Composite execution evidence"))))
        (:pre (cl-who:esc (fragment-text definition)))))))

(defmethod html-inspector-views:text-representation ((definition javascript-source-definition))
  (format nil "JavaScript definition ~A" (gethash "key" (gethash "definition" (fragment-metadata definition)))))
