;;;; Run only in a separate image whose four Topic Maps ASDF systems come from the active 88994c1b snapshot.
(asdf:load-system "dreyeck/source-snapshot")
(let* ((root (uiop:ensure-directory-pathname (uiop:getenv "TOPIC_MAPS_CANDIDATE_ROOT")))
       (manifest (dreyeck/source-snapshot:find-snapshot-manifest "88994c1b9e1edbf13e665e984a5c9c3b2cdf7575")))
  (dreyeck/source-snapshot:verify-snapshot-tree root manifest))
(asdf:load-system "dreyeck/work/topic-maps-instance-of-export")
(assert
 (handler-case
     (progn
       (dreyeck/work/topic-maps-instance-of-export:export-instance-of
        (dreyeck/work/project:project-ctm-document)
        "tag:dreyeck.ch,2026:hyperdoc/page/dreyeck/work/reading/work-breakdown"
        "tag:dreyeck.ch,2026:hyperdoc/schema/hyperdoc-page")
       nil)
   (dreyeck/work/topic-maps-instance-of-export:export-refused (condition)
     (eq :relationship-reader-unavailable
         (dreyeck/work/topic-maps-instance-of-export:refusal-reason condition)))))
(format t "~&OLD-PIN-REFUSAL-PASS: active 88994c1b verified; optional system loads; missing public reader explicitly refused.~%")
