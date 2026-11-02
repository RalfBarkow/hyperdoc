;;;; Membership proof for the "Reading a Wiki Page Without DNS" demo, in a fresh SBCL:
;;;;   1. The default Catalog (dreyeck/catalog) is the 23 HyperBooks admitted at dreyeck.ch 19e824d plus the Original Wiki Editor demo, each once,
;;;;      and the without-DNS demo is neither among them nor among the dependencies of dreyeck/catalog.
;;;;   2. Naming the demo, as HYPERDOC_CATALOG_SYSTEM does (ASDF:LOAD-SYSTEM), adds exactly its own id; every HyperBook before is still there once.
;;;;   3. Naming it again adds nothing.
;;;; Starts no server, reads no wiki site and makes no network connection.
;;;;   sbcl --noinform --no-sysinit --no-userinit --non-interactive --load scripts/check-without-dns-demo-membership.lisp
(require :asdf)
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path))
             collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :ignore-inherited-configuration))

(defparameter *base-ids*
  '("asdf-systems" "dreyeck/authority/reading" "dreyeck/clog-tutorial/reading"
    "dreyeck/fedwiki-config/reading" "dreyeck/fedwiki-source-relations" "dreyeck/gesture/reading"
    "dreyeck/lisp-critic/reading" "dreyeck/lisp-image" "dreyeck/mech-intake/reading"
    "dreyeck/nested-actions/reading" "dreyeck/topicmap/tala/reading" "dreyeck/traverse/reading"
    "dreyeck/upstream-intake" "dreyeck/upstream-intake/temporal" "dreyeck/wiki-link"
    "dreyeck/work/reading" "dreyeck/workflow/reading" "hyperbook" "hyperdoc" "hyperdoc/explorer"
    "lisp-classes" "lisp-functions" "moldable-inspector" "dreyeck/fedwiki-original-editor-demo")
  "The default Catalog at dreyeck.ch 0a7d4de: the 23 admitted at 19e824d and the Original Wiki Editor demo.")
(defparameter *demo* "dreyeck/fedwiki-without-dns-demo")

(assert (= 24 (length *base-ids*) (length (remove-duplicates *base-ids* :test #'string=))))
(asdf:load-system "dreyeck/catalog")

(defun ids () (mapcar (uiop:find-symbol* "ID-OF" "HYPERBOOK") (funcall (uiop:find-symbol* "HYPERBOOKS-OF" "HYPERBOOK") (symbol-value (uiop:find-symbol* "*CATALOG*" "HYPERBOOK")))))
(defun count-of (id ids) (count id ids :test #'string=))
(defun dependency-closure (name)
  (let ((seen '()))
    (labels ((walk (system-name)
               (unless (member system-name seen :test #'string=)
                 (push system-name seen)
                 (let ((system (asdf:find-system system-name nil)))
                   (when system
                     (dolist (dependency (asdf:system-depends-on system))
                       (let ((name (typecase dependency
                                     (string dependency)
                                     (cons (case (first dependency) (:version (second dependency)) (:feature (third dependency)))))))
                         (when (stringp name) (walk name)))))))))
      (walk name))
    seen))

;; 1. The default Catalog
(let ((ids (ids)))
  (dolist (id *base-ids*) (unless (= 1 (count-of id ids)) (error "default Catalog: ~S occurs ~D times." id (count-of id ids))))
  (when (set-difference ids *base-ids* :test #'string=) (error "default Catalog has further HyperBooks: ~S" (set-difference ids *base-ids* :test #'string=)))
  (when (find *demo* ids :test #'string=) (error "~A is in the default Catalog." *demo*))
  (when (member *demo* (dependency-closure "dreyeck/catalog") :test #'string=) (error "~A is a dependency of dreyeck/catalog." *demo*))
  (format t "~&DEFAULT-CATALOG ~D HyperBooks, each once; ~A is not among them and not a dependency.~%" (length ids) *demo*))

;; 2. Named explicitly
(let ((before (ids)))
  (asdf:load-system *demo*)
  (let* ((after (ids)) (added (set-difference after before :test #'string=)))
    (dolist (id before) (unless (= 1 (count-of id after)) (error "after loading ~A: ~S occurs ~D times." *demo* id (count-of id after))))
    (unless (equal added (list *demo*)) (error "loading ~A added ~S, not exactly itself." *demo* added))
    (format t "~&WITH-DEMO ~D HyperBooks: the previous ~D once each; added ~S.~%" (length after) (length before) added)))

;; 3. Again
(let ((before (ids)))
  (asdf:load-system *demo*)
  (unless (equal before (ids)) (error "Loading ~A again changed the Catalog." *demo*)))

(format t "~&WITHOUT-DNS-DEMO-MEMBERSHIP-PASS~%")
