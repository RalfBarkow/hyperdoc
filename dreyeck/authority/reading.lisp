;;;; Authority Surface Witnesses
(defpackage #:dreyeck/authority/reading
  (:use #:cl)
  (:local-nicknames (#:ap #:dreyeck/authority-policy)
                    (#:hv #:html-inspector-views)
                    (#:hvs #:html-inspector-views/standard))
  (:export #:authority-demonstration #:uncontracted-marker #:reading-target
           #:upstream-operations-source #:invocation-path #:decision-objects
           #:policy-test-source #:render-expression-source))
(in-package #:dreyeck/authority/reading)


(dreyeck/hyperdoc:defhyperdoc *authority-reading*
  :id "dreyeck/authority/reading" :title "HyperDoc Authority: A Reading Path"
  :asdf-system-name "dreyeck/authority/reading"
  :subdirectory "dreyeck/pages/authority" :code-subdirectory "dreyeck/authority"
  :main-page-id "Using HyperDoc as a Library")
(HYPERDOC:SEE
  (HYPERDOC:PAGE "Using HyperDoc as a Library" :HYPERBOOK
                 "dreyeck/authority/reading"))
(HYPERDOC:SEE
  (HYPERDOC:PAGE "Reading the HyperDoc Authority Surface" :HYPERBOOK
                 "dreyeck/authority/reading"))
(HYPERDOC:SEE
  (HYPERDOC:PAGE "Extending HyperDoc Without Granting Authority" :HYPERBOOK
                 "dreyeck/authority/reading"))
(HYPERDOC:SEE
  (HYPERDOC:PAGE "Using Upstream Safely" :HYPERBOOK
                 "dreyeck/authority/reading"))

;;; Source evidence is read from the actual installed source, not reconstructed
;;; from the currently installed generic function (which dreyeck replaces).
(defstruct source-evidence origin text)
(hv:defview evidence-source (evidence source-evidence)
  (hv:html-view :title "Source" :priority 0
    (hv:html (:p (hv:esc (source-evidence-origin evidence)))
             (:pre (hv:esc (source-evidence-text evidence))))))
(defun source-form (system file marker)
  (let* ((path (asdf:system-relative-pathname system file))
         (text (uiop:read-file-string path :external-format :utf-8))
         (start (search marker text)))
    (assert start () "Source marker absent: ~A / ~A: ~A" system file marker)
    (let ((definition (ap::%form-text text start)))
      (make-source-evidence
       :origin (format nil "~A / ~A — ~A [source SHA-256 ~A]"
                       system file marker
                       (ironclad:byte-array-to-hex-string
                        (ironclad:digest-sequence :sha256
                         (sb-ext:string-to-octets definition :external-format :utf-8))))
       :text definition))))

(hyperdoc:defexample upstream-operations-source
  (source-form "html-inspector-views" "basic.lisp" "(defview 👀operations (object t)"))

;;; Source/evidence example: inspect the definitions of the invocation path.
;;; The live generic includes dreyeck methods. No browser event is exercised.
(hyperdoc:defexample invocation-path
  (list :evaluate-button
        (source-form "html-inspector-views" "html.lisp" "(defun eval-button")
        :eval-reference (source-form "html-inspector-views" "html.lisp" "(defun eval-id")
        :reference-map (source-form "html-inspector-views" "html.lisp" "(defun html-id")
        :browser-handler
        (source-form "clog-moldable-inspector" "inspector.lisp" "(defun set-event-handlers")
        :active-button
        (source-form "clog-moldable-inspector" "inspector.lisp" "(defun eval-thunk-with-active-button")
        :thunk-dispatch (source-form "html-inspector-views" "thunks.lisp" "(defgeneric eval-thunk")
        :live-thunk-generic #'hv:eval-thunk))

(defun reading-target ()
  (hyperbook:find-page *authority-reading* "Authority Surface Witnesses" :signal-error? t))
(defun page-method (generic)
  (find-method generic '() (list (find-class 'hyperbook:page))))

;;; Deliberately no operation contract. Applicability is its only offer.
;;; The method has no file, network, process, registry or object mutation.
(defgeneric uncontracted-marker (page))
(defmethod uncontracted-marker ((page hyperbook:page))
  (declare (ignore page))
  :applicable-only)

(HYPERDOC:DEFEXAMPLE DECISION-OBJECTS
  (LET ((METHOD (PAGE-METHOD #'UNCONTRACTED-MARKER)))
    (LIST :TARGET (READING-TARGET) :UNCONTRACTED-METHOD METHOD
          :UNCONTRACTED-GENERIC #'UNCONTRACTED-MARKER :CONTRACT
          (AP:METHOD-CONTRACT METHOD) :DECISION #'AP:INVOCATION-DECISION
          :METHOD-DECISION #'AP:METHOD-INVOCATION-DECISION :GATE-METHOD
          (FIND-METHOD #'HV:EVAL-THUNK 'NIL
                       (LIST (FIND-CLASS 'AP:OPERATION-THUNK)))
          :OPERATIONS-NOW #'HVS::👀OPERATIONS :CONTRACTED-METHOD
          (PAGE-METHOD #'HYPERBOOK:PATH-ITEM-OF) :OBSERVATIONAL-CONTRACT
          (AP:FIND-OPERATION-CONTRACT "hyperbook:path-item-of on page")
          :LOAD-PAGE-CONTRACT (AP:FIND-OPERATION-CONTRACT "hyperdoc:load-page")
          :UPSTREAM-LOAD-PAGE-METHOD
          (FIND-METHOD #'HYPERDOC:LOAD-PAGE 'NIL
                       (LIST (FIND-CLASS 'HYPERDOC::CODE-PAGE))))))

(defun operations-view (page)
  (hvs::👀operations page))
(defun rendered-references (view)
  (hv:view-html view)
  (mapcar #'cdr (hv:view-references view)))
(defun thunk-for-method-p (reference method)
  (and (typep reference 'ap:operation-thunk)
       (eq method (ap::operation-thunk-method reference))))
(defun under-served-policy (fn)
  "Exercise the real policy with served, non-development parameters.
This dynamic binding starts no server and never disables a running policy."
  (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server))
         (list (list "700px" nil))
    (funcall fn)))

;;; Behavioral witness of current dreyeck containment, not pristine upstream.
;;; Dynamic served parameters select the typed method-thunk gate; no browser
;;; event is exercised. The lexical counter checks entry to the refused body.
;;; The permitted reader checks its result and the Page ID, not all Page state.
(hyperdoc:defexample authority-demonstration
  (under-served-policy
   (lambda ()
     (let* ((target (reading-target))
            (method (page-method #'uncontracted-marker))
            (reader (page-method #'hyperbook:path-item-of))
            (contract (ap:method-contract reader))
            (id-before (hyperbook:id-of target))
            (view (operations-view target))
            (references (rendered-references view))
            (calls 0)
            (thunk (make-instance 'ap:operation-thunk :method method :target target
                     :fn (lambda () (incf calls) (uncontracted-marker target))))
            (refusal (hv:eval-thunk thunk))
            (reader-thunk (find-if (lambda (ref) (thunk-for-method-p ref reader)) references)))
       (assert (member method (hvs::find-applicable-methods target)))
       (assert (member method references))
       (assert (null (ap:method-contract method)))
       (assert (notany (lambda (ref) (thunk-for-method-p ref method)) references))
       (assert (typep refusal 'ap:invocation-refused))
       (assert (zerop calls))
       (assert (member reader (hvs::find-applicable-methods target)))
       (assert (member reader references))
       (assert (eq contract (ap:find-operation-contract "hyperbook:path-item-of on page")))
       (assert (equal '(:observational) (ap:contract-effect-classes contract)))
       (assert (ap::%capability-present-p (ap:contract-required-capability contract)))
       (assert (ap:method-invocation-decision reader))
       (assert reader-thunk)
       (let ((reader-result (hv:eval-thunk reader-thunk)))
         (assert (equal reader-result id-before))
         (assert (equal (hyperbook:id-of target) id-before))
         (list :policy-enforced (ap:policy-enforced-p)
               :target target :operations-view view
               :uncontracted
               (list :method method :exists t :applicable t :inspector-visible t
                     :contract nil :evaluate-offered nil :guarded-attempt thunk
                     :invocation :refused :result refusal :thunk-body-calls calls)
               :contracted
               (list :method reader :exists t :applicable t :inspector-visible t
                     :contract contract :effect-classes (ap:contract-effect-classes contract)
                     :required-capability (ap:contract-required-capability contract)
                     :capability-present t :invocation-permitted t :evaluate-thunk reader-thunk
                     :result reader-result :page-id-unchanged t)))))))


;;; Source groups for the Library definitions view and the Text Pages.
(defun library-boundary ()
  (let* ((file "docs/hyperdoc-upstream-boundary.md")
         (path (asdf:system-relative-pathname "dreyeck" file))
         (text (uiop:read-file-string path :external-format :utf-8)))
    (make-source-evidence
     :origin (format nil "dreyeck / ~A [source SHA-256 ~A]" file
                     (ironclad:byte-array-to-hex-string
                      (ironclad:digest-sequence :sha256
                       (sb-ext:string-to-octets text :external-format :utf-8))))
     :text text)))

(defun discovery-sources ()
  (list
   (source-form "html-inspector-views" "swank.lisp"
                "(defun find-applicable-methods")
   (source-form "html-inspector-views" "swank.lisp"
                "(defun find-specializers-with-superclasses")
   (source-form "html-inspector-views" "basic.lisp"
                "(defun callable-with-one-arg?")))

(defun upstream-page-methods ()
  (list
   (source-form "hyperdoc/explorer" "hyperdoc-explorer/html-pages.lisp"
                "(defmethod load-page ((page html-page))")
   (source-form "hyperdoc/explorer" "hyperdoc-explorer/code-pages.lisp"
                "(defmethod load-page ((page code-page))")
   (source-form "hyperbook" "hyperbook/hyperbooks.lisp"
                "(defgeneric path-item-of")))

(defun policy-sources ()
  (list (source-form "dreyeck/authority-policy" "dreyeck/src/authority-policy.lisp"
                     "(defclass operation-contract")
        (source-form "dreyeck/authority-policy" "dreyeck/src/authority-policy.lisp"
                     "(defun method-contract")
        (source-form "dreyeck/authority-policy" "dreyeck/src/authority-policy.lisp"
                     "(defun policy-enforced-p")
        (source-form "dreyeck/authority-policy" "dreyeck/src/authority-policy.lisp"
                     "(defun %capability-present-p")
        (source-form "dreyeck/authority-policy" "dreyeck/src/authority-policy.lisp"
                     "(defun %permission-granted-p")
        (source-form "dreyeck/authority-policy" "dreyeck/src/authority-policy.lisp"
                     "(defun invocation-decision")
        (source-form "dreyeck/authority-policy" "dreyeck/src/authority-policy.lisp"
                     "(defun method-invocation-decision")
        (source-form "dreyeck/authority-policy" "dreyeck/src/authority-policy.lisp"
                     "(defmethod hvs::👀operations ((object t))")
        (source-form "dreyeck/authority-policy" "dreyeck/src/authority-policy.lisp"
                     "(defmethod hv:eval-thunk ((thunk operation-thunk))")))

(defun disclosure-sources ()
  (list (source-form "html-inspector-views" "pathnames.lisp" "(defview 👀items")
        (source-form "html-inspector-views" "pathnames.lisp"
                     "(defview 👀content")
        (source-form "dreyeck/authority-policy"
                     "dreyeck/src/authority-policy.lisp"
                     "(defun allowed-disclosure-roots")
        (source-form "dreyeck/authority-policy"
                     "dreyeck/src/authority-policy.lisp"
                     "(defun pathname-disclosure-permitted-p")))

(defun intake-sources ()
  (list
   (source-form "dreyeck" "dreyeck/src/upstream-intake.lisp"
                "(defun make-hyperdoc-page-loading-intake")
   (source-form "dreyeck/authority-policy" "dreyeck/src/authority-policy.lisp"
                "(defun containment-adapter-drift")
   (source-form "dreyeck"
                "dreyeck/tests/upstream-intake-smoke.lisp"
                "(defun check-authority-containment-as-reviewed")))

(defun library-definition-sections ()
  (let ((path (invocation-path)))
    (list
     (cons "1. Discovery — upstream source inspection"
           (append (discovery-sources) (list (upstream-operations-source))))
     (cons "2. Affordance construction — upstream source inspection"
           (loop for key in '(:evaluate-button :eval-reference :reference-map)
                 collect (getf path key)))
     (cons "3. Invocation — upstream source inspection"
           (loop for key in '(:browser-handler :active-button :thunk-dispatch)
                 collect (getf path key)))
     (cons "4. Downstream decision — adopted Page methods and dreyeck containment"
           (append (butlast (upstream-page-methods)) (policy-sources)))
     (cons "5. Refusal / permitted contrast — current dreyeck containment witness"
           (append
            (last (upstream-page-methods))
            (loop for marker in '("(defgeneric uncontracted-marker"
                                  "(defmethod uncontracted-marker"
                                  "(defun reading-target"
                                  "(defun page-method"
                                  "(defun operations-view"
                                  "(defun rendered-references"
                                  "(defun thunk-for-method-p"
                                  "(defun under-served-policy")
                  collect (source-form "dreyeck/authority/reading"
                                       "dreyeck/authority/reading.lisp" marker)))))))

(hv:defview authority-library-definitions (page hyperdoc::code-page)
  (when (and (eq (hyperbook:hyperbook-of page) *authority-reading*)
             (equal (hyperbook:id-of page) "Authority Surface Witnesses"))
    (hv:html-view :title "Library definitions" :priority 0
      (hv:html
        (:h1 "Authority Surface Witnesses")
        (:p "Discovery → affordance construction → invocation → downstream decision → refusal / permitted contrast.")
        (:p "The first three sections inspect upstream source. Section four reads the downstream decision. Section five contains a runnable witness of current dreyeck containment; it exercises neither pristine upstream nor a browser click.")
        (dolist (section (library-definition-sections))
          (hv:html
            (:h2 (hv:esc (car section)))
            (dolist (evidence (cdr section))
              (hv:html
                (:p (hv:object-ref evidence :display (source-evidence-origin evidence) :select "Source"))
                (:pre (hv:esc (source-evidence-text evidence)))))))
        (:p "Behavioral witness: the existing AUTHORITY-DEMONSTRATION checks visibility, absence of an Evaluate offer and refusal before the uncontracted thunk body. The permitted contrast returns the Page ID and checks that ID remains unchanged; :NONE requires no additional runtime capability.")
        (let ((evidence (source-form "dreyeck/authority/reading" "dreyeck/authority/reading.lisp"
                                    "(hyperdoc:defexample authority-demonstration")))
          (hv:html
            (:p (hv:object-ref evidence :display (source-evidence-origin evidence) :select "Source"))
            (hv:transclusion (hvs:source-code-view #'authority-demonstration))))
        (:h2 "What running each existing example establishes")
        (:table :class "inspector-table"
          (dolist (entry
                   '((upstream-operations-source
                      "Source object: the pinned upstream Operations form; does not render or execute upstream Operations.")
                     (invocation-path
                      "Source/evidence objects: Evaluate construction, browser handler and thunk dispatch. The live generic also includes dreyeck methods; no browser event is exercised.")
                     (decision-objects
                      "Evidence objects: methods, contracts and decision functions. Does not itself execute an invocation decision.")
                     (authority-demonstration
                      "Behavioral witness: the bounded refusal and permitted observational contrast under dynamic served parameters; no persistent or external effect.")
                     (policy-test-source
                      "Source objects: the existing composition tests and their helpers. Reading this example does not execute that suite or display recorded results.")
                     (render-expression-source
                      "Source/evidence objects: render-time PARSE-AND-EVAL paths. Does not execute or contain them; their authority remains unresolved.")))
            (hv:html
              (:tr (:td (hv:object-ref (symbol-function (first entry))
                                      :display (symbol-name (first entry)) :select "Source code"))
                   (:td (hv:esc (second entry)))))))
        (:p (hv:object-ref page :display "Complete Lisp file and all six existing run widgets" :select "Source"))
        (:p "Previous: "
         (hv:object-ref (hyperbook:find-page *authority-reading* "Reading the HyperDoc Authority Surface" :signal-error? t)
                        :display "Reading the HyperDoc Authority Surface" :select "Content")
         ". Next: "
         (hv:object-ref (hyperbook:find-page *authority-reading* "Extending HyperDoc Without Granting Authority" :signal-error? t)
                        :display "Extending HyperDoc Without Granting Authority" :select "Content"))))))

;;; Current test source, not a recorded result: dreyeck/authority-policy/tests
;;; runs these forms; reading them here does not.
(hyperdoc:defexample policy-test-source
  (loop for marker in '("(defvar *probe-calls*"
                         "(defgeneric probe-effect"
                         "(defmethod probe-effect"
                         "(defun served"
                         "(defun %code-page"
                         "(defun %view"
                         "(defun %operations"
                         "(defun %references"
                         "(defun %operation-thunks"
                         "(defun %offered-p"
                         "(defun %method"
                         "(defun %forged"
                         "(defun check-operations-stay-inspectable"
                         "(defun check-uncontracted-invocation-refused")
        collect (source-form "dreyeck" "dreyeck/tests/authority-policy.lisp" marker)))
(hyperdoc:defexample render-expression-source
  (list :html-generator
        (source-form "hyperdoc/explorer" "hyperdoc-explorer/html-pages.lisp"
                     "(plump:define-tag-printer html-generator")
        :expression-link
        (source-form "hyperdoc/explorer" "hyperdoc-explorer/html-pages.lisp"
                     "(defun serialize-a-expr-element")
        :parse-and-eval (fdefinition 'hyperdoc::parse-and-eval)))

;;; Only the named reading examples are reviewed here. The marker METHOD above
;;; remains uncontracted. These example contracts permit observation, including
;;; an explicitly refused attempt; they do not authorize arbitrary page code.
(dolist (name '(upstream-operations-source invocation-path decision-objects
                authority-demonstration policy-test-source render-expression-source))
  (ap:register-operation-contract
   :identity (format nil "authority-reading/~A" (string-downcase name))
   :operation (format nil "DREYECK/AUTHORITY/READING::~A" name)
   :applicability :example :status :contracted :effect-classes '(:observational)
   :effect-extent "Reads repository/dependency source and image metadata; allocates ephemeral evidence; the demonstration changes only a lexical counter and dynamic server parameters"
   :authority "the named reading example and its explicit source files/objects"
   :preconditions "reading system loaded; demonstration enforces non-development served policy dynamically"
   :postconditions "no file, registry, server, network or inspected target is changed by running the example"
   :verification-evidence "dreyeck/authority/reading/tests: method visible, no Evaluate, thunk refused before its body, contracted PATH-ITEM-OF runs; gate-removal control fails"
   :replay-semantics "repeatable observation"
   :audit-provenance "dreyeck/authority/reading, source reviewed 2026-09-30"))
