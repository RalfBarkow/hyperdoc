;;;; Reuse only the fixed PR's prepared dependency registry; select a new acceptance FASL cache.
(require :asdf)
(load (merge-pathnames "docs/topic-maps-conformance-planning/environment-bootstrap.lisp"
                       (uiop:ensure-directory-pathname (uiop:getenv "DEFEDERATION_REPO"))))
(asdf:initialize-output-translations
 '(:output-translations (t "/workspace/work/acceptance-fasls-hyperdoc/") :ignore-inherited-configuration))
(let ((root (uiop:getenv "TOPIC_MAPS_CANDIDATE_ROOT")))
  (when root (asdf:load-asd (merge-pathnames "topic-maps.asd" (uiop:ensure-directory-pathname root)))))
