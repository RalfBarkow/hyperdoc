;;;; Smoke tests for executable S-expression prompt split views.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-S-EXPRESSION-PROMPT-PURE-CORE-SMOKE-TEST"
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

(defun run-s-expression-prompt-smoke-tests ()
  (run-s-expression-prompt-pure-core-smoke-test)
  (asdf:load-system :hyperdoc/explorer)
  (run-s-expression-prompt-inspector-smoke-test)
  (format t "~&S-expression prompt split-view smoke tests passed.~%")
  t)
