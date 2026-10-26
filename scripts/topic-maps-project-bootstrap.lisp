;;; Fresh local process only. No Quicklisp, profile mutation or implicit checkout.
(require :asdf)
(let* ((root (uiop:pathname-parent-directory-pathname (uiop:pathname-directory-pathname *load-truename*)))
       (selected (uiop:getenv "TOPIC_MAPS_ROOT"))
       (topic-root (and selected (uiop:ensure-directory-pathname selected)))
       (cache (uiop:ensure-directory-pathname
               (or (uiop:getenv "HYPERDOC_22U_FASL_ROOT")
                   (merge-pathnames (format nil "hyperdoc-22u-~A/" (gensym)) (uiop:temporary-directory)))))
       (dependencies (loop for entry in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
                           when (uiop:string-prefix-p "/nix/store/" entry)
                             collect (uiop:ensure-directory-pathname (string-right-trim "/" entry)))))
  (unless (and topic-root (uiop:directory-exists-p topic-root))
    (error "Set TOPIC_MAPS_ROOT to the clean Topic Maps Slice 22U checkout."))
  ;; Nix's wrapper prefixes a colon mapping to its environment variable. Do not
  ;; append a Lisp output-translations expression to that variable.
  (asdf:initialize-output-translations
    `(:output-translations (,root ,(merge-pathnames "hyperdoc/" cache))
                           (,topic-root ,(merge-pathnames "topic-maps/" cache)) :inherit-configuration))
  (asdf:initialize-source-registry
    `(:source-registry (:tree ,root) (:tree ,topic-root)
       ,@(loop for path in dependencies collect `(:tree ,path)) :ignore-inherited-configuration))
  (asdf:load-system "dreyeck/work/topic-maps-project-example"))
