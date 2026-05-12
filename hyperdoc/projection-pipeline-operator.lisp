(defpackage :projection-pipeline-operator
  (:use :cl)
  (:nicknames :ppipe)
  (:export
   #:*topic-id*
   #:*workspace-id*
   #:*topicmap-id*
   #:*current-coordinate*
   #:operator-plan
   #:current-coordinate
   #:goto-coordinate
   #:operator-status
   #:shop3-plan-fixture
   #:scxml-dry-run-trace
   #:artifact-paths
   #:root-path
   #:write-text-file
   #:write-operator-scxml
   #:write-operator-page
   #:bootstrap-operator-page
   #:reload-operator-page
   #:find-operator-page
   #:resolve-artifact
   #:inspect-operator-page
   #:inspect-operator-plan
   #:inspect-operator-status
   #:inspect-current-artifact
   #:inspect-scxml-dry-run-trace
   #:inspect-shop3-plan-fixture))

(in-package :ppipe)

(defparameter *topic-id* 968855)
(defparameter *workspace-id* 919815)
(defparameter *topicmap-id* 919822)
(defparameter *current-coordinate* :p0)

(defparameter *operator-page-title*
  "Projection Pipeline Operator Plan")

(defparameter *operator-page-relative-path*
  "hyperdoc/Projection Pipeline Operator Plan.html")

(defparameter *operator-scxml-relative-path*
  "hyperdoc/projection-pipeline-operator-plan.scxml")

(defparameter *steps*
  '((:id :p0
     :title "Bootstrap operator page"
     :status :active
     :purpose "Create the shared HyperDoc control surface first."
     :artifact "hyperdoc/Projection Pipeline Operator Plan.html")
    (:id :p1
     :title "Add SCXML trace"
     :status :pending
     :purpose "Model the workflow states and dry-run path."
     :artifact "hyperdoc/projection-pipeline-operator-plan.scxml")
    (:id :p2
     :title "Add clickable examples"
     :status :pending
     :purpose "Expose demo annotation, dry-run plan, SCXML trace, and SHOP3 plan objects."
     :artifact "projection-pipeline-operator package")
    (:id :p3
     :title "Add SHOP3 plan"
     :status :pending
     :purpose "Use SHOP3 as plan-only organizer, not executor."
     :artifact "hyperdoc-shop3/projection-pipeline-dmx-annotation-plan.sexp")
    (:id :p4
     :title "Add focused smoke test"
     :status :pending
     :purpose "Verify page, SCXML, examples, and plan objects without live DMX mutation."
     :artifact "tests/projection-pipeline-dmx-annotation-smoke.lisp")
    (:id :p5
     :title "Add memory-client annotation write/readback"
     :status :pending
     :purpose "Demonstrate end-to-end annotation persistence without live HTTP."
     :artifact "tests/projection-pipeline-dmx-annotation-smoke.lisp")
    (:id :p6
     :title "Optional guarded live DMX write/readback"
     :status :blocked
     :purpose "Run only with explicit live-test environment and mutation guard."
     :artifact "manual SLY mREPL run")))

(defun root-path (relative)
  (asdf:system-relative-pathname :hyperdoc relative))

(defun write-text-file (relative text)
  (let ((path (root-path relative)))
    (ensure-directories-exist path)
    (with-open-file (stream path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
      (write-string text stream))
    (format t "~&Wrote ~A~%" path)
    path))

(defun current-coordinate ()
  (find *current-coordinate* *steps*
        :key (lambda (step) (getf step :id))))

(defun operator-plan ()
  (list :topic-id *topic-id*
        :workspace-id *workspace-id*
        :topicmap-id *topicmap-id*
        :current-coordinate *current-coordinate*
        :default-mode :dry-run
        :mutation-allowed nil
        :steps *steps*))

(defun goto-coordinate (coordinate)
  (unless (find coordinate *steps*
                :key (lambda (step) (getf step :id)))
    (error "Unknown projection pipeline coordinate: ~S" coordinate))
  (setf *current-coordinate* coordinate)
  (operator-status))

(defun artifact-paths ()
  (list :operator-page (root-path *operator-page-relative-path*)
        :operator-scxml (root-path *operator-scxml-relative-path*)
        :smoke-test (root-path "tests/projection-pipeline-dmx-annotation-smoke.lisp")
        :shop3-plan (root-path "hyperdoc-shop3/projection-pipeline-dmx-annotation-plan.sexp")))

(defun find-operator-page (&key (reload t) (signal-error? t))
  "Return the HyperDoc HTML page object for the operator plan page."
  (when reload
    (hyperdoc::reload-text-pages hyperdoc::*hyperdoc*))
  (hyperbook:find-page hyperdoc::*hyperdoc*
                       *operator-page-title*
                       :signal-error? signal-error?))

(defun resolve-artifact (artifact)
  "Resolve an operator artifact designator to an inspectable object.

For the operator HTML page, return the HyperDoc page object, not the
artifact path string. That gives the CLOG inspector the page Content/Source
views instead of a simple-character-string view."
  (cond
    ((null artifact)
     nil)

    ((and (stringp artifact)
          (string= artifact *operator-page-relative-path*))
     (find-operator-page :reload t :signal-error? t))

    ((and (stringp artifact)
          (string= artifact *operator-scxml-relative-path*))
     (root-path artifact))

    ((stringp artifact)
     (let ((path (root-path artifact)))
       (or (probe-file path)
           artifact)))

    (t artifact)))

(defun operator-status ()
  "Return current coordinate with :ARTIFACT as an inspectable object."
  (let* ((coordinate (current-coordinate))
         (artifact-label (getf coordinate :artifact))
         (artifact-object (resolve-artifact artifact-label)))
    (list :coordinate *current-coordinate*
          :title (getf coordinate :title)
          :purpose (getf coordinate :purpose)
          :artifact artifact-object
          :artifact-label artifact-label
          :topic-id *topic-id*
          :workspace-id *workspace-id*
          :topicmap-id *topicmap-id*
          :next-action
          (case *current-coordinate*
            (:p0 "Inspect :ARTIFACT; it should open the HyperDoc HTML page object.")
            (:p1 "Add or inspect the SCXML trace.")
            (:p2 "Add concrete clickable demo examples.")
            (:p3 "Replace the static SHOP3 fixture with a real plan object.")
            (:p4 "Write the focused smoke test.")
            (:p5 "Adapt the existing memory-client DMX annotation smoke path.")
            (:p6 "Run live write/readback only with explicit guards.")
            (otherwise "Inspect operator plan.")))))

(defun shop3-plan-fixture ()
  "Plan-only SHOP3-shaped fixture. This is intentionally not an executor."
  (list :kind :shop3-plan-fixture
        :execution-mode :plan-only
        :task '(:ensure-projection-pipeline-demonstration 968855)
        :ordered-steps
        '((!bootstrap-operator-page)
          (!write-scxml-trace)
          (!create-clickable-demo-examples)
          (!construct-dry-run-annotation-plan)
          (!validate-non-mutating-dry-run)
          (!write-focused-smoke-test)
          (!demonstrate-memory-client-readback)
          (!optionally-run-guarded-live-dmx-write)
          (!publish-verification-report))))

(defun scxml-dry-run-trace ()
  (list :kind :scxml-dry-run-trace
        :chart *operator-scxml-relative-path*
        :events
        '((:state "bootstrapOperatorPage" :event "PAGE.WRITTEN")
          (:state "operatorPageReady" :event "SCXML.REQUESTED")
          (:state "writeScxmlTrace" :event "SCXML.WRITTEN")
          (:state "scxmlTraceReady" :event "DRY_RUN")
          (:state "dryRunBlocked" :final t))
        :mutation-performed nil))

(defun ensure-clog-inspector-loaded ()
  (handler-case
      (progn
        (asdf:load-system :hyperdoc/inspector)
        t)
    (error (condition)
      (format t "~&Could not load :hyperdoc/inspector: ~A~%" condition)
      nil)))

(defun clog-inspect-object (object)
  "Open OBJECT in the CLOG moldable inspector."
  (ensure-clog-inspector-loaded)
  (clog-moldable-inspector:clog-inspect :object object))

(defun reload-operator-page ()
  "Reload HyperDoc text pages and return the operator page object."
  (find-operator-page :reload t :signal-error? t))

(defun inspect-current-artifact ()
  "Inspect the resolved artifact for the current coordinate."
  (let* ((coordinate (current-coordinate))
         (artifact (resolve-artifact (getf coordinate :artifact))))
    (clog-inspect-object artifact)
    artifact))

(defun inspect-operator-page ()
  "Open the operator HyperDoc page object in the CLOG inspector."
  (clog-inspect-object (find-operator-page :reload t :signal-error? t)))

(defun inspect-operator-plan ()
  "Open the current operator plan object in the CLOG inspector."
  (clog-inspect-object (operator-plan)))

(defun inspect-operator-status ()
  "Open the current coordinate/status object in the CLOG inspector."
  (clog-inspect-object (operator-status)))

(defun inspect-scxml-dry-run-trace ()
  "Open the dry-run trace object in the CLOG inspector."
  (clog-inspect-object (scxml-dry-run-trace)))

(defun inspect-shop3-plan-fixture ()
  "Open the current SHOP3-shaped plan fixture in the CLOG inspector."
  (clog-inspect-object (shop3-plan-fixture)))

(defun write-operator-scxml ()
  (write-text-file
   *operator-scxml-relative-path*
   "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<scxml
    xmlns=\"http://www.w3.org/2005/07/scxml\"
    version=\"1.0\"
    name=\"projection-pipeline-operator-plan\"
    initial=\"bootstrapOperatorPage\">

  <state id=\"bootstrapOperatorPage\">
    <onentry>
      <log label=\"P0 bootstrap the shared operator HyperDoc page\"/>
    </onentry>
    <transition event=\"PAGE.WRITTEN\" target=\"operatorPageReady\"/>
  </state>

  <state id=\"operatorPageReady\">
    <onentry>
      <log label=\"Operator page exists and can be inspected\"/>
    </onentry>
    <transition event=\"SCXML.REQUESTED\" target=\"writeScxmlTrace\"/>
    <transition event=\"SHOP3.REQUESTED\" target=\"writeShop3Plan\"/>
    <transition event=\"TEST.REQUESTED\" target=\"writeSmokeTest\"/>
  </state>

  <state id=\"writeScxmlTrace\">
    <onentry>
      <log label=\"P1 write trace chart for annotation projection pipeline\"/>
    </onentry>
    <transition event=\"SCXML.WRITTEN\" target=\"scxmlTraceReady\"/>
  </state>

  <state id=\"scxmlTraceReady\">
    <transition event=\"DRY_RUN\" target=\"dryRunBlocked\"/>
    <transition event=\"ALLOW_MUTATION\" target=\"mutationAllowed\"/>
  </state>

  <state id=\"writeShop3Plan\">
    <onentry>
      <log label=\"P3 write SHOP3 plan-only organizer\"/>
    </onentry>
    <transition event=\"SHOP3.PLAN_READY\" target=\"operatorPageReady\"/>
  </state>

  <state id=\"writeSmokeTest\">
    <onentry>
      <log label=\"P4 write focused non-mutating smoke test\"/>
    </onentry>
    <transition event=\"TEST.WRITTEN\" target=\"operatorPageReady\"/>
  </state>

  <state id=\"dryRunBlocked\" final=\"true\">
    <onentry>
      <log label=\"Dry run reached non-mutating terminal state\"/>
    </onentry>
  </state>

  <state id=\"mutationAllowed\">
    <onentry>
      <log label=\"Explicit live mutation guard accepted\"/>
    </onentry>
    <transition event=\"LIVE.WRITE.OK\" target=\"liveReadbackStarted\"/>
    <transition event=\"LIVE.WRITE.FAILED\" target=\"verificationFailed\"/>
  </state>

  <state id=\"liveReadbackStarted\">
    <transition event=\"READBACK.OK\" target=\"verified\"/>
    <transition event=\"READBACK.FAILED\" target=\"verificationFailed\"/>
  </state>

  <state id=\"verified\" final=\"true\">
    <onentry>
      <log label=\"Projection pipeline verified by readback\"/>
    </onentry>
  </state>

  <state id=\"verificationFailed\" final=\"true\">
    <onentry>
      <log label=\"Projection pipeline verification failed\"/>
    </onentry>
  </state>
</scxml>
"))

(defun write-operator-page ()
  (write-text-file
   *operator-page-relative-path*
   "<h1>Projection Pipeline Operator Plan</h1>

<in-package>projection-pipeline-operator</in-package>

<p>
  This page is the shared operator surface for topic <tt>968855</tt>. It is
  the place where we plan, trace, implement, and verify the DMX annotation
  projection pipeline step by step.
</p>

<h2>Current coordinate</h2>

<ul>
  <li><a expr=\"(operator-status)\"><tt>Current operator status</tt></a></li>
  <li><a expr=\"(operator-plan)\"><tt>Full operator plan</tt></a></li>
  <li><a expr=\"(artifact-paths)\"><tt>Artifact paths</tt></a></li>
</ul>

<h2>Coordinates</h2>

<table>
  <tr><th>Coordinate</th><th>Topic</th><th>Purpose</th><th>Expected artifact</th></tr>
  <tr><td><tt>P0</tt></td><td>Bootstrap operator page</td><td>Create this page first so all later work has a shared surface.</td><td><tt>hyperdoc/Projection Pipeline Operator Plan.html</tt></td></tr>
  <tr><td><tt>P1</tt></td><td>SCXML trace</td><td>Track the state-machine route for dry-run and live guarded paths.</td><td><tt>hyperdoc/projection-pipeline-operator-plan.scxml</tt></td></tr>
  <tr><td><tt>P2</tt></td><td>Clickable examples</td><td>Expose demo annotation, dry-run report, trace, and plan objects.</td><td><tt>projection-pipeline-operator</tt> functions</td></tr>
  <tr><td><tt>P3</tt></td><td>SHOP3 plan</td><td>Use SHOP3 as a plan-only organizer, not an executor.</td><td><tt>hyperdoc-shop3/projection-pipeline-dmx-annotation-plan.sexp</tt></td></tr>
  <tr><td><tt>P4</tt></td><td>Focused smoke test</td><td>Verify the page, SCXML trace, examples, and plan objects.</td><td><tt>tests/projection-pipeline-dmx-annotation-smoke.lisp</tt></td></tr>
  <tr><td><tt>P5</tt></td><td>Memory-client readback</td><td>Demonstrate annotation write/readback without live HTTP mutation.</td><td>Focused smoke-test extension</td></tr>
  <tr><td><tt>P6</tt></td><td>Guarded live DMX readback</td><td>Optional, explicit, authenticated, mutation-allowed live run.</td><td>Manual SLY run report</td></tr>
</table>

<h2>SCXML trace</h2>

<ul>
  <li><a expr=\"(scxml-dry-run-trace)\"><tt>Dry-run SCXML trace object</tt></a></li>
  <li><a expr=\"(root-path *operator-scxml-relative-path*)\"><tt>SCXML file pathname</tt></a></li>
</ul>

<h2>SHOP3 plan-only organizer</h2>

<ul>
  <li><a expr=\"(shop3-plan-fixture)\"><tt>SHOP3-shaped plan fixture</tt></a></li>
</ul>

<h2>DMX target coordinates</h2>

<table>
  <tr><th>Field</th><th>Value</th></tr>
  <tr><td>Topic</td><td><tt>968855</tt></td></tr>
  <tr><td>Workspace</td><td><tt>919815</tt></td></tr>
  <tr><td>Topicmap</td><td><tt>919822</tt></td></tr>
  <tr><td>Default mutation mode</td><td><tt>nil</tt></td></tr>
</table>

<h2>Readback discipline</h2>

<ul>
  <li><a page=\"DMX machine-readable read paths\">DMX machine-readable read paths</a></li>
  <li><a page=\"DMX note read-write boundary\">DMX note read-write boundary</a></li>
  <li><a page=\"DMX twins\">DMX twins</a></li>
  <li><a page=\"Workspace-native annotations in a DMX workspace\">Workspace-native annotations in a DMX workspace</a></li>
  <li><a page=\"SCXML Architect\">SCXML Architect</a></li>
  <li><a page=\"SHOP3 Planning Layer for HyperDoc\">SHOP3 Planning Layer for HyperDoc</a></li>
</ul>

<h2>Working rule</h2>

<ul>
  <li>No live DMX mutation by default.</li>
  <li>No generic raw DMX mutation tool.</li>
  <li>No refactor before the demonstration slice is inspectable.</li>
  <li>No test before the artifact it verifies exists.</li>
</ul>
"))

(defun bootstrap-operator-page ()
  "Create the operator artifacts, reload the page, and open it in CLOG inspector."
  (write-operator-scxml)
  (write-operator-page)
  (setf *current-coordinate* :p0)
  (let ((page (reload-operator-page)))
    (format t "~&Bootstrapped operator page: ~A~%" page)
    (clog-inspect-object page)
    page))
