;;;; Records, the Pins, Views and the Entry of the Re-pin Reading
(in-package #:topic-maps-task-1e-review)

(hyperdoc:see (hyperdoc:page "Re-pinning Topic Maps to 88994c1b" :hyperbook "topic-maps-task-1e-review"))
(hyperdoc:see #'topic-maps.tmdm::next-association-merge)
(hyperdoc:see #'topic-maps.tmdm::scan-next-association-merge)
(hyperdoc:see #'topic-maps.tmdm::normalize-associations)
(hyperdoc:see #'p::topic-maps-source-identity)
(hyperdoc:see #'p::pinned-state-p)

(defparameter +book-id+ "topic-maps-task-1e-review")
(defparameter +commit+ "88994c1b9e1edbf13e665e984a5c9c3b2cdf7575"
  "Task 1E: 6162ed68 plus the indexed search for the next Association merge, independently reviewed (GO) and integrated locally on 2026-10-28.")
(defparameter +parent-commit+ "6162ed68c94ea4796b8cf2282edd347d9607b08c" "Task 1C, the previous pin.")

(defun review-page (title) (hyperbook:find-page +book-id+ title :signal-error? t))
(defun evidence-pathname (file)
  (merge-pathnames (concatenate 'string "evidence/" file) (asdf:system-source-directory "topic-maps-task-1e-review")))

;;; A record is one file of evidence/: showing it reads the file and checks it against evidence/SHA256SUMS; it runs nothing.
(defclass record () ((file :initarg :file :reader record-file) (title :initarg :title :reader record-title)
                     (kind :initarg :kind :reader record-kind) (what :initarg :what :reader record-what)))
(defmethod v:text-representation ((r record)) (record-title r))
(defun record-text (record) (uiop:read-file-string (evidence-pathname (record-file record)) :external-format :utf-8))
(defun record-sha256 (record) (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 (evidence-pathname (record-file record)))))
(defun recorded-sha256 (file)
  (with-open-file (in (evidence-pathname "SHA256SUMS") :external-format :utf-8)
    (loop for line = (read-line in nil) while line
          when (and (> (length line) 66) (string= file (string-left-trim "* " (subseq line 64)))) return (subseq line 0 64))))
(defun record-intact-p (record) (equal (record-sha256 record) (recorded-sha256 (record-file record))))

(defvar *records* nil)
(defun records ()
  (or *records*
      (setf *records*
            (flet ((rec (file title kind what) (make-instance 'record :file file :title title :kind kind :what what)))
              (list
               (rec "task1e-independent-review.md" "Task 1E independent review (GO FOR LOCAL COMMIT)" :independent "The reviewer's own reconstruction, checkers and mutants; states its limits.")
               (rec "task1e-commit-record.md" "Task 1E commit record" :integration "Commit, tree, parent, author, message, file count and the primary checkout's state.")
               (rec "snapshot-archive-verification.json" "Snapshot verified against the commit with Git and Nix" :integration "scripts/topic-maps-snapshot.py verify: 19 checks, no failure.")
               (rec "snapshot-archive-and-manifest.sha256" "Archive and manifest digests" :integration "Two create runs were byte-identical; these are the digests.")
               (rec "snapshot-suites.log" "Verifier, 22U reading and CTM review on the Git-free snapshot" :integration "34, 41 and 58 assertions.")
               (rec "workspace-original-ctm-git-checkout.log" "Project Workspace, original CTM, Git checkout" :integration "Fresh process; 55/57/4/40 model; read-and-model time.")
               (rec "workspace-original-ctm-verified-snapshot.log" "Project Workspace, original CTM, verified snapshot" :integration "Fresh process.")
               (rec "workspace-stage1-ctm-git-checkout-run1.log" "Project Workspace, Stage 1 CTM, Git checkout, run 1" :integration "Disposable copy of the Stage 1 tree; CTM digest fe2955e9.")
               (rec "workspace-stage1-ctm-git-checkout-run2.log" "Project Workspace, Stage 1 CTM, Git checkout, run 2" :integration "Second sequential run.")
               (rec "workspace-stage1-ctm-verified-snapshot.log" "Project Workspace, Stage 1 CTM, verified snapshot" :integration "The Git-free root.")
               (rec "negative-6162ed68-checkout-not-pinned.log" "Negative: a clean 6162ed68 checkout is not the pin" :integration "Identity only; PIN-NOT-OK.")
               (rec "stage1-ctm-timings-at-6162ed68.txt" "Stage 1 CTM timings under the previous pin" :zettel "The 107.7-113.3 s readings that blocked the Scope Declaration Review (an earlier state of the CTM: see the page).")
               (rec "control-stage1-ctm-at-6162ed68.log" "Control: the final Stage 1 CTM under the previous pin" :integration "Same bytes, same script and copy; PIN-NOT-OK is expected: the control changes only Topic Maps.")
               (rec "control-stage1-ctm-at-88994c1b.log" "The final Stage 1 CTM under the new pin, straight after the control" :integration "Same bytes, same script and copy.")
               (rec "suites-and-controls.txt" "Test suites of the re-pin and the same-bytes control" :integration "Catalog, Project, Stage 1 copy; control of fe2955e9 under 6162ed68."))))))
(defun record (file) (or (find file (records) :key #'record-file :test #'string=) (error "No record ~S" file)))

(v:defview record-view (record record)
  (v:html-view :title "Record" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (record-title record)))
       (:p (v:esc (format nil "~(~A~) evidence. File evidence/~A; its SHA-256 ~:[does NOT match~;matches~] evidence/SHA256SUMS. ~A"
                          (record-kind record) (record-file record) (record-intact-p record) (record-what record))))
       (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere;max-height:34em;overflow:auto" (v:esc (record-text record)))))))

;;; The pins: where the Topic Maps commit is named, read live from the loaded source, not from this text.
(defclass pin-row () ((where :initarg :where :reader pin-row-where) (pin :initarg :pin :reader pin-row-pin)))
(defmethod v:text-representation ((r pin-row)) (pin-row-where r))
(defclass pins () ())
(defvar *pins* (make-instance 'pins))
(defun the-pins () *pins*)
(defmethod v:text-representation ((p pins)) "The Topic Maps pins")
(defun pin-rows ()
  (list (make-instance 'pin-row :where "Project Workspace (+topic-maps-revision+)" :pin p::+topic-maps-revision+)
        (make-instance 'pin-row :where "Catalog (+topic-maps-commit+)" :pin (symbol-value (find-symbol "+TOPIC-MAPS-COMMIT+" "DREYECK/CATALOG-TOPIC-MAPS")))
        (make-instance 'pin-row :where "22U reading (+source-revision+)" :pin (symbol-value (find-symbol "+SOURCE-REVISION+" "DREYECK/WORK/TOPIC-MAPS-PROJECT-EXAMPLE")))
        (make-instance 'pin-row :where "Manifest nix/topic-maps-88994c1b.manifest (:commit)" :pin (snap:manifest-commit (snap:find-snapshot-manifest +commit+)))))
(v:defview pins-view (pins pins)
  (v:html-view :title "Pins" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "Where HyperDoc names its Topic Maps commit")
       (:p "Read from the loaded source when this view is shown. Each should equal " (:code (v:esc +commit+)) ".")
       (:table :class "inspector-table"
        (:tr (:th "Place") (:th "Commit") (:th "Is 88994c1b"))
        (dolist (row (pin-rows))
          (v:html (:tr (:td (v:esc (pin-row-where row))) (:td (:code (v:esc (pin-row-pin row)))) (:td (v:esc (if (equal (pin-row-pin row) +commit+) "yes" "NO")))))))))))

(hyperdoc:defhyperdoc *topic-maps-task-1e-review*
  :title "Re-pinning Topic Maps to 88994c1b"
  :id "topic-maps-task-1e-review"
  :asdf-system-name "topic-maps-task-1e-review"
  :subdirectory "pages"
  :code-subdirectory "code"
  :main-page-id "Re-pinning Topic Maps to 88994c1b")
