;;; Probe of the ASDF method collision, one fresh process per mode. Writes evidence/<mode>.sexp next to this file.
;;;   sbcl --script probe-asdf-method-collision.lisp baseline     ASDF alone
;;;   sbcl --script probe-asdf-method-collision.lisp with-guard   after loading dreyeck/catalog-topic-maps
;;; It reads HyperDoc's working tree and writes only its record and a temporary directory of its own.
(require :asdf) (require :sb-introspect)
(defvar *mode* (second sb-ext:*posix-argv*))
(defvar *here* (uiop:pathname-directory-pathname *load-truename*))
(defvar *hyperdoc* (merge-pathnames "../../../../" *here*))
(asdf:initialize-source-registry
 `(:source-registry (:tree ,(truename *hyperdoc*))
   ,@(loop for p in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           when (uiop:string-prefix-p "/nix/store/" p) collect `(:tree ,(string-right-trim "/" p)))
   :ignore-inherited-configuration))
(defun now () (multiple-value-bind (s m h d mo y) (decode-universal-time (get-universal-time) 0) (format nil "~D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ" y mo d h m s)))
(defun method-state (generic qualifiers classes)
  (let* ((method (find-method generic qualifiers classes nil))
         (source (and method (sb-introspect:find-definition-source method))))
    (list :source (and source (namestring (translate-logical-pathname (sb-introspect:definition-source-pathname source))))
          :methods-of-generic (length (sb-mop:generic-function-methods generic)))))
(defun census ()
  (list :operate-before-t-t (method-state #'asdf:operate '(:before) (list (find-class t) (find-class t)))
        :perform-before-operation-component
        (method-state #'asdf:perform '(:before) (list (find-class 'asdf:operation) (find-class 'asdf:component)))))
(defvar *temp* (uiop:ensure-directory-pathname (format nil "~Aasdf-collision-probe-~36R/" (namestring (uiop:temporary-directory)) (random (expt 36 8) (make-random-state t)))))
(ensure-directories-exist *temp*)
(defvar *before* (census))
(defvar *candidate-sha256* nil)
(when (equal *mode* "with-guard")
  (asdf:load-system "dreyeck/catalog-topic-maps")
  (setf *candidate-sha256*
        (let ((path (asdf:system-relative-pathname "dreyeck" "dreyeck/src/catalog-topic-maps.lisp")))
          (uiop:symbol-call :ironclad :byte-array-to-hex-string (uiop:symbol-call :ironclad :digest-file :sha256 path)))))
(defvar *after* (census))
;;; Consequence 1: an action that relies on ASDF to create its output directory.
(defclass collision-probe-op (asdf:non-propagating-operation) ())
(defmethod asdf:output-files ((o collision-probe-op) (c asdf:system))
  (values (list (merge-pathnames "made-by-asdf/out.txt" *temp*)) t))
(defmethod asdf:perform ((o collision-probe-op) (c asdf:system))
  (with-open-file (s (first (asdf:output-files o c)) :direction :output) (write-string "ok" s)))
(asdf:defsystem "collision-probe-system")
(defvar *action*
  (handler-case (progn (asdf:perform (asdf:make-operation 'collision-probe-op) (asdf:find-system "collision-probe-system")) :succeeded)
    (error (e) (list :failed (princ-to-string e)))))
;;; Consequence 2: compiling a file into a directory that does not yet exist.
(defvar *compile*
  (let ((source (merge-pathnames "source/probe.lisp" *temp*)) (fasl (merge-pathnames "fasl/deep/probe.fasl" *temp*)))
    (ensure-directories-exist source)
    (with-open-file (s source :direction :output) (write-string "(defun collision-probe-f () 1)" s))
    (handler-case (progn (uiop:compile-file* source :output-file fasl) (if (probe-file fasl) :succeeded :no-output))
      (error (e) (list :failed (princ-to-string e))))))
(uiop:delete-directory-tree *temp* :validate t)
(with-open-file (out (merge-pathnames (format nil "evidence/~A.sexp" *mode*) *here*) :direction :output :if-exists :supersede)
  (with-standard-io-syntax
    (let ((*print-readably* nil) (*print-case* :downcase))
      (format out ";;; Written by probe-asdf-method-collision.lisp; one fresh process, mode ~A.~%" *mode*)
      (prin1 (list :mode *mode* :at (now) :lisp (format nil "~A ~A" (lisp-implementation-type) (lisp-implementation-version))
                   :asdf (asdf:asdf-version) :guard-loaded (and (asdf:component-loaded-p "dreyeck/catalog-topic-maps") t)
                   :candidate-file "dreyeck/src/catalog-topic-maps.lisp" :candidate-file-sha256 *candidate-sha256*
                   :before *before* :after *after*
                   :action-relying-on-asdf-for-its-output-directory *action*
                   :compile-file-into-a-new-directory *compile*)
             out)
      (terpri out))))
(format t "~&PROBE ~A done~%" *mode*)
