;;;; Explaining Prepare edit proposal through the objects it makes
(defpackage #:dreyeck/work/item-edit-proposal
  (:use #:cl)
  (:local-nicknames (#:c #:dreyeck/work/ctm-page-authoring)
                    (#:v #:html-inspector-views)
                    (#:lp #:dreyeck/local-fedwiki-page)
                    (#:p #:dreyeck/fedwiki-item-edit-preview)
                    (#:plan #:dreyeck/fedwiki-page-edit-plan))
  ;; The recorded trial is defined where the Edit Action view is, in the preview system.
  (:import-from #:dreyeck/fedwiki-item-edit-preview #:persisted-trial #:trial-record #:trial-path #:read-trial-record)
  (:export #:read-proposal-anatomy #:proposal-anatomy #:anatomy-subject #:anatomy-source #:anatomy-item
           #:anatomy-proposal #:anatomy-preview #:anatomy-expected #:anatomy-replacement #:anatomy-action
           #:anatomy-next-page #:anatomy-index #:anatomy-trial
           #:persisted-trial #:trial-record #:trial-path #:retained-site-root #:read-trial-record
           #:source-line #:proposal-reading-error))
(in-package #:dreyeck/work/item-edit-proposal)

;; Prepare edit proposal is an operation: the button of the view STORY-ITEM-EDIT-OFFER,
;; whose thunk calls PROPOSE-ITEM-EDIT. It is neither the Work package ctm-wp-2, which
;; says what the proposal is for, nor a TMDM Topic. This reading forms one real proposal
;; for E3 on the retained copy of the page, previews it, and shows each object it
;; rests on as an object. It loads no writer, grants no capability, writes nothing, and
;; keeps what a preview computes apart from what a recorded trial persisted.

(defparameter +slug+ "ctm-and-tmdm-in-hyperdoc")
(defparameter +e3-id+ "ed37e9bac2fcd548")
(defparameter +writer-package+ "DREYECK/FEDWIKI-PAGE-AUTHORING")

(define-condition proposal-reading-error (error)
  ((reason :initarg :reason :reader reading-error-reason))
  (:report (lambda (condition stream) (format stream "Proposal reading refused: ~A" (reading-error-reason condition)))))
(defun refuse (control &rest arguments)
  (error 'proposal-reading-error :reason (apply #'format nil control arguments)))

(defun repo-file (relative)
  (asdf:system-relative-pathname "dreyeck/work/item-edit-proposal" relative))
(defun retained-site-root () (repo-file "dreyeck/work/ctm-page-evidence/site/"))
(defun file-text (path) (uiop:read-file-string path :external-format :utf-8))
(defun file-digest (path) (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))
(defun rj (object &rest keys) (dolist (key keys object) (setf object (gethash key object))))

(defun source-line (file marker)
  "The line of FILE, relative to this repository, on which MARKER occurs once."
  (let* ((text (file-text (repo-file file))) (at (search marker text)))
    (unless at (refuse "~S does not occur in ~A" marker file))
    (when (search marker text :start2 (1+ at)) (refuse "~S occurs more than once in ~A" marker file))
    (1+ (count #\Newline text :end at))))

;;; Objects

(defclass proposal-anatomy ()
  ((subject :initarg :subject :reader anatomy-subject)
   (source :initarg :source :reader anatomy-source)
   (item :initarg :item :reader anatomy-item)
   (proposal :initarg :proposal :reader anatomy-proposal)
   (preview :initarg :preview :reader anatomy-preview)
   (trial :initarg :trial :reader anatomy-trial))
  (:documentation "One proposal for Story Item E3 and the preview it gives, each part an object."))

(defun anatomy-expected (anatomy) (p:preview-expected-item (anatomy-preview anatomy)))
(defun anatomy-action (anatomy) (p:preview-action (anatomy-preview anatomy)))
(defun anatomy-replacement (anatomy) (gethash "item" (anatomy-action anatomy)))
(defun anatomy-next-page (anatomy) (p:preview-next-page (anatomy-preview anatomy)))
(defun anatomy-index (anatomy) (p:preview-index (anatomy-preview anatomy)))

(defun read-proposal-anatomy (&key subject (site-root (retained-site-root)) (check-revision t))
  "Observe the page file under SITE-ROOT, propose the recorded example text for E3 and preview it.
Reads only. With CHECK-REVISION the revision must be the one the trial record names."
  (let* ((trial (read-trial-record))
         (record (trial-record trial))
         (source (lp:observe-local-fedwiki-page-source site-root +slug+))
         (item (find +e3-id+ (lp:source-story-items source) :key #'lp:story-item-id :test #'equal)))
    (when (and check-revision (not (equal (rj record "before" "pageSha256") (lp:page-source-sha256 source))))
      (refuse "the page file is revision ~A, not the recorded ~A" (lp:page-source-sha256 source) (rj record "before" "pageSha256")))
    (unless item (refuse "the page has no Story Item ~A" +e3-id+))
    (let ((proposal (p:propose-item-edit item (rj record "action" "replacementText"))))
      (make-instance 'proposal-anatomy :subject subject :source source :item item :proposal proposal
                                       :preview (p:preview-item-edit proposal) :trial trial))))

(defmethod v:text-representation ((anatomy proposal-anatomy)) "Prepare edit proposal: its objects")

;;; The present image

(defun %symbol (name package) (let ((pkg (find-package package))) (and pkg (find-symbol name pkg))))
(defun writer-class () (let ((s (%symbol "FEDWIKI-PAGE-EDIT" +writer-package+))) (and s (find-class s nil))))
(defun slot-names (class)
  (unless (sb-mop:class-finalized-p class) (sb-mop:finalize-inheritance class))
  (mapcar #'sb-mop:slot-definition-name (sb-mop:class-slots class)))

;;; Inspection

(defun ref (object &optional label select)
  (v:html (v:object-ref object :display (or label (v:text-representation object)) :select select)))
(defun function-ref (symbol) (ref (fdefinition symbol) (string-downcase (symbol-name symbol))))
(defun json-text (value) (shasht:write-json value nil))
(defvar *anatomy-of* (make-hash-table :test 'eq :weakness :key))
(defun remember (anatomy)
  (dolist (part (list anatomy (anatomy-trial anatomy)))
    (setf (gethash part *anatomy-of*) anatomy))
  anatomy)
(defun links (anatomy)
  (v:html (:p (ref anatomy "Anatomy" "Anatomy") " / " (ref anatomy "Preview or edit?" "Preview or edit?") " / "
              (ref anatomy "Operation or topic?" "Operation or topic?") " / "
              (ref (anatomy-trial anatomy) "Recorded persisted trial" "Persisted trial"))))

(v:defview wp2-proposal-anatomy (subject c::wbs-element)
  (when (equal "ctm-wp-2" (c::subject-id subject))
    (v:html-view :title "Proposal anatomy" :priority 998
      (let ((anatomy (remember (read-proposal-anatomy :subject subject))))
        (v:html (:h2 "What Prepare edit proposal makes")
          (:p "One real proposal for Story Item E3, the preview it gives and what an executed edit would add, as objects. Opening it writes nothing, loads no writer and grants no capability.")
          (:p (ref anatomy "Open the proposal anatomy" "Anatomy")))))))

(v:defview anatomy-view (anatomy proposal-anatomy)
  (v:html-view :title "Anatomy" :priority 0
    (remember anatomy)
    (let* ((source (anatomy-source anatomy)) (item (anatomy-item anatomy)))
      (v:html
        (:h2 "Prepare edit proposal: the objects")
        (:p "Pressing " (:strong "Prepare edit proposal") " on Story Item E3 runs " (function-ref 'p:propose-item-edit)
            ". Everything below is computed from the page file as observed, in memory. Nothing is persisted, and the preview states "
            (:code "Executed: no.") " The example text is only an example: the content decision of E3 is open.")
        (:table :class "inspector-table"
          (:tr (:th "Part") (:th "Object") (:th "Made by") (:th "State"))
          (:tr (:td "1 Observed page revision") (:td (ref source (format nil "Page source ~A…" (subseq (lp:page-source-sha256 source) 0 8))))
               (:td (function-ref 'lp:observe-local-fedwiki-page-source)) (:td "read from the file; reads only"))
          (:tr (:td "2 Selected Story Item") (:td (ref item nil "Story item"))
               (:td (function-ref 'lp:source-story-items)) (:td "as part 1 observed it"))
          (:tr (:td "3 Edit proposal") (:td (ref (anatomy-proposal anatomy) nil "Edit proposal"))
               (:td (function-ref 'p:propose-item-edit)) (:td "in memory; the text is only the example"))
          (:tr (:td "4 Expected Item") (:td (ref (anatomy-expected anatomy) "the Item's exact current JSON"))
               (:td (function-ref 'p:preview-item-edit)) (:td "computed"))
          (:tr (:td "5 Replacement Item") (:td (ref (anatomy-replacement anatomy) "same id, other text"))
               (:td (function-ref 'p:proposal-replacement-item)) (:td "computed"))
          (:tr (:td "6 FedWiki edit Action") (:td (ref (anatomy-action anatomy) "the ordinary edit Action, without a date"))
               (:td (function-ref 'p:proposal-action)) (:td "computed; not executed"))
          (:tr (:td "7 Result of the page checks") (:td (ref (anatomy-next-page anatomy) "the page as the Action would leave it")
                                                         (v:esc (format nil " (Item index ~D)" (anatomy-index anatomy))))
               (:td (function-ref 'plan:plan-fedwiki-page-edit)) (:td "computed; the page file is untouched"))
          (:tr (:td "8 Preview") (:td (ref (anatomy-preview anatomy) nil "Preview"))
               (:td (function-ref 'p:preview-item-edit)) (:td "computed; Executed: no")))
        (:p "The page file's revision is " (:code (v:esc (lp:page-source-sha256 source))) ", the retained copy of the page; it is not the page on any server.")
        (:h3 "What is not here")
        (:p "An executed journal edit needs more than a preview. " (ref anatomy "What that is, and what exists" "Preview or edit?") ".")
        (links anatomy)))))

(v:defview preview-or-edit-view (anatomy proposal-anatomy)
  (v:html-view :title "Preview or edit?" :priority -1
    (remember anatomy)
    (let* ((preview-class (find-class 'p:item-edit-preview))
           (writer (writer-class))
           (preview-slots (slot-names preview-class))
           (action (anatomy-action anatomy))
           (trial (anatomy-trial anatomy)))
      (v:html
        (:h2 "A computed preview and a persisted edit")
        (:p "Both rest on the same page checks, " (function-ref 'plan:plan-fedwiki-page-edit)
            ". They differ in what they hold and do. The facts below are read from the classes and the source, not typed in.")
        (:table :class "inspector-table"
          (:tr (:th "") (:th "item-edit-preview") (:th "fedwiki-page-edit"))
          (:tr (:td "Class") (:td (ref preview-class "item-edit-preview"))
               (:td (if writer (ref writer "fedwiki-page-edit")
                        (v:html "not loaded in this image; defined at "
                                (:code (v:esc (format nil "dreyeck/src/fedwiki-page-authoring.lisp:~D" (source-line "dreyeck/src/fedwiki-page-authoring.lisp" "(defclass fedwiki-page-edit ()"))))))))
          (:tr (:td "Made by") (:td (function-ref 'p:preview-item-edit))
               (:td (:code "edit-fedwiki-page-item") " (writer); " (if writer "loaded here" "not loaded here")))
          (:tr (:td "Slots") (:td (v:esc (format nil "~{~(~A~)~^, ~}" preview-slots)))
               (:td (if writer (v:esc (format nil "~{~(~A~)~^, ~}" (slot-names writer))) (v:html "known only when the writer is loaded"))))
          (:tr (:td "Holds a capability") (:td (v:esc (if (find "CAPABILITY" preview-slots :key #'symbol-name :test #'string=) "yes" "no")))
               (:td (if writer (v:esc (if (find "CAPABILITY" (slot-names writer) :key #'symbol-name :test #'string=) "yes" "no")) (v:html "see the writer's source"))))
          (:tr (:td "Changes the page file") (:td "no: it reads the file again and plans")
               (:td "yes: it replaces one Item and appends the Action, then rereads the file and checks it"))
          (:tr (:td "Documentation") (:td (v:esc (or (documentation preview-class t) "")))
               (:td (if writer (v:esc (or (documentation writer t) "")) (v:html "see the writer's source")))))
        (:h3 "Who dates the journal entry?")
        (:p "The previewed Action holds no " (:code "date") " (checked now: "
            (v:esc (if (nth-value 1 (gethash "date" action)) "it does" "it does not")) "), and the writer appends exactly the Action it is given: "
            (:code (v:esc (format nil "dreyeck/src/fedwiki-page-authoring.lisp:~D" (source-line "dreyeck/src/fedwiki-page-authoring.lisp" "(%json-equal (car (last journal)) action)")))) ". "
            "Neither the preview nor the writer sets a date, so whoever executes must stamp it. That is open.")
        (:p "The persisted result exists only as a recorded trial: " (ref trial "see the trial" "Persisted trial") ".")
        (links anatomy)))))

(v:defview persisted-trial-view (trial persisted-trial)
  (v:html-view :title "Persisted trial" :priority 0
    (let* ((record (trial-record trial))
           (anatomy (gethash trial *anatomy-of*))
           (reading (and anatomy (c::subject-reading (or (anatomy-subject anatomy) (c::%subject (c:read-ctm-authoring) "ctm-wp-2")))))
           (reading (or reading (c:read-ctm-authoring))))
      (flet ((row (label value) (v:html (:tr (:td (v:esc label)) (:td (:code (v:esc (princ-to-string value))))))))
        (v:html
          (:h2 "A journal edit that was executed, on a temporary copy")
          (:p (:strong "Recorded, not performed here. ") "This Inspector computes previews. The trial below was executed by the test "
              (:code "dreyeck/fedwiki-item-edit-preview/tests: check-persisted-trial") ", which reproduces it each time it runs ("
              (:code (v:esc (format nil "dreyeck/tests/fedwiki-item-edit-preview.lisp:~D" (source-line "dreyeck/tests/fedwiki-item-edit-preview.lisp" "(defun check-persisted-trial"))))
              "). It used the existing writer with a capability made for a temporary copy: a test capability, not a production one. "
              "The wiki store of localhost:3000, dreyeck.ch and the retained evidence copy were not written.")
          (:table :class "inspector-table"
            (row "Revision before" (rj record "before" "pageSha256"))
            (row "Story Items / journal entries before" (format nil "~D / ~D" (rj record "before" "storyItems") (rj record "before" "journalEntries")))
            (row "Action" (format nil "~A of Item ~A (index ~D)" (rj record "action" "type") (rj record "action" "itemId") (rj record "action" "storyIndex")))
            (row "Replacement text (example only)" (rj record "action" "replacementText"))
            (row "Decision" (rj record "action" "decision"))
            (row "Story Items / journal entries after" (format nil "~D / ~D" (rj record "after" "storyItems") (rj record "after" "journalEntries")))
            (row "Story Items that changed" (format nil "~{~A~^, ~}" (coerce (rj record "after" "changedStoryItemIds") 'list)))
            (row "New journal entry" (format nil "type ~A, id ~A, item equals the replacement: ~A" (rj record "after" "newJournalEntry" "type")
                                              (rj record "after" "newJournalEntry" "id") (rj record "after" "newJournalEntry" "itemEqualsReplacement")))
            (row "Date of that entry" (rj record "after" "newJournalEntry" "date"))
            (row "Older entries unchanged" (rj record "after" "olderJournalEntriesUnchanged"))
            (row "Independent check" (rj record "independentVerification"))
            (row "Not recorded" (format nil "~{~A~^; ~}" (coerce (rj record "notRecorded") 'list))))
          (:p "The record file: " (ref (trial-path trial) "persisted-edit-trial.json") ". The page it was made on: "
              (if anatomy (ref (anatomy-source anatomy) "the retained page source") (v:html "the retained page")) ".")
          (:h3 "What an executed edit in production still lacks")
          (:p "Taken from the plan and its dictionary, not from this page:")
          (:ul
            (:li (ref (c::step-authorization (c::%subject reading "ctm-plan-p3")) "Authorization of the edit step (P3)") ": no grant exists.")
            (:li (ref (c::%subject reading "ctm-pre-authority") "Edit authority for the site and page") ": a precondition; its status is on the plan.")
            (:li (ref (c::%subject reading "ctm-pre-content") "The content decision for E3") ": a precondition; its status is on the plan.")
            (:li "A date for the journal entry: "
                 (if anatomy (ref anatomy "see Preview or edit?" "Preview or edit?") (v:html "see the preview and the writer")) "."))
          (when anatomy (links anatomy)))))))

(v:defview operation-or-topic-view (anatomy proposal-anatomy)
  (v:html-view :title "Operation or topic?" :priority -2
    (remember anatomy)
    (let ((subject (or (anatomy-subject anatomy) (c::%subject (c:read-ctm-authoring) "ctm-wp-2"))))
      (v:html
        (:h2 "Three things that are easily taken for one")
        (:table :class "inspector-table"
          (:tr (:th "Name") (:th "What it is") (:th "The object"))
          (:tr (:td (:strong "Prepare edit proposal"))
               (:td "an operation: the label of a button in the view " (:code "story-item-edit-offer") ", running " (:code "propose-item-edit"))
               (:td (function-ref 'p:propose-item-edit) " / " (ref (fdefinition 'p::story-item-edit-offer) "the view's generic function")))
          (:tr (:td (:strong "ctm-wp-2") " (Inspectable edit proposal)")
               (:td "a Work package declared on the plan page: what a proposal must be, its status and its controls")
               (:td (ref subject nil "WBS")))
          (:tr (:td (:strong "a TMDM Topic"))
               (:td "an information item of a Topic Map read from CTM; it has no status and does nothing")
               (:td (if (find-package "DREYECK/TOPIC-MAPS-READING")
                        (ref anatomy "TMDM example" "TMDM example")
                        (v:html "not loaded here; the TMDM example is the optional system dreyeck/topic-maps-reading")))))
        (:p "Story Item E3 is a paragraph on a wiki page. It is about how Associations are shown, and its text is an open decision. It is none of the three.")
        (links anatomy)))))
