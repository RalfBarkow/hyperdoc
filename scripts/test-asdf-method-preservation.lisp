;;; ASDF's own methods before and after dreyeck/catalog-topic-maps is loaded, in one fresh process.
;;; The guard of hyperdoc-catalog-topic-maps must add nothing to ASDF and replace nothing of it. A method is identified by its
;;; generic function, qualifiers and specializers, and defining one with the same three replaces the earlier method; the
;;; first version of the guard did that to two methods of ASDF 3.3.1. This script captures the method OBJECTS of every
;;; generic function of the ASDF packages before the guard system is loaded, loads it, and compares the objects themselves.
;;; It also runs the behaviour those methods give, before and after.
;;;   sbcl --noinform --no-sysinit --no-userinit --non-interactive --load scripts/test-asdf-method-preservation.lisp
;;; with CL_SOURCE_REGISTRY naming the HyperDoc source and the runtime's source trees, as the package contract does, and
;;; XDG_CACHE_HOME naming an empty directory: ASDF then has the directories of its compilation cache to create.
;;; It writes only into a temporary directory of its own, and loads nothing of Topic Maps.
(require :asdf)
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path))
             collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :ignore-inherited-configuration))
(require :sb-introspect)

(defvar *checks* nil)
(defmacro check (label form)
  `(progn (unless ,form (error "ASDF method preservation check failed: ~A" ,label)) (push ,label *checks*)))

(defvar *temp* (uiop:ensure-directory-pathname (format nil "~Aasdf-preservation-~36R/" (namestring (uiop:temporary-directory))
                                                      (random (expt 36 8) (make-random-state t)))))
(ensure-directories-exist *temp*)

;;; Methods, as objects

(defun asdf-generic-functions ()
  "Every generic function that a symbol of a package named ASDF* or UIOP* names, each once."
  (let ((seen (make-hash-table :test #'eq)) (functions nil))
    (dolist (package (list-all-packages))
      (when (or (uiop:string-prefix-p "ASDF" (package-name package)) (uiop:string-prefix-p "UIOP" (package-name package)))
        (do-symbols (symbol package)
          (when (and (eq (symbol-package symbol) package) (fboundp symbol) (not (macro-function symbol)) (not (special-operator-p symbol)))
            (let ((function (fdefinition symbol)))
              (when (and (typep function 'generic-function) (not (gethash function seen)))
                (setf (gethash function seen) t) (push function functions)))))))
    (sort functions #'string< :key (lambda (f) (prin1-to-string (sb-mop:generic-function-name f))))))
(defun census ()
  "((generic-function . its method objects) ...), copied now."
  (mapcar (lambda (f) (cons f (copy-list (sb-mop:generic-function-methods f)))) (asdf-generic-functions)))
(defun method-file (method)
  (let ((source (sb-introspect:find-definition-source method)))
    (and source (sb-introspect:definition-source-pathname source) (namestring (translate-logical-pathname (sb-introspect:definition-source-pathname source))))))
(defparameter +identities+
  (list (list "operate :before (t t)" #'asdf:operate '(:before) (list (find-class t) (find-class t)))
        (list "perform :before (operation component)" #'asdf:perform '(:before) (list (find-class 'asdf:operation) (find-class 'asdf:component)))
        (list "operate :before (operation component)" #'asdf:operate '(:before) (list (find-class 'asdf:operation) (find-class 'asdf:component)))))
(defun identity-methods ()
  (loop for (label generic qualifiers classes) in +identities+ collect (list label (find-method generic qualifiers classes nil))))

;;; Behaviour those methods give

(defclass probe-op (asdf:non-propagating-operation) ())
(defvar *phase* "before" "Each phase writes below a directory of its own, which ASDF must create.")
(defmethod asdf:output-files ((o probe-op) (c asdf:system))
  (values (list (merge-pathnames (format nil "made-by-asdf-~A/out.txt" *phase*) *temp*)) t))
(defmethod asdf:perform ((o probe-op) (c asdf:system))
  (with-open-file (s (first (asdf:output-files o c)) :direction :output) (write-string "ok" s)))

(defun write-system (name)
  "A system of one Lisp file in *TEMP*, defined there; loading it compiles the file into a directory ASDF must create."
  (let ((directory (merge-pathnames (format nil "~A/" name) *temp*)))
    (ensure-directories-exist directory)
    (with-open-file (s (merge-pathnames "probe.lisp" directory) :direction :output) (format s "(defparameter cl-user::*probe-~A* t)~%" name))
    (with-open-file (s (merge-pathnames (format nil "~A.asd" name) directory) :direction :output)
      (format s "(asdf:defsystem ~S :components ((:file \"probe\")))~%" name))
    (asdf:load-asd (merge-pathnames (format nil "~A.asd" name) directory))
    directory))

(defun behaviour (tag)
  "What ASDF does, observed now, as a plist. TAG names the phase."
  (let ((result nil) (*phase* (string-downcase (princ-to-string tag))))
    (flet ((note (key value) (setf result (append result (list key value)))))
      ;; 1. perform :before (operation component) creates the output directory of an action.
      (note :output-directory-created-by-asdf
            (handler-case (progn (asdf:perform (asdf:make-operation 'probe-op) (asdf:find-system "asdf")) :succeeded)
              (error (e) (list :failed (princ-to-string e)))))
      ;; 2. A real operation: load a system whose file ASDF compiles into a directory it creates.
      (let* ((name (format nil "preservation-probe-~(~A~)" tag)) (directory (write-system name)))
        (declare (ignorable directory))
        (note :load-system-compiles-into-created-directory
              (handler-case (progn (asdf:load-system name)
                                   (let ((fasl (first (asdf:output-files (asdf:make-operation 'asdf:compile-op) (asdf:find-component name "probe")))))
                                     (and (probe-file fasl) (symbol-value (find-symbol (string-upcase (format nil "*probe-~A*" name)) :cl-user)) :succeeded)))
                (error (e) (list :failed (princ-to-string e))))))
      ;; 3. operate :before (operation component &key version) refuses a version the system does not satisfy.
      (note :version-requirement-refused
            (handler-case (progn (asdf:operate 'asdf:load-op "uiop" :version "99999") :not-refused)
              (asdf:missing-component-of-version () :refused)
              (error (e) (list :other-error (princ-to-string e)))))
      ;; 4. operate :before (operation-class system &rest args) refuses ASDF-BINARY-LOCATIONS: its symbol exists in ASDF.
      (let* ((name "OUTPUT-FILES-FOR-SYSTEM-AND-OPERATION") (existed (find-symbol name :asdf)))
        (unwind-protect
             (progn (unless existed (intern name :asdf))
                    (note :asdf-binary-locations-refused
                          (handler-case (progn (asdf:operate 'asdf:load-op "uiop") :not-refused)
                            (error (e) (if (search "ASDF-BINARY-LOCATIONS" (princ-to-string e)) :refused (list :other-error (princ-to-string e)))))))
          (unless existed (unintern (find-symbol name :asdf) :asdf)))))
    result))

;;; Before

(defvar *before-census* (census))
(defvar *before-identities* (identity-methods))
(defvar *before-behaviour* (behaviour :before))
(defvar *before-operate-count* (length (sb-mop:generic-function-methods #'asdf:operate)))
(defvar *before-perform-count* (length (sb-mop:generic-function-methods #'asdf:perform)))

(format t "~&ASDF ~A; ~D generic functions with ~D methods; behaviour before: ~S~%" (asdf:asdf-version) (length *before-census*)
        (reduce #'+ *before-census* :key (lambda (entry) (length (cdr entry)))) *before-behaviour*)

;; Test A, first part: the identities the first guard replaced were ASDF's own, before the guard.
(dolist (entry *before-identities*)
  (check (format nil "before: ~A exists" (first entry)) (and (second entry) (search "asdf" (or (method-file (second entry)) "")))))
(check :before-ok (and (eq :succeeded (getf *before-behaviour* :output-directory-created-by-asdf))
                       (eq :succeeded (getf *before-behaviour* :load-system-compiles-into-created-directory))
                       (eq :refused (getf *before-behaviour* :version-requirement-refused))
                       (eq :refused (getf *before-behaviour* :asdf-binary-locations-refused))))

;;; Load the corrected guard

(asdf:load-system "dreyeck/catalog-topic-maps")
(check :guard-system-loaded (asdf:component-loaded-p "dreyeck/catalog-topic-maps"))

;;; Test A: ASDF's methods are the same objects, and the guard defined none of its own

(defvar *after-census* (census))
(defvar *guard-file* (namestring (translate-logical-pathname (asdf:system-relative-pathname "dreyeck" "dreyeck/src/catalog-topic-maps.lisp"))))
(defun added-methods ()
  "(generic-function-name qualifiers specializers file) of every method an ASDF generic function has now and had not before."
  (loop for (generic . methods) in *after-census*
        for before = (cdr (assoc generic *before-census*))
        append (loop for m in methods unless (member m before :test #'eq)
                     collect (list (sb-mop:generic-function-name generic) (sb-mop:method-qualifiers m)
                                   (mapcar (lambda (s) (if (typep s 'class) (class-name s) s)) (sb-mop:method-specializers m)) (method-file m)))))
;; Nothing of ASDF is removed or replaced: each method object ASDF had is still in its generic function. (Other libraries may
;; add methods of their own to ASDF's generic functions; they are listed, and none of them is the guard's.)
(dolist (entry *before-census*)
  (let ((after (cdr (assoc (car entry) *after-census*))))
    (check (format nil "every method of ~A is still the same object" (sb-mop:generic-function-name (car entry)))
           (every (lambda (m) (member m after :test #'eq)) (cdr entry)))))
(format t "~&Methods added to ASDF's generic functions by what was loaded, none replacing one:~%~{  ~S~%~}" (added-methods))
(check :nothing-added-by-the-guard (notany (lambda (m) (equal *guard-file* (fourth m))) (added-methods)))
(dolist (before *before-identities*)
  (let ((now (find (first before) (identity-methods) :key #'first :test #'string=)))
    (check (format nil "~A is the very method it was" (first before)) (eq (second before) (second now)))
    (check (format nil "~A is still defined in ASDF's file" (first before)) (equal (method-file (second before)) (method-file (second now))))))
(check :no-method-of-asdf-is-the-guards
       (notany (lambda (entry) (some (lambda (m) (equal *guard-file* (method-file m))) (cdr entry))) *after-census*))
(format t "~&Counts, for the record only (additions by other libraries grow them; the assertions compare the objects): operate ~D -> ~D, perform ~D -> ~D.~%"
        *before-operate-count* (length (sb-mop:generic-function-methods #'asdf:operate))
        *before-perform-count* (length (sb-mop:generic-function-methods #'asdf:perform)))

;;; Test B: ASDF behaves as it did

(defvar *after-behaviour* (behaviour :after))
(format t "~&behaviour after: ~S~%" *after-behaviour*)
(check :behaviour-identical-to-before (equal *before-behaviour* *after-behaviour*))

;;; Test C, the part that needs no Topic Maps: the refusal reads definitions and loads nothing

(let ((c-refuse (find-symbol "REFUSE-PROJECT-WORKSPACE" "DREYECK/CATALOG-TOPIC-MAPS"))
      (refused-condition (find-symbol "PROJECT-WORKSPACE-REFUSED" "DREYECK/CATALOG-TOPIC-MAPS")))
  (flet ((refused-p (name)
           (handler-case (progn (funcall c-refuse name) (format t "~&NOT REFUSED: ~A~%" name) nil)
             (error (c) (or (typep c refused-condition) (progn (format t "~&~A: unexpected ~A~%" name c) nil))))))
    (flet ((define (name depends-on)
             (let ((directory (merge-pathnames (format nil "~A/" name) *temp*)))
               (ensure-directories-exist directory)
               (with-open-file (s (merge-pathnames (format nil "~A.asd" name) directory) :direction :output)
                 (format s "(asdf:defsystem ~S :depends-on (~S))~%" name depends-on))
               (asdf:load-asd (merge-pathnames (format nil "~A.asd" name) directory)))))
      (define "preservation-probe-depending-on-project" "dreyeck/work/project")
      (define "preservation-probe-depending-indirectly" "preservation-probe-depending-on-project"))
    (let ((loaded (asdf:already-loaded-systems))
          (packages (loop for p in (list-all-packages) when (uiop:string-prefix-p "DREYECK/WORK/PROJECT" (package-name p)) collect p)))
      (check :project-workspace-refused (refused-p "dreyeck/work/project"))
      (check :project-workspace-tests-refused (refused-p "dreyeck/work/project/tests"))
      (check :dependent-refused (refused-p "preservation-probe-depending-on-project"))
      (check :indirect-dependent-refused (refused-p "preservation-probe-depending-indirectly"))
      (check :refusal-loaded-nothing (and (equal loaded (asdf:already-loaded-systems))
                                          (not (asdf:component-loaded-p "dreyeck/work/project"))
                                          (equal packages (loop for p in (list-all-packages) when (uiop:string-prefix-p "DREYECK/WORK/PROJECT" (package-name p)) collect p))))
      (check :page-attached-loader-refused (refused-p "dreyeck/page-attached-hyperdoc"))
      (check :loader-dependents-refused (and (refused-p "dreyeck/fedwiki-hyperdoc") (refused-p "dreyeck/local-fedwiki-page/activation-inspector")))
      (check :ordinary-systems-permitted (notany #'refused-p '("dreyeck/catalog" "dreyeck/catalog-application" "dreyeck/catalog-topic-maps" "uiop"
                                                                "dreyeck/work/topic-maps-ctm-review" "dreyeck/work/topic-maps-project-example"))))))

;;; Positive control: the check can fail. A method with a colliding identity, defined now, replaces ASDF's, and the same
;;; comparison sees it.
(let ((original (second (first *before-identities*))))
  (eval `(defmethod asdf:operate :before ((operation t) (component t) &key &allow-other-keys) nil))
  (let ((after (cdr (assoc #'asdf:operate (census)))))
    (check :control-collision-replaces-the-method (not (member original after :test #'eq)))
    (check :control-collision-is-seen (not (eq original (find-method #'asdf:operate '(:before) (list (find-class t) (find-class t)) nil))))))

(uiop:delete-directory-tree *temp* :validate t :if-does-not-exist :ignore)
(format t "~&ASDF-METHOD-PRESERVATION-PASS: ~D assertions; ASDF ~A methods unchanged by identity, behaviour equal before and after, a control collision is seen.~%"
        (length *checks*) (asdf:asdf-version))
