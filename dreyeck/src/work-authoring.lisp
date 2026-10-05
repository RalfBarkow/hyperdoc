;;;; Work status change: from a request to a checked HTML effect
;;;;
;;;; A WORK-STATUS-CHANGE-REQUEST carries the intended change and nothing
;;;; else. This authoring-side system adds what carrying it out in HTML
;;;; takes, in four separate steps:
;;;;
;;;;   PLAN-WORK-STATUS-CHANGE   validate the request again against the page
;;;;                             source now, refuse a proposed status the
;;;;                             plain, unescaped data-status representation
;;;;                             does not admit, and record where the
;;;;                             declaration's data-status value is. Writes
;;;;                             nothing.
;;;;   APPLY-WORK-STATUS-CHANGE  only while the page source is still exactly
;;;;                             the plan's snapshot: derive the candidate,
;;;;                             verify it, install it atomically, reload the
;;;;                             page object, verify what was installed.
;;;;   before installation       everything the plan, its snapshot and the
;;;;                             candidate decide: the status is admitted in
;;;;                             that representation, the candidate differs
;;;;                             from the snapshot in the status value alone,
;;;;                             and it projects to exactly the intended
;;;;                             change -- the target's status, every other
;;;;                             Topic and every Association as before. A
;;;;                             candidate not admitted, or not exactly the
;;;;                             intended change, never becomes the page.
;;;;   after installation        only what installing can reveal: the page
;;;;                             file is the verified candidate, and the page
;;;;                             object reloads to show the new status. The
;;;;                             result is then observed: the Work Topic as
;;;;                             reading the installed page declares it, not
;;;;                             the candidate's projection, which proved the
;;;;                             candidate correct and nothing more.
;;;;
;;;; EXECUTE-WORK-STATUS-CHANGE carries one request through these steps, and
;;;; only in an image holding the pinned authoring environment, the same
;;;; capability the Lisp source writers require. It adds no editing of its
;;;; own. Only such an image offers Change work status: on a Work Topic
;;;; declared in HTML, on a Workspace whose Point is one, and on the Topic
;;;; sign of one, by menu or by mark. Every offer first selects the operation
;;;; on the exact declaration as the one shared OPERATION-REQUEST; choosing a
;;;; status completes it into the request, which is executed. Neither the
;;;; offers nor the executor exist in an image that has not loaded this
;;;; system, though the selection is representable there.
;;;;
;;;; Staleness is the whole snapshot's, as for every Work source occurrence:
;;;; any difference refuses, and nothing is relocated by Topic ID. A plan
;;;; applied once has changed its own snapshot, so it cannot be applied
;;;; again. Which values a status may take, and who may apply a plan, are
;;;; not decided here.

(defpackage #:dreyeck/work/authoring
  (:use #:cl)
  (:local-nicknames (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap)
                    (#:r #:dreyeck/gesture/operation-request)
                    (#:ops #:dreyeck/work/operation-requests)
                    (#:m #:dreyeck/inspector/topicmap)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:views #:html-inspector-views))
  (:export #:work-status-change-plan #:plan-work-status-change
           #:work-status-change-plan-request #:work-status-change-plan-snapshot
           #:work-status-change-plan-status-range
           #:apply-work-status-change
           #:work-status-change-plan-refused #:work-status-change-plan-refused-reason
           #:work-status-change-plan-refused-cause
           #:work-status-change-apply-refused #:work-status-change-apply-refused-reason
           #:work-status-change-apply-refused-cause
           #:work-status-change-unverified #:work-status-change-unverified-reason
           #:execute-work-status-change #:work-status-change-outcome
           #:work-status-change-outcome-request #:work-status-change-outcome-plan
           #:work-status-change-outcome-status #:work-status-change-outcome-cause
           #:work-status-change-outcome-topic #:work-status-change-outcome-selection
           #:complete-work-status-change
           #:work-relationship-creation-plan #:plan-work-relationship-creation
           #:work-relationship-creation-plan-request #:work-relationship-creation-plan-snapshot
           #:work-relationship-creation-plan-position #:work-relationship-creation-plan-representation
           #:work-relationship-creation-plan-refused #:work-relationship-creation-plan-refused-reason
           #:work-relationship-creation-plan-refused-cause
           #:apply-work-relationship-creation
           #:work-relationship-creation-apply-refused #:work-relationship-creation-apply-refused-reason
           #:work-relationship-creation-apply-refused-cause
           #:work-relationship-creation-unverified #:work-relationship-creation-unverified-reason
           #:execute-work-relationship-creation #:work-relationship-creation-outcome
           #:work-relationship-creation-outcome-request #:work-relationship-creation-outcome-plan
           #:work-relationship-creation-outcome-status #:work-relationship-creation-outcome-cause
           #:work-relationship-creation-outcome-association #:work-relationship-creation-outcome-occurrence
           #:work-relationship-creation-execution-refused
           #:work-relationship-creation-execution-refused-reason
           #:work-status-change-execution-refused #:work-status-change-execution-refused-reason))

(in-package #:dreyeck/work/authoring)

(define-condition work-status-change-plan-refused (error)
  ((request :initarg :request :reader refused-plan-request)
   (reason :initarg :reason :reader work-status-change-plan-refused-reason)
   (cause :initarg :cause :initform nil :reader work-status-change-plan-refused-cause))
  (:report (lambda (condition stream)
             (format stream "No work status change plan: ~A"
                     (work-status-change-plan-refused-reason condition))))
  (:documentation "Nothing was planned and nothing was written. CAUSE, if
any, is the condition that showed why."))

(define-condition work-status-change-apply-refused (error)
  ((plan :initarg :plan :reader refused-apply-plan)
   (reason :initarg :reason :reader work-status-change-apply-refused-reason)
   (cause :initarg :cause :initform nil :reader work-status-change-apply-refused-cause))
  (:report (lambda (condition stream)
             (format stream "Work status change not applied: ~A"
                     (work-status-change-apply-refused-reason condition))))
  (:documentation "The page source was not changed."))

(define-condition work-status-change-unverified (error)
  ((plan :initarg :plan :reader unverified-plan)
   (reason :initarg :reason :reader work-status-change-unverified-reason))
  (:report (lambda (condition stream)
             (format stream "Work status change written but not accepted: ~A"
                     (work-status-change-unverified-reason condition))))
  (:documentation "The verified candidate was installed atomically, but
afterwards the page file or the reloaded page object does not coincide with
it. The effect is not accepted; nothing is rolled back, so the page shows
what happened."))

(defclass work-status-change-plan ()
  ((request :initarg :request :reader work-status-change-plan-request)
   (snapshot :initarg :snapshot :reader work-status-change-plan-snapshot)
   (status-range :initarg :status-range :reader work-status-change-plan-status-range))
  (:documentation "How one Work status change request is carried out in its
HTML source: the exact page source the plan was derived from, and the
half-open character range of the declaration's data-status value in it,
which the proposed status replaces. A plan writes nothing;
APPLY-WORK-STATUS-CHANGE does, only while the page source is still exactly
SNAPSHOT."))

(defmethod print-object ((plan work-status-change-plan) stream)
  (print-unreadable-object (plan stream :type t)
    (let ((request (work-status-change-plan-request plan)))
      (format stream "~A: ~S -> ~S at ~S"
              (tm:topicmap-topic-id-of (work:work-status-change-topic request))
              (work:work-status-change-observed-status request)
              (work:work-status-change-proposed-status request)
              (work-status-change-plan-status-range plan)))))

(defun %read-source (path)
  (uiop:read-file-string path :external-format :utf-8))

(defun %declaring-page (request)
  (work:topic-occurrence-page (work:work-status-change-occurrence request)))

(defparameter +unwritable-status-characters+ '(#\" #\& #\<)
  "Characters not admitted in the plain, unescaped data-status representation
used by this plan. A policy of this representation, not a limit of HTML: the
plan neither escapes them nor claims that every value containing one would
break the page; it refuses.")

(defun %unwritable-character (status)
  "The first character of STATUS not admitted in the plain, unescaped
data-status representation used by this plan, or NIL."
  (find-if (lambda (character) (member character +unwritable-status-characters+))
           status))

(defun %status-range (request snapshot refuse)
  "The range of the data-status value in the start tag of REQUEST's
declaration in SNAPSHOT, or a call to REFUSE."
  (let ((tag (work:topic-occurrence-start-tag-range (work:work-status-change-occurrence request))))
    (multiple-value-bind (name attributes end) (work::%start-tag snapshot (car tag))
      (declare (ignore name))
      (unless (eql end (cdr tag))
        (funcall refuse "the declaration's start tag no longer ends where its occurrence recorded"))
      (let ((entries (remove "data-status" attributes :key #'first :test-not #'string-equal)))
        (unless (and (= 1 (length entries)) (string= "data-status" (first (first entries))))
          (funcall refuse "the declaration does not state data-status exactly once, in lower case"))
        (destructuring-bind (attribute value start stop quote) (first entries)
          (declare (ignore attribute))
          (unless (eql #\" quote)
            (funcall refuse "the declaration's data-status value is not in double quotes"))
          (unless (string= value (work:work-status-change-observed-status request))
            (funcall refuse "the declaration's data-status value is not written as the status it states"))
          (cons start stop))))))

(defun plan-work-status-change (request &key (current nil current-p))
  "The HTML edit that would carry out REQUEST. CURRENT is the declaring page's
source now, read from its page unless given; the request is validated again
against it exactly as when it was made. Writes nothing, and signals
WORK-STATUS-CHANGE-PLAN-REFUSED unless every check holds."
  (flet ((refuse (reason &optional cause)
           (error 'work-status-change-plan-refused :request request :reason reason :cause cause)))
    (unless (typep request 'work:work-status-change-request)
      (refuse (format nil "~S is not a work status change request" request)))
    (let ((page (%declaring-page request))
          (proposed (work:work-status-change-proposed-status request)))
      (unless (typep page 'hyperdoc:html-page)
        (refuse (format nil "its declaring page ~S is not a HyperDoc HTML page" page)))
      (let ((current (if current-p current (%read-source (hyperdoc:file-of page)))))
        (handler-case (work:request-work-status-change (work:work-status-change-selection request)
                                                       (work:work-status-change-topic request) proposed
                                                       :current current)
          (work:work-status-change-refused (condition)
            (refuse "the request no longer holds" condition)))
        (let ((unwritable (%unwritable-character proposed)))
          (when unwritable
            (refuse (format nil "~S is not admitted in the plain, unescaped data-status representation used by this plan: it contains ~S"
                            proposed unwritable))))
        (let ((snapshot (work:topic-occurrence-snapshot (work:work-status-change-occurrence request))))
          (make-instance 'work-status-change-plan
                         :request request :snapshot snapshot
                         :status-range (%status-range request snapshot #'refuse)))))))

(defun %splice-source (snapshot range text)
  "SNAPSHOT with the characters in RANGE, (start . end), replaced by TEXT, and
nothing else. An empty RANGE inserts TEXT at its start."
  (concatenate 'string (subseq snapshot 0 (car range)) text (subseq snapshot (cdr range))))

(defun %candidate (plan)
  "The source PLAN would leave: its snapshot with the status value replaced
by the proposed status, and nothing else."
  (%splice-source (work-status-change-plan-snapshot plan)
                  (work-status-change-plan-status-range plan)
                  (work:work-status-change-proposed-status (work-status-change-plan-request plan))))

(defun %replace-source (path expected candidate refuse &key before-install)
  "Make PATH hold CANDIDATE, if it still holds exactly EXPECTED: through a
sibling file, read back before it is renamed over PATH. Otherwise, or if the
sibling does not read back, call REFUSE; PATH is then unchanged and the
sibling removed."
  (let ((sibling (make-pathname :name (format nil "~A.~36R" (pathname-name path) (random (expt 36 8)))
                                :type "candidate" :defaults path)))
    (unwind-protect
         (progn
           (with-open-file (stream sibling :direction :output :if-exists :error
                                           :if-does-not-exist :create :external-format :utf-8)
             (write-string candidate stream))
           (unless (string= candidate (%read-source sibling))
             (funcall refuse "the written candidate does not read back as planned"))
           (unless (string= expected (%read-source path))
             (funcall refuse "the page source changed while the candidate was written"))
           (when before-install (funcall before-install))
           (rename-file sibling path))
      (when (probe-file sibling)
        (delete-file sibling)))))

(defun %topic-row (topic &key (status t))
  "What a Topic says, its object compared by identity; its status only if STATUS."
  (let ((properties (tm:topicmap-topic-view-properties-of topic)))
    (list* (tm:topicmap-topic-id-of topic) (tm:topicmap-topic-label-of topic)
           (tm:topicmap-topic-type-of topic) (getf properties :kind)
           (getf properties :x) (getf properties :y) (tm:topicmap-topic-object-of topic)
           (and status (list (getf properties :status))))))

(defun %association-row (association)
  (list (tm:topicmap-association-id-of association) (tm:topicmap-association-type-of association)
        (tm:topicmap-association-from-of association) (tm:topicmap-association-to-of association)
        (tm:topicmap-association-relation-label association)))

(defun %verify-candidate (plan candidate refuse)
  "Call REFUSE unless CANDIDATE is exactly the intended change of the plan's
snapshot. Decided from the plan and the candidate alone, before anything is
installed; what the change produced is observed only after installation."
  (let* ((request (work-status-change-plan-request plan))
         (id (tm:topicmap-topic-id-of (work:work-status-change-topic request)))
         (proposed (work:work-status-change-proposed-status request))
         (page (%declaring-page request))
         (snapshot (work-status-change-plan-snapshot plan))
         (range (work-status-change-plan-status-range plan))
         (end (+ (car range) (length proposed)))
         (unwritable (%unwritable-character proposed)))
    ;; A plan need not have come from the planner.
    (when unwritable
      (funcall refuse (format nil "~S is not admitted in the plain, unescaped data-status representation used by this plan: it contains ~S"
                              proposed unwritable)))
    ;; The source delta: the status value and nothing else.
    (unless (and (= (length candidate) (+ (length snapshot) (- end (cdr range))))
                 (string= snapshot candidate :end1 (car range) :end2 (car range))
                 (string= proposed candidate :start2 (car range) :end2 end)
                 (string= snapshot candidate :start1 (cdr range) :start2 end))
      (funcall refuse "the candidate changes bytes outside the status value"))
    ;; The reconstructed delta: the target's status and nothing else.
    (let* ((before (work:project-work-breakdown snapshot :source page))
           (after (handler-case (work:project-work-breakdown candidate :source page)
                    (error (condition)
                      (funcall refuse (format nil "the candidate does not project: ~A" condition)))))
           (old (tm:topicmap-projection-topics-of before))
           (new (tm:topicmap-projection-topics-of after)))
      (unless (= (length old) (length new))
        (funcall refuse "the candidate declares another number of Topics"))
      (loop for was in old
            for is in new
            do (if (equal id (tm:topicmap-topic-id-of was))
                   (unless (and (equal (%topic-row was :status nil) (%topic-row is :status nil))
                                (equal proposed (getf (tm:topicmap-topic-view-properties-of is) :status)))
                     (funcall refuse (format nil "the candidate's Topic ~A is not ~A with the proposed status"
                                             id id)))
                   (unless (equal (%topic-row was) (%topic-row is))
                     (funcall refuse (format nil "the candidate changes Topic ~A"
                                             (tm:topicmap-topic-id-of was))))))
      (unless (equal (mapcar #'%association-row (tm:topicmap-projection-associations-of before))
                     (mapcar #'%association-row (tm:topicmap-projection-associations-of after)))
        (funcall refuse "the candidate changes the Associations")))))

(defun %verify-installed (plan candidate)
  "Reload the declaring page, and signal WORK-STATUS-CHANGE-UNVERIFIED unless
its file is the verified CANDIDATE and the reloaded page object shows the
proposed status. Only installation can reveal these."
  (let* ((request (work-status-change-plan-request plan))
         (id (tm:topicmap-topic-id-of (work:work-status-change-topic request)))
         (proposed (work:work-status-change-proposed-status request))
         (page (%declaring-page request)))
    (flet ((unverified (reason)
             (error 'work-status-change-unverified :plan plan :reason reason)))
      (unless (string= candidate (%read-source (hyperdoc:file-of page)))
        (unverified "the page file is not the verified candidate"))
      (handler-case (hyperdoc:load-page page)
        (error (condition)
          (unverified (format nil "the page object could not be reloaded: ~A" condition))))
      (let ((anchor (find id (plump:get-elements-by-tag-name (hyperbook:dom-of page) "a")
                          :key (lambda (node) (plump:attribute node "data-topic"))
                          :test #'equal)))
        (unless (and anchor (equal proposed (plump:attribute anchor "data-status")))
          (unverified "the reloaded page does not show the proposed status"))))))

(defun %observe-status-topic (plan)
  "The Work Topic the installed page declares for PLAN's request, as reading it
now finds it; otherwise WORK-STATUS-CHANGE-UNVERIFIED."
  (let* ((request (work-status-change-plan-request plan))
         (page (%declaring-page request))
         (id (tm:topicmap-topic-id-of (work:work-status-change-topic request))))
    (or (tm:topicmap-projection-topic-by-id
         (work:project-work-breakdown (%read-source (hyperdoc:file-of page)) :source page) id)
        (error 'work-status-change-unverified :plan plan
               :reason (format nil "reading the installed page finds no Topic ~A" id)))))

(defun apply-work-status-change (plan)
  "Carry out PLAN: only while the declaring page's source is still exactly the
plan's snapshot, derive the candidate and verify that it is exactly the
intended change, install it atomically, reload the page object, and accept
the effect only if the file and the reloaded page are that candidate.
Returns the Work Topic as reading the installed page declares it. Signals
WORK-STATUS-CHANGE-APPLY-REFUSED having written nothing, or
WORK-STATUS-CHANGE-UNVERIFIED having installed the verified candidate."
  (flet ((refuse (reason &optional cause)
           (error 'work-status-change-apply-refused :plan plan :reason reason :cause cause)))
    (unless (typep plan 'work-status-change-plan)
      (refuse (format nil "~S is not a work status change plan" plan)))
    (let* ((request (work-status-change-plan-request plan))
           (page (%declaring-page request))
           (path (hyperdoc:file-of page))
           (snapshot (work-status-change-plan-snapshot plan)))
      (unless (string= snapshot (%read-source path))
        (refuse "the page source is not the plan's snapshot"))
      ;; The same bytes, so every check the plan made holds again.
      (unless (equal (work-status-change-plan-status-range plan)
                     (%status-range request snapshot #'refuse))
        (refuse "the status value is not where the plan found it"))
      (let ((candidate (%candidate plan)))
        (%verify-candidate plan candidate #'refuse)
        (%replace-source path snapshot candidate #'refuse)
        (%verify-installed plan candidate)
        (%observe-status-topic plan)))))

;;;; Executing a request, and where an Inspector starts it

(define-condition work-status-change-execution-refused (error)
  ((request :initarg :request :reader refused-execution-request)
   (reason :initarg :reason :reader work-status-change-execution-refused-reason))
  (:report (lambda (condition stream)
             (format stream "Work status change not executed: ~A"
                     (work-status-change-execution-refused-reason condition))))
  (:documentation "Nothing was planned and nothing was written."))

(defclass work-status-change-outcome ()
  ((request :initarg :request :reader work-status-change-outcome-request)
   (plan :initarg :plan :initform nil :reader work-status-change-outcome-plan)
   (status :initarg :status :reader work-status-change-outcome-status)
   (cause :initarg :cause :initform nil :reader work-status-change-outcome-cause)
   (topic :initarg :topic :initform nil :reader work-status-change-outcome-topic))
  (:documentation "What executing one work status change request came to:
STATUS is :APPLIED, :REFUSED or :UNVERIFIED. PLAN is NIL if execution stopped
before planning. CAUSE is the refusal or the unverified condition. TOPIC, once
applied, is the Work Topic as the written page now declares it. The selection
is the request's."))

(defun work-status-change-outcome-selection (outcome)
  "The operation request OUTCOME's request completed."
  (work:work-status-change-selection (work-status-change-outcome-request outcome)))

(defmethod print-object ((outcome work-status-change-outcome) stream)
  (print-unreadable-object (outcome stream :type t)
    (format stream "~A ~A" (tm:topicmap-topic-id-of
                            (work:work-status-change-topic (work-status-change-outcome-request outcome)))
            (work-status-change-outcome-status outcome))))

(defun execute-work-status-change (request environment)
  "Carry REQUEST through the authoring contract: plan it, then apply the plan,
if ENVIRONMENT is the pinned authoring environment this image was given.
Returns a WORK-STATUS-CHANGE-OUTCOME in every case. Adds no editing of its
own: planning, applying and verifying are the existing steps."
  (flet ((outcome (&rest initargs)
           (apply #'make-instance 'work-status-change-outcome :request request initargs)))
    (unless (typep environment 'dreyeck/workflow/authoring::authoring-environment)
      (return-from execute-work-status-change
        (outcome :status :refused
                 :cause (make-condition 'work-status-change-execution-refused
                                        :request request
                                        :reason "there is no authoring environment: the pinned authoring capability is absent"))))
    (let ((plan (handler-case (plan-work-status-change request)
                  (work-status-change-plan-refused (condition)
                    (return-from execute-work-status-change
                      (outcome :status :refused :cause condition))))))
      (handler-case (outcome :status :applied :plan plan :topic (apply-work-status-change plan))
        (work-status-change-apply-refused (condition)
          (outcome :status :refused :plan plan :cause condition))
        (work-status-change-unverified (condition)
          (outcome :status :unverified :plan plan :cause condition))))))

(defun %status-choices (topic)
  "The statuses declared elsewhere on TOPIC's declaring page, in page order,
other than its own. An affordance of the view only: a value observed on the
page is merely a value to propose. It does not make a change permitted or
recommended, or part of any lifecycle."
  (let* ((occurrence (work:topic-source-occurrence topic))
         (own (getf (tm:topicmap-topic-view-properties-of topic) :status))
         (projection (work:project-work-breakdown (work:topic-occurrence-snapshot occurrence)
                                                  :source (work:topic-occurrence-page occurrence))))
    (remove own (remove-duplicates
                 (remove nil (mapcar (lambda (other)
                                       (getf (tm:topicmap-topic-view-properties-of other) :status))
                                     (tm:topicmap-projection-topics-of projection)))
                 :test #'equal :from-end t)
            :test #'equal)))

(defun complete-work-status-change (selection proposed)
  "Complete SELECTION -- Change work status selected on a Work Topic's exact
declaration -- with the status PROPOSED: make the request for the Topic that
declaration declares, execute it with this image's authoring environment, and
return the outcome, or the condition that refused a request."
  (let* ((occurrence (and (typep selection 'r:operation-request)
                          (eq (w:change-work-status-operation) (r:operation-request-operation selection))
                          (r:operation-request-occurrence selection)))
         (topic (and (typep occurrence 'work:work-topic-source-occurrence)
                     (ops:declared-work-topic occurrence))))
    (if (null topic)
        (make-condition 'work-status-change-execution-refused
                        :request nil
                        :reason (format nil "~S is not Change work status selected on a Work Topic declaration"
                                        selection))
        (handler-case
            (execute-work-status-change (work:request-work-status-change selection topic proposed)
                                        (handler-case (dreyeck/workflow/authoring:make-authoring-environment)
                                          (error () nil)))
          (work:work-status-change-refused (condition) condition)))))

(defun %declared-work-topic-p (topic)
  (and (typep topic 'work:work-topic) (work:topic-source-occurrence topic) t))

(defparameter *topic-sign-bindings*
  (loop for kind in '(:radial-menu :learned-mark)
        collect (w::%make-gesture-binding
                 :id (format nil "binding/~(~A~)-change-work-status" kind) :kind kind
                 :sector-center 0.0d0 :sector-half-width 30.0d0
                 :target-type :workspace-action-sign-occurrence
                 :enabled-p t :operation (w:change-work-status-operation)))
  "What the Topic sign of a Work Topic declared in HTML offers in an image that
has loaded this system: Change work status, by the visible menu or by a mark.")

(defmethod m:workspace-action-sign-bindings :around ((occurrence m:workspace-action-sign-occurrence))
  "Add Change work status to the Topic signs it applies to."
  (if (%declared-work-topic-p (m:occurrence-topic occurrence))
      (append (call-next-method) *topic-sign-bindings*)
      (call-next-method)))

(defmethod m:operation-inspectable-object ((operation (eql (w:change-work-status-operation))) target)
  "What Change work status shows for a Topic sign: the operation request it
selects on that Topic's exact declaration, from the shared registry."
  (let ((occurrence (getf target :occurrence)))
    (unless (and (eq :workspace-action-sign-occurrence (getf target :type))
                 (typep occurrence 'm:workspace-action-sign-occurrence)
                 (%declared-work-topic-p (m:occurrence-topic occurrence)))
      (error 'm:operation-not-applicable
             :operation operation :target target
             :reason "the target is no Topic sign of a Work Topic declared in HTML"))
    (select-work-operation operation (m:occurrence-topic occurrence) (m:occurrence-workspace occurrence))))

(defun %render-status-actions (topic &optional selection workspace)
  (let* ((occurrence (work:topic-source-occurrence topic))
         (page (work:topic-occurrence-page occurrence))
         (status (getf (tm:topicmap-topic-view-properties-of topic) :status))
         (choices (%status-choices topic)))
    (views:html
      (:table :class "inspector-table"
        (:tr (:td "Work Topic") (:td (views:object-ref topic :display (tm:topicmap-topic-id-of topic))))
        (:tr (:td "Declaring page")
             (:td (if (typep page 'hyperbook:page)
                      (views:object-ref page)
                      (views:html (:tt (views:esc (prin1-to-string page)))))))
        (:tr (:td "Work status now") (:td (:tt (views:esc (or status "none stated"))))))
      (:p "Each value below occurs elsewhere on the declaring page. Offering one does not mean the change is permitted, recommended, or part of a lifecycle.")
      (if choices
          (views:html
            (:ul
             (dolist (choice choices)
               (views:html
                 (:li (views:eval-button
                       (views:esc (format nil "Change work status to ~S" choice))
                       (views:thunk
                         (complete-editor-status
                          (or selection
                              (select-work-operation (w:change-work-status-operation) topic
                                                     (or workspace (%topic-workspace topic))))
                          choice))))))))
          (views:html (:p "No other status occurs on the declaring page.")))
      (:p "Choose a status to inspect the request. Preview its plan separately, then explicitly execute the request after revalidation."))))

(views:defview work-topic-status-actions (topic work:work-topic)
  (when (%declared-work-topic-p topic)
    (views:html-view :title "Change work status" :priority 2
      (%render-status-actions topic))))

(views:defview workspace-status-actions (workspace tm:topicmap-workspace)
  (when (tm:topicmap-workspace-point-projected-p workspace)
    (let ((topic (tm:topicmap-workspace-current-topic workspace)))
      (when (%declared-work-topic-p topic)
        (views:html-view :title "Change work status" :priority 5
          (%render-status-actions topic nil workspace))))))

(views:defview operation-request-status-actions (selection r:operation-request)
  (let ((occurrence (r:operation-request-occurrence selection)))
    (when (and (eq (w:change-work-status-operation) (r:operation-request-operation selection))
               (typep occurrence 'work:work-topic-source-occurrence))
      (let ((topic (ops:declared-work-topic occurrence)))
        (when topic
          (views:html-view :title "Change work status" :priority 2
            (%render-status-actions topic selection)))))))

(views:defview work-status-change-outcome-overview (outcome work-status-change-outcome)
  (views:html-view :title "Work status change outcome" :priority 1
    (let* ((request (work-status-change-outcome-request outcome))
           (plan (work-status-change-outcome-plan outcome))
           (cause (work-status-change-outcome-cause outcome))
           (topic (work-status-change-outcome-topic outcome))
           (page (%declaring-page request)))
      (views:html
        (:table :class "inspector-table"
          (:tr (:td "Operation")
               (:td (:tt (views:esc (dreyeck/gesture-binding-witness:semantic-operation-identity-id
                                     (work:work-status-change-operation request))))))
          (:tr (:td "Work Topic")
               (:td (views:object-ref (work:work-status-change-topic request)
                                      :display (tm:topicmap-topic-id-of (work:work-status-change-topic request)))))
          (:tr (:td "Selection")
               (:td (let ((selection (work-status-change-outcome-selection outcome)))
                      (if selection (views:object-ref selection) (views:html "none")))))
          (:tr (:td "Request") (:td (views:object-ref request)))
          (:tr (:td "Plan") (:td (if plan (views:object-ref plan) (views:html "none: execution stopped before planning"))))
          (:tr (:td "Outcome") (:td (:tt (views:esc (string-downcase (symbol-name (work-status-change-outcome-status outcome)))))))
          (:tr (:td "Cause") (:td (if cause (views:object-ref cause) (views:html "none"))))
          (:tr (:td "Source authority")
               (:td (if (typep page 'hyperbook:page)
                        (views:html (views:object-ref page) " " (:tt (views:esc (namestring (hyperdoc:file-of page)))))
                        (views:html (:tt (views:esc (prin1-to-string page)))))))
          (:tr (:td "Work Topic now")
               (:td (if topic
                        (views:html (views:object-ref topic :display (tm:topicmap-topic-id-of topic))
                                    " " (:tt (views:esc (getf (tm:topicmap-topic-view-properties-of topic) :status))))
                        (views:html "unchanged")))))))))

;;;; Planning a relationship creation
;;;;
;;;; A WORK-RELATIONSHIP-CREATION-REQUEST binds what is to be created to the
;;;; observed page snapshot; the plan adds how it would be written there. It
;;;; inserts one relationship statement, in the form the page's statements
;;;; have, directly after the last authored statement. That place is a
;;;; representation policy: the page declares no relationship collection,
;;;; and a statement anywhere on it would read the same. A page that states
;;;; no relationship gives the policy no place, and is refused. Before it is
;;;; returned, the plan's candidate is read and projected: exactly one new
;;;; statement, read as the requested one, and exactly one new Association,
;;;; everything else as before. No relationship occurrence is made here;
;;;; only reading written source would observe one. Nothing writes.

(define-condition work-relationship-creation-plan-refused (error)
  ((request :initarg :request :reader refused-relationship-plan-request)
   (reason :initarg :reason :reader work-relationship-creation-plan-refused-reason)
   (cause :initarg :cause :initform nil :reader work-relationship-creation-plan-refused-cause))
  (:report (lambda (condition stream)
             (format stream "No relationship creation plan: ~A"
                     (work-relationship-creation-plan-refused-reason condition))))
  (:documentation "Nothing was planned and nothing was written. CAUSE, if
any, is the condition that showed why."))

(defclass work-relationship-creation-plan ()
  ((request :initarg :request :reader work-relationship-creation-plan-request)
   (snapshot :initarg :snapshot :reader work-relationship-creation-plan-snapshot)
   (position :initarg :position :reader work-relationship-creation-plan-position)
   (representation :initarg :representation :reader work-relationship-creation-plan-representation))
  (:documentation "How one relationship creation request would be written:
the exact page source it was derived from, the character position the
statement goes at, and the statement's text. A plan writes nothing and holds
no relationship occurrence."))

(defmethod print-object ((plan work-relationship-creation-plan) stream)
  (print-unreadable-object (plan stream :type t)
    (format stream "~A at ~D" (work-relationship-creation-plan-request plan)
            (work-relationship-creation-plan-position plan))))

(defun %escape-text (text)
  "TEXT as HTML text content: & < and > written as entities."
  (with-output-to-string (stream)
    (loop for character across text
          do (case character
               (#\& (write-string "&amp;" stream))
               (#\< (write-string "&lt;" stream))
               (#\> (write-string "&gt;" stream))
               (t (write-char character stream))))))

(defun %relationship-representation (from to relation from-label to-label relation-label)
  "One relationship statement, on its own line, in the form the page's
statements have."
  (format nil "~%<li data-from=\"~A\" data-to=\"~A\" data-relation=\"~A\">~A → ~A: ~A.</li>"
          from to relation (%escape-text from-label) (%escape-text to-label) (%escape-text relation-label)))

(defun %relationship-candidate (plan)
  (let ((position (work-relationship-creation-plan-position plan)))
    (%splice-source (work-relationship-creation-plan-snapshot plan) (cons position position)
                    (work-relationship-creation-plan-representation plan))))

(defun %statement-triple (occurrence)
  (list (work:relationship-occurrence-from occurrence) (work:relationship-occurrence-relation occurrence)
        (work:relationship-occurrence-to occurrence)))

(defun %verify-relationship-candidate (plan refuse)
  "Call REFUSE unless PLAN's candidate, read and projected, differs from its
snapshot by exactly the requested statement and Association."
  (let* ((request (work-relationship-creation-plan-request plan))
         (page (work:work-relationship-creation-authority-page request))
         (snapshot (work-relationship-creation-plan-snapshot plan))
         (position (work-relationship-creation-plan-position plan))
         (representation (work-relationship-creation-plan-representation plan))
         (candidate (%relationship-candidate plan))
         (triple (list (work:topic-occurrence-topic (work:work-relationship-creation-from-occurrence request))
                       (work:work-relationship-creation-relation request)
                       (work:topic-occurrence-topic (work:work-relationship-creation-to-occurrence request)))))
    (flet ((read-source (text what)
             (handler-case (values (work:scan-work-relationships text page)
                                   (work:project-work-breakdown text :source page))
               (error (condition)
                 (funcall refuse (format nil "the ~A does not read as Work source: ~A" what condition))))))
      (multiple-value-bind (old before) (read-source snapshot "snapshot")
        (multiple-value-bind (new after) (read-source candidate "candidate")
          ;; The source: one new statement, read as the requested one, just
          ;; where the plan put it; every earlier statement as it was.
          (unless (and (= (length new) (1+ (length old)))
                       (equal (mapcar #'%statement-triple old) (mapcar #'%statement-triple (butlast new)))
                       (equal triple (%statement-triple (car (last new))))
                       (equal (cons (1+ position) (+ position (length representation)))
                              (work:relationship-occurrence-element-range (car (last new)))))
            (funcall refuse "the candidate does not add exactly the requested statement after the last one"))
          ;; The projection: every Topic as it was, and the Associations
          ;; as they were, followed by exactly the requested one.
          (let ((old-associations (tm:topicmap-projection-associations-of before))
                (new-associations (tm:topicmap-projection-associations-of after)))
            (unless (equal (mapcar #'%topic-row (tm:topicmap-projection-topics-of before))
                           (mapcar #'%topic-row (tm:topicmap-projection-topics-of after)))
              (funcall refuse "the candidate changes the Topics"))
            (unless (and (= (length new-associations) (1+ (length old-associations)))
                         (equal (mapcar #'%association-row old-associations)
                                (mapcar #'%association-row (butlast new-associations)))
                         (let ((added (car (last new-associations))))
                           (equal triple (list (tm:topicmap-association-from-of added)
                                               (tm:topicmap-association-type-of added)
                                               (tm:topicmap-association-to-of added)))))
              (funcall refuse "the candidate does not project to exactly the requested new Association"))))))))

(defun plan-work-relationship-creation (request &key (current nil current-p))
  "The HTML statement that would carry out REQUEST, verified before it is
returned. CURRENT is the page's source now, read from its page unless given;
the request is validated again against it exactly as when it was made.
Writes nothing, and signals WORK-RELATIONSHIP-CREATION-PLAN-REFUSED unless
every check holds."
  (flet ((refuse (reason &optional cause)
           (error 'work-relationship-creation-plan-refused :request request :reason reason :cause cause)))
    (when (typep request 'work:addresses-creation-request)
      (return-from plan-work-relationship-creation (plan-addresses-creation request)))
    (unless (typep request 'work:work-relationship-creation-request)
      (refuse (format nil "~S is not a relationship creation request" request)))
    (let* ((page (work:work-relationship-creation-authority-page request))
           (snapshot (work:work-relationship-creation-authority-snapshot request))
           (from (work:work-relationship-creation-from-occurrence request))
           (to (work:work-relationship-creation-to-occurrence request))
           (relation (work:work-relationship-creation-relation request)))
      (unless (typep page 'hyperdoc:html-page)
        (refuse (format nil "its authority page ~S is not a HyperDoc HTML page" page)))
      (let ((current (if current-p current (%read-source (hyperdoc:file-of page)))))
        (handler-case (work:request-work-relationship-creation
                       (work:work-relationship-creation-selection request) (ops:declared-work-topic to)
                       relation :current current)
          (work:work-relationship-creation-refused (condition)
            (refuse "the request no longer holds" condition))))
      (let ((unwritable (%unwritable-character relation)))
        (when unwritable
          (refuse (format nil "~S is not admitted in the plain, unescaped data-relation representation used by this plan: it contains ~S"
                          relation unwritable))))
      (let ((statements (work:scan-work-relationships snapshot page)))
        (unless statements
          (refuse "the observed page states no relationship, so this plan's policy has no statement to insert after"))
        (let* ((projection (work:project-work-breakdown snapshot :source page))
               (contract (and (work::relation-contract-reference-p relation)
                              (tm:topicmap-projection-topic-by-id projection relation)))
               (plan (make-instance
                      'work-relationship-creation-plan
                      :request request :snapshot snapshot
                      :position (work:relationship-insertion-position snapshot page)
                      :representation (%relationship-representation
                                       (work:topic-occurrence-topic from) (work:topic-occurrence-topic to) relation
                                       (tm:topicmap-topic-label-of (ops:declared-work-topic from))
                                       (tm:topicmap-topic-label-of (ops:declared-work-topic to))
                                       (if contract (tm:topicmap-topic-label-of contract) relation)))))
          (%verify-relationship-candidate plan #'refuse)
          plan)))))

;;;; Applying a relationship creation plan
;;;;
;;;; The effect follows the status writer's discipline: only while the page is
;;;; still exactly the plan's snapshot, the candidate is derived and verified
;;;; again -- a plan verified once is not trusted to stay sufficient -- then
;;;; installed atomically, and the page object reloaded. What was created is
;;;; then observed, not asserted: the written page is read by the ordinary
;;;; relationship scanner and projection, and the result is the Association and
;;;; the source occurrence that reading finds. The planned statement is a
;;;; representation before the effect; the occurrence is an observation after.

(define-condition work-relationship-creation-apply-refused (error)
  ((plan :initarg :plan :reader refused-relationship-apply-plan)
   (reason :initarg :reason :reader work-relationship-creation-apply-refused-reason)
   (cause :initarg :cause :initform nil :reader work-relationship-creation-apply-refused-cause))
  (:report (lambda (condition stream)
             (format stream "Relationship creation not applied: ~A"
                     (work-relationship-creation-apply-refused-reason condition))))
  (:documentation "The page source was not changed."))

(define-condition work-relationship-creation-unverified (error)
  ((plan :initarg :plan :reader unverified-relationship-plan)
   (reason :initarg :reason :reader work-relationship-creation-unverified-reason))
  (:report (lambda (condition stream)
             (format stream "Relationship creation installed but not accepted: ~A"
                     (work-relationship-creation-unverified-reason condition))))
  (:documentation "The verified candidate was installed atomically, but
afterwards the page file, or the reloaded page object, or reading the written
page does not show it. The effect is not accepted; nothing is rolled back."))

(defun %statement-count (dom triple)
  "How many relationship statements in DOM read as TRIPLE."
  (count triple (remove-if-not (lambda (node) (plump:attribute node "data-from"))
                               (plump:get-elements-by-tag-name dom "li"))
         :key (lambda (node) (list (plump:attribute node "data-from") (plump:attribute node "data-relation")
                                   (plump:attribute node "data-to")))
         :test #'equal))

(defun apply-work-relationship-creation (plan)
  "Carry out PLAN: only while the page is still exactly the plan's snapshot,
verify its candidate again, install it atomically and reload the page object;
then read the written page. Returns the Association that reading projects for
the requested relationship, and the source occurrence it was read from, as two
values. Signals WORK-RELATIONSHIP-CREATION-APPLY-REFUSED having written
nothing, or WORK-RELATIONSHIP-CREATION-UNVERIFIED having installed the
verified candidate."
  (flet ((refuse (reason &optional cause)
           (error 'work-relationship-creation-apply-refused :plan plan :reason reason :cause cause)))
    (when (typep plan 'addresses-creation-plan)
      (return-from apply-work-relationship-creation (apply-addresses-creation plan)))
    (unless (typep plan 'work-relationship-creation-plan)
      (refuse (format nil "~S is not a relationship creation plan" plan)))
    (let* ((request (work-relationship-creation-plan-request plan))
           (page (work:work-relationship-creation-authority-page request))
           (path (hyperdoc:file-of page))
           (snapshot (work-relationship-creation-plan-snapshot plan))
           (triple (list (work:topic-occurrence-topic (work:work-relationship-creation-from-occurrence request))
                         (work:work-relationship-creation-relation request)
                         (work:topic-occurrence-topic (work:work-relationship-creation-to-occurrence request)))))
      (unless (string= snapshot (%read-source path))
        (refuse "the page source is not the plan's snapshot"))
      (let ((candidate (%relationship-candidate plan)))
        (%verify-relationship-candidate plan #'refuse)
        (%replace-source path snapshot candidate #'refuse)
        (flet ((unverified (reason)
                 (error 'work-relationship-creation-unverified :plan plan :reason reason)))
          (let ((written (%read-source path)))
            (unless (string= candidate written)
              (unverified "the page file is not the verified candidate"))
            (handler-case (hyperdoc:load-page page)
              (error (condition)
                (unverified (format nil "the page object could not be reloaded: ~A" condition))))
            (unless (= 1 (%statement-count (hyperbook:dom-of page) triple))
              (unverified "the reloaded page does not show exactly one such statement"))
            ;; What exists now is what reading the written page observes.
            (let ((created (remove triple
                                   (tm:topicmap-projection-associations-of
                                    (work:project-work-breakdown written :source page))
                                   :key (lambda (association)
                                          (%statement-triple
                                           (getf (tm:topicmap-association-properties-of association)
                                                 :source-occurrence)))
                                   :test-not #'equal)))
              (unless (= 1 (length created))
                (unverified (format nil "reading the written page finds ~D such statements" (length created))))
              (values (first created)
                      (getf (tm:topicmap-association-properties-of (first created)) :source-occurrence)))))))))

;;;; Executing a relationship creation request
;;;;
;;;; The same boundary as EXECUTE-WORK-STATUS-CHANGE: only with the pinned
;;;; authoring environment this image was given does a request go on to its
;;;; plan and effect. The executor adds no editing of its own.

(define-condition work-relationship-creation-execution-refused (error)
  ((request :initarg :request :reader refused-relationship-execution-request)
   (reason :initarg :reason :reader work-relationship-creation-execution-refused-reason))
  (:report (lambda (condition stream)
             (format stream "Relationship creation not executed: ~A"
                     (work-relationship-creation-execution-refused-reason condition))))
  (:documentation "Nothing was planned and nothing was written."))

(defclass work-relationship-creation-outcome ()
  ((request :initarg :request :reader work-relationship-creation-outcome-request)
   (plan :initarg :plan :initform nil :reader work-relationship-creation-outcome-plan)
   (status :initarg :status :reader work-relationship-creation-outcome-status)
   (cause :initarg :cause :initform nil :reader work-relationship-creation-outcome-cause)
   (association :initarg :association :initform nil :reader work-relationship-creation-outcome-association)
   (occurrence :initarg :occurrence :initform nil :reader work-relationship-creation-outcome-occurrence))
  (:documentation "What executing one relationship creation request came to:
STATUS is :APPLIED, :REFUSED or :UNVERIFIED. PLAN is NIL if execution stopped
before planning. CAUSE is the refusal or the unverified condition. Once
applied, ASSOCIATION and OCCURRENCE are what reading the written page
observed: the relationship and the statement it was read from."))

(defmethod print-object ((outcome work-relationship-creation-outcome) stream)
  (print-unreadable-object (outcome stream :type t)
    (format stream "~A ~A" (work-relationship-creation-outcome-request outcome)
            (work-relationship-creation-outcome-status outcome))))

(defun execute-work-relationship-creation (request environment)
  "Carry REQUEST through the authoring contract -- plan it, then apply the plan
-- if ENVIRONMENT is the pinned authoring environment this image was given.
Returns a WORK-RELATIONSHIP-CREATION-OUTCOME in every case. Adds no editing
of its own: planning, applying and observing are the existing steps."
  (flet ((outcome (&rest initargs)
           (apply #'make-instance 'work-relationship-creation-outcome :request request initargs)))
    (unless (typep environment 'dreyeck/workflow/authoring::authoring-environment)
      (return-from execute-work-relationship-creation
        (outcome :status :refused
                 :cause (make-condition 'work-relationship-creation-execution-refused
                                        :request request
                                        :reason "there is no authoring environment: the pinned authoring capability is absent"))))
    (let ((plan (handler-case (plan-work-relationship-creation request)
                  (work-relationship-creation-plan-refused (condition)
                    (return-from execute-work-relationship-creation
                      (outcome :status :refused :cause condition))))))
      (handler-case (multiple-value-bind (association occurrence) (apply-work-relationship-creation plan)
                      (outcome :status :applied :plan plan :association association :occurrence occurrence))
        (work-relationship-creation-apply-refused (condition)
          (outcome :status :refused :plan plan :cause condition))
        (work-relationship-creation-unverified (condition)
          (outcome :status :unverified :plan plan :cause condition))))))

(views:defview work-relationship-creation-outcome-overview (outcome work-relationship-creation-outcome)
  (views:html-view :title "Relationship creation outcome" :priority 1
    (let* ((request (work-relationship-creation-outcome-request outcome))
           (plan (work-relationship-creation-outcome-plan outcome))
           (cause (work-relationship-creation-outcome-cause outcome))
           (association (work-relationship-creation-outcome-association outcome))
           (occurrence (work-relationship-creation-outcome-occurrence outcome))
           (page (work:work-relationship-creation-authority-page request)))
      (views:html
        (:table :class "inspector-table"
          (:tr (:td "Operation")
               (:td (:tt (views:esc (w:semantic-operation-identity-id
                                     (work:work-relationship-creation-operation request))))))
          (:tr (:td "Request") (:td (views:object-ref request)))
          (:tr (:td "Plan") (:td (if plan (views:object-ref plan) (views:html "none: execution stopped before planning"))))
          (:tr (:td "Outcome") (:td (:tt (views:esc (string-downcase (symbol-name (work-relationship-creation-outcome-status outcome)))))))
          (:tr (:td "Cause") (:td (if cause (views:object-ref cause) (views:html "none"))))
          (:tr (:td "Source authority")
               (:td (if (typep page 'hyperbook:page)
                        (views:html (views:object-ref page) " " (:tt (views:esc (namestring (hyperdoc:file-of page)))))
                        (views:html (:tt (views:esc (prin1-to-string page)))))))
          (:tr (:td "Relationship statement")
               (:td (if occurrence
                        (views:html (views:object-ref occurrence
                                                      :display (format nil "statement ~D, as reading the written page observed it"
                                                                       (work:relationship-occurrence-ordinal occurrence))))
                        (views:html "none"))))
          (:tr (:td "Association")
               (:td (if association
                        (views:object-ref association :display (tm:topicmap-association-id-of association))
                        (views:html "none")))))))))

(views:defview work-relationship-creation-plan-overview (plan work-relationship-creation-plan)
  (views:html-view :title "Relationship creation plan" :priority 1
    (let ((page (work:work-relationship-creation-authority-page (work-relationship-creation-plan-request plan))))
      (views:html
        (:table :class "inspector-table"
          (:tr (:td "Request") (:td (views:object-ref (work-relationship-creation-plan-request plan))))
          (:tr (:td "Authority") (:td (views:object-ref page)))
          (:tr (:td "Insertion")
               (:td (views:esc (format nil "at character ~D of the observed source: after the last authored relationship statement -- a representation policy, not a relationship collection"
                                       (work-relationship-creation-plan-position plan)))))
          (:tr (:td "Statement") (:td (:pre (views:esc (string-left-trim '(#\Newline) (work-relationship-creation-plan-representation plan))))))
          (:tr (:td "Relationship occurrence") (:td "none -- only reading the written source would observe one"))
          (:tr (:td "Applied") (:td "no -- there is no writer for this plan")))))))

(views:defview work-status-change-plan-overview (plan work-status-change-plan)
  (views:html-view :title "Work status change plan" :priority 1
    (let* ((request (work-status-change-plan-request plan))
           (page (%declaring-page request))
           (range (work-status-change-plan-status-range plan)))
      (views:html
        (:table :class "inspector-table"
          (:tr (:td "Request") (:td (views:object-ref request)))
          (:tr (:td "Declaring page") (:td (views:object-ref page)))
          (:tr (:td "Status value")
               (:td (views:esc (format nil "characters ~D to ~D of the observed source: ~S, to become ~S"
                                       (car range) (cdr range)
                                       (work:work-status-change-observed-status request)
                                       (work:work-status-change-proposed-status request)))))
          (:tr (:td "Applied")
               (:td "no -- a plan writes nothing; APPLY-WORK-STATUS-CHANGE does, only while the page source is still this snapshot")))))))
