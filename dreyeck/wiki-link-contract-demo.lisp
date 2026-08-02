;;;; Wiki-link title and slug lookup contract examples

(defpackage :dreyeck/wiki-link-contract-demo
  (:use :cl)
  (:import-from :hyperdoc
                #:defexample
                #:defhyperdoc))

(in-package :dreyeck/wiki-link-contract-demo)

(defstruct wiki-link-lookup-observation
  path
  target-title
  target-slug
  resolved-p
  resolved-page-id
  condition-type
  condition-slug
  title-evidence-bound-p
  condition-title
  strict-slug-contract
  installed-behavior
  interpretation
  same-target-p
  difference-visible-p)

(defun %make-wiki-link-demo-source-page ()
  (let ((wiki (make-instance 'hyperbook/fedwiki::fedwiki
                             :id "fedwiki:example.test")))
    (setf (hyperbook/fedwiki::status-of wiki) t)
    (hyperbook/fedwiki::make-fedwiki-page
     wiki "source-page" "Source Page")))

(defun %call-with-plugin-page-lookup-disabled (thunk)
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

(defun %condition-slot-value (condition slot)
  (when (slot-boundp condition slot)
    (slot-value condition slot)))

(defun %observe-missing-wiki-target
    (path target-title target-slug strict-slug-contract interpretation thunk)
  (%call-with-plugin-page-lookup-disabled
   (lambda ()
     (handler-case
         (let ((page (funcall thunk)))
           (make-wiki-link-lookup-observation
            :path path
            :target-title target-title
            :target-slug target-slug
            :resolved-p t
            :resolved-page-id (hyperbook:id-of page)
            :strict-slug-contract strict-slug-contract
            :interpretation interpretation))
       (hyperbook/fedwiki::wiki-lookup-failure (condition)
         (let ((title-bound-p
                 (slot-boundp condition 'hyperbook/fedwiki::title)))
           (make-wiki-link-lookup-observation
            :path path
            :target-title target-title
            :target-slug target-slug
            :resolved-p nil
            :condition-type (type-of condition)
            :condition-slug
            (%condition-slot-value condition 'hyperbook/fedwiki::slug)
            :title-evidence-bound-p title-bound-p
            :condition-title
            (%condition-slot-value condition 'hyperbook/fedwiki::title)
            :strict-slug-contract strict-slug-contract
            :interpretation interpretation)))))))

(defexample wiki-link-successful-lookup-equivalence-example
  "Observe effect equality for title and slug lookup of an existing page."
  (let* ((source-page (%make-wiki-link-demo-source-page))
         (wiki (hyperbook:hyperbook-of source-page))
         (target-title "Existing Human Title")
         (target-slug "existing-human-title")
         (target-page
           (hyperbook/fedwiki::make-fedwiki-page
            wiki target-slug target-title)))
    (setf (gethash target-slug (hyperbook/fedwiki::pages-of wiki))
          target-page)
    (let* ((by-title
             (hyperbook/fedwiki::find-target-by-title
              target-title source-page))
           (by-slug
             (hyperbook/fedwiki::find-target-by-slug
              target-slug source-page))
           (same-target-p (eq by-title by-slug)))
      (make-wiki-link-lookup-observation
       :path :title-and-slug
       :target-title target-title
       :target-slug target-slug
       :resolved-p t
       :resolved-page-id (hyperbook:id-of by-title)
       :strict-slug-contract :not-distinguished
       :interpretation
       "Equal local effects do not establish identical lookup contracts."
       :same-target-p same-target-p
       :difference-visible-p (not same-target-p)))))

(defexample wiki-link-upstream-title-path-example
  "Observe the original expression at upstream commit 0d5bd1b."
  (let* ((source-page (%make-wiki-link-demo-source-page))
         (target-title "Missing Human Title")
         (target-slug "missing-human-title"))
    (%observe-missing-wiki-target
     :upstream-title-path target-title target-slug :red
     "The supplied slug is also recorded as title evidence."
     (lambda ()
       (hyperbook/fedwiki::find-target-by-title target-slug source-page)))))

(defexample wiki-link-strict-slug-path-example
  "Observe the proposed expression under a strict slug contract."
  (let* ((source-page (%make-wiki-link-demo-source-page))
         (target-title "Missing Human Title")
         (target-slug "missing-human-title"))
    (%observe-missing-wiki-target
     :strict-slug-path target-title target-slug :green
     "The failure records slug evidence without asserting title evidence."
     (lambda ()
       (hyperbook/fedwiki::find-target-by-slug target-slug source-page)))))

(defexample wiki-link-installed-thunk-example
  "Classify the Wiki-link thunk installed in the currently loaded image."
  (let* ((source-page (%make-wiki-link-demo-source-page))
         (target-title "Missing Human Title")
         (target-slug "missing-human-title")
         (link (hyperbook/fedwiki::make-wiki-link
                source-page
                :target-title target-title
                :target-slug target-slug))
         (result
           (%call-with-plugin-page-lookup-disabled
            (lambda ()
              (html-inspector-views:eval-thunk
               (hyperbook:thunk-of link)))))
         (title-bound-p
           (and (typep result 'hyperbook/fedwiki::wiki-lookup-failure)
                (slot-boundp result 'hyperbook/fedwiki::title)))
         (condition-slug
           (and (typep result 'hyperbook/fedwiki::wiki-lookup-failure)
                (%condition-slot-value result 'hyperbook/fedwiki::slug)))
         (condition-title
           (and title-bound-p
                (%condition-slot-value result 'hyperbook/fedwiki::title)))
         (installed-behavior
           (cond
             ((and (equal target-slug condition-slug)
                   title-bound-p
                   (equal target-slug condition-title))
              :matches-title-path)
             ((and (equal target-slug condition-slug)
                   (not title-bound-p))
              :matches-slug-path)
             (t
              :other))))
    (make-wiki-link-lookup-observation
     :path :installed-wiki-link-thunk
     :target-title target-title
     :target-slug target-slug
     :resolved-p (typep result 'hyperbook:page)
     :resolved-page-id
     (and (typep result 'hyperbook:page)
          (hyperbook:id-of result))
     :condition-type
     (and (typep result 'condition) (type-of result))
     :condition-slug condition-slug
     :title-evidence-bound-p title-bound-p
     :condition-title condition-title
     :strict-slug-contract
     (case installed-behavior
       (:matches-title-path :red)
       (:matches-slug-path :green)
       (otherwise :undetermined))
     :installed-behavior installed-behavior
     :interpretation
     "This reports the real MAKE-WIKI-LINK thunk in the current image.")))

(defhyperdoc *wiki-link-contract-demo*
  :title "Dreyeck Wiki-link contract demonstration"
  :id "dreyeck/wiki-link-contract-demo"
  :asdf-system-name "dreyeck/wiki-link-contract-demo"
  :subdirectory "dreyeck/pages"
  :main-page-id "Wiki-link title and slug lookup contracts")
