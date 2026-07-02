;;;; Contract checks for FedWiki page-attached ASDF placement.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-PAGE-ATTACHED-ASDF-CONTRACT-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defparameter +page-attached-contract-site-root+
  #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/")

(defparameter +page-attached-contract-mcdermott-slug+
  "the-1998-ai-planning-systems-competition")

(defparameter +page-attached-contract-physics-slug+
  "physics-not-advice")

(defun page-attached-contract-assert-true (condition message)
  (unless condition
    (error "~A" message))
  condition)

(defun page-attached-contract-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun page-attached-contract-old-fedwiki-system-name (slug)
  (concatenate 'string "fedwiki/" "page/wiki.ralfbarkow.ch/" slug))

(defun page-attached-contract-old-hyperdoc-system-name (slug)
  (concatenate 'string "hyperdoc/" "page/" slug))

(defun page-attached-contract-mcdermott-home ()
  (hyperdoc:make-fedwiki-attached-asdf-system
   :slug +page-attached-contract-mcdermott-slug+
   :site-root +page-attached-contract-site-root+
   :system :the-1998-ai-planning-systems-competition
   :system-file +page-attached-contract-mcdermott-slug+
   :test-system :the-1998-ai-planning-systems-competition/test
   :package-name "THE-1998-AI-PLANNING-SYSTEMS-COMPETITION"))

(defun page-attached-contract-physics-home ()
  (hyperdoc:make-fedwiki-attached-asdf-system
   :slug +page-attached-contract-physics-slug+
   :site-root +page-attached-contract-site-root+
   :system :physics-not-advice
   :system-file +page-attached-contract-physics-slug+
   :test-system :physics-not-advice/test
   :package-name "PHYSICS-NOT-ADVICE"))

(defun page-attached-contract-page-pathname (slug)
  (merge-pathnames
   (format nil "pages/~A" slug)
   +page-attached-contract-site-root+))

(defun page-attached-contract-sqlite-pathname (home sqlite-file)
  (merge-pathnames
   sqlite-file
   (hyperdoc:fedwiki-page-asset-root home)))

(defun page-attached-contract-forbidden-asdf-names ()
  (list
   (page-attached-contract-old-fedwiki-system-name
    "mobile-progressive-chrome-in-hyperdoc")
   (page-attached-contract-old-fedwiki-system-name "shop3")
   (page-attached-contract-old-fedwiki-system-name
    +page-attached-contract-mcdermott-slug+)
   (page-attached-contract-old-fedwiki-system-name
    +page-attached-contract-physics-slug+)
   (page-attached-contract-old-hyperdoc-system-name
    "mobile-progressive-chrome")
   (page-attached-contract-old-hyperdoc-system-name
    "dm6-appembed-inline-proof")))

(defun run-page-attached-asdf-no-legacy-registry-symbols-smoke-test ()
  (let ((package (find-package :hyperdoc)))
    (dolist (name (list "*PAGE-SYSTEM-DEFAULT-ASDF-SYSTEMS*"
                        "ENSURE-DEFAULT-PAGE-SYSTEMS-REGISTERED"))
      (multiple-value-bind (symbol status)
          (find-symbol name package)
        (declare (ignore symbol))
        (page-attached-contract-assert-true
         (null status)
         (format nil "Legacy registry symbol must be absent: ~A" name))))))

(defun run-page-attached-asdf-no-legacy-asdf-systems-smoke-test ()
  (dolist (name (page-attached-contract-forbidden-asdf-names))
    (page-attached-contract-assert-true
     (null (asdf:find-system name nil))
     (format nil "Legacy ASDF system must not resolve: ~A" name))))

(defun run-page-attached-asdf-underlying-systems-smoke-test ()
  (dolist (name '("hyperdoc/mobile-progressive-chrome"
                  "hyperdoc/explorer"
                  "hyperdoc/fedwiki-asdf-assets"
                  "fedwiki"))
    (page-attached-contract-assert-true
     (asdf:find-system name nil)
     (format nil "Underlying real ASDF system must remain findable: ~A" name))))

(defun run-page-attached-asdf-mcdermott-layout-smoke-test ()
  (let* ((home (page-attached-contract-mcdermott-home))
         (entrypoint (hyperdoc:fedwiki-page-asdf-entrypoint home))
         (page-path (page-attached-contract-page-pathname
                     +page-attached-contract-mcdermott-slug+))
         (sqlite-path
           (page-attached-contract-sqlite-pathname
            home
            "the-1998-ai-planning-systems-competition.dmx.sqlite")))
    (page-attached-contract-assert-equal
     (merge-pathnames
      "assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.asd"
      +page-attached-contract-site-root+)
     entrypoint
     "McDermott ASDF entrypoint must be page-attached under assets/pages")
    (page-attached-contract-assert-true
     (probe-file entrypoint)
     "McDermott page-attached ASDF entrypoint must exist")
    (page-attached-contract-assert-true
     (probe-file sqlite-path)
     "McDermott attached SQLite asset must exist")
    (page-attached-contract-assert-true
     (probe-file page-path)
     "McDermott FedWiki page JSON must remain in the pages store")))

(defun run-page-attached-asdf-physics-layout-smoke-test ()
  (let* ((home (page-attached-contract-physics-home))
         (entrypoint (hyperdoc:fedwiki-page-asdf-entrypoint home))
         (page-path (page-attached-contract-page-pathname
                     +page-attached-contract-physics-slug+))
         (sqlite-path
           (page-attached-contract-sqlite-pathname
            home
            "physics-not-advice.dmx.sqlite")))
    (page-attached-contract-assert-equal
     (merge-pathnames
      "assets/pages/physics-not-advice/physics-not-advice.asd"
      +page-attached-contract-site-root+)
     entrypoint
     "Physics, Not Advice ASDF entrypoint must be page-attached under assets/pages")
    (page-attached-contract-assert-true
     (probe-file entrypoint)
     "Physics, Not Advice page-attached ASDF entrypoint must exist")
    (page-attached-contract-assert-true
     (probe-file sqlite-path)
     "Physics, Not Advice attached SQLite asset must exist")
    (page-attached-contract-assert-true
     (probe-file page-path)
     "Physics, Not Advice FedWiki page JSON must remain in the pages store")))

(defun run-page-attached-asdf-mcdermott-load-smoke-test ()
  (let* ((home (page-attached-contract-mcdermott-home))
         (loaded (hyperdoc:load-fedwiki-attached-asdf-system home :force nil)))
    (page-attached-contract-assert-true
     (typep loaded 'asdf:system)
     "McDermott page-attached ASDF system must load through the generic loader")
    (asdf:load-system "the-1998-ai-planning-systems-competition/test")
    (let ((report
            (uiop:symbol-call
             :the-1998-ai-planning-systems-competition/tests
             :run-smoke-tests)))
      (page-attached-contract-assert-true
       (getf report :ok)
       "McDermott page-attached smoke tests must pass")
      (page-attached-contract-assert-true
       (probe-file (getf report :db-path))
       "McDermott smoke report must point to an existing SQLite asset")
      (page-attached-contract-assert-equal
       nil
       (getf report :network-required-p)
       "McDermott materialization validation must not require live network"))))

(defun run-page-attached-asdf-physics-load-smoke-test ()
  (let* ((home (page-attached-contract-physics-home))
         (loaded (hyperdoc:load-fedwiki-attached-asdf-system home :force nil)))
    (page-attached-contract-assert-true
     (typep loaded 'asdf:system)
     "Physics, Not Advice page-attached ASDF system must load through the generic loader")
    (asdf:load-system "physics-not-advice/test")
    (let ((report
            (uiop:symbol-call :physics-not-advice/tests
                              :run-smoke-tests)))
      (page-attached-contract-assert-true
       (getf report :ok)
       "Physics, Not Advice page-attached smoke tests must pass")
      (page-attached-contract-assert-true
       (probe-file (getf report :db-path))
       "Physics, Not Advice smoke report must point to an existing SQLite asset")
      (page-attached-contract-assert-equal
       nil
       (getf report :network-required-p)
       "Physics, Not Advice materialization validation must not require live network"))))

(defun run-page-attached-asdf-contract-smoke-tests ()
  (run-page-attached-asdf-no-legacy-registry-symbols-smoke-test)
  (run-page-attached-asdf-no-legacy-asdf-systems-smoke-test)
  (run-page-attached-asdf-underlying-systems-smoke-test)
  (run-page-attached-asdf-mcdermott-layout-smoke-test)
  (run-page-attached-asdf-mcdermott-load-smoke-test)
  (run-page-attached-asdf-physics-layout-smoke-test)
  (run-page-attached-asdf-physics-load-smoke-test)
  (format t "~&FedWiki page-attached ASDF contract smoke tests passed.~%")
  t)
