;;;; Views, Explicit Runs and the Reading's Entry
(in-package #:topic-maps-integration-review)

(hyperdoc:see (hyperdoc:page "Integrating Topic Maps 6162ed68" :hyperbook "topic-maps-integration-review"))
(hyperdoc:see #'topic-maps.tmdm::next-topic-merge)
(hyperdoc:see #'topic-maps.tmdm::scan-next-topic-merge)
(hyperdoc:see #'topic-maps.tmdm::normalize-topic-map)
(hyperdoc:see #'p::topic-maps-source-identity)
(hyperdoc:see #'p::pinned-state-p)
(hyperdoc:see #'c:refuse-project-workspace)

(defun reading-links ()
  "The way back from any object of this reading to its pages."
  (v:html
    (:p :class "topic-maps-integration-review-links"
        "Back to the reading: "
        (v:object-ref (review-page "Integrating Topic Maps 6162ed68") :select "Content" :display "Overview")
        " · " (v:object-ref (the-workspace) :select "Topicmap" :display "Subjects")
        " · " (v:object-ref (review-page "Remaining Work and Acceptance") :select "Content" :display "Remaining work and acceptance"))))

;;; Records and claims

(v:defview record-view (record record)
  (v:html-view :title "Record" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (record-title record)))
       (:p (v:esc (format nil "~(~A~) evidence, ~A. File evidence/~A, ~D octets; its SHA-256 ~:[does NOT match~;matches~] evidence/SHA256SUMS."
                          (record-kind record) (record-when record) (record-file record)
                          (length (sb-ext:string-to-octets (record-text record) :external-format :utf-8)) (record-intact-p record))))
       (:p "Produced by: " (dolist (item (record-procedure record)) (if (stringp item) (v:html (v:esc item) " ") (v:html (v:object-ref item) " "))))
       (:h3 "Lines that state the outcome")
       (let ((lines (record-outcomes record)))
         (if lines
             (v:html (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc (format nil "~{~A~^~%~}" (subseq lines 0 (min 40 (length lines)))))))
             (v:html (:p "None of the outcome patterns occurs; see the whole record."))))
       (:h3 "The record")
       (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere;max-height:30em;overflow:auto" (v:esc (record-text record)))
       (reading-links)))))

(v:defview review-claim-view (claim review-claim)
  (v:html-view :title "Claim" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (claim-statement claim)))
       (:p (:strong "Known as: ") (v:esc (string-downcase (claim-class claim))) " · " (:strong "Id: ") (:code (v:esc (claim-id claim))))
       (:h3 "Evidence")
       (if (claim-evidence claim)
           (v:html (:ul (dolist (e (claim-evidence claim)) (v:html (:li (v:object-ref e :select "Record"))))))
           (v:html (:p (v:esc (if (eq :open (claim-class claim)) "None: this is not done." "None recorded: see its sources.")))))
       (:h3 "Sources")
       (if (claim-sources claim)
           (v:html (:ul (dolist (s (claim-sources claim)) (v:html (:li (v:object-ref s))))))
           (v:html (:p "No definition is named.")))
       (:h3 "What the evidence does not show")
       (:p (v:esc (or (claim-limit claim) "Nothing beyond what the class says.")))
       (reading-links)))))

(v:defview claims-table (workspace integration-workspace)
  (v:html-view :title "Claims" :priority 4
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "Every claim and how it is known")
       (:table :class "inspector-table"
        (:tr (:th "Known as") (:th "Claim") (:th "Evidence"))
        (dolist (c (claims))
          (v:html (:tr :data-claim-id (claim-id c)
                       (:td (v:esc (string-downcase (claim-class c))))
                       (:td (v:object-ref c :select "Claim" :display (claim-statement c)))
                       (:td (v:esc (format nil "~D record~:P" (length (claim-evidence c)))))))))
       (reading-links)))))

;;; Performance: read from the recorded benchmark files when shown

(defclass performance () () (:documentation "The recorded timings of reading the unchanged project CTM, and the slices b2eecffa can finish."))
(defmethod v:text-representation ((p performance)) "Performance difference")
(defvar *performance* (make-instance 'performance))
(defun the-performance () *performance*)

(defun json-file (file)
  (with-open-file (in (evidence-pathname file) :external-format :utf-8) (shasht:read-json in)))
(defun runs-of (summary) (coerce (gethash "runs" summary) 'list))
(defun performance-rows ()
  "Rows (label walls-in-seconds returncodes signature-equal-p experimental-p record-file), from the benchmark summaries."
  (flet ((row (label file &optional experimental)
           (let* ((runs (runs-of (json-file file))) (walls (loop for r in runs for w = (gethash "read_wall" r) when (numberp w) collect w)))
             (list label (sort (copy-list walls) #'<) (mapcar (lambda (r) (gethash "returncode" r)) runs)
                   (and runs (every (lambda (r) (and (eq t (gethash "signature_equals_5a4a668" r)) (eq t (gethash "cxtm_equals_5a4a668" r)))) runs))
                   experimental file))))
    (list (row "b2eecffa, SBCL 2.6.4 (limit 120 s)" "independent-bench-baseline-timeout.json")
          (row "Task 1C 6162ed68, SBCL 2.6.4, independent reproduction" "independent-bench-candidate.json")
          (row "Task 1C 6162ed68, packaged SBCL 2.4.10, independent" "independent-bench-candidate-nix.json")
          (row "6162ed68 integrated primary checkout, SBCL 2.6.4, this step" "phase-b-benchmark-integrated.json")
          (row "5a4a668 reference (sibling lineage)" "independent-bench-reference.json")
          (row "EXPERIMENTAL, not Task 1C: 6162ed68 + association index" "independent-bench-experimental.json" t))))
(defun median (numbers) (and numbers (nth (floor (length numbers) 2) (sort (copy-list numbers) #'<))))

(defparameter +slice-rows+
  '(("slice R3 (154 Topics, 3 reified Associations)" "111.475 s" "0.492 s")
    ("slice R8 (171 Topics, 8 reified Associations)" "152.317 s" "0.510 s"))
  "Quoted from independent-review.md, section 4; the test checks that the review states them.")
(defparameter +micro-rows+
  '(("Two Topics, no pair, per search" "0.420 µs" "1.424 µs") ("Eight Topics, immediate pair, per search" "1.898 µs" "4.074 µs")
    ("32 Topics, no pair, per search" "951.857 µs" "20.827 µs") ("Normalize 256 equal Topics, per map" "15.402 ms" "25.557 ms"))
  "Quoted from independent-review.md, section 5: the tradeoff on tiny or first-pair-heavy synthetic maps.")

(v:defview performance-view (performance performance)
  (v:html-view :title "Performance" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "Reading the unchanged project CTM")
       (:p "Read from the recorded benchmark summaries when this view is shown; nothing is measured now. The input is the 161,228-octet "
           "dreyeck/work/project/hyperdoc-project.ctm (SHA-256 f4f04bb4…b540d3).")
       (:table :class "inspector-table"
        (:tr (:th "Implementation and runtime") (:th "Read wall seconds") (:th "Median") (:th "Exit codes") (:th "Signature and CXTM equal 5a4a668") (:th "Record"))
        (dolist (row (performance-rows))
          (destructuring-bind (label walls codes same experimental file) row
            (v:html (:tr :class (if experimental "topic-maps-integration-review-experimental" "")
                         (:td (v:esc label))
                         (:td (v:esc (if walls (format nil "~{~,1F~^ / ~}" walls) "none: timed out")))
                         (:td (v:esc (if walls (format nil "~,1F" (median walls)) "—")))
                         (:td (v:esc (format nil "~{~A~^ ~}" codes)))
                         (:td (v:esc (cond ((null walls) "no output") (same "byte-identical") (t "NOT equal"))))
                         (:td (v:object-ref (record file) :select "Record" :display "record")))))))
       (:p "The operational limit is 90 seconds: met by the integrated revision (median about 34 s here, 29 s independently). The approximately 20-second aspiration is not met. "
           "The remaining time is the Association pair search; the experimental row shows what an association index would give and is not part of this integration.")
       (:h3 "Against b2eecffa itself, on the slices it can finish")
       (:table :class "inspector-table"
        (:tr (:th "Real corpus slice") (:th "b2eecffa") (:th "6162ed68"))
        (dolist (row +slice-rows+) (v:html (:tr (:td (v:esc (first row))) (:td (v:esc (second row))) (:td (v:esc (third row)))))))
       (:p "Their semantic signatures and CXTM are byte-identical. " (v:object-ref (record "independent-review.md") :select "Record" :display "The review"))
       (:h3 "A tradeoff the review measured")
       (:table :class "inspector-table"
        (:tr (:th "Synthetic workload") (:th "Old scan") (:th "Index"))
        (dolist (row +micro-rows+) (v:html (:tr (:td (v:esc (first row))) (:td (v:esc (second row))) (:td (v:esc (third row)))))))
       (:p "The index costs a constant more on tiny maps and nothing like the old scan's growth on larger ones; the review judged the extra work small in absolute terms and not a reason to hold the commit.")
       (reading-links)))))

;;; Revisions

(v:defview source-revision-view (revision source-revision)
  (v:html-view :title "Revision" :priority -10
    (let ((commit (revision-commit revision)))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 (v:esc (format nil "Topic Maps ~A" commit)))
         (:p (v:esc (format nil "~@(~A~). Read from ~A when shown." (revision-role revision) (or (topic-maps-repository) "no local repository"))))
         (:p (v:esc (or (revision-git revision "log" "-1" "--format=%s (%ad, tree %T)" "--date=short" commit) "The commit is not in the local repository, or there is no repository here.")))
         (:p (v:esc (format nil "Branches holding it: ~A" (or (revision-git revision "branch" "--format=%(refname:short)" "--contains" commit) "none"))))
         (reading-links))))))

(v:defview git-observation-view (o git-observation)
  (v:html-view :title "Git answer" :priority -10
    (v:html
      (:h2 (v:esc (observation-question o)))
      (:p (:code (v:esc (format nil "~{~A~^ ~}" (observation-command o)))) (v:esc (format nil " in ~A" (topic-maps-repository))))
      (:p (v:esc (format nil "Exit status ~A, so: ~(~A~). Asked at ~A (universal time), when the subjects were projected." (observation-exit-code o) (observation-answer o) (observation-at o))))
      (reading-links))))

(v:defview snapshot-manifest-view (manifest snap:snapshot-manifest)
  (v:html-view :title "Manifest" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (format nil "The snapshot manifest of Topic Maps ~A" (snap:manifest-commit manifest))))
       (:p (v:esc (format nil "NAR hash ~A. Excluded: ~{~A~^, ~}. Read from ~A." (snap:manifest-nar-hash manifest) (snap:manifest-excluded manifest)
                          (namestring (snap:manifest-pathname manifest)))))
       (:h3 "The raw commit object")
       (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc (snap:manifest-commit-object manifest)))
       (:h3 (v:esc (format nil "The root tree ~A" (snap:manifest-root-tree manifest))))
       (:table :class "inspector-table"
        (:tr (:th "Mode") (:th "Type") (:th "Id") (:th "Name") (:th "In the snapshot"))
        (dolist (entry (snap:manifest-entries manifest))
          (destructuring-bind (mode type id name) entry
            (v:html (:tr (:td (:code (v:esc mode))) (:td (v:esc type)) (:td (:code (v:esc id))) (:td (:code (v:esc name)))
                         (:td (v:esc (if (member name (snap:manifest-excluded manifest) :test #'string=) "excluded: named, not shipped" "shipped"))))))))
       (reading-links)))))

;;; Three explicit runs. Rendering a view runs none of them; each has a plain v:thunk button.

(defclass topic-maps-source () ((runs :initform nil :accessor runs))
  (:documentation "The Topic Maps source of this image, asked about on request."))
(defmethod v:text-representation ((s topic-maps-source)) "Topic Maps source of this image")
(defvar *topic-maps-source* (make-instance 'topic-maps-source))
(defun the-topic-maps-source () *topic-maps-source*)

(defun source-facts ()
  "What can be said without verifying: the directory ASDF loaded topic-maps from and what kind of tree it is."
  (let ((root (asdf:system-source-directory "topic-maps")))
    (list :directory (namestring root) :kind (snap:source-kind root))))

(defclass source-run () ((identity :initarg :identity :reader run-identity) (seconds :initarg :seconds :reader run-seconds) (at :initarg :at :reader run-at)))
(defmethod v:text-representation ((r source-run)) (format nil "Source identity: ~(~A~)" (getf (run-identity r) :kind)))
(hyperdoc:defexample identify-topic-maps-source-now
  "Ask HyperDoc's own pin check what Topic Maps source this image loaded: a clean Git checkout of 6162ed68, its verified Git-free snapshot, or neither."
  (let* ((start (get-internal-real-time)) (identity (p::topic-maps-source-identity))
         (run (make-instance 'source-run :identity identity :at (get-universal-time)
                                         :seconds (/ (- (get-internal-real-time) start) internal-time-units-per-second 1.0))))
    (push run (runs *topic-maps-source*))
    run))
(v:defview source-run-view (run source-run)
  (v:html-view :title "Source identity" :priority -10
    (let ((identity (run-identity run)))
      (v:html
        (:h2 (v:esc (format nil "Topic Maps source: ~(~A~)" (getf identity :kind))))
        (:table :class "inspector-table"
         (dolist (key '(:directory :kind :commit :clean :one-root :pinned :reason))
           (when (member key identity) (v:html (:tr (:th (v:esc (string-downcase key))) (:td (:code (v:esc (format nil "~A" (getf identity key))))))))))
        (:p (v:esc (format nil "Pinned revision: ~A. Asked at ~A (universal time); the check took ~,2F s." p::+topic-maps-revision+ (run-at run) (run-seconds run))))
        (reading-links)))))
(v:defview topic-maps-source-view (source topic-maps-source)
  (v:html-view :title "Source" :priority -10
    (let ((facts (source-facts)))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 "The Topic Maps source of this image")
         (:p (v:esc (format nil "ASDF loaded topic-maps from ~A, a ~(~A~)." (getf facts :directory) (getf facts :kind))))
         (:p "The pinned revision is " (:code (v:esc +reviewed-commit+)) ". Rendering this view verifies nothing; the button asks the pin check.")
         (:p (v:eval-button "Identify the Topic Maps source now" (v:thunk (identify-topic-maps-source-now)) "Run identify-topic-maps-source-now"))
         (:p "The procedure: " (v:object-ref #'p::topic-maps-source-identity :select "Source code") ", which uses " (v:object-ref #'snap:verify-store-snapshot :select "Source code")
             " for a /nix/store snapshot and Git's own answers for a checkout.")
         (:h3 "Runs in this image")
         (if (runs source)
             (v:html (:ul (dolist (r (runs source)) (v:html (:li (v:object-ref r :select "Source identity"))))))
             (v:html (:p "None yet.")))
         (reading-links))))))

(defclass guard-run () ((condition :initarg :condition :reader run-condition) (loaded :initarg :loaded :reader run-loaded) (at :initarg :at :reader run-at)))
(defmethod v:text-representation ((r guard-run)) (if (run-condition r) "Refused" "Not refused"))
(defvar *guard-runs* nil)
(hyperdoc:defexample ask-whether-project-workspace-is-refused
  "Ask the packaged startup check whether it refuses dreyeck/work/project. It reads system definitions; this image has loaded the Workspace already."
  (let* ((condition (handler-case (progn (c:refuse-project-workspace "dreyeck/work/project") nil) (c:project-workspace-refused (refusal) refusal)))
         (run (make-instance 'guard-run :condition condition :loaded (asdf:component-loaded-p "dreyeck/work/project") :at (get-universal-time))))
    (push run *guard-runs*) run))
(v:defview guard-run-view (run guard-run)
  (v:html-view :title "Guard result" :priority -10
    (v:html
      (:h2 (v:esc (if (run-condition run) "The startup check refuses the Project Workspace" "The startup check does not refuse it")))
      (:p (if (run-condition run) (v:esc (princ-to-string (run-condition run))) (v:esc "No refusal was signalled.")))
      (:p (v:esc (format nil "dreyeck/work/project is ~:[not ~;~]loaded in this image (it has to be, for this reading); the check reads definitions, so that is no reason for it to pass. Asked at ~A." (run-loaded run) (run-at run))))
      (reading-links))))

(defclass read-run ()
  ((seconds :initarg :seconds :reader run-seconds) (digest :initarg :digest :reader run-digest) (equal-retained :initarg :equal-retained :reader run-equal-retained)
   (topics :initarg :topics :reader run-topics) (associations :initarg :associations :reader run-associations) (refusal :initarg :refusal :reader run-refusal)))
(defmethod v:text-representation ((r read-run)) (format nil "CTM read in ~,1F s" (run-seconds r)))
(defvar *read-runs* nil)
(hyperdoc:defexample read-project-ctm-now
  "Read the retained project CTM once with this image's Topic Maps reader (about half a minute) and report the time, digest and counts. Writes nothing."
  (let* ((path (p:project-ctm-pathname)) (start (get-internal-real-time)) (revision (p:observe-ctm-revision path))
         (seconds (/ (- (get-internal-real-time) start) internal-time-units-per-second 1.0)) (map (p:revision-map revision))
         (run (make-instance 'read-run :seconds seconds :digest (p:revision-sha256 revision) :refusal (p:revision-refusal revision)
                                       :equal-retained (equal (p:revision-sha256 revision) (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))
                                       :topics (and map (length (topic-maps.tmdm:topic-map-topics map)))
                                       :associations (and map (length (topic-maps.tmdm:topic-map-associations map))))))
    (push run *read-runs*) run))
(v:defview read-run-view (run read-run)
  (v:html-view :title "CTM read" :priority -10
    (v:html
      (:h2 (v:esc (format nil "The project CTM read in ~,1F seconds" (run-seconds run))))
      (:p (v:esc (format nil "SHA-256 ~A (~:[differs from~;equals~] the file now); ~A Topics, ~A Associations; refusal ~S. The 90-second limit is ~:[NOT met~;met~]."
                         (run-digest run) (run-equal-retained run) (run-topics run) (run-associations run) (run-refusal run) (< (run-seconds run) 90))))
      (:p "The time depends on the machine and its load; compare the recorded runs in " (v:object-ref (the-performance) :select "Performance" :display "Performance") ".")
      (reading-links))))
(v:defview experiments-view (workspace integration-workspace)
  (v:html-view :title "Runs" :priority 3
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "Three things this reading can run, only when you press the button")
       (:p "Rendering any view of this reading runs none of them. They are plain v:thunk buttons; whether the served Catalog's authority policy gates them is not established, so serve this reading on loopback only.")
       (:p (v:eval-button "Identify the Topic Maps source now" (v:thunk (identify-topic-maps-source-now)) "Run identify-topic-maps-source-now")
           " — a verified snapshot hashes 2,354 files; a checkout asks Git.")
       (:p (v:eval-button "Ask whether the Project Workspace is refused" (v:thunk (ask-whether-project-workspace-is-refused)) "Run ask-whether-project-workspace-is-refused")
           " — reads definitions only.")
       (:p (v:eval-button "Read the project CTM now (about 30 s)" (v:thunk (read-project-ctm-now)) "Run read-project-ctm-now")
           " — blocks this server while it runs.")
       (:h3 "Results so far")
       (:ul (dolist (r (append (runs (the-topic-maps-source)) *guard-runs* *read-runs*)) (v:html (:li (v:object-ref r)))))
       (reading-links)))))

(hyperdoc:defhyperdoc *topic-maps-integration-review*
  :title "Integrating Topic Maps 6162ed68"
  :id "topic-maps-integration-review"
  :asdf-system-name "topic-maps-integration-review"
  :subdirectory "pages"
  :code-subdirectory "code"
  :main-page-id "Integrating Topic Maps 6162ed68")
