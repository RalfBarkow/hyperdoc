;;;; Focused smoke tests for interaction-net implementation seed
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-INTERACTION-NET-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun interaction-net-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun interaction-net-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun interaction-net-assert-signals (thunk condition-type message)
  (handler-case
      (progn
        (funcall thunk)
        (error "~A -- expected condition ~S" message condition-type))
    (condition (caught)
      (unless (typep caught condition-type)
        (error "~A -- expected ~S but got ~S"
               message condition-type (type-of caught)))
      t)))

(defun interaction-net-smoke-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun interaction-net-smoke-read-page (namestring)
  (uiop:read-file-string
   (interaction-net-smoke-relative-path namestring)))

(defun run-interaction-net-demo-plus-smoke-test ()
  (asdf:load-system :interaction-net)
  (multiple-value-bind (result steps trace)
      (interaction-net:demo-plus)
    (interaction-net-assert-equal
     3
     result
     "demo-plus must return 3 for 2 + 1")
    (interaction-net-assert-equal
     3
     steps
     "demo-plus must fire exactly 3 interactions for 2 + 1")
    (interaction-net-assert-equal
     3
     (length trace)
     "demo-plus trace must contain exactly 3 reduction steps")
    (interaction-net-assert-true
     (every #'interaction-net:reduction-step-p trace)
     "demo-plus trace entries must be inspectable reduction-step objects")))

(defun run-interaction-net-rule-validation-smoke-test ()
  (asdf:load-system :interaction-net)
  (let ((runtime (interaction-net:make-runtime)))
    (interaction-net:define-agent runtime 'a 0)
    (interaction-net:define-agent runtime 'b 0)
    (interaction-net:define-rule runtime 'a 'b (lambda (net left right)
                                                 (declare (ignore net left right))))
    (interaction-net-assert-signals
     (lambda ()
       (interaction-net:define-rule runtime 'a 'b (lambda (net left right)
                                                    (declare (ignore net left right)))))
     'interaction-net:duplicate-rule-error
     "define-rule must reject duplicate active-pair registration")
    (interaction-net-assert-signals
     (lambda ()
       (interaction-net:define-rule runtime 'a 'a (lambda (net left right)
                                                    (declare (ignore net left right)))))
     'interaction-net:same-symbol-rule-error
     "define-rule must reject same-symbol rules by default")
    (interaction-net-assert-signals
     (lambda ()
       (interaction-net:define-rule runtime 'a 'unknown-kind
                                    (lambda (net left right)
                                      (declare (ignore net left right)))))
     'interaction-net:unknown-agent-kind
     "define-rule must reject unknown agent kinds")))

(defun run-interaction-net-parse-and-interface-smoke-test ()
  (asdf:load-system :interaction-net)
  (let ((runtime (interaction-net:make-runtime)))
    (interaction-net:define-agent runtime 'zero 0)
    (interaction-net-assert-signals
     (lambda ()
       (interaction-net:parse-net
        runtime
        '((:agent z1 zero w)
          (:agent z2 zero w)
          (:agent z3 zero w))))
     'error
     "parse-net must error when a wire occurs more than twice")
    (let ((net (interaction-net:parse-net runtime '((:agent z zero result)))))
      (interaction-net-assert-signals
       (lambda ()
         (interaction-net:read-nat net 'missing))
       'error
       "read-nat must error on missing free endpoint")
      (interaction-net::detach-endpoint
       (interaction-net::net-free-endpoint net 'result))
      (interaction-net-assert-signals
       (lambda ()
         (interaction-net:read-nat net 'result))
       'error
       "read-nat must error on disconnected free endpoint"))))

(defun run-interaction-net-reduction-limit-smoke-test ()
  (asdf:load-system :interaction-net)
  (let ((runtime (interaction-net:make-runtime)))
    (interaction-net:define-agent runtime 'ping 0)
    (interaction-net:define-agent runtime 'pong 0)
    (interaction-net:define-rule
        runtime 'ping 'pong
        (lambda (net ping pong)
          (let ((new-ping (interaction-net::make-cell* (gensym "PING-") 'ping 0))
                (new-pong (interaction-net::make-cell* (gensym "PONG-") 'pong 0)))
            (interaction-net::kill-cell net ping)
            (interaction-net::kill-cell net pong)
            (interaction-net::install-cell net new-ping)
            (interaction-net::install-cell net new-pong)
            (interaction-net::connect-endpoints
             net
             (interaction-net::port-endpoint new-ping 0)
             (interaction-net::port-endpoint new-pong 0)))))
    (let ((net (interaction-net:parse-net runtime '((:agent p ping w)
                                                    (:agent q pong w)))))
      (interaction-net-assert-signals
       (lambda ()
         (interaction-net:reduce-net net :limit 5 :trace t))
       'interaction-net:reduction-limit-reached
       "reduce-net must signal reduction-limit-reached for nonterminating rewrites"))))

(defun run-interaction-net-figure9-list-smoke-test ()
  (asdf:load-system :interaction-net)
  (multiple-value-bind (result trace-object)
      (interaction-net:demo-append-figure9)
    (interaction-net-assert-equal
     '("P" "0" "L")
     (mapcar (lambda (item)
               (string-upcase (symbol-name item)))
             result)
     "Figure 9 list append demo must reduce to expected list order")
    (interaction-net-assert-true
     (interaction-net:reduction-trace-p trace-object)
     "Reducer must expose a structured reduction trace object")
    (interaction-net-assert-equal
     :normal-form
     (interaction-net:reduction-trace-status trace-object)
     "Figure 9 append demo must terminate in normal form")
    (interaction-net-assert-equal
     3
     (interaction-net:reduction-trace-total-steps trace-object)
     "Figure 9 append demo should fire 3 interactions")))

(defun run-interaction-net-doc-and-topic-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (interaction-net-assert-true
   (hyperbook:find-page hyperdoc::*hyperdoc*
                        "Lafont 1990 Interaction Nets"
                        :signal-error? t)
   "HyperDoc page Lafont 1990 Interaction Nets must resolve")
  (dolist (spec '((hyperdoc::lafont-1990-interaction-nets-source-topic
                   . "Lafont 1990 Interaction Nets source")
                  (hyperdoc::interaction-nets-topic
                   . "Interaction nets")
                  (hyperdoc::active-pair-topic
                   . "Active pair")
                  (hyperdoc::cells-and-pointers-runtime-topic
                   . "Cells and pointers runtime")
                  (hyperdoc::interaction-net-implementation-seed-topic
                   . "Interaction-net implementation seed")))
    (let* ((symbol (car spec))
           (title (cdr spec))
           (topic (funcall symbol)))
      (interaction-net-assert-equal
       title
       (hyperbook:title-of topic)
       (format nil "Topic title mismatch for ~A" symbol))
      (interaction-net-assert-true
       (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
       (format nil "Topics HyperBook must resolve ~A" title))))
  (let ((page-source
         (interaction-net-smoke-read-page
          "hyperdoc/Lafont 1990 Interaction Nets.html")))
    (interaction-net-assert-true
     (search "Implementation crosswalk" page-source :test #'char=)
     "Lafont page must include the implementation crosswalk section")
    (interaction-net-assert-true
     (search "Not yet implemented" page-source :test #'char=)
     "Lafont page must include an explicit not-yet-implemented section")
    (interaction-net-assert-true
     (search "cells + pointers + active-pair stack" page-source :test #'char=)
     "Lafont page must describe the cells/pointers/active-pair stack runtime hint")))

(defun run-interaction-net-smoke-tests ()
  (run-interaction-net-demo-plus-smoke-test)
  (run-interaction-net-rule-validation-smoke-test)
  (run-interaction-net-parse-and-interface-smoke-test)
  (run-interaction-net-reduction-limit-smoke-test)
  (run-interaction-net-figure9-list-smoke-test)
  (run-interaction-net-doc-and-topic-smoke-test)
  (format t "~&Interaction-net smoke tests passed.~%"))
