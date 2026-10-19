;;; A fresh, loopback-only review Catalog with the Item edit path: Edit proposal, Preview, Action context,
;;; Execution (no request is attached, so nothing can be written) and the TMDM readings.
;;; No existing Lisp image is contacted. Environment:
;;;   TOPIC_MAPS_ROOT           a CLEAN topic-maps checkout (required): the commit 788899ae or a descendant whose reading inputs are
;;;                             unchanged since (tested with 5a4a668). Not a working repository that is being developed.
;;;   HYPERDOC_FEDWIKI_SITE_ROOT the FedWiki site directory to read, e.g. ~/.wiki/localhost/ (required, unless the review copy is asked for)
;;;   HYPERDOC_CTM_REVIEW_COPY  "1": read a TEMPORARY COPY of the two retained pages instead (the review mode). The copy is made from the repository's
;;;                             files into a fresh directory of the temporary directory, marked as a test copy, and removed on shutdown. Nothing is
;;;                             read from or written to any wiki directory. Not together with HYPERDOC_FEDWIKI_SITE_ROOT.
;;;   HYPERDOC_CTM_PORT         default 18773; 18775 in the review mode, so that it never meets a Catalog that is already running on 18773
(load (merge-pathnames "tmdm-model-bootstrap.lisp" *load-truename*))
(asdf:load-system "dreyeck/catalog-application")

(defparameter +review-pages+
  '(("dreyeck/work/ctm-page-evidence/site/pages/ctm-and-tmdm-in-hyperdoc" . "ctm-and-tmdm-in-hyperdoc")
    ("dreyeck/work/topicmap-inspection-docs/site/pages/topicmap-inspection-dita" . "topicmap-inspection-dita"))
  "The retained pages of the repository, and the slugs they get in the copy. The repository's files stay the authority.")

(defun review-copy ()
  "A fresh temporary site root holding copies of +REVIEW-PAGES+, and a marker that says it is a test copy."
  (let* ((root (uiop:ensure-directory-pathname
                (merge-pathnames (format nil "hyperdoc-review-TEST-COPY-~D-~D/" (sb-unix:unix-getpid) (get-universal-time)) (uiop:temporary-directory)))))
    (ensure-directories-exist (merge-pathnames "pages/" root))
    (dolist (entry +review-pages+)
      (uiop:copy-file (asdf:system-relative-pathname "dreyeck" (car entry)) (merge-pathnames (format nil "pages/~A" (cdr entry)) root)))
    (with-open-file (out (merge-pathnames "THIS-IS-A-TEST-COPY.txt" root) :direction :output :if-exists :supersede)
      (write-line "A temporary copy of two retained pages of the HyperDoc repository, made for review. It is not a wiki and is removed when the Catalog stops." out))
    root))

(defun hyperdoc-commit ()
  (let ((directory (asdf:system-relative-pathname "dreyeck" "")))
    (flet ((git (&rest arguments)
             (string-trim '(#\Newline) (uiop:run-program (append (list "git" "-C" (namestring directory)) arguments) :output :string :ignore-error-status t))))
      (format nil "~A~:[~; (working tree has uncommitted changes)~]" (git "rev-parse" "--short" "HEAD") (plusp (length (git "status" "--porcelain")))))))

(let* ((review (equal "1" (uiop:getenv "HYPERDOC_CTM_REVIEW_COPY")))
       (given (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT"))
       (site (cond ((and review given (plusp (length given)))
                    (error "HYPERDOC_CTM_REVIEW_COPY=1 reads a temporary copy; do not also set HYPERDOC_FEDWIKI_SITE_ROOT."))
                   (review (review-copy))
                   (t given)))
       (port (parse-integer (or (uiop:getenv "HYPERDOC_CTM_PORT") (if review "18775" "18773")))))
  (unless (and site (uiop:directory-exists-p site))
    (error "Set HYPERDOC_FEDWIKI_SITE_ROOT to the FedWiki site directory to read."))
  (unwind-protect
       (progn
         (dreyeck/catalog-application:start-catalog
          :port port :host "127.0.0.1" :site-root (uiop:ensure-directory-pathname site)
          :development nil :catalog-system "dreyeck/ctm-page-authoring/local")
         (format t "~&REVIEW-MODE: ~:[off (the site root is read as given)~;on: a temporary TEST COPY of two retained pages; no wiki directory is read or written~]~%" review)
         (format t "SITE-ROOT: ~A~%HYPERDOC-COMMIT: ~A~%" (namestring (uiop:ensure-directory-pathname site)) (hyperdoc-commit))
         (format t "CTM page authoring review Catalog: http://127.0.0.1:~D/ (nothing is written to ~A)~%" port site)
         (when review (format t "Read the DITA topics: http://127.0.0.1:~D/view/topicmap-inspection-dita and Work Breakdown -> Topicmap Interaction Documentation~%" port))
         (finish-output)
         (loop (sleep 1)))
    (clog:shutdown)
    (when review (uiop:delete-directory-tree site :validate t :if-does-not-exist :ignore))))
