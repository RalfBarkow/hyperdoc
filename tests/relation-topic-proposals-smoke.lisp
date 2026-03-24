;;;; Smoke tests for reviewed relation-to-topic proposals

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-RELATION-TOPIC-PROPOSALS-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun relation-proposal-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun relation-proposal-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun relation-proposal-make-temp-root ()
  (let* ((base (uiop:temporary-directory))
         (name (format nil "hyperdoc-relation-topic-~A/"
                       (gensym "TEST-")))
         (path (merge-pathnames name base)))
    (uiop:ensure-directory-pathname path)))

(defun relation-proposal-write-string-file (path content)
  (uiop:ensure-all-directories-exist (list path))
  (with-open-file (stream path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :external-format :utf-8)
    (write-string content stream)))

(defun relation-proposal-read-string-file (path)
  (uiop:read-file-string path))

(defun relation-proposal-existing-topics-file-content ()
  "(in-package :hyperdoc)\n\n(defun association-topics-topic ()\n  (make-topic\n   :id \"association-topics\"\n   :title \"Association topics\"\n   :summary \"Old summary to be replaced by the approved patch application.\"\n   :references '(\"Old reference\")))\n")

(defun run-relation-topic-proposal-existing-title-smoke-test ()
  (let* ((relation (hyperdoc::example-association-topics-relation))
         (proposal (hyperdoc::promote-relation-to-topic-proposal relation))
         (factory-form (hyperdoc::relation-topic-proposal-factory-form proposal)))
    (relation-proposal-assert-true
     (typep relation 'hyperdoc::dom-relation-annotation)
     "Example relation must be a dom-relation-annotation")
    (relation-proposal-assert-true
     (typep proposal 'hyperdoc::relation-topic-proposal)
     "Promotion must produce a relation-topic-proposal")
    (relation-proposal-assert-equal
     "Association topics"
     (hyperdoc::proposed-title-of proposal)
     "Specific relation kind should derive the exact topic title")
    (relation-proposal-assert-equal
     :merge-into-existing-topic
     (hyperdoc::merge-status-of proposal)
     "Exact-title collision must classify as merge-into-existing-topic")
    (relation-proposal-assert-true
     (typep (hyperdoc::existing-topic-of proposal) 'hyperdoc::topic)
     "Exact-title proposal must carry the existing topic object")
    (relation-proposal-assert-true
     (and (stringp factory-form)
          (plusp (length factory-form)))
     "Proposed topic factory text must be non-empty")))

(defun run-relation-topic-proposal-authoring-bundle-smoke-test ()
  (let* ((relation (hyperdoc::example-association-topics-relation))
         (proposal (hyperdoc::promote-relation-to-topic-proposal relation))
         (page-fragment
           (hyperdoc::relation-topic-proposal-page-fragment proposal))
         (bundle
           (hyperdoc::relation-topic-proposal-authoring-bundle proposal))
         (fedwiki-delta
           (hyperdoc::relation-topic-proposal-fedwiki-twin-delta proposal))
         (patch-plan
           (hyperdoc::make-relation-topic-patch-plan proposal)))
    (relation-proposal-assert-true
     (and (stringp page-fragment)
          (plusp (length page-fragment)))
     "Proposed HyperDoc page fragment must be non-empty")
    (relation-proposal-assert-true
     (search (hyperdoc::proposed-title-of proposal)
             page-fragment
             :test #'char=)
     "Proposed HyperDoc page fragment must contain the proposed title")
    (relation-proposal-assert-true
     (and (stringp bundle)
          (plusp (length bundle)))
     "Authoring bundle text must be non-empty")
    (relation-proposal-assert-true
     (and (stringp fedwiki-delta)
          (plusp (length fedwiki-delta)))
     "FedWiki twin delta text must be non-empty")
    (relation-proposal-assert-true
     (typep patch-plan 'hyperdoc::relation-topic-patch-plan)
     "Patch plan must be a relation-topic-patch-plan")
    (relation-proposal-assert-true
     (and (stringp (hyperdoc::topics-target-path-of patch-plan))
          (plusp (length (hyperdoc::topics-target-path-of patch-plan))))
     "Patch plan must carry a non-empty topics.lisp target path")
    (relation-proposal-assert-true
     (member (hyperdoc::topics-action-of patch-plan)
             '(:edit-existing-factory :append-new-factory))
     "Patch plan must classify the topics.lisp action")
    (relation-proposal-assert-true
     (and (stringp (hyperdoc::topics-payload-of patch-plan))
          (plusp (length (hyperdoc::topics-payload-of patch-plan))))
     "Patch plan must carry a non-empty topics.lisp payload")
    (relation-proposal-assert-true
     (member (hyperdoc::page-action-of patch-plan)
             '(:edit-existing-page :create-new-page :no-page-needed))
     "Patch plan must classify the page action")))

(defun run-relation-topic-proposal-review-wording-smoke-test ()
  (let* ((relation
           (make-instance
            'hyperdoc::dom-relation-annotation
            :id "dom-relation/example-review-wording"
            :title "Association: source -> target"
            :summary "Minimal relation for review-wording fallback."
            :context-view-title "Content"
            :source-anchor
            (make-instance 'hyperdoc::dom-annotation-anchor
                           :provider-kind "dom-v1"
                           :strategy "semantic-heading"
                           :value "source"
                           :label "Source seam"
                           :page-title
                           "Association Topics for Stable Identity and Mutable Titles")
            :target-anchor
            (make-instance 'hyperdoc::dom-annotation-anchor
                           :provider-kind "dom-v1"
                           :strategy "semantic-heading"
                           :value "target"
                           :label "Target seam"
                           :page-title
                           "Association Topics for Stable Identity and Mutable Titles")
            :relation-kind "unclassified association"))
         (proposal (hyperdoc::promote-relation-to-topic-proposal relation)))
    (relation-proposal-assert-equal
     :new-topic
     (hyperdoc::merge-status-of proposal)
     "Generic relation kinds should stay in reviewed new-topic status")
    (relation-proposal-assert-true
     (search "Review relation topic:"
             (hyperdoc::proposed-title-of proposal)
             :test #'char=)
     "Generic relation kinds must require explicit review wording")))

(defun run-relation-topic-patch-plan-no-approval-smoke-test ()
  (let* ((root (relation-proposal-make-temp-root))
         (topics-path (merge-pathnames "hyperdoc/topics.lisp" root))
         (page-path
           (merge-pathnames "hyperdoc/Association topics.html" root))
         (initial-content
           (relation-proposal-existing-topics-file-content))
         (proposal
           (hyperdoc::promote-relation-to-topic-proposal
            (hyperdoc::example-association-topics-relation)))
         approval-error-signaled)
    (relation-proposal-write-string-file topics-path initial-content)
    (let ((hyperdoc::*relation-topic-patch-repo-root* root))
      (let ((plan (hyperdoc::make-relation-topic-patch-plan proposal)))
        (handler-case
            (hyperdoc::apply-relation-topic-patch-plan plan nil)
          (hyperdoc::relation-topic-patch-approval-required ()
            (setf approval-error-signaled t)))
        (relation-proposal-assert-true
         approval-error-signaled
         "Missing approval token must signal a clear approval-required condition")
        (relation-proposal-assert-equal
         initial-content
         (relation-proposal-read-string-file topics-path)
         "Missing approval token must leave topics.lisp content unchanged")
        (relation-proposal-assert-true
         (null (probe-file page-path))
         "Missing approval token must not create a page file")))))

(defun run-relation-topic-patch-plan-approval-application-smoke-test ()
  (let* ((root (relation-proposal-make-temp-root))
         (topics-path (merge-pathnames "hyperdoc/topics.lisp" root))
         (proposal
           (hyperdoc::promote-relation-to-topic-proposal
            (make-instance
             'hyperdoc::dom-relation-annotation
             :id "dom-relation/example-patch-application"
             :title "Association: source -> target"
             :summary "Minimal relation for approved patch-plan application."
             :context-view-title "Content"
             :source-anchor
             (make-instance 'hyperdoc::dom-annotation-anchor
                            :provider-kind "dom-v1"
                            :strategy "semantic-heading"
                            :value "source"
                            :label "Source seam"
                            :page-title
                            "Association Topics for Stable Identity and Mutable Titles")
             :target-anchor
             (make-instance 'hyperdoc::dom-annotation-anchor
                            :provider-kind "dom-v1"
                            :strategy "semantic-heading"
                            :value "target"
                            :label "Target seam"
                            :page-title
                            "Association Topics for Stable Identity and Mutable Titles")
             :relation-kind "Patch application seam"))))
    (relation-proposal-write-string-file topics-path "(in-package :hyperdoc)\n")
    (let ((hyperdoc::*relation-topic-patch-repo-root* root))
      (let* ((plan (hyperdoc::make-relation-topic-patch-plan proposal))
             (page-path (merge-pathnames
                         (hyperdoc::page-target-path-of plan)
                         root))
             (result
               (hyperdoc::apply-relation-topic-patch-plan
                plan
                hyperdoc::*relation-topic-patch-approval-token*)))
        (relation-proposal-assert-true
         (typep result 'hyperdoc::approved-relation-topic-patch-application)
         "Valid approval token must return an application result object")
        (relation-proposal-assert-equal
         (list (hyperdoc::topics-action-of plan)
               (hyperdoc::page-action-of plan))
         (hyperdoc::actions-performed-of result)
         "Application result actions must match the patch-plan classification")
        (relation-proposal-assert-true
         (search (hyperdoc::topics-payload-of plan)
                 (relation-proposal-read-string-file topics-path)
                 :test #'char=)
         "Approved application must write the topics.lisp payload")
        (relation-proposal-assert-true
         (probe-file page-path)
         "Approved application must create the planned page file when required")
        (relation-proposal-assert-true
         (search (hyperdoc::page-payload-of plan)
                 (relation-proposal-read-string-file page-path)
                 :test #'char=)
         "Approved application must write the page payload")
        (relation-proposal-assert-true
         (every (lambda (path)
                  (not (search ".wiki" path :test #'char=)))
                (hyperdoc::applied-paths-of result))
         "Approved application must not write FedWiki paths")))))

(defun run-relation-topic-proposals-smoke-tests ()
  (run-relation-topic-proposal-existing-title-smoke-test)
  (run-relation-topic-proposal-authoring-bundle-smoke-test)
  (run-relation-topic-proposal-review-wording-smoke-test)
  (run-relation-topic-patch-plan-no-approval-smoke-test)
  (run-relation-topic-patch-plan-approval-application-smoke-test)
  (format t "~&Relation topic proposal smoke tests passed.~%")
  t)
