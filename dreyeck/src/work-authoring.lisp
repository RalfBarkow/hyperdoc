;;;; Work status change: from a request to a checked HTML effect
;;;;
;;;; A WORK-STATUS-CHANGE-REQUEST carries the intended change and nothing
;;;; else. This authoring-side system adds what carrying it out in HTML
;;;; takes, in four separate steps:
;;;;
;;;;   PLAN-WORK-STATUS-CHANGE   validate the request again against the page
;;;;                             source now, refuse a proposed status the
;;;;                             source cannot hold as written, and record
;;;;                             where the declaration's data-status value
;;;;                             is. Writes nothing.
;;;;   APPLY-WORK-STATUS-CHANGE  only while the page source is still exactly
;;;;                             the plan's snapshot: derive the candidate,
;;;;                             verify it, install it atomically, reload the
;;;;                             page object, verify what was installed.
;;;;   before installation       everything the plan, its snapshot and the
;;;;                             candidate decide: the status is writable as
;;;;                             is, the candidate differs from the snapshot
;;;;                             in the status value alone, and it projects
;;;;                             to exactly the intended change -- the
;;;;                             target's status, every other Topic and every
;;;;                             Association as before. A candidate known to
;;;;                             be wrong never becomes the page.
;;;;   after installation        only what installing can reveal: the page
;;;;                             file is the verified candidate, and the page
;;;;                             object reloads to show the new status.
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
                    (#:views #:html-inspector-views))
  (:export #:work-status-change-plan #:plan-work-status-change
           #:work-status-change-plan-request #:work-status-change-plan-snapshot
           #:work-status-change-plan-status-range
           #:apply-work-status-change
           #:work-status-change-plan-refused #:work-status-change-plan-refused-reason
           #:work-status-change-plan-refused-cause
           #:work-status-change-apply-refused #:work-status-change-apply-refused-reason
           #:work-status-change-apply-refused-cause
           #:work-status-change-unverified #:work-status-change-unverified-reason))

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
  "Characters a data-status value cannot hold as written. This plan does not
escape them; it refuses.")

(defun %unwritable-character (status)
  "The first character of STATUS a data-status value cannot hold as written,
or NIL."
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
        (handler-case (work:request-work-status-change (work:work-status-change-topic request) proposed
                                                       :current current)
          (work:work-status-change-refused (condition)
            (refuse "the request no longer holds" condition)))
        (let ((unwritable (%unwritable-character proposed)))
          (when unwritable
            (refuse (format nil "~S cannot be written as a data-status value without escaping ~S"
                            proposed unwritable))))
        (let ((snapshot (work:topic-occurrence-snapshot (work:work-status-change-occurrence request))))
          (make-instance 'work-status-change-plan
                         :request request :snapshot snapshot
                         :status-range (%status-range request snapshot #'refuse)))))))

(defun %candidate (plan)
  "The source PLAN would leave: its snapshot with the status value replaced
by the proposed status, and nothing else."
  (let ((snapshot (work-status-change-plan-snapshot plan))
        (range (work-status-change-plan-status-range plan)))
    (concatenate 'string (subseq snapshot 0 (car range))
                 (work:work-status-change-proposed-status (work-status-change-plan-request plan))
                 (subseq snapshot (cdr range)))))

(defun %replace-source (path expected candidate refuse)
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
  "The Work Topic as CANDIDATE declares it, if CANDIDATE is exactly the
intended change of the plan's snapshot; otherwise a call to REFUSE. Decided
from the plan and the candidate alone, before anything is installed."
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
      (funcall refuse (format nil "~S cannot be written as a data-status value without escaping ~S"
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
        (funcall refuse "the candidate changes the Associations"))
      (tm:topicmap-projection-topic-by-id after id))))

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

(defun apply-work-status-change (plan)
  "Carry out PLAN: only while the declaring page's source is still exactly the
plan's snapshot, derive the candidate and verify that it is exactly the
intended change, install it atomically, reload the page object, and accept
the effect only if the file and the reloaded page are that candidate.
Returns the Work Topic as the page now declares it. Signals
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
      (let* ((candidate (%candidate plan))
             (topic (%verify-candidate plan candidate #'refuse)))
        (%replace-source path snapshot candidate #'refuse)
        (%verify-installed plan candidate)
        topic))))

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
