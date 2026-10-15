;;;; Proposing one FedWiki Item edit and previewing it, without writing
(defpackage #:dreyeck/fedwiki-item-edit-preview
  (:use #:cl)
  (:local-nicknames (#:lp #:dreyeck/local-fedwiki-page)
                    (#:pa #:dreyeck/fedwiki-page-authoring)
                    (#:v #:html-inspector-views)
                    (#:hvr #:html-inspector-views/reactive))
  (:export #:item-edit-proposal #:propose-item-edit #:proposal-item #:proposal-text
           #:proposal-replacement-item #:proposal-action
           #:item-edit-preview #:preview-item-edit #:preview-proposal #:preview-source
           #:preview-expected-item #:preview-action #:preview-next-page #:preview-index
           #:stale-item-source #:stale-item-source-observed #:stale-item-source-current))
(in-package #:dreyeck/fedwiki-item-edit-preview)

;; An edit proposal names one story Item as one observation of its page saw
;; it, and the text proposed for it. A preview reads the page file again,
;; refuses unless it is still the observed revision, and asks the existing
;; page-authoring contract (PLAN-FEDWIKI-PAGE-EDIT) what the edit would leave.
;; Neither holds a capability and neither writes: performing the edit is
;; EDIT-FEDWIKI-PAGE-ITEM's, with a capability this system never makes.

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
  "The ordinary FedWiki edit Action for PROPOSAL. Its date is set when it is executed."
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
      (multiple-value-bind (next index) (pa:plan-fedwiki-page-edit (lp:page-source-json now) expected action)
        (make-instance 'item-edit-preview :proposal proposal :source now :expected-item expected
                                          :action action :next-page next :index index)))))

;;; Inspection

(defun %story (page) (coerce (or (gethash "story" page) (vector)) 'list))
(defun %journal (page) (coerce (or (gethash "journal" page) (vector)) 'list))
(defun %json (value) (shasht:write-json value nil))

(defmethod v:text-representation ((proposal item-edit-proposal))
  (format nil "Edit proposal for ~A" (lp:story-item-id (proposal-item proposal))))
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
                                              (handler-case (preview-item-edit proposal)
                                                (error (condition) condition))))))))
            (v:html
              (:p "This Item's text has more than one line, which a single-line input cannot hold. The proposed text is set in Lisp with (setf proposal-text).")
              (:p (v:eval-button "Preview" (v:thunk (handler-case (preview-item-edit proposal)
                                                      (error (condition) condition)))))))
        (:p (v:object-ref item :display "Return to the Item" :select "Story item"))))))

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
             (:li (v:esc (format nil "Journal: ~D entries become ~D; the new entry is this edit Action, dated when it is executed."
                                 (length (%journal before)) (length (%journal after)))))
             (:li "The page's new SHA-256 is known only after the write."))
        (:p (:strong "Executed: no.")
            " A preview holds no capability and writes nothing. Executing it needs a page-authoring capability for this site root, this page and the Action edit, which nothing here grants.")
        (:p (v:object-ref proposal :display "Return to the proposal" :select "Edit proposal"))))))
