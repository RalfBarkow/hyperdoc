;;;; Focused smoke tests for the Kioskberrli dashboard case study
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-KIOSKBERRLI-DASHBOARD-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun kioskberrli-dashboard-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun kioskberrli-dashboard-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun read-kioskberrli-dashboard-page (namestring)
  (uiop:read-file-string
   (kioskberrli-dashboard-relative-path namestring)))

(defun normalize-kioskberrli-dashboard-whitespace (string)
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

(defun kioskberrli-dashboard-page-contains-p (page-source needle)
  (search (normalize-kioskberrli-dashboard-whitespace needle)
          (normalize-kioskberrli-dashboard-whitespace page-source)
          :test #'char=))

(defun assert-kioskberrli-dashboard-page-contains (page-source page-label needle)
  (kioskberrli-dashboard-assert-true
   (kioskberrli-dashboard-page-contains-p page-source needle)
   (format nil "~A must contain ~S" page-label needle)))

(defun assert-kioskberrli-dashboard-page-contains-all
    (page-source page-label needles)
  (dolist (needle needles)
    (assert-kioskberrli-dashboard-page-contains page-source page-label needle)))

(defun kioskberrli-dashboard-count-substring (needle haystack)
  (loop with count = 0
        with start = 0
        for position = (search needle haystack :start2 start :test #'char=)
        while position
        do (incf count)
           (setf start (+ position (length needle)))
        finally (return count)))

(defun assert-kioskberrli-dashboard-before
    (page-source left right message)
  (let ((left-position (search left page-source :test #'char=))
        (right-position (search right page-source :test #'char=)))
    (kioskberrli-dashboard-assert-true
     left-position
     (format nil "~A -- missing left marker ~S" message left))
    (kioskberrli-dashboard-assert-true
     right-position
     (format nil "~A -- missing right marker ~S" message right))
    (kioskberrli-dashboard-assert-true
     (< left-position right-position)
     (format nil "~A -- expected ~S before ~S" message left right))))

(defun kioskberrli-dashboard-primary-topic-block (page-source)
  (let* ((start-marker "<ul id=\"primary-dashboard-topics\">")
         (start (search start-marker page-source :test #'char=)))
    (kioskberrli-dashboard-assert-true
     start
     "Dashboard must expose a primary-dashboard-topics block.")
    (let ((end (search "</ul>" page-source
                       :start2 start
                       :test #'char=)))
      (kioskberrli-dashboard-assert-true
       end
       "Dashboard primary topic block must close with </ul>.")
      (subseq page-source start (+ end (length "</ul>"))))))

(defun assert-kioskberrli-dashboard-primary-topics (page-source)
  (let ((block (kioskberrli-dashboard-primary-topic-block page-source)))
    (kioskberrli-dashboard-assert-true
     (= 5 (kioskberrli-dashboard-count-substring "<li><a href=" block))
     "Dashboard station-board summary must expose exactly five primary topic links.")
    (dolist (label '("Current status"
                     "Build evidence"
                     "Flash / boot evidence"
                     "Public-display layout state"
                     "Related topic board"))
      (kioskberrli-dashboard-assert-true
       (= 1 (kioskberrli-dashboard-count-substring label block))
       (format nil "Primary topic block must contain exactly one ~S label"
               label)))))

(defun assert-kioskberrli-hyperdoc-page-present (title)
  (asdf:load-system :hyperdoc/explorer)
  (kioskberrli-dashboard-assert-true
   (hyperbook:find-page hyperdoc::*hyperdoc* title :signal-error? t)
   (format nil "Missing HyperDoc page ~A" title)))

(defun assert-kioskberrli-topic-present (symbol title)
  (kioskberrli-dashboard-assert-true
   (fboundp symbol)
   (format nil "Missing topic function ~A" symbol))
  (kioskberrli-dashboard-assert-true
   (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
   (format nil "Missing Topics HyperBook page ~A" title)))

(defun run-kioskberrli-dashboard-topic-object-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (dolist (spec '((hyperdoc::kioskberrli-topic . "Kioskberrli")
                  (hyperdoc::kioskberrli-dashboard-topic . "Kioskberrli Dashboard")
                  (hyperdoc::kioskberrli-cross-host-build-failure-topic
                   . "Kioskberrli Cross-Host Build Failure")
                  (hyperdoc::salon-pi-4-kiosk-hardening-checklist-topic
                   . "Salon Pi 4 Kiosk Hardening Checklist")
                  (hyperdoc::runbook-build-and-flash-sd-image-topic
                   . "Runbook - Build and Flash NixOS SD Image for Kioskberrli")
                  (hyperdoc::invariant-boot-partition-must-be-big-enough-topic
                   . "Invariant: Boot Partition Must Be Big Enough")))
    (assert-kioskberrli-topic-present (car spec) (cdr spec)))
  (dolist (symbol '(hyperdoc::kioskberrli-dashboard
                    hyperdoc::kioskberrli-dashboard-status
                    hyperdoc::kioskberrli-dashboard-stations
                    hyperdoc::kioskberrli-current-blocker
                    hyperdoc::kioskberrli-build-evidence-status))
    (kioskberrli-dashboard-assert-true
     (fboundp symbol)
     (format nil "Missing dashboard helper ~A" symbol)))
  (let ((status (hyperdoc::kioskberrli-dashboard-status))
        (vocabulary (hyperdoc::kioskberrli-dashboard-status-vocabulary))
        (stations (hyperdoc::kioskberrli-dashboard-stations)))
    (kioskberrli-dashboard-assert-true
     (typep status 'hyperdoc::kioskberrli-dashboard-status)
     "Dashboard status helper must return an inspectable status object.")
    (dolist (status-word '("declared" "blocked" "corrected"
                           "missing evidence" "verified" "unknown"))
      (kioskberrli-dashboard-assert-true
       (member status-word vocabulary :test #'string=)
       (format nil "Dashboard status vocabulary must include ~S" status-word)))
    (dolist (station '("Kioskberrli"
                       "Kioskberrli Cross-Host Build Failure"
                       "Salon Pi 4 Kiosk Hardening Checklist"
                       "Runbook - Build and Flash NixOS SD Image for Kioskberrli"))
      (kioskberrli-dashboard-assert-true
       (member station stations :test #'string=)
       (format nil "Dashboard station list must include ~S" station)))))

(defun run-kioskberrli-dashboard-page-smoke-test ()
  (assert-kioskberrli-hyperdoc-page-present "Kioskberrli Dashboard")
  (dolist (title '("Kioskberrli"
                   "Kioskberrli sdImage imageSize Failure"
                   "Kioskberrli Cross-Host Build Failure"
                   "Salon Pi 4 Kiosk Hardening Checklist"
                   "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                   "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
                   "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                   "Two Installation Models: SD Image vs Classic Installer"
                   "Invariant: Boot Partition Must Be Big Enough"
                   "Prepare the AArch64 image"
                   "Hauptsache Entry Model"))
    (assert-kioskberrli-hyperdoc-page-present title))
  (let ((dashboard (read-kioskberrli-dashboard-page
                    "hyperdoc/Kioskberrli Dashboard.html"))
        (kioskberrli (read-kioskberrli-dashboard-page
                      "hyperdoc/Kioskberrli.html")))
    (kioskberrli-dashboard-assert-true
     (probe-file (kioskberrli-dashboard-relative-path
                  "hyperdoc/Kioskberrli Dashboard.html"))
     "Kioskberrli Dashboard page file must exist.")
    (assert-kioskberrli-dashboard-page-contains
     kioskberrli
     "Kioskberrli"
     "<a page=\"Kioskberrli Dashboard\">Kioskberrli Dashboard</a>")
    (assert-kioskberrli-dashboard-primary-topics dashboard)
    (assert-kioskberrli-dashboard-page-contains-all
     dashboard
     "Kioskberrli Dashboard"
     '("From: <a page=\"Kioskberrli\">Kioskberrli</a>"
       "To: <a page=\"Kioskberrli Cross-Host Build Failure\">Kioskberrli Cross-Host Build Failure</a>"
       "blocked</b> &middot; build blocked &middot; flash missing evidence &middot; boot missing evidence"
       "<h2 id=\"current-status\">Current status</h2>"
       "<h2 id=\"build-evidence\">Build evidence</h2>"
       "<h2 id=\"flash-boot-evidence\">Flash / boot evidence</h2>"
       "<h2 id=\"public-display-layout-state\">Public-display layout state</h2>"
       "<h2 id=\"related-topic-board\">Related topic board</h2>"
       "<h2>Topic identity</h2>"
       "<h2>Inspectable objects</h2>"
       "<h2>Inspect station list</h2>"
       "page=\"Kioskberrli Cross-Host Build Failure\""
       "page=\"Salon Pi 4 Kiosk Hardening Checklist\""
       "page=\"Runbook - Build and Flash NixOS SD Image for Kioskberrli\""
       "page=\"Kioskberrli sdImage imageSize Failure\""
       "expr=\"(hyperdoc::kioskberrli-dashboard-status)\""
       "expr=\"(hyperdoc::kioskberrli-dashboard-stations)\""
       "declared"
       "blocked"
       "corrected"
       "missing evidence"
       "verified"
       "unknown"))
    (assert-kioskberrli-dashboard-before
     dashboard
     "<ul id=\"primary-dashboard-topics\">"
     "<h2 id=\"current-status\">Current status</h2>"
     "Station-board topic tiles must appear before expanded sections.")
    (assert-kioskberrli-dashboard-before
     dashboard
     "<h2 id=\"related-topic-board\">Related topic board</h2>"
     "<h2>Topic identity</h2>"
     "Expanded five-topic sections must appear before topic identity details.")
    (assert-kioskberrli-dashboard-before
     dashboard
     "<h2>Topic identity</h2>"
     "<h2>Inspectable objects</h2>"
     "Inspectable objects must appear after topic identity details.")
    (assert-kioskberrli-dashboard-before
     dashboard
     "<ul id=\"primary-dashboard-topics\">"
     "<h2>Inspectable objects</h2>"
     "Inspectable objects must not appear before the five-topic station-board summary.")
    (assert-kioskberrli-dashboard-before
     dashboard
     "<h2>Inspectable objects</h2>"
     "<h2>Inspect station list</h2>"
     "Station-list inspection must appear below inspectable objects.")
    (assert-kioskberrli-dashboard-before
     dashboard
     "<ul id=\"primary-dashboard-topics\">"
     "kioskberrli-dashboard-stations"
     "kioskberrli-dashboard-stations must remain below the primary dashboard topics.")))

(defun run-kioskberrli-dashboard-smoke-tests ()
  (run-kioskberrli-dashboard-topic-object-smoke-test)
  (run-kioskberrli-dashboard-page-smoke-test)
  (format t "~&Kioskberrli dashboard smoke tests passed.~%")
  t)
