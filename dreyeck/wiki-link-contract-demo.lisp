;;;; Wiki-link title and slug lookup contract examples

(defpackage :dreyeck/wiki-link-contract-demo
  (:use :cl)
  (:import-from :hyperdoc
                #:defexample
                #:defhyperdoc)
  (:export
   #:wiki-link-lookup-observation
   #:wiki-link-lookup-observation-route
   #:wiki-link-lookup-observation-lookup-value
   #:wiki-link-lookup-observation-outcome
   #:wiki-link-lookup-resolved-p
   #:wiki-link-lookup-evidence-shape
   #:wiki-link-route-evidence-relation
   #:same-resolved-target-p
   #:installed-lookup-pattern))

(in-package :dreyeck/wiki-link-contract-demo)

(defstruct (wiki-link-lookup-observation
            (:constructor %make-wiki-link-lookup-observation
                (route lookup-value outcome)))
  "A fact-preserving observation of one Wiki-link lookup execution.

ROUTE documents the operation invoked: :TITLE, :SLUG, or :INSTALLED.
LOOKUP-VALUE is the exact string supplied to that operation, or the target
slug captured by the installed Wiki-link thunk. OUTCOME is the actual
FEDWIKI-PAGE returned or the actual WIKI-LOOKUP-FAILURE observed."
  (route nil :type (member :title :slug :installed))
  (lookup-value nil :type string)
  outcome)

(defun %make-wiki-link-demo-source-page ()
  (let ((wiki (make-instance 'hyperbook/fedwiki::fedwiki
                             :id "fedwiki:example.test")))
    (setf (hyperbook/fedwiki::status-of wiki) t)
    (hyperbook/fedwiki::make-fedwiki-page
     wiki "source-page" "Source Page")))

(defun %call-with-global-plugin-page-lookup-disabled (thunk)
  "Call THUNK while globally replacing GET-PLUGIN-PAGE with a NIL result.

This is a serial-only white-box demonstration mechanism. It mutates the
symbol function globally and is not safe for concurrent execution."
  (let* ((name 'hyperbook/fedwiki::get-plugin-page)
         (original (symbol-function name)))
    (unwind-protect
         (progn
           (setf (symbol-function name)
                 (lambda (wiki slug)
                   (declare (ignore wiki slug))
                   nil))
           (funcall thunk))
      (setf (symbol-function name) original))))

(defun %wiki-lookup-failure-slot-bound-p (condition slot)
  (slot-boundp condition slot))

(defun %wiki-lookup-failure-slot-value (condition slot)
  (when (%wiki-lookup-failure-slot-bound-p condition slot)
    (slot-value condition slot)))

(defun %wiki-lookup-failure-slug (condition)
  (%wiki-lookup-failure-slot-value condition 'hyperbook/fedwiki::slug))

(defun %wiki-lookup-failure-title-bound-p (condition)
  (%wiki-lookup-failure-slot-bound-p condition 'hyperbook/fedwiki::title))

(defun %wiki-lookup-failure-title (condition)
  (%wiki-lookup-failure-slot-value condition 'hyperbook/fedwiki::title))

(defun %fedwiki-page-p (value)
  ;; Intentional white-box dependency: both lookup functions return this
  ;; internal page class (including its REMOTE-FEDWIKI-PAGE subclass).
  (typep value 'hyperbook/fedwiki::fedwiki-page))

(defun %validated-wiki-link-route (route)
  (unless (member route '(:title :slug :installed))
    (error 'type-error
           :datum route
           :expected-type '(member :title :slug :installed)))
  route)

(defun %make-observation-from-outcome (route lookup-value outcome)
  (%validated-wiki-link-route route)
  (check-type lookup-value string)
  (cond
    ((or (%fedwiki-page-p outcome)
         (typep outcome 'hyperbook/fedwiki::wiki-lookup-failure))
     (%make-wiki-link-lookup-observation route lookup-value outcome))
    ((typep outcome 'condition)
     ;; MAKE-WIKI-LINK currently returns conditions from its stored thunk.
     ;; Re-signal an unrelated returned condition without translating it.
     (error outcome))
    (t
     (error "Wiki-link lookup route ~S for ~S returned ~S; expected a ~
FEDWIKI-PAGE or WIKI-LOOKUP-FAILURE."
            route lookup-value outcome))))

(defun %observe-wiki-lookup (route lookup-value thunk)
  "Observe THUNK, accepting only a FedWiki page or WIKI-LOOKUP-FAILURE."
  (handler-case
      (%make-observation-from-outcome route lookup-value (funcall thunk))
    (hyperbook/fedwiki::wiki-lookup-failure (condition)
      (%make-observation-from-outcome route lookup-value condition))))

(defun %wiki-link-lookup-outcome-kind (observation)
  (check-type observation wiki-link-lookup-observation)
  (let ((outcome (wiki-link-lookup-observation-outcome observation)))
    (cond
      ((%fedwiki-page-p outcome) :resolved)
      ((typep outcome 'hyperbook/fedwiki::wiki-lookup-failure) :failure)
      ((typep outcome 'condition) (error outcome))
      (t
       (error "Invalid Wiki-link observation outcome ~S; expected a ~
FEDWIKI-PAGE or WIKI-LOOKUP-FAILURE."
              outcome)))))

(defun wiki-link-lookup-resolved-p (observation)
  "Return true exactly when OBSERVATION retained a resolved FedWiki page."
  (eq :resolved (%wiki-link-lookup-outcome-kind observation)))

(defun wiki-link-lookup-evidence-shape (observation)
  "Derive the lookup evidence shape solely from the raw outcome and value.

The result is :TITLE-AND-SLUG-EVIDENCE, :SLUG-ONLY-EVIDENCE, :OTHER, or
:NOT-APPLICABLE. ROUTE does not participate in this classification."
  (if (wiki-link-lookup-resolved-p observation)
      :not-applicable
      (let* ((condition (wiki-link-lookup-observation-outcome observation))
             (lookup-value
               (wiki-link-lookup-observation-lookup-value observation))
             (condition-slug (%wiki-lookup-failure-slug condition))
             (title-bound-p (%wiki-lookup-failure-title-bound-p condition)))
        (cond
          ((and title-bound-p
                (equal lookup-value condition-slug)
                (equal lookup-value (%wiki-lookup-failure-title condition)))
           :title-and-slug-evidence)
          ((and (not title-bound-p)
                (equal lookup-value condition-slug))
           :slug-only-evidence)
          (t :other)))))

(defun wiki-link-route-evidence-relation (observation)
  "Compare OBSERVATION's declared route with its independently derived shape.

The result is :CONSISTENT, :INCONSISTENT, :NOT-DECLARED, or
:NOT-APPLICABLE."
  (if (wiki-link-lookup-resolved-p observation)
      :not-applicable
      (let ((route
              (%validated-wiki-link-route
               (wiki-link-lookup-observation-route observation)))
            (shape (wiki-link-lookup-evidence-shape observation)))
        (case route
          (:installed :not-declared)
          (:title
           (if (eq shape :title-and-slug-evidence)
               :consistent
               :inconsistent))
          (:slug
           (if (eq shape :slug-only-evidence)
               :consistent
               :inconsistent))))))

(defun same-resolved-target-p (first-observation second-observation)
  "Return true when both observations resolved to the identical page object."
  (and (wiki-link-lookup-resolved-p first-observation)
       (wiki-link-lookup-resolved-p second-observation)
       (eq (wiki-link-lookup-observation-outcome first-observation)
           (wiki-link-lookup-observation-outcome second-observation))))

(defun installed-lookup-pattern (observation)
  "Map a valid observation's actual outcome to the installed lookup pattern.

The result is :MATCHES-TITLE-PATH, :MATCHES-SLUG-PATH, :OTHER, or :RESOLVED."
  (case (wiki-link-lookup-evidence-shape observation)
    (:title-and-slug-evidence :matches-title-path)
    (:slug-only-evidence :matches-slug-path)
    (:other :other)
    (:not-applicable :resolved)))

(defexample wiki-link-successful-lookup-equivalence-example
  "Observe page-object identity for title and slug lookup of an existing page."
  (let* ((source-page (%make-wiki-link-demo-source-page))
         (wiki (hyperbook:hyperbook-of source-page))
         (target-title "Existing Human Title")
         (target-slug "existing-human-title")
         (target-page
           (hyperbook/fedwiki::make-fedwiki-page
            wiki target-slug target-title)))
    (setf (gethash target-slug (hyperbook/fedwiki::pages-of wiki))
          target-page)
    (list
     (%observe-wiki-lookup
      :title target-title
      (lambda ()
        (hyperbook/fedwiki::find-target-by-title target-title source-page)))
     (%observe-wiki-lookup
      :slug target-slug
      (lambda ()
        (hyperbook/fedwiki::find-target-by-slug target-slug source-page))))))

(defexample wiki-link-upstream-title-path-example
  "Observe the original title operation supplied with a target slug."
  (let* ((source-page (%make-wiki-link-demo-source-page))
         (target-slug "missing-human-title"))
    (%call-with-global-plugin-page-lookup-disabled
     (lambda ()
       (%observe-wiki-lookup
        :title target-slug
        (lambda ()
          (hyperbook/fedwiki::find-target-by-title
           target-slug source-page)))))))

(defexample wiki-link-strict-slug-path-example
  "Observe direct slug lookup for the same missing target slug."
  (let* ((source-page (%make-wiki-link-demo-source-page))
         (target-slug "missing-human-title"))
    (%call-with-global-plugin-page-lookup-disabled
     (lambda ()
       (%observe-wiki-lookup
        :slug target-slug
        (lambda ()
          (hyperbook/fedwiki::find-target-by-slug
           target-slug source-page)))))))

(defexample wiki-link-installed-thunk-example
  "Observe the Wiki-link thunk installed in the currently loaded image."
  (let* ((source-page (%make-wiki-link-demo-source-page))
         (target-title "Missing Human Title")
         (target-slug "missing-human-title")
         (link (hyperbook/fedwiki::make-wiki-link
                source-page
                :target-title target-title
                :target-slug target-slug))
         (captured-target-slug (hyperbook/fedwiki::target-slug-of link))
         ;; THUNK-OF yields the HTML-INSPECTOR-VIEWS thunk wrapper stored by
         ;; MAKE-WIKI-LINK. EVAL-THUNK is its required invocation protocol.
         (installed-thunk (hyperbook:thunk-of link)))
    (%call-with-global-plugin-page-lookup-disabled
     (lambda ()
       (%observe-wiki-lookup
        :installed captured-target-slug
        (lambda ()
          (html-inspector-views:eval-thunk installed-thunk)))))))

(defhyperdoc *wiki-link-contract-demo*
  :title "Dreyeck Wiki-link contract demonstration"
  :id "dreyeck/wiki-link-contract-demo"
  :asdf-system-name "dreyeck/wiki-link-contract-demo"
  :subdirectory "dreyeck/pages"
  :main-page-id "Wiki-link title and slug lookup contracts")
