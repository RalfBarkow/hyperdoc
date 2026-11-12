;;;; Optional read-only export of one stated relationship from one retained Project CTM revision.
(defpackage #:dreyeck/work/topic-maps-instance-of-export
  (:use #:cl)
  (:local-nicknames (#:p #:dreyeck/work/project) (#:tmdm #:topic-maps.tmdm)
                    (#:cxtm #:topic-maps.cxtm) (#:v #:html-inspector-views))
  (:export #:export-instance-of #:instance-of-statement #:export-refused #:refusal-reason
           #:statement-atom #:statement-association #:statement-instance #:statement-type
           #:statement-map #:statement-revision #:statement-source-sha256
           #:statement-cxtm-sha256 #:statement-scope #:statement-provenance))
(in-package #:dreyeck/work/topic-maps-instance-of-export)

(define-condition export-refused (error)
  ((reason :initarg :reason :reader refusal-reason))
  (:report (lambda (condition stream)
             (format stream "Instance-of export refused: ~S" (refusal-reason condition)))))
(defun refuse (reason) (error 'export-refused :reason reason))
(defun digest (octets)
  (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 octets)))

(defclass instance-of-statement ()
  ((atom :initarg :atom :reader statement-atom)
   (association :initarg :association :reader statement-association)
   (instance :initarg :instance :reader statement-instance)
   (type :initarg :type :reader statement-type)
   (map :initarg :map :reader statement-map)
   (revision :initarg :revision :reader statement-revision)
   (source-sha256 :initarg :source-sha256 :reader statement-source-sha256)
   (cxtm-sha256 :initarg :cxtm-sha256 :reader statement-cxtm-sha256)
   (scope :initarg :scope :reader statement-scope)
   (provenance :initform '(:warrant :observed-in-map :recognition :tmdm-7.2
                         :scope-policy :unscoped-only :inference :none :conformance-claim :none)
               :reader statement-provenance))
  (:documentation "An adapter statement, not a TMDM item or conformance Case Record. Object links retain EQ identity;
the source-octet digest and map CXTM digest identify different representations at export time. The map is not frozen."))

(defun relationship-reader ()
  ;; Resolve only the public reader. This optional system can load under the active old pin, but cannot export there.
  ;; No fallback interpretation and no change to the active ASDF source registry or dependency pin is permitted here.
  (multiple-value-bind (symbol status) (find-symbol "TYPE-INSTANCE-RELATIONSHIP" "TOPIC-MAPS.TMDM")
    (unless (and (eq status :external) (fboundp symbol)) (refuse :relationship-reader-unavailable))
    (symbol-function symbol)))

(defun export-instance-of (revision instance-identifier type-identifier)
  "Export one unambiguous, unscoped stated relationship. Both Topics must have exactly one Subject Identifier.
Read REVISION's existing native map; never reread/materialize its source, create items, infer, plan or execute anything.
Signal EXPORT-REFUSED for missing/ambiguous witnesses, scope, unsupported identity or a changed retained snapshot."
  (check-type revision p:ctm-revision)
  (unless (and (stringp instance-identifier) (plusp (length instance-identifier))
               (stringp type-identifier) (plusp (length type-identifier)))
    (refuse :invalid-identifiers))
  (let* ((reader (relationship-reader)) (map (p:revision-map revision))
         (source-sha (digest (p:revision-octets revision))))
    (unless map (refuse :source-revision-refused))
    (unless (equal source-sha (p:revision-sha256 revision)) (refuse :source-octets-changed))
    (let* ((before (cxtm:canonicalize-octets map :base-locator p:+document-iri+))
           (matches nil))
      (unless (equalp before (p:revision-cxtm revision)) (refuse :map-snapshot-changed))
      (dolist (association (tmdm:topic-map-associations map))
        (multiple-value-bind (type instance) (funcall reader association)
          (when (and type instance
                     (member instance-identifier (tmdm:topic-subject-identifiers instance) :test #'string=)
                     (member type-identifier (tmdm:topic-subject-identifiers type) :test #'string=))
            (push (list association instance type) matches))))
      (unless matches (refuse :no-stated-relationship))
      (unless (= 1 (length matches)) (refuse :ambiguous-relationship))
      (destructuring-bind (association instance type) (first matches)
        (unless (and (= 1 (length (tmdm:topic-subject-identifiers instance)))
                     (= 1 (length (tmdm:topic-subject-identifiers type))))
          (refuse :non-single-subject-identifier))
        (let ((scope (tmdm:association-scope association)))
          (when scope (refuse :scoped-relationship))
          (unless (and (eq map (p:revision-map revision))
                       (equal source-sha (digest (p:revision-octets revision)))
                       (equalp before (cxtm:canonicalize-octets map :base-locator p:+document-iri+)))
            (refuse :snapshot-changed-during-export))
          (make-instance 'instance-of-statement
                         :atom (list 'instance-of (copy-seq instance-identifier) (copy-seq type-identifier))
                         :association association :instance instance :type type :map map :revision revision
                         :source-sha256 source-sha :cxtm-sha256 (digest before) :scope scope))))))

(defmethod v:text-representation ((statement instance-of-statement))
  (format nil "Stated instance-of: ~S" (rest (statement-atom statement))))
(v:defview instance-of-provenance (statement instance-of-statement)
  (v:html-view :title "Instance-of provenance" :priority 0
    (v:html (:h2 "One stated relationship — read only")
      (:p (v:object-ref (statement-atom statement) :display "Exported atom"))
      (:p (v:object-ref (statement-association statement) :display "Source Association") " · "
          (v:object-ref (statement-instance statement) :display "Instance Topic") " · "
          (v:object-ref (statement-type statement) :display "Type Topic"))
      (:p (v:object-ref (statement-map statement) :display "Native Topic Map") " · "
          (v:object-ref (statement-revision statement) :display "Source CTM revision"))
      (:p "Source octets SHA-256: " (:code (v:esc (statement-source-sha256 statement))))
      (:p "Map CXTM SHA-256: " (:code (v:esc (statement-cxtm-sha256 statement))))
      (:p (v:object-ref (statement-scope statement) :display "Scope (empty; no context interpretation)"))
      (:p (v:object-ref (statement-provenance statement) :display "Statement provenance"))
      (:p "Observed in this map at export time. No inference, conformance decision or SHOP3 action. The native map remains mutable."))))
