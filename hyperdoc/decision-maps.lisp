;;;; Inspectable implementation decision maps
;;;;
;;;; Decision-space objects for architecture and implementation planning.

(in-package :hyperdoc)


(defclass implementation-decision-map nil
          ((id :initarg :id :reader id-of)
           (title :initarg :title :reader title-of)
           (problem-statement :initarg :problem-statement :reader
            problem-statement-of)
           (constraints :initarg :constraints :initform nil :reader
            constraints-of)
           (options :initarg :options :initform nil :reader options-of)
           (relations :initarg :relations :initform nil :reader relations-of)
           (recommended-path :initarg :recommended-path :initform nil :reader
            recommended-path-of)
           (evidence :initarg :evidence :initform nil :reader evidence-of)))


(defclass implementation-option nil
          ((id :initarg :id :reader id-of)
           (title :initarg :title :reader title-of)
           (summary :initarg :summary :reader summary-of)
           (family :initarg :family :reader family-of)
           (effort :initarg :effort :reader effort-of)
           (risk :initarg :risk :reader risk-of)
           (embedded-fit :initarg :embedded-fit :reader embedded-fit-of)
           (hyperdoc-fit :initarg :hyperdoc-fit :reader hyperdoc-fit-of)
           (deliverables :initarg :deliverables :initform nil :reader
            deliverables-of)
           (pros :initarg :pros :initform nil :reader pros-of)
           (cons :initarg :cons :initform nil :reader cons-of)
           (status :initarg :status :initform :candidate :reader status-of)))


(defclass implementation-relation nil
          ((from :initarg :from :reader from-option-id-of)
           (to :initarg :to :reader to-option-id-of)
           (kind :initarg :kind :reader kind-of)
           (rationale :initarg :rationale :initform "" :reader rationale-of)))


(defun make-scxml-c-embedding-decision-map ()
  (let* ((a
          (make-instance 'implementation-option :id "A" :title
                         "HyperDoc-first MVP" :summary
                         "Use SCXML as the protocol contract; HyperDoc validates, documents, and replays it while the first C client is handwritten."
                         :family :mvp :effort :low :risk :low :embedded-fit
                         :medium :hyperdoc-fit :high :status :recommended-start
                         :deliverables
                         '("protocol SCXML file" "HyperDoc inspector page"
                           "handwritten C JSON-RPC/MCP client"
                           "smoke test against local HyperDoc service")
                         :pros
                         '("fastest proof" "uses existing SCXML runtime"
                           "validates service boundary early")
                         :cons
                         '("C state machine can drift from SCXML until codegen exists")))
         (k
          (make-instance 'implementation-option :id "K" :title
                         "Embedded-safe SCXML profile" :summary
                         "Constrain SCXML to deterministic, codegen-friendly constructs."
                         :family :profile :effort :medium :risk :low
                         :embedded-fit :very-high :hyperdoc-fit :high :status
                         :recommended-next :deliverables
                         '("profile document" "validator rules"
                           "unsupported construct diagnostics")
                         :pros
                         '("keeps generated C small"
                           "prevents hidden dynamic behavior"
                           "makes safety boundary explicit")
                         :cons '("not full SCXML")))
         (d
          (make-instance 'implementation-option :id "D" :title
                         "Generated C machine plus handwritten transport"
                         :summary
                         "Generate deterministic state/event logic; keep HTTP/MCP adapter separate."
                         :family :codegen :effort :medium :risk :low
                         :embedded-fit :high :hyperdoc-fit :high :status
                         :recommended :deliverables
                         '("generated .h/.c" "action callback interface"
                           "fake transport harness" "trace equivalence test")
                         :pros '("portable" "testable" "transport-independent")
                         :cons '("requires C generator backend"))))
    (make-instance 'implementation-decision-map :id
                   "scxml-c-embedding-decision-map" :title
                   "SCXML-to-C HyperDoc integration decision space"
                   :problem-statement
                   "Keep HyperDoc as a long-running Lisp service, embed only a generated SCXML protocol machine into C, and make HyperDoc inspect, validate, replay, and document the same machine."
                   :constraints
                   '("Do not embed HyperDoc itself into C."
                     "Generated C must not hide transport I/O inside transition logic."
                     "HyperDoc remains the authority for inspection, replay, and documentation."
                     "Embedded target should not require a Lisp runtime."
                     "SCXML profile must be deterministic and codegen-friendly.")
                   :options (list a k d) :recommended-path (list a k d)
                   :relations
                   (list
                    (make-instance 'implementation-relation :from "A" :to "K"
                                   :kind :precedes :rationale
                                   "The MVP exposes which SCXML subset is actually needed.")
                    (make-instance 'implementation-relation :from "K" :to "D"
                                   :kind :enables :rationale
                                   "The embedded profile constrains the C generator target.")))))


(defparameter *scxml-c-embedding-decision-map*
  (make-scxml-c-embedding-decision-map))

