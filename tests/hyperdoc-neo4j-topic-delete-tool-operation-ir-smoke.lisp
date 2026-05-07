;;;; Smoke tests for HyperdocNeo4jTopicDeleteTool operation IR
;;
;; These tests are source-parity checks only. They do not spawn Java, open a
;; Neo4j database, or execute any destructive command.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-HYPERDOC-NEO4J-TOPIC-DELETE-TOOL-OPERATION-IR-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defparameter +neo4j-topic-delete-tool-commands+
  '("report-topic"
    "plan-delete-topic"
    "delete-topic"
    "force-detach-delete-topic"
    "plan-force-delete-orphan-assoc-nodes"
    "force-delete-orphan-assoc-nodes"
    "report-workspace-na-candidates"
    "delete-manifest"))

(defparameter +neo4j-topic-delete-tool-force-topic-token+
  "I_UNDERSTAND_THIS_DETACH_DELETES_PRIMARY_TOPIC_ONLY")

(defparameter +neo4j-topic-delete-tool-force-assoc-token+
  "I_UNDERSTAND_THIS_DELETES_LISTED_ASSOCIATION_NODES")

(defun neo4j-topic-delete-tool-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun neo4j-topic-delete-tool-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun neo4j-topic-delete-tool-repo-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun neo4j-topic-delete-tool-read-repo-file (relative-path)
  (uiop:read-file-string
   (neo4j-topic-delete-tool-repo-path relative-path)))

(defun neo4j-topic-delete-tool-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun neo4j-topic-delete-tool-load-inspector-views (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun neo4j-topic-delete-tool-parse-integer-at (string start)
  (let ((end (or (position-if-not #'digit-char-p string :start start)
                 (length string))))
    (parse-integer string :start start :end end)))

(defun neo4j-topic-delete-tool-java-command-arities (source)
  (let ((result '())
        (position 0)
        (if-marker "if (\"")
        (command-suffix "\".equals(command))")
        (arity-marker "args.length != "))
    (loop
          for if-start = (search if-marker source :start2 position)
          while if-start
          do (let* ((command-start (+ if-start (length if-marker)))
                    (command-end (search command-suffix
                                         source
                                         :start2 command-start)))
               (unless command-end
                 (setf position (+ command-start 1))
                 (return))
               (let* ((command (subseq source command-start command-end))
                      (return-pos (or (search "return;" source :start2 command-end)
                                      (length source)))
                      (block (subseq source command-end return-pos))
                      (arity-pos (search arity-marker block)))
                 (when arity-pos
                   (let* ((args-length-start (+ arity-pos (length arity-marker)))
                          (args-length
                           (neo4j-topic-delete-tool-parse-integer-at
                            block
                            args-length-start)))
                     (push (cons command (1- args-length)) result)))
                 (setf position return-pos))))
    (nreverse result)))

(defun neo4j-topic-delete-tool-sorted-command-arities (alist)
  (sort (copy-list alist) #'string< :key #'car))

(defun neo4j-topic-delete-tool-ir-command-arities (ir)
  (mapcar
   (lambda (operation)
     (cons (getf operation :command)
           (getf operation :arity)))
   (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operations ir)))

(defun run-hyperdoc-neo4j-topic-delete-tool-operation-ir-load-smoke-test ()
  (let* ((ir (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-ir))
         (tool (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-ir-tool
                ir))
         (operations
          (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operations ir)))
    (neo4j-topic-delete-tool-assert-equal
     "HyperdocNeo4jTopicDeleteTool"
     (getf tool :id)
     "IR tool id")
    (neo4j-topic-delete-tool-assert-equal
     "HyperdocNeo4jTopicDeleteTool"
     (getf tool :class-name)
     "IR class name")
    (neo4j-topic-delete-tool-assert-equal
     +neo4j-topic-delete-tool-commands+
     (mapcar (lambda (operation)
               (getf operation :command))
             operations)
     "IR command order must cover the Java command surface")
    (dolist (operation operations)
      (neo4j-topic-delete-tool-assert-equal
       (length (getf operation :arguments))
       (getf operation :arity)
       (format nil "IR arity must match argument list for ~A"
               (getf operation :command))))
    (neo4j-topic-delete-tool-assert-true
     (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-by-command
      "delete-topic"
      ir)
     "Operation lookup by command must work")
    (neo4j-topic-delete-tool-assert-true
     (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-by-id
      :delete-topic
      ir)
     "Operation lookup by id must work")
    t))

(defun run-hyperdoc-neo4j-topic-delete-tool-operation-ir-java-parity-smoke-test ()
  (let* ((java-source
          (neo4j-topic-delete-tool-read-repo-file
           "tools/HyperdocNeo4jTopicDeleteTool.java"))
         (ir (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-ir))
         (java-arities
          (neo4j-topic-delete-tool-java-command-arities java-source))
         (ir-arities
          (neo4j-topic-delete-tool-ir-command-arities ir)))
    (neo4j-topic-delete-tool-assert-equal
     (neo4j-topic-delete-tool-sorted-command-arities java-arities)
     (neo4j-topic-delete-tool-sorted-command-arities ir-arities)
     "IR command arities must match Java main dispatcher")
    (dolist (command +neo4j-topic-delete-tool-commands+)
      (neo4j-topic-delete-tool-assert-true
       (search command java-source :test #'char=)
       (format nil "Java source must contain command ~A" command)))
    (neo4j-topic-delete-tool-assert-true
     (search +neo4j-topic-delete-tool-force-topic-token+
             java-source
             :test #'char=)
     "Java source must contain primary-topic emergency confirmation token")
    (neo4j-topic-delete-tool-assert-true
     (search +neo4j-topic-delete-tool-force-assoc-token+
             java-source
             :test #'char=)
     "Java source must contain orphan-association emergency confirmation token")
    (neo4j-topic-delete-tool-assert-equal
     +neo4j-topic-delete-tool-force-topic-token+
     (getf (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-by-command
            "force-detach-delete-topic"
            ir)
           :confirmation-token)
     "IR primary-topic emergency confirmation token must match Java exactly")
    (neo4j-topic-delete-tool-assert-equal
     +neo4j-topic-delete-tool-force-assoc-token+
     (getf (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-by-command
            "force-delete-orphan-assoc-nodes"
            ir)
           :confirmation-token)
     "IR orphan-association emergency confirmation token must match Java exactly")
    t))

(defun run-hyperdoc-neo4j-topic-delete-tool-operation-ir-safety-smoke-test ()
  (let ((ir (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-ir)))
    (dolist (command '("delete-topic"
                       "force-detach-delete-topic"
                       "force-delete-orphan-assoc-nodes"
                       "delete-manifest"))
      (neo4j-topic-delete-tool-assert-true
       (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-destructive-p
        (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-by-command
         command
         ir))
       (format nil "~A must be classified as destructive" command)))
    (dolist (command '("report-topic"
                       "plan-delete-topic"
                       "plan-force-delete-orphan-assoc-nodes"
                       "report-workspace-na-candidates"))
      (neo4j-topic-delete-tool-assert-true
       (not
        (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-destructive-p
         (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-by-command
          command
          ir)))
       (format nil "~A must stay read-only/non-destructive" command)))
    t))

(defun run-hyperdoc-neo4j-topic-delete-tool-operation-ir-scxml-smoke-test ()
  (let* ((path
          (neo4j-topic-delete-tool-repo-path
           "hyperdoc/hyperdoc-neo4j-topic-delete-tool-capability-model.scxml"))
         (chart (hyperdoc/scxml:parse-scxml-file path))
         (findings (hyperdoc/scxml:validate-scxml-chart chart))
         (states
          (mapcar #'hyperdoc/scxml:scxml-state-id-of
                  (hyperdoc/scxml:scxml-chart-states-of chart))))
    (neo4j-topic-delete-tool-assert-equal
     "hyperdoc-neo4j-topic-delete-tool-capability-model"
     (hyperdoc/scxml:scxml-chart-name-of chart)
     "SCXML chart name")
    (neo4j-topic-delete-tool-assert-equal
     "receiving-command"
     (hyperdoc/scxml:scxml-chart-initial-state-of chart)
     "SCXML initial state")
    (dolist (state '("receiving-command"
                     "report-topic"
                     "plan-delete-topic"
                     "delete-planned-closure"
                     "emergency-force-detach-delete-topic"
                     "plan-orphan-association-cleanup"
                     "emergency-orphan-association-cleanup"
                     "report-workspace-na-candidates"
                     "delete-manifest"
                     "final-success"
                     "final-refusal"
                     "final-missing"))
      (neo4j-topic-delete-tool-assert-true
       (member state states :test #'string=)
       (format nil "SCXML must define state ~A" state)))
    (neo4j-topic-delete-tool-assert-true
     (notany (lambda (finding)
               (eq :error
                   (hyperdoc/scxml:scxml-validation-finding-severity-of
                    finding)))
             findings)
     (format nil "SCXML model must validate without errors: ~S"
             (mapcar #'hyperdoc/scxml:scxml-validation-finding-code-of
                     findings)))
    t))

(defun run-hyperdoc-neo4j-topic-delete-tool-operation-ir-inspector-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((model
          (hyperdoc::make-hyperdoc-neo4j-topic-delete-tool-operation-model))
         (views (neo4j-topic-delete-tool-load-inspector-views model))
         (operations-view
          (neo4j-topic-delete-tool-find-view-by-title views "Operations"))
         (safety-view
          (neo4j-topic-delete-tool-find-view-by-title
           views
           "Safety classification"))
         (preview-view
          (neo4j-topic-delete-tool-find-view-by-title
           views
           "Command previews")))
    (dolist (view (list operations-view safety-view preview-view))
      (neo4j-topic-delete-tool-assert-true
       view
       "Operation model must expose read-only inspector views"))
    (let ((combined-html
           (concatenate
            'string
            (html-inspector-views:view-html operations-view)
            (html-inspector-views:view-html safety-view)
            (html-inspector-views:view-html preview-view))))
      (dolist (command +neo4j-topic-delete-tool-commands+)
        (neo4j-topic-delete-tool-assert-true
         (search command combined-html :test #'char=)
         (format nil "Inspector views must expose command ~A" command)))
      (neo4j-topic-delete-tool-assert-true
       (search "java HyperdocNeo4jTopicDeleteTool"
               combined-html
               :test #'char=)
       "Inspector must expose materialized command previews")
      (neo4j-topic-delete-tool-assert-true
       (not (search "<button" combined-html :test #'char-equal))
       "Inspector model must not expose live execution buttons")
      (neo4j-topic-delete-tool-assert-true
       (not (search "onclick" combined-html :test #'char-equal))
       "Inspector model must not expose browser execution handlers"))
    t))

(defun run-hyperdoc-neo4j-topic-delete-tool-operation-ir-doc-smoke-test ()
  (let ((page
         (neo4j-topic-delete-tool-read-repo-file
          "hyperdoc/Hyperdoc Neo4j Topic Delete Tool Operation Model.html"))
        (ir
         (neo4j-topic-delete-tool-read-repo-file
          "tools/hyperdoc-neo4j-topic-delete-tool.operations.sexp")))
    (dolist (needle '("source parity"
                      "not behavioral change"
                      "936040"
                      "SCXML capability model"
                      "does not generate low-level Neo4j graph mutation logic"
                      "No inspector action executes a Java command"))
      (neo4j-topic-delete-tool-assert-true
       (search needle page :test #'char-equal)
       (format nil "Documentation must contain ~S" needle)))
    (dolist (forbidden '("delete/recreate"
                         "replacement topic"
                         "Authorization:"
                         "JSESSIONID="
                         "password"))
      (neo4j-topic-delete-tool-assert-true
       (not (search forbidden page :test #'char-equal))
       (format nil "Documentation must not contain forbidden phrase ~S"
               forbidden)))
    (dolist (forbidden (list (concatenate 'string "Embedded" "GraphDatabase")
                             (concatenate 'string "EmbeddedReadOnly"
                                          "GraphDatabase")
                             (concatenate 'string "uiop:run" "-program")
                             (concatenate 'string
                                          "/Users/rgb/Applications/"
                                          "dmx-5.3.5/dmx-db")))
      (neo4j-topic-delete-tool-assert-true
       (not (search forbidden ir :test #'char-equal))
       (format nil "IR must not contain database access or local DB path marker ~S"
               forbidden)))
    t))

(defun run-hyperdoc-neo4j-topic-delete-tool-operation-ir-smoke-tests ()
  (run-hyperdoc-neo4j-topic-delete-tool-operation-ir-load-smoke-test)
  (run-hyperdoc-neo4j-topic-delete-tool-operation-ir-java-parity-smoke-test)
  (run-hyperdoc-neo4j-topic-delete-tool-operation-ir-safety-smoke-test)
  (run-hyperdoc-neo4j-topic-delete-tool-operation-ir-scxml-smoke-test)
  (run-hyperdoc-neo4j-topic-delete-tool-operation-ir-inspector-smoke-test)
  (run-hyperdoc-neo4j-topic-delete-tool-operation-ir-doc-smoke-test)
  t)
