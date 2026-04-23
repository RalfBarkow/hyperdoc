;;;; Smoke tests for structured page-lookup issues
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-MISSING-LOCAL-FEDWIKI-TWIN-LOOKUP-ISSUE-SMOKE-TEST"
                        :hyperdoc/tests)
                (intern "RUN-PAGE-LOOKUP-ISSUES-SMOKE-TESTS"
                        :hyperdoc/tests))
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

(defun smoke-make-missing-local-fedwiki-twin-issue (slug pages-directory repo-root)
  (let* ((pages-directory (uiop:ensure-directory-pathname pages-directory))
         (repo-root (uiop:ensure-directory-pathname repo-root))
         (issue (smoke-make-page-lookup-issue "fedwiki:wiki.ralfbarkow.ch" slug)))
    (hyperbook::append-lookup-issue-details!
     issue
     (list :target-domain "wiki.ralfbarkow.ch"
           :local-domain-p t
           :local-path (merge-pathnames slug pages-directory)
           :local-page-exists-p nil
           :sitemap-has-slug-p nil
           :fetch-status :error
           :publication-classification :remote-page-missing
           :fedwiki-pages-directory pages-directory
           :fedwiki-repo-root repo-root))
    (hyperbook::configure-lookup-issue!
     issue
     :target-kind :local-fedwiki-twin
     :classification :missing-local-fedwiki-twin)
    issue))

(defun run-missing-local-fedwiki-twin-lookup-issue-smoke-test ()
  (let* ((root (page-lookup-smoke-tempdir))
         (pages-directory (merge-pathnames "pages/" root))
         (slug "civilian-casualty-mitigation"))
    (unwind-protect
         (let* ((issue
                  (smoke-make-missing-local-fedwiki-twin-issue
                   slug
                   pages-directory
                   root))
                (views (page-lookup-load-inspector-views-for-object issue))
                (overview-html
                  (html-inspector-views:view-html
                   (page-lookup-smoke-find-view-by-title views "Overview")))
                (repair-html
                  (html-inspector-views:view-html
                   (page-lookup-smoke-find-view-by-title views "Repair")))
                (repair-thunk
                  (hyperbook::lookup-issue-repair-thunk-of issue))
                (details (hyperbook:lookup-issue-details-of issue)))
           (assert-equal :local-fedwiki-twin
                         (hyperbook:lookup-issue-target-kind-of issue)
                         "The synthetic FedWiki issue must keep the local twin target kind")
           (assert-equal :missing-local-fedwiki-twin
                         (hyperbook:lookup-issue-classification-of issue)
                         "The synthetic FedWiki issue must keep the missing-local-twin classification")
           (assert-equal :open
                         (hyperbook:lookup-issue-status-of issue)
                         "Missing local FedWiki twins should preserve the visible open status until the twin exists")
           (assert-equal :materialize-local-fedwiki-twin
                         (hyperbook:lookup-issue-suggested-repair-of issue)
                         "Missing local FedWiki twins should derive their current repair action through bounded hooks")
           (assert-true repair-thunk
                        "Missing local FedWiki twins should expose a repair thunk while the local twin is absent")
           (assert-true
            (search "Materialize the missing FedWiki twin"
                    (hyperbook:lookup-issue-repair-description-of issue)
                    :test #'char=)
            "Missing local FedWiki twins should expose the materialization guidance from runtime state")
           (assert-equal nil
                         (getf details :current-local-page-exists-p)
                         "Runtime details should report that the local FedWiki twin is initially absent")
           (assert-equal :create
                         (getf details :current-materialization-action)
                         "Runtime details should expose the current materialization action")
           (assert-true
            (search "open" overview-html :test #'char-equal)
            "Generic issue overview should continue to render the current open status")
           (assert-true
            (search "Materialize the missing FedWiki twin" repair-html :test #'char=)
            "Generic repair view should render the current FedWiki twin guidance")
           (let* ((plan (funcall repair-thunk))
                  (entry (first (hyperdoc::fedwiki-materialization-entries-of plan)))
                  (target (merge-pathnames slug pages-directory)))
             (assert-true (typep plan 'hyperdoc::fedwiki-materialization-plan)
                          "FedWiki twin repair should yield a fresh FedWiki materialization plan")
             (assert-equal pages-directory
                           (hyperdoc::fedwiki-materialization-fedwiki-pages-directory-of
                            plan)
                           "FedWiki twin repair should honor the preserved disposable pages directory")
             (assert-equal root
                           (hyperdoc::fedwiki-materialization-fedwiki-repo-root-of
                            plan)
                           "FedWiki twin repair should honor the preserved disposable repo root")
             (assert-true
              (uiop:string-prefix-p
               (namestring pages-directory)
               (namestring (hyperdoc::fedwiki-materialization-entry-target-path-of entry)))
              "FedWiki twin repair should target only the disposable pages directory")
             (hyperdoc::materialize-fedwiki-materialization-plan plan)
             (assert-true (uiop:file-exists-p target)
                          "FedWiki twin repair should materialize the missing page into the disposable pages directory")
             (assert-string=
              "Civilian casualty mitigation in targeting operations"
              (getf (hyperdoc::article-allegation-read-json-file target) :title)
              "FedWiki twin repair should materialize the expected topic-derived page")
             (let* ((refreshed-views
                      (page-lookup-load-inspector-views-for-object issue))
                    (refreshed-overview-html
                      (html-inspector-views:view-html
                       (page-lookup-smoke-find-view-by-title refreshed-views
                                                             "Overview")))
                    (refreshed-repair-html
                      (html-inspector-views:view-html
                       (page-lookup-smoke-find-view-by-title refreshed-views
                                                             "Repair")))
                    (refreshed-details
                      (hyperbook:lookup-issue-details-of issue)))
               (assert-equal :fixed
                             (hyperbook:lookup-issue-status-of issue)
                             "The same FedWiki twin lookup issue should refresh to fixed once the local page exists")
               (assert-equal nil
                             (hyperbook:lookup-issue-suggested-repair-of issue)
                             "The same FedWiki twin lookup issue should clear its suggested repair after materialization")
               (assert-true
                (null (hyperbook::lookup-issue-repair-thunk-of issue))
                "The same FedWiki twin lookup issue should clear its repair thunk after materialization")
               (assert-true
                (search "No repair is needed."
                        (hyperbook:lookup-issue-repair-description-of issue)
                        :test #'char-equal)
                "The same FedWiki twin lookup issue should refresh its repair description after materialization")
               (assert-equal t
                             (getf refreshed-details :current-local-page-exists-p)
                             "Runtime details should refresh once the local FedWiki twin exists")
               (assert-true
                (search "fixed" refreshed-overview-html :test #'char-equal)
                "Generic issue overview should refresh to fixed once the local twin exists")
               (assert-true
                (search "No repair is needed."
                        refreshed-repair-html
                        :test #'char-equal)
                "Generic repair view should refresh once the local twin exists"))))
      (ignore-errors
        (uiop:delete-directory-tree root
                                    :validate t
                                    :if-does-not-exist :ignore)))))

(defun page-lookup-authored-artifact-state-ids (machine)
  (mapcar #'hyperdoc::id-of
          (hyperdoc::state-machine-definition-states-of machine)))

(defun page-lookup-authored-artifact-transition-triggers (machine)
  (mapcar #'hyperdoc::state-machine-transition-trigger-of
          (hyperdoc::state-machine-definition-transitions-of machine)))

(defun page-lookup-authored-artifact-layout-relation-p
    (layout-spec predicate subject object)
  (member (list predicate subject object)
          (getf layout-spec :relations)
          :test #'equal))

(defun page-lookup-authored-source-relation-definition-by-id
    (definitions relation-id)
  (find relation-id
        definitions
        :key (lambda (definition) (getf definition :id))
        :test #'equal))

(defun run-page-lookup-authored-artifact-smoke-test ()
  (let* ((source (hyperdoc::page-lookup-issue-authored-source-artifact))
         (authored (hyperdoc::page-lookup-issue-authored-artifact))
         (behavior (hyperdoc::page-lookup-issue-behavior-artifact))
         (layout (hyperdoc::page-lookup-issue-layout-artifact))
         (machine (hyperdoc::compiled-behavior-artifact-machine behavior))
         (layout-spec
           (hyperdoc::compiled-layout-artifact-layout-spec-of layout))
         (issue (smoke-make-page-lookup-issue "topics"
                                             "Synthetic artifact target"))
         (source-views (page-lookup-load-inspector-views-for-object source))
         (authored-views (page-lookup-load-inspector-views-for-object authored))
         (relation-graph-view
           (page-lookup-smoke-find-view-by-title
            authored-views
            "Relation graph"))
         (behavior-views
           (page-lookup-load-inspector-views-for-object behavior))
         (layout-views (page-lookup-load-inspector-views-for-object layout)))
    (assert-true
     (typep source 'hyperdoc::authored-relation-artifact-source)
     "Page lookup authored source must exist as a repo-native source artifact")
    (assert-true
     (typep authored 'hyperdoc::page-lookup-issue-authored-artifact)
     "Page lookup authored artifact must reconstruct from the authored source")
    (assert-true
     (typep behavior 'hyperdoc::page-lookup-issue-behavior-artifact)
     "Page lookup behavior artifact must compile from the authored artifact")
    (assert-true
     (typep layout 'hyperdoc::page-lookup-issue-layout-artifact)
     "Page lookup layout artifact must compile from the authored artifact")
    (assert-true
     (hyperdoc::compiled-artifact-derived-p behavior authored)
     "Page lookup behavior artifact must keep its authored-artifact derivation")
    (assert-true
     (hyperdoc::compiled-artifact-derived-p layout authored)
     "Page lookup layout artifact must keep its authored-artifact derivation")
    (assert-equal (list authored)
                  (hyperdoc::compiled-artifact-compiler-inputs-of behavior)
                  "Behavior compiler inputs must name the reconstructed authored artifact")
    (assert-equal (list authored)
                  (hyperdoc::compiled-artifact-compiler-inputs-of layout)
                  "Layout compiler inputs must name the reconstructed authored artifact")
    (assert-equal 4
                  (length
                   (hyperdoc::authored-relation-artifact-semantic-roles-of
                    authored))
                  "The page-lookup artifact should expose its compact semantic roles")
    (assert-equal '(:overview-pane :repair-pane)
                  (getf layout-spec :ordered-panes)
                  "Page lookup layout should keep Overview before Repair")
    (assert-true
     (page-lookup-authored-artifact-layout-relation-p
      layout-spec
      :contains
      :lookup-issue-pane
      :overview-pane)
     "Layout artifact must place the Overview pane in the lookup issue pane")
    (assert-true
     (page-lookup-authored-artifact-layout-relation-p
      layout-spec
      :contains
      :lookup-issue-pane
      :repair-pane)
     "Layout artifact must place the Repair pane in the lookup issue pane")
    (assert-true
     (page-lookup-authored-artifact-layout-relation-p
      layout-spec
      :after
      :repair-pane
      :overview-pane)
     "Layout artifact must preserve the Repair-after-Overview relation")
    (assert-equal '(:open :needs-target-chunk :fixed)
                  (page-lookup-authored-artifact-state-ids machine)
                  "Behavior artifact must include the expected lookup issue lifecycle states")
    (assert-equal '(:target-chunk-derived :target-resolved)
                  (page-lookup-authored-artifact-transition-triggers machine)
                  "Behavior artifact must include the expected lifecycle events")
    (assert-equal :open
                  (hyperdoc::state-machine-definition-initial-state-of machine)
                  "Page lookup lifecycle should start open")
    (assert-equal '(:fixed)
                  (hyperdoc::state-machine-definition-terminal-states-of
                   machine)
                  "Page lookup lifecycle should terminate at fixed")
    (assert-true
     (search "<scxml"
             (hyperdoc::compiled-behavior-artifact-machine-scxml behavior)
             :test #'char=)
     "Behavior artifact should expose SCXML for inspection")
    (assert-equal authored
                  (hyperdoc::page-lookup-issue-authored-artifact-for issue)
                  "A page-lookup-issue should expose the reconstructed authored artifact")
    (assert-equal behavior
                  (hyperdoc::page-lookup-issue-behavior-artifact-for issue)
                  "A page-lookup-issue should expose the compiled behavior artifact")
    (assert-equal layout
                  (hyperdoc::page-lookup-issue-layout-artifact-for issue)
                  "A page-lookup-issue should expose the compiled layout artifact")
    (assert-true
     (page-lookup-smoke-find-view-by-title source-views "Relation definitions")
     "Authored source artifact should expose relation definitions as an inspector view")
    (assert-true
     (page-lookup-smoke-find-view-by-title authored-views "Semantic roles")
     "Authored relation artifact should expose semantic roles as an inspector view")
    (assert-true
     (page-lookup-smoke-find-view-by-title authored-views "Behavior relations")
     "Authored relation artifact should expose behavior relations as an inspector view")
    (assert-true
     (page-lookup-smoke-find-view-by-title authored-views "Layout relations")
     "Authored relation artifact should expose layout relations as an inspector view")
    (assert-true
     relation-graph-view
     "Authored relation artifact should expose the relation graph view")
    (assert-true
     (search "data-hyperdoc-authored-relation-graph"
             (html-inspector-views:view-html relation-graph-view)
             :test #'char=)
     "Relation graph view should render with the graph marker")
    (assert-true
     (search "compiled-from"
             (html-inspector-views:view-html relation-graph-view)
             :test #'char=)
     "Relation graph view should render compiled-from derivation edges")
    (assert-true
     (page-lookup-smoke-find-view-by-title behavior-views "Behavior machine")
     "Compiled behavior artifact should expose its behavior machine view")
    (assert-true
     (page-lookup-smoke-find-view-by-title behavior-views "SCXML")
     "Compiled behavior artifact should expose its SCXML view")
    (assert-true
     (page-lookup-smoke-find-view-by-title layout-views "Layout")
     "Compiled layout artifact should expose its layout view")))

(defun run-page-lookup-authored-mutation-roundtrip-smoke-test ()
  (let* ((root (page-lookup-smoke-tempdir))
         (source-pathname
           (merge-pathnames "page-lookup-issue-authored-layout-relation.sexp"
                            root))
         (source-path (namestring source-pathname))
         (relation-id "layout/page-lookup/repair-after-overview"))
    (unwind-protect
         (let ((hyperdoc::*page-lookup-issue-authored-layout-source-path*
                 source-path))
           (hyperdoc::write-page-lookup-issue-authored-layout-override-payload
            (hyperdoc::page-lookup-issue-authored-layout-default-override-payload)
            :source-path source-path)
           (let* ((initial-reconstruction
                    (hyperdoc::reconstruct-page-lookup-issue-artifacts-from-source
                     :refresh-source t))
                  (initial-layout (getf initial-reconstruction :layout))
                  (initial-layout-spec
                    (hyperdoc::compiled-layout-artifact-layout-spec-of
                     initial-layout))
                  (mutation
                    (hyperdoc::make-page-lookup-issue-layout-order-toggle-mutation
                     :source-path source-path)))
             (assert-true
              (typep mutation
                     'hyperdoc::page-lookup-issue-authored-relation-mutation)
              "Page-lookup mutation path should expose an explicit authored-relation mutation object")
             (assert-equal source-path
                           (hyperdoc::authored-relation-mutation-source-path-of
                            mutation)
                           "Mutation object should retain the repo-native authored source write target")
             (assert-equal '(:overview-pane :repair-pane)
                           (getf initial-layout-spec :ordered-panes)
                           "Baseline reconstruction should keep Overview before Repair before mutation")
             (multiple-value-bind (applied reconstruction)
                 (hyperdoc::apply-authored-relation-mutation
                  mutation
                  :source-path source-path)
               (let* ((updated-source-payload
                        (hyperdoc::page-lookup-issue-authored-layout-override-payload
                         :source-path source-path))
                      (updated-relation-definition
                        (page-lookup-authored-source-relation-definition-by-id
                         (getf updated-source-payload :relation-overrides)
                         relation-id))
                      (updated-source (getf reconstruction :source))
                      (updated-authored (getf reconstruction :authored))
                      (updated-behavior (getf reconstruction :behavior))
                      (updated-layout (getf reconstruction :layout))
                      (updated-layout-spec
                        (hyperdoc::compiled-layout-artifact-layout-spec-of
                         updated-layout))
                      (issue (smoke-make-page-lookup-issue
                              "topics"
                              "Synthetic mutation target"))
                      (issue-layout
                        (hyperdoc::page-lookup-issue-layout-artifact-for issue)))
                 (assert-equal :applied
                               (hyperdoc::authored-relation-mutation-status-of
                                applied)
                               "Mutation apply should report applied status")
                 (assert-true
                  updated-relation-definition
                  "Mutation apply should persist the updated layout relation override in source payload")
                 (assert-equal :overview-pane
                               (getf updated-relation-definition :subject)
                               "Mutation apply should rewrite the relation subject in the authored source payload")
                 (assert-equal :repair-pane
                               (getf updated-relation-definition :object)
                               "Mutation apply should rewrite the relation object in the authored source payload")
                 (assert-true
                  (typep updated-source 'hyperdoc::authored-relation-artifact-source)
                  "Reconstruction after mutation should still yield a source artifact")
                 (assert-equal source-path
                               (hyperdoc::authored-relation-artifact-source-path-of
                                updated-source)
                               "Reconstruction should report the mutated repo-native source path")
                 (assert-true
                  (typep updated-authored
                         'hyperdoc::page-lookup-issue-authored-artifact)
                  "Reconstruction after mutation should still yield a page-lookup authored artifact")
                 (assert-true
                  (typep updated-behavior
                         'hyperdoc::page-lookup-issue-behavior-artifact)
                  "Behavior artifact should recompile from mutated authored source")
                 (assert-true
                  (typep updated-layout
                         'hyperdoc::page-lookup-issue-layout-artifact)
                  "Layout artifact should recompile from mutated authored source")
                 (assert-true
                  (hyperdoc::compiled-artifact-derived-p
                   updated-behavior
                   updated-authored)
                  "Recompiled behavior artifact must remain derived from reconstructed authored artifact")
                 (assert-true
                  (hyperdoc::compiled-artifact-derived-p
                   updated-layout
                   updated-authored)
                  "Recompiled layout artifact must remain derived from reconstructed authored artifact")
                 (assert-equal '(:repair-pane :overview-pane)
                               (getf updated-layout-spec :ordered-panes)
                               "Mutated layout relation should invert pane ordering in compiled layout artifact")
                 (assert-true
                  (page-lookup-authored-artifact-layout-relation-p
                   updated-layout-spec
                   :after
                   :overview-pane
                   :repair-pane)
                  "Compiled layout relations should reflect the mutated authored relation")
                 (assert-equal updated-layout
                               issue-layout
                               "Page-lookup issue consumer should expose the recompiled layout artifact after mutation")))))
      (let ((hyperdoc::*page-lookup-issue-authored-layout-source-path*
              "hyperdoc/page-lookup-issue-authored-layout-relation.sexp"))
        (hyperdoc::reconstruct-page-lookup-issue-artifacts-from-source
         :refresh-source t))
      (ignore-errors
        (uiop:delete-directory-tree root
                                    :validate t
                                    :if-does-not-exist :ignore)))))

(defun run-page-lookup-issues-smoke-tests ()
  (run-page-lookup-authored-artifact-smoke-test)
  (run-page-lookup-authored-mutation-roundtrip-smoke-test)
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
         (topic-issue-views
           (page-lookup-load-inspector-views-for-object topic-issue))
         (topic-issue-overview-html
           (html-inspector-views:view-html
            (page-lookup-smoke-find-view-by-title topic-issue-views "Overview")))
         (topic-issue-repair-html
           (html-inspector-views:view-html
            (page-lookup-smoke-find-view-by-title topic-issue-views "Repair")))
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
    (assert-string=
     "Ensure target chunk"
     (hyperbook::lookup-issue-repair-button-label-of topic-issue)
     "Topics targets should render a chunk-first repair action label")
    (assert-true (typep topic-repair 'hyperdoc::topic-page-availability-chunk)
                 "Topic repair thunk should now expose the target chunk itself")
    (assert-equal :needs-topic-creation
                  (hyperdoc::topic-page-lookup-chunk-state topic-repair)
                  "Chunk state should diagnose a missing authored topic as Needs topic")
    (assert-true (typep (hyperdoc::issue-target-chunk topic-issue)
                        'hyperdoc::topic-page-availability-chunk)
                 "Topics lookup issues should compute a target chunk directly")
    (assert-equal :needs-topic-creation
                  (getf (hyperbook:lookup-issue-details-of topic-issue)
                        :derived-status)
                  "Topics lookup issue details should expose the runtime-derived status")
    (assert-true (search "Current repair operation"
                         topic-issue-overview-html
                         :test #'char=)
                 "Lookup issue overview should expose the current repair operation label")
    (assert-true (search "Target chunk"
                         topic-issue-overview-html
                         :test #'char=)
                 "Lookup issue overview should expose the target chunk row")
    (assert-true (search "Repair path on click"
                         topic-issue-overview-html
                         :test #'char=)
                 "Lookup issue overview should expose the chunk-first repair path row")
    (assert-true (search "Ensure target chunk"
                         topic-issue-overview-html
                         :test #'char=)
                 "Lookup issue overview should point to ensure-target-chunk as the active repair path")
    (assert-true (search "chunk-first"
                         topic-issue-repair-html
                         :test #'char-equal)
                 "Lookup issue repair view should describe the chunk-first repair flow")
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
                       (hyperbook:lookup-issue-status-of issue)
                       "The same topic lookup issue should refresh to fixed once chunk repair materializes the topic")
         (assert-true
          (search "No repair is needed."
                  (hyperbook:lookup-issue-repair-description-of issue)
                  :test #'char-equal)
          "The same topic lookup issue should refresh its repair description after chunk repair succeeds")
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
                         (hyperbook:lookup-issue-status-of stale-issue)
                         "The same stale topic lookup issue should refresh to fixed after materialization repair")
           (assert-true
            (search "No repair is needed."
                    (hyperbook:lookup-issue-repair-description-of stale-issue)
                    :test #'char-equal)
            "The same stale topic lookup issue should refresh its repair description after repair")
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
  (run-missing-local-fedwiki-twin-lookup-issue-smoke-test)
  (format t "~&Page lookup issue smoke tests passed.~%")
  t)
