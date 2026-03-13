;;;; CLI for live FedWiki page materialization from HyperDoc artifacts

(require :asdf)

(defun fedwiki-materialization-script-root ()
  (let* ((self (or *load-truename*
                   (error "Cannot resolve tools/fedwiki-materialization.lisp path")))
         (tools-dir (uiop:pathname-directory-pathname self)))
    (uiop:pathname-parent-directory-pathname tools-dir)))

(defun initialize-fedwiki-materialization-script-asdf ()
  (let* ((root (fedwiki-materialization-script-root))
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

(defun fedwiki-materialization-usage ()
  (format t
          "Usage: sbcl --script tools/fedwiki-materialization.lisp (--page-slug <slug> | --slice-id <slice-id>) [--include-daily-anchor] [--print-plan] [--write-live]~%~
Example preview: sbcl --script tools/fedwiki-materialization.lisp --page-slug civilian-casualty-mitigation --print-plan~%"))

(defun parse-fedwiki-materialization-cli (arguments)
  (let ((page-slug nil)
        (slice-id nil)
        (print-plan-p nil)
        (write-live-p nil)
        (include-daily-anchor-p nil))
    (loop while arguments
          do (let ((arg (pop arguments)))
               (cond
                 ((string= arg "--page-slug")
                  (setf page-slug (pop arguments)))
                 ((string= arg "--slice-id")
                  (setf slice-id (pop arguments)))
                 ((string= arg "--print-plan")
                  (setf print-plan-p t))
                 ((string= arg "--write-live")
                  (setf write-live-p t))
                 ((string= arg "--include-daily-anchor")
                  (setf include-daily-anchor-p t))
                 ((or (string= arg "-h") (string= arg "--help"))
                  (fedwiki-materialization-usage)
                  (uiop:quit 0))
                 (t
                  (error "Unknown argument ~S" arg)))))
    (unless (or page-slug slice-id)
      (error "Choose --page-slug <slug> or --slice-id <slice-id>"))
    (when (and page-slug slice-id)
      (error "Choose only one selector: --page-slug or --slice-id"))
    (unless (or print-plan-p write-live-p)
      (error "Choose --print-plan, --write-live, or both"))
    (list :page-slug page-slug
          :slice-id slice-id
          :print-plan-p print-plan-p
          :write-live-p write-live-p
          :include-daily-anchor-p include-daily-anchor-p)))

(defun main ()
  (initialize-fedwiki-materialization-script-asdf)
  (let* ((options (parse-fedwiki-materialization-cli uiop:*command-line-arguments*))
         (plan (if (getf options :page-slug)
                   (uiop:symbol-call :hyperdoc
                                     :plan-fedwiki-page-materialization
                                     (getf options :page-slug))
                   (uiop:symbol-call :hyperdoc
                                     :plan-fedwiki-slice-materialization
                                     (getf options :slice-id)
                                     :include-daily-anchor-p
                                     (getf options :include-daily-anchor-p)))))
    (labels ((plan-slot (name)
               (funcall (symbol-function (find-symbol name :hyperdoc)) plan)))
    (when (getf options :print-plan-p)
      (uiop:symbol-call :hyperdoc :print-fedwiki-materialization-plan plan))
    (when (getf options :write-live-p)
      (uiop:symbol-call :hyperdoc :materialize-fedwiki-materialization-plan plan))
    (format t "FEDWIKI_MATERIALIZATION_OK~%")
    (format t "MODE=~(~A~)~%" (plan-slot "FEDWIKI-MATERIALIZATION-MODE-OF"))
    (format t "SELECTOR=~A~%" (plan-slot "FEDWIKI-MATERIALIZATION-SELECTOR-OF"))
    (format t "ENTRIES=~D~%" (length (plan-slot "FEDWIKI-MATERIALIZATION-ENTRIES-OF")))
    (when (plan-slot "FEDWIKI-MATERIALIZATION-EXECUTION-REPORT-OF")
      (format t "CREATED_OR_APPENDED=~D~%"
              (count-if (lambda (entry)
                          (member (getf entry :action) '(:create :append)))
                        (plan-slot "FEDWIKI-MATERIALIZATION-EXECUTION-REPORT-OF")))))))

(main)
