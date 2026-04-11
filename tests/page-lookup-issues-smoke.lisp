;;;; Smoke tests for structured page-lookup issues
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-PAGE-LOOKUP-ISSUES-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun smoke-find-hyperdoc-page (title)
  (hyperbook:find-page hyperdoc:*hyperdoc* title :signal-error? t))

(defun smoke-heading-texts (page)
  (mapcar #'plump:text
          (plump:get-elements-by-tag-name (hyperbook:dom-of page) "h2")))

(defun smoke-fedwiki-link-texts (page)
  (loop for anchor in (plump:get-elements-by-tag-name (hyperbook:dom-of page) "a")
        for hb = (plump:get-attribute anchor "hyperbook")
        when (and hb (uiop:string-prefix-p "fedwiki:" hb))
          collect (plump:text anchor)))

(defun smoke-find-issue-by-target (issues target-id)
  (find target-id
        issues
        :test #'string=
        :key #'hyperbook:lookup-issue-expected-page-id-of))

(defun page-lookup-smoke-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun page-lookup-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun smoke-make-page-lookup-issue (target-hyperbook-id expected-page-id)
  (hyperbook:make-page-lookup-issue
   (make-condition 'simple-error
                   :format-control "Synthetic lookup issue"
                   :format-arguments nil)
   :source-hyperbook "hyperdoc"
   :source-page-id "Synthetic source page"
   :source-page-title "Synthetic source page"
   :source-section "Smoke"
   :link-text expected-page-id
   :target-hyperbook-id target-hyperbook-id
   :expected-page-id expected-page-id
   :classification :lookup-failure))

(defun page-lookup-smoke-tempdir ()
  (uiop:ensure-directory-pathname
   (merge-pathnames
    (format nil "page-lookup-issues-smoke-~D-~A/"
            (get-universal-time)
            (gensym "RUN"))
    (uiop:temporary-directory))))

(defun page-lookup-copy-file (from to)
  (uiop:ensure-all-directories-exist (list to))
  (with-open-file (in from :direction :input :external-format :utf-8)
    (with-open-file (out to
                         :direction :output
                         :if-exists :supersede
                         :if-does-not-exist :create
                         :external-format :utf-8)
      (uiop:copy-stream-to-stream in out)))
  to)

(defun topic-factory-test-state (symbol)
  (list :had-definition-p (fboundp symbol)
        :old-definition (and (fboundp symbol) (symbol-function symbol))
        :had-authoring-factory-p (nth-value 1
                                            (gethash symbol
                                                     hyperdoc::*topic-authoring-factories*))
        :old-authoring-factory (gethash symbol
                                        hyperdoc::*topic-authoring-factories*)))

(defun restore-topic-factory-test-state! (symbol state)
  (if (getf state :had-definition-p)
      (setf (fdefinition symbol) (getf state :old-definition))
      (fmakunbound symbol))
  (if (getf state :had-authoring-factory-p)
      (setf (gethash symbol hyperdoc::*topic-authoring-factories*)
            (getf state :old-authoring-factory))
      (remhash symbol hyperdoc::*topic-authoring-factories*))
  (hyperdoc::rebuild-topic-indexes))

(defun append-placeholder-topic-factory-to-file (title path)
  (with-open-file (stream path
                          :direction :output
                          :if-exists :append
                          :if-does-not-exist :error
                          :external-format :utf-8)
    (write-string (hyperdoc::page-lookup-placeholder-topic-form title) stream))
  path)

(defun rewrite-file-substring! (path old-substring new-substring)
  (let* ((content (uiop:read-file-string path))
         (position (search old-substring content :test #'char=)))
    (unless position
      (error "Substring ~S not found in ~A" old-substring path))
    (with-open-file (stream path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
      (write-string content stream :end position)
      (write-string new-substring stream)
      (write-string content
                    stream
                    :start (+ position (length old-substring)))))
  path)

(defun call-with-disposable-topic-source-copy (title thunk)
  (let* ((symbol (hyperdoc::page-lookup-title->factory-symbol title))
         (state (topic-factory-test-state symbol))
         (root (page-lookup-smoke-tempdir))
         (temp-topics (merge-pathnames "topics-copy.lisp" root))
         (original-topics (hyperdoc::page-lookup-topic-source-path)))
    (page-lookup-copy-file original-topics temp-topics)
    (unwind-protect
         (let ((hyperdoc::*page-lookup-topic-source-path* temp-topics))
           (funcall thunk symbol temp-topics original-topics))
      (restore-topic-factory-test-state! symbol state)
      (ignore-errors
        (uiop:delete-directory-tree root
                                    :validate t
                                    :if-does-not-exist :ignore)))))

(defun run-page-lookup-issues-smoke-tests ()
  (let* ((denk-page (smoke-find-hyperdoc-page "Denkpanzer paper 2013"))
         (denk-headings (smoke-heading-texts denk-page))
         (denk-counterpart-issues
           (slot-value denk-page 'hyperdoc::counterpart-section-issues))
         (denk-link-texts (smoke-fedwiki-link-texts denk-page)))
    (assert-true (member "FedWiki counterparts" denk-headings :test #'string=)
                 "Counterpart heading should be normalized away from Localhost")
    (assert-true (equal '("[wiki.ralfbarkow.ch] denkpanzer-paper-2013"
                          "[wiki.ralfbarkow.ch] denkpanzer-stren")
                        denk-link-texts)
                 "FedWiki counterpart links should be prefixed with their actual site")
    (assert-equal 1 (length denk-counterpart-issues)
                  "Denkpanzer page should record one mislabelled counterpart-section issue")
    (let ((issue (first denk-counterpart-issues)))
      (assert-equal :mislabelled-target-grouping
                    (hyperbook:lookup-issue-classification-of issue)
                    "Counterpart-section issue should be classified as mislabelled target grouping")
      (assert-equal :mislabelled-target
                    (hyperbook:lookup-issue-status-of issue)
                    "Counterpart-section issue should carry the dedicated status"))
    (let* ((writing-page (smoke-find-hyperdoc-page "Writing text pages"))
           (issues (hyperbook:lookup-issues-of writing-page))
           (missing-issue (smoke-find-issue-by-target issues
                                                     "Defining custom views")))
      (assert-true missing-issue
                   "Writing text pages should expose the missing Defining custom views target as a structured issue")
      (assert-equal :hyperdoc-page
                    (hyperbook:lookup-issue-target-kind-of missing-issue)
                    "Missing HyperDoc page should keep the HyperDoc page target kind")
      (assert-equal :missing-hyperdoc-page
                    (hyperbook:lookup-issue-classification-of missing-issue)
                    "Missing HyperDoc page should classify separately from FedWiki publication issues")
      (assert-equal :scaffold-hyperdoc-page
                    (hyperbook:lookup-issue-suggested-repair-of missing-issue)
                    "Missing HyperDoc page should propose a scaffold operation")
      (let ((repair (funcall (slot-value missing-issue 'hyperbook::repair-thunk))))
        (assert-true (typep repair 'hyperdoc::hyperdoc-authoring-scaffold-plan)
                     "Repair thunk should yield a HyperDoc authoring scaffold plan")
        (assert-equal :page
                      (hyperdoc::hyperdoc-authoring-scaffold-mode-of repair)
                      "Missing HyperDoc page scaffold should be page-mode")
        (assert-string= "Defining custom views"
                        (hyperdoc::hyperdoc-authoring-scaffold-page-id-of repair)
                        "Scaffold plan should keep the missing target id"))
      (hyperbook:mark-lookup-issue! missing-issue :fixed)
      (assert-equal :fixed
                    (hyperbook:lookup-issue-status-of missing-issue)
                    "Lookup-issue status should be markable from the operation flow")))
  (let* ((topic-issue
           (hyperbook:enrich-lookup-issue
            (smoke-make-page-lookup-issue "topics"
                                          "Synthetic missing topic")))
         (topic-repair (funcall (hyperbook::lookup-issue-repair-thunk-of topic-issue)))
         (topic-repair-views
           (page-lookup-load-inspector-views-for-object topic-repair))
         (overview-html
           (html-inspector-views:view-html
            (page-lookup-smoke-find-view-by-title topic-repair-views "Overview")))
         (freshness-html
           (html-inspector-views:view-html
            (page-lookup-smoke-find-view-by-title topic-repair-views "Freshness")))
         (repair-html
           (html-inspector-views:view-html
            (page-lookup-smoke-find-view-by-title topic-repair-views "Repair"))))
    (assert-equal :hyperdoc-topic-page
                  (hyperbook:lookup-issue-target-kind-of topic-issue)
                  "Topics targets should route to HyperDoc topic-page repair planning")
    (assert-equal :missing-hyperdoc-topic-page
                  (hyperbook:lookup-issue-classification-of topic-issue)
                  "Topics targets should classify as missing HyperDoc topic pages")
    (assert-equal :needs-topic-creation
                  (hyperbook:lookup-issue-status-of topic-issue)
                  "Missing topics should derive Needs topic from chunk state")
    (assert-equal :ensure-target-chunk
                  (hyperbook:lookup-issue-suggested-repair-of topic-issue)
                  "Topics targets should point to a target chunk repair path")
    (assert-true (typep topic-repair 'hyperdoc::topic-page-availability-chunk)
                 "Topic repair thunk should now expose the target chunk itself")
    (assert-equal :needs-topic-creation
                  (hyperdoc::topic-page-lookup-chunk-state topic-repair)
                  "Chunk state should diagnose a missing authored topic as Needs topic")
    (assert-true (typep (hyperdoc::issue-target-chunk topic-issue)
                        'hyperdoc::topic-page-availability-chunk)
                 "Topics lookup issues should compute a target chunk directly")
    (assert-true (search "Status reason" overview-html :test #'char=)
                 "Topic-page chunk overview should expose the runtime-derived status reason")
    (assert-true (search "No authored topic factory for this title exists in the bound topics source."
                         overview-html
                         :test #'char=)
                 "Topic-page chunk overview should explain the missing-topic status")
    (assert-true (search "Authored signature token" freshness-html :test #'char=)
                 "Topic-page chunk freshness view should show authored freshness evidence")
    (assert-true (search "Materialization signature token" freshness-html :test #'char=)
                 "Topic-page chunk freshness view should show materialization freshness evidence")
    (assert-true (search "Ensure the authored topic factory basis chunk first."
                         repair-html
                         :test #'char=)
                 "Topic-page chunk repair view should expose the missing-topic repair hint"))
  (call-with-disposable-topic-source-copy
   "Synthetic missing topic via chunk repair"
   (lambda (symbol temp-topics original-topics)
     (let* ((issue
              (hyperbook:enrich-lookup-issue
               (smoke-make-page-lookup-issue "topics"
                                             "Synthetic missing topic via chunk repair")))
            (chunk (hyperdoc::issue-target-chunk issue))
            (factory-marker
              (string-upcase
               (format nil "(defun ~A"
                       (symbol-name symbol))))
            (before (uiop:read-file-string temp-topics))
            (original-before (uiop:read-file-string original-topics)))
       (assert-equal :needs-topic-creation
                     (hyperbook:lookup-issue-status-of issue)
                     "Disposable-source repair test must begin in Needs topic state")
       (assert-true (not (search "Synthetic missing topic via chunk repair"
                                 before
                                 :test #'char=))
                    "Disposable topics copy should start without the synthetic topic")
       (hyperdoc::repair-lookup-issue-via-chunks issue)
       (let ((after (uiop:read-file-string temp-topics)))
         (assert-true (search factory-marker
                              (string-upcase after)
                              :test #'char=)
                      "Repair should append a placeholder factory to the disposable topics copy")
         (assert-equal :fixed
                       (hyperdoc::topic-page-lookup-chunk-state chunk)
                       "Repair through the disposable copy should bring the topic-page chunk to fixed")
         (assert-string=
          original-before
          (uiop:read-file-string original-topics)
          "Repair through the disposable copy must not mutate the authoritative topics source")))))
  (call-with-disposable-topic-source-copy
   "Synthetic topic freshness"
   (lambda (symbol temp-topics original-topics)
     (declare (ignore symbol original-topics))
     (let* ((title "Synthetic topic freshness")
            (fresh-form (hyperdoc::page-lookup-placeholder-topic-form title))
            (updated-form
              (hyperdoc::page-lookup-placeholder-topic-form
               title
               :summary "Updated summary for freshness smoke.")))
       (append-placeholder-topic-factory-to-file title temp-topics)
       (hyperdoc::load-page-lookup-topic-source!)
       (hyperdoc::rebuild-topic-indexes)
       (let ((fresh-issue
               (hyperbook:enrich-lookup-issue
                (smoke-make-page-lookup-issue "topics" title))))
         (assert-true (hyperdoc::topic-page-resolves-p title)
                      "Freshness smoke should start from a resolving topics page")
         (assert-equal :fixed
                       (hyperbook:lookup-issue-status-of fresh-issue)
                       "Freshly rebuilt authored topics should classify as fixed")
         (assert-string=
          (hyperdoc::authored-topic-factory-source-signature title)
          (hyperdoc::topic-page-materialization-signature title)
          "Fresh materialization should capture the current per-topic authored signature")
         (append-placeholder-topic-factory-to-file
          "Unrelated topic freshness noise"
          temp-topics)
         (let* ((unchanged-issue
                  (hyperbook:enrich-lookup-issue
                   (smoke-make-page-lookup-issue "topics" title)))
                (unchanged-chunk (hyperdoc::issue-target-chunk unchanged-issue)))
           (assert-equal :fixed
                         (hyperbook:lookup-issue-status-of unchanged-issue)
                         "An unrelated authored change elsewhere in topics.lisp should not falsely stale an untouched topic")
           (assert-equal :fixed
                         (hyperdoc::topic-page-lookup-chunk-state unchanged-chunk)
                         "Chunk state should remain fixed when the topic-specific authored signature is unchanged"))
         (rewrite-file-substring! temp-topics fresh-form updated-form)
         (let* ((stale-issue
                  (hyperbook:enrich-lookup-issue
                   (smoke-make-page-lookup-issue "topics" title)))
                (stale-chunk (hyperdoc::issue-target-chunk stale-issue))
                (stale-views
                  (page-lookup-load-inspector-views-for-object stale-chunk))
                (stale-overview-html
                  (html-inspector-views:view-html
                   (page-lookup-smoke-find-view-by-title stale-views "Overview")))
                (stale-freshness-html
                  (html-inspector-views:view-html
                   (page-lookup-smoke-find-view-by-title stale-views "Freshness")))
                (stale-repair-html
                  (html-inspector-views:view-html
                   (page-lookup-smoke-find-view-by-title stale-views "Repair"))))
           (assert-true (hyperdoc::topic-page-resolves-p title)
                        "Freshness smoke should keep the topic page resolving while the authored signature changes")
           (assert-equal :needs-local-materialization
                         (hyperbook:lookup-issue-status-of stale-issue)
                         "Editing that topic's authored definition should classify as Needs materialization")
           (assert-true
            (search "materialized per-topic signature no longer matches the current authored topic factory"
                    stale-overview-html
                    :test #'char-equal)
            "Topic-page chunk overview should expose the stale-signature reason")
           (assert-true
            (search "Updated summary for freshness smoke."
                    stale-freshness-html
                    :test #'char=)
            "Topic-page chunk freshness view should show the updated authored signature content")
           (assert-true
            (search "materialized per-topic signature matches the current authored topic factory"
                    stale-repair-html
                    :test #'char-equal)
            "Topic-page chunk repair view should explain the stale-topic refresh action")
           (assert-true (not (string=
                              (hyperdoc::authored-topic-factory-source-signature title)
                              (hyperdoc::topic-page-materialization-signature title)))
                        "A stale topic should expose a per-topic signature mismatch before repair")
           (hyperdoc::repair-lookup-issue-via-chunks stale-issue)
           (assert-equal :fixed
                         (hyperdoc::topic-page-lookup-chunk-state stale-chunk)
                         "Repair should refresh a stale topic-page materialization back to fixed")
           (assert-string=
            (hyperdoc::authored-topic-factory-source-signature title)
            (hyperdoc::topic-page-materialization-signature title)
            "Repair should refresh the per-topic materialization signature to the updated authored definition"))))))
  (let ((generic-issue
          (hyperbook:enrich-lookup-issue
           (smoke-make-page-lookup-issue "lisp-functions"
                                         "hyperbook:make-page-lookup-issue"))))
    (assert-equal :hyperbook-page
                  (hyperbook:lookup-issue-target-kind-of generic-issue)
                  "Non-HyperDoc targets should remain generic HyperBook page issues")
    (assert-equal :missing-hyperbook-page
                  (hyperbook:lookup-issue-classification-of generic-issue)
                  "Non-HyperDoc targets should not be misclassified as missing HyperDoc pages")
    (assert-equal :inspect-target-hyperbook
                  (hyperbook:lookup-issue-suggested-repair-of generic-issue)
                  "Non-HyperDoc targets should suggest inspecting the target HyperBook")
    (assert-true (null (hyperbook::lookup-issue-repair-thunk-of generic-issue))
                 "Generic HyperBook lookup issues should not attach a HyperDoc scaffold thunk"))
  (format t "~&Page lookup issue smoke tests passed.~%")
  t)
