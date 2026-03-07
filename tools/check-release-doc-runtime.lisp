;;;; Release doc/runtime consistency gate for shipped HyperDoc pages.
;;;
;;;; Ensures every expr-linked function used in shipped hyperdoc/*.html pages
;;;; is fbound after loading :hyperdoc/server.

(in-package :cl-user)

(require :asdf)
(asdf:load-system :hyperdoc/server :force t)

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
    (multiple-value-bind (symbol position)
        (read-from-string token)
      (declare (ignore position))
      symbol)))

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
           when token
             collect (token->symbol token))
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
