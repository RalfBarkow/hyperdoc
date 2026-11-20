;;;; Code paths into page-attached code: where this image could make ASDF see or evaluate code that arrived with a
;;;; wiki page, and whether each place passes the execution guard. Read-only: it asks SBCL's cross-reference data
;;;; and reads source files; it loads, compiles and evaluates nothing.
(defpackage #:codepath-review
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views) (#:dita #:dreyeck/dita-story-item)
                    (#:policy #:dreyeck/authority-policy) (#:hb #:hyperbook) (#:tm #:dreyeck/topicmap))
  (:export #:analyze #:*analysis* #:analysis-sinks #:analysis-nodes #:analysis-edges #:analysis-text-only
           #:node-name #:node-status #:node-guard #:node-role #:path-status #:open-task #:call-graph))
(in-package #:codepath-review)

;;; What counts. A page's .asd becomes visible to ASDF only where something puts a page's asset directory on a
;;; registry (binding or setting ASDF:*CENTRAL-REGISTRY*), or loads an .asd by path (ASDF:LOAD-ASD). Every later
;;; ASDF:FIND-SYSTEM or LOAD-SYSTEM happens inside such an extent, so the places that open it are the sinks.

(defparameter +sink-variables+ '(asdf:*central-registry*))
(defparameter +sink-functions+ '(asdf:load-asd asdf:initialize-source-registry))
(defparameter +text-sink-pattern+ '("load-asd" "central-registry" "source-registry"))
(defparameter +guard-substring+ "EXECUTION-PERMITTED-P"
  "A function whose name contains this is a guard; a definition that mentions it in its text checks it.")
(defvar *excluded-package-prefixes* '("ASDF" "UIOP" "SB-" "SWANK" "SLYNK" "COMMON-LISP" "CODEPATH-REVIEW" "CPR-FIXTURE")
  "Packages left out. This reading and its test fixture are left out, so that they never count as findings.")
(defvar *max-depth* 5)

(defun scoped-package-p (package)
  (and package
       (let ((name (package-name package)))
         (notany (lambda (prefix) (uiop:string-prefix-p prefix name)) *excluded-package-prefixes*))))

(defun function-name-of (spec)
  "The name in an SB-INTROSPECT xref entry: a symbol, (SETF symbol), or NIL for methods and lambdas we cannot place."
  (let ((name (if (consp spec) (car spec) spec)))
    (cond ((symbolp name) name)
          ((and (consp name) (eq (first name) 'setf)) name)
          ((and (consp name) (member (first name) '(sb-pcl::fast-method sb-pcl::slow-method)))
           (let ((gf (second name))) (if (symbolp gf) gf nil)))
          (t nil))))

(defun name-package (name)
  (symbol-package (if (consp name) (second name) name)))

(defun scoped-names (specs)
  (remove-duplicates (remove-if-not (lambda (n) (and n (scoped-package-p (name-package n))))
                                    (mapcar #'function-name-of specs))
                     :test #'equal))

(defun xref-callers (name)
  (scoped-names (ignore-errors (sb-introspect:who-calls name))))

;;; Source text

(defun definition-location (name)
  (let ((source (first (ignore-errors (sb-introspect:find-definition-sources-by-name name :function)))))
    (and source (sb-introspect:definition-source-pathname source)
         (list (sb-introspect:definition-source-pathname source)
               (sb-introspect:definition-source-character-offset source)))))

(defvar *file-texts* nil "Pathname namestring -> file text, filled per analysis.")

(defun file-text (path)
  (unless *file-texts* (return-from file-text (handler-case (uiop:read-file-string path :external-format :utf-8) (error () ""))))
  (let ((key (namestring path)))
    (or (gethash key *file-texts*)
        (setf (gethash key *file-texts*)
              (handler-case (uiop:read-file-string path :external-format :utf-8) (error () ""))))))

(defun form-end (text start)
  (let ((*read-suppress* t) (*package* (find-package '#:codepath-review)))
    (handler-case (nth-value 1 (read-from-string text t nil :start start)) (error () (length text)))))

(defun toplevel-start (text offset)
  "The start of the top-level form at OFFSET: OFFSET itself when it is a paren in column 0, else the last line
before it that starts with a paren."
  (let ((offset (min (max 0 offset) (max 0 (1- (length text))))))
    (if (and (< offset (length text)) (char= #\( (char text offset)) (or (zerop offset) (char= #\Newline (char text (1- offset)))))
        offset
        (let ((at (search (format nil "~%(") text :end2 (min (length text) (1+ offset)) :from-end t)))
          (if at (1+ at) 0)))))

(defun definition-text (name)
  "(values TEXT PATHNAME) for the top-level form that defines NAME, or NIL. The form is found by its defined name in
the file SBCL records for NAME, nearest to the recorded offset; the offset alone can point at a neighbour."
  (let ((location (definition-location name)))
    (when location
      (destructuring-bind (path offset) location
        (let* ((text (file-text path))
               (symbol-name (symbol-name (if (consp name) (second name) name)))
               (candidates (remove-if-not (lambda (form) (equal (third form) symbol-name)) (file-forms path)))
               (form (first (sort (copy-list candidates) #'<
                                  :key (lambda (form) (abs (- (first form) (or offset 0))))))))
          (cond (form (values (subseq text (first form) (second form)) path))
                ((plusp (length text))
                 (let ((start (toplevel-start text (or offset 0))))
                   (values (subseq text start (form-end text start)) path)))))))))

(defun mentions-p (text needle) (and text (search needle text :test #'char-equal)))

;;; Text index over the loaded sources under the dreyeck system directory

(defvar *include-self* nil "True only in the tests: scan this reading's own files too.")
(defvar *extra-source-files* nil "Namestrings of further files to scan, for the tests.")
(defun self-directory () (asdf:system-source-directory "codepath-review"))

(defun scoped-source-files ()
  (let ((root (asdf:system-source-directory "dreyeck")) (files nil))
    (dolist (name (asdf:already-loaded-systems))
      (let ((system (asdf:find-system name nil)))
        (when system
          (labels ((walk (c) (typecase c
                               (asdf:cl-source-file (push (asdf:component-pathname c) files))
                               (asdf:parent-component (mapc #'walk (asdf:component-children c))))))
            (walk system)))))
    (remove-duplicates (remove-if-not (lambda (p) (and p (probe-file p)
                                                       (or (member (namestring p) *extra-source-files* :test #'string=)
                                                           (and (uiop:subpathp p root)
                                                                (or *include-self* (not (uiop:subpathp p (self-directory))))))))
                                      files)
                       :test #'equal :key #'namestring)))

(defparameter +definers+ '("defun" "defmacro" "defmethod" "defgeneric" "defvar" "defparameter" "define-condition"))

(defun definer-name (form-text)
  "The defined name of a top-level form text such as (DEFUN foo ...), as a string, or NIL."
  (let* ((open (position #\( form-text))
         (head-end (and open (position-if (lambda (c) (member c '(#\Space #\Newline #\Tab))) form-text :start open)))
         (head (and head-end (string-downcase (subseq form-text (1+ open) head-end))))
         (head (and head (subseq head (1+ (or (position #\: head :from-end t) -1))))))
    (when (and head (member head +definers+ :test #'string=))
      (let* ((start (position-if-not (lambda (c) (member c '(#\Space #\Newline #\Tab))) form-text :start head-end))
             (end (and start (position-if (lambda (c) (member c '(#\Space #\Newline #\Tab #\( #\)))) form-text :start start))))
        (and start end (string-upcase (subseq form-text start end)))))))

(defun file-forms (path)
  "(start end name package-name) for each top-level form of PATH, tracking IN-PACKAGE."
  (let ((text (file-text path)) (forms nil) (package "CL-USER") (at 0))
    (loop
      (let ((start (position #\( text :start at)))
        (unless start (return))
        (if (and (plusp start) (not (char= #\Newline (char text (1- start)))))
            (setf at (1+ start))
            (let* ((end (form-end text start)) (form (subseq text start end))
                   (name (definer-name form)))
              (when (and (< (length form) 200) (search "in-package" form :test #'char-equal))
                (let ((p (string-trim '(#\# #\: #\" #\' #\Space #\) #\Newline #\Tab #\Return)
                                      (subseq form (+ (search "in-package" form :test #'char-equal) 10)))))
                  (setf package (string-upcase p))))
              (push (list start end name package) forms)
              (setf at (max (1+ start) end))))))
    (nreverse forms)))

(defun resolve-name (string package-name)
  (let* ((colon (position #\: string :from-end t))
         (pkg (if colon (find-package (string-trim ":" (subseq string 0 (position #\: string)))) (find-package package-name)))
         (sym (and pkg (find-symbol (subseq string (if colon (1+ colon) 0)) pkg))))
    (and sym (fboundp sym) sym)))

(defstruct text-hit path name form-text pattern)

(defun text-hits (needles files &key exclude)
  "Top-level definitions in FILES whose text mentions one of NEEDLES (case-insensitive), except EXCLUDE (a name)."
  (let ((hits nil))
    (dolist (path files)
      (let ((text (file-text path)))
        (when (some (lambda (n) (mentions-p text n)) needles)
          (dolist (form (file-forms path))
            (destructuring-bind (start end name package) form
              (let* ((form-text (subseq text start end))
                     (needle (find-if (lambda (n) (mentions-p form-text n)) needles)))
                (when needle
                  (let ((symbol (let ((sym (and name (resolve-name name package))))
                                  (and sym (scoped-package-p (symbol-package sym)) sym))))
                    (unless (and exclude symbol (equal symbol exclude))
                      (push (make-text-hit :path path :name (or symbol name) :form-text form-text :pattern needle)
                            hits))))))))))
    (nreverse hits)))

;;; Nodes and edges

(defstruct node
  name            ; function name (symbol or (setf symbol)) or a string for a form we could not resolve
  role            ; :sink, :caller or :text-only
  guard           ; :xref, :text or NIL
  status          ; path status, see PATH-STATUS
  sources         ; how the node was found: :xref, :text
  path)           ; source file

(defstruct edge from to via) ; FROM calls TO; VIA :xref or :text

(defstruct analysis time revision sinks nodes edges text-only guards files)

(defun guard-functions ()
  (let ((guards nil))
    (do-all-symbols (s)
      (when (and (fboundp s) (scoped-package-p (symbol-package s)) (search +guard-substring+ (symbol-name s)))
        (pushnew s guards)))
    guards))

(defun guard-of (name guard-callers)
  (cond ((member name guard-callers :test #'equal) :xref)
        ((mentions-p (definition-text name) +guard-substring+) :text)))

(defun sink-names ()
  (remove-duplicates
   (append (loop for var in +sink-variables+
                 append (scoped-names (append (ignore-errors (sb-introspect:who-binds var))
                                              (ignore-errors (sb-introspect:who-sets var)))))
           (loop for fn in +sink-functions+ append (xref-callers fn)))
   :test #'equal))

(defun text-callers (name files)
  "Definitions whose text names NAME's symbol, other than NAME itself: callers xref may not see."
  (let ((needle (string-downcase (symbol-name (if (consp name) (second name) name)))))
    (remove-if-not (lambda (hit) (and (symbolp (text-hit-name hit)) (fboundp (text-hit-name hit))))
                   (text-hits (list needle) files :exclude name))))

(defun source-revision ()
  (let ((root (asdf:system-source-directory "dreyeck")))
    (or (uiop:getenv "HYPERDOC_SOURCE_REVISION")
        (ignore-errors (uiop:run-program (list "git" "-C" (namestring root) "rev-parse" "HEAD")
                                         :output '(:string :stripped t)))
        "nicht ermittelt")))

(defun analyze (&key (max-depth *max-depth*))
  "Find the sinks, walk their callers up to MAX-DEPTH by xref and by text, and classify every node."
  (let* ((*file-texts* (make-hash-table :test #'equal))
         (files (scoped-source-files))
         (guards (guard-functions))
         (guard-callers (loop for g in guards append (xref-callers g)))
         (nodes (make-hash-table :test #'equal))
         (edges nil)
         (sinks (sink-names)))
    (labels ((node (name role source)
               (let ((n (or (gethash name nodes)
                            (setf (gethash name nodes)
                                  (make-node :name name :role role :guard (guard-of name guard-callers)
                                             :path (second (multiple-value-list (definition-text name))))))))
                 (pushnew source (node-sources n))
                 n))
             (walk (name depth)
               (when (< depth max-depth)
                 (let ((xref (xref-callers name))
                       (text (mapcar #'text-hit-name (text-callers name files))))
                   (dolist (caller (remove-duplicates (append xref text) :test #'equal))
                     (unless (or (equal caller name) (member caller guards))
                       (let ((new (null (gethash caller nodes))))
                         (node caller :caller (if (member caller xref :test #'equal) :xref :text))
                         (pushnew (make-edge :from caller :to name
                                             :via (if (member caller xref :test #'equal) :xref :text))
                                  edges :test #'equalp)
                         (when new (walk caller (1+ depth))))))))))
      (dolist (sink sinks) (node sink :sink :xref))
      ;; Text sinks: definitions that mention LOAD-ASD or a registry but that xref did not report, for example a
      ;; form that builds an SBCL command line for another process, or a docstring. They are read by a person.
      (let* ((hits (text-hits +text-sink-pattern+ files))
             (text-sinks (remove-duplicates
                          (loop for hit in hits
                                for name = (text-hit-name hit)
                                when (and (symbolp name) name (not (member name sinks :test #'equal)))
                                  collect name)
                          :test #'equal))
             (text-only (remove-if (lambda (hit) (and (text-hit-name hit) (symbolp (text-hit-name hit)))) hits)))
        (dolist (name text-sinks) (node name :text-sink :text))
        (dolist (sink sinks) (walk sink 0))
        ;; A text finding is a hint to read; its callers are followed less far, so that it does not crowd the map.
        (dolist (sink text-sinks) (walk sink (max 0 (- max-depth 2))))
        (setf sinks (append sinks text-sinks))
        (let ((analysis (make-analysis :time (get-universal-time) :revision (source-revision)
                                       :sinks sinks :nodes nil :edges edges
                                       :text-only text-only :guards guards :files (length files))))
          (setf (analysis-nodes analysis) (loop for n being the hash-values of nodes collect n))
          (dolist (n (analysis-nodes analysis))
            (setf (node-status n) (if (member (node-role n) '(:sink :text-sink))
                                      (path-status analysis (node-name n))
                                      (coverage analysis (node-name n)))))
          analysis)))))

(defun find-node (analysis name) (find name (analysis-nodes analysis) :key #'node-name :test #'equal))

(defun neighbours (analysis name direction via)
  "Callers (DIRECTION :CALLERS) or callees (:CALLEES) of NAME over edges found by VIA (:XREF, :TEXT or :ANY)."
  (remove-duplicates
   (loop for e in (analysis-edges analysis)
         when (and (or (eq via :any) (eq via (edge-via e)))
                   (equal name (if (eq direction :callers) (edge-to e) (edge-from e))))
           collect (if (eq direction :callers) (edge-from e) (edge-to e)))
   :test #'equal))

(defun callers-of (analysis name &optional (via :any)) (neighbours analysis name :callers via))
(defun callees-of (analysis name &optional (via :any)) (neighbours analysis name :callees via))

(defun sink-role-p (node) (member (node-role node) '(:sink :text-sink)))

(defun worst (statuses order)
  (or (find-if (lambda (s) (member s statuses)) order) (first (last order))))

(defun path-status (analysis name &optional seen)
  "For a sink, over cross-reference edges only: :GUARDED when it checks the guard itself; :PROTECTED when every caller
chain reaches a guard; :OPEN when an unguarded chain reaches a definition that is not itself a sink and has no
caller; :NO-CALLER when the only unguarded chains end in sinks without callers; :NOT-DETERMINED for a cycle.
A caller found only in the text does not decide the status: a docstring can name a function it no longer calls."
  (let ((node (find-node analysis name)))
    (cond ((null node) :not-determined)
          ((member name seen :test #'equal) :not-determined)
          ((node-guard node) :guarded)
          (t (let ((callers (callers-of analysis name :xref)))
               (if (null callers)
                   (if (sink-role-p node) :no-caller :open)
                   (worst (mapcar (lambda (c) (let ((x (path-status analysis c (cons name seen))))
                                                (if (eq x :guarded) :protected x)))
                                  callers)
                          '(:open :not-determined :no-caller :protected))))))))

(defun coverage (analysis name &optional seen)
  "For a caller, over cross-reference edges: :GUARDED when it checks the guard itself; :COVERED when every path down
to a sink passes a guard; :UNCOVERED when one reaches an unguarded sink; :TO-READ when a path ends in a text-only
finding or a text-only connection; :NOT-DETERMINED for a cycle."
  (let ((node (find-node analysis name)))
    (cond ((null node) :not-determined)
          ((member name seen :test #'equal) :not-determined)
          ((node-guard node) :guarded)
          ((eq (node-role node) :sink) :uncovered)
          ((eq (node-role node) :text-sink) :to-read)
          (t (let ((callees (callees-of analysis name :xref)))
               (if (null callees)
                   (if (callees-of analysis name :text) :to-read :not-determined)
                   (let ((s (mapcar (lambda (c) (coverage analysis c (cons name seen))) callees)))
                     (if (every (lambda (x) (member x '(:guarded :covered))) s)
                         :covered
                         (worst s '(:uncovered :to-read :not-determined :covered))))))))))

(defvar *analysis* nil "The latest analysis of this image.")

;;; The call graph as a Topicmap projection, for the native Topicmap view

(defclass call-graph () ((analysis :initarg :analysis :reader graph-analysis)))
(defmethod v:text-representation ((g call-graph)) "Codepfade als Topicmap")

(defun node-label (name)
  (let ((symbol (if (consp name) (second name) name)))
    (if (symbolp symbol) (string-downcase (symbol-name symbol)) (princ-to-string name))))

(defun node-id (name) (format nil "codepath:~S" name))

(defun depth-from-sinks (analysis)
  "Layer of each node: 0 for sinks, 1 + the smallest layer of a callee otherwise."
  (let ((depth (make-hash-table :test #'equal)) (changed t))
    (dolist (s (analysis-sinks analysis)) (setf (gethash s depth) 0))
    (loop while changed
          do (setf changed nil)
             (dolist (e (analysis-edges analysis))
               (let ((d (gethash (edge-to e) depth)))
                 (when (and d (or (null (gethash (edge-from e) depth)) (> (gethash (edge-from e) depth) (1+ d))))
                   (setf (gethash (edge-from e) depth) (1+ d) changed t)))))
    depth))

(defmethod tm:topicmap-projection-of ((graph call-graph))
  (let* ((analysis (graph-analysis graph))
         (depth (depth-from-sinks analysis))
         (layers (make-hash-table)))
    (dolist (n (analysis-nodes analysis)) (push n (gethash (gethash (node-name n) depth 0) layers)))
    (let ((topics
            (loop for layer being the hash-keys of layers using (hash-value members)
                  append (loop for n in (sort (copy-list members) #'string< :key (lambda (n) (node-label (node-name n))))
                               for i from 0
                               collect (tm:make-topicmap-topic
                                        :id (node-id (node-name n))
                                        :type (intern (format nil "~A-~A" (node-role n) (node-status n)) :keyword)
                                        :label (node-label (node-name n))
                                        :object (let ((s (node-name n))) (if (and (symbolp s) (fboundp s)) (fdefinition s) n))
                                        :view-properties (list :x (+ 40 (* 240 i)) :y (- 620 (* 130 layer))
                                                               :visible t :pinned t)))))
          (associations
            (loop for e in (analysis-edges analysis) for i from 0
                  collect (tm:make-topicmap-association
                           :id (format nil "codepath-call:~D" i) :type (if (eq (edge-via e) :xref) :calls :names-in-text)
                           :from (node-id (edge-from e)) :to (node-id (edge-to e))))))
      (tm:make-topicmap-projection :source graph :topics topics :associations associations
                                   :view-properties (list :width (max 1200 (+ 80 (* 240 (loop for m being the hash-values of layers maximize (length m)))))
                                                          :height 720)))))
