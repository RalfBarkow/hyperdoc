(defpackage #:dreyeck/ctm-page-authoring-documentation/tests
  (:use #:cl)
  (:export #:run-tests))
(in-package #:dreyeck/ctm-page-authoring-documentation/tests)

;; The documentation says what the code is. Here the links it makes are followed: each expression behind a
;; link must evaluate in its page's package to an object, each link to a page must name a page that exists,
;; and the pages must reach one another. Identities and reachability are checked, not how many there are.

(defvar *checks* 0)
(defmacro check (form) `(progn (incf *checks*) (assert ,form)))

(defparameter +pages+ '("Item Edit Path in HyperDoc" "Authoring the CTM Plan Page" "CTM Plan Page WBS Dictionary" "Topicmap Interaction Documentation"))

(defun page-source (title)
  (uiop:read-file-string (asdf:system-relative-pathname "dreyeck/work/reading" (format nil "dreyeck/pages/work/~A.html" title))
                         :external-format :utf-8))

(defun unescape (string)
  (let ((string (ppcre-free-replace string "&quot;" "\"")))
    (ppcre-free-replace (ppcre-free-replace string "&lt;" "<") "&amp;" "&")))

(defun ppcre-free-replace (string from to)
  (with-output-to-string (out)
    (loop with start = 0
          for at = (search from string :start2 start)
          do (write-string string out :start start :end (or at (length string)))
             (if at (progn (write-string to out) (setf start (+ at (length from)))) (return)))))

(defun attribute-values (source attribute)
  "The values of ATTRIBUTE=\"...\" or ATTRIBUTE='...' in SOURCE."
  (let ((marker (format nil " ~A=" attribute)) (values nil) (start 0))
    (loop for at = (search marker source :start2 start)
          while at
          do (let* ((open (+ at (length marker))) (quote (char source open))
                    (close (position quote source :start (1+ open))))
               (push (unescape (subseq source (1+ open) close)) values)
               (setf start close)))
    (nreverse values)))

(defun page-package (source)
  (let* ((open (search "<in-package>" source)) (close (search "</in-package>" source)))
    (find-package (string-upcase (subseq source (+ open (length "<in-package>")) close)))))

(defun check-expressions (title)
  (let* ((source (page-source title)) (package (page-package source)))
    (check package)
    (dolist (text (attribute-values source "expr"))
      (let ((value (let ((*package* package)) (eval (read-from-string text)))))
        (check value)))))

(defun check-pages ()
  (let ((titles (mapcar (lambda (file) (subseq (file-namestring file) 0 (- (length (file-namestring file)) (length ".html"))))
                        (remove "html" (uiop:directory-files (asdf:system-relative-pathname "dreyeck/work/reading" "dreyeck/pages/work/"))
                                :key #'pathname-type :test-not #'equal))))
    (check (member "Item Edit Path in HyperDoc" titles :test #'equal))
    (dolist (title '("Item Edit Path in HyperDoc" "CTM Plan Page WBS Dictionary" "Topicmap Interaction Documentation"))
      (dolist (target (attribute-values (page-source title) "page"))
        (check (member target titles :test #'equal))))))

(defun check-reachability ()
  (let ((new "Item Edit Path in HyperDoc"))
    (dolist (from '("Authoring the CTM Plan Page" "Work Breakdown" "Deriving HyperDoc Authoring Constraints"))
      (check (member new (attribute-values (page-source from) "page") :test #'equal)))
    ;; and back to the pages it describes
    (check (member "Authoring the CTM Plan Page" (attribute-values (page-source new) "page") :test #'equal))
    (check (member "Work Breakdown" (attribute-values (page-source new) "page") :test #'equal))
    ;; the Work item that documents the Topicmap interaction is reached from the Work Breakdown and leads back to it
    (check (member "Topicmap Interaction Documentation" (attribute-values (page-source "Work Breakdown") "page") :test #'equal))
    (check (member "Work Breakdown" (attribute-values (page-source "Topicmap Interaction Documentation") "page") :test #'equal))))

(defun check-optional-objects ()
  ;; Where the system is loaded the link is the real object; where it is not, it is an explanation and no condition.
  (let ((optional (find-symbol "OPTIONAL-OBJECT" "DREYECK/WORK/CTM-PAGE-AUTHORING")))
    (check (typep (funcall optional :class "dreyeck/fedwiki-item-edit-execution" "item-edit-completion" "x") 'class))
    (check (functionp (funcall optional :function "dreyeck/fedwiki-item-edit-execution" "execute-completed-edit" "x")))
    (let ((absent (funcall optional :class "dreyeck/not-a-package" "something" "dreyeck/some-system")))
      (check (stringp absent))
      (check (search "dreyeck/some-system" absent))
      (check (not (typep absent 'condition))))
    ;; every optional link of the pages names a package that this system loads, so locally none falls back
    (dolist (title +pages+)
      (let ((source (page-source title)))
        (dolist (text (attribute-values source "expr"))
          (when (search "(optional-object" text)
            (check (not (stringp (let ((*package* (find-package "DREYECK/WORK/CTM-PAGE-AUTHORING"))) (eval (read-from-string text))))))))))))

(defun check-page-object-link ()
  ;; The page that is edited is linked as the HyperBook page object, not only named.
  (check (search "(registered-page \"fedwiki:dreyeck.ch\" \"ctm-and-tmdm-in-hyperdoc\")" (page-source "Authoring the CTM Plan Page")))
  ;; Without a registered wiki the link is an explanation, no condition and no wiki made by the lookup.
  (let ((registered (find-symbol "REGISTERED-PAGE" "DREYECK/WORK/CTM-PAGE-AUTHORING")) (before (length (hyperbook::hyperbooks-of hyperbook::*catalog*))))
    (check (stringp (funcall registered "fedwiki:no-such-wiki.example" "x")))
    (check (= before (length (hyperbook::hyperbooks-of hyperbook::*catalog*))))))

(defun sha256-of-file (path)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))

(defun call-with-registered-copy (function)
  "FUNCTION is called with the site root of a temporary copy of the retained page, registered as fedwiki:dreyeck.ch in a
catalog of its own."
  (let* ((root (uiop:ensure-directory-pathname (merge-pathnames (format nil "ctm-doc-site-~D/" (random 1000000000)) (uiop:temporary-directory))))
         (page (merge-pathnames "pages/ctm-and-tmdm-in-hyperdoc" root))
         (hyperbook::*catalog* (make-instance 'hyperbook:catalog)))
    (ensure-directories-exist page)
    (uiop:copy-file (asdf:system-relative-pathname "dreyeck/work/reading" "dreyeck/work/ctm-page-evidence/site/pages/ctm-and-tmdm-in-hyperdoc") page)
    (unwind-protect
         (progn (dreyeck/local-fedwiki-page:register-local-fedwiki root "fedwiki:dreyeck.ch")
                (funcall function root page))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(defun check-story-item-link ()
  (let ((resolve (find-symbol "REGISTERED-STORY-ITEM" "DREYECK/WORK/CTM-PAGE-AUTHORING"))
        (e3 "ed37e9bac2fcd548"))
    ;; The carrier page links E3 by wiki, page and Item id, and still links the whole page.
    (let ((source (page-source "Authoring the CTM Plan Page")))
      (check (search "(registered-story-item \"fedwiki:dreyeck.ch\" \"ctm-and-tmdm-in-hyperdoc\" \"ed37e9bac2fcd548\")'>E3</a>" source))
      (check (search "(registered-page \"fedwiki:dreyeck.ch\" \"ctm-and-tmdm-in-hyperdoc\")" source)))
    (call-with-registered-copy
     (lambda (root page)
       (let* ((before (sha256-of-file page)) (systems (asdf:already-loaded-systems))
              (books (length (hyperbook::hyperbooks-of hyperbook::*catalog*)))
              (item (funcall resolve "fedwiki:dreyeck.ch" "ctm-and-tmdm-in-hyperdoc" e3)))
         ;; Registered, Item present: the reader's own Item, whose id, position and origin are those of the file.
         (check (typep item 'dreyeck/local-fedwiki-page:local-story-item))
         (check (equal e3 (dreyeck/local-fedwiki-page:story-item-id item)))
         (check (= 10 (dreyeck/local-fedwiki-page:story-item-index item)))
         (check (equal before (dreyeck/local-fedwiki-page:page-source-sha256 (dreyeck/local-fedwiki-page:story-item-source item))))
         (check (equal "ctm-and-tmdm-in-hyperdoc" (dreyeck/local-fedwiki-page:page-source-slug (dreyeck/local-fedwiki-page:story-item-source item))))
         ;; The same Item as the Page source view's: each reading observes the file anew, so the objects are equal in id,
         ;; position and origin, not the same object. No cache makes them EQ.
         (let* ((wiki (hyperbook:find-hyperbook "fedwiki:dreyeck.ch"))
                (page-object (hyperbook:find-page wiki "ctm-and-tmdm-in-hyperdoc"))
                (via-source (find e3 (dreyeck/local-fedwiki-page:source-story-items (dreyeck/local-fedwiki-page:local-fedwiki-page-source-of page-object))
                                  :key #'dreyeck/local-fedwiki-page:story-item-id :test #'equal)))
           (check (= (dreyeck/local-fedwiki-page:story-item-index via-source) (dreyeck/local-fedwiki-page:story-item-index item)))
           (check (equalp (dreyeck/local-fedwiki-page:story-item-json via-source) (dreyeck/local-fedwiki-page:story-item-json item)))
           (check (equal (dreyeck/local-fedwiki-page:page-source-sha256 (dreyeck/local-fedwiki-page:story-item-source via-source))
                         (dreyeck/local-fedwiki-page:page-source-sha256 (dreyeck/local-fedwiki-page:story-item-source item)))))
         ;; Registered, id absent: an explanation, not a condition.
         (let ((absent (funcall resolve "fedwiki:dreyeck.ch" "ctm-and-tmdm-in-hyperdoc" "0000000000000000")))
           (check (stringp absent)) (check (search "0000000000000000" absent)))
         ;; Registered, page absent.
         (check (stringp (funcall resolve "fedwiki:dreyeck.ch" "no-such-page" e3)))
         ;; Not registered: an explanation, and no wiki is made by looking.
         (check (stringp (funcall resolve "fedwiki:other.example" "ctm-and-tmdm-in-hyperdoc" e3)))
         (check (= books (length (hyperbook::hyperbooks-of hyperbook::*catalog*))))
         ;; Reordering the story changes the position and not the identity.
         (let ((json (shasht:read-json (uiop:read-file-string page :external-format :utf-8))))
           (let* ((story (gethash "story" json)) (last (1- (length story))) (first-item (aref story 0)))
             (setf (aref story 0) (aref story last) (aref story last) first-item))
           (with-open-file (out page :direction :output :if-exists :supersede :external-format :utf-8) (shasht:write-json json out)))
         (let ((again (funcall resolve "fedwiki:dreyeck.ch" "ctm-and-tmdm-in-hyperdoc" e3)))
           (check (equal e3 (dreyeck/local-fedwiki-page:story-item-id again)))
           (check (equal (dreyeck/local-fedwiki-page:story-item-text item) (dreyeck/local-fedwiki-page:story-item-text again))))
         ;; Looking changed nothing: no system was loaded and the (reordered) file is as the test left it.
         (check (equal systems (asdf:already-loaded-systems)))
         (check (not (equal before (sha256-of-file page))))
         (check (probe-file root)))))))

(defun check-ctm-section ()
  ;; The completion's section names the CTM view and says what is observed, what is derived and that nothing is hypothetical.
  (let ((source (page-source "Item Edit Path in HyperDoc")))
    (dolist (text '("id=\"ctm-view\"" "CTM view of the completion" "Observed" "Derived" "No relation is hypothetical" "A completion is not an authorization"
                    "dreyeck/item-edit-ctm" "href=\"#ctm-view\"" "Lay out with TALA" "TALA (interactive)" "Marking menu" "Inspect represented object" "Inspect Topicmap sign" "synthetic pointer events" "why HyperDoc states it" "one edge for each Role"))
      (check (search text source)))))

(defun check-states-are-kept-apart ()
  ;; The implementation state names the six statements and does not let one stand for another.
  (let ((source (page-source "Authoring the CTM Plan Page")))
    (dolist (statement '("Integrated in source" "Locally executable" "Tested on temporary copies"
                         "Read in the local Inspector" "Served on dreyeck.ch" "Accepted"))
      (check (search statement source)))))

(defun run-tests ()
  (let ((*checks* 0))
    (dolist (title +pages+) (check-expressions title))
    (check-pages)
    (check-reachability)
    (check-optional-objects)
    (check-page-object-link)
    (check-story-item-link)
    (check-ctm-section)
    (check-states-are-kept-apart)
    (format t "~&CTM-PAGE-AUTHORING-DOCUMENTATION-PASS: ~D checks; every expression link of the three pages evaluates to an object in its package, every page link names a page, the new page is reachable from the Work item, the Item page and the derivation, and the six statements of the implementation state are named.~%" *checks*)
    t))
