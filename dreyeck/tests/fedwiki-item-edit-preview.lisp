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

(defun run-tests ()
  (assert (equal +observed-sha256+ (file-sha256 (evidence-path))))
  (let ((books (length (hyperbook:hyperbooks-of hyperbook:*catalog*))))
    (unwind-protect (run-checks)
      (assert (= books (length (hyperbook:hyperbooks-of hyperbook:*catalog*))))))
  t)

(defun run-checks ()
  (call-with-site #'check-identity-and-path)
  (call-with-site #'check-refusals)
  (format t "~&FEDWIKI-ITEM-EDIT-PREVIEW-PASS: one reading gives revision ~A and 18 unique Item ids; E3 ~A is paragraph 11; local-fedwiki-page → Story item → Edit proposal → Preview by view references; the preview shows original, id, proposal and effect and equals what the writer writes; no file changed while previewing; no-change and a stale revision (another Item, E3 itself) refused.~%"
          +observed-sha256+ +e3-id+)
  t)
