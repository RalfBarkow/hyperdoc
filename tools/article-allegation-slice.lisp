;;;; CLI for article allegation slice scaffolding

(require :asdf)

(defun article-allegation-script-root ()
  (let* ((self (or *load-truename*
                   (error "Cannot resolve tools/article-allegation-slice.lisp path")))
         (tools-dir (uiop:pathname-directory-pathname self)))
    (uiop:pathname-parent-directory-pathname tools-dir)))

(defun initialize-article-allegation-script-asdf ()
  (let* ((root (article-allegation-script-root))
         (flake-deps (uiop:ensure-directory-pathname
                      (merge-pathnames ".flake-deps/" root)))
         (cache (uiop:ensure-directory-pathname
                 (merge-pathnames ".cache/asdf/" root)))
         (src-pattern (list root #P"**/*.*"))
         (dst-pattern (list cache #P"**/*.*")))
    (ensure-directories-exist cache)
    (asdf:initialize-source-registry
     (list :source-registry
           (list :tree root)
           (list :tree flake-deps)
           :inherit-configuration))
    (asdf:initialize-output-translations
     (list :output-translations
           (list src-pattern dst-pattern)
           :ignore-inherited-configuration))
    (asdf:load-asd (merge-pathnames "hyperbook.asd" root))
    (asdf:load-asd (merge-pathnames "hyperdoc.asd" root))
    (asdf:load-system :hyperdoc)))

(defun article-allegation-usage ()
  (format t
          "Usage: sbcl --script tools/article-allegation-slice.lisp --input <spec.lisp> [--dry-run-dir <dir>] [--write-live] [--print-plan]~%~
Example dry run: sbcl --script tools/article-allegation-slice.lisp --input tools/testdata/article-allegation-slice/minab-example.lisp --dry-run-dir /tmp/article-allegation-slice~%"))

(defun print-article-allegation-plan (bundle)
  (let ((metadata (getf bundle :slice-metadata)))
    (format t "Slice plan:~%~%")
    (format t "Slice metadata~%")
    (format t "  id: ~A~%" (getf metadata :slice-id))
    (format t "  mode: ~(~A~)~%" (getf metadata :mode))
    (format t "  epistemic-status: ~(~A~)~%" (getf metadata :epistemic-status))
    (format t "  source-type: ~(~A~)~%" (getf metadata :source-type))
    (format t "  source-label: ~A~%~%" (getf metadata :source-label))
    (format t "Incident page~%")
    (format t "  title: ~A~%" (getf metadata :incident-page-title))
    (format t "  path: ~A~%~%" (getf metadata :incident-page))
    (format t "Concept pages~%")
    (loop for title in (getf metadata :concept-page-titles)
          for path in (getf metadata :concept-pages)
          do (format t "  ~A~%    ~A~%" title path))
    (format t "~%Topics~%")
    (dolist (handle (getf metadata :topic-handles))
      (format t "  ~A~%" handle))
    (when (getf metadata :fedwiki-pages)
      (format t "~%FedWiki twins~%")
      (format t "  incident slug: ~A~%    ~A~%"
              (getf metadata :incident-fedwiki-slug)
              (first (getf metadata :fedwiki-pages)))
      (loop for slug in (getf metadata :concept-fedwiki-slugs)
            for path in (rest (getf metadata :fedwiki-pages))
            do (format t "  ~A~%    ~A~%" slug path)))
    (when (getf metadata :daily-anchor)
      (format t "~%Daily anchor~%")
      (format t "  target: ~A~%    ~A~%"
              (getf metadata :daily-anchor-target)
              (getf metadata :daily-anchor)))))

(defun parse-article-allegation-cli (arguments)
  (let ((input nil)
        (dry-run-dir nil)
        (live-write-p nil)
        (print-plan-p nil))
    (loop while arguments
          do (let ((arg (pop arguments)))
               (cond
                 ((string= arg "--input")
                  (setf input (pop arguments)))
                 ((string= arg "--dry-run-dir")
                  (setf dry-run-dir (pop arguments)))
                 ((string= arg "--write-live")
                  (setf live-write-p t))
                 ((string= arg "--print-plan")
                  (setf print-plan-p t))
                 ((or (string= arg "-h") (string= arg "--help"))
                  (article-allegation-usage)
                  (uiop:quit 0))
                 (t
                  (error "Unknown argument ~S" arg)))))
    (unless input
      (error "Missing required --input argument"))
    (unless (or dry-run-dir live-write-p print-plan-p)
      (error "Choose --dry-run-dir <dir>, --write-live, --print-plan, or a combination of --print-plan with one write mode"))
    (when (and dry-run-dir live-write-p)
      (error "Choose only one mode: --dry-run-dir or --write-live"))
    (list :input input
          :dry-run-dir dry-run-dir
          :live-write-p live-write-p
          :print-plan-p print-plan-p)))

(defun main ()
  (initialize-article-allegation-script-asdf)
  (let* ((options (parse-article-allegation-cli uiop:*command-line-arguments*))
         (input (uiop:symbol-call :hyperdoc
                                  :read-article-allegation-slice-input
                                  (getf options :input)))
         (bundle (uiop:symbol-call :hyperdoc
                                   :render-article-allegation-slice-bundle
                                   input
                                   :dry-run-directory
                                   (getf options :dry-run-dir))))
    (when (getf options :print-plan-p)
      (print-article-allegation-plan bundle))
    (when (or (getf options :dry-run-dir)
              (getf options :live-write-p))
      (uiop:symbol-call :hyperdoc
                        :write-article-allegation-slice-bundle
                        bundle
                        :live-write-p (getf options :live-write-p)))
    (format t "ARTICLE_ALLEGATION_SLICE_OK~%")
    (format t "INPUT=~A~%" (getf options :input))
    (when (getf options :dry-run-dir)
      (format t "DRY_RUN_DIR=~A~%" (getf options :dry-run-dir)))
    (format t "HYPERDOC_FILES=~D~%" (length (getf bundle :hyperdoc-files)))
    (format t "FEDWIKI_FILES=~D~%" (length (getf bundle :fedwiki-files)))
    (format t "TOPIC_FUNCTIONS=~D~%" (length (getf bundle :topic-definitions)))))

(main)
