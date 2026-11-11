;;;; Host-specific prepared dependency registry reused from the completed independent slice.
;;;; ASDF definitions only: no Topic Maps code is loaded before run.lisp verifies the candidate tree.
(require :asdf)
(load (merge-pathnames "../../topic-maps-conformance-planning/environment-bootstrap.lisp"
                       (uiop:pathname-directory-pathname *load-truename*)))
(asdf:initialize-output-translations
 '(:output-translations (t "/workspace/work/topic-maps-export-fasls/") :ignore-inherited-configuration))
(let ((root (uiop:ensure-directory-pathname
             (or (uiop:getenv "TOPIC_MAPS_CANDIDATE_ROOT") (error "Set TOPIC_MAPS_CANDIDATE_ROOT.")))))
  (asdf:load-asd (merge-pathnames "topic-maps.asd" root)))
