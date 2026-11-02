;;;; Fresh test runtime, never a user's SLY image. Reads the site, never writes it.
(require :asdf)
;; Follow catalog-main.lisp: use only the supplied trees, without personal ASDF
;; configuration. Nix's SBCL wrapper prefixes colon-form output translations;
;; do not append a second, s-expression form to that environment variable.
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path)) collect
             `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :ignore-inherited-configuration))
(let ((fasls (uiop:getenv "HYPERDOC_EDITOR_TEST_FASL_DIR")))
  (when fasls
    ;; macOS /tmp is normally a symlink to /private/tmp. Compare canonical
    ;; pathname identities, just as the ASDF-origin checks below do.
    (ensure-directories-exist (uiop:ensure-directory-pathname fasls))
    (setf fasls (namestring (truename (uiop:ensure-directory-pathname fasls))))
    (asdf:initialize-output-translations
     `(:output-translations
       ;; All recompilation belongs in this cache, even when ASDF decides a
       ;; prebuilt dependency needs rebuilding. Never write into the Nix store.
       ;; ASDF widens directory STRING designators recursively. A literal
       ;; pathname destination would flatten unrelated package.fasl files.
       (t ,(namestring (uiop:ensure-directory-pathname fasls)))
       :ignore-inherited-configuration))
    (let* ((root (uiop:ensure-directory-pathname (uiop:getenv "HYPERDOC_EDITOR_TEST_CHECKOUT")))
           (a (asdf:apply-output-translations (merge-pathnames "hyperbook/package.fasl" root)))
           (b (asdf:apply-output-translations (merge-pathnames "hyperdoc/package.fasl" root))))
      (assert (not (equal a b)))
      (assert (and (uiop:subpathp a (uiop:ensure-directory-pathname fasls))
                   (uiop:subpathp b (uiop:ensure-directory-pathname fasls))))
      (format t "~&FASL-CACHE ~A (source directories preserved)~%" fasls))))
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
;; The demo is a member of the default Catalog: present once before the additive CATALOG-SYSTEM below names it again.
(let ((ids (mapcar #'hyperbook:id-of (hyperbook:hyperbooks-of hyperbook:*catalog*))))
  (assert (= 1 (count "dreyeck/fedwiki-original-editor-demo" ids :test #'string=)))
  (format t "~&CATALOG-MEMBERSHIP dreyeck/fedwiki-original-editor-demo once among ~D~%" (length ids)))
;; This launcher embeds the editor on purpose; the configuration must say so, or the browser case would test nothing.
(let ((configuration (dreyeck/fedwiki-original-editor-configuration:editor-configuration)))
  (assert (eq :isolated-loopback-editor (dreyeck/fedwiki-original-editor-configuration:configuration-mode configuration))
          () "Editor not offered: ~S" (dreyeck/fedwiki-original-editor-configuration:configuration-problems configuration))
  (format t "~&EDITOR-MODE ~(~A~)~%" (dreyeck/fedwiki-original-editor-configuration:configuration-mode configuration)))
(dreyeck/catalog-application:start-catalog
 :port (parse-integer (uiop:getenv "HYPERDOC_EDITOR_TEST_CATALOG_PORT"))
 :host "127.0.0.1"
 :site-root (uiop:getenv "HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT")
 :catalog-system "dreyeck/fedwiki-original-editor-demo")
(assert (= 1 (count "dreyeck/fedwiki-original-editor-demo" (mapcar #'hyperbook:id-of (hyperbook:hyperbooks-of hyperbook:*catalog*))
                    :test #'string=)))
(finish-output)
(loop until (probe-file (uiop:getenv "HYPERDOC_EDITOR_TEST_STOP")) do (sleep 0.1))
(clog:shutdown)
(uiop:quit 0)
