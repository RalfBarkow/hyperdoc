;;;; Work Topic declarations as operation request targets
;;;;
;;;; An OPERATION-REQUEST is an operation selected on one exact target
;;;; occurrence. This file lets that occurrence be a Work Topic declaration:
;;;; the WORK-TOPIC-SOURCE-OCCURRENCE a projection kept. It adds
;;;; representation only. Whether a Topic sign or an Inspector view offers an
;;;; operation, and anything that plans or writes, belong to authoring-side
;;;; systems: an operation can be representable here without being offered
;;;; here.

(defpackage #:dreyeck/work/operation-requests
  (:use #:cl)
  (:local-nicknames (#:r #:dreyeck/gesture/operation-request)
                    (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap))
  (:export #:work-topic-operation-request #:declared-work-topic))

(in-package #:dreyeck/work/operation-requests)

(defmethod r:occurrence-page ((occurrence work:work-topic-source-occurrence))
  "The page the declaration is on, not the carrier page it names."
  (work:topic-occurrence-page occurrence))

(defmethod r:occurrence-source ((occurrence work:work-topic-source-occurrence))
  (work:topic-occurrence-snapshot occurrence))

(defmethod r:occurrence-range ((occurrence work:work-topic-source-occurrence))
  (work:topic-occurrence-element-range occurrence))

(defmethod r:occurrence-status ((occurrence work:work-topic-source-occurrence))
  "Read-only freshness check against the declaring page's source now. An
unavailable page is also stale."
  (handler-case (progn (work:resolve-work-topic-occurrence occurrence) :current)
    (error () :stale-authority)))

(defmethod r:resolve-occurrence ((occurrence work:work-topic-source-occurrence))
  "OCCURRENCE, while the declaring page's source is exactly its snapshot;
otherwise WORK:STALE-WORK-TOPIC-OCCURRENCE. Nothing is relocated."
  (work:resolve-work-topic-occurrence occurrence))

(defmethod r::%write-occurrence-label ((occurrence work:work-topic-source-occurrence) stream)
  (format stream "Work Topic ~A, declaration ~D at ~S"
          (work:topic-occurrence-topic occurrence) (work:topic-occurrence-ordinal occurrence)
          (work:topic-occurrence-element-range occurrence)))

(defmethod r::%request-key (operation (occurrence work:work-topic-source-occurrence))
  (list operation (work:topic-occurrence-page occurrence) (work:topic-occurrence-topic occurrence)
        (work:topic-occurrence-snapshot occurrence) (work:topic-occurrence-element-range occurrence)))

(defun work-topic-operation-request (operation topic)
  "The request for OPERATION on TOPIC's exact declaration, from the one registry
every affordance uses: two affordances that select the same operation on the
same declaration get the same request."
  (let ((occurrence (and (typep topic 'work:work-topic) (work:topic-source-occurrence topic))))
    (unless occurrence
      (error "~S is no Work Topic declared in HTML." topic))
    (r:ensure-operation-request operation occurrence)))

(defun declared-work-topic (occurrence)
  "The Work Topic that OCCURRENCE's page declares at OCCURRENCE, as its snapshot
projects it, or NIL."
  (let ((start (car (work:topic-occurrence-element-range occurrence))))
    (find start
          (tm:topicmap-projection-topics-of
           (work:project-work-breakdown (work:topic-occurrence-snapshot occurrence)
                                        :source (work:topic-occurrence-page occurrence)))
          :key (lambda (topic)
                 (car (work:topic-occurrence-element-range (work:topic-source-occurrence topic)))))))
