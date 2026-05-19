;;;; Release doc/runtime consistency gate for shipped HyperDoc pages.
;;;
;;;; Ensures every expr-linked function used in shipped hyperdoc/*.html pages
;;;; is fbound after loading :hyperdoc/server.

(in-package :cl-user)

(require :asdf)
(asdf:load-system :hyperdoc/server :force t)

(defparameter *release-doc-runtime-support-systems*
  '(:hyperdoc-goldberg-programmer-as-reader)
  "ASDF systems that provide packages/functions referenced by shipped page expr links.")

(defun load-release-doc-runtime-support-systems ()
  (dolist (system *release-doc-runtime-support-systems*)
    (asdf:load-system system)))

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
  "Resolve a page-derived Lisp symbol token without invoking READ.

The release checker scans shipped HTML pages. Those pages may contain
package-qualified symbols from optional extension packages that are not loaded
in the release-smoke image. Calling READ-FROM-STRING on such tokens signals a
reader package error before this checker can classify the reference.

Returns a symbol when resolved. Returns NIL when unresolved."
  (labels ((canon (string)
             (string-upcase string))
           (skip (reason &rest details)
             (warn "Skipping unresolved page symbol token ~S: ~S ~S"
                   token reason details)
             nil)
           (resolve-in-package (package-name symbol-name require-external-p)
             (let ((package (find-package (canon package-name))))
               (cond
                 ((null package)
                  (skip :missing-package
                        :package package-name
                        :symbol symbol-name))
                 ((string= symbol-name "")
                  (skip :missing-symbol-name
                        :package package-name))
                 (t
                  (multiple-value-bind (symbol status)
                      (find-symbol (canon symbol-name) package)
                    (cond
                      ((null status)
                       (skip :missing-symbol
                             :package package-name
                             :symbol symbol-name))
                      ((and require-external-p
                            (not (eq status :external)))
                       (skip :symbol-not-external
                             :package package-name
                             :symbol symbol-name
                             :status status))
                      (t
                       symbol))))))))
    (let ((colon (position #\: token)))
      (cond
        ((null colon)
         (let ((package (or (find-package :hyperdoc) *package*)))
           (multiple-value-bind (symbol status)
               (find-symbol (canon token) package)
             (if status
                 symbol
                 (skip :missing-bare-symbol
                       :package (package-name package)
                       :symbol token)))))

        ((zerop colon)
         (let ((symbol-name (subseq token 1)))
           (multiple-value-bind (symbol status)
               (find-symbol (canon symbol-name) "KEYWORD")
             (if status
                 symbol
                 (skip :missing-keyword-symbol
                       :symbol symbol-name)))))

        (t
         (let* ((double-colon-p
                  (and (< (1+ colon) (length token))
                       (char= (char token (1+ colon)) #\:)))
                (package-name
                  (subseq token 0 colon))
                (symbol-start
                  (+ colon (if double-colon-p 2 1)))
                (symbol-name
                  (if (<= symbol-start (length token))
                      (subseq token symbol-start)
                      "")))
           (resolve-in-package package-name
                               symbol-name
                               (not double-colon-p))))))))

(defun shipped-hyperdoc-html-pages ()
  (let* ((root (asdf:system-relative-pathname :hyperdoc "hyperdoc/")))
    (sort (directory (merge-pathnames "*.html" root))
          #'string<
          :key #'namestring)))

(defun collect-page-fn-symbols (pathname)
  (let* ((html (uiop:read-file-string pathname))
         (forms (extract-expr-forms html)))
    (remove-duplicates
     (loop for expr in forms
           for token = (expr-function-token expr)
           for symbol = (and token (token->symbol token))
           when symbol
             collect symbol)
     :test #'eq)))

(defparameter *required-release-symbols*
  '(hyperdoc::official-rpi-tutorial-workflow
    hyperdoc::official-rpi-tutorial-step
    hyperdoc::official-rpi-sd-image-tutorial-topic
    hyperdoc::sd-image-zstd-to-img-handoff-defect-topic
    hyperdoc::hydra-latest-filename-handoff-defect-topic
    hyperdoc::official-zstd-to-img-handoff-defect
    hyperdoc::official-zstd-to-img-handoff-patch-target
    hyperdoc::official-hydra-latest-filename-handoff-defect
    hyperdoc::official-hydra-latest-filename-handoff-patch-target))

(defun symbol-key (symbol)
  (if (symbol-package symbol)
      (format nil "~A::~A"
              (package-name (symbol-package symbol))
              (symbol-name symbol))
      (symbol-name symbol)))

(defun run-check ()
  (load-release-doc-runtime-support-systems)
  (let ((all-symbols (copy-list *required-release-symbols*))
        (symbol-pages (make-hash-table :test #'eq)))
    (dolist (page (shipped-hyperdoc-html-pages))
      (dolist (symbol (collect-page-fn-symbols page))
        (pushnew symbol all-symbols :test #'eq)
        (pushnew (namestring page) (gethash symbol symbol-pages) :test #'equal)))
    (let ((missing (loop for symbol in all-symbols
                         unless (fboundp symbol)
                         collect symbol)))
      (if missing
          (progn
            (format t "RELEASE_DOC_RUNTIME_FAIL~%")
            (dolist (symbol (sort (copy-list missing) #'string<
                                  :key #'symbol-key))
              (format t "MISSING ~A~%" (symbol-key symbol))
              (dolist (page (sort (copy-list (gethash symbol symbol-pages))
                                  #'string<))
                (format t "  REFERENCED_BY ~A~%" page)))
            (uiop:quit 1))
          (progn
            (format t "RELEASE_DOC_RUNTIME_OK~%")
            (format t "CHECKED_SYMBOLS=~D~%" (length all-symbols))
            (format t "CHECKED_PAGES=~D~%" (length (shipped-hyperdoc-html-pages)))
            (uiop:quit 0))))))

(run-check)
