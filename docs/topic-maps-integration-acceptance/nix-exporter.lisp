;;;; Acceptance-only Nix build check over immutable PR sources and the candidate store output.
(require :asdf)
(asdf:load-system "dreyeck/source-snapshot")
(defparameter *verified-candidate*
  (dreyeck/source-snapshot:verify-store-snapshot
   (uiop:ensure-directory-pathname (uiop:getenv "TOPIC_MAPS_CANDIDATE_ROOT"))
   "c446a8228017f405c3a2650ca893e9450ac7cd7b"))
(format t "~&NIX-CANDIDATE-STORE-PASS: ~D blobs, unchanged production store verification policy.~%"
        (dreyeck/source-snapshot:verification-blob-count *verified-candidate*))
(asdf:load-system "dreyeck/work/topic-maps-instance-of-export")
(let ((root (truename (uiop:ensure-directory-pathname (uiop:getenv "TOPIC_MAPS_CANDIDATE_ROOT")))))
  (dolist (system '("topic-maps" "topic-maps/tmdm" "topic-maps/ctm" "topic-maps/cxtm"))
    (assert (equal root (truename (asdf:system-source-directory system))))))
(asdf:test-system "dreyeck/work/topic-maps-instance-of-export")
(format t "~&NIX-EXPORTER-ACCEPTANCE-PASS: native instance-of export in the isolated Nix dependency closure.~%")
