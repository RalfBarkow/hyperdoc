;;; The repository's own discovery on the files hyperdoc.dreyeck.ch serves (run 2026-11-08 in a fresh SBCL process without network).
;;; NOT purely read-only: A-CRITIC-FOR-LISP-OBSERVATION evaluated the page's a-critic-for-lisp.asd, because EXECUTION-PERMITTED-P is true
;;; in an image without a server, which registered the ASDF system (see ../README.md, section 5). Nothing else was loaded.
;;; Environment: PROBE_SITE=<scratch site root>, DREYECK_LISP_CRITIC_ROOT=<scratch site root>/assets/pages/a-critic-for-lisp/
(require :asdf)
(asdf:load-asd (merge-pathnames "dreyeck.asd" (uiop:ensure-directory-pathname (uiop:getenv "CRITIC_TREE"))))
(asdf:load-system "dreyeck/lisp-critic/engine-integration/tests")
(defun out (fmt &rest args) (let ((*print-pretty* nil) (*print-length* 12)) (format t "~&STATION-PROBE ~?~%" fmt args)))
(let ((site (uiop:getenv "PROBE_SITE")))
  (out "env DREYECK_LISP_CRITIC_ROOT=~A" (uiop:getenv "DREYECK_LISP_CRITIC_ROOT"))
  (let ((d (dreyeck/fedwiki-assets:page-attached-asdf-discovery-observation site "a-critic-for-lisp")))
    (out "fedwiki-assets discovery: title=~S references=~S asdf-files=~S"
         (getf d :page-title) (getf d :assets-references) (mapcar #'file-namestring (getf d :asdf-files)))))
(multiple-value-bind (root source candidates) (dreyeck/lisp-critic/reading::resolve-engine-asset-root)
  (out "resolve-engine-asset-root: root=~A source=~S candidates=~S" root source (mapcar #'car candidates)))
(out "engine-station-files-missing: ~S" (dreyeck/lisp-critic/reading::engine-station-files-missing))
(out "execution-permitted-p (default policy): ~S" (uiop:symbol-call :dreyeck/page-attached-system-projection :execution-permitted-p))
(let ((o (dreyeck/lisp-critic/reading:a-critic-for-lisp-observation)))
  (out "observation :wrapper-system ~S" (getf o :wrapper-system))
  (out "observation :wrapped-source ~S" (getf o :wrapped-source))
  (out "observation :loading :assets-present-p ~S" (getf (getf o :loading) :assets-present-p))
  (out "observation :page-attachment :resolution-source ~S :discovery-asdf ~S"
       (getf (getf o :page-attachment) :resolution-source)
       (mapcar #'file-namestring (getf (getf (getf o :page-attachment) :discovery) :asdf-files))))
(out "packages loaded? A-CRITIC-FOR-LISP=~S LISP-CRITIC=~S; registered a-critic-for-lisp: ~S"
     (and (find-package "A-CRITIC-FOR-LISP") t) (and (find-package "LISP-CRITIC") t)
     (and (member "a-critic-for-lisp" (asdf:registered-systems) :test #'string=) t))
(handler-case (progn (dreyeck/lisp-critic/engine-integration/tests:require-station) (out "require-station: PASSED"))
  (error (c) (out "require-station: ~A" (substitute #\Space #\Newline (princ-to-string c)))))
