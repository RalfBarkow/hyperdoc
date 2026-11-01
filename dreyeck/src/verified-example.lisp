;;;; Stored documentation, never an execution service. Opt-in local extension.
(defpackage #:dreyeck/verified-example
  (:use #:cl)
  (:local-nicknames (#:lp #:dreyeck/local-fedwiki-page)
                    (#:ap #:dreyeck/authority-policy)
                    (#:ev #:dreyeck/evaluation-record)
                    (#:v #:html-inspector-views)
                    (#:fw #:hyperbook/fedwiki))
  (:export #:stored-example #:example-page-source #:example-item-id
           #:example-systems #:example-manifest #:example-digest
           #:approve-display #:revoke-display #:display-decision
           #:request-play #:example-view))
(in-package #:dreyeck/verified-example)

(defclass stored-example ()
  ((page-source :initarg :page-source :reader example-page-source)
   (page-json :initarg :page-json :reader example-page-json)
   (item-id :initarg :item-id :reader example-item-id)
   (systems :initarg :systems :reader example-systems)
   (manifest :initarg :manifest :reader example-manifest)
   (input :initarg :input :reader ev:evaluation-input-of)
   (result :initarg :result :reader ev:evaluation-result-of)
   (status :initarg :status :reader ev:evaluation-status-of)
   (failure :initarg :failure :reader ev:evaluation-failure-of)
   (started :initarg :started :reader ev:evaluation-started-at-of)
   (finished :initarg :finished :reader ev:evaluation-finished-at-of))
  (:documentation "A trusted producer's stored data. Holding this record grants nothing.
SYSTEMS are inert source descriptors, never ASDF lookup requests. MANIFEST is
the producer's explicitly reviewed input closure, including tests and runtime."))

(defun %json-data (value)
  ;; Deterministic data encoding: no Lisp reader, package lookup or evaluation.
  (cond ((hash-table-p value)
         (cons :object
               (loop for key in (sort (loop for k being the hash-keys of value collect k) #'string<)
                     collect (list key (%json-data (gethash key value))))))
        ((and (vectorp value) (not (stringp value)))
         (cons :array (map 'list #'%json-data value)))
        (t value)))

(defun %digest-data (data)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence
    :sha256 (sb-ext:string-to-octets
             (with-standard-io-syntax (prin1-to-string data)) :external-format :utf-8))))

(defun %file-digest (path)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))

(defun %manifest (paths)
  (loop for path in (sort (remove-duplicates (mapcar #'truename paths) :test #'equal)
                         #'string< :key #'namestring)
        collect (list (namestring path) (%file-digest path))))

(defun %manifest-current-p (manifest)
  (and manifest
       (every (lambda (entry) (equal (second entry) (%file-digest (first entry)))) manifest)))

(defun example-digest (record)
  (let ((source (example-page-source record)))
    (%digest-data
     (list "hyperdoc-stored-example-v1"
           (namestring (lp:page-source-site-root source)) (lp:page-source-slug source)
           (lp:page-source-sha256 source) (example-page-json record)
           (%json-data (lp:page-source-json source))
           (example-item-id record) (example-systems record) (example-manifest record)
           (ev:evaluation-input-of record) (ev:evaluation-result-of record)
           (ev:evaluation-status-of record) (ev:evaluation-failure-of record)
           (ev:evaluation-started-at-of record) (ev:evaluation-finished-at-of record)))))

(defmethod ev:evaluation-specification-of ((record stored-example)) (example-systems record))
(defmethod ev:evaluation-evidence-of ((record stored-example)) (example-manifest record))
(defmethod ev:evaluation-identity-of ((record stored-example)) (example-digest record))
(defmethod ev:evaluation-trace-of ((record stored-example)) nil)
(defmethod ev:evaluation-annotation-of ((record stored-example))
  (declare (ignore record)) '(:stored-documentation :execution-disabled))

(defun approve-display (identity record authority)
  "Local maintenance operation. No Wiki field or HTTP handler calls this.
AUTHORITY identifies the reviewer, not a principal authenticated by this function.
The caller must already hold trusted Lisp access. Approval is volatile and explicit."
  (check-type identity string)
  (check-type record stored-example)
  (assert (and (stringp authority) (plusp (length authority))))
  (assert (eq :passed (ev:evaluation-status-of record)))
  (assert (null (ev:evaluation-failure-of record)))
  (assert (%manifest-current-p (example-manifest record)))
  (assert (lp:page-source-current-p (example-page-source record)))
  (ap:register-operation-contract
   :identity identity :status :contracted :effect-classes '(:display-only)
   :authority authority :required-permission :anonymous :required-capability :none
   :execution nil :verification-evidence record :audit-provenance (example-digest record)
   :replay-semantics :stored-data-only))

(defun revoke-display (identity reason)
  "Replace the existing authority entry; even a retained old contract cannot grant."
  (ap:register-operation-contract :identity identity :status :unsafe
                                  :failure-modes reason :execution nil))

(defun %item-matches-p (item record)
  (let* ((json (lp:page-source-json (example-page-source record)))
         (matches (remove-if-not (lambda (entry)
                                   (equal (gethash "id" entry) (example-item-id record)))
                                 (coerce (gethash "story" json) 'list))))
    (and (= 1 (length matches))
         (let ((expected (fw::make-story-item (fw::copy-page-json (first matches)))))
           (and (eq (fw::item-type-of expected) (fw::item-type-of item))
                (equal (fw::id-of expected) (fw::id-of item))
                (equal (fw::text-of expected) (fw::text-of item))
                (equal (%json-data (fw::data-of expected)) (%json-data (fw::data-of item))))))))

(defun display-decision (identity page item)
  "Recheck local authority and exact data. Return ALLOWED, REASON, RECORD, CONTRACT.
Only paths already held by the trusted producer are read. Never resolve a system,
transclude content, dispatch scripts, or evaluate a form from the page."
  (handler-case
      (let* ((contract (and (stringp identity) (ap:find-operation-contract identity)))
             (record (and contract (ap:contract-verification-evidence contract))))
        (flet ((deny (reason) (values nil reason nil nil)))
          (cond
            ((null contract) (deny :not-approved))
            ((not (eq :contracted (ap:contract-status contract))) (deny :revoked))
            ((not (and (equal '(:display-only) (ap:contract-effect-classes contract))
                       (null (ap:contract-execution contract))
                       (ap:invocation-decision contract)
                       (typep record 'stored-example))) (deny :wrong-contract))
            ((not (and (eq :passed (ev:evaluation-status-of record))
                       (null (ev:evaluation-failure-of record)))) (deny :verification-failed))
            ((not (equal (ap:contract-audit-provenance contract) (example-digest record)))
             (deny :artifact-changed))
            ((not (typep page 'lp:local-fedwiki-page)) (deny :foreign-page))
            ((not (and (equal (lp:local-fedwiki-page-site-root-of page)
                              (lp:page-source-site-root (example-page-source record)))
                       (equal (hyperbook:id-of page)
                              (lp:page-source-slug (example-page-source record)))
                       (equal (%json-data (fw::raw-json-of page)) (example-page-json record))
                       (%item-matches-p item record))) (deny :page-or-item-changed))
            ((not (lp:page-source-current-p (example-page-source record))) (deny :page-revision-changed))
            ((not (%manifest-current-p (example-manifest record))) (deny :source-revision-changed))
            ((not (eq contract (ap:find-operation-contract identity))) (deny :authorization-changed))
            (t (values t :display-only record contract)))))
    (error () (values nil :unavailable-or-malformed nil nil))))

(defun request-play (identity)
  "Closed server-side seam, deliberately without an HTTP route or evaluator.
Even a valid display grant is insufficient. No input is read as Lisp."
  (declare (ignore identity))
  (list :status :refused :reason :execution-unavailable :executed-p nil))

(defun %render-example (identity page item)
  (multiple-value-bind (allowed reason record contract) (display-decision identity page item)
    (declare (ignore contract))
    (v:html
      (:section :class "hyperdoc-stored-example"
        (:p (v:esc (format nil "~A; execution disabled" reason)))
        (when allowed
          (v:html (:pre (v:esc (ev:evaluation-input-of record)))
                  (:pre (v:esc (ev:evaluation-result-of record)))))))))

;; Reuse Code, without a new Story Item type, editor, endpoint or JS module.
;; Ordinary Code remains a passive source view. A marked Code item fails closed.
(defmethod fw::render-story-item ((type (eql :code)) item page)
  (let ((identity (and (fw::data-of item) (gethash "hyperdocExample" (fw::data-of item)))))
    (if identity
        (%render-example identity page item)
        (v:html (:pre (v:esc (fw::text-of item)))))))

(defun example-view (identity page item)
  "Render only the selected Code artifact, never the surrounding untrusted story."
  (v:html-view :title "Stored example" :priority 0
    (%render-example identity page item)))

(v:defview stored-evidence (record stored-example)
  ;; Local inspection of evidence is not a public disclosure grant. Show only
  ;; inert metadata here; the authorized view is EXAMPLE-VIEW.
  (v:html-view :title "Evidence" :priority 0
    (v:html (:p "Stored evidence; no operation is offered.")
            (:pre (v:esc (format nil "~S" (list :status (ev:evaluation-status-of record)
                                               :digest (example-digest record)
                                               :systems (example-systems record)
                                               :item (example-item-id record))))))))
