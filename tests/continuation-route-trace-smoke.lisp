;;;; Smoke tests for the continuation route trace bridge

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-CONTINUATION-ROUTE-TRACE-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun continuation-route-smoke-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun continuation-route-smoke-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun continuation-route-smoke-plist-key-present-p (plist key)
  (loop for (plist-key nil) on plist by #'cddr
        thereis (eq plist-key key)))

(defun continuation-route-smoke-route ()
  (asdf:load-system :hyperdoc/continuation-route-trace :force t)
  (hyperdoc::make-continuation-route-trace-demo))

(defun run-continuation-route-trace-object-smoke-test ()
  (let ((route (continuation-route-smoke-route)))
    (continuation-route-smoke-assert-true
     (typep route 'hyperdoc::continuation-route)
     "Demo must produce a continuation route object")
    (continuation-route-smoke-assert-true
     (not (endp (hyperdoc::continuation-route-steps route)))
     "Route must have at least one route step")
    (continuation-route-smoke-assert-true
     (some (lambda (alternative)
             (and (continuation-route-smoke-plist-key-present-p
                   alternative :remembered-refusal)
                  (continuation-route-smoke-plist-key-present-p
                   alternative :alternate)))
           (hyperdoc::continuation-route-alternatives route))
     "Route must expose at least one remembered refusal or alternate")
    (continuation-route-smoke-assert-true
     (some (lambda (repair)
             (eq (hyperdoc::continuation-route-repair-continuation repair)
                 :failure-continuation))
           (hyperdoc::continuation-route-repairs route))
     "At least one failure continuation must become a route repair")
    (continuation-route-smoke-assert-true
     (search "Graham Closures and the NOR Graph Matcher"
             (prin1-to-string (hyperdoc::continuation-route-evidence route))
             :test #'char=)
     "Route must carry evidence back to the NOR closure demo/page")))

(defun run-continuation-route-trace-replay-smoke-test ()
  (let* ((route (continuation-route-smoke-route))
         (replay (hyperdoc::continuation-route-replay route))
         (pretty (hyperdoc::continuation-route-pretty-string route)))
    (continuation-route-smoke-assert-true
     (not (endp replay))
     "Route replay must return replay rows without re-running the matcher")
    (continuation-route-smoke-assert-equal
     (length (hyperdoc::continuation-route-steps route))
     (length replay)
     "Replay row count must match route step count")
    (continuation-route-smoke-assert-true
     (search "repair" pretty :test #'char-equal)
     "Pretty route output must include a visible repair")
    (continuation-route-smoke-assert-true
     (search "Route" pretty :test #'char=)
     "Pretty route output must include a route heading")))

(defun run-continuation-route-trace-page-smoke-test ()
  (asdf:load-system :hyperdoc/server)
  ;; In a long-lived image, HYPERDOC::*HYPERDOC* may already have loaded its
  ;; text-page catalog before this bridge page existed on disk.  Force a
  ;; rescan before looking up the newly added page.
  (hyperdoc::reload-text-pages hyperdoc::*hyperdoc*)
  (let ((page
          (hyperbook:find-page hyperdoc::*hyperdoc*
                               "From Remembered Refusals to Repairable Routes"
                               :signal-error? t))
        (source
          (uiop:read-file-string
           (asdf:system-relative-pathname
            :hyperdoc
            "hyperdoc/From Remembered Refusals to Repairable Routes.html"))))
    (continuation-route-smoke-assert-true
     (uiop:string-prefix-p "<h1>From Remembered Refusals to Repairable Routes</h1>" source)
     "Bridge page must start with the required h1")
    (dolist (needle '("Graham Closures and the NOR Graph Matcher"
                      "Planning Routes through Uncertain Territory"
                      "continuation-route-trace-demo-example"))
      (continuation-route-smoke-assert-true
       (search needle source :test #'char=)
       (format nil "Bridge page must include ~A" needle)))
    (continuation-route-smoke-assert-equal
     nil
     (hyperbook:lookup-issues-of page)
     "Bridge page must not introduce page-level lookup issues")))

(defun run-continuation-route-trace-smoke-tests ()
  (run-continuation-route-trace-object-smoke-test)
  (run-continuation-route-trace-replay-smoke-test)
  (run-continuation-route-trace-page-smoke-test)
  (format t "~&Continuation route trace smoke tests passed.~%")
  t)
