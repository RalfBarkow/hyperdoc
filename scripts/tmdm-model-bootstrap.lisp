;;; Load only this checkout, the explicitly selected Topic Maps checkout and
;;; the pinned Nix dependencies. Never inherit another mutable HyperDoc tree.
(require :asdf)
(let* ((root (uiop:pathname-parent-directory-pathname (uiop:pathname-directory-pathname *load-truename*)))
       (topic-root (uiop:getenv "TOPIC_MAPS_ROOT")))
  (unless (and topic-root (uiop:directory-exists-p topic-root))
    (error "Set TOPIC_MAPS_ROOT to the clean, accepted Slice 12A checkout."))
  (asdf:initialize-source-registry
   `(:source-registry (:tree ,root) (:tree ,(uiop:ensure-directory-pathname topic-root))
     ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
             when (uiop:string-prefix-p "/nix/store/" path)
               collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
     :ignore-inherited-configuration))
  (asdf:load-system "dreyeck/work/tmdm-reading"))
