;;;; Runtime coherence chunks for dependency repair.

(in-package :hyperdoc)

(defparameter *coherence-chunk-statuses*
  '(:unknown
    :good
    :missing
    :stale
    :blocked
    :failed
    :optional-unavailable))

(defparameter *coherence-chunk-kinds*
  '(:asdf-code-root
    :static-asset-root
    :asdf-system
    :optional-inspector-view
    :browser-inspection-session
    :plan-result
    :projection))

(defclass coherence-chunk ()
  ((id
    :reader coherence-chunk-id-of
    :initarg :id)
   (title
    :reader coherence-chunk-title-of
    :initarg :title)
   (kind
    :reader coherence-chunk-kind-of
    :initarg :kind)
   (basis
    :accessor coherence-chunk-basis-of
    :initarg :basis
    :initform nil)
   (status
    :accessor coherence-chunk-status-of
    :initarg :status
    :initform :unknown)
   (value
    :accessor coherence-chunk-value-of
    :initarg :value
    :initform nil)
   (evidence
    :accessor coherence-chunk-evidence-of
    :initarg :evidence
    :initform nil)
   (last-error
    :accessor coherence-chunk-last-error-of
    :initarg :last-error
    :initform nil)
   (repair-options
    :accessor coherence-chunk-repair-options-of
    :initarg :repair-options
    :initform nil)
   (depends-on
    :accessor coherence-chunk-depends-on-of
    :initarg :depends-on
    :initform nil)))

(defclass runtime-coherence-report ()
  ((title
    :reader runtime-coherence-report-title-of
    :initarg :title)
   (observed-at
    :reader runtime-coherence-report-observed-at-of
    :initarg :observed-at)
   (chunks
    :reader runtime-coherence-report-chunks-of
    :initarg :chunks)
   (summary
    :reader runtime-coherence-report-summary-of
    :initarg :summary)
   (recommended-next-actions
    :reader runtime-coherence-report-recommended-next-actions-of
    :initarg :recommended-next-actions)))

(defun make-coherence-chunk (&key id
                                  title
                                  kind
                                  basis
                                  (status :unknown)
                                  value
                                  evidence
                                  last-error
                                  repair-options
                                  depends-on)
  (assert (member status *coherence-chunk-statuses*) (status)
          "Unknown coherence chunk status ~S." status)
  (assert (member kind *coherence-chunk-kinds*) (kind)
          "Unknown coherence chunk kind ~S." kind)
  (make-instance 'coherence-chunk
                 :id id
                 :title title
                 :kind kind
                 :basis basis
                 :status status
                 :value value
                 :evidence evidence
                 :last-error last-error
                 :repair-options repair-options
                 :depends-on depends-on))

(defun coherence-chunk-status-blocking-p (status)
  (member status '(:missing :stale :blocked :failed) :test #'eq))

(defun coherence-status-counts (chunks)
  (let ((counts (make-hash-table :test #'eq)))
    (dolist (chunk chunks)
      (incf (gethash (coherence-chunk-status-of chunk) counts 0)))
    (loop for status in *coherence-chunk-statuses*
          for count = (gethash status counts)
          when count
            collect (cons status count))))

(defun runtime-coherence-blocking-chunks (chunks)
  (remove-if-not
   (lambda (chunk)
     (coherence-chunk-status-blocking-p
      (coherence-chunk-status-of chunk)))
   chunks))

(defun runtime-coherence-default-summary (chunks)
  (let ((blocking (runtime-coherence-blocking-chunks chunks)))
    (list :total (length chunks)
          :by-status (coherence-status-counts chunks)
          :blocking-chunks (mapcar #'coherence-chunk-id-of blocking)
          :good-chunks (mapcar #'coherence-chunk-id-of
                               (remove :good chunks
                                       :key #'coherence-chunk-status-of
                                       :test-not #'eq)))))

(defun runtime-coherence-default-actions (chunks)
  (let ((blocking (runtime-coherence-blocking-chunks chunks))
        (optional-unavailable
          (remove :optional-unavailable chunks
                  :key #'coherence-chunk-status-of
                  :test-not #'eq)))
    (append
     (when blocking
       (list "Inspect blocked or failed chunks before re-deriving browser inspection state."))
     (when optional-unavailable
       (list "Treat optional inspector capabilities as degraded, not as plan-object failure."))
     (unless (or blocking optional-unavailable)
       (list "No repair action is indicated by this non-mutating coherence report.")))))

(defun make-runtime-coherence-report (&key (title "Runtime coherence report")
                                           (observed-at (get-universal-time))
                                           (chunks nil)
                                           summary
                                           recommended-next-actions)
  (make-instance 'runtime-coherence-report
                 :title title
                 :observed-at observed-at
                 :chunks chunks
                 :summary (or summary
                              (runtime-coherence-default-summary chunks))
                 :recommended-next-actions
                 (or recommended-next-actions
                     (runtime-coherence-default-actions chunks))))

(defun make-inspector-runtime-coherence-report (&key
                                                  (title "Inspector runtime coherence report")
                                                  (observed-at (get-universal-time)))
  (make-runtime-coherence-report
   :title title
   :observed-at observed-at
   :chunks nil))

(defun make-current-plan-browser-coherence-report (&key root-object
                                                        summary
                                                        checklist
                                                        projections
                                                        (title "Plan browser coherence report")
                                                        (observed-at (get-universal-time)))
  (declare (ignore checklist))
  (let ((chunks
          (remove
           nil
           (list
            (when root-object
              (make-coherence-chunk
               :id "current-plan-result"
               :title "Current plan result"
               :kind :plan-result
               :status :good
               :value root-object
               :evidence (list (list :object-type (type-of root-object)))))
            (when projections
              (make-coherence-chunk
               :id "current-plan-projections"
               :title "Current plan projections"
               :kind :projection
               :status :good
               :value projections
               :evidence (list (list :projection-count
                                     (length projections)))))))))
    (make-runtime-coherence-report
     :title title
     :observed-at observed-at
     :chunks chunks
     :summary (or summary
                  (runtime-coherence-default-summary chunks)))))
