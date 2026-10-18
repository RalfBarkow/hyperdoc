;;;; CTM views for the Item edit path
(defpackage #:dreyeck/item-edit-ctm
  (:use #:cl)
  (:local-nicknames (#:p #:dreyeck/fedwiki-item-edit-preview)
                    (#:x #:dreyeck/fedwiki-item-edit-execution)
                    (#:lp #:dreyeck/local-fedwiki-page)
                    (#:tr #:dreyeck/topic-maps-reading)
                    (#:tmdm #:topic-maps.tmdm)
                    (#:ctm #:topic-maps.ctm)
                    (#:tm #:dreyeck/topicmap)
                    (#:native #:dreyeck/inspector/topicmap)
                    (#:tala #:dreyeck/topicmap/tala)
                    (#:v #:html-inspector-views))
  (:export #:project-item-edit #:current-projection #:item-edit-ctm #:item-edit-ctm-refused #:item-edit-topic #:ctm-workspace #:tala-layout
           #:ctm-origin #:ctm-stage #:ctm-text #:ctm-map #:ctm-document-iri #:ctm-sha256
           #:ctm-topics #:ctm-statements #:ctm-binding #:ctm-topic-of))
(in-package #:dreyeck/item-edit-ctm)

;; A completed, previewed or proposed Item edit, written as CTM and read back with the topic-maps reader.
;; The Lisp objects stay the source: the CTM text is derived from them every time a projection is made, is not stored,
;; and carries no more than the objects show. Each Topic keeps the Lisp object it stands for in BINDINGS, which belong
;; to this one projection; there is no registry from TMDM objects to Lisp objects.
;;
;; What is stated, and how it is known (the scope of each Association, and the class of each Occurrence):
;;   observed  read from a slot of the Lisp object as it is now
;;   derived   computed here from the objects: an equality check, or an Action that PROPOSAL-ACTION makes now
;; Nothing is hypothetical in this projection: no relation is stated that no object shows.
;;
;; Limits of the reader that the text keeps to: Topics with names and Occurrences, typed with isa, and Associations
;; with Roles and a Scope. It uses no template, no include and no datatype suffix; an integer is written bare.
;; The text holds no Item text, only ids, digests and the date, so no escaping of user text is needed beyond quotes.

(define-condition item-edit-ctm-refused (error)
  ((reason :initarg :reason :reader item-edit-ctm-refusal-reason))
  (:report (lambda (condition stream) (format stream "No CTM projection: ~A" (item-edit-ctm-refusal-reason condition)))))
(defun refuse (control &rest arguments)
  (error 'item-edit-ctm-refused :reason (apply #'format nil control arguments)))

(defclass topic-spec ()
  ((id :initarg :id :reader spec-id)
   (type :initarg :type :reader spec-type)
   (name :initarg :name :reader spec-name)
   (occurrences :initarg :occurrences :initform nil :reader spec-occurrences)
   (object :initarg :object :reader spec-object)
   (class :initarg :class :reader spec-class)
   (source :initarg :source :reader spec-source))
  (:documentation "One Topic of the projection: its id, type, name, Occurrences (TYPE VALUE CLASS SOURCE), the Lisp object it stands for."))

(defclass statement ()
  ((type :initarg :type :reader statement-type)
   (roles :initarg :roles :reader statement-roles)
   (class :initarg :class :reader statement-class)
   (source :initarg :source :reader statement-source))
  (:documentation "One Association of the projection: its type, Roles ((ROLE-TYPE TOPIC-ID)...), its class and where it comes from."))

(defclass item-edit-ctm ()
  ((origin :initarg :origin :reader ctm-origin)
   (stage :initarg :stage :reader ctm-stage)
   (topics :initarg :topics :reader ctm-topics)
   (statements :initarg :statements :reader ctm-statements)
   (document-iri :initarg :document-iri :reader ctm-document-iri)
   (text :initarg :text :reader ctm-text)
   (sha256 :initarg :sha256 :reader ctm-sha256)
   (map :initarg :map :reader ctm-map)
   (native :initform nil :accessor %native)
   (workspace :initform nil :accessor %workspace))
  (:documentation "The CTM text derived from ORIGIN, an ITEM-EDIT-COMPLETION, ITEM-EDIT-PREVIEW or ITEM-EDIT-PROPOSAL, and the TMDM
Topic Map the topic-maps reader makes of it. STAGE says which of the three it was made from."))

(defmethod v:text-representation ((c item-edit-ctm))
  (format nil "CTM of the ~(~A~) of ~A" (ctm-stage c) (ctm-item-id c)))

(defun ctm-binding (c topic-id) (let ((spec (find topic-id (ctm-topics c) :key #'spec-id :test #'equal))) (and spec (spec-object spec))))
(defun ctm-topic-of (c topic-id)
  "The TMDM Topic of C whose item identifier is the id TOPIC-ID in C's document."
  (let ((identifier (format nil "~A#~A" (ctm-document-iri c) topic-id)))
    (find-if (lambda (topic) (member identifier (tmdm:topic-item-identifiers topic) :test #'equal)) (tmdm:topic-map-topics (ctm-map c)))))
(defun ctm-item-id (c) (spec-text-occurrence (find "the-expected-item" (ctm-topics c) :key #'spec-id :test #'equal) "item-id"))
(defun spec-text-occurrence (spec type)
  (second (find type (spec-occurrences spec) :key #'first :test #'equal)))

;;; The objects of one projection

(defun %json-equal (a b) (x:json-equal a b))
(defun %hex-sha256 (string) (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets string :external-format :utf-8))))

(defun %chain (object)
  "The stage and the proposal, preview and completion OBJECT leads back to."
  (etypecase object
    (x:item-edit-completion (let ((preview (x:completion-preview object))) (values :completion (p:preview-proposal preview) preview object)))
    (p:item-edit-preview (values :preview (p:preview-proposal object) object nil))
    (p:item-edit-proposal (values :proposal object nil nil))))

(defun %decoded-body (completion)
  (shasht:read-json (sb-ext:octets-to-string (x:completion-body completion) :external-format :utf-8)))

(defun project-item-edit (object)
  "The CTM projection of OBJECT, an ITEM-EDIT-COMPLETION, ITEM-EDIT-PREVIEW or ITEM-EDIT-PROPOSAL, read back as a TMDM Topic Map.
Reads OBJECT and its page source as they are held; changes nothing and writes nothing."
  (multiple-value-bind (stage proposal preview completion) (%chain object)
    (let* ((item (p:proposal-item proposal))
           (source (lp:story-item-source item))
           (item-id (lp:story-item-id item))
           (slug (lp:page-source-slug source))
           (revision (lp:page-source-sha256 (if preview (p:preview-source preview) source)))
           ;; The Action: the preview's own, or, before a preview, the one the proposal makes now.
           (proposed (if preview (p:preview-action preview) (p:proposal-action proposal)))
           (expected (if preview (p:preview-expected-item preview) (lp:story-item-json item)))
           (action-source (if preview "the Action of the preview, PREVIEW-ACTION"
                              "the Action PROPOSAL-ACTION makes from the proposal now; the proposal holds none"))
           (topics nil) (statements nil))
      (unless (equal item-id (gethash "id" proposed)) (refuse "the proposed Action names ~A, not ~A" (gethash "id" proposed) item-id))
      (labels ((topic (id type name object class source occurrences)
                 (push (make-instance 'topic-spec :id id :type type :name name :object object :class class :source source
                                                  :occurrences occurrences)
                       topics))
               (state (type roles class source)
                 (push (make-instance 'statement :type type :roles roles :class class :source source) statements)))
        (topic "the-proposal" "item-edit-proposal" (format nil "Item edit proposal for ~A" item-id) proposal :observed "the proposal object"
               `(("item-id" ,item-id :observed "LOCAL-STORY-ITEM of the proposal")
                 ("page-slug" ,slug :observed "the page source of the item")))
        (topic "the-expected-item" "story-item" (format nil "Story Item ~A as observed" item-id) expected :observed
               (if preview "PREVIEW-EXPECTED-ITEM" "the Item JSON as the page source observed it")
               `(("item-id" ,item-id :observed "the id in the Item JSON")
                 ("page-slug" ,slug :observed "the page source")
                 ("item-type" ,(gethash "type" expected) :observed "the type in the Item JSON")
                 ("source-sha256" ,revision :observed ,(if preview "the revision the preview read" "the revision the Item was observed in"))))
        (topic "the-proposed-action" "edit-action" (format nil "Edit Action proposed for ~A, without a date" item-id) proposed
               (if preview :observed :derived) action-source
               `(("action-type" ,(gethash "type" proposed) ,(if preview :observed :derived) "the type of the Action")
                 ("item-id" ,item-id ,(if preview :observed :derived) "the id of the Action")))
        (when (nth-value 1 (gethash "date" proposed)) (refuse "the proposed Action has a date"))
        (state "proposes" '(("proposal" "the-proposal") ("action" "the-proposed-action")) :derived
               (if preview "a preview made from this proposal holds the Action; PROPOSAL-ACTION makes the same Action from the proposal"
                   "PROPOSAL-ACTION makes the Action from the proposal"))
        (when preview
          (unless (eq proposal (p:preview-proposal preview)) (refuse "the preview belongs to another proposal"))
          (topic "the-preview" "item-edit-preview" (format nil "Preview of the edit of ~A" item-id) preview :observed "the preview object"
                 `(("source-sha256" ,revision :observed "PREVIEW-SOURCE, the page file read again when the preview was made")))
          (state "previews" '(("preview" "the-preview") ("action" "the-proposed-action")) :observed "PREVIEW-ACTION"))
        (when completion
          (let* ((completed (x:completion-action completion)) (date (x:completion-date completion))
                 (body (%decoded-body completion)))
            (unless (eq preview (x:completion-preview completion)) (refuse "the completion belongs to another preview"))
            (unless (and (integerp date) (eql date (gethash "date" completed)))
              (refuse "the completion's date ~S is not the date of its Action ~S" date (gethash "date" completed)))
            (when (eq completed proposed) (refuse "the completed Action is the proposed Action"))
            (let ((undated (let ((copy (make-hash-table :test #'equal)))
                             (maphash (lambda (key value) (unless (equal key "date") (setf (gethash key copy) value))) completed) copy)))
              (unless (%json-equal undated proposed) (refuse "the completed Action differs from the proposed one by more than the date")))
            (unless (and (%json-equal (gethash "expected" body) expected) (%json-equal (gethash "action" body) completed))
              (refuse "the body to be signed is not {expected, action} of these objects"))
            (topic "the-completion" "item-edit-completion" (format nil "Completion of the edit of ~A" item-id) completion :observed
                   "the completion object"
                   `(("request-attached" ,(if (x:completion-request completion) "yes" "no") :observed "COMPLETION-REQUEST")
                     ("scope-of-statement" "A completion is not an authorization. This projection shows no execution and no persistence."
                      :derived "stated by the projection: what these objects do not show")))
            (topic "the-completed-action" "edit-action" (format nil "Edit Action completed for ~A, with a date" item-id) completed :observed
                   "COMPLETION-ACTION"
                   `(("action-type" ,(gethash "type" completed) :observed "the type of the Action")
                     ("item-id" ,item-id :observed "the id of the Action")
                     ("date" ,date :observed "COMPLETION-DATE, milliseconds since 1970-01-01 UTC")))
            (topic "the-signed-body" "signed-body" (format nil "Body to be signed for ~A" item-id) (x:completion-body completion) :observed
                   "COMPLETION-BODY, the octets of {expected, action}"
                   `(("body-digest" ,(x:completion-body-keccak-256 completion) :observed "COMPLETION-BODY-KECCAK-256")
                     ("body-octets" ,(length (x:completion-body completion)) :observed "the length of COMPLETION-BODY")))
            (state "completes" '(("completion" "the-completion") ("preview" "the-preview")) :observed "COMPLETION-PREVIEW")
            (state "yields" '(("completion" "the-completion") ("action" "the-completed-action")) :observed "COMPLETION-ACTION")
            (state "has-body" '(("completion" "the-completion") ("body" "the-signed-body")) :observed "COMPLETION-BODY")
            (state "completed-from" '(("completed" "the-completed-action") ("original" "the-proposed-action")) :derived
                   "compared here: the two Actions are different objects and equal in every field but the date")
            (state "contains" '(("body" "the-signed-body") ("content" "the-expected-item")) :derived
                   "the body read back as JSON: its expected equals PREVIEW-EXPECTED-ITEM")
            (state "contains" '(("body" "the-signed-body") ("content" "the-completed-action")) :derived
                   "the body read back as JSON: its action equals COMPLETION-ACTION"))))
      (let* ((topics (nreverse topics)) (statements (nreverse statements))
             (iri (format nil "https://hyperdoc.invalid/item-edit/~A/~(~A~)" item-id stage))
             (text (%ctm-text object stage topics statements))
             (map (ctm:deserialize-string text :document-iri iri :source-name (format nil "item-edit-~(~A~)" stage))))
        (make-instance 'item-edit-ctm :origin object :stage stage :topics topics :statements statements :document-iri iri
                                      :text text :sha256 (%hex-sha256 text) :map map)))))

;;; The CTM text

(defun %q (value)
  (if (integerp value)
      (princ-to-string value)
      (with-output-to-string (out)
        (write-char #\" out)
        (loop for char across value do (when (member char '(#\" #\\)) (write-char #\\ out)) (write-char char out))
        (write-char #\" out))))

(defun %ctm-text (object stage topics statements)
  (declare (ignore object))
  (with-output-to-string (out)
    (format out "# Derived from the Lisp objects of one Item edit (~(~A~)); not a source. The objects are authoritative.~%" stage)
    (format out "# Association scopes: observed = read from a slot, derived = computed from the objects. Nothing is hypothetical.~%~%")
    (let ((types nil))
      (flet ((note (id) (pushnew id types :test #'equal)))
        (dolist (spec topics)
          (note (spec-type spec)) (dolist (o (spec-occurrences spec)) (note (first o))))
        (dolist (s statements)
          (note (statement-type s)) (dolist (r (statement-roles s)) (note (first r))) (note (string-downcase (symbol-name (statement-class s)))))
        (dolist (id (reverse types)) (format out "~A - ~A .~%" id (%q id)))))
    (terpri out)
    (dolist (spec topics)
      (format out "~A isa ~A ; - ~A" (spec-id spec) (spec-type spec) (%q (spec-name spec)))
      (dolist (o (spec-occurrences spec)) (format out " ; ~A: ~A" (first o) (%q (second o))))
      (format out " .~%"))
    (terpri out)
    (dolist (s statements)
      (format out "~A(~{~A~^, ~}) @~(~A~)~%" (statement-type s)
              (mapcar (lambda (r) (format nil "~A: ~A" (first r) (second r))) (statement-roles s)) (statement-class s)))))

;;; Inspection

(defun ref (object &optional label select)
  (v:html (v:object-ref object :display (or label (v:text-representation object)) :select select)))
(defun class-word (class) (string-downcase (symbol-name class)))

(defparameter +stage-words+
  '((:proposal "A proposal is the intended change: one Item and the text proposed for it. It holds no Action; the Action shown is the one PROPOSAL-ACTION makes now.")
    (:preview "A preview is the effect computed against the page file read again. It writes nothing; its Action has no date.")
    (:completion "A completion is the previewed Action copied with a date, and the body to be signed. It is not an authorization, and it shows neither execution nor persistence.")))

(defun %ctm-section (object)
  (let ((projection (handler-case (current-projection object) (item-edit-ctm-refused (condition) (princ-to-string condition)))))
    (if (stringp projection)
        (v:html (:h2 "CTM") (:p (v:esc projection)))
        (v:html
          (:h2 (v:esc (format nil "CTM of the ~(~A~) of ~A" (ctm-stage projection) (ctm-item-id projection))))
          (:p (v:esc (second (assoc (ctm-stage projection) +stage-words+))))
          (:p "The text below is derived from the Lisp objects each time this view is shown. It is not stored, and the objects stay authoritative. "
              "It is read with the topic-maps reader " (:code "topic-maps.ctm:deserialize-string") ", which yields the TMDM Topic Map linked here.")
          (:p (ref projection "The derived projection: its Topics, Associations and the Lisp objects they stand for" "TMDM objects") " / "
              (ref (ctm-map projection) "the TMDM Topic Map") " / "
              (ref projection "Topicmap: the diagram, with Point and History, and the TALA layout" "Topicmap"))
          (:h3 "CTM text")
          (:pre (v:esc (ctm-text projection)))
          (:table :class "inspector-table"
            (:tr (:td "Document IRI") (:td (:code (v:esc (ctm-document-iri projection))) " — a name for this derived document, not an address"))
            (:tr (:td "SHA-256 of the text") (:td (:code (v:esc (ctm-sha256 projection)))))
            (:tr (:td "Derived from") (:td (ref (ctm-origin projection)))))
          (:h3 "How each statement is known")
          (:table :class "inspector-table"
            (:tr (:th "Association") (:th "Class") (:th "From"))
            (dolist (s (ctm-statements projection))
              (v:html (:tr (:td (:code (v:esc (format nil "~A(~{~A~^, ~})" (statement-type s) (mapcar (lambda (r) (format nil "~A: ~A" (first r) (second r))) (statement-roles s))))))
                           (:td (v:esc (class-word (statement-class s)))) (:td (v:esc (statement-source s)))))))
          (:p "Observed: read from a slot of the object. Derived: computed here from the objects. No relation is hypothetical: none is stated that no object shows.")))))

(v:defview item-edit-proposal-ctm (proposal p:item-edit-proposal)
  (v:html-view :title "CTM" :priority 4 (%ctm-section proposal)))
(v:defview item-edit-preview-ctm (preview p:item-edit-preview)
  (v:html-view :title "CTM" :priority 4 (%ctm-section preview)))
(v:defview item-edit-completion-ctm (completion x:item-edit-completion)
  (v:html-view :title "CTM" :priority 4 (%ctm-section completion)))

(v:defview item-edit-ctm-objects (c item-edit-ctm)
  (v:html-view :title "TMDM objects" :priority 0
    (let ((map (ctm-map c)))
      (v:html
        (:h2 (v:esc (v:text-representation c)))
        (:p "The TMDM Topic Map the topic-maps reader made of the CTM text, and, for each Topic, the Lisp object it stands for. The binding is kept by this projection alone; "
            "TMDM objects carry no reference to Lisp objects, and nothing is registered globally.")
        (:p (ref map "the TMDM Topic Map") (v:esc (format nil " — ~D Topics, ~D Associations" (length (tmdm:topic-map-topics map)) (length (tmdm:topic-map-associations map))))
            " / " (ref (ctm-workspace c) "native Topicmap workspace") " / " (ref (ctm-origin c) "the object it was derived from"))
        (:h3 "Topics for the objects of the Item edit")
        (:table :class "inspector-table"
          (:tr (:th "Id") (:th "TMDM Topic") (:th "Type") (:th "Lisp object") (:th "Known by"))
          (dolist (spec (ctm-topics c))
            (v:html (:tr (:td (:code (v:esc (spec-id spec)))) (:td (ref (ctm-topic-of c (spec-id spec)) "TMDM Topic")) (:td (v:esc (spec-type spec)))
                         (:td (ref (spec-object spec))) (:td (v:esc (format nil "~A: ~A" (class-word (spec-class spec)) (spec-source spec))))))))
        (:h3 "Occurrences")
        (:table :class "inspector-table"
          (:tr (:th "Topic") (:th "Type") (:th "Value") (:th "Class") (:th "From"))
          (dolist (spec (ctm-topics c))
            (dolist (o (spec-occurrences spec))
              (v:html (:tr (:td (:code (v:esc (spec-id spec)))) (:td (v:esc (first o))) (:td (:code (v:esc (princ-to-string (second o)))))
                           (:td (v:esc (class-word (third o)))) (:td (v:esc (fourth o))))))))
        (:h3 "Associations and Roles")
        (dolist (association (tmdm:topic-map-associations map))
          (let ((scope (mapcar #'tr:topic-label (tmdm:association-scope association))))
            (when (tmdm:association-roles association)
              (v:html (:p (ref association "TMDM Association") (v:esc (format nil " ~A~@[, scope ~{~A~^ ~}~]" (tr:topic-label (tmdm:association-type association)) scope)))
                (:table :class "inspector-table"
                  (:tr (:th "Role") (:th "Role type") (:th "Player"))
                  (dolist (role (tmdm:association-roles association))
                    (let* ((player (tmdm:association-role-player role)) (id (tr:topic-label player)) (spec (find id (ctm-topics c) :key #'spec-id :test #'equal)))
                      (v:html (:tr (:td (ref role "TMDM Role")) (:td (ref (tmdm:association-role-type role) (tr:topic-label (tmdm:association-role-type role))))
                                   (:td (ref player id) (when spec (v:html " → " (ref (spec-object spec))))))))))))))
        (:p "The Associations without a scope are the type-instance Associations the reader makes of " (:code "isa") ".")))))

(v:defview item-edit-ctm-projections (c item-edit-ctm)
  (v:html-view :title "Projections" :priority -1
    (v:html
      (:h2 "The Topicmap projection")
      (:p "The Topic Map is shown as one projection, in " (ref c "the Topicmap view" "Topicmap") ": the objects of the Item edit and their Associations drawn as nodes with their Role edges, "
          "the schema Topics (types, Role types, Occurrence types, Scopes) kept out of the drawing but listed. Its Workspace is " (ref (ctm-workspace c) "the Topicmap workspace")
          ", which holds the Point and its History. " (ref c "Back to the TMDM objects" "TMDM objects")))))
