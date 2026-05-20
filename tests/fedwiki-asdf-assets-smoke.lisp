;;;; Smoke tests for HyperDoc-native FedWiki page-local ASDF assets.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-FEDWIKI-ASDF-ASSETS-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun fedwiki-asdf-assets-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun fedwiki-asdf-assets-assert-false (condition message)
  (when condition
    (error "~A" message)))

(defun fedwiki-asdf-assets-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun fedwiki-asdf-assets-assert-contains (needle haystack message)
  (unless (and haystack (search needle haystack :test #'char=))
    (error "~A -- missing substring: ~S" message needle)))

(defun fedwiki-asdf-assets-assert-not-contains (needle haystack message)
  (when (and haystack (search needle haystack :test #'char=))
    (error "~A -- unexpected substring: ~S" message needle)))

(defparameter +fedwiki-asdf-assets-dm6-native-assoc-types+
  '("Association" "Hierarchy"))

(defun fedwiki-asdf-assets-alist-field (alist key)
  (cdr (assoc key alist :test #'string=)))

(defun fedwiki-asdf-assets-sequence-items (value)
  (cond
    ((null value) nil)
    ((vectorp value) (coerce value 'list))
    ((listp value) value)
    (t (error "Expected list or vector, got: ~S" value))))

(defun fedwiki-asdf-assets-json-field (object key)
  (gethash key object))

(defun fedwiki-asdf-assets-semantic-assoc-by-id (id semantic-assocs)
  (find id semantic-assocs :key (lambda (assoc)
                                  (getf assoc :id))
                         :test #'eql))

(defun fedwiki-asdf-assets-assert-native-model-compatible (projection)
  (let* ((key
           (fedwiki-asdf-assets-call "MG-TOPICMAP-PROJECTION-KEY"
                                     projection))
         (semantic-topicmap
           (fedwiki-asdf-assets-call
            "MG-TOPICMAP-PROJECTION-SEMANTIC-TOPICMAP"
            projection))
         (native-topicmap
           (fedwiki-asdf-assets-call
            "MG-TOPICMAP-PROJECTION-NATIVE-TOPICMAP"
            projection))
         (semantic-assocs (getf semantic-topicmap :assocs))
         (native-topics
           (fedwiki-asdf-assets-sequence-items
            (fedwiki-asdf-assets-alist-field native-topicmap "topics")))
         (native-assocs
           (fedwiki-asdf-assets-sequence-items
            (fedwiki-asdf-assets-alist-field native-topicmap "assocs"))))
    (fedwiki-asdf-assets-assert-true
     native-topics
     (format nil "Generated native model must contain non-empty topics for ~A"
             key))
    (fedwiki-asdf-assets-assert-true
     native-assocs
     (format nil "Generated native model must contain non-empty assocs for ~A"
             key))
    (dolist (native-assoc native-assocs)
      (let* ((id (fedwiki-asdf-assets-alist-field native-assoc "id"))
             (native-type
               (fedwiki-asdf-assets-alist-field native-assoc "type"))
             (semantic-type
               (fedwiki-asdf-assets-alist-field native-assoc "semanticType"))
             (semantic-assoc
               (fedwiki-asdf-assets-semantic-assoc-by-id
                id
                semantic-assocs))
             (original-semantic-type
               (and semantic-assoc
                    (getf semantic-assoc :type))))
        (fedwiki-asdf-assets-assert-true
         semantic-assoc
         (format nil "Native assoc ~A must correspond to a semantic assoc in ~A"
                 id
                 key))
        (fedwiki-asdf-assets-assert-true
         (and native-type
              (member native-type
                      +fedwiki-asdf-assets-dm6-native-assoc-types+
                      :test #'string=))
         (format nil "Native assoc ~A in ~A must use a DM6 decoder type"
                 id
                 key))
        (fedwiki-asdf-assets-assert-false
         (equal native-type original-semantic-type)
         (format nil
                 "Native assoc ~A in ~A must not emit semantic relation name in type"
                 id
                 key))
        (fedwiki-asdf-assets-assert-equal
         original-semantic-type
         semantic-type
         (format nil
                 "Native assoc ~A in ~A must preserve semantic relation metadata"
                 id
                 key))))))

(defun fedwiki-asdf-assets-assert-rendered-json-model-populated (projection)
  (let* ((key
           (fedwiki-asdf-assets-call "MG-TOPICMAP-PROJECTION-KEY"
                                     projection))
         (json
           (fedwiki-asdf-assets-call "MG-TOPICMAP-PROJECTION-JSON"
                                     projection))
         (model (shasht:read-json json))
         (topics
           (fedwiki-asdf-assets-sequence-items
            (fedwiki-asdf-assets-json-field model "topics")))
         (assocs
           (fedwiki-asdf-assets-sequence-items
            (fedwiki-asdf-assets-json-field model "assocs"))))
    (fedwiki-asdf-assets-assert-true
     topics
     (format nil "Rendered model JSON must contain non-empty topics for ~A"
             key))
    (fedwiki-asdf-assets-assert-true
     assocs
     (format nil "Rendered model JSON must contain non-empty assocs for ~A"
             key))))

(defun fedwiki-asdf-assets-assert-metagraph-models-compatible ()
  (dolist (which '(:conversation-story :layer-contract :planning-example))
    (let ((projection
            (fedwiki-asdf-assets-call "MG-TOPICMAP-PROJECTION" which)))
      (fedwiki-asdf-assets-assert-native-model-compatible projection)
      (fedwiki-asdf-assets-assert-rendered-json-model-populated projection))))

(defun fedwiki-asdf-assets-temp-root ()
  (merge-pathnames
   (format nil "hyperdoc-fedwiki-asdf-assets-smoke-~D-~D/assets/pages/"
           (get-universal-time)
           (random 1000000))
   (uiop:temporary-directory)))

(defun fedwiki-asdf-assets-make-spec ()
  (hyperdoc:make-metagraph-jsonld-fluree-asset-spec
   :asset-root (fedwiki-asdf-assets-temp-root)))

(defun fedwiki-asdf-assets-page-dir (spec)
  (hyperdoc:fedwiki-page-assets-directory
   (hyperdoc:page-asdf-asset-spec-page-slug spec)
   :asset-root (hyperdoc:page-asdf-asset-spec-asset-root spec)))

(defun fedwiki-asdf-assets-asd-path (spec)
  (merge-pathnames
   (format nil "~A.asd" (hyperdoc:page-asdf-asset-spec-system-name spec))
   (fedwiki-asdf-assets-page-dir spec)))

(defun fedwiki-asdf-assets-generated-symbol (name)
  (let ((package (find-package "METAGRAPH-AS-BIPARTITE-GRAPH-JSON-LD--FLUREE")))
    (unless package
      (error "Generated metagraph package is not present."))
    (multiple-value-bind (symbol status)
        (find-symbol (string-upcase name) package)
      (unless (eq status :external)
        (error "Generated symbol is not exported: ~A" name))
      symbol)))

(defun fedwiki-asdf-assets-call (name &rest args)
  (apply (symbol-function (fedwiki-asdf-assets-generated-symbol name)) args))

(defun fedwiki-asdf-assets-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun fedwiki-asdf-assets-view-titles (object)
  (mapcar #'html-inspector-views:view-title
          (fedwiki-asdf-assets-load-inspector-views-for-object object)))

(defun fedwiki-asdf-assets-view-title-present-p (label titles)
  (some (lambda (title)
          (and title
               (search label title :test #'char-equal)))
        titles))

(defun fedwiki-asdf-assets-create-file (pathname contents)
  (ensure-directories-exist pathname)
  (with-open-file (stream pathname
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :external-format :utf-8)
    (write-string contents stream))
  pathname)

(defun fedwiki-asdf-assets-zip-list (zip-path)
  (uiop:run-program
   (list "zipinfo" "-1" (namestring zip-path))
   :output :string
   :error-output :string))

(defun run-fedwiki-asdf-assets-layout-and-load-smoke-test ()
  (let* ((spec (fedwiki-asdf-assets-make-spec))
         (page-dir (fedwiki-asdf-assets-page-dir spec))
         (system-name (hyperdoc:page-asdf-asset-spec-system-name spec)))
    (hyperdoc:write-page-asdf-system spec :clean t)
    (fedwiki-asdf-assets-assert-true
     (probe-file (merge-pathnames
                  (format nil "~A.asd" system-name)
                  page-dir))
     "Writer must place the .asd directly in the page asset directory")
    (fedwiki-asdf-assets-assert-true
     (probe-file (merge-pathnames "src/topicmaps.lisp" page-dir))
     "Writer must create flat src/topicmaps.lisp")
    (fedwiki-asdf-assets-assert-true
     (probe-file (merge-pathnames "src/projections.lisp" page-dir))
     "Writer must create flat src/projections.lisp")
    (fedwiki-asdf-assets-assert-false
     (probe-file (merge-pathnames
                  (uiop:ensure-directory-pathname system-name)
                  page-dir))
     "Writer must not create a nested system-name directory")
    (hyperdoc:load-page-asdf-system spec :force t)
    (fedwiki-asdf-assets-assert-true
     (asdf:find-system system-name)
     "Generated system must load after ASDF:LOAD-ASD of exact pathname")
    (fedwiki-asdf-assets-assert-true
     (uiop:pathname-equal
      (truename (uiop:ensure-directory-pathname page-dir))
      (truename (asdf:system-source-directory (asdf:find-system system-name))))
     "Generated system source directory must be the exact written page asset directory")
    spec))

(defun run-fedwiki-asdf-assets-generated-api-smoke-test ()
  (let ((spec (run-fedwiki-asdf-assets-layout-and-load-smoke-test)))
    (dolist (name '("MG-ENSURE-INSPECTOR-VIEWS"
                    "MG-INSPECT-RENDERED-TOPICMAP"
                    "MG-TOPICMAP-PROJECTION"))
      (let ((symbol (fedwiki-asdf-assets-generated-symbol name)))
        (fedwiki-asdf-assets-assert-true
         (fboundp symbol)
         (format nil "Generated system must export callable ~A" name))))
    (let* ((projection
             (fedwiki-asdf-assets-call "MG-TOPICMAP-PROJECTION"
                                       :planning-example))
           (class (find-class
                   (fedwiki-asdf-assets-generated-symbol
                    "MG-TOPICMAP-PROJECTION")))
           (html
             (fedwiki-asdf-assets-call "MG-RENDERED-TOPICMAP-HTML"
                                       projection)))
      (fedwiki-asdf-assets-assert-true
       (typep projection class)
       "MG-TOPICMAP-PROJECTION must return an MG-TOPICMAP-PROJECTION instance")
      (fedwiki-asdf-assets-assert-metagraph-models-compatible)
      (dolist (needle '("class=\"dm6-hyperdoc-map dm6-island\""
                        "class=\"dm6-stored\""
                        "data-dm6-bundle=\"/assets/dm6-elm/app.js\""
                        "/assets/dm6-elm/hyperdoc-dm6-inline.js"))
        (fedwiki-asdf-assets-assert-contains
         needle
         html
         "Rendered metagraph Topic Map HTML must use the DM6 AppEmbed contract"))
      (fedwiki-asdf-assets-assert-not-contains
       "localhost:"
       html
       "Rendered metagraph Topic Map HTML must not hard-code localhost origins"))
    (let ((written (fedwiki-asdf-assets-call
                    "MG-WRITE-ALL-RENDERED-TOPICMAPS")))
      (fedwiki-asdf-assets-assert-equal
       3
       (length written)
       "MG-WRITE-ALL-RENDERED-TOPICMAPS must write three pages")
      (dolist (pathname written)
        (fedwiki-asdf-assets-assert-true
         (probe-file pathname)
         (format nil "Rendered Topic Map page must exist: ~A" pathname))))
    (hyperdoc:test-page-asdf-system spec)
    spec))

(defun run-fedwiki-asdf-assets-inspector-smoke-test ()
  (let ((spec (run-fedwiki-asdf-assets-layout-and-load-smoke-test)))
    (asdf:load-system :hyperdoc/inspector)
    (fedwiki-asdf-assets-assert-true
     (member (fedwiki-asdf-assets-call "MG-ENSURE-INSPECTOR-VIEWS")
             '(:installed :already-installed))
     "MG-ENSURE-INSPECTOR-VIEWS must register projection views when inspector packages are loaded")
    (let* ((projection
             (fedwiki-asdf-assets-call "MG-TOPICMAP-PROJECTION"
                                       :planning-example))
           (titles (fedwiki-asdf-assets-view-titles projection)))
      (dolist (title '("Topic Map"
                       "Native Model"
                       "Semantic Model"
                       "Rendered HTML"
                       "Slots"
                       "Print"
                       "Operations"
                       "Playground"))
        (fedwiki-asdf-assets-assert-true
         (fedwiki-asdf-assets-view-title-present-p title titles)
         (format nil "Projection inspector views must include ~A" title))))
    spec))

(defun run-fedwiki-asdf-assets-zip-smoke-test ()
  (let* ((spec (run-fedwiki-asdf-assets-generated-api-smoke-test))
         (page-dir (fedwiki-asdf-assets-page-dir spec))
         (system-name (hyperdoc:page-asdf-asset-spec-system-name spec))
         (nested-stale
           (merge-pathnames
            (format nil "~A/src/stale.lisp" system-name)
            page-dir))
         (fasl-stale (merge-pathnames "src/stale.fasl" page-dir))
         (cache-stale (merge-pathnames "cache/stale.txt" page-dir))
         (old-zip (merge-pathnames "old-output.zip" page-dir)))
    (fedwiki-asdf-assets-create-file nested-stale "stale nested source")
    (fedwiki-asdf-assets-create-file fasl-stale "stale fasl")
    (fedwiki-asdf-assets-create-file cache-stale "stale cache")
    (fedwiki-asdf-assets-create-file old-zip "stale zip")
    (let* ((zip-report (hyperdoc:build-page-asdf-asset-zip spec))
           (zip-path (getf zip-report :zip))
           (listing (fedwiki-asdf-assets-zip-list zip-path)))
      (fedwiki-asdf-assets-assert-true
       (probe-file zip-path)
       "ZIP builder must create a deployable ZIP")
      (fedwiki-asdf-assets-assert-contains
       "metagraph-as-bipartite-graph-json-ld--fluree.asd"
       listing
       "ZIP must include the flat ASDF file")
      (dolist (unexpected (list (format nil "~A/src/stale.lisp" system-name)
                                "src/stale.fasl"
                                "cache/stale.txt"
                                "old-output.zip"))
        (fedwiki-asdf-assets-assert-not-contains
         unexpected
         listing
         "ZIP must exclude stale nested directories, fasls, caches, and prior ZIPs")))))

(defun run-fedwiki-asdf-assets-idempotent-workflow-smoke-test ()
  (let* ((spec (fedwiki-asdf-assets-make-spec))
         (page-dir (fedwiki-asdf-assets-page-dir spec))
         (system-name (hyperdoc:page-asdf-asset-spec-system-name spec)))
    (hyperdoc:page-asdf-asset-workflow
     spec
     :clean t
     :force t
     :test t
     :zip t)
    (fedwiki-asdf-assets-create-file
     (merge-pathnames
      (format nil "~A/src/stale.lisp" system-name)
      page-dir)
     "stale nested source")
    (let* ((report
             (hyperdoc:page-asdf-asset-workflow
              spec
              :clean t
              :force t
              :test t
              :zip t))
           (zip-path (getf (getf report :zip) :zip))
           (listing (fedwiki-asdf-assets-zip-list zip-path)))
      (fedwiki-asdf-assets-assert-equal
       :ok
       (getf report :status)
       "Workflow must complete on a second clean run")
      (fedwiki-asdf-assets-assert-false
       (probe-file (merge-pathnames
                    (uiop:ensure-directory-pathname system-name)
                    page-dir))
       "Second workflow run must remove stale nested system directories")
      (fedwiki-asdf-assets-assert-not-contains
       (format nil "~A/src/stale.lisp" system-name)
       listing
       "Second workflow ZIP must not reintroduce stale nested contents"))))

(defun run-fedwiki-asdf-assets-smoke-tests ()
  (run-fedwiki-asdf-assets-layout-and-load-smoke-test)
  (run-fedwiki-asdf-assets-generated-api-smoke-test)
  (run-fedwiki-asdf-assets-inspector-smoke-test)
  (run-fedwiki-asdf-assets-zip-smoke-test)
  (run-fedwiki-asdf-assets-idempotent-workflow-smoke-test)
  (format t "~&FedWiki ASDF asset smoke tests passed.~%")
  t)
