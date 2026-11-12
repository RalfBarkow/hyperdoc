;;;; Acceptance-only fresh loopback Inspector. No existing image, Catalog or service is used.
(asdf:load-system "dreyeck/source-snapshot")
(defparameter *candidate-verification*
  (dreyeck/source-snapshot:verify-snapshot-tree
   (uiop:ensure-directory-pathname (uiop:getenv "TOPIC_MAPS_CANDIDATE_ROOT"))
   (dreyeck/source-snapshot:find-snapshot-manifest "c446a8228017f405c3a2650ca893e9450ac7cd7b")))
(asdf:load-system "dreyeck/work/topic-maps-instance-of-export")
(asdf:load-system "dreyeck/work/topic-maps-conformance-planning")
(asdf:load-system "clog-moldable-inspector")
(defparameter *revision* (dreyeck/work/project:project-ctm-document))
(defparameter *statement*
  (dreyeck/work/topic-maps-instance-of-export:export-instance-of
   *revision*
   "tag:dreyeck.ch,2026:hyperdoc/page/dreyeck/work/reading/work-breakdown"
   "tag:dreyeck.ch,2026:hyperdoc/schema/hyperdoc-page"))
(defparameter *investigation*
  (dreyeck/work/topic-maps-conformance-planning:investigate-case
   (make-instance 'dreyeck/git:git-repository-checkout
                  :root #P"/workspace/topic-maps/" :root-source :acceptance-fixed-git-evidence)
   :include-template))
(defparameter *result* (dreyeck/work/topic-maps-conformance-planning:run-result *investigation*))
(defparameter *map-before* (dreyeck/inspector/tmdm:model-state
                          (dreyeck/work/topic-maps-instance-of-export:statement-map *statement*)))
(defparameter *eq-targets*
  (list (cons "STATEMENT" *statement*)
        (cons "ASSOCIATION" (dreyeck/work/topic-maps-instance-of-export:statement-association *statement*))
        (cons "INSTANCE" (dreyeck/work/topic-maps-instance-of-export:statement-instance *statement*))
        (cons "TYPE" (dreyeck/work/topic-maps-instance-of-export:statement-type *statement*))
        (cons "MAP" (dreyeck/work/topic-maps-instance-of-export:statement-map *statement*))
        (cons "REVISION" *revision*) (cons "INVESTIGATION" *investigation*) (cons "PLAN-RESULT" *result*)
        (cons "PLAN-TREE-0" (first (dreyeck/shop3:plan-trees-of *result*)))
        (cons "PLAN-TREE-1" (second (dreyeck/shop3:plan-trees-of *result*)))))
(assert (= 2 (length (dreyeck/shop3:plans-of *result*))))
(assert (eq :plan-only (dreyeck/shop3:execution-mode-of *result*)))
(clog:initialize
 (lambda (body)
   (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
   (let* ((inspector (clog-moldable-inspector::create-inspector body :pane-width "750px" :playground? nil))
          (probe (clog:create-button body :content "Probe actual pane EQ"))
          (open-statement (clog:create-button body :content "Open retained statement"))
          (open-plans (clog:create-button body :content "Open retained investigation"))
          (result (clog:create-div body :content "No probe" :html-id "eq-result")))
     (clog-moldable-inspector::create-pane inspector *statement* :select "Instance-of provenance")
     (clog:set-on-click probe
       (lambda (event)
         (declare (ignore event))
         (let* ((panes (clog-moldable-inspector::inspector-panes inspector))
                (pane (fset:lookup panes (1- (fset:size panes))))
                (object (clog-moldable-inspector::pane-object pane))
                (name (car (find object *eq-targets* :key #'cdr :test #'eq))))
           (assert (equal *map-before* (dreyeck/inspector/tmdm:model-state
                                      (dreyeck/work/topic-maps-instance-of-export:statement-map *statement*))))
           (setf (clog:text result) (format nil "EQ:~A; map unchanged; mode ~S" name
                                         (dreyeck/shop3:execution-mode-of *result*)))
           (format t "~&BROWSER-NATIVE-EQ ~A; unchanged map; :PLAN-ONLY~%" name) (finish-output))))
     (clog:set-on-click open-statement
       (lambda (event) (declare (ignore event))
         (clog-moldable-inspector::create-pane inspector *statement* :select "Instance-of provenance")))
     (clog:set-on-click open-plans
       (lambda (event) (declare (ignore event))
         (clog-moldable-inspector::create-pane inspector *investigation* :select "Investigation alternatives")))))
 :host "127.0.0.1" :port (parse-integer (uiop:getenv "ACCEPTANCE_INSPECTOR_PORT")))
(format t "~&ACCEPTANCE-INSPECTOR-READY~%") (finish-output)
(unwind-protect
     (loop repeat 3600 until (probe-file (uiop:getenv "ACCEPTANCE_INSPECTOR_STOP")) do (sleep .1))
  (clog:shutdown))
