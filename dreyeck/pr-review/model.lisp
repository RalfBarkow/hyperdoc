;;;; Explicit observations and curated warrants, not a GitHub client or acceptance model.
(defpackage #:dreyeck/pull-request-review
  (:use #:cl)
  (:local-nicknames (#:tm #:dreyeck/topicmap))
  (:export #:import-snapshot #:import-annotations #:make-reading #:example-reading
           #:make-unavailable-snapshot #:make-human-review-note #:snapshot-age-status
           #:changed-revisions #:claim-status #:mark-status #:note-status
           #:review-snapshot #:pull-request-observation #:github-commit #:github-issue
           #:source-document #:relationship-claim #:source-mark #:human-review-note
           #:review-reading #:pull-request-review #:review-pr #:reading-items #:snapshot-prs #:snapshot-issues #:snapshot-observed-at
           #:snapshot-digest #:snapshot-status #:snapshot-repository #:snapshot-url
           #:pr-number #:pr-repository #:pr-title #:pr-head #:pr-base #:pr-head-ref #:pr-base-ref
           #:pr-draft #:pr-state #:pr-url #:pr-commits #:pr-source
           #:commit-sha #:commit-url #:reading-snapshot #:reading-notes
           #:reading-claims #:reading-marks #:claim-type #:claim-quote #:claim-level
           #:find-pr #:make-reading-book #:local-reading #:prepare-example-reading))
(in-package #:dreyeck/pull-request-review)

(defparameter +repository+ "RalfBarkow/hyperdoc")
(defparameter +web+ "https://github.com/RalfBarkow/hyperdoc/")
(defparameter +levels+ '(("observed" . :source-observed) ("derived" . :mechanically-derived)
                        ("inferred" . :design-inference) ("hypothesized" . :working-hypothesis)))
(defparameter +relations+ '(("ctm-source" . :reported-verified-ctm-source)
                           ("source-port" . :source-port)
                           ("separate-investigation" . :separate-investigation)))

(defstruct (source-document (:conc-name document-))
  (url "" :read-only t) (text "" :read-only t) (digest "" :read-only t)
  (observed-at "" :read-only t))
(defstruct (github-commit (:conc-name commit-))
  (sha "" :read-only t) (repository "" :read-only t) (url "" :read-only t)
  (message "" :read-only t))
(defstruct (pull-request-observation (:conc-name pr-))
  (repository +repository+ :read-only t)
  (number 0 :read-only t) (title "" :read-only t) (url "" :read-only t)
  (base-ref "" :read-only t) (head-ref "" :read-only t)
  (base nil :read-only t) (head nil :read-only t) (commits nil :read-only t)
  (draft nil :read-only t) (state "" :read-only t) (source nil :read-only t)
  (observed-at "" :read-only t))
(defstruct (github-issue (:conc-name issue-))
  (number 0 :read-only t) (title "" :read-only t) (url "" :read-only t)
  (state "" :read-only t) (source nil :read-only t))
(defstruct (review-snapshot (:conc-name snapshot-))
  (repository +repository+ :read-only t) (repository-id nil :read-only t)
  (observed-at "" :read-only t) (url "" :read-only t) (digest "" :read-only t)
  (status :available :read-only t) (reason nil :read-only t)
  (prs nil :read-only t) (issues nil :read-only t))
(defstruct (relationship-claim (:conc-name claim-))
  (type nil :read-only t) (from 0 :read-only t) (to 0 :read-only t)
  (from-sha "" :read-only t) (to-revision "" :read-only t)
  (level :mechanically-derived :read-only t) (source-pr 0 :read-only t)
  (body-digest "" :read-only t) (quote "" :read-only t))
(defstruct (source-mark (:conc-name mark-))
  (pr 0 :read-only t) (head "" :read-only t) (kind nil :read-only t)
  (label "" :read-only t) (url "" :read-only t) (quote "" :read-only t)
  (body-digest "" :read-only t))
(defstruct (human-review-note (:conc-name note-))
  (pr 0 :read-only t) (head "" :read-only t) (author "" :read-only t)
  (recorded-at "" :read-only t) (text "" :read-only t))
(defstruct (pull-request-review (:conc-name review-))
  (pr nil :read-only t) (snapshot nil :read-only t) (marks nil :read-only t)
  (claims nil :read-only t) (notes nil :read-only t))
(defstruct (review-reading (:conc-name reading-))
  (snapshot nil :read-only t) (claims nil :read-only t) (marks nil :read-only t)
  (notes nil :read-only t) (items nil :read-only t) (annotation-digest nil :read-only t))

(defun digest-text (text)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence :sha256 (babel:string-to-octets text :encoding :utf-8))))
(defun %string (object key)
  (let ((value (gethash key object)))
    (unless (stringp value) (error "Expected string field ~A" key)) value))
(defun %array (object key)
  (let ((value (gethash key object)))
    (unless (and (vectorp value) (not (stringp value))) (error "Expected array field ~A" key))
    (coerce value 'list)))
(defun %number (object key)
  (let ((value (gethash key object)))
    (unless (and (integerp value) (plusp value)) (error "Expected positive integer field ~A" key)) value))
(defun %sha (value)
  (unless (and (stringp value) (= 40 (length value))
               (every (lambda (c) (digit-char-p c 16)) value)) (error "Invalid full Git SHA")) value)
(defun %web (path) (concatenate 'string +web+ path))
(defun %url (value expected)
  (unless (equal value expected) (error "Source URL does not match its identity")) value)
(defun %body (row)
  (let ((body (gethash "body" row)))
    (cond ((stringp body) body) ((member body '(nil :null)) "") (t (error "Invalid body")))))
(defun %utc (text)
  (unless (and (stringp text) (= 20 (length text))
               (loop for (i c) in '((4 #\-) (7 #\-) (10 #\T) (13 #\:) (16 #\:) (19 #\Z))
                     always (char= c (char text i)))) (error "Expected UTC observation time"))
  (flet ((n (start end) (parse-integer text :start start :end end)))
    (encode-universal-time (n 17 19) (n 14 16) (n 11 13) (n 8 10) (n 5 7) (n 0 4) 0)))
(defun %json-file (path)
  ;; Trusted, explicit local import only. No URL fetch, Lisp reader or evaluation.
  (with-open-file (in path :element-type '(unsigned-byte 8))
    (when (> (file-length in) (* 4 1024 1024)) (error "Snapshot exceeds import bound")))
  (let ((text (uiop:read-file-string path :external-format :utf-8)))
    (values (with-input-from-string (in text)
              (let ((value (shasht:read-json in)))
                (when (peek-char t in nil nil) (error "Trailing data after JSON"))
                (unless (hash-table-p value) (error "Expected JSON object")) value))
            (digest-text text))))
(defun %source (row observed)
  (let ((text (%body row)))
    (make-source-document :url (%string row "html_url") :text text
                          :digest (digest-text text) :observed-at observed)))
(defun %state (row)
  (let ((state (%string row "state")))
    (unless (member state '("open" "closed") :test #'equal) (error "Invalid state")) state))
(defun %unique-numbers (rows)
  (let ((numbers (mapcar (lambda (r) (%number r "number")) rows)))
    (unless (= (length numbers) (length (remove-duplicates numbers))) (error "Duplicate object numbers"))))

(defun import-snapshot (pathname)
  "Import only a completed trusted capture; all displayed GitHub data remains inert."
  (multiple-value-bind (json digest) (%json-file pathname)
    (unless (= 1 (gethash "schemaVersion" json 0)) (error "Unsupported snapshot schema"))
    (let* ((repository (gethash "repository" json))
           (name (%string repository "fullName"))
           (observed (%string json "observedAt"))
           (rows (%array json "pullRequests")) (issues (%array json "issues"))
           (commits (make-hash-table :test #'equal)))
      (unless (equal name +repository+) (error "Unexpected repository authority"))
      (%number repository "id") (%utc observed)
      (%url (%string json "sourceURL") "https://api.github.com/repos/RalfBarkow/hyperdoc/pulls?state=open&per_page=100")
      (unless (equal "available" (gethash "status" json)) (error "Use an explicit unavailable observation"))
      (%unique-numbers rows) (%unique-numbers issues)
      (labels ((commit (sha &optional (message ""))
                 (%sha sha)
                 (or (gethash sha commits)
                     (setf (gethash sha commits)
                           (make-github-commit :sha sha :repository name :message message
                                               :url (%web (format nil "commit/~A" sha)))))))
        ;; Populate messages before constructing shared base/head references.
        (dolist (row rows)
          (dolist (entry (%array row "commits"))
            (commit (%string entry "sha") (%string entry "message"))))
        (make-review-snapshot
         :repository name :repository-id (gethash "id" repository) :observed-at observed
         :url (%string json "sourceURL") :digest digest
         :prs
         (sort
          (mapcar
           (lambda (row)
             (let* ((number (%number row "number")) (head (gethash "head" row)) (base (gethash "base" row))
                    (history
                     (mapcar (lambda (entry)
                               (let ((sha (%string entry "sha")))
                                 (%url (%string entry "html_url") (%web (format nil "commit/~A" sha)))
                                 (commit sha (%string entry "message"))))
                             (%array row "commits")))
                    (head-object (commit (%string head "sha"))))
               (dolist (side (list head base))
                 (unless (equal name (%string side "repository")) (error "Foreign branch authority")))
               (unless (and history (eq head-object (car (last history))))
                 (error "Commit history does not reach observed head"))
               (unless (member (gethash "draft" row) '(t nil :true :false)) (error "Invalid draft flag"))
               (make-pull-request-observation
                :repository name :number number :title (%string row "title")
                :url (%url (%string row "html_url") (%web (format nil "pull/~D" number)))
                :head head-object :base (commit (%string base "sha")) :commits history
                :head-ref (%string head "ref") :base-ref (%string base "ref")
                :draft (not (null (member (gethash "draft" row) '(t :true))))
                :state (%state row) :source (%source row observed) :observed-at observed))) rows)
          #'< :key #'pr-number)
         :issues
         (mapcar (lambda (row)
                   (let ((number (%number row "number")))
                     (make-github-issue
                      :number number :title (%string row "title") :state (%state row)
                      :url (%url (%string row "html_url") (%web (format nil "issues/~D" number)))
                      :source (%source row observed)))) issues))))))

(defun make-unavailable-snapshot (observed-at &optional (reason "GitHub capture unavailable"))
  (%utc observed-at)
  (make-review-snapshot :observed-at observed-at :status :unavailable :reason reason))
(defun find-pr (snapshot number) (find number (snapshot-prs snapshot) :key #'pr-number))
(defun snapshot-age-status (snapshot &key (now (get-universal-time)) (max-age 86400))
  (cond ((eq :unavailable (snapshot-status snapshot)) :unavailable)
        ((< now (%utc (snapshot-observed-at snapshot))) :future-observation)
        ((> (- now (%utc (snapshot-observed-at snapshot))) max-age) :stale-by-age)
        (t :within-age-window-unchecked)))
(defun changed-revisions (old newer)
  "No implicit refresh: compare two explicit observations, including missing PRs."
  (unless (and (eq :available (snapshot-status old)) (eq :available (snapshot-status newer)))
    (return-from changed-revisions :unavailable))
  (remove-if-not
   (lambda (number)
     (let ((a (find-pr old number)) (b (find-pr newer number)))
       (or (not a) (not b) (not (equal (commit-sha (pr-head a)) (commit-sha (pr-head b))))
           (not (equal (commit-sha (pr-base a)) (commit-sha (pr-base b)))))))
   (remove-duplicates (append (mapcar #'pr-number (snapshot-prs old)) (mapcar #'pr-number (snapshot-prs newer))))))

(defun %warrant-valid-p (pr digest quote)
  (and pr (plusp (length quote)) (equal digest (document-digest (pr-source pr)))
       (search quote (document-text (pr-source pr)))))
(defun claim-status (snapshot claim)
  "Supported means a curated, revision-qualified textual warrant, never acceptance."
  (let* ((type (claim-type claim)) (from (find-pr snapshot (claim-from claim)))
         (source (find-pr snapshot (claim-source-pr claim)))
         (to (if (eq type :separate-investigation)
                 (find (claim-to claim) (snapshot-issues snapshot) :key #'issue-number)
                 (find-pr snapshot (claim-to claim)))))
    (cond
      ((not (member type (mapcar #'cdr +relations+))) :unsupported-type)
      ((not (member (claim-level claim) '(:source-observed :mechanically-derived))) :unasserted)
      ((or (not from) (not to) (not source)) :missing-endpoint)
      ((or (not (equal (claim-from-sha claim) (commit-sha (pr-head from))))
           (not (equal (claim-to-revision claim)
                       (if (github-issue-p to) (document-digest (issue-source to)) (commit-sha (pr-head to)))))) :stale-revision)
      ((not (%warrant-valid-p source (claim-body-digest claim) (claim-quote claim))) :unsupported-warrant)
      ;; Every supported relation uses a qualified consumer report, never commit ancestry.
      ((not (= (claim-source-pr claim) (if (eq type :separate-investigation) (claim-from claim) (claim-to claim)))) :unsupported-warrant)
      ((and (not (eq type :separate-investigation))
            (not (search (claim-from-sha claim) (claim-quote claim)))) :unsupported-warrant)
      (t :supported))))
(defun mark-status (snapshot mark)
  (let ((pr (find-pr snapshot (mark-pr mark))))
    (cond ((not pr) :missing-endpoint)
          ((not (equal (mark-head mark) (commit-sha (pr-head pr)))) :stale-revision)
          ((not (%warrant-valid-p pr (mark-body-digest mark) (mark-quote mark))) :unsupported-warrant)
          (t :supported))))
(defun note-status (snapshot note)
  (let ((pr (find-pr snapshot (note-pr note))))
    (cond ((not pr) :missing-endpoint)
          ((not (equal (note-head note) (commit-sha (pr-head pr)))) :stale-revision)
          (t :review-note-only))))
(defun import-annotations (pathname)
  "Separate curated source claims; no alteration of the GitHub snapshot."
  (multiple-value-bind (json digest) (%json-file pathname)
    (unless (and (= 1 (gethash "schemaVersion" json 0)) (equal +repository+ (%string json "repository")))
      (error "Unexpected annotation authority/schema"))
    (values
     (mapcar (lambda (row)
               (make-relationship-claim
                :type (or (cdr (assoc (%string row "type") +relations+ :test #'equal)) :unsupported)
                :from (%number row "from") :to (%number row "to")
                :from-sha (%sha (%string row "fromHead")) :to-revision (%string row "toRevision")
                :source-pr (%number row "sourcePR") :body-digest (%string row "bodyDigest")
                :quote (%string row "quote")
                :level (or (cdr (assoc (%string row "level") +levels+ :test #'equal)) :unsupported)))
             (%array json "claims"))
     (mapcar (lambda (row)
               (let ((url (%string row "url")) (kind (%string row "kind")))
                 (unless (member kind '("evidence" "question") :test #'equal)
                   (error "Unsupported source mark kind"))
                 (unless (every (lambda (c) (or (and (<= 33 (char-code c) 126)
                                                                      (alphanumericp c))
                                                    (find c "/:-._~%?#=&+@"))) url)
                   (error "Unsafe navigation URL"))
                 (unless (and (<= (length +web+) (length url)) (string= +web+ url :end2 (length +web+)))
                   (error "Untrusted source navigation URL"))
                 (make-source-mark :pr (%number row "pr") :head (%sha (%string row "head"))
                                   :kind (if (equal "evidence" kind) :reported-evidence :reported-question)
                                   :label (%string row "label") :url url :quote (%string row "quote")
                                   :body-digest (%string row "bodyDigest")))) (%array json "marks"))
     digest)))
(defun make-reading (snapshot &key claims marks notes annotation-digest)
  (check-type snapshot review-snapshot)
  (unless (every #'human-review-note-p notes) (error "Human notes must be separate note objects"))
  (make-review-reading :snapshot snapshot :claims (copy-list claims) :marks (copy-list marks)
                       :notes (copy-list notes) :annotation-digest annotation-digest
                       :items (mapcar
                               (lambda (pr)
                                 (make-pull-request-review
                                  :pr pr :snapshot snapshot
                                  :marks (remove-if-not (lambda (m) (= (pr-number pr) (mark-pr m))) marks)
                                  :claims (remove-if-not
                                           (lambda (c) (or (= (pr-number pr) (claim-from c))
                                                           (and (not (eq :separate-investigation (claim-type c)))
                                                                (= (pr-number pr) (claim-to c))))) claims)
                                  :notes (remove-if-not (lambda (n) (= (pr-number pr) (note-pr n))) notes)))
                               (snapshot-prs snapshot))))
(defun example-reading ()
  (let* ((root (asdf:system-relative-pathname "dreyeck/pull-request-review" "dreyeck/pr-review/example/"))
         (snapshot (import-snapshot (merge-pathnames "github-snapshot.json" root))))
    (multiple-value-bind (claims marks digest) (import-annotations (merge-pathnames "review-annotations.json" root))
      (make-reading snapshot :claims claims :marks marks :annotation-digest digest))))

(defmethod tm:topicmap-projection-of ((reading review-reading))
  (let* ((snapshot (reading-snapshot reading))
         (topics (list (tm:make-topicmap-topic :id "snapshot" :type :github-observation
                          :label "Observed GitHub PRs"
                          ;; Observation time belongs to the snapshot's provenance,
                          ;; not to the producer's status classification.
                          :object snapshot :view-properties (list :x 300 :y 40 :visible t :pinned t :kind "snapshot"))))
         (associations nil))
    (flet ((pr-id (number) (format nil "pr:~A:~D" (snapshot-repository snapshot) number)))
      (loop for item in (reading-items reading) for pr = (review-pr item) for i from 0 do
        (push (tm:make-topicmap-topic :id (pr-id (pr-number pr)) :type :pull-request
                :label (format nil "PR #~D" (pr-number pr)) :object item
                :view-properties (list :x (+ 30 (* 290 (mod i 3))) :y (+ 170 (* 200 (floor i 3))) :visible t :pinned nil
                                       :kind "pull request" :status (if (pr-draft pr) "draft" (pr-state pr)))) topics)
        (push (tm:make-topicmap-association :id (format nil "observed:~D" (pr-number pr)) :type :observed-pr
                :from "snapshot" :to (pr-id (pr-number pr))
                :properties (list :epistemic-status :source-observed :warrant (pr-url pr) :source (pr-source pr))) associations))
      (loop for issue in (snapshot-issues snapshot) for i from 0 do
        (push (tm:make-topicmap-topic :id (format nil "issue:~D" (issue-number issue)) :type :github-issue
                :label (format nil "Issue #~D" (issue-number issue)) :object issue
                :view-properties (list :x (+ 30 (* 290 i)) :y (+ 190 (* 200 (ceiling (length (snapshot-prs snapshot)) 3))) :visible t :pinned nil)) topics))
      (loop for claim in (reading-claims reading) for i from 0
            when (eq :supported (claim-status snapshot claim)) do
        (push (tm:make-topicmap-association :id (format nil "claim:~D" i) :type (claim-type claim)
                :from (pr-id (claim-from claim))
                :to (if (eq :separate-investigation (claim-type claim)) (format nil "issue:~D" (claim-to claim)) (pr-id (claim-to claim)))
                :properties (list :epistemic-status (claim-level claim) :warrant (claim-quote claim)
                                  :claim claim :basis :curated-source-reference :git-merge-dependency nil)) associations)))
    (tm:make-topicmap-projection :source reading :topics (nreverse topics) :associations (nreverse associations)
       :view-properties (list :width 1000 :height (+ 400 (* 200 (ceiling (length (snapshot-prs snapshot)) 3)))
                              :scope :observed-github-snapshot :point "snapshot"))))
