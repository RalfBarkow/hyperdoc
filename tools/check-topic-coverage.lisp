;;;; HyperDoc topic coverage gate for expr references on selected pages.
;;;;
;;;; Default scope: the Raspberry Pi / SD-image docs cluster.
;;;; Usage:
;;;;   nix develop --command sbcl --no-userinit --non-interactive \
;;;;     --load tools/check-topic-coverage.lisp
;;;;
;;;; Optional: pass explicit page paths after -- to override default pages.
;;;;   ... --load tools/check-topic-coverage.lisp -- hyperdoc/page-a.html ...

(in-package :cl-user)

(require :asdf)
(asdf:load-system :hyperdoc :force t)

(defparameter *default-topic-coverage-pages*
  '("hyperdoc/official-tutorial-nixos-sd-image-on-raspberry-pi-4-400.html"
    "hyperdoc/two-installation-models-sd-image-vs-classic-installer.html"
    "hyperdoc/invariant-boot-partition-must-be-big-enough.html"
    "hyperdoc/preflight-checklist-for-raspberry-pi-nixos-sd-images.html"
    "hyperdoc/Runbook - Build and Flash NixOS SD Image for Kioskberrli.html"
    "hyperdoc/Prepare the AArch64 image.html"))

(defun whitespace-char-p (ch)
  (or (char= ch #\Space)
      (char= ch #\Tab)
      (char= ch #\Newline)
      (char= ch #\Return)))

(defun extract-expr-forms (html)
  (loop with pos = 0
        for start = (search "expr=\"" html :start2 pos)
        while start
        for value-start = (+ start 6)
        for value-end = (position #\" html :start value-start)
        when value-end
          collect (subseq html value-start value-end)
          and do (setf pos (1+ value-end))
        else
          do (setf pos (1+ value-start))))

(defun expr-function-token (expr)
  (let ((open (position #\( expr)))
    (when open
      (let* ((start (or (position-if-not #'whitespace-char-p expr :start (1+ open))
                        (1+ open)))
             (end (position-if #'(lambda (ch)
                                   (or (whitespace-char-p ch)
                                       (char= ch #\))))
                               expr
                               :start start)))
        (subseq expr start (or end (length expr)))))))

(defun token->symbol (token)
  (let ((*package* (find-package :hyperdoc)))
    (handler-case
        (multiple-value-bind (symbol position)
            (read-from-string token)
          (declare (ignore position))
          symbol)
      (error () nil))))

(defun hyperdoc-symbol-p (symbol)
  (and symbol
       (symbol-package symbol)
       (string-equal (package-name (symbol-package symbol)) "HYPERDOC")))

(defun repo-root-pathname ()
  (asdf:system-relative-pathname :hyperdoc ""))

(defun resolve-page-path (path)
  (or (uiop:file-exists-p path)
      (uiop:file-exists-p (merge-pathnames path (repo-root-pathname)))
      (error "Topic coverage page not found: ~A" path)))

(defun selected-pages ()
  (let ((args (remove "--" (uiop:command-line-arguments) :test #'string=)))
    (if args
        (mapcar #'resolve-page-path args)
        (mapcar #'resolve-page-path *default-topic-coverage-pages*))))

(defun collect-page-symbol-exprs (pathname)
  (let* ((html (uiop:read-file-string pathname))
         (exprs (extract-expr-forms html))
         (seen (make-hash-table :test #'eq)))
    (loop for expr in exprs
          for token = (expr-function-token expr)
          for symbol = (and token (token->symbol token))
          when (and (hyperdoc-symbol-p symbol)
                    (not (gethash symbol seen)))
            collect (progn
                      (setf (gethash symbol seen) t)
                      (cons symbol expr)))))

(defun symbol-key (symbol)
  (format nil "~A::~A"
          (package-name (symbol-package symbol))
          (symbol-name symbol)))

(defun sorted-page-symbol-counts (table)
  (sort (loop for page being the hash-keys of table
              using (hash-value count)
              collect (list page count))
        #'string<
        :key #'first))

(defun run-check ()
  (let ((pages (selected-pages))
        (all-symbols '())
        (symbol-sources (make-hash-table :test #'eq))
        (symbol-reference-counts (make-hash-table :test #'eq))
        (page-symbol-counts (make-hash-table :test #'equal)))
    (dolist (page pages)
      (let ((page-symbols (collect-page-symbol-exprs page)))
        (setf (gethash (namestring page) page-symbol-counts)
              (length page-symbols))
        (dolist (symbol+expr page-symbols)
        (destructuring-bind (symbol . expr) symbol+expr
          (pushnew symbol all-symbols :test #'eq)
          (incf (gethash symbol symbol-reference-counts 0))
          (pushnew (list (namestring page) expr)
                   (gethash symbol symbol-sources)
                   :test #'equal)))))
    (let ((missing (loop for symbol in all-symbols
                         unless (fboundp symbol)
                           collect symbol))
          (duplicate-symbol-count
            (loop for symbol in all-symbols
                  count (> (gethash symbol symbol-reference-counts 0) 1))))
      (if missing
          (progn
            (format t "TOPIC_COVERAGE_FAIL~%")
            (dolist (symbol (sort (copy-list missing) #'string<
                                  :key #'symbol-key))
              (format t "MISSING ~A~%" (symbol-key symbol))
              (dolist (source (sort (copy-list (gethash symbol symbol-sources))
                                    #'string<
                                    :key #'first))
                (destructuring-bind (page expr) source
                  (format t "  REFERENCED_BY ~A~%" page)
                  (format t "  EXPR ~A~%" expr))))
            (format t "CHECKED_PAGES=~D~%" (length pages))
            (format t "CHECKED_SYMBOLS=~D~%" (length all-symbols))
            (format t "DUPLICATE_SYMBOLS=~D~%" duplicate-symbol-count)
            (dolist (entry (sorted-page-symbol-counts page-symbol-counts))
              (destructuring-bind (page count) entry
                (format t "PAGE_SYMBOLS ~A ~D~%" page count)))
            (uiop:quit 1))
          (progn
            (format t "TOPIC_COVERAGE_OK~%")
            (format t "CHECKED_PAGES=~D~%" (length pages))
            (format t "CHECKED_SYMBOLS=~D~%" (length all-symbols))
            (format t "DUPLICATE_SYMBOLS=~D~%" duplicate-symbol-count)
            (dolist (entry (sorted-page-symbol-counts page-symbol-counts))
              (destructuring-bind (page count) entry
                (format t "PAGE_SYMBOLS ~A ~D~%" page count)))
            (uiop:quit 0))))))

(run-check)
