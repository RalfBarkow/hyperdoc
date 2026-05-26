;;;; Focused smoke tests for the Kioskbeerli dashboard case study
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-KIOSKBEERLI-DASHBOARD-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun kioskbeerli-dashboard-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun kioskbeerli-dashboard-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun read-kioskbeerli-dashboard-page (namestring)
  (uiop:read-file-string
   (kioskbeerli-dashboard-relative-path namestring)))

(defun normalize-kioskbeerli-dashboard-whitespace (string)
  (with-output-to-string (stream)
    (loop with pending-space = nil
          with wrote-char = nil
          for char across string
          do (if (find char '(#\Space #\Tab #\Newline #\Return))
                 (setf pending-space t)
                 (progn
                   (when pending-space
                     (when wrote-char
                       (write-char #\Space stream))
                     (setf pending-space nil))
                   (write-char char stream)
                   (setf wrote-char t))))))

(defun kioskbeerli-dashboard-page-contains-p (page-source needle)
  (search (normalize-kioskbeerli-dashboard-whitespace needle)
          (normalize-kioskbeerli-dashboard-whitespace page-source)
          :test #'char=))

(defun assert-kioskbeerli-dashboard-page-contains (page-source page-label needle)
  (kioskbeerli-dashboard-assert-true
   (kioskbeerli-dashboard-page-contains-p page-source needle)
   (format nil "~A must contain ~S" page-label needle)))

(defun assert-kioskbeerli-dashboard-page-contains-all
    (page-source page-label needles)
  (dolist (needle needles)
    (assert-kioskbeerli-dashboard-page-contains page-source page-label needle)))

(defun kioskbeerli-dashboard-count-substring (needle haystack)
  (loop with count = 0
        with start = 0
        for position = (search needle haystack :start2 start :test #'char=)
        while position
        do (incf count)
           (setf start (+ position (length needle)))
        finally (return count)))

(defun assert-kioskbeerli-dashboard-string-member (needle haystack message)
  (kioskbeerli-dashboard-assert-true
   (member needle haystack :test #'string=)
   message))

(defun run-kioskbeerli-dashboard-boundary-smoke-test ()
  (let ((core-concepts
          (uiop:read-file-string
           (kioskbeerli-dashboard-relative-path
            "hyperdoc/topics/core-concepts.lisp"))))
    (dolist (legacy-definition
              '("(defparameter *kioskbeerli-dashboard-status-vocabulary*"
                "(defclass kioskbeerli-dashboard-status"
                "(defclass kioskbeerli-topic-dashboard"
                "(defun kioskbeerli-dashboard"
                "(defun kioskbeerli-topic"
                "(defun kioskbeerli-dashboard-topic"
                "(defun kioskbeerli-sdimage-imagesize-failure-topic"
                "(defun kioskbeerli-cross-host-build-failure-topic"
                "(defun salon-pi-4-kiosk-hardening-checklist-topic"
                "(defun kioskbeerli-preconfigured-headless-image-topic"
                "(defun runbook-build-and-flash-sd-image-topic"
                "(defun preflight-rpi-sd-image-checklist-topic"
                "(defun official-rpi-sd-image-tutorial-topic"
                "(defun two-installation-models-topic"
                "(defun invariant-boot-partition-must-be-big-enough-topic"
                "(defun prepare-aarch64-image-topic"
                "(defun hauptsache-entry-model-topic"))
      (kioskbeerli-dashboard-assert-true
       (not (search legacy-definition core-concepts :test #'char=))
       (format nil
               "Kioskbeerli implementation boundary leaked into core concepts: ~A"
               legacy-definition)))))

(defun assert-kioskbeerli-dashboard-before
    (page-source left right message)
  (let ((left-position (search left page-source :test #'char=))
        (right-position (search right page-source :test #'char=)))
    (kioskbeerli-dashboard-assert-true
     left-position
     (format nil "~A -- missing left marker ~S" message left))
    (kioskbeerli-dashboard-assert-true
     right-position
     (format nil "~A -- missing right marker ~S" message right))
    (kioskbeerli-dashboard-assert-true
     (< left-position right-position)
     (format nil "~A -- expected ~S before ~S" message left right))))

(defun kioskbeerli-dashboard-primary-topic-block (page-source)
  (let* ((start-marker "<ul id=\"primary-dashboard-topics\">")
         (start (search start-marker page-source :test #'char=)))
    (kioskbeerli-dashboard-assert-true
     start
     "Dashboard must expose a primary-dashboard-topics block.")
    (let ((end (search "</ul>" page-source
                       :start2 start
                       :test #'char=)))
      (kioskbeerli-dashboard-assert-true
       end
       "Dashboard primary topic block must close with </ul>.")
      (subseq page-source start (+ end (length "</ul>"))))))

(defun assert-kioskbeerli-dashboard-primary-topics (page-source)
  (let ((block (kioskbeerli-dashboard-primary-topic-block page-source)))
    (kioskbeerli-dashboard-assert-true
     (= 5 (kioskbeerli-dashboard-count-substring "<li><a href=" block))
     "Dashboard station-board summary must expose exactly five primary topic links.")
    (dolist (label '("Current status"
                     "Build evidence"
                     "Flash / boot evidence"
                     "Public-display layout state"
                     "Related topic board"))
      (kioskbeerli-dashboard-assert-true
       (= 1 (kioskbeerli-dashboard-count-substring label block))
       (format nil "Primary topic block must contain exactly one ~S label"
               label)))))

(defun assert-kioskbeerli-hyperdoc-page-present (title)
  (kioskbeerli-dashboard-assert-true
   (hyperbook:find-page hyperdoc::*hyperdoc* title :signal-error? t)
   (format nil "Missing HyperDoc page ~A" title)))

(defun assert-kioskbeerli-topic-present (symbol title)
  (kioskbeerli-dashboard-assert-true
   (fboundp symbol)
   (format nil "Missing topic function ~A" symbol))
  (kioskbeerli-dashboard-assert-true
   (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
   (format nil "Missing Topics HyperBook page ~A" title)))

(defun run-kioskbeerli-dashboard-topic-object-smoke-test ()
  (dolist (spec '((hyperdoc::kioskbeerli-topic . "Kioskbeerli")
                  (hyperdoc::kioskbeerli-dashboard-topic . "Kioskbeerli Dashboard")
                  (hyperdoc::kioskbeerli-planner-and-trace-topic
                   . "Kioskbeerli Planner and Trace")
                  (hyperdoc::kioskbeerli-cross-host-build-failure-topic
                   . "Kioskbeerli Cross-Host Build Failure")
                  (hyperdoc::salon-pi-4-kiosk-hardening-checklist-topic
                   . "Salon Pi 4 Kiosk Hardening Checklist")
                  (hyperdoc::kioskbeerli-preconfigured-headless-image-topic
                   . "Kioskbeerli preconfigured headless image")
                  (hyperdoc::runbook-build-and-flash-sd-image-topic
                   . "Runbook - Build and Flash NixOS SD Image for Kioskbeerli")
                  (hyperdoc::invariant-boot-partition-must-be-big-enough-topic
                   . "Invariant: Boot Partition Must Be Big Enough")))
    (assert-kioskbeerli-topic-present (car spec) (cdr spec)))
  (dolist (symbol '(hyperdoc::kioskbeerli-dashboard
                    hyperdoc::kioskbeerli-dashboard-status
                    hyperdoc::kioskbeerli-dashboard-stations
                    hyperdoc::kioskbeerli-current-blocker
                    hyperdoc::kioskbeerli-build-evidence-status
                    hyperdoc::kioskbeerli-planner-run
                    hyperdoc::kioskbeerli-behavior-chart
                    hyperdoc::kioskbeerli-project-trace
                    hyperdoc::kioskbeerli-latest-progress
                    hyperdoc::record-kioskbeerli-progress
                    hyperdoc::kioskbeerli-planner-run
                    hyperdoc::kioskbeerli-behavior-chart
                    hyperdoc::kioskbeerli-project-trace
                    hyperdoc::kioskbeerli-latest-progress
                    hyperdoc::record-kioskbeerli-progress
                    hyperdoc::kioskbeerli-lookup-plan-task
                    hyperdoc::kioskbeerli-lookup-plan-task
                    hyperdoc::kioskbeerli-task-plan
                    hyperdoc::kioskbeerli-task-plan
                    hyperdoc::kioskbeerli-task-progress
                    hyperdoc::kioskbeerli-task-progress
                    hyperdoc::kioskbeerli-task-state-link
                    hyperdoc::kioskbeerli-task-state-link
                    hyperdoc::kioskbeerli-task-dependents
                    hyperdoc::kioskbeerli-task-dependents
                    hyperdoc::kioskbeerli-current-scxml-state
                    hyperdoc::kioskbeerli-current-scxml-state
                    hyperdoc::kioskbeerli-next-missing-evidence-tasks
                    hyperdoc::kioskbeerli-next-missing-evidence-tasks
                    hyperdoc::kioskbeerli-record-boot-observed
                    hyperdoc::kioskbeerli-record-boot-observed))
    (kioskbeerli-dashboard-assert-true
     (fboundp symbol)
     (format nil "Missing dashboard helper ~A" symbol)))
  (let ((dashboard (hyperdoc::kioskbeerli-dashboard))
        (status (hyperdoc::kioskbeerli-dashboard-status))
        (vocabulary (hyperdoc::kioskbeerli-dashboard-status-vocabulary))
        (stations (hyperdoc::kioskbeerli-dashboard-stations)))
    (kioskbeerli-dashboard-assert-true
     (typep dashboard 'dreyeck/kioskbeerli:kioskbeerli-topic-dashboard)
     "Dashboard helper must return the dreyeck/kioskbeerli dashboard object.")
    (kioskbeerli-dashboard-assert-true
     (typep status 'dreyeck/kioskbeerli:kioskbeerli-dashboard-status)
     "Dashboard status helper must return an inspectable status object.")
    (dolist (status-word '("declared" "blocked" "corrected"
                           "missing evidence" "verified" "unknown"))
      (kioskbeerli-dashboard-assert-true
       (member status-word vocabulary :test #'string=)
       (format nil "Dashboard status vocabulary must include ~S" status-word)))
    (dolist (station '("Kioskbeerli"
                       "Kioskbeerli Cross-Host Build Failure"
                       "Salon Pi 4 Kiosk Hardening Checklist"
                       "Runbook - Build and Flash NixOS SD Image for Kioskbeerli"))
      (kioskbeerli-dashboard-assert-true
       (member station stations :test #'string=)
       (format nil "Dashboard station list must include ~S" station)))))

(defun run-kioskbeerli-dashboard-planner-smoke-test ()
  (let* ((run (dreyeck/kioskbeerli:kioskbeerli-planner-run))
         (tasks (dreyeck/kioskbeerli:tasks-of run))
         (task-ids (mapcar #'dreyeck/kioskbeerli:id-of tasks)))
    (kioskbeerli-dashboard-assert-true
     (typep run 'dreyeck/kioskbeerli:kioskbeerli-plan-run)
     "Planner helper must return a Kioskbeerli plan-run object.")
    (kioskbeerli-dashboard-assert-true
     (eq :plan-only (dreyeck/kioskbeerli:execution-mode-of run))
     "Planner run must default to :PLAN-ONLY.")
    (kioskbeerli-dashboard-assert-true
     (dreyeck/kioskbeerli:dry-run-p run)
     "Planner run must be dry-run/plan-only.")
    (dolist (task-id (dreyeck/kioskbeerli:kioskbeerli-plan-task-ids))
      (assert-kioskbeerli-dashboard-string-member
       task-id
       task-ids
       (format nil "Planner run must include task ~S" task-id)))
    (let ((build-task (find "build-aarch64-image"
                            tasks
                            :key #'dreyeck/kioskbeerli:id-of
                            :test #'string=))
          (flash-task (find "flash-sd-card"
                            tasks
                            :key #'dreyeck/kioskbeerli:id-of
                            :test #'string=)))
      (assert-kioskbeerli-dashboard-string-member
       "provision-linux-builder"
       (dreyeck/kioskbeerli:dependencies-of build-task)
       "build-aarch64-image must depend on provision-linux-builder.")
      (assert-kioskbeerli-dashboard-string-member
       "build-aarch64-image"
       (dreyeck/kioskbeerli:dependencies-of flash-task)
       "flash-sd-card must depend on build-aarch64-image."))))

(defun run-kioskbeerli-dashboard-task-lookup-smoke-test ()
  (let* ((task (dreyeck/kioskbeerli:kioskbeerli-lookup-plan-task :boot-pi))
         (run (dreyeck/kioskbeerli:kioskbeerli-task-plan task))
         (state-link (dreyeck/kioskbeerli:kioskbeerli-task-state-link task))
         (progress-before
           (dreyeck/kioskbeerli:kioskbeerli-task-progress task)))
    (kioskbeerli-dashboard-assert-true
     (typep task 'dreyeck/kioskbeerli:kioskbeerli-plan-task)
     "lookup-plan-task must return the boot-pi task.")
    (kioskbeerli-dashboard-assert-true
     (string= "boot-pi" (dreyeck/kioskbeerli:id-of task))
     "lookup-plan-task must normalize :boot-pi to boot-pi.")
    (kioskbeerli-dashboard-assert-true
     (typep run 'dreyeck/kioskbeerli:kioskbeerli-plan-run)
     "boot-pi task must link to the planner run.")
    (kioskbeerli-dashboard-assert-true
     (member task (dreyeck/kioskbeerli:tasks-of run))
     "boot-pi task must be a member of its parent plan.")
    (kioskbeerli-dashboard-assert-true
     (string= "PI_BOOTED"
              (dreyeck/kioskbeerli:scxml-event-of state-link))
     "boot-pi task must link to SCXML event PI_BOOTED.")
    (kioskbeerli-dashboard-assert-true
     (string= "first-boot-observed"
              (dreyeck/kioskbeerli:scxml-state-of state-link))
     "boot-pi task must link to state first-boot-observed.")
    (kioskbeerli-dashboard-assert-true
     (typep (dreyeck/kioskbeerli:kioskbeerli-lookup-plan-task :boot-pi)
            'dreyeck/kioskbeerli:kioskbeerli-plan-task)
     "kioskbeerli lookup compatibility alias must resolve boot-pi.")
    (dreyeck/kioskbeerli:kioskbeerli-record-boot-observed
     :actor "operator"
     :evidence "logged in as nixos on the booted Raspberry Pi")
    (let* ((progress-after
             (dreyeck/kioskbeerli:kioskbeerli-task-progress :boot-pi))
           (updated-task
             (dreyeck/kioskbeerli:kioskbeerli-lookup-plan-task :boot-pi))
           (next-task-ids
             (mapcar #'dreyeck/kioskbeerli:id-of
                     (dreyeck/kioskbeerli:kioskbeerli-next-missing-evidence-tasks))))
      (kioskbeerli-dashboard-assert-true
       (> (length progress-after) (length progress-before))
       "Recording boot observed must create a progress entry.")
      (kioskbeerli-dashboard-assert-true
       (not (string= "missing-evidence"
                     (dreyeck/kioskbeerli:status-of updated-task)))
       "After recording boot observed, boot-pi must no longer be missing-evidence.")
      (kioskbeerli-dashboard-assert-true
       (string= "verified" (dreyeck/kioskbeerli:status-of updated-task))
       "After recording boot observed, boot-pi must be verified.")
      (kioskbeerli-dashboard-assert-true
       (member "logged in as nixos on the booted Raspberry Pi"
               (dreyeck/kioskbeerli:evidence-paths-of updated-task)
               :test #'string=)
       "boot-pi must carry the operator evidence text.")
      (kioskbeerli-dashboard-assert-true
       (string= "first-boot-observed"
                (dreyeck/kioskbeerli:kioskbeerli-current-scxml-state))
       "Current SCXML state must be first-boot-observed after boot evidence.")
      (dolist (later-task-id '("verify-network"
                               "verify-kiosk-session"
                               "verify-landing-page"
                               "record-evidence"))
        (kioskbeerli-dashboard-assert-true
         (string= "missing-evidence"
                  (dreyeck/kioskbeerli:status-of
                   (dreyeck/kioskbeerli:kioskbeerli-lookup-plan-task
                    later-task-id)))
         (format nil "~A must remain missing-evidence." later-task-id))
        (assert-kioskbeerli-dashboard-string-member
         later-task-id
         next-task-ids
         (format nil "~A must remain a next missing-evidence task."
                 later-task-id)))
      (kioskbeerli-dashboard-assert-true
       (string= "blocked"
                (dreyeck/kioskbeerli:status-of
                 (dreyeck/kioskbeerli:kioskbeerli-lookup-plan-task
                  :mark-dashboard-status)))
       "mark-dashboard-status must remain blocked until separately evidenced.")
      (assert-kioskbeerli-dashboard-string-member
       "mark-dashboard-status"
       next-task-ids
       "mark-dashboard-status must remain a next blocked task."))))

(defun run-kioskbeerli-dashboard-scxml-smoke-test ()
  (let* ((chart (dreyeck/kioskbeerli:kioskbeerli-behavior-chart))
         (states (dreyeck/kioskbeerli:kioskbeerli-behavior-state-ids chart))
         (events (dreyeck/kioskbeerli:kioskbeerli-behavior-events chart)))
    (kioskbeerli-dashboard-assert-true
     (typep chart 'hyperdoc/scxml:scxml-chart)
     "Behavior helper must return a parsed SCXML chart.")
    (kioskbeerli-dashboard-assert-true
     (string= "declared" (hyperdoc/scxml:scxml-chart-initial-state-of chart))
     "Kioskbeerli SCXML initial state must be declared.")
    (dolist (state '("declared"
                     "source-inspected"
                     "obsolete-option-corrected"
                     "cross-host-build-blocked"
                     "linux-builder-required"
                     "image-built"
                     "sd-flashed"
                     "first-boot-observed"
                     "network-verified"
                     "kiosk-session-running"
                     "landing-page-visible"
                     "maintenance-ready"
                     "failed-with-evidence"
                     "unknown"))
      (assert-kioskbeerli-dashboard-string-member
       state
       states
       (format nil "Kioskbeerli SCXML must include state ~S" state)))
    (dolist (event '("SOURCE_REVIEWED"
                     "OBSOLETE_OPTION_REMOVED"
                     "BUILD_ATTEMPTED"
                     "BUILD_HOST_REJECTED"
                     "LINUX_BUILDER_AVAILABLE"
                     "IMAGE_BUILD_SUCCEEDED"
                     "FLASH_COMPLETED"
                     "PI_BOOTED"
                     "NETWORK_OK"
                     "KIOSK_SESSION_OK"
                     "LANDING_PAGE_OK"
                     "EVIDENCE_MISSING"
                     "FAILURE_RECORDED"))
      (assert-kioskbeerli-dashboard-string-member
       event
       events
       (format nil "Kioskbeerli SCXML must include event ~S" event)))))

(defun run-kioskbeerli-dashboard-trace-smoke-test ()
  (let* ((trace (dreyeck/kioskbeerli:kioskbeerli-project-trace))
         (updated
          (dreyeck/kioskbeerli:record-kioskbeerli-progress
           :trace trace
           :task-id "build-aarch64-image"
           :from-state "linux-builder-required"
           :to-state "linux-builder-required"
           :status "missing-evidence"
           :evidence-paths '("missing: successful aarch64 SD-image artifact")
           :note "Smoke test records missing evidence explicitly."))
         (latest (dreyeck/kioskbeerli:kioskbeerli-latest-progress updated)))
    (kioskbeerli-dashboard-assert-true
     (typep updated 'dreyeck/kioskbeerli:kioskbeerli-project-trace)
     "Trace helper must return a project trace object.")
    (assert-kioskbeerli-dashboard-string-member
     "missing-evidence"
     (dreyeck/kioskbeerli:kioskbeerli-trace-status-vocabulary)
     "Trace status vocabulary must include missing-evidence.")
    (kioskbeerli-dashboard-assert-true
     (string= "missing-evidence" (dreyeck/kioskbeerli:status-of latest))
     "Latest progress must preserve missing-evidence status.")))

(defun run-kioskbeerli-dashboard-dita-view-contract-smoke-test ()
  (let* ((topic
           (dreyeck/kioskbeerli:kioskbeerli-semi-headless-set-password-task))
         (view
           (dreyeck/kioskbeerli:kioskbeerli-dita-task-view topic))
         (contract
           (html-inspector-views:view-specification view topic))
         (box-contract
           (html-inspector-views:box-contract-of contract))
         (box-names
           (mapcar #'first box-contract))
         (box-text
           (prin1-to-string box-contract))
         (contract-view-titles
           (mapcar #'html-inspector-views:view-title
                   (html-inspector-views:all-views contract))))
    (kioskbeerli-dashboard-assert-true
     (typep view 'dreyeck/kioskbeerli:kioskbeerli-dita-task-view)
     "DITA task view must be a typed view object.")
    (kioskbeerli-dashboard-assert-true
     (typep contract 'html-inspector-views:inspector-view-specification)
     "DITA task view must produce an inspector-view-specification.")
    (kioskbeerli-dashboard-assert-true
     (string= "What should the operator do next, and what evidence proves completion?"
              (html-inspector-views:reader-question-of contract))
     "DITA task contract must preserve the required reader question.")
    (kioskbeerli-dashboard-assert-true
     (equal '(:title :shortdesc :context :prerequisites :steps
              :expected-result :postrequisites :evidence)
            (html-inspector-views:content-model-of contract))
     "DITA task contract must expose the required content model.")
    (dolist (box-name '(:root-box :prose-boxes :steps-list-boxes :code-boxes))
      (kioskbeerli-dashboard-assert-true
       (member box-name box-names)
       (format nil "DITA task box contract must include ~S" box-name)))
    (dolist (term '("INLINE-SIZE" "BLOCK-SIZE" "MAX-INLINE-SIZE"
                    "OVERFLOW" "PADDING-INLINE"))
      (kioskbeerli-dashboard-assert-true
       (search term box-text :test #'char=)
       (format nil "DITA task box contract must use logical layout term ~A"
               term)))
    (kioskbeerli-dashboard-assert-true
     (member '(:layout-snapshot :missing-evidence)
             (html-inspector-views:evidence-of contract)
             :test #'equal)
     "DITA task contract must report missing layout snapshot evidence.")
    (kioskbeerli-dashboard-assert-true
     (search "EXTERNAL-MUTATION-NOT-PERFORMED"
             (prin1-to-string (html-inspector-views:actions-of contract))
             :test #'char=)
     "DITA task contract actions must remain descriptive-only.")
    (dolist (title '("Summary"
                     "Content model"
                     "Box contract"
                     "Priority policy"
                     "Actions"
                     "Evidence"
                     "Failure modes"))
      (assert-kioskbeerli-dashboard-string-member
       title
       contract-view-titles
       (format nil "DITA task contract must expose view ~S" title)))))

(defun run-kioskbeerli-dashboard-page-smoke-test ()
  (assert-kioskbeerli-hyperdoc-page-present "Kioskbeerli Dashboard")
  (dolist (title '("Kioskbeerli"
                   "Kioskbeerli Planner and Trace"
                   "Kioskbeerli sdImage imageSize Failure"
                   "Kioskbeerli Cross-Host Build Failure"
                   "Salon Pi 4 Kiosk Hardening Checklist"
                   "Runbook - Build and Flash NixOS SD Image for Kioskbeerli"
                   "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
                   "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                   "Two Installation Models: SD Image vs Classic Installer"
                   "Invariant: Boot Partition Must Be Big Enough"
                   "Prepare the AArch64 image"
                   "Hauptsache Entry Model"))
    (assert-kioskbeerli-hyperdoc-page-present title))
  (let ((dashboard (read-kioskbeerli-dashboard-page
                    "hyperdoc/Kioskbeerli Dashboard.html"))
        (kioskbeerli (read-kioskbeerli-dashboard-page
                      "hyperdoc/Kioskbeerli.html")))
    (kioskbeerli-dashboard-assert-true
     (probe-file (kioskbeerli-dashboard-relative-path
                  "hyperdoc/Kioskbeerli Dashboard.html"))
     "Kioskbeerli Dashboard page file must exist.")
    (assert-kioskbeerli-dashboard-page-contains
     kioskbeerli
     "Kioskbeerli"
     "<a page=\"Kioskbeerli Dashboard\">Kioskbeerli Dashboard</a>")
    (assert-kioskbeerli-dashboard-primary-topics dashboard)
    (assert-kioskbeerli-dashboard-page-contains-all
     dashboard
     "Kioskbeerli Dashboard"
     '("From: <a page=\"Kioskbeerli\">Kioskbeerli</a>"
       "To: <a page=\"Kioskbeerli Cross-Host Build Failure\">Kioskbeerli Cross-Host Build Failure</a>"
       "blocked</b> &middot; build blocked &middot; flash missing evidence &middot; boot observed"
       "<h2 id=\"current-status\">Current status</h2>"
       "<h2 id=\"build-evidence\">Build evidence</h2>"
       "<h2 id=\"flash-boot-evidence\">Flash / boot evidence</h2>"
       "<h2 id=\"public-display-layout-state\">Public-display layout state</h2>"
       "<h2 id=\"related-topic-board\">Related topic board</h2>"
       "<h2>Topic identity</h2>"
       "<h2>Inspectable objects</h2>"
       "<h2>Inspect station list</h2>"
       "<h2>Planner run</h2>"
       "<h2>Behavioral state machine</h2>"
       "<h2>Project trace / record progress</h2>"
       "page=\"Kioskbeerli Cross-Host Build Failure\""
       "page=\"Salon Pi 4 Kiosk Hardening Checklist\""
       "page=\"Runbook - Build and Flash NixOS SD Image for Kioskbeerli\""
       "page=\"Kioskbeerli sdImage imageSize Failure\""
       "expr=\"(hyperdoc::kioskbeerli-dashboard-status)\""
       "expr=\"(hyperdoc::kioskbeerli-dashboard-stations)\""
       "expr=\"(hyperdoc::kioskbeerli-planner-run)\""
       "expr=\"(hyperdoc::kioskbeerli-lookup-plan-task :boot-pi)\""
       "expr=\"(hyperdoc::kioskbeerli-task-state-link :boot-pi)\""
       "expr=\"(hyperdoc::kioskbeerli-behavior-chart)\""
       "expr=\"(hyperdoc::kioskbeerli-project-trace)\""
       "expr=\"(hyperdoc::kioskbeerli-record-boot-observed"
       "expr=\"(hyperdoc::record-kioskbeerli-progress"
       "declared"
       "blocked"
       "corrected"
       "missing evidence"
       "verified"
       "unknown"))
    (assert-kioskbeerli-dashboard-before
     dashboard
     "<ul id=\"primary-dashboard-topics\">"
     "<h2 id=\"current-status\">Current status</h2>"
     "Station-board topic tiles must appear before expanded sections.")
    (assert-kioskbeerli-dashboard-before
     dashboard
     "<h2 id=\"related-topic-board\">Related topic board</h2>"
     "<h2>Topic identity</h2>"
     "Expanded five-topic sections must appear before topic identity details.")
    (assert-kioskbeerli-dashboard-before
     dashboard
     "<h2>Topic identity</h2>"
     "<h2>Inspectable objects</h2>"
     "Inspectable objects must appear after topic identity details.")
    (assert-kioskbeerli-dashboard-before
     dashboard
     "<ul id=\"primary-dashboard-topics\">"
     "<h2>Inspectable objects</h2>"
     "Inspectable objects must not appear before the five-topic station-board summary.")
    (assert-kioskbeerli-dashboard-before
     dashboard
     "<h2>Inspectable objects</h2>"
     "<h2>Inspect station list</h2>"
     "Station-list inspection must appear below inspectable objects.")
    (assert-kioskbeerli-dashboard-before
     dashboard
     "<ul id=\"primary-dashboard-topics\">"
     "kioskbeerli-dashboard-stations"
     "kioskbeerli-dashboard-stations must remain below the primary dashboard topics.")))

(defun run-kioskbeerli-dashboard-smoke-tests ()
  (run-kioskbeerli-dashboard-boundary-smoke-test)
  (run-kioskbeerli-dashboard-topic-object-smoke-test)
  (run-kioskbeerli-dashboard-planner-smoke-test)
  (run-kioskbeerli-dashboard-task-lookup-smoke-test)
  (run-kioskbeerli-dashboard-scxml-smoke-test)
  (run-kioskbeerli-dashboard-trace-smoke-test)
  (run-kioskbeerli-dashboard-dita-view-contract-smoke-test)
  (run-kioskbeerli-dashboard-page-smoke-test)
  (format t "~&Kioskbeerli dashboard smoke tests passed.~%")
  t)
