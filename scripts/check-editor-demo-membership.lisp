;;;; Membership proof for the Original Wiki Editor demo (RalfBarkow/hyperdoc#12), in a fresh SBCL:
;;;;   1. Loading dreyeck/catalog gives exactly the 23 HyperBooks admitted at dreyeck.ch 19e824d, plus the demo, each once.
;;;;   2. With HYPERDOC_CATALOG_SYSTEM naming a further system, loaded as START-CATALOG loads it (ASDF:LOAD-SYSTEM), every one
;;;;      of those is still there once, and the system's own books are added, not substituted.
;;;;   3. Naming the demo again, as HYPERDOC_CATALOG_SYSTEM could, adds nothing.
;;;; The base list is frozen here on purpose: it is not read from dreyeck/tests/catalog-startup-smoke.lisp, which this change edits.
;;;; Starts no server and reads no Wiki site.
;;;;   sbcl --noinform --no-sysinit --no-userinit --non-interactive --load scripts/check-editor-demo-membership.lisp
(require :asdf)
;; As scripts/catalog-main.lisp: only the supplied registry trees, no personal ASDF configuration.
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path))
             collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :ignore-inherited-configuration))

(defparameter *base-commit* "19e824d326def8bc227101e2494500630f441953")
(defparameter *base-ids*
  '("asdf-systems" "dreyeck/authority/reading" "dreyeck/clog-tutorial/reading"
    "dreyeck/fedwiki-config/reading" "dreyeck/fedwiki-source-relations" "dreyeck/gesture/reading"
    "dreyeck/lisp-critic/reading" "dreyeck/lisp-image" "dreyeck/mech-intake/reading"
    "dreyeck/nested-actions/reading" "dreyeck/topicmap/tala/reading" "dreyeck/traverse/reading"
    "dreyeck/upstream-intake" "dreyeck/upstream-intake/temporal" "dreyeck/wiki-link"
    "dreyeck/work/reading" "dreyeck/workflow/reading" "hyperbook" "hyperdoc" "hyperdoc/explorer"
    "lisp-classes" "lisp-functions" "moldable-inspector")
  "+ADMITTED-HYPERBOOK-IDS+ of dreyeck/tests/catalog-startup-smoke.lisp at *BASE-COMMIT*.")
(defparameter *demo* "dreyeck/fedwiki-original-editor-demo")

(assert (= 23 (length *base-ids*) (length (remove-duplicates *base-ids* :test #'string=))))
(asdf:load-system "dreyeck/catalog")

(defun ids () (mapcar (uiop:find-symbol* "ID-OF" "HYPERBOOK") (funcall (uiop:find-symbol* "HYPERBOOKS-OF" "HYPERBOOK") (symbol-value (uiop:find-symbol* "*CATALOG*" "HYPERBOOK")))))
(defun once-each (wanted ids label)
  (dolist (id wanted)
    (let ((n (count id ids :test #'string=)))
      (unless (= 1 n) (error "~A: ~S occurs ~D times." label id n)))))

;; 1. The default Catalog: the base set, the demo, nothing else.
(let ((ids (ids)))
  (once-each (cons *demo* *base-ids*) ids "dreyeck/catalog")
  (let ((extra (set-difference ids (cons *demo* *base-ids*) :test #'string=)))
    (when extra (error "dreyeck/catalog has HyperBooks neither in the base set nor the demo: ~S" extra)))
  (format t "~&DEFAULT-CATALOG ~D HyperBooks: the ~D of ~A, each once, and ~A once; no other.~%"
          (length ids) (length *base-ids*) (subseq *base-commit* 0 7) *demo*))

;; 2. An additional system, as the service would name it.
(let ((system (let ((value (uiop:getenv "HYPERDOC_CATALOG_SYSTEM"))) (and value (plusp (length value)) value))))
  (when system
    (let ((before (ids)))
      (asdf:load-system system)
      (let* ((after (ids)) (added (set-difference after before :test #'string=)))
        (once-each before after (format nil "after loading ~A" system))
        (format t "~&WITH-CATALOG-SYSTEM ~A: ~D HyperBooks; the previous ~D kept once each; added ~S.~%"
                system (length after) (length before) added)))))

;; 3. The demo named again adds nothing.
(let ((before (ids)))
  (asdf:load-system *demo*)
  (unless (equal before (ids)) (error "Loading ~A again changed the Catalog." *demo*)))

(format t "~&EDITOR-DEMO-MEMBERSHIP-PASS~%")
