;;;; Smoke tests for inspector compile/load order safety

(in-package :hyperdoc/tests)

(defun compile-order-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun compile-order-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun compile-order-assert-search (needle haystack message)
  (compile-order-assert-true
   (not (null (search needle haystack :test #'char=)))
   (format nil "~A -- missing substring ~S" message needle)))

(defun compile-order-assert-before (text left right message)
  (let ((left-pos (search left text :test #'char=))
        (right-pos (search right text :test #'char=)))
    (compile-order-assert-true
     left-pos
     (format nil "~A -- left marker missing: ~S" message left))
    (compile-order-assert-true
     right-pos
     (format nil "~A -- right marker missing: ~S" message right))
    (compile-order-assert-true
     (< left-pos right-pos)
     (format nil "~A -- expected ~S before ~S" message left right))))

(defun compile-order-system-definition-source ()
  (uiop:read-file-string
   (asdf:system-relative-pathname :hyperdoc "hyperdoc.asd")))

(defun run-hyperdoc-inspector-asd-order-smoke-test ()
  (let ((source (compile-order-system-definition-source)))
    (compile-order-assert-search
     "(defsystem #:hyperdoc/inspector"
     source
     "hyperdoc.asd must define the hyperdoc/inspector system")
    (compile-order-assert-before
     source
     "(:file \"package\")"
     "(:file \"code-path-graphs\")"
     "Inspector package must load before inspector implementation files")
    (compile-order-assert-before
     source
     "(:file \"code-path-graphs\")"
     "(:file \"state-machines\")"
     "Code-path graphs must load before state-machines in the current inspector contract")
    (compile-order-assert-before
     source
     "(:file \"state-machines\")"
     "(:file \"dmx-topics\")"
     "State-machine helpers must load before dmx-topics")
    (compile-order-assert-before
     source
     "(:file \"surfaces\")"
     "(:file \"dmx-topics\")"
     "Surface helpers must load before dmx-topics")
    (compile-order-assert-before
     source
     "(:file \"boundaries\")"
     "(:file \"dmx-topics\")"
     "Boundary helpers must load before dmx-topics"))
  t)

(defun run-fresh-inspector-compile-smoke-test ()
  ;; The practical safety contract is:
  ;; 1. explorer loads and provides make-code-page-source-navigation
  ;; 2. inspector then compiles/loads cleanly on top of that image
  ;; 3. the new DMX repair auth state-machine helpers are fbound afterwards
  (asdf:load-system :hyperdoc/explorer :force t)
  (compile-order-assert-true
   (fboundp 'hyperdoc::make-code-page-source-navigation)
   "Explorer load must provide HYPERDOC::MAKE-CODE-PAGE-SOURCE-NAVIGATION before inspector compilation")

  (asdf:compile-system :hyperdoc/inspector :force t)
  (asdf:load-system :hyperdoc/inspector :force t)

  (compile-order-assert-true
   (find-package :hyperdoc/inspector)
   "Fresh inspector load must create package HYPERDOC/INSPECTOR")

  (compile-order-assert-true
   (fboundp 'hyperdoc/inspector::make-dmx-repair-auth-state-machine-definition)
   "Inspector load must provide MAKE-DMX-REPAIR-AUTH-STATE-MACHINE-DEFINITION")

  (compile-order-assert-true
   (fboundp 'hyperdoc/inspector::make-dmx-repair-auth-state-machine-run)
   "Inspector load must provide MAKE-DMX-REPAIR-AUTH-STATE-MACHINE-RUN")

  (compile-order-assert-true
   (fboundp 'hyperdoc::make-state-machine-definition)
   "Core HyperDoc state-machine constructor must be available")

  (compile-order-assert-true
   (fboundp 'hyperdoc::make-state-machine-run)
   "Core HyperDoc state-machine run constructor must be available")

  t)

(defun run-compile-order-smoke-tests ()
  (run-hyperdoc-inspector-asd-order-smoke-test)
  (run-fresh-inspector-compile-smoke-test)
  (format t "~&Compile-order smoke tests passed.~%")
  t)