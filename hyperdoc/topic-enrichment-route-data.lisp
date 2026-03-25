;;;; Topic enrichment route definitions
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *topic-enrichment-route-definitions*
  '((:id "route/chunk-zotero-library"
     :topic-id "chunk"
     :source-id "zotero-library/default"
     :notes "Durable baseline touch-fahrplan route for Chunk.")))

(defun topic-enrichment-route-definition-by-id (id)
  (find id *topic-enrichment-route-definitions*
        :key (lambda (entry) (getf entry :id))))

(defun topic-enrichment-route-definition-entries-for-topic-id (topic-id)
  (remove-if-not (lambda (entry)
                   (string= topic-id (getf entry :topic-id)))
                 *topic-enrichment-route-definitions*))
