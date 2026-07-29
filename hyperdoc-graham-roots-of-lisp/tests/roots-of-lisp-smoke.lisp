;;;; Smoke tests for the executable Roots of Lisp source station.

(in-package #:hyperdoc-graham-roots-of-lisp/tests)

(defun assert-true (value format-control &rest arguments)
  (unless value
    (error "Roots smoke test failed: ~?"
           format-control arguments)))

(defun assert-object-equal (actual expected label)
  (assert-true
   (hyperdoc-graham-roots-of-lisp:roots-object-equal actual expected)
   "~A: expected ~S, got ~S"
   label expected actual))

(defun evaluation-result (evaluation)
  (assert-true
   (eq (hyperdoc-graham-roots-of-lisp:status-of evaluation) :ok)
   "evaluation failed: ~A"
   (hyperdoc-graham-roots-of-lisp:condition-of evaluation))
  (hyperdoc-graham-roots-of-lisp:result-of evaluation))

(defun render-roots-html-fragment (thunk)
  (with-output-to-string (stream)
    (let ((html-inspector-views::*html-stream* stream)
          (html-inspector-views::*view-accumulator*
            (make-instance 'html-inspector-views::view-accumulator)))
      (funcall thunk))))

(defun roots-test-temporary-directory ()
  (let ((directory
          (merge-pathnames
           (format nil "roots-lynn-missing-~A/" (gensym))
           (uiop:temporary-directory))))
    (ensure-directories-exist (merge-pathnames "placeholder" directory))
    directory))

(defparameter *required-roots-examples*
  '((hyperdoc-graham-roots-of-lisp:roots-seven-primitives-example
     "The Roots of Lisp reconstruction layers")
    (hyperdoc-graham-roots-of-lisp:roots-lambda-and-label-example
     "The Surprise as an evaluation trace")
    (hyperdoc-graham-roots-of-lisp:roots-direct-subst-example
     "The Surprise as an evaluation trace")
    (hyperdoc-graham-roots-of-lisp:roots-surprise-example
     "The Surprise as an evaluation trace")
    (hyperdoc-graham-roots-of-lisp:roots-named-call-double-evaluation-example
     "Which bugs did Graham correct?")
    (hyperdoc-graham-roots-of-lisp:roots-dynamic-binding-capture-example
     "Dynamic capture in MAPLIST and DIFF")))

(defun required-roots-example-entry (function-symbol entries)
  (or (find function-symbol
            entries
            :key #'hyperdoc:example-entry-function-of)
      (error "Required Roots example was not discovered: ~S"
             function-symbol)))

(defun run-roots-example-registration-smoke-tests ()
  (let ((entries
          (hyperdoc:discover-examples
           :system "hyperdoc-graham-roots-of-lisp")))
    (dolist (expectation *required-roots-examples*)
      (destructuring-bind (function-symbol expected-page) expectation
        (let ((entry (required-roots-example-entry function-symbol entries)))
          (assert-true
           (string= "hyperdoc-graham-roots-of-lisp"
                    (hyperdoc:example-entry-system-of entry))
           "example ~S should retain its owning ASDF system"
           function-symbol)
          (assert-true
           (string= expected-page
                    (hyperdoc:example-entry-source-page-of entry))
           "example ~S page: expected ~S, got ~S"
           function-symbol
           expected-page
           (hyperdoc:example-entry-source-page-of entry))
          (assert-true
           (search "src/examples.lisp"
                   (namestring
                    (hyperdoc:example-entry-source-file-of entry)))
           "example ~S should navigate to src/examples.lisp"
           function-symbol)
          (let ((result (hyperdoc:run-example-entry entry)))
            (assert-true
             (typep result 'hyperdoc:example-result)
             "running ~S should return an EXAMPLE-RESULT"
             function-symbol)
            (assert-true
             (eq :success (hyperdoc:example-result-status-of result))
             "running ~S should succeed, got ~S"
             function-symbol
             (hyperdoc:example-result-status-of result))))))
    entries))

(defun run-roots-retrace-smoke-tests ()
  (let* ((comparison
           (hyperdoc-graham-roots-of-lisp:roots-named-call-double-evaluation-report))
         (mccarthy
           (hyperdoc-graham-roots-of-lisp:roots-comparison-mccarthy-evaluation-of
            comparison))
         (graham
           (hyperdoc-graham-roots-of-lisp:roots-comparison-graham-evaluation-of
            comparison))
         (expected
           (hyperdoc-graham-roots-of-lisp:roots-read-form "(a b c)")))
    (assert-true
     (eq :confirmed
         (hyperdoc-graham-roots-of-lisp:roots-comparison-replay-status-of
          comparison))
     "named-call comparison should confirm the reconstructed divergence")
    (assert-true
     (eq :error (hyperdoc-graham-roots-of-lisp:status-of mccarthy))
     "McCarthy named-call replay should capture a language error")
    (assert-true
     (typep (hyperdoc-graham-roots-of-lisp:condition-of mccarthy)
            'hyperdoc-graham-roots-of-lisp:roots-language-error)
     "historical failure should be a ROOTS-LANGUAGE-ERROR")
    (assert-true
     (hyperdoc-graham-roots-of-lisp:roots-object-equal
      (hyperdoc-graham-roots-of-lisp:roots-language-error-expression-of
       (hyperdoc-graham-roots-of-lisp:condition-of mccarthy))
      (hyperdoc-graham-roots-of-lisp:roots-read-form "(b c)"))
     "historical failure should identify (B C) as the second application")
    (assert-object-equal
     (evaluation-result graham)
     expected
     "Graham corrected named call")
    (assert-object-equal
     (evaluation-result
      (hyperdoc-graham-roots-of-lisp:roots-example-report :higher-order))
     expected
     "corrected named-call rule remains the default after historical replay")
    comparison))

(defun run-roots-dynamic-binding-smoke-test ()
  (let ((evaluation
          (hyperdoc-graham-roots-of-lisp:roots-dynamic-binding-capture-report)))
    (assert-object-equal
     (evaluation-result evaluation)
     (hyperdoc-graham-roots-of-lisp:roots-read-form "inner")
     "dynamic binding capture")
    evaluation))

(defun run-roots-lynn-runner-smoke-tests (subst-report)
  (let* ((artifact
           (hyperdoc-graham-roots-of-lisp:make-roots-lynn-runner-artifact))
         (registration
           (hyperdoc-graham-roots-of-lisp:register-roots-lynn-runtime-asset-path
            artifact))
         (checks
           (hyperdoc-graham-roots-of-lisp:roots-lynn-runner-asset-checks-of
            registration)))
    (assert-true
     (= 6 (length checks))
     "the fixed runner manifest should contain all six requested assets")
    (dolist (check checks)
      (assert-true
       (eq :ok
           (hyperdoc-graham-roots-of-lisp:roots-lynn-asset-check-status-of
            check))
       "runner asset failed presence/hash validation: ~A"
       check))
    (assert-true
     (hyperdoc-graham-roots-of-lisp:roots-lynn-runner-route-ready-p-of
      registration)
     "the stable runner route should be registered against the verified output")
    (let ((mime-function (find-symbol "MIME" "TRIVIAL-MIMES")))
      (assert-true
       (and mime-function (fboundp mime-function))
       "CLOG's MIME resolver should be available")
      (assert-true
       (string-equal
        "application/wasm"
        (funcall mime-function "doh.wasm"))
       "CLOG's MIME resolver should serve doh.wasm as application/wasm"))
    (let ((url
            (hyperdoc-graham-roots-of-lisp:roots-lynn-runner-local-public-url
             artifact)))
      (assert-true
       (uiop:string-suffix-p
        url
        "/roots-of-lisp-lynn/lambda/lisp.html")
       "runner URL should use the fixed public route, got ~A"
       url)
      (assert-true
       (string=
        (format nil "~A~%HEIGHT 720" url)
        (hyperdoc-graham-roots-of-lisp:roots-lynn-frame-item-text artifact))
       "FedWiki frame text should derive from the canonical route URL"))

    (let* ((page
             (hyperdoc-graham-roots-of-lisp:roots-lynn-fedwiki-page artifact))
           (story (hyperbook/fedwiki::story-of page))
           (frame-item (aref story 1))
           (adapted
             (hyperbook/fedwiki::adapt-plugin-like-story-item
              :frame frame-item page)))
      (assert-true
       (eq :frame (hyperbook/fedwiki::item-type-of frame-item))
       "the fixture's second story item should remain a real :FRAME item")
      (assert-true
       (string=
        (hyperdoc-graham-roots-of-lisp:roots-lynn-frame-item-text artifact)
        (hyperbook/fedwiki::text-of frame-item))
       "frame adaptation should preserve the source-faithful item text")
      (assert-true
       (typep adapted 'hyperbook/fedwiki::adapted-frame-snippet)
       "the source-faithful frame item should pass through the existing adapter")
      (assert-true
       (eq frame-item
           (hyperbook/fedwiki::adapted-frame-snippet-source-item-of adapted))
       "the adapted snippet should retain the original frame item")
      (assert-true
       (= 720
          (hyperbook/fedwiki::adapted-frame-snippet-height-of adapted))
       "the frame adapter should preserve HEIGHT 720"))

    (let* ((json-text
             (hyperdoc-graham-roots-of-lisp:roots-lynn-fedwiki-page-json
              artifact))
           (json (shasht:read-json json-text))
           (journal (gethash "journal" json)))
      (assert-true
       (string= "create" (gethash "type" (elt journal 0)))
       "copy-pasteable FedWiki JSON should begin its journal with create")
      (assert-true
       (loop for index below (1- (length journal))
             always (< (gethash "date" (elt journal index))
                       (gethash "date" (elt journal (1+ index)))))
       "copy-pasteable FedWiki journal dates should be strictly monotonic"))

    (let ((runner-html
            (render-roots-html-fragment
             (lambda ()
               (hyperdoc-graham-roots-of-lisp::roots-render-runner-artifact
                artifact)))))
      (assert-true (search "<iframe" runner-html :test #'char-equal)
                   "the ready native Runner view should contain an iframe")
      (assert-true (search "Open the local runner directly" runner-html)
                   "the native Runner view should contain a direct-open fallback")
      (assert-true (search "allow-scripts allow-same-origin" runner-html)
                   "the runner should declare its required iframe capabilities")
      (assert-true (search "not a compute sandbox" runner-html)
                   "the same-origin scripted iframe should state its trust boundary"))

    (let* ((surface
             (hyperdoc-graham-roots-of-lisp:make-roots-lynn-runner-surface
              :artifact artifact
              :common-lisp-report subst-report))
           (side-by-side-html
             (render-roots-html-fragment
              (lambda ()
                (hyperdoc-graham-roots-of-lisp::roots-render-side-by-side-surface
                 surface)))))
      (assert-true
       (search "data-roots-lynn-representation='fedwiki-frame'"
               side-by-side-html
               :test #'char-equal)
       "side-by-side Browser view should contain the FedWiki representation")
      (assert-true
       (search "data-roots-lynn-representation='native-hyperdoc'"
               side-by-side-html
               :test #'char-equal)
       "side-by-side Browser view should contain the native HyperDoc representation")
      (assert-true
       (search "data-story-item-type='frame'" side-by-side-html
               :test #'char-equal)
       "left panel should render the real source-faithful :FRAME story item")
      (assert-true
       (>= (loop with start = 0
                 for found = (search "<iframe" side-by-side-html
                                     :start2 start
                                     :test #'char-equal)
                 while found
                 count t
                 do (setf start (1+ found)))
           2)
       "the two panels should contain independent Lynn runner iframes"))

    (let* ((missing-root (roots-test-temporary-directory))
           (missing-artifact
             (hyperdoc-graham-roots-of-lisp:make-roots-lynn-runner-artifact
              :asset-root missing-root)))
      (unwind-protect
           (progn
             (let ((malformed-asset
                     (merge-pathnames "lambda/lisp.html" missing-root)))
               (ensure-directories-exist malformed-asset)
               (with-open-file (stream malformed-asset
                                       :direction :output
                                       :if-exists :supersede
                                       :if-does-not-exist :create)
                 (write-string "not the pinned asset" stream)))
             (let* ((failure-status
                      (hyperdoc-graham-roots-of-lisp:roots-lynn-runner-readiness
                       missing-artifact))
                    (failure-html
                   (render-roots-html-fragment
                    (lambda ()
                      (hyperdoc-graham-roots-of-lisp::roots-render-runner-artifact
                       missing-artifact)))))
             (assert-true
              (find
               :hash-mismatch
               (hyperdoc-graham-roots-of-lisp:roots-lynn-runner-asset-checks-of
                failure-status)
               :key
               #'hyperdoc-graham-roots-of-lisp:roots-lynn-asset-check-status-of)
              "a malformed present asset should fail closed as hash-mismatch")
             (assert-true
              (search "Runner unavailable" failure-html)
              "missing assets should produce a visible inspectable failure")
             (assert-true
              (search "Inspect failure" failure-html)
              "missing assets should expose the typed failure object")
             (assert-true
              (not (search "<iframe" failure-html :test #'char-equal))
              "missing or malformed assets should withhold broken iframe HTML")))
        (uiop:delete-directory-tree missing-root :validate t :if-does-not-exist :ignore)))

    (let* ((source-path
             (hyperdoc-graham-roots-of-lisp::roots-system-relative-pathname
              "src/lynn-runner.lisp"))
           (source (uiop:read-file-string source-path)))
      (assert-true
       (search
        "(defun make-roots-lynn-runner-artifact (&key (asset-root"
        source
        :test #'char-equal)
       "the public constructor should expose only local asset relocation")
      (assert-true
       (not (search "drakma:http-request" source :test #'char-equal))
       "the bounded integration should not introduce a generic reverse proxy")
      (assert-true
       (not (search "postmessage" source :test #'char-equal))
       "the bounded comparison should not introduce cross-pane synchronization"))))

(defun run-roots-of-lisp-smoke-tests ()
  (let* ((quote-report
           (hyperdoc-graham-roots-of-lisp:roots-example-report :quote))
         (subst-report
           (hyperdoc-graham-roots-of-lisp:roots-direct-subst-report))
         (surprise-report
           (hyperdoc-graham-roots-of-lisp:roots-surprise-report))
         (expected-list
           (hyperdoc-graham-roots-of-lisp:roots-read-form "(a b c)"))
         (expected-subst
           (hyperdoc-graham-roots-of-lisp:roots-read-form
            "(a m (a m c) d)"))
         (dotted
           (hyperdoc-graham-roots-of-lisp:roots-evaluate-source
            "(quote (a . b))")))
    (run-roots-example-registration-smoke-tests)
    (run-roots-retrace-smoke-tests)
    (run-roots-dynamic-binding-smoke-test)
    (assert-object-equal
     (evaluation-result quote-report)
     expected-list
     "QUOTE")
    (assert-object-equal
     (evaluation-result subst-report)
     expected-subst
     "direct SUBST")
    (assert-object-equal
     (evaluation-result surprise-report)
     expected-subst
     "self-interpreted SUBST")
    (assert-true
     (consp (evaluation-result dotted))
     "quoted dotted pair should remain a cons")
    (assert-true
     (find :label-bind
           (hyperdoc-graham-roots-of-lisp:events-of subst-report)
           :key #'hyperdoc-graham-roots-of-lisp:kind-of)
     "direct SUBST trace should contain LABEL-BIND")
    (dolist (topic-id '("roots-graham-corrected-bugs"
                        "roots-dynamic-capture-maplist-diff"))
      (assert-true
       (hyperdoc-graham-roots-of-lisp:roots-topic-by-id topic-id)
       "required Roots topic should resolve by id: ~A"
       topic-id))
    (dolist (title '("Which bugs did Graham correct?"
                     "Dynamic capture in MAPLIST and DIFF"))
      (assert-true
       (hyperdoc-graham-roots-of-lisp:roots-topic-by-title title)
       "required Roots topic should resolve locally by title: ~A"
       title)
      (assert-true
       (hyperdoc::find-topic-by-title title)
       "required Roots topic should resolve in the Topics hyperbook: ~A"
       title))
    (assert-true
     (hyperdoc::find-topic-by-title
      "Roots of Lisp browser runner comparison")
     "the runner comparison topic should be registered in the Topics hyperbook")
    (assert-true
     (search
      "/hyperdoc-graham-roots-of-lisp/pages/"
      (namestring
       (hyperdoc:directory-of
       hyperdoc-graham-roots-of-lisp:*roots-hyperdoc*)))
     "the Roots HyperDoc should resolve its authored bundle directory")
    (assert-true
     (find "examples.lisp"
           (coerce
            (hyperdoc::code-pages-of
             hyperdoc-graham-roots-of-lisp:*roots-hyperdoc*)
            'list)
           :key (lambda (page)
                  (file-namestring
                   (asdf:component-pathname (hyperdoc::file-of page))))
           :test #'string=)
     "the Roots HyperDoc should expose src/examples.lisp as a code page")
    (assert-true
     (= 1
        (count "hyperdoc-graham-roots-of-lisp"
               (hyperbook:hyperbooks-of hyperbook:*catalog*)
               :key #'hyperbook:id-of
               :test #'string=))
     "the Roots of Lisp catalogue entry should appear exactly once")
    (dolist (page '("Which bugs did Graham correct?.html"
                    "Dynamic capture in MAPLIST and DIFF.html"))
      (assert-true
       (probe-file
        (hyperdoc-graham-roots-of-lisp::roots-system-relative-pathname
         (format nil "pages/~A" page)))
       "required authored page should exist: ~A"
       page))
    (run-roots-lynn-runner-smoke-tests subst-report)
    (format t
            "~&Roots of Lisp smoke tests passed: evaluator, registered examples, retrace cases, topics/pages, pinned Lynn assets, route, FedWiki frame seam, native runner, failure path, and side-by-side surface.~%")
    t))
