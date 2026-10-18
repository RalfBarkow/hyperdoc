(defpackage #:dreyeck/dita-story-item/tests
  (:use #:cl)
  (:local-nicknames (#:lp #:dreyeck/local-fedwiki-page)
                    (#:d #:dreyeck/dita-story-item)
                    (#:p #:dreyeck/fedwiki-item-edit-preview)
                    (#:tm #:dreyeck/topicmap)
                    (#:tmdm #:topic-maps.tmdm)
                    (#:g #:dreyeck/gesture-binding-witness)
                    (#:m #:dreyeck/inspector/topicmap)
                    (#:v #:html-inspector-views)
                    (#:work #:dreyeck/work/reading))
  (:export #:run-tests))
(in-package #:dreyeck/dita-story-item/tests)

;; The four DITA topics on Topicmap inspection, as Story Items of the retained page topicmap-inspection-dita.
;; Checked here: the Items (id, type, information type), that the XML validates against the DITA 1.3 DTD, that the
;; Inspector reads them as a structured topic beside their source, that what the topics say about Operations
;; and results is what the code does, and that the Work Breakdown reaches the page and changes nothing else.

(defvar *checks* 0)
(defmacro check (form) `(progn (incf *checks*) (assert ,form () "check failed: ~S" ',form)))

(defun docs-root () (asdf:system-relative-pathname "dreyeck" "dreyeck/work/topicmap-inspection-docs/"))
(defparameter +item-ids+ '("4f1c7a92b3d85e01" "4f1c7a92b3d85e02" "4f1c7a92b3d85e03" "4f1c7a92b3d85e04"))
(defparameter +info-types+ '("concept" "concept" "reference" "task"))
(defparameter +names+ '("topicmap-signs-and-represented-objects" "tmdm-roles-and-projected-edges" "topicmap-gesture-operations" "inspect-a-topicmap-sign"))
(defparameter +slug+ "topicmap-inspection-dita")

(defun page-source () (lp:observe-local-fedwiki-page-source (merge-pathnames "site/" (docs-root)) +slug+))
(defun dita-items (source) (remove-if-not (lambda (item) (equal "dita" (lp:story-item-type item))) (lp:source-story-items source)))
(defun read-file (pathname) (uiop:read-file-string pathname :external-format :utf-8))

;;; 1. The Items

(defun check-items ()
  (let* ((source (page-source)) (items (lp:source-story-items source)) (dita (dita-items source)))
    (check (= 5 (length items)))
    (check (equal "paragraph" (lp:story-item-type (first items))))
    (check (equal +item-ids+ (mapcar #'lp:story-item-id dita)))
    (check (= (length items) (length (remove-duplicates (mapcar #'lp:story-item-id items) :test #'equal))))
    (loop for item in dita for info in +info-types+ for name in +names+
          do (let* ((json (lp:story-item-json item)) (xml (lp:story-item-text item)) (root (d:parse-dita-topic xml)))
               (check (typep item 'd:dita-story-item))
               (check (equal "1.3" (gethash "ditaVersion" json)))
               ;; The information type is stated, and it is the root element, which is the DOCTYPE's.
               (check (equal info (gethash "infoType" json)))
               (check (equal info (plump:tag-name root)))
               (check (equal name (plump:attribute root "id")))
               (check (search (format nil "<!DOCTYPE ~A PUBLIC \"-//OASIS//DTD DITA ~:(~A~)//EN\" \"~A.dtd\">" info info info) xml))
               (check (equal xml (read-file (merge-pathnames (format nil "dita/~A.dita" name) (docs-root)))))
               ))
    ;; find-story-item gives the same class: the id is the identity.
    (check (typep (lp:find-story-item source "4f1c7a92b3d85e03") 'd:dita-story-item))
    (check (not (typep (lp:find-story-item source "4f1c7a92b3d85e00") 'd:dita-story-item)))))

;;; 2. Validation against DITA 1.3

(defun dita-ot-libexec ()
  (or (let ((home (uiop:getenv "DITA_OT_HOME"))) (and home (plusp (length home)) (probe-file (uiop:ensure-directory-pathname home))))
      (first (sort (append (directory "/usr/local/Cellar/dita-ot/*/libexec/") (directory "/opt/homebrew/Cellar/dita-ot/*/libexec/"))
                   #'string> :key #'namestring))))

(defun java-available-p ()
  (ignore-errors (zerop (nth-value 2 (uiop:run-program '("java" "-version") :output :string :error-output :string :ignore-error-status t)))))

(defun validate-dita (texts)
  "Run the DTD validation on each text; the exit status and the output of the validator (stdout and stderr together)."
  (let* ((libexec (dita-ot-libexec))
         (directory (uiop:ensure-directory-pathname (merge-pathnames (format nil "dita-validation-~D-~D/" (sb-unix:unix-getpid) (random 1000000)) (uiop:temporary-directory))))
         (files (loop for text in texts for index from 0
                      collect (let ((file (merge-pathnames (format nil "item-~D.dita" index) directory)))
                                (ensure-directories-exist file)
                                (with-open-file (out file :direction :output :external-format :utf-8 :if-exists :supersede) (write-string text out))
                                (namestring file))))
         (lib (lambda (name) (namestring (merge-pathnames (format nil "lib/~A" name) libexec)))))
    (unwind-protect
         (multiple-value-bind (output error status)
             (uiop:run-program (append (list "java" "-cp" (format nil "~A:~A:~A" (funcall lib "xercesImpl-2.12.2.jar") (funcall lib "xml-apis-1.4.01.jar") (funcall lib "xml-resolver-1.2.jar"))
                                             (namestring (asdf:system-relative-pathname "dreyeck" "scripts/DitaValidate.java"))
                                             (namestring (merge-pathnames "catalog-dita.xml" libexec)))
                                       files)
                               :output :string :error-output :string :ignore-error-status t)
           (values status (format nil "~A~A" output error)))
      (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore))))

(defun check-validation ()
  (let ((texts (mapcar #'lp:story-item-text (dita-items (page-source)))))
    (cond
      ((not (and (dita-ot-libexec) (java-available-p)))
       (if (equal "1" (uiop:getenv "HYPERDOC_ALLOW_UNVALIDATED_DITA"))
           (format t "~&DITA-VALIDATION-SKIPPED: no DITA-OT and Java here; HYPERDOC_ALLOW_UNVALIDATED_DITA=1. The Items are NOT validated.~%")
           (error "DITA-OT 4.3.4 (DITA_OT_HOME) and Java are needed to validate the Items; set HYPERDOC_ALLOW_UNVALIDATED_DITA=1 to skip, which validates nothing.")))
      (t
       ;; Positive control: the validator accepts the four Items.
       (multiple-value-bind (status output) (validate-dita texts)
         (check (zerop status))
         (check (= 4 (count-substring ": valid" output))))
       ;; Negative control: the same validator refuses an element the DTD does not have, so that "valid" means something.
       (multiple-value-bind (status output) (validate-dita (list (replace-first (first texts) "<shortdesc>" "<shortdesc><bogus/>")))
         (check (not (zerop status)))
         (check (search "bogus" output)))
       ;; and refuses a topic with the wrong root for its DOCTYPE.
       (multiple-value-bind (status output) (validate-dita (list (replace-first (second texts) "<concept id=" "<task id=")))
         (declare (ignore output))
         (check (not (zerop status))))
       (format t "~&DITA-VALIDATION-PASS: four Items valid against the DITA 1.3 DTD (Xerces, ~A); a foreign element and a wrong root are refused.~%"
               (car (last (pathname-directory (dita-ot-libexec)) 2)))))))

(defun count-substring (needle haystack)
  (loop with start = 0 for at = (search needle haystack :start2 start) while at count t do (setf start (1+ at))))
(defun replace-first (string from to)
  (let ((at (search from string))) (assert at) (concatenate 'string (subseq string 0 at) to (subseq string (+ at (length from))))))

;;; 3. The Inspector's reading

(defun view-titled (object title) (find title (v:all-views object) :key #'v:view-title :test #'equal))

(defun check-reading ()
  (let ((source (page-source)))
    (dolist (item (dita-items source))
      (let ((structured (view-titled item "DITA topic")) (stored (view-titled item "Story item")))
        (check structured) (check stored)
        (let ((html (v:view-html structured)) (xml-view (v:view-html stored)))
          (check (search "<article" html))
          (check (null (search "&lt;!DOCTYPE" html)))          ; the structured reading is not the source
          (check (search "&lt;!DOCTYPE" xml-view))             ; the source view is
          (check (search (d:dita-topic-title (d:parse-dita-topic (lp:story-item-text item))) html))
          (check (null (d:dita-unsupported-elements (lp:story-item-text item))))
          (check (null (search "dita-unsupported" html)))
          (check (search (gethash "infoType" (lp:story-item-json item)) html)))))
    ;; The tab order puts the structured reading first and keeps the source as its own tab.
    (let ((titles (mapcar #'v:view-title (sort (copy-list (v:all-views (lp:find-story-item source "4f1c7a92b3d85e01"))) #'< :key #'v:view-priority))))
      (check (< (position "DITA topic" titles :test #'equal) (position "Story item" titles :test #'equal))))
    ;; An unknown element is shown by name and never dropped.
    (check (equal '("bogus") (d:dita-unsupported-elements "<concept id=\"x\"><title>t</title><conbody><p><bogus>y</bogus></p></conbody></concept>")))
    ;; The page's own Content reading renders the Item as a topic too, not as a block of text.
    (let* ((story (hyperbook/fedwiki::make-story (gethash "story" (lp:page-source-json source))))
           (html (v:html-and-references
                   (hyperbook/fedwiki::render-story-item :dita (find "4f1c7a92b3d85e03" story :key #'hyperbook/fedwiki::id-of :test #'equal) nil))))
      (check (search "<article" html))
      (check (search "DITA reference" html)))))

;;; 4. The references of the topics

(defun all-hrefs (item)
  (let ((root (d:parse-dita-topic (lp:story-item-text item))) (hrefs nil))
    (labels ((walk (node) (when (plump:element-p node)
                            (when (and (string= "xref" (plump:tag-name node)) (plump:attribute node "href")) (push (plump:attribute node "href") hrefs))
                            (map nil #'walk (plump:children node)))))
      (walk root))
    (nreverse hrefs)))

(defun local-example-item ()
  "The Item E3 of the retained plan page, read from the file; the Catalog is not needed for it."
  (let ((source (lp:observe-local-fedwiki-page-source (asdf:system-relative-pathname "dreyeck" "dreyeck/work/ctm-page-evidence/site/") "ctm-and-tmdm-in-hyperdoc")))
    (lp:find-story-item source "ed37e9bac2fcd548")))

(defun check-references ()
  (let* ((source (page-source)) (item-ids (mapcar #'lp:story-item-id (lp:source-story-items source)))
         (dreyeck/item-edit-ctm::*example-item* (local-example-item)))
    (dolist (item (dita-items source))
      (let ((context (lambda (id) (lp:find-story-item source id))))
        (dolist (href (all-hrefs item))
          (when (str:starts-with? "hyperdoc:" href)
            (let ((object (d:resolve-hyperdoc-reference href context)))
              ;; Every reference of every topic leads to an object of this image; none falls back to an explanation here.
              (check (not (stringp object)))
              (when (str:starts-with? "hyperdoc:item:" href)
                (check (member (subseq href (length "hyperdoc:item:")) item-ids :test #'equal))))))))
    ;; A reference to something this image does not have is an explanation, not a condition.
    (check (stringp (d:resolve-hyperdoc-reference "hyperdoc:class:dreyeck/no-such-package:thing")))
    (check (stringp (d:resolve-hyperdoc-reference "hyperdoc:example:no-such-example")))
    (check (stringp (d:resolve-hyperdoc-reference "hyperdoc:nothing:at-all")))
    (check (stringp (d:resolve-hyperdoc-reference "hyperdoc:item:ffff" (lambda (id) (lp:find-story-item source id)))))))

;;; 5. What the topics say is what the code does

(defun text-of-section (root title)
  (let ((section (find-if (lambda (node) (and (plump:element-p node) (string= "section" (plump:tag-name node))
                                              (let ((heading (find-if (lambda (c) (and (plump:element-p c) (string= "title" (plump:tag-name c)))) (plump:children node)))) (and heading (equal title (plump:text heading))))))
                          (plump:children (find-if #'plump:element-p (plump:children root))))))
    (assert section () "no section ~A" title)
    section))

(defun node-text (node) (plump:text node))

(defun check-reference-topic ()
  "The Binding ids, sectors and target types of the reference topic are those of the Binding catalogues in the source."
  (let* ((source (page-source)) (item (lp:find-story-item source "4f1c7a92b3d85e03"))
         (root (let ((r (d:parse-dita-topic (lp:story-item-text item)))) (find "refbody" (plump:children r) :key (lambda (c) (and (plump:element-p c) (plump:tag-name c))) :test #'equal)))
         (actual (append (coerce m::*workspace-action-sign-bindings* 'list) (coerce (symbol-value (find-symbol "*ASSOCIATION-ROLE-BINDINGS*" "DREYECK/INSPECTOR/TOPICMAP")) 'list)
                         (g:make-association-binding-catalog))))
    (check (= 8 (length actual)))
    (dolist (title '("Inspect Topicmap sign" "Inspect represented object" "Inspect relation contract"))
      (let* ((section (let ((found (find-if (lambda (c) (and (plump:element-p c) (string= "section" (plump:tag-name c))
                                                              (search title (node-text (find "title" (plump:children c) :key (lambda (x) (and (plump:element-p x) (plump:tag-name x))) :test #'equal)))))
                                            (plump:children root)))) (assert found () "no section ~A" title) found))
             (text (node-text section))
             (mine (remove title actual :key (lambda (b) (g::semantic-operation-identity-title (g::gesture-binding-operation b))) :test-not #'equal)))
        (check mine)
        ;; the Operation's identity as the code names it
        (check (search (g::semantic-operation-identity-id (g::gesture-binding-operation (first mine))) text))
        (dolist (binding mine)
          (check (search (g::gesture-binding-id binding) text))
          (check (search (string-downcase (format nil "~S" (g::gesture-binding-target-type binding))) text))
          (check (search (format nil "center ~D degrees" (round (g::gesture-binding-sector-center binding))) text))
          (check (search (format nil "half width ~D degrees" (round (g::gesture-binding-sector-half-width binding))) text)))
        ;; and no Binding id of another Operation is claimed here
        (dolist (other (set-difference actual mine))
          (unless (member (g::gesture-binding-id other) (mapcar #'g::gesture-binding-id mine) :test #'equal)
            (check (null (search (g::gesture-binding-id other) text)))))))))

(defun check-operations-on-the-example ()
  "The returned objects the reference topic and the concept topics name, on the real example."
  (let* ((dreyeck/item-edit-ctm::*example-item* (local-example-item))
         (chain (dreyeck/item-edit-ctm::%example-chain))
         (topic (getf chain :topic)) (association (getf chain :association)) (edge (getf chain :edge)) (role (getf chain :role)))
    (check (not (stringp chain)))
    ;; the projected Topic and the TMDM Association it represents: two objects, linked
    (check (typep topic 'dreyeck/item-edit-ctm:item-edit-topic))
    (check (typep association 'tmdm:association))
    (check (not (eq topic association)))
    (check (eq association (tm:topicmap-topic-object-of topic)))
    (check (equal "proposes(action=the-proposed-action,proposal=the-proposal)" (tm:topicmap-topic-id-of topic)))
    (check (equal "proposes" (dreyeck/item-edit-ctm::topic-key (tmdm:association-type association))))
    ;; Inspect Topicmap sign and Inspect represented object on a Topic sign
    (let* ((projection (dreyeck/item-edit-ctm::native-projection (getf chain :ctm)))
           (occurrence (make-instance 'm::workspace-action-sign-occurrence
                                      :reference (make-instance 'm::topic-action-reference :topic topic :projection projection :workspace nil :fn (lambda () nil))))
           (target (list :type :workspace-action-sign-occurrence :occurrence occurrence)))
      (check (eq topic (m::operation-inspectable-object (g:inspect-topicmap-sign-operation) target)))
      (check (eq association (m::operation-inspectable-object (g:inspect-represented-object-operation) target)))
      (check (equal '("operation/inspect-represented-object" "operation/inspect-topicmap-sign")
                    (sort (remove-duplicates (mapcar (lambda (b) (g::semantic-operation-identity-id (g::gesture-binding-operation b))) (m::workspace-action-sign-bindings occurrence)) :test #'equal) #'string<))))
    ;; a Role edge: the Role itself; only Inspect represented object is offered; Inspect relation contract is not applicable
    (let ((target (list :type :topicmap-association :association edge)))
      (check (eq role (m::operation-inspectable-object (g:inspect-represented-object-operation) target)))
      (check (typep role 'tmdm:association-role))
      (check (eq association (tmdm:association-role-parent role)))
      (check (equal "action" (dreyeck/item-edit-ctm::topic-key (tmdm:association-role-type role))))
      (check (equal "the-proposed-action" (dreyeck/item-edit-ctm::topic-key (tmdm:association-role-player role))))
      (check (equal '("operation/inspect-represented-object")
                    (remove-duplicates (mapcar (lambda (b) (g::semantic-operation-identity-id (g::gesture-binding-operation b))) (m::association-sign-bindings edge)) :test #'equal)))
      (check (handler-case (progn (m::operation-inspectable-object (g:inspect-relation-contract-operation) target) nil) (m::operation-not-applicable () t))))
    ;; the direction of the projected edge: from the Association node, to the player, whatever the Role type
    (check (equal (tm:topicmap-topic-id-of topic) (tm:topicmap-association-from-of edge)))
    (check (equal "the-proposed-action" (tm:topicmap-association-to-of edge)))
    (let ((other (find "proposes(action=the-proposed-action,proposal=the-proposal):proposal:the-proposal"
                       (tm:topicmap-projection-associations-of (dreyeck/item-edit-ctm::native-projection (getf chain :ctm)))
                       :key #'tm:topicmap-association-id-of :test #'equal)))
      (check (equal (tm:topicmap-topic-id-of topic) (tm:topicmap-association-from-of other))))
    ;; the Provenance of the example Association node says derived and where from
    (let ((statement (dreyeck/item-edit-ctm::topic-statement topic)))
      (check (equal "derived" (dreyeck/item-edit-ctm::class-word (dreyeck/item-edit-ctm::statement-class statement))))
      (check (search "PROPOSAL-ACTION" (dreyeck/item-edit-ctm::statement-source statement))))))

;;; 6. The Work Breakdown

(defun check-work-breakdown ()
  (let* ((file (asdf:system-relative-pathname "dreyeck" "dreyeck/pages/work/Work Breakdown.html"))
         (projection (work:project-work-breakdown file :source :dita-documentation-test))
         (topic (tm:topicmap-projection-topic-by-id projection "topicmap-interaction-documentation")))
    (check topic)
    (check (equal "work item" (getf (tm:topicmap-topic-view-properties-of topic) :kind)))
    (check (equal "open" (getf (tm:topicmap-topic-view-properties-of topic) :status)))
    ;; the Topic's object is the carrier page, which exists
    (check (eq (work:work-page "Topicmap Interaction Documentation") (tm:topicmap-topic-object-of topic)))
    ;; two plain relations, both existing words, from the existing areas
    (let ((mine (remove-if-not (lambda (a) (equal "topicmap-interaction-documentation" (tm:topicmap-association-to-of a))) (tm:topicmap-projection-associations-of projection))))
      (check (equal '(("dogfooding" "current-work") ("interaction" "contains"))
                    (sort (mapcar (lambda (a) (list (tm:topicmap-association-from-of a) (tm:topicmap-association-type-of a))) mine) #'string< :key #'first)))
      ;; no Relation Contract was made for them
      (check (every (lambda (a) (null (getf (tm:topicmap-association-properties-of a) :relation-contract))) mine)))
    (check (null (set-difference '("work:relation/informs" "work:relation/addresses") (mapcar #'tm:topicmap-topic-id-of (tm:topicmap-projection-topics-of projection)) :test-not #'equal)))
    ;; The plan of the CTM plan page is as it was: the item that edits one wiki Item is still there with its own relations, and the plan page does not mention the new item.
    (check (tm:topicmap-projection-topic-by-id projection "ctm-plan-page-authoring"))
    (let ((plan (uiop:read-file-string (asdf:system-relative-pathname "dreyeck" "dreyeck/pages/work/Authoring the CTM Plan Page.html") :external-format :utf-8))
          (dictionary (uiop:read-file-string (asdf:system-relative-pathname "dreyeck" "dreyeck/pages/work/CTM Plan Page WBS Dictionary.html") :external-format :utf-8)))
      (check (null (search "topicmap-interaction-documentation" plan)))
      (check (null (search "topicmap-inspection-dita" dictionary))))
    ;; the carrier page links the page and the four Items, and every page link of it names a page
    (let* ((source (uiop:read-file-string (asdf:system-relative-pathname "dreyeck" "dreyeck/pages/work/Topicmap Interaction Documentation.html") :external-format :utf-8)))
      (dolist (id +item-ids+) (check (search (format nil "\"topicmap-inspection-dita\" \"~A\"" id) source)))
      (check (search "(registered-page \"fedwiki:dreyeck.ch\" \"topicmap-inspection-dita\")" source)))))


;;; 7. The Catalog path: the page registered as a wiki, the Items and the example reached the way the Work pages reach them

(defun sha256-of-file (path) (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))

(defun check-catalog-path ()
  (let* ((root (uiop:ensure-directory-pathname (merge-pathnames (format nil "dita-doc-site-~D/" (random 1000000000)) (uiop:temporary-directory))))
         (plan (merge-pathnames "pages/ctm-and-tmdm-in-hyperdoc" root))
         (documentation-page (merge-pathnames (format nil "pages/~A" +slug+) root))
         (hyperbook::*catalog* (make-instance 'hyperbook:catalog))
         (helper-item (find-symbol "REGISTERED-STORY-ITEM" "DREYECK/WORK/CTM-PAGE-AUTHORING"))
         (helper-page (find-symbol "REGISTERED-PAGE" "DREYECK/WORK/CTM-PAGE-AUTHORING")))
    (ensure-directories-exist plan)
    (uiop:copy-file (asdf:system-relative-pathname "dreyeck" "dreyeck/work/ctm-page-evidence/site/pages/ctm-and-tmdm-in-hyperdoc") plan)
    (uiop:copy-file (merge-pathnames (format nil "site/pages/~A" +slug+) (docs-root)) documentation-page)
    (unwind-protect
         (let ((before (list (sha256-of-file plan) (sha256-of-file documentation-page))))
           (dreyeck/local-fedwiki-page:register-local-fedwiki root "fedwiki:dreyeck.ch")
           ;; The links of the carrier page resolve to the page and to the four Items, as DITA Story Items.
           (let ((page (funcall helper-page "fedwiki:dreyeck.ch" +slug+)))
             (check (not (stringp page)))
             (check (equal "Topicmap Inspection (DITA)" (hyperbook:title-of page))))
           (dolist (id +item-ids+)
             (let ((item (funcall helper-item "fedwiki:dreyeck.ch" +slug+ id)))
               (check (typep item 'd:dita-story-item))
               (check (equal id (lp:story-item-id item)))))
           ;; The example, reached through the Catalog and no seam: the Item E3 of the registered plan page.
           (let ((dreyeck/item-edit-ctm::*example-item* nil))
             (let ((topic (d:resolve-hyperdoc-reference "hyperdoc:example:proposes-topic")))
               (check (typep topic 'dreyeck/item-edit-ctm:item-edit-topic)))
             ;; One chain of objects for all the references of a document: the proposal is the same object each time.
             (check (eq (d:resolve-hyperdoc-reference "hyperdoc:example:proposal") (d:resolve-hyperdoc-reference "hyperdoc:example:proposal")))
             (check (eq (d:resolve-hyperdoc-reference "hyperdoc:example:proposes-association")
                        (tm:topicmap-topic-object-of (d:resolve-hyperdoc-reference "hyperdoc:example:proposes-topic")))))
           ;; Reading wrote nothing.
           (check (equal before (list (sha256-of-file plan) (sha256-of-file documentation-page)))))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))
    ;; Without a registered wiki the example is an explanation, not a condition.
    (let ((hyperbook::*catalog* (make-instance 'hyperbook:catalog)) (dreyeck/item-edit-ctm::*example-item* nil))
      (check (stringp (d:resolve-hyperdoc-reference "hyperdoc:example:proposes-topic"))))))

(defun run-tests ()
  (setf *checks* 0)
  (check-items)
  (check-validation)
  (check-reading)
  (check-references)
  (check-reference-topic)
  (check-operations-on-the-example)
  (check-work-breakdown)
  (check-catalog-path)
  (format t "~&DITA-STORY-ITEM-PASS: ~D checks. Four DITA 1.3 Story Items; read as topics beside their source; the references lead to objects; the reference topic and the example agree with the Binding catalogues and Operations; the Work Breakdown reaches the page.~%" *checks*)
  t)
