;;;; Smoke tests for executable S-expression prompt split views.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-S-EXPRESSION-PROMPT-PURE-CORE-SMOKE-TEST"
                        :hyperdoc/tests)
                (intern "RUN-S-EXPRESSION-PROMPT-PURE-BOUNDARY-SMOKE-TEST"
                        :hyperdoc/tests)
                (intern "RUN-S-EXPRESSION-PROMPT-ROUNDTRIP-SMOKE-TEST"
                        :hyperdoc/tests)
                (intern "RUN-S-EXPRESSION-PROMPT-GENERATED-PAGE-SMOKE-TEST"
                        :hyperdoc/tests)
                (intern "RUN-S-EXPRESSION-PROMPT-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun s-expression-prompt-smoke-assert (condition message)
  (unless condition
    (error "~A" message)))

(defun s-expression-prompt-smoke-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message expected-type (type-of object))))

(defun s-expression-prompt-smoke-assert-contains (needle haystack message)
  (unless (and haystack (search needle haystack :test #'char=))
    (error "~A -- missing substring: ~S" message needle)))

(defparameter *s-expression-prompt-smoke-forbidden-systems*
  '("drakma"
    "cl+ssl"
    "hunchentoot"
    "clack"
    "usocket"
    "hyperbook/server"
    "hyperbook/explorer"
    "hyperbook/wikipedia"
    "hyperbook/fedwiki"))

(defun s-expression-prompt-smoke-system-name (designator)
  (string-downcase
   (etypecase designator
     (string designator)
     (symbol (symbol-name designator)))))

(defun s-expression-prompt-smoke-dependency-name (dependency)
  (cond
    ((and (consp dependency)
          (eq (first dependency) :version))
     (second dependency))
    ((and (consp dependency)
          (eq (first dependency) :feature))
     (third dependency))
    ((consp dependency)
     (first dependency))
    (t dependency)))

(defun s-expression-prompt-smoke-hyperdoc-server-system-p (system-name)
  (and (search "hyperdoc/" system-name :test #'char=)
       (or (search "server" system-name :test #'char=)
           (search "explorer" system-name :test #'char=)
           (search "inspector" system-name :test #'char=))))

(defun s-expression-prompt-smoke-forbidden-system-p (system-name)
  (or (member system-name
              *s-expression-prompt-smoke-forbidden-systems*
              :test #'string=)
      (s-expression-prompt-smoke-hyperdoc-server-system-p system-name)))

(defun s-expression-prompt-smoke-system-dependency-closure (root)
  (let ((seen (make-hash-table :test #'equal))
        (result nil))
    (labels ((visit (designator)
               (let* ((name (s-expression-prompt-smoke-system-name designator))
                      (system (ignore-errors
                                (asdf:find-system name nil))))
                 (unless (gethash name seen)
                   (setf (gethash name seen) t)
                   (push name result)
                   (when system
                     (dolist (dependency (asdf:system-depends-on system))
                       (let ((dependency-name
                               (s-expression-prompt-smoke-dependency-name
                                dependency)))
                         (when dependency-name
                           (visit dependency-name)))))))))
      (visit root)
      (nreverse result))))

(defun s-expression-prompt-smoke-loaded-system-names ()
  (sort
   (remove-duplicates
    (loop for system in (asdf:already-loaded-systems)
          for name = (or (ignore-errors (asdf:component-name system))
                         system)
          collect (s-expression-prompt-smoke-system-name name))
    :test #'string=)
   #'string<))

(defun s-expression-prompt-smoke-symbol (package-name symbol-name)
  (let* ((package (find-package package-name))
         (symbol (and package (find-symbol symbol-name package))))
    (unless symbol
      (error "Required symbol is unavailable: ~A::~A"
             package-name symbol-name))
    symbol))

(defun s-expression-prompt-smoke-function (package-name symbol-name)
  (let ((symbol (s-expression-prompt-smoke-symbol package-name symbol-name)))
    (unless (fboundp symbol)
      (error "Required function is unavailable: ~A::~A"
             package-name symbol-name))
    (symbol-function symbol)))

(defun s-expression-prompt-smoke-load-inspector-views (object)
  (let* ((pane-class
           (s-expression-prompt-smoke-symbol
            "CLOG-MOLDABLE-INSPECTOR" "PANE"))
         (load-views
           (s-expression-prompt-smoke-function
            "CLOG-MOLDABLE-INSPECTOR" "LOAD-VIEWS"))
         (views-slot
           (s-expression-prompt-smoke-symbol
            "CLOG-MOLDABLE-INSPECTOR" "VIEWS"))
         (pane (make-instance pane-class
                              :inspector nil
                              :object object)))
    (funcall load-views pane)
    (slot-value pane views-slot)))

(defun s-expression-prompt-smoke-view-title (view)
  (funcall
   (s-expression-prompt-smoke-function "HTML-INSPECTOR-VIEWS" "VIEW-TITLE")
   view))

(defun s-expression-prompt-smoke-view-html (view)
  (funcall
   (s-expression-prompt-smoke-function "HTML-INSPECTOR-VIEWS" "VIEW-HTML")
   view))

(defun s-expression-prompt-smoke-find-view (views title)
  (find title views :key #'s-expression-prompt-smoke-view-title :test #'string=))

(defun s-expression-prompt-smoke-html ()
  "<article id=\"split-view-contract\">
     <h1>S-Expression Prompt Split View Contract</h1>
     <p>The topic map program is durable.</p>
     <p><a page=\"Codex handover for HyperDoc\">Canonical handover</a></p>
   </article>")

(defun s-expression-prompt-smoke-temp-page-path ()
  (merge-pathnames
   (format nil "hyperdoc-s-expression-prompt-~D-~D.html"
           (get-universal-time)
           (random 1000000))
   (uiop:temporary-directory)))

(defun s-expression-prompt-smoke-program ()
  (hyperdoc:html-page-to-topicmap-program
   (s-expression-prompt-smoke-html)
   :source-path "hyperdoc/S-Expression Prompt Split View Contract.html"
   :source-title "S-Expression Prompt Split View Contract"
   :source-evidence '(:fixture :smoke-test)
   :operator-task "Project source HTML into a split-view executable prompt."))

(defun run-s-expression-prompt-object-smoke-test ()
  (let* ((program (s-expression-prompt-smoke-program))
         (prompt
           (hyperdoc:make-executable-prompt
            :knowledge '(:rules (:program-is-durable)
                         :repo-boundaries (:no-dmx-write-path))
            :input (getf (rest program) :input)
            :output-contract (getf (rest program) :output-contract)
            :topicmap-program program)))
    (s-expression-prompt-smoke-assert-typep
     'hyperdoc:executable-prompt
     prompt
     "Three-layer executable prompt object must be constructible")
    (s-expression-prompt-smoke-assert
     (getf (rest (hyperdoc:executable-prompt-program-form prompt))
           :layers)
     "Executable prompt program form must carry explicit layers")
    (s-expression-prompt-smoke-assert
     (getf (rest program) :topics)
     "HTML projection must produce topic entries")
    (s-expression-prompt-smoke-assert
     (getf (rest program) :relations)
     "HTML projection must produce relation entries")
    prompt))

(defun run-s-expression-prompt-crosswalk-smoke-test ()
  (let* ((program (s-expression-prompt-smoke-program))
         (story-items
           (hyperdoc:topicmap-program-to-fedwiki-story-items program))
         (response
           (hyperdoc:make-split-view-response
            :fedwiki-story-items story-items
            :topicmap-program program))
         (validation
           (hyperdoc:split-view-response-validation-result-of response)))
    (s-expression-prompt-smoke-assert-typep
     'hyperdoc:split-view-response
     response
     "Split-view response object must be constructible")
    (s-expression-prompt-smoke-assert
     (hyperdoc:split-view-response-valid-p response)
     "Story items and topicmap program must crosswalk to the same ids")
    (s-expression-prompt-smoke-assert
     (eq :success (getf validation :status))
     "Successful split-view validation must expose exact success status")
    (let* ((broken-story
             (remove-if (lambda (item)
                          (getf item :topic-id))
                        story-items
                        :count 1))
           (broken-validation
             (hyperdoc:validate-split-view-response broken-story program)))
      (s-expression-prompt-smoke-assert
       (eq :failure (getf broken-validation :status))
       "Missing story projection ids must expose exact failure status")
      (s-expression-prompt-smoke-assert
       (getf broken-validation :missing-story-topics)
       "Failure shape must report missing story topics"))
    response))

(defun run-s-expression-prompt-inspector-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((program (s-expression-prompt-smoke-program))
         (response
           (hyperdoc:make-split-view-response
            :fedwiki-story-items
            (hyperdoc:topicmap-program-to-fedwiki-story-items program)
            :topicmap-program program))
         (views (s-expression-prompt-smoke-load-inspector-views response))
         (view (s-expression-prompt-smoke-find-view views "Split view")))
    (s-expression-prompt-smoke-assert
     view
     "Split-view response inspector must expose a Split view")
    (let ((html (s-expression-prompt-smoke-view-html view)))
      (s-expression-prompt-smoke-assert-contains
       "FedWiki story view"
       html
       "Inspector split view must expose the human story view")
      (s-expression-prompt-smoke-assert-contains
       "Topic map program view"
       html
       "Inspector split view must expose the S-expression program view")
      (s-expression-prompt-smoke-assert-contains
       "source-page"
       html
       "Inspector split view must render durable program topic ids")))
  t)

(defun run-s-expression-prompt-pure-core-smoke-test ()
  (asdf:load-system :hyperdoc/s-expression-prompts)
  (let ((program
          (hyperdoc:html-page-to-topicmap-program
           "<article><h1>Prompt Split View</h1><p>Program is durable.</p></article>"
           :source-path "smoke.html"
           :source-title "Prompt Split View")))
    (s-expression-prompt-smoke-assert
     program
     "Pure prompt core must project local HTML into a topicmap program")
    (s-expression-prompt-smoke-assert
     (getf (rest program) :topics)
     "Pure prompt core projection must produce topic entries"))
  (run-s-expression-prompt-object-smoke-test)
  (run-s-expression-prompt-crosswalk-smoke-test)
  (format t "~&S-expression prompt pure core smoke tests passed.~%")
  t)

(defun run-s-expression-prompt-pure-boundary-smoke-test ()
  (asdf:load-system :hyperdoc/s-expression-prompts)
  (let* ((closure
           (s-expression-prompt-smoke-system-dependency-closure
            :hyperdoc/s-expression-prompts))
         (loaded (s-expression-prompt-smoke-loaded-system-names))
         (forbidden-closure
           (remove-if-not #'s-expression-prompt-smoke-forbidden-system-p
                          closure))
         (forbidden-loaded
           (remove-if-not #'s-expression-prompt-smoke-forbidden-system-p
                          loaded)))
    (when (or forbidden-closure forbidden-loaded)
      (error "Pure prompt core boundary violation.~%Forbidden dependency closure entries: ~S~%Forbidden loaded systems: ~S~%Dependency closure: ~S~%Loaded systems: ~S"
             forbidden-closure
             forbidden-loaded
             closure
             loaded))
    (format t "~&S-expression prompt pure boundary smoke test passed.~%")
    t))

(defun run-s-expression-prompt-roundtrip-smoke-test ()
  (asdf:load-system :hyperdoc/s-expression-prompts)
  (let* ((program (s-expression-prompt-smoke-program))
         (prompt
           (hyperdoc:make-executable-prompt
            :knowledge '(:rules (:program-is-durable)
                         :repo-boundaries (:no-dmx-write-path)
                         :validation (:roundtrip-equivalence))
            :input (getf (rest program) :input)
            :output-contract (getf (rest program) :output-contract)
            :topicmap-program program))
         (response
           (hyperdoc:make-split-view-response
            :fedwiki-story-items
            (hyperdoc:topicmap-program-to-fedwiki-story-items program)
            :topicmap-program program))
         (html
           (hyperdoc:split-view-response-to-hyperdoc-html
            response
            :prompt prompt
            :title "S-Expression Prompt Round Trip"))
         (reloaded-program
           (hyperdoc:hyperdoc-html-to-topicmap-program html))
         (reloaded-response
           (hyperdoc:hyperdoc-html-to-split-view-response html))
         (reloaded-prompt
           (hyperdoc:hyperdoc-html-to-executable-prompt html))
         (program-validation
           (hyperdoc:validate-topicmap-program-equivalence
            program reloaded-program))
         (roundtrip-validation
           (hyperdoc:validate-split-view-response-roundtrip
            response reloaded-response)))
    (s-expression-prompt-smoke-assert-contains
     "data-hyperdoc-topicmap-program=\"true\""
     html
     "Materialized HyperDoc HTML must embed the durable topicmap program")
    (s-expression-prompt-smoke-assert-contains
     "data-hyperdoc-fedwiki-story-items=\"true\""
     html
     "Materialized HyperDoc HTML must embed FedWiki story items in order")
    (s-expression-prompt-smoke-assert
     (getf program-validation :success-p)
     "Reloaded topicmap program must be semantically equivalent")
    (s-expression-prompt-smoke-assert
     (getf roundtrip-validation :success-p)
     "Reloaded split-view response must preserve program and story order")
    (s-expression-prompt-smoke-assert
     (equal (hyperdoc:executable-prompt-knowledge-of prompt)
            (hyperdoc:executable-prompt-knowledge-of reloaded-prompt))
     "Executable prompt knowledge layer must survive materialization")
    (s-expression-prompt-smoke-assert
     (equal (hyperdoc:executable-prompt-input-of prompt)
            (hyperdoc:executable-prompt-input-of reloaded-prompt))
     "Executable prompt input layer must survive materialization")
    (s-expression-prompt-smoke-assert
     (equal (hyperdoc:executable-prompt-output-contract-of prompt)
            (hyperdoc:executable-prompt-output-contract-of reloaded-prompt))
     "Executable prompt output contract layer must survive materialization")
    (run-s-expression-prompt-generated-page-smoke-test)
    (format t "~&S-expression prompt roundtrip smoke test passed.~%")
    t))

(defun run-s-expression-prompt-generated-page-smoke-test ()
  (asdf:load-system :hyperdoc/s-expression-prompts)
  (let* ((program (s-expression-prompt-smoke-program))
         (prompt
           (hyperdoc:make-executable-prompt
            :knowledge '(:rules (:program-is-durable)
                         :authoring (:normal-hyperdoc-page-workflow))
            :input (getf (rest program) :input)
            :output-contract (getf (rest program) :output-contract)
            :topicmap-program program))
         (output-path (s-expression-prompt-smoke-temp-page-path)))
    (unwind-protect
         (let* ((report
                  (hyperdoc:materialize-s-expression-prompt-page
                   output-path
                   prompt
                   :title "Generated S-Expression Prompt Artifact"))
                (html (uiop:read-file-string output-path))
                (reloaded-program
                  (hyperdoc:hyperdoc-html-to-topicmap-program output-path))
                (program-validation
                  (hyperdoc:validate-topicmap-program-equivalence
                   program
                   reloaded-program)))
           (s-expression-prompt-smoke-assert
            (getf report :success-p)
            "Generated prompt page helper must validate its reload")
           (s-expression-prompt-smoke-assert
            (uiop:file-exists-p output-path)
            "Generated prompt page helper must write the output file")
           (s-expression-prompt-smoke-assert-contains
            "FedWiki story pane"
            html
            "Generated prompt page must expose the FedWiki story pane")
           (s-expression-prompt-smoke-assert-contains
            "Topicmap program pane"
            html
            "Generated prompt page must expose the topicmap program pane")
           (s-expression-prompt-smoke-assert-contains
            "Validation pane"
            html
            "Generated prompt page must expose the validation pane")
           (s-expression-prompt-smoke-assert-contains
            "SLY mREPL replay pane"
            html
            "Generated prompt page must expose the SLY mREPL replay pane")
           (s-expression-prompt-smoke-assert-contains
            "Optional inspector replay pane"
            html
            "Generated prompt page must expose the optional inspector replay pane")
           (s-expression-prompt-smoke-assert-contains
            "data-hyperdoc-topicmap-program=\"true\""
            html
            "Generated prompt page must embed the durable topicmap program")
           (s-expression-prompt-smoke-assert-contains
            "(asdf:load-system :hyperdoc/s-expression-prompts)"
            html
            "Generated prompt page must include pure-core SLY replay")
           (s-expression-prompt-smoke-assert-contains
            "(asdf:load-system :hyperdoc/inspector)"
            html
            "Generated prompt page must include optional late inspector replay")
           (s-expression-prompt-smoke-assert
            (getf program-validation :success-p)
            "Generated prompt page reload must reconstruct an equivalent program")
           (format t "~&S-expression prompt generated page smoke test passed.~%")
           t)
      (when (probe-file output-path)
        (delete-file output-path)))))

(defun run-s-expression-prompt-smoke-tests ()
  (run-s-expression-prompt-pure-core-smoke-test)
  (run-s-expression-prompt-pure-boundary-smoke-test)
  (run-s-expression-prompt-roundtrip-smoke-test)
  (asdf:load-system :hyperdoc/explorer)
  (run-s-expression-prompt-inspector-smoke-test)
  (format t "~&S-expression prompt split-view smoke tests passed.~%")
  t)
