;;; The hyperdoc-catalog-topic-maps contract, run on the package's own registry (nix/catalog-topic-maps-check.nix).
;;; Every result here is executed now; nothing stored is reported as a run.
(require :asdf)
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path))
             collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :ignore-inherited-configuration))
(format t "~&RUN-STARTED ~A ~A ~A~%" (get-universal-time) (lisp-implementation-type) (lisp-implementation-version))
;; Where ASDF finds each system this package is about, before anything is loaded.
(dolist (system '("topic-maps" "topic-maps/tmdm" "topic-maps/ctm" "topic-maps/cxtm" "topic-maps/project-work-example"
                  "dreyeck" "dreyeck/catalog-application" "ironclad" "babel" "cl-base64" "cl-who" "html-inspector-views"))
  (format t "~&ASDF-ORIGIN ~A ~A~%" system (namestring (asdf:system-source-directory system))))
(format t "~&FASL-CACHE ~A~%" (namestring (asdf:apply-output-translations (asdf:system-source-directory "dreyeck"))))
(asdf:test-system "dreyeck/catalog-topic-maps")
(asdf:test-system "dreyeck/source-snapshot")
(asdf:test-system "dreyeck/work/topic-maps-project-example")
(asdf:test-system "dreyeck/work/topic-maps-ctm-review")
(format t "~&RUN-FINISHED ~A~%CATALOG-TOPIC-MAPS-PACKAGE-PASS~%" (get-universal-time))
