;;;; Proposing one FedWiki Item edit and previewing it, without writing
(defpackage #:dreyeck/fedwiki-item-edit-preview
  (:use #:cl)
  (:local-nicknames (#:lp #:dreyeck/local-fedwiki-page)
                    (#:plan #:dreyeck/fedwiki-page-edit-plan)
                    (#:v #:html-inspector-views)
                    (#:hvr #:html-inspector-views/reactive))
  (:export #:item-edit-proposal #:propose-item-edit #:proposal-item #:proposal-text
           #:proposal-replacement-item #:proposal-action
           #:item-edit-preview #:preview-item-edit #:preview-proposal #:preview-source
           #:preview-expected-item #:preview-action #:preview-next-page #:preview-index
           #:stale-item-source #:stale-item-source-observed #:stale-item-source-current
           #:interactive-preview #:unchanged-edit-preview #:unchanged-edit-proposal
           #:edit-conflict #:conflict-proposal #:conflict-condition
           #:persisted-trial #:trial-record #:trial-path #:read-trial-record))
(in-package #:dreyeck/fedwiki-item-edit-preview)

;; An edit proposal names one story Item as one observation of its page saw
;; it, and the text proposed for it. A preview reads the page file again,
;; refuses unless it is still the observed revision, and asks the existing
;; page-authoring contract (PLAN-FEDWIKI-PAGE-EDIT) what the edit would leave.
;; Neither holds a capability and neither writes: performing the edit is
;; EDIT-FEDWIKI-PAGE-ITEM's, in a system this one does not load.

(define-condition stale-item-source (error)
  ((observed :initarg :observed :reader stale-item-source-observed)
   (current :initarg :current :reader stale-item-source-current))
  (:report (lambda (condition stream)
             (format stream "The page file is no longer the observed revision ~A; it is now ~A. Observe the page again."
                     (lp:page-source-sha256 (stale-item-source-observed condition))
                     (lp:page-source-sha256 (stale-item-source-current condition)))))
  (:documentation "Nothing was planned and nothing was written."))

(defclass item-edit-proposal ()
  ((item :initarg :item :reader proposal-item)
   (text :initarg :text :accessor proposal-text))
  (:documentation "A proposed new text for one observed story Item. Making or
changing a proposal reads and writes nothing."))

(defun propose-item-edit (item &optional (text (lp:story-item-text item)))
  "A proposal for ITEM, a LOCAL-STORY-ITEM, starting from TEXT."
  (check-type item lp:local-story-item)
  (check-type text string)
  (make-instance 'item-edit-proposal :item item :text text))

(defun proposal-replacement-item (proposal)
  "The observed Item with the proposed text: same id, same type, same other fields."
  (let ((replacement (lp:story-item-json (proposal-item proposal))))
    (setf (gethash "text" replacement) (proposal-text proposal))
    replacement))

(defun proposal-action (proposal)
  "The ordinary FedWiki edit Action for PROPOSAL: type, id and item. It has no date: neither this function nor the writer sets one."
  (let ((action (make-hash-table :test #'equal))
        (replacement (proposal-replacement-item proposal)))
    (setf (gethash "type" action) "edit"
          (gethash "id" action) (gethash "id" replacement)
          (gethash "item" action) replacement)
    action))

(defclass item-edit-preview ()
  ((proposal :initarg :proposal :reader preview-proposal)
   (source :initarg :source :reader preview-source)
   (expected-item :initarg :expected-item :reader preview-expected-item)
   (action :initarg :action :reader preview-action)
   (next-page :initarg :next-page :reader preview-next-page)
   (index :initarg :index :reader preview-index))
  (:documentation "What one proposal would do to its page, as the page-authoring
contract plans it against the page file read again. A preview is not an edit."))

(defun preview-item-edit (proposal)
  "Read the proposal's page file again. Signal STALE-ITEM-SOURCE unless it is
still the observed revision, or FEDWIKI-PAGE-EDIT-REFUSED where the contract
refuses; otherwise return an ITEM-EDIT-PREVIEW. Writes nothing."
  (let* ((item (proposal-item proposal))
         (observed (lp:story-item-source item))
         (now (lp:observe-local-fedwiki-page-source (lp:page-source-site-root observed)
                                                    (lp:page-source-slug observed))))
    (unless (equal (lp:page-source-sha256 observed) (lp:page-source-sha256 now))
      (error 'stale-item-source :observed observed :current now))
    (let ((expected (lp:story-item-json item))
          (action (proposal-action proposal)))
      (multiple-value-bind (next index) (plan:plan-fedwiki-page-edit (lp:page-source-json now) expected action)
        (make-instance 'item-edit-preview :proposal proposal :source now :expected-item expected
                                          :action action :next-page next :index index)))))

;;; What the Inspector's Preview button shows

;; PREVIEW-ITEM-EDIT signals; whether a signalled condition is exceptional is the
;; caller's question. Interactively, "the text is unchanged" and "the page has
;; moved on" are ordinary outcomes of pressing Preview, so each becomes a small
;; result object with its own view. The conditions, the page-edit contract and the
;; writer are untouched, and the writer still refuses a no-change edit. Every other
;; condition is returned as before, so it stays recognisable and inspectable.

(defclass unchanged-edit-preview ()
  ((proposal :initarg :proposal :reader unchanged-edit-proposal))
  (:documentation "The proposed text equals the Item's current text: there is nothing to preview."))

(defclass edit-conflict ()
  ((proposal :initarg :proposal :reader conflict-proposal)
   (condition :initarg :condition :reader conflict-condition))
  (:documentation "The page file is no longer the revision the proposal was made against.
The proposal is kept as it was; nothing was planned or written."))

(defun interactive-preview (proposal)
  "What pressing Preview on PROPOSAL yields: an ITEM-EDIT-PREVIEW, an
UNCHANGED-EDIT-PREVIEW, an EDIT-CONFLICT, or, for any other condition, that condition."
  (handler-case (preview-item-edit proposal)
    (stale-item-source (condition)
      (make-instance 'edit-conflict :proposal proposal :condition condition))
    (plan:fedwiki-page-edit-refused (condition)
      (if (eq :no-change (plan:page-edit-refusal-reason condition))
          (make-instance 'unchanged-edit-preview :proposal proposal)
          condition))
    (error (condition) condition)))

;;; Inspection

(defun %story (page) (coerce (or (gethash "story" page) (vector)) 'list))
(defun %journal (page) (coerce (or (gethash "journal" page) (vector)) 'list))
(defun %json (value) (shasht:write-json value nil))

(defmethod v:text-representation ((proposal item-edit-proposal))
  (format nil "Edit proposal for ~A" (lp:story-item-id (proposal-item proposal))))
(defmethod v:text-representation ((result unchanged-edit-preview))
  (format nil "No change for ~A" (lp:story-item-id (proposal-item (unchanged-edit-proposal result)))))
(defmethod v:text-representation ((conflict edit-conflict))
  (format nil "Edit conflict for ~A" (lp:story-item-id (proposal-item (conflict-proposal conflict)))))
(defmethod v:text-representation ((preview item-edit-preview))
  (format nil "Preview of the edit of ~A" (lp:story-item-id (proposal-item (preview-proposal preview)))))

(v:defview story-item-edit-offer (item lp:local-story-item)
  (v:html-view :title "Edit" :priority 0
    (v:html
      (:p "Prepare a proposal for this Item. Preparing it and previewing it write nothing; executing it needs a page-authoring capability that this view does not hold.")
      (v:eval-button "Prepare edit proposal" (v:thunk (propose-item-edit item))))))

(v:defview item-edit-proposal-view (proposal item-edit-proposal)
  (v:html-view :title "Edit proposal" :priority -1
    (let* ((item (proposal-item proposal))
           (original (lp:story-item-text item))
           (single-line (not (find #\Newline original))))
      (v:html
        (:h2 (v:esc (format nil "Edit proposal for ~A" (lp:story-item-id item))))
        (:p "Original text, as observed at revision " (:code (v:esc (lp:page-source-sha256 (lp:story-item-source item)))) ":")
        (:pre (v:esc original))
        (if single-line
            (v:html
              (:p "Proposed text:")
              (let ((cell (hvr:input :initial-value (proposal-text proposal) :size "120")))
                (v:html
                  (:p (v:eval-button "Preview"
                                     (v:thunk (setf (proposal-text proposal) (lwcells:cell-ref cell))
                                              (interactive-preview proposal)))))))
            (v:html
              (:p "This Item's text has more than one line, which a single-line input cannot hold. The proposed text is set in Lisp with (setf proposal-text).")
              (:p (v:eval-button "Preview" (v:thunk (interactive-preview proposal))))))
        (:p (v:object-ref item :display "Return to the Item" :select "Story item"))))))

(v:defview unchanged-edit-preview-view (result unchanged-edit-preview)
  (v:html-view :title "No change" :priority 0
    (let* ((proposal (unchanged-edit-proposal result))
           (item (proposal-item proposal)))
      (v:html
        (:h2 (v:esc (format nil "No change for ~A" (lp:story-item-id item))))
        (:p "The proposed text equals the Item's text at revision "
            (:code (v:esc (lp:page-source-sha256 (lp:story-item-source item))))
            ". There is nothing to preview, and nothing was written.")
        (:p (v:object-ref proposal :display "Return to the proposal" :select "Edit proposal"))))))

(v:defview edit-conflict-view (conflict edit-conflict)
  (v:html-view :title "Conflict" :priority 0
    (let* ((proposal (conflict-proposal conflict))
           (condition (conflict-condition conflict))
           (observed (stale-item-source-observed condition))
           (current (stale-item-source-current condition))
           (item (proposal-item proposal)))
      (v:html
        (:h2 (v:esc (format nil "Edit conflict for ~A" (lp:story-item-id item))))
        (:p "The page file changed after this proposal was made. Nothing was previewed, planned or written, and nothing was replaced or rebased.")
        (:table :class "inspector-table"
          (:tr (:td "Page") (:td (:code (v:esc (lp:page-source-slug observed))) " in "
                                 (:code (v:esc (namestring (lp:page-source-site-root observed))))))
          (:tr (:td "Revision the proposal was made against") (:td (:code (v:esc (lp:page-source-sha256 observed)))))
          (:tr (:td "Revision of the page file now") (:td (:code (v:esc (lp:page-source-sha256 current))))))
        (:p "Your proposed text is kept:")
        (:pre (v:esc (proposal-text proposal)))
        (:p "To propose against the current revision, open the current page source and the Item again.")
        (:ul
          (:li (v:object-ref proposal :display "Return to the proposal" :select "Edit proposal"))
          (:li (v:object-ref observed :display "The page source the proposal was made against"))
          (:li (v:object-ref current :display "The page source now"))
          (:li (v:object-ref condition :display "Inspect the original condition")))))))

(v:defview item-edit-preview-view (preview item-edit-preview)
  (v:html-view :title "Preview" :priority -1
    (let* ((proposal (preview-proposal preview))
           (item (proposal-item proposal))
           (source (preview-source preview))
           (before (lp:page-source-json source))
           (after (preview-next-page preview))
           (replacement (gethash "item" (preview-action preview)))
           (old-story (%story before))
           (unchanged (loop for old in old-story for new in (%story after)
                            count (equal (%json old) (%json new)))))
      (v:html
        (:h2 (v:esc (format nil "Preview: edit of ~A" (lp:story-item-id item))))
        (:table :class "inspector-table"
          (:tr (:td "Page") (:td (:code (v:esc (lp:page-source-slug source))) " in "
                                 (:code (v:esc (namestring (lp:page-source-site-root source))))))
          (:tr (:td "Source revision") (:td (:code (v:esc (lp:page-source-sha256 source)))
                                         (v:esc ", read again for this preview and unchanged since the Item was observed")))
          (:tr (:td "Item id") (:td (:code (v:esc (lp:story-item-id item)))))
          (:tr (:td "Position") (:td (v:esc (format nil "~D of ~D, type ~A" (1+ (preview-index preview)) (length old-story)
                                                   (lp:story-item-type item))))))
        (:h3 "Original Item")
        (:pre (v:esc (%json (preview-expected-item preview))))
        (:h3 "Proposed Item")
        (:pre (v:esc (%json replacement)))
        (:h3 "Changed fields")
        (:table :class "inspector-table"
          (loop for field being the hash-keys of replacement using (hash-value value)
                unless (equal (%json value) (%json (gethash field (preview-expected-item preview))))
                  do (v:html (:tr (:td (:code (v:esc field)))
                                  (:td (:pre (v:esc (princ-to-string (gethash field (preview-expected-item preview))))))
                                  (:td "→")
                                  (:td (:pre (v:esc (princ-to-string value))))))))
        (:h3 "Expected effect")
        (:ul (:li (v:esc (format nil "Story: ~D Items; Item ~D is replaced; ~D Items stay byte-for-byte as they are."
                                 (length old-story) (1+ (preview-index preview)) unchanged)))
             (:li (v:esc (format nil "Journal: ~D entries become ~D; the new entry is "
                                 (length (%journal before)) (length (%journal after))))
                  (v:object-ref (preview-action preview) :display "this edit Action")
                  (v:esc ", which has no date field; neither the preview nor the writer sets one."))
             (:li "The page's new SHA-256 is known only after the write."))
        (:p (:strong "Executed: no.")
            " A preview holds no capability and writes nothing. Executing it needs a page-authoring capability for this site root, this page and the Action edit, which nothing here grants.")
        (:p (v:object-ref proposal :display "Return to the proposal" :select "Edit proposal"))))))

;;; The Edit Action as an object, and where it stands

;; The Action shown is PREVIEW-ACTION itself, the hash table the page checks were
;; given: nothing is built for the display, and rendering changes nothing. Which of
;; proposed, previewed and persisted holds is stated apart; the persisted edit that
;; exists is a recorded trial on a temporary copy, not an execution here. Who dates an
;; Action is not decided here: the view reports what the code and the sources say.

(defun %repo-file (relative) (asdf:system-relative-pathname "dreyeck/fedwiki-item-edit-preview" relative))
(defun %file-text (path) (uiop:read-file-string path :external-format :utf-8))
(defun %marker-line (path marker)
  "The line of PATH on which MARKER occurs exactly once; NIL if the file is not there; :AMBIGUOUS or :ABSENT otherwise."
  (and (probe-file path)
       (let* ((text (%file-text path)) (at (search marker text)))
         (cond ((null at) :absent)
               ((search marker text :start2 (1+ at)) :ambiguous)
               (t (1+ (count #\Newline text :end at)))))))
(defclass persisted-trial ()
  ((record :initarg :record :reader trial-record)
   (path :initarg :path :reader trial-path))
  (:documentation "A recorded trial of the existing writer on a temporary copy of the page.
It was recorded, not performed by this reading or by the Inspector."))

(defun read-trial-record ()
  (let ((path (%repo-file "dreyeck/work/ctm-page-evidence/persisted-edit-trial.json")))
    (make-instance 'persisted-trial :path path :record (shasht:read-json (%file-text path)))))
(defmethod v:text-representation ((trial persisted-trial)) "Recorded persisted edit trial")

;; Where FedWiki itself dates an Action: lines recorded from an installed FedWiki, in an evidence file that
;; names packages, versions and files relative to the package, and no machine path. They can be read
;; again where that installation is available: bind *FEDWIKI-NODE-MODULES* or set
;; HYPERDOC_FEDWIKI_NODE_MODULES to its node_modules directory. Otherwise they are shown as recorded.
(defvar *fedwiki-node-modules* nil
  "A directory holding wiki-client and wiki-server, or NIL; then HYPERDOC_FEDWIKI_NODE_MODULES is used.")

(defun read-dating-record ()
  (shasht:read-json (%file-text (%repo-file "dreyeck/work/ctm-page-evidence/fedwiki-action-dating.json"))))

(defun %reread-dating-source (source)
  "How the recorded SOURCE stands in the installation to be read again: :NOT-REREAD without one, otherwise
:SAME, (:LINE n), :OTHER-VERSION, :MARKER-ABSENT or :FILE-ABSENT."
  (let* ((given (or *fedwiki-node-modules* (let ((env (uiop:getenv "HYPERDOC_FEDWIKI_NODE_MODULES"))) (and env (plusp (length env)) env)))))
    (if (null given)
        :not-reread
        (let* ((root (uiop:ensure-directory-pathname given))
               (package (gethash "package" source))
               (file (merge-pathnames (format nil "~A/~A" package (gethash "file" source)) root))
               (manifest (merge-pathnames (format nil "~A/package.json" package) root))
               (line (%marker-line file (gethash "marker" source))))
          (cond ((null line) :file-absent)
                ((and (probe-file manifest)
                      (not (equal (gethash "version" source) (gethash "version" (shasht:read-json (%file-text manifest))))))
                 :other-version)
                ((eq line :absent) :marker-absent)
                ((eq line :ambiguous) :marker-absent)
                ((= line (gethash "line" source)) :same)
                (t (list :line line)))))))

(defmacro %row (label &rest content) `(v:html (:tr (:td (v:esc ,label)) (:td ,@content))))
(defun %code (value) (v:html (:code (v:esc (princ-to-string value)))))

(defun %function (designator) (if (functionp designator) designator (fdefinition designator)))
(defun %fref (designator &optional select label)
  (v:html (v:object-ref (%function designator) :display (or label (string-downcase (symbol-name designator))) :select select)))
(defun %writer-function ()
  (let ((package (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
    (let ((symbol (and package (find-symbol "EDIT-FEDWIKI-PAGE-ITEM" package))))
      (and symbol (fboundp symbol) (fdefinition symbol)))))
(defparameter +writer-file+ "dreyeck/src/fedwiki-page-authoring.lisp")
(defparameter +writer-package-file+ "dreyeck/src/fedwiki-page-authoring-package.lisp")

(v:defview item-edit-action-view (preview item-edit-preview)
  (v:html-view :title "Action context" :priority 0
    (let* ((proposal (preview-proposal preview))
           (item (proposal-item proposal))
           (action (preview-action preview))
           (expected (preview-expected-item preview))
           (replacement (gethash "item" action))
           (source (preview-source preview))
           (observed (lp:story-item-source item))
           (before (lp:page-source-json observed))
           (after (preview-next-page preview))
           (old-story (%story before))
           (unchanged (loop for old in old-story for new in (%story after) count (equal (%json old) (%json new))))
           (dated (nth-value 1 (gethash "date" action)))
           (plan-function (%function 'plan:plan-fedwiki-page-edit))
           (writer (%writer-function))
           (writer-line (%marker-line (%repo-file +writer-file+) "(defun edit-fedwiki-page-item"))
           (appends-line (%marker-line (%repo-file +writer-file+) "(%json-equal (car (last journal)) action)"))
           (shared-line (%marker-line (%repo-file +writer-package-file+) "#:%check-edit-action #:%plan-edit"))
           (trial (read-trial-record))
           (record (trial-record trial)))
      (flet ((rj (&rest keys) (let ((value record)) (dolist (key keys value) (setf value (gethash key value))))))
        (v:html
          (:h2 (v:esc (format nil "Edit Action for ~A" (lp:story-item-id item))))
          (:p "This is the preview's context for its Action. The Action is a plain hash table and does not know where it came from; this view says so, and the links lead to the objects themselves.")
          (:h3 "What the Action is")
          (:p "The ordinary FedWiki " (:code "edit") " Action " (:code "{type, id, item}") ": "
              (v:object-ref action :display "preview-action, a hash table")
              ". It is the object the page checks were given, not a copy made for this display.")
          (:p (:strong (v:esc (if dated "It has a date field." "It has no date field."))) " Checked now: "
              (:code (v:esc (format nil "(nth-value 1 (gethash \"date\" action)) => ~S" dated))) ".")
          (:h3 "Where it comes from")
          (:table :class "inspector-table"
            (%row "Story Item" (v:object-ref item :display "E3, as the observed page held it" :select "Story item") " in " (v:object-ref observed :display "the page source observed") ", " (v:object-ref before :display "its JSON, the original page state"))
            (%row "Edit proposal" (v:object-ref proposal :display "the proposal" :select "Edit proposal") ", made by " (%fref 'propose-item-edit))
            (%row "Expected Item" (v:object-ref expected :display "the Item's exact current JSON") ", a copy of the Item's JSON made by " (%fref 'preview-item-edit nil "preview-item-edit"))
            (%row "Replacement Item" (v:object-ref replacement :display "the Item the Action carries") ", made by " (%fref 'proposal-replacement-item))
            (%row "The Action" (v:object-ref action :display "type, id and this Item") ", made by " (%fref 'proposal-action)))
          (:h3 "How its effect was computed")
          (:p (%fref 'preview-item-edit) " read the page file again (" (v:object-ref source :display "the page source read again")
              (v:esc (if (equal (lp:page-source-sha256 source) (lp:page-source-sha256 observed)) ", the same revision" ", another revision"))
              ") and called " (%fref 'plan:plan-fedwiki-page-edit) " with the page, the expected Item and the Action. "
              (v:esc (if (typep plan-function 'generic-function) "It is a generic function." "It is an ordinary function, not a generic function."))
              " It returns the page the Action would leave and the Item's index, signals "
              (:code "fedwiki-page-edit-refused") " when a check fails, and reads and writes no file.")
          (:table :class "inspector-table"
            (%row "Computed page" (v:object-ref after :display "the page the Action would leave")
                  (v:esc (format nil " — Item ~D replaced, ~D Items unchanged" (1+ (preview-index preview)) unchanged)))
            (%row "Computed journal" (v:object-ref (gethash "journal" after) :display "the journal the Action would leave")
                  (v:esc (format nil " — ~D entries become ~D; the last is this Action" (length (%journal before)) (length (%journal (preview-next-page preview))))))
            (%row "Original journal" (v:object-ref (gethash "journal" before) :display "the journal as observed")))
          (:h3 "What an authorized execution would do")
          (:p (if writer
                  (v:html (:code "edit-fedwiki-page-item") " is loaded in this image: " (v:object-ref writer :display "the function") ". ")
                  (v:html (:code "edit-fedwiki-page-item") " is the writer's function. The writer is not loaded in this image, so there is no function object to open: its definition is "
                          (v:object-ref (%repo-file +writer-file+) :display (format nil "~A, line ~A" +writer-file+ writer-line)) ". "))
              "Given a page-authoring capability for the site root, the page and the Action " (:code "edit") ", it plans with the same page checks"
              (when (integerp shared-line) (v:html " (the writer imports " (:code "%plan-edit") " from the same package, " (:code (v:esc (format nil "~A:~A" +writer-package-file+ shared-line))) ")"))
              ", replaces Item " (:code (v:esc (lp:story-item-id item))) ", appends this Action exactly as it is to the journal, reads the file again and checks the result ("
              (:code (v:esc (format nil "~A:~A" +writer-file+ appends-line))) "). Nothing calls it here.")
          (:h3 "Computed, and executed")
          (:table :class "inspector-table"
            (%row "proposed" (:strong "yes") " — a text for one Item, in memory: " (v:object-ref proposal :display "the proposal" :select "Edit proposal"))
            (%row "previewed" (:strong "yes") " — computed against revision " (%code (lp:page-source-sha256 source)) ": " (v:object-ref preview :display "the preview" :select "Preview") ". " (:code "Executed: no."))
            (%row "persisted" (:strong "no") ", not by this Inspector. An edit Action of this kind was persisted once, in a recorded trial on a temporary copy, which is not an execution here: "
                  (v:object-ref trial :display "the recorded trial")))
          (:h3 "The date")
          (:p "The Action has no date, and nothing in this code adds one: " (%fref 'proposal-action) " builds " (:code "{type, id, item}")
              (when (integerp appends-line) (v:html ", and the writer appends the Action it is given (" (:code (v:esc (format nil "~A:~A" +writer-file+ appends-line))) ")"))
              ". What FedWiki itself does, as recorded from an installed FedWiki:")
          (:ul
            (dolist (source (coerce (gethash "sources" (read-dating-record)) 'list))
              (let ((status (%reread-dating-source source)))
                (v:html (:li (v:esc (gethash "role" source)) ": "
                             (:code (v:esc (format nil "~A ~A, ~A:~D" (gethash "package" source) (gethash "version" source)
                                                   (gethash "file" source) (gethash "line" source))))
                             " — " (:code (v:esc (gethash "marker" source))) ". "
                             (:em (v:esc (cond ((eq status :not-reread) "Recorded 2026-10-17; not read again here.")
                                               ((eq status :same) "Read again here: the same line.")
                                               ((eq status :file-absent) "Not found in the installation given; not checked.")
                                               ((eq status :other-version) "The installation given is another version; not checked.")
                                               ((eq status :marker-absent) "Read again here: the marker is not on that file.")
                                               (t (format nil "Read again here: now on line ~D." (second status))))))))))
            (:li "A journal entry without a date is not counted when FedWiki reads a page's last edit; a date is milliseconds since 1970."))
          (:p (:strong "Not decided here: ") "who dates an Action in HyperDoc, and when. This view reports; it adds no date and no policy.")
          (:h3 "The recorded trial")
          (:p (:strong "Recorded, not performed here. ") "The test " (:code (v:esc (rj "performedBy"))) " executed an equal Action with the existing writer on "
              "a temporary copy of the page, then a fresh process read the saved file and compared it with the proposal.")
          (:table :class "inspector-table"
            (%row "Revision before" (%code (rj "before" "pageSha256")))
            (%row "Items / journal entries" (v:esc (format nil "~D / ~D before, ~D / ~D after" (rj "before" "storyItems") (rj "before" "journalEntries")
                                                          (rj "after" "storyItems") (rj "after" "journalEntries"))))
            (%row "Changed Items" (v:esc (format nil "~{~A~^, ~}" (coerce (rj "after" "changedStoryItemIds") 'list))))
            (%row "New journal entry" (v:esc (format nil "type ~A, item equals the replacement: ~A" (rj "after" "newJournalEntry" "type") (rj "after" "newJournalEntry" "itemEqualsReplacement"))))
            (%row "Its date" (v:esc (rj "after" "newJournalEntry" "date")))
            (%row "Same Action as this one" (v:esc (if (equal (rj "action" "replacementText") (lp:story-item-text item)) "the proposal has the recorded text" "no: this proposal has another text; the recorded one was for the example text"))))
          (:p (v:object-ref trial :display "The recorded trial as an object") " / " (v:object-ref preview :display "Back to the preview" :select "Preview")
              " / " (v:object-ref proposal :display "the proposal" :select "Edit proposal")
              " / " (v:object-ref item :display "Story Item E3" :select "Story item")))))))
