;;;; Catalog membership, in a fresh SBCL: the default Catalog is what the product declares, and what loading does to it.
;;;;   1. Loading dreyeck/catalog materializes what its ASDF closure and the DEFHYPERDOC forms of its systems declare: each book once, with
;;;;      its main page, and no HyperDoc that no declaration names (dreyeck/catalog/membership). No list of ids, no count, no base commit.
;;;;   2. The Original Wiki Editor demo, a declared member, is present once (regression of RalfBarkow/hyperdoc#12).
;;;;   3. With HYPERDOC_CATALOG_SYSTEM naming a further system, loaded as START-CATALOG loads it (ASDF:LOAD-SYSTEM), every member stays,
;;;;      once and as the same object, and the system's own books are added, not substituted; the added books are those its sources declare.
;;;;   4. Loading systems again, and evaluating a member's sources again, changes nothing; registering a second book under an id keeps the first.
;;;; The checkers themselves are first shown to detect faulty input (RUN-SELF-TESTS), so that passing means something.
;;;; Starts no server and reads no Wiki site.
;;;;   sbcl --noinform --no-sysinit --no-userinit --non-interactive --load scripts/check-catalog-membership.lisp
(require :asdf)
;; As scripts/catalog-main.lisp: only the supplied registry trees, no personal ASDF configuration.
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path))
             collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :ignore-inherited-configuration))

(asdf:load-system "dreyeck/catalog/membership/tests")

(defun m (name &rest arguments) (apply #'uiop:symbol-call :dreyeck/catalog/membership name arguments))
(uiop:symbol-call :dreyeck/catalog/membership/tests :run-self-tests)

;; 1. The default Catalog is what the product declares.
(let ((report (m :assert-membership :check-pages t)))
  (declare (ignore report))
  (format t "~&DEFAULT-CATALOG ~D HyperBooks, each once; every HyperDoc declared by the sources of dreyeck/catalog's systems is present with its main page, and no HyperDoc is present that no declaration names.~%"
          (length (m :catalog-ids))))

;; 2. The Original Wiki Editor demo: a declared member, once.
(m :assert-hyperbook-present "dreyeck/fedwiki-original-editor-demo")

;; 3. An additional system, as the service would name it.
(let ((system (let ((value (uiop:getenv "HYPERDOC_CATALOG_SYSTEM"))) (and value (plusp (length value)) value))))
  (when system
    (let* ((before (m :catalog-ids))
           (added (m :assert-additive :loader (lambda () (asdf:load-system system))))
           (declared-by-it (mapcar (lambda (entry) (getf entry :id))
                                   (m :source-hyperdocs (m :repository-systems (m :declared-systems system))))))
      (dolist (id added)
        (unless (member id declared-by-it :test #'string=)
          (error "~A added ~S, which no source of its closure declares." system id)))
      (format t "~&WITH-CATALOG-SYSTEM ~A: ~D HyperBooks; the previous ~D kept once each and as the same objects; added ~S.~%"
              system (length (m :catalog-ids)) (length before) added))))

;; 4. Again, and twice.
(m :assert-idempotent :loader (lambda () (m :load-systems (list "dreyeck/catalog" "dreyeck/fedwiki-original-editor-demo"))
                                 (m :load-systems (list "dreyeck/fedwiki-original-editor-demo") :reload-sources t)))
(m :assert-registration-keeps-first)

(format t "~&CATALOG-MEMBERSHIP-SCRIPT-PASS~%")
