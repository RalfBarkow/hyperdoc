;;;; Verification harness only: fresh process, loopback Inspector, no existing image.
(asdf:load-system "dreyeck/work/acceptance-evidence-chain")
(asdf:load-system "clog-moldable-inspector")
(defpackage #:acceptance-evidence-browser-check
  (:use #:cl)
  (:local-nicknames (#:c #:dreyeck/work/acceptance-evidence-chain)
                    (#:g #:dreyeck/git) (#:ev #:dreyeck/evaluation-record)))
(in-package #:acceptance-evidence-browser-check)

(defparameter *repository*
  (make-instance 'g:git-repository-checkout
                 :root (uiop:ensure-directory-pathname (uiop:getenv "DEFEDERATION_REPO"))
                 :root-source :isolated-browser-check))
(defparameter *chain* (c:inspect-acceptance-evidence-chain *repository*))
(defparameter *targets*
  (list (cons "CHAIN" *chain*)
        (cons "REPORT-FILE" (c:chain-report-file *chain*))
        (cons "LOG-FILE" (c:chain-log-file *chain*))
        (cons "EVIDENCE-REVISION" (c:chain-source-revision *chain*))
        (cons "PARSED-REPORT" (c:chain-report *chain*))
        (cons "SPECIFIED-REVISION" (c:chain-tested-revision *chain*))
        (cons "DESCRIPTOR-FILE" (c:chain-descriptor-file *chain*))))
(defparameter *annotation-before* (copy-tree (ev:evaluation-annotation-of *chain*)))
(defparameter *statements-before* (c:chain-statements *chain*))

(defun check-invariants ()
  (assert (eq :inspected (ev:evaluation-status-of *chain*)))
  (assert (equal *annotation-before* (ev:evaluation-annotation-of *chain*)))
  (assert (eq :none (getf *annotation-before* :acceptance-decision)))
  (assert (eq :not-established (getf *annotation-before* :historical-execution-revision-binding)))
  (assert (eq :not-assessed (getf *annotation-before* :independent-author-review)))
  (assert (eq :none (getf *annotation-before* :deployment-authority)))
  (assert (eq *statements-before* (c:chain-statements *chain*)))
  (assert (not (nth-value 1 (gethash "testedRevision" (c:chain-report *chain*)))))
  (assert (= 121067 (c:chain-log-octets *chain*)))
  (assert (equal "2f9276424cd418cfe55db57a22cbfb542115659d1b98f390a3d0aacd1fa24adf"
                 (c:chain-log-sha256 *chain*)))
  (dolist (file (list (c:chain-report-file *chain*) (c:chain-log-file *chain*)
                     (c:chain-descriptor-file *chain*)))
    (assert (eq (c:chain-source-revision *chain*) (g:git-file-commit-of file)))
    (assert (eq file (g:ensure-git-evidence-file (c:chain-source-revision *chain*)
                                               (g:git-file-path-of file)))))
  t)
(check-invariants)

(clog:initialize
 (lambda (body)
   (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
   (let* ((inspector (clog-moldable-inspector::create-inspector
                      body :pane-width "800px" :playground? nil))
          (probe (clog:create-button body :content "Probe actual pane EQ"))
          (result (clog:create-div body :content "No probe" :html-id "eq-result")))
     (clog-moldable-inspector::create-pane inspector *chain* :select "Evidence chain")
     (clog:set-on-click
      probe
      (lambda (event)
        (declare (ignore event))
        (check-invariants)
        (let* ((panes (clog-moldable-inspector::inspector-panes inspector))
               (pane (fset:lookup panes (1- (fset:size panes))))
               (object (clog-moldable-inspector::pane-object pane))
               (name (car (find object *targets* :key #'cdr :test #'eq))))
          (assert name)
          (setf (clog:text result)
                (format nil "EQ:~A; :INSPECTED; revision binding :NOT-ESTABLISHED; acceptance :NONE" name))
          (format t "~&BROWSER-NATIVE-EQ ~A; invariant checks hold~%" name)
          (finish-output))))))
 :host "127.0.0.1" :port (parse-integer (uiop:getenv "EVIDENCE_INSPECTOR_PORT")))
(format t "~&EVIDENCE-INSPECTOR-READY~%")
(finish-output)
(unwind-protect
     (loop repeat 3000 until (probe-file (uiop:getenv "EVIDENCE_INSPECTOR_STOP")) do (sleep .1))
  (check-invariants)
  (clog:shutdown))
