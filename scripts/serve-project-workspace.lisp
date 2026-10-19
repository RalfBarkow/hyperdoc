;;; A fresh, loopback-only Catalog with the HyperDoc Project Workspace (system dreyeck/work/project).
;;; No existing Lisp image is contacted and no wiki directory is read or written: the FedWiki site root is a fresh TEST COPY
;;; directory with an empty pages/ directory, removed on shutdown. Environment:
;;;   TOPIC_MAPS_ROOT          a clean topic-maps checkout of the pinned commit 5a4a668 (required; refused otherwise)
;;;   HYPERDOC_PROJECT_PORT    default 18777
(load (merge-pathnames "tmdm-model-bootstrap.lisp" *load-truename*))
(asdf:load-system "dreyeck/catalog-application")
(asdf:load-system "dreyeck/work/project")

(let ((identity (uiop:symbol-call :dreyeck/work/project :topic-maps-source-identity)))
  (unless (getf identity :pinned)
    (error "TOPIC_MAPS_ROOT must be a clean checkout of ~A; it is ~S."
           (symbol-value (find-symbol "+TOPIC-MAPS-REVISION+" :dreyeck/work/project)) identity)))

(defun test-copy-site-root ()
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "hyperdoc-project-TEST-COPY-~D-~D/" (sb-unix:unix-getpid) (get-universal-time)) (uiop:temporary-directory)))))
    (ensure-directories-exist (merge-pathnames "pages/" root))
    (with-open-file (out (merge-pathnames "THIS-IS-A-TEST-COPY.txt" root) :direction :output :if-exists :supersede)
      (write-line "An empty temporary FedWiki site root for the Project Workspace review Catalog. Removed when the Catalog stops." out))
    root))

(let ((site (test-copy-site-root)) (port (parse-integer (or (uiop:getenv "HYPERDOC_PROJECT_PORT") "18777"))))
  (unwind-protect
       (progn
         (dreyeck/catalog-application:start-catalog :port port :host "127.0.0.1" :site-root site :development nil
                                                    :catalog-system "dreyeck/work/project")
         (format t "~&SITE-ROOT: ~A~%TOPIC-MAPS: ~A~%" (namestring site)
                 (getf (uiop:symbol-call :dreyeck/work/project :topic-maps-source-identity) :commit))
         (format t "PROJECT-WORKSPACE-CATALOG: http://127.0.0.1:~D/ (HyperBook HyperDoc Project Workspace; nothing is written)~%" port)
         (finish-output)
         (loop (sleep 1)))
    (clog:shutdown)
    (uiop:delete-directory-tree site :validate t :if-does-not-exist :ignore)))
