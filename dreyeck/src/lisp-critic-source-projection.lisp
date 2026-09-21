;;;; Where the Lisp Critic's source lives, across three kinds of ownership.
;;
;; The book's Code pages tab is empty, and correctly so. Code Pages
;; means the CL source components under one component of one system —
;; the book's own — and that is a useful thing to mean. This subject
;; simply does not have that shape: its source is spread over four
;; repository systems, a system that lives beside a wiki page, and a
;; vendored historical distribution with a definition of its own.
;;
;; So Code Pages is left as it is and a second reading is added beside
;; it. The two answer different questions:
;;
;;     Code pages          which source files does this book carry?
;;     Source structure    where does this subject's source live at all?
;;
;; Each layer is observed by the means that layer permits, and the
;; difference is not incidental. The repository systems are ours and
;; already loaded, so ASDF can be asked about them without evaluating
;; anything new. The page-attached system and the vendored engine are
;; neither, and asking ASDF about them would mean running a definition
;; that arrived with a page — so they are read as text and listed as
;; files. A projection that discovered them by loading them would have
;; destroyed the very distinction it exists to show.

(in-package #:dreyeck/lisp-critic/reading)

(hyperdoc:see
  (hyperdoc:page "Where the Source Lives"))

(defparameter +repository-source-systems+
  '("dreyeck/lisp-critic"
    "dreyeck/lisp-critic/critique"
    "dreyeck/inspector/lisp-critic"
    "dreyeck/lisp-critic/reading")
  "The repository systems whose source is about the Lisp Critic.

Named rather than searched. A search over every registered system for
the string \"lisp-critic\" would find test systems and coincidences, and
would quietly change meaning whenever something was renamed. These four
are a claim about what belongs to the subject, and the tests check that
each one exists and that its files are the ones ASDF reports.")

;;
;; The three layers
;;

(defun %repository-source-layer ()
  "The source this repository owns, as ASDF already holds it.

Asking ASDF is safe here and only here: these systems are loaded, so
FIND-SYSTEM looks up rather than evaluates. The same call against the
page's definition would run it."
  (labels ((files (component)
             (cond ((typep component 'asdf:cl-source-file) (list component))
                   ((typep component 'asdf:module)
                    (mapcan #'files (asdf:component-children component)))
                   (t nil))))
    (list
     :layer :repository-owned
     :observed-by :asdf-registry
     :why "these systems are this repository's own and already loaded"
     :systems
     (mapcar (lambda (name)
               (let ((system (asdf:find-system name nil)))
                 (list :name name
                       :present-p (and system t)
                       :files (when system
                                (mapcar (lambda (file)
                                          (file-namestring
                                           (asdf:component-pathname file)))
                                        (mapcan #'files
                                                (asdf:component-children system)))))))
             +repository-source-systems+))))

(defun %source-files-under (directory &optional (types '("lisp" "asd")))
  "The source files directly in DIRECTORY, by extension, sorted."
  (let ((resolved (uiop:directory-exists-p directory)))
    (when resolved
      (sort (remove-if-not
             (lambda (path) (member (pathname-type path) types :test #'string-equal))
             (uiop:directory-files resolved))
            #'string< :key #'file-namestring))))

(defun %page-attached-source-layer ()
  "The wrapper that lives beside the page, read as files and text.

No FIND-SYSTEM and no LOAD-ASD. What the definition says comes from
scanning it as text; what is there comes from listing the directory.
Both are questions about files."
  (let* ((root (resolve-engine-asset-root))
         (declaration (engine-asdf-source-declaration)))
    (list
     :layer :page-attached
     :observed-by :file-system-and-text
     :why "this definition arrived with a page and is not evaluated here"
     :root (and root (namestring root))
     :declaration declaration
     :systems
     (list (list :name +engine-wrapper-system+
                 :present-p (and root (getf declaration :read-p) t)
                 :files (append
                         (mapcar #'file-namestring (%source-files-under root))
                         (mapcar (lambda (path)
                                   (format nil "src/~A" (file-namestring path)))
                                 (and root
                                      (%source-files-under
                                       (merge-pathnames "src/" root))))))))))

(defun %vendored-source-layer ()
  "The historical engine the wrapper carries, likewise as files and text."
  (let* ((directory (vendored-engine-directory))
         (files (%source-files-under directory)))
    (list
     :layer :vendored-historical
     :observed-by :file-system-and-text
     :why "a copy of someone else's distribution, not this repository's source"
     :root (and directory (namestring directory))
     :systems
     (list (list :name "lisp-critic"
                 :present-p (and files t)
                 :files (mapcar #'file-namestring files))))))

(defun lisp-critic-source-layers ()
  "All three layers, in the order ownership passes through them."
  (list (%repository-source-layer)
        (%page-attached-source-layer)
        (%vendored-source-layer)))

;;
;; The subject
;;

(defclass lisp-critic-source-structure ()
  ()
  (:documentation
   "A handle for where the Lisp Critic's source lives, so it can be projected.

Holds nothing, like the page-loading history before it. Everything it
stands for is observed when asked."))

(defun make-lisp-critic-source-structure ()
  (make-instance 'lisp-critic-source-structure))

(defmethod print-object ((object lisp-critic-source-structure) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~D layers" (length (lisp-critic-source-layers)))))

;;
;; The projection
;;

(defun %layer-topic-id (layer) (format nil "source-layer:~(~A~)" layer))
(defun %system-topic-id (name) (format nil "asdf-system:~A" name))

(defmethod dreyeck/topicmap:topicmap-projection-of
    ((structure lisp-critic-source-structure))
  "Layers and the systems in them, with ownership passing between layers.

Files are not topics. Six systems and three layers make a diagram a
reader can take in; twenty-four file nodes make a thicket. Each system
topic carries its own observation, files and all, so nothing is lost —
it is one inspection away rather than drawn.

The two edges between layers are read from the source binding, which
names the wrapper system it registers and the upstream system that
wrapper loads. They are not a guess about what probably calls what."
  (declare (ignore structure))
  (let* ((layers (lisp-critic-source-layers))
         (binding (engine-source-binding))
         (wrapper (critic:lisp-critic-source-station-wrapper-system-of binding))
         (upstream (critic:lisp-critic-source-station-upstream-system-of binding))
         (topics nil)
         (associations nil))
    (dolist (layer layers)
      (let ((id (%layer-topic-id (getf layer :layer))))
        (push (dreyeck/topicmap:make-topicmap-topic
               :id id :type :source-layer
               :label (substitute #\Space #\- (string-downcase (getf layer :layer)))
               :object layer)
              topics)
        (dolist (system (getf layer :systems))
          (push (dreyeck/topicmap:make-topicmap-topic
                 :id (%system-topic-id (getf system :name))
                 :type :asdf-system
                 :label (getf system :name)
                 :object system)
                topics)
          (push (dreyeck/topicmap:make-topicmap-association
                 :id (format nil "source-layer-membership:~A" (getf system :name))
                 :type :in-layer
                 :from (%system-topic-id (getf system :name)) :to id)
                associations))))
    ;; Ownership passes outward, and each step is named by the binding.
    (push (dreyeck/topicmap:make-topicmap-association
           :id "source-ownership:reading-registers-wrapper"
           :type :registers
           :from (%system-topic-id "dreyeck/lisp-critic/reading")
           :to (%system-topic-id wrapper))
          associations)
    (push (dreyeck/topicmap:make-topicmap-association
           :id "source-ownership:wrapper-loads-engine"
           :type :loads
           :from (%system-topic-id wrapper)
           :to (%system-topic-id upstream))
          associations)
    (dreyeck/topicmap:make-topicmap-projection
     :source (make-lisp-critic-source-structure)
     :topics (nreverse topics)
     :associations (nreverse associations)
     :view-properties
     (list :presentation :lisp-critic-source-structure
           :point (%layer-topic-id :repository-owned)
           :width 1200 :height 720))))

;;
;; Reading
;;

(hyperdoc:defexample lisp-critic-source-structure-example
  "Where the Lisp Critic's source lives, as one inspectable subject."
  (make-lisp-critic-source-structure))

(hyperdoc:defexample lisp-critic-source-layers-example
  "The three layers, each with how it was observed and why."
  (lisp-critic-source-layers))

(hyperdoc:defexample lisp-critic-source-workspace-example
  "The same structure as a Workspace, navigable by its native Topic signs."
  (dreyeck/topicmap::make-topicmap-workspace-for-object
   (make-lisp-critic-source-structure)))

(hyperdoc:defexample lisp-critic-source-d2-example
  "The structure serialized to ordinary D2, with its identity maps."
  (dreyeck/topicmap/tala:projection-tala-input
   (dreyeck/topicmap:topicmap-projection-of
    (make-lisp-critic-source-structure))))

(hyperdoc:defexample lisp-critic-source-diagram-example
  "The structure laid out by TALA, as a non-interactive image.

The pinned renderer is not on every runtime, so an absent one is
reported rather than signalled."
  (let ((dependency (dreyeck/topicmap/tala:tala-dependency-status)))
    (if (eq :available (getf dependency :status))
        (dreyeck/topicmap/tala:run-tala
         (dreyeck/topicmap/tala:projection-tala-input
          (dreyeck/topicmap:topicmap-projection-of
           (make-lisp-critic-source-structure))))
        (list :kind :tala-unavailable
              :dependency dependency
              :remedy "nix develop .#tala"
              :evidence-status :observed))))

(hyperdoc:defexample lisp-critic-code-pages-observation-example
  "Why this book's Code pages tab is empty, read from the book itself.

Not an explanation written down beside the tab, but the two facts that
produce it: which ASDF component the book names for its pages, and what
kind of components are under it."
  (let* ((book *lisp-critic-reading*)
         (named (hyperdoc::directory-of book)))
    (list :kind :code-pages-observation
          :book (hyperbook:title-of book)
          :asdf-system (hyperdoc::asdf-system-name-of book)
          :subdirectory-names-the-pages-module-p t
          :pages-directory (and named (namestring named))
          :code-page-count (length (hyperdoc::code-pages-of book))
          :why "Code pages are the CL source components under the component the book names, and the component it names holds its pages"
          :source-structure "the source of this subject is read separately, because it spans three kinds of ownership"
          :evidence-status :observed)))
