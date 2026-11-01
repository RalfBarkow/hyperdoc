;;;; Fresh test runtime, never a user's SLY image. Reads the site, never writes it.
(require :asdf)
(asdf:load-system "dreyeck/catalog-application")
(asdf:load-system "dreyeck/fedwiki-original-editor-demo")

(let ((expected (truename (uiop:getenv "HYPERDOC_EDITOR_TEST_CHECKOUT"))))
  (dolist (system '("dreyeck" "hyperbook" "dreyeck/fedwiki-original-editor-demo"))
    (let ((actual (truename (asdf:system-source-directory system))))
      (assert (equal actual expected))
      (format t "~&ASDF-ORIGIN ~A ~A~%" system actual))))

;; Verify the attributes on a real HyperDoc HTML parse-tree node, not a browser DOM copy.
(let* ((page (hyperbook:find-page dreyeck/fedwiki-original-editor-demo::*demo*
                                 "Editing One Isolated Wiki Page" :signal-error? t))
       (coordinate (dreyeck/fedwiki-original-editor-demo:paragraph-reference page)))
  (assert (equal coordinate '("fedwiki:original-editor-test.invalid"
                              "original-editor-test" "1111111111111111")))
  (format t "~&PARSE-TREE-REFERENCE ~S~%" coordinate))

(assert (not (asdf:component-loaded-p (asdf:find-system "dreyeck/verified-example"))))
(dreyeck/catalog-application:start-catalog
 :port (parse-integer (uiop:getenv "HYPERDOC_EDITOR_TEST_CATALOG_PORT"))
 :host "127.0.0.1"
 :site-root (uiop:getenv "HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT")
 :catalog-system "dreyeck/fedwiki-original-editor-demo")
(finish-output)
(loop until (probe-file (uiop:getenv "HYPERDOC_EDITOR_TEST_STOP")) do (sleep 0.1))
(clog:shutdown)
(uiop:quit 0)
