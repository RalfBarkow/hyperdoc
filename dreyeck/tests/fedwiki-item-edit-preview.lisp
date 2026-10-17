(defpackage #:dreyeck/fedwiki-item-edit-preview/tests
  (:use #:cl)
  (:local-nicknames (#:p #:dreyeck/fedwiki-item-edit-preview)
                    (#:lp #:dreyeck/local-fedwiki-page)
                    (#:pa #:dreyeck/fedwiki-page-authoring)
                    (#:v #:html-inspector-views))
  (:export #:run-tests))
(in-package #:dreyeck/fedwiki-item-edit-preview/tests)

;; The page is the local observation retained beside the CTM plan page, copied
;; into temporary site roots. No test touches a real Wiki store.

(defparameter +slug+ "ctm-and-tmdm-in-hyperdoc")
(defparameter +observed-sha256+ "d7215c50f4efa07b3e94749b060b7d7b828654f2a44caab7f1034415c6003dff")
(defparameter +e3-id+ "ed37e9bac2fcd548")

(defun evidence-path ()
  (asdf:system-relative-pathname "dreyeck/fedwiki-item-edit-preview"
                                 "dreyeck/work/ctm-page-evidence/ctm-and-tmdm-in-hyperdoc.json"))
(defun file-sha256 (path) (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))
(defun page-path (root) (merge-pathnames (format nil "pages/~A" +slug+) root))
(defun state (root)
  "The page file's digest and write date, and every file in pages/: what a write would change."
  (list (file-sha256 (page-path root)) (file-write-date (page-path root))
        (mapcar #'namestring (directory (merge-pathnames "pages/*" root)))))

(defun call-with-site (function)
  (let ((root (merge-pathnames (format nil "item-edit-preview-~D-~D/" (get-universal-time) (random 1000000))
                               (uiop:temporary-directory))))
    (ensure-directories-exist (page-path root))
    (unwind-protect (progn (uiop:copy-file (evidence-path) (page-path root))
                           (funcall function root))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(defun rewrite (root mutate)
  "Change the page file in ROOT by MUTATE on its parsed JSON."
  (let ((json (shasht:read-json (uiop:read-file-string (page-path root) :external-format :utf-8))))
    (funcall mutate json)
    (with-open-file (out (page-path root) :direction :output :if-exists :supersede :external-format :utf-8)
      (shasht:write-json json out))))
(defun story-item-with (json id)
  (find id (gethash "story" json) :key (lambda (item) (gethash "id" item)) :test #'equal))

(defun view (object title)
  (let ((view (or (find title (v:all-views object) :key #'v:view-title :test #'equal)
                  (error "Missing ~A view of ~S" title object))))
    (v:view-html view)
    (assert (notany (lambda (ref) (typep (cdr ref) 'condition)) (v:view-references view)))
    view))
(defun refs (object title) (mapcar #'cdr (v:view-references (view object title))))
(defun refused (reason thunk)
  (let ((condition (handler-case (progn (funcall thunk) nil) (error (condition) condition))))
    (assert condition)
    (assert (if (keywordp reason)
                (and (typep condition 'pa:fedwiki-page-edit-refused) (eq reason (pa:page-edit-refusal-reason condition)))
                (typep condition reason)))
    condition))

(defun e3 (source) (find +e3-id+ (lp:source-story-items source) :key #'lp:story-item-id :test #'equal))

(defun check-identity-and-path (root)
  (let* ((before (state root))
         ;; Constructed, not registered: the Catalog stays as it was.
         (wiki (lp:make-local-fedwiki root (format nil "fedwiki:preview-~D" (random 1000000))))
         (page (lp:make-local-fedwiki-page root wiki +slug+))
         (source (lp:local-fedwiki-page-source-of page))
         (items (lp:source-story-items source))
         (item (e3 source)))
    ;; Source revision and Item identity, from one reading of the bytes.
    (assert (equal +observed-sha256+ (lp:page-source-sha256 source)))
    (assert (= 28101 (lp:page-source-octet-count source)))
    (assert (= 18 (length items)))
    (assert (= 1 (count +e3-id+ items :key #'lp:story-item-id :test #'equal)))
    (assert (= 18 (length (remove-duplicates (mapcar #'lp:story-item-id items) :test #'equal))))
    (assert (= 10 (lp:story-item-index item)))
    (assert (equal "paragraph" (lp:story-item-type item)))
    (assert (eql 0 (search "E3 — Darstellung:" (lp:story-item-text item))))
    ;; local-fedwiki-page → Story Item E3 → Edit Proposal → Preview, by the views' own references.
    (let ((listed (find +e3-id+ (refs page "Page source") :key (lambda (o) (and (typep o 'lp:local-story-item) (lp:story-item-id o)))
                        :test #'equal)))
      (assert listed)
      (assert (search +e3-id+ (v:view-html (view listed "Story item"))))
      (assert (search +observed-sha256+ (v:view-html (view listed "Story item"))))
      (view listed "Edit")
      (let* ((proposal (p:propose-item-edit listed))
             (proposal-html (v:view-html (view proposal "Edit proposal"))))
        (assert (search "Preview" proposal-html))
        (assert (search "Darstellung" proposal-html))
        (setf (p:proposal-text proposal)
              "E3 — Darstellung: Association-Knoten (im Bericht empfohlen). Decision: example text for the preview test only.")
        (let* ((preview (p:preview-item-edit proposal))
               (html (v:view-html (view preview "Preview"))))
          (dolist (text (list +e3-id+ +observed-sha256+ "Rollentyp-Topics" "example text for the preview test only"
                              "Item 11 is replaced; 17 Items stay" "Journal: 2 entries become 3" "Executed: no."))
            (assert (search text html)))
          ;; The planned page: exactly one Item and one journal entry differ.
          (let ((old (gethash "story" (lp:page-source-json source))) (new (gethash "story" (p:preview-next-page preview))))
            (assert (= 1 (count nil (map 'list (lambda (a b) (equal (shasht:write-json a nil) (shasht:write-json b nil))) old new))))
            (assert (equal (gethash "text" (aref new 10)) (p:proposal-text proposal)))
            (assert (equal +e3-id+ (gethash "id" (aref new 10)))))
          (assert (= 3 (length (gethash "journal" (p:preview-next-page preview)))))
          ;; The same contract as the writer: what it plans is what the writer would write.
          (check-plan-is-effect preview))))
    ;; Opening every view and previewing wrote nothing.
    (assert (equal before (state root)))))

(defun check-plan-is-effect (preview)
  "Apply the previewed Action with the existing writer to a second copy; compare."
  (call-with-site
   (lambda (other)
     (let* ((capability (pa:make-fedwiki-page-authoring-capability other (list +slug+)))
            (action (p:proposal-action (p:preview-proposal preview))))
       (pa:edit-fedwiki-page-item capability +slug+ (p:preview-expected-item preview) action)
       (let ((written (shasht:read-json (uiop:read-file-string (page-path other) :external-format :utf-8))))
         (assert (equal (shasht:write-json (gethash "story" (p:preview-next-page preview)) nil)
                        (shasht:write-json (gethash "story" written) nil)))
         (assert (equal (shasht:write-json (gethash "journal" (p:preview-next-page preview)) nil)
                        (shasht:write-json (gethash "journal" written) nil))))))))

(defun check-refusals (root)
  (let* ((source (lp:observe-local-fedwiki-page-source root +slug+))
         (proposal (p:propose-item-edit (e3 source) "E3 — changed for the stale test."))
         (unchanged (p:propose-item-edit (e3 source))))
    ;; Positive control: the untouched file previews.
    (assert (typep (p:preview-item-edit proposal) 'p:item-edit-preview))
    ;; The contract refuses a replacement equal to the current Item.
    (refused :no-change (lambda () (p:preview-item-edit unchanged)))
    ;; Another Item changes: the source revision is no longer the observed one.
    (let ((before (state root)))
      (rewrite root (lambda (json) (setf (gethash "text" (story-item-with json "fa6304a65d40144c")) "E2 changed elsewhere.")))
      (assert (not (equal before (state root)))))
    (refused 'p:stale-item-source (lambda () (p:preview-item-edit proposal)))
    ;; Observed again, the same proposal text previews against the new revision.
    (let ((again (lp:observe-local-fedwiki-page-source root +slug+)))
      (assert (not (equal (lp:page-source-sha256 source) (lp:page-source-sha256 again))))
      (assert (typep (p:preview-item-edit (p:propose-item-edit (e3 again) (p:proposal-text proposal))) 'p:item-edit-preview))
      ;; The Item itself changes: refused as stale as well, nothing planned.
      (rewrite root (lambda (json) (setf (gethash "text" (story-item-with json +e3-id+)) "E3 changed by someone else.")))
      ;; The revision check comes first, so the contract's own :STALE is not
      ;; reached through a preview; it remains the writer's guard at execution.
      (refused 'p:stale-item-source (lambda () (p:preview-item-edit (p:propose-item-edit (e3 again) "mine")))))))

(defun item-of (source id)
  (find id (lp:source-story-items source) :key #'lp:story-item-id :test #'equal))
(defun preview-button (proposal)
  "The thunk of the Preview button, taken from the Edit proposal view's own references."
  (let ((thunks (remove-if-not (lambda (object) (typep object 'v:thunk)) (refs proposal "Edit proposal"))))
    (assert (= 1 (length thunks)))
    (first thunks)))
(defun press-preview (proposal) (v:eval-thunk (preview-button proposal)))
(defun raw-view (object title)
  (let ((view (or (find title (v:all-views object) :key #'v:view-title :test #'equal) (error "Missing ~A view of ~S" title object))))
    (v:view-html view)
    view))
(defun no-backtrace (object &optional allowed)
  "OBJECT is an ordinary result: not a condition, no view of it shows a backtrace, and the only
condition a view refers to is ALLOWED, offered as a link and not opened."
  (assert (not (typep object 'condition)))
  (dolist (view (v:all-views object))
    (when (typep view 'v::html-view)
      (let ((html (v:view-html view)))
        (assert (not (search "Backtrace" html)))
        (assert (every (lambda (ref) (or (not (typep (cdr ref) 'condition)) (eq allowed (cdr ref))))
                       (v:view-references view))))))
  object)

(defparameter +multi-line-id+ "174e5462ccd2815f")

(defun check-interactive-outcomes (root)
  (let* ((source (lp:observe-local-fedwiki-page-source root +slug+))
         (multi (item-of source +multi-line-id+)))
    (assert (find #\Newline (lp:story-item-text multi)))
    ;; Unchanged text, both Preview buttons: a plain result, never a condition.
    (dolist (item (list (e3 source) multi))
      (let* ((before (state root))
             (proposal (p:propose-item-edit item))
             (result (press-preview proposal)))
        (assert (typep result 'p:unchanged-edit-preview))
        (assert (eq proposal (p:unchanged-edit-proposal result)))
        (no-backtrace result)
        (let ((html (v:view-html (view result "No change"))))
          (assert (search "nothing was written" html))
          (assert (search +observed-sha256+ html)))
        (assert (member proposal (refs result "No change") :test #'eq))
        ;; Positive control: without the interactive handling the same press is the refusal, a condition.
        (assert (typep (handler-case (p:preview-item-edit proposal) (error (condition) condition))
                       'pa:fedwiki-page-edit-refused))
        (assert (equal before (state root)))))
    ;; Changed text, both buttons: the regular preview, unchanged by this slice.
    (dolist (item (list (e3 source) multi))
      (let* ((before (state root))
             (proposal (p:propose-item-edit item (concatenate 'string (lp:story-item-text item) " (changed)")))
             (result (press-preview proposal)))
        (assert (typep result 'p:item-edit-preview))
        (no-backtrace result)
        (assert (search "Executed: no." (v:view-html (view result "Preview"))))
        (assert (equal before (state root)))))
    ;; Another contract violation stays a recognisable refusal. Since the revision is checked first, a
    ;; proposal made through the Inspector cannot reach one, so the Action is made malformed by an
    ;; encapsulation that exists only for this call.
    (let ((proposal (p:propose-item-edit (e3 source) "changed")))
      (sb-int:encapsulate 'p:proposal-action 'malformed-for-test
                          (lambda (function proposal)
                            (let ((action (funcall function proposal)))
                              (setf (gethash "type" action) "add")
                              action)))
      (unwind-protect
           (let ((result (press-preview proposal)))
             (assert (typep result 'condition))
             (assert (typep result 'pa:fedwiki-page-edit-refused))
             (assert (eq :malformed (pa:page-edit-refusal-reason result))))
        (sb-int:unencapsulate 'p:proposal-action 'malformed-for-test))
      ;; Positive control: without the encapsulation the same proposal previews.
      (assert (typep (press-preview proposal) 'p:item-edit-preview)))
    ;; A page file that is gone is an unexpected error: returned as the condition, not hidden.
    (call-with-site
     (lambda (other)
       (let* ((observed (lp:observe-local-fedwiki-page-source other +slug+))
              (proposal (p:propose-item-edit (e3 observed) "changed")))
         (delete-file (page-path other))
         (let ((result (press-preview proposal)))
           (assert (typep result 'error))
           (assert (not (typep result 'p:stale-item-source)))
           (assert (not (typep result 'pa:fedwiki-page-edit-refused)))))))
    ;; A conflict, both buttons: understandable, the proposal kept, nothing rebased, nothing written.
    (dolist (item (list (e3 source) multi))
      (call-with-site
       (lambda (other)
         (let* ((observed (lp:observe-local-fedwiki-page-source other +slug+))
                (item (item-of observed (lp:story-item-id item)))
                (text (concatenate 'string (lp:story-item-text item) " (my edit)"))
                (proposal (p:propose-item-edit item text)))
           (preview-button proposal)    ; the view is rendered against the observed revision
           (rewrite other (lambda (json) (setf (gethash "text" (story-item-with json "fa6304a65d40144c")) "E2 changed elsewhere.")))
           (let* ((moved (state other))
                  (current-sha (first moved))
                  (result (press-preview proposal)))
             (assert (typep result 'p:edit-conflict))
             (assert (not (typep result 'condition)))
             (no-backtrace result (p:conflict-condition result))
             (assert (typep (p:conflict-condition result) 'p:stale-item-source))
             (assert (eq proposal (p:conflict-proposal result)))
             (assert (equal text (p:proposal-text proposal)))
             (assert (eq item (p:proposal-item proposal)))
             (let ((html (v:view-html (raw-view result "Conflict"))))
               (dolist (expected (list +observed-sha256+ current-sha " (my edit)" "nothing was replaced or rebased"))
                 (assert (search expected html))))
             (assert (not (equal +observed-sha256+ current-sha)))
             (let ((references (mapcar #'cdr (v:view-references (raw-view result "Conflict")))))
               (assert (member proposal references :test #'eq))
               (assert (member (lp:story-item-source item) references :test #'eq))
               (assert (member (p:conflict-condition result) references :test #'eq))
               (assert (find current-sha references :test #'equal
                             :key (lambda (o) (and (typep o 'lp:local-fedwiki-page-source) (lp:page-source-sha256 o))))))
             ;; The page file was not touched by the press, nor by any view of the result.
             (assert (equal moved (state other))))))))))

;;; A persisted edit, apart from a computed one

;; The Inspector's preview computes. This trial executes the same proposal with the
;; existing writer on a temporary copy, then lets a fresh process, which loads only
;; SHASHT and IRONCLAD, compare the saved file with the proposal. The facts that do not
;; depend on the execution date are those recorded in persisted-edit-trial.json, which
;; the HyperDoc reading of the proposal shows as a recorded trial.

(defun trial-record-path ()
  (asdf:system-relative-pathname "dreyeck/fedwiki-item-edit-preview"
                                 "dreyeck/work/ctm-page-evidence/persisted-edit-trial.json"))
(defun read-json-file (path) (shasht:read-json (uiop:read-file-string path :external-format :utf-8)))
(defun rj (object &rest keys)
  (dolist (key keys object) (setf object (gethash key object))))
(defun text-sha256 (text)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence :sha256 (babel:string-to-octets text :encoding :utf-8))))

(defparameter +fresh-verifier+ "
(require :asdf)
(asdf:load-system \"shasht\")
(asdf:load-system \"ironclad\")
(defun jequal (a b)
  (cond ((and (hash-table-p a) (hash-table-p b))
         (and (= (hash-table-count a) (hash-table-count b))
              (loop for k being the hash-keys of a using (hash-value v)
                    always (multiple-value-bind (w present) (gethash k b) (and present (jequal v w))))))
        ((and (vectorp a) (vectorp b) (not (stringp a)) (not (stringp b)))
         (and (= (length a) (length b)) (every #'jequal a b)))
        (t (equal a b))))
(defun without-date (entry)
  (let ((copy (make-hash-table :test 'equal)))
    (maphash (lambda (k v) (unless (equal k \"date\") (setf (gethash k copy) v))) entry) copy))
(defun read-json-file (path) (shasht:read-json (uiop:read-file-string path :external-format :utf-8)))
(let* ((saved (read-json-file ~S))
       (proposal (read-json-file ~S))
       (original (gethash \"originalPage\" proposal))
       (replacement (gethash \"replacement\" proposal))
       (id (gethash \"id\" replacement))
       (story (gethash \"story\" saved)) (old-story (gethash \"story\" original))
       (journal (gethash \"journal\" saved)) (old-journal (gethash \"journal\" original))
       (entry (aref journal (1- (length journal)))))
  (format t \"~~&FRESH-EDIT-VERIFIED ~~S~~%\"
          (list :sha256 (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 ~S))
                :story-items (length story) :journal-entries (length journal)
                :changed-ids (loop for new across story for old across old-story
                                   unless (jequal new old) collect (gethash \"id\" new))
                :same-ids (equal (map 'list (lambda (i) (gethash \"id\" i)) story)
                                 (map 'list (lambda (i) (gethash \"id\" i)) old-story))
                :replacement-in-place (jequal replacement (find id story :key (lambda (i) (gethash \"id\" i)) :test #'equal))
                :older-journal-unchanged (jequal (subseq journal 0 (length old-journal)) old-journal)
                :new-entry-type (gethash \"type\" entry) :new-entry-id (gethash \"id\" entry)
                :new-entry-item-equals-replacement (jequal (gethash \"item\" entry) replacement)
                :new-entry-equals-action-but-date (jequal (without-date entry) (gethash \"action\" proposal))
                :new-entry-has-date (integerp (gethash \"date\" entry))
                :other-top-level-equal (every (lambda (k) (jequal (gethash k saved) (gethash k original)))
                                              (remove-if (lambda (k) (member k '(\"story\" \"journal\") :test #'equal))
                                                         (loop for k being the hash-keys of original collect k))))))
")

(defun fresh-verification (saved-path proposal-path)
  "The facts a new SBCL reads from SAVED-PATH, compared there with the proposal in PROPOSAL-PATH."
  (let ((script (merge-pathnames "verify.lisp" (uiop:pathname-directory-pathname proposal-path)))
        (program (or (uiop:argv0) (first sb-ext:*posix-argv*))))
    (with-open-file (out script :direction :output :if-exists :supersede :external-format :utf-8)
      (format out +fresh-verifier+ (namestring saved-path) (namestring proposal-path) (namestring saved-path)))
    (multiple-value-bind (output error-output status)
        (uiop:run-program (list program "--noinform" "--non-interactive" "--load" (namestring script))
                          :output :string :error-output :output :ignore-error-status t)
      (declare (ignore error-output))
      (let ((at (search "FRESH-EDIT-VERIFIED " output)))
        (unless (and (zerop status) at) (error "The fresh verifier failed (status ~S):~%~A" status output))
        (let ((*read-eval* nil) (*package* (find-package "COMMON-LISP-USER")))
          (read-from-string output t nil :start (+ at (length "FRESH-EDIT-VERIFIED "))))))))

(defun inline-ref (view text)
  "The object the link whose text is TEXT refers to, found through the id in the view's own html."
  (let* ((html (v:view-html view)) (at (search (format nil ">~A</span>" text) html)))
    (assert at)
    (let* ((id-at (search "id='" html :end2 at :from-end t)) (start (+ id-at 4)) (end (position #\' html :start start)))
      (cdr (assoc (subseq html start end) (v:view-references view) :test #'equal)))))

(defun check-edit-action-view (root)
  "The Edit Action view shows PREVIEW-ACTION itself, with the writer loaded or not, and writes nothing."
  (let* ((source (lp:observe-local-fedwiki-page-source root +slug+))
         (before (state root))
         (proposal (p:propose-item-edit (e3 source) "E3 — Edit Action view test text."))
         (preview (press-preview proposal))
         (action (p:preview-action preview))
         (copy (shasht:write-json action nil)))
    (assert (typep preview 'p:item-edit-preview))
    (assert (eq action (inline-ref (view preview "Preview") "this edit Action")))
    (assert (not (search "The Action itself" (v:view-html (view preview "Preview")))))
    (let ((table (refs preview "Action context")) (text (v:view-html (view preview "Action context"))))
      (dolist (object (list action (p:preview-expected-item preview) (gethash "item" action) (p:preview-source preview)
                            (lp:story-item-source (p:proposal-item proposal))
                            (lp:page-source-json (lp:story-item-source (p:proposal-item proposal))) (p:preview-next-page preview)
                            (gethash "journal" (p:preview-next-page preview)) proposal preview))
        (assert (member object table :test #'eq)))
      (assert (every (lambda (state) (search state text)) '("proposed" "previewed" "persisted" "no date field")))
      (assert (search "not by this Inspector" text))
      ;; The writer is loaded here, so the function that would persist the Action is the object itself.
      (assert (member (fdefinition 'pa:edit-fedwiki-page-item) table :test #'eq))
      (assert (search "is loaded in this image" text))
      (assert (not (typep (fdefinition 'pa:edit-fedwiki-page-item) 'generic-function)))
      (dolist (symbol '(p:proposal-action pa:plan-fedwiki-page-edit p:preview-item-edit))
        (assert (member (fdefinition symbol) table :test #'eq)))
      ;; No registration of objects to previews exists: the Action's pane has no view of that kind.
      (assert (null (find-symbol "*PREVIEW-CONTEXT*" "DREYECK/FEDWIKI-ITEM-EDIT-PREVIEW")))
      (assert (null (find "Where this comes from" (v:all-views action) :key #'v:view-title :test #'equal))))
    ;; The same object each time, unchanged, and no file touched, although the writer is loaded here.
    (assert (eq action (p:preview-action preview)))
    (assert (equal copy (shasht:write-json action nil)))
    (assert (null (nth-value 1 (gethash "date" action))))
    (assert (equal before (state root)))))

(defun check-persisted-trial (root)
  (let* ((record (read-json-file (trial-record-path)))
         (text (rj record "action" "replacementText"))
         (source (lp:observe-local-fedwiki-page-source root +slug+))
         (item (e3 source))
         (proposal (p:propose-item-edit item text))
         (work (merge-pathnames "trial/" (uiop:pathname-directory-pathname root)))
         (proposal-path (merge-pathnames "proposal.json" work)))
    (ensure-directories-exist proposal-path)
    ;; The record names what it must: the text, the revision and the counts as observed now.
    (assert (equal (rj record "action" "replacementTextSha256") (text-sha256 text)))
    (assert (and (equal (rj record "before" "pageSha256") (lp:page-source-sha256 source)) (equal +observed-sha256+ (lp:page-source-sha256 source))))
    (assert (= (rj record "before" "storyItems") (length (lp:source-story-items source)) 18))
    (assert (= (rj record "before" "journalEntries") (length (gethash "journal" (lp:page-source-json source))) 2))
    (assert (= (rj record "action" "storyIndex") (lp:story-item-index item)))
    (assert (equal (rj record "action" "itemId") (lp:story-item-id item)))
    ;; Computed: the preview. It wrote nothing.
    (let* ((before (state root))
           (preview (p:preview-item-edit proposal)))
      (assert (equal before (state root)))
      (assert (= 3 (length (gethash "journal" (p:preview-next-page preview)))))
      ;; The proposal, set down in a file outside the site for the fresh process.
      (let ((document (make-hash-table :test 'equal)))
        (setf (gethash "originalPage" document) (lp:page-source-json source)
              (gethash "replacement" document) (gethash "item" (p:preview-action preview))
              (gethash "expected" document) (p:preview-expected-item preview)
              (gethash "action" document) (p:preview-action preview))
        (with-open-file (out proposal-path :direction :output :if-exists :supersede :external-format :utf-8)
          (shasht:write-json document out)))
      ;; Executed: one authorized Action, with a capability made for this temporary copy only.
      ;; Neither the previewed Action nor the writer dates an Action: the Action holds no
      ;; "date", and the writer appends exactly the Action it is given. The executing caller
      ;; stamps it, here with the time of execution in milliseconds.
      (assert (null (nth-value 1 (gethash "date" (p:preview-action preview)))))
      (let* ((capability (pa:make-fedwiki-page-authoring-capability root (list +slug+)))
             (action (let ((copy (make-hash-table :test 'equal)))
                       (maphash (lambda (key value) (setf (gethash key copy) value)) (p:preview-action preview))
                       (setf (gethash "date" copy) (* 1000 (- (get-universal-time) (encode-universal-time 0 0 0 1 1 1970 0))))
                       copy))
             (edit (pa:edit-fedwiki-page-item capability +slug+ (p:preview-expected-item preview) action)))
        (assert (typep edit 'pa:fedwiki-page-edit))
        (assert (equal +e3-id+ (pa:page-edit-item-id edit)))
        (assert (eql (gethash "date" action) (gethash "date" (pa:page-edit-action edit)))))
      (assert (not (equal before (state root))))
      ;; Independent: a fresh process reads the saved file and compares it with the proposal.
      (let ((facts (fresh-verification (page-path root) proposal-path)))
        (assert (equal (coerce (rj record "after" "changedStoryItemIds") 'list) (getf facts :changed-ids)))
        (assert (= (rj record "after" "storyItems") (getf facts :story-items)))
        (assert (= (rj record "after" "journalEntries") (getf facts :journal-entries)))
        (assert (getf facts :same-ids))
        (assert (getf facts :replacement-in-place))
        (assert (eq (rj record "after" "olderJournalEntriesUnchanged") (and (getf facts :older-journal-unchanged) t)))
        (assert (equal (rj record "after" "newJournalEntry" "type") (getf facts :new-entry-type)))
        (assert (equal (rj record "after" "newJournalEntry" "id") (getf facts :new-entry-id)))
        (assert (eq (rj record "after" "newJournalEntry" "itemEqualsReplacement") (and (getf facts :new-entry-item-equals-replacement) t)))
        (assert (getf facts :new-entry-equals-action-but-date))
        (assert (getf facts :new-entry-has-date))
        (assert (getf facts :other-top-level-equal))
        (assert (equal (file-sha256 (page-path root)) (getf facts :sha256)))
        (assert (not (equal +observed-sha256+ (getf facts :sha256))))
        ;; Positive control: the verifier does notice a file that differs from the proposal.
        (let ((tampered (merge-pathnames "tampered" work)))
          (uiop:copy-file (page-path root) tampered)
          (rewrite-file tampered (lambda (json) (setf (gethash "text" (story-item-with json +e3-id+)) "tampered")))
          (let ((bad (fresh-verification tampered proposal-path)))
            (assert (not (getf bad :replacement-in-place)))
            (assert (equal '("ed37e9bac2fcd548") (getf bad :changed-ids)))
            (assert (getf bad :new-entry-item-equals-replacement))))))
    (assert (equal +observed-sha256+ (file-sha256 (evidence-path))))))

(defun rewrite-file (path mutate)
  (let ((json (read-json-file path)))
    (funcall mutate json)
    (with-open-file (out path :direction :output :if-exists :supersede :external-format :utf-8)
      (shasht:write-json json out))))

(defun system-closure (name)
  "NAME and every system it depends on, as declared, by name."
  (let ((seen nil))
    (labels ((visit (designator)
               (let ((system (and (or (stringp designator) (symbolp designator))
                                  (asdf:find-system designator nil))))
                 (when (and system (not (member (asdf:component-name system) seen :test #'string=)))
                   (push (asdf:component-name system) seen)
                   (mapc #'visit (asdf:system-depends-on system))))))
      (visit name))
    seen))

(defun check-load-contract ()
  "Activating the preview loads the page checks, never the writer."
  (let ((closure (system-closure "dreyeck/fedwiki-item-edit-preview")))
    (assert (member "dreyeck/fedwiki-page-edit-plan" closure :test #'string=))
    (assert (not (member "dreyeck/fedwiki-page-authoring" closure :test #'string=)))
    ;; Positive control: the same walk does find the writer where it is declared.
    (assert (member "dreyeck/fedwiki-page-authoring" (system-closure "dreyeck/authenticated-page-authoring")
                    :test #'string=))))

(defun run-tests ()
  (assert (equal +observed-sha256+ (file-sha256 (evidence-path))))
  (check-load-contract)
  (let ((books (copy-list (hyperbook:hyperbooks-of hyperbook:*catalog*))))
    (unwind-protect (run-checks)
      (assert (equal books (hyperbook:hyperbooks-of hyperbook:*catalog*)))))
  t)

(defun run-checks ()
  (call-with-site #'check-identity-and-path)
  (call-with-site #'check-refusals)
  (call-with-site #'check-interactive-outcomes)
  (call-with-site #'check-edit-action-view)
  (call-with-site #'check-persisted-trial)
  (format t "~&FEDWIKI-ITEM-EDIT-PREVIEW-PASS: one reading gives revision ~A and 18 unique Item ids; E3 ~A is paragraph 11; local-fedwiki-page → Story item → Edit proposal → Preview by view references; the preview shows original, id, proposal and effect and equals what the writer writes; no file changed while previewing; no-change and a stale revision (another Item, E3 itself) refused; the preview's declared load closure holds the page checks and not the writer; both Preview buttons answer an unchanged text with No change and a moved page with a Conflict that keeps the proposal, and any other condition stays a condition.~%"
          +observed-sha256+ +e3-id+)
  t)
