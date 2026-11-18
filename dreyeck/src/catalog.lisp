
(DEFPACKAGE #:DREYECK/CATALOG
  (:USE #:CL)
  (:EXPORT #:CATALOG-PRESENTATION-STATE))

(IN-PACKAGE #:DREYECK/CATALOG)

(DEFUN DREYECK/CATALOG:CATALOG-PRESENTATION-STATE (CATALOG WORKSPACE-TOPICS)
  (LIST :HYPERBOOKS
        (MAPCAR
         (LAMBDA (HYPERBOOK)
           (LIST :ID (HYPERBOOK:ID-OF HYPERBOOK) :LABEL
                 (HYPERBOOK:TITLE-OF HYPERBOOK) :STATE :MATERIALIZED))
         (SORT (COPY-LIST (HYPERBOOK:HYPERBOOKS-OF CATALOG)) #'STRING< :KEY
               #'HYPERBOOK:TITLE-OF))
        :WORKSPACES
        (MAPCAR
         (LAMBDA (TOPIC)
           (LIST :ID (DREYECK/TOPICMAP:TOPICMAP-TOPIC-ID-OF TOPIC) :LABEL
                 (DREYECK/TOPICMAP:TOPICMAP-TOPIC-LABEL-OF TOPIC) :STATE
                 :DISCOVERED))
         WORKSPACE-TOPICS)))



(defun admit (target system-designator)
  (ecase target
    (:catalog
     (let* ((id (format nil "workspace:~A" system-designator))
            (existing (find id (hyperbook:hyperbooks-of hyperbook:*catalog*)
                            :key #'hyperbook:id-of :test #'string=)))
       (or existing
           (let ((offer (make-instance
                         'dreyeck/page-attached-workspace-offer:page-attached-workspace-offer
                         :id id :title system-designator)))
             (hyperbook:register offer)
             offer))))))
