;;;; From a work status change request to a checked HTML effect.
;;;; Every write here goes to a copy of Work Breakdown in a temporary
;;;; HyperDoc; the repository's pages are compared before and after.
(defpackage #:dreyeck/work/authoring/tests
  (:use #:cl)
  (:local-nicknames (#:a #:dreyeck/work/authoring)
                    (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap)
                    (#:r #:dreyeck/gesture/operation-request)
                    (#:ops #:dreyeck/work/operation-requests)
                    (#:m #:dreyeck/inspector/topicmap)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:gt #:dreyeck/topicmap/gesture/tests)
                    (#:views #:html-inspector-views))
  (:export #:run-tests))

(in-package #:dreyeck/work/authoring/tests)

(defun %read (path) (uiop:read-file-string path :external-format :utf-8))

(defun %write (path text)
  "Test-only: put TEXT in a fixture file, as a concurrent editor would."
  (with-open-file (stream path :direction :output :if-exists :supersede
                               :if-does-not-exist :create :external-format :utf-8)
    (write-string text stream)))

(defun replace-once (string old new)
  "STRING with its one occurrence of OLD replaced; a fixture edit that misses fails."
  (let ((start (search old string)))
    (assert start () "Fixture text ~S is absent." old)
    (assert (not (search old string :start2 (1+ start))) () "Fixture text ~S is ambiguous." old)
    (concatenate 'string (subseq string 0 start) new (subseq string (+ start (length old))))))

(defun work-page-sources ()
  "Every authored Work page file with its contents, to show nothing wrote them."
  (mapcar (lambda (file) (cons file (%read file)))
          (uiop:directory-files (asdf:system-relative-pathname "dreyeck" "dreyeck/pages/work/"))))

(defun call-with-work-breakdown-fixture (function)
  "FUNCTION called with the Work Breakdown page of a temporary HyperDoc, made
by HyperDoc's own constructor, whose one page is a copy of the real one, and
with that page's file. The system and its directory are removed afterwards."
  (let* ((root (merge-pathnames (format nil "work-authoring-probe-~D-~D/"
                                        (get-universal-time) (random 100000))
                                (uiop:temporary-directory)))
         (asd (merge-pathnames "work-authoring-probe.asd" root))
         (path (merge-pathnames "pages/Work Breakdown.html" root)))
    (ensure-directories-exist path)
    (unwind-protect
         (progn
           (%write asd "(defsystem \"work-authoring-probe\")
")
           (%write path (%read (hyperdoc:file-of (work:work-page "Work Breakdown"))))
           (asdf:load-asd asd)
           (let ((book (hyperdoc:make-hyperdoc :id "work-authoring-probe"
                                               :title "Work authoring probe"
                                               :asdf-system-name "work-authoring-probe"
                                               :subdirectory "pages")))
             (funcall function (hyperbook:find-page book "Work Breakdown" :signal-error? t) path)))
      (ignore-errors (asdf:clear-system "work-authoring-probe"))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(defun %project (page path)
  (work:project-work-breakdown (%read path) :source page))

(defun %status (projection id)
  (getf (tm:topicmap-topic-view-properties-of (tm:topicmap-projection-topic-by-id projection id))
        :status))

(defun %request (page path &optional (proposed "in progress"))
  (work:request-work-status-change
   (tm:topicmap-projection-topic-by-id (%project page path) "hyperdoc-page-authoring")
   proposed))

(defun plan-refusal (thunk)
  (handler-case (progn (funcall thunk) (error "Expected a plan refusal."))
    (a:work-status-change-plan-refused (condition) condition)))

(defun apply-refusal (thunk)
  (handler-case (progn (funcall thunk) (error "Expected an apply refusal."))
    (a:work-status-change-apply-refused (condition) condition)))

(defun %candidates (path)
  "Sibling files a writer left behind."
  (directory (make-pathname :name :wild :type "candidate" :defaults path)))

(defun %moved (source request)
  "SOURCE with the request's declaration moved elsewhere on the page."
  (let* ((occurrence (work:work-status-change-occurrence request))
         (range (work:topic-occurrence-element-range occurrence))
         (element (subseq source (car range) (cdr range))))
    (replace-once (replace-once source element "Structural HyperDoc Page Authoring")
                  "<h2>Relation contracts</h2>"
                  (concatenate 'string "<p>" element "</p><h2>Relation contracts</h2>"))))

(defun check-planning (page path)
  "A valid request plans and writes nothing; a stale request, or a status the
plain data-status representation does not admit, plans nothing."
  (let* ((source (%read path))
         (request (%request page path))
         (occurrence (work:work-status-change-occurrence request))
         (plan (a:plan-work-status-change request))
         (range (a:work-status-change-plan-status-range plan))
         (tag (work:topic-occurrence-start-tag-range occurrence)))
    (assert (eq request (a:work-status-change-plan-request plan)))
    (assert (eq (work:topic-occurrence-snapshot occurrence) (a:work-status-change-plan-snapshot plan)))
    (assert (<= (car tag) (car range) (cdr range) (cdr tag)))
    (assert (equal "open" (subseq source (car range) (cdr range))))
    (assert (string= source (%read path)))
    ;; The plan says where and what, and that nothing was applied.
    (let* ((view (find "Work status change plan" (views:all-views plan)
                       :key #'views:view-title :test #'equal))
           (html (views:view-html view)))
      (assert view)
      (dolist (text '("Declaring page" "Status value" "Applied" "no -- a plan writes nothing"))
        (assert (search text html) () "The plan view lacks ~S." text))
      (assert (member request (mapcar #'cdr (views:view-references view)) :test #'eq)))
    ;; A request may propose any other status; this representation does not
    ;; admit every one.
    (dolist (proposed '("in \"progress\"" "in progress & review" "in <progress>"))
      (let* ((request (%request page path proposed))
             (condition (plan-refusal (lambda () (a:plan-work-status-change request)))))
        (assert (equal proposed (work:work-status-change-proposed-status request)))
        (assert (search "is not admitted in the plain, unescaped data-status representation"
                        (a:work-status-change-plan-refused-reason condition)))))
    (assert (string= source (%read path)))
    ;; A stale request plans nothing: the page changed elsewhere, or its
    ;; declaration moved. Nothing relocates by Topic ID.
    (dolist (current (list (replace-once source "This page is the current work map"
                                         "This page is the present work map")
                           (%moved source request)))
      (%write path current)
      (let ((condition (plan-refusal (lambda () (a:plan-work-status-change request)))))
        (assert (search "no longer holds" (a:work-status-change-plan-refused-reason condition)))
        (assert (typep (a:work-status-change-plan-refused-cause condition) 'work:work-status-change-refused)))
      (assert (string= current (%read path))))
    (%write path source)
    (assert (null (%candidates path)))))

(defun check-stale-plans (page path)
  "A plan applies only to its own snapshot: a change anywhere between planning
and applying refuses, and nothing is written."
  (let* ((source (%read path))
         (request (%request page path))
         (plan (a:plan-work-status-change request))
         (range (a:work-status-change-plan-status-range plan))
         (elsewhere (replace-once source "This page is the current work map"
                                  "This page is the present work map")))
    ;; The declaration stays at the same offset; the page is still other.
    (assert (= (length source) (length elsewhere)))
    (assert (equal "open" (subseq elsewhere (car range) (cdr range))))
    (dolist (current (list elsewhere (%moved source request)))
      (%write path current)
      (let ((condition (apply-refusal (lambda () (a:apply-work-status-change plan)))))
        (assert (search "not the plan's snapshot" (a:work-status-change-apply-refused-reason condition))))
      (assert (string= current (%read path)))
      (assert (null (%candidates path))))
    (%write path source)))

(defun check-hand-built-plans (page path)
  "APPLY does not trust that a plan came from the planner: a plan built by hand
for a status the plain data-status representation does not admit is refused
before anything is installed, and the page is left byte for byte as it was."
  (let* ((source (%read path))
         (valid (a:plan-work-status-change (%request page path))))
    (dolist (proposed '("in \"progress\"" "in progress & review" "in <progress>"))
      (let* ((request (%request page path proposed))
             (plan (make-instance 'a:work-status-change-plan
                                  :request request
                                  :snapshot (work:topic-occurrence-snapshot
                                             (work:work-status-change-occurrence request))
                                  :status-range (a:work-status-change-plan-status-range valid)))
             (condition (apply-refusal (lambda () (a:apply-work-status-change plan)))))
        (assert (search "is not admitted in the plain, unescaped data-status representation"
                        (a:work-status-change-apply-refused-reason condition)))
        (assert (string= source (%read path)))
        (assert (null (%candidates path)))))
    ;; The loaded page was not reloaded from anything new.
    (let ((anchor (find "hyperdoc-page-authoring"
                        (plump:get-elements-by-tag-name (hyperbook:dom-of page) "a")
                        :key (lambda (node) (plump:attribute node "data-topic")) :test #'equal)))
      (assert (equal "open" (plump:attribute anchor "data-status"))))))

(defun check-applying (page path)
  "Applied once, the plan changes exactly the status value, the page and its
projection show exactly the intended change, and it cannot be applied again."
  (let* ((pages (work-page-sources))
         (source (%read path))
         (request (%request page path))
         (plan (a:plan-work-status-change request))
         (range (a:work-status-change-plan-status-range plan))
         (topic (a:apply-work-status-change plan))
         (written (%read path))
         (end (+ (car range) (length "in progress"))))
    ;; The source delta is exact.
    (assert (string= source written :end1 (car range) :end2 (car range)))
    (assert (string= "in progress" written :start2 (car range) :end2 end))
    (assert (string= source written :start1 (cdr range) :start2 end))
    (assert (= (length written) (+ (length source) (- end (cdr range)))))
    (assert (null (%candidates path)))
    ;; The reconstructed delta is exact.
    (let ((before (work:project-work-breakdown source :source page))
          (after (%project page path)))
      (assert (equal "open" (%status before "hyperdoc-page-authoring")))
      (assert (equal "in progress" (%status after "hyperdoc-page-authoring")))
      (assert (equal "open" (%status after "lisp-source-authoring")))
      (loop for was in (tm:topicmap-projection-topics-of before)
            for is in (tm:topicmap-projection-topics-of after)
            do (assert (equal (tm:topicmap-topic-id-of was) (tm:topicmap-topic-id-of is)))
               (assert (eq (tm:topicmap-topic-object-of was) (tm:topicmap-topic-object-of is)))
               (assert (equal (tm:topicmap-topic-label-of was) (tm:topicmap-topic-label-of is)))
               (unless (equal "hyperdoc-page-authoring" (tm:topicmap-topic-id-of was))
                 (assert (equal (tm:topicmap-topic-view-properties-of was)
                                (tm:topicmap-topic-view-properties-of is)))))
      (assert (equal (mapcar #'tm:topicmap-association-id-of (tm:topicmap-projection-associations-of before))
                     (mapcar #'tm:topicmap-association-id-of (tm:topicmap-projection-associations-of after)))))
    ;; What APPLY returns is the Topic as the written page declares it.
    (assert (equal "hyperdoc-page-authoring" (tm:topicmap-topic-id-of topic)))
    (assert (equal "in progress" (getf (tm:topicmap-topic-view-properties-of topic) :status)))
    (assert (string= written (work:topic-occurrence-snapshot (work:topic-source-occurrence topic))))
    (assert (eq page (work:topic-occurrence-page (work:topic-source-occurrence topic))))
    ;; The page object already loaded now shows the written source.
    (let ((anchor (find "hyperdoc-page-authoring"
                        (plump:get-elements-by-tag-name (hyperbook:dom-of page) "a")
                        :key (lambda (node) (plump:attribute node "data-topic")) :test #'equal)))
      (assert (equal "in progress" (plump:attribute anchor "data-status"))))
    (assert (eq page (hyperbook:find-page (hyperbook:hyperbook-of page) "Work Breakdown")))
    ;; No replay: the plan's snapshot is gone, and so is the request's.
    (let ((condition (apply-refusal (lambda () (a:apply-work-status-change plan)))))
      (assert (search "not the plan's snapshot" (a:work-status-change-apply-refused-reason condition))))
    (assert (search "no longer holds"
                    (a:work-status-change-plan-refused-reason
                     (plan-refusal (lambda () (a:plan-work-status-change request))))))
    (assert (string= written (%read path)))
    ;; The written page is where the next request starts.
    (assert (equal "in progress" (work:work-status-change-observed-status (%request page path "open"))))
    ;; The repository's own pages were never written.
    (assert (equal pages (work-page-sources)))))

(defun %view (object title)
  (let ((view (find title (views:all-views object) :key #'views:view-title :test #'equal)))
    (when view (views:view-html view))
    view))

(defun %buttons (view)
  "Each eval button of VIEW as (LABEL . THUNK), read from its rendered HTML."
  (let ((html (views:view-html view)))
    (loop for (id . thunk) in (views:view-references view)
          when (eql 0 (search "eval-" id))
            collect (let* ((start (+ (search (format nil "id='~A'" id) html) (length id) 6))
                           (open (1+ (position #\> html :start start)))
                           (close (search "</button>" html :start2 open)))
                      (cons (plump:decode-entities (subseq html open close)) thunk)))))

(defun %no-actions-p (view)
  (notany (lambda (entry) (or (eql 0 (search "action-" (car entry))) (eql 0 (search "eval-" (car entry)))))
          (views:view-references view)))

(defun check-authoring-circle (page path)
  "From a Work Topic at a Workspace Point, in an image holding the pinned
authoring environment: the Change work status view offers values observed on
the page, one action carries the request through plan and apply, and request,
plan, source, reloaded page and projected Topic stay inspectably connected."
  (let* ((pages (work-page-sources))
         (source (%read path))
         (projection (%project page path))
         (topic (tm:topicmap-projection-topic-by-id projection "hyperdoc-page-authoring"))
         (workspace (tm:make-topicmap-workspace projection "hyperdoc-page-authoring"))
         (point (copy-seq (tm:topicmap-workspace-point-of workspace)))
         (view (%view workspace "Change work status"))
         (html (views:view-html view))
         (buttons (%buttons view)))
    ;; The Workspace and the Topic itself offer the same actions.
    (assert view)
    (assert (equal (mapcar #'car buttons) (mapcar #'car (%buttons (%view topic "Change work status")))))
    ;; Offered values are values observed on the page, not a lifecycle.
    (assert (member "Change work status to \"in progress\"" (mapcar #'car buttons) :test #'equal))
    (assert (notany (lambda (label) (search "\"open\"" label)) (mapcar #'car buttons)))
    (assert (= (length buttons) (length (remove-duplicates (mapcar #'car buttons) :test #'equal))))
    (dolist (text '("allowed" "valid transition" "Allowed" "Valid transition"))
      (assert (null (search text html)) () "The action view says ~S." text))
    (assert (search "does not mean the change is permitted, recommended, or part of a lifecycle" html))
    (assert (member topic (mapcar #'cdr (views:view-references view)) :test #'eq))
    ;; Without the pinned authoring environment: refused, no plan, no write.
    (let ((outcome (a:execute-work-status-change (work:request-work-status-change topic "in progress") nil)))
      (assert (eq :refused (a:work-status-change-outcome-status outcome)))
      (assert (null (a:work-status-change-outcome-plan outcome)))
      (assert (typep (a:work-status-change-outcome-cause outcome) 'a:work-status-change-execution-refused))
      (assert (string= source (%read path))))
    ;; The action: selection, request, plan, authorised apply, and the
    ;; outcome to open.
    (let* ((selection (ops:work-topic-operation-request (w:change-work-status-operation) topic))
           (outcome (views:eval-thunk (cdr (assoc "Change work status to \"in progress\"" buttons :test #'equal))))
           (request (a:work-status-change-outcome-request outcome))
           (plan (a:work-status-change-outcome-plan outcome))
           (now (a:work-status-change-outcome-topic outcome)))
      (assert (typep outcome 'a:work-status-change-outcome))
      (assert (eq :applied (a:work-status-change-outcome-status outcome)))
      (assert (null (a:work-status-change-outcome-cause outcome)))
      ;; The request completed the shared selection, for the Topic its
      ;; declaration declares.
      (assert (eq selection (a:work-status-change-outcome-selection outcome)))
      (assert (equal (tm:topicmap-topic-id-of topic)
                     (tm:topicmap-topic-id-of (work:work-status-change-topic request))))
      (assert (string= (work:topic-occurrence-snapshot (work:topic-source-occurrence topic))
                       (work:topic-occurrence-snapshot (work:work-status-change-occurrence request))))
      (assert (equal (work:topic-occurrence-element-range (work:topic-source-occurrence topic))
                     (work:topic-occurrence-element-range (work:work-status-change-occurrence request))))
      (assert (equal "open" (work:work-status-change-observed-status request)))
      (assert (equal "in progress" (work:work-status-change-proposed-status request)))
      (assert (eq request (a:work-status-change-plan-request plan)))
      ;; The source changed, the same page object shows it, and the Topic
      ;; read from the written page has the new status.
      (assert (not (string= source (%read path))))
      (assert (equal "in progress" (%status (%project page path) "hyperdoc-page-authoring")))
      (assert (equal "hyperdoc-page-authoring" (tm:topicmap-topic-id-of now)))
      (assert (equal "in progress" (getf (tm:topicmap-topic-view-properties-of now) :status)))
      (assert (eq page (work:topic-occurrence-page (work:topic-source-occurrence now))))
      (let ((anchor (find "hyperdoc-page-authoring" (plump:get-elements-by-tag-name (hyperbook:dom-of page) "a")
                          :key (lambda (node) (plump:attribute node "data-topic")) :test #'equal)))
        (assert (equal "in progress" (plump:attribute anchor "data-status"))))
      ;; Request and plan are only inspected; the outcome connects them all.
      (assert (%no-actions-p (%view request "Work status change request")))
      (assert (%no-actions-p (%view plan "Work status change plan")))
      (let* ((outcome-view (%view outcome "Work status change outcome"))
             (outcome-html (views:view-html outcome-view))
             (objects (mapcar #'cdr (views:view-references outcome-view))))
        (assert (%no-actions-p outcome-view))
        (dolist (text '("operation/change-work-status" "Request" "Plan" "applied" "Source authority"
                        "Work Topic now" "<tt>in progress</tt>"))
          (assert (search text outcome-html) () "The outcome view lacks ~S." text))
        (dolist (object (list (work:work-status-change-topic request) selection request plan page now))
          (assert (member object objects :test #'eq)))))
    ;; The Workspace it started from is as it was.
    (assert (equal point (tm:topicmap-workspace-point-of workspace)))
    ;; A Workspace over the written page offers the way back.
    (let ((again (%view (tm:make-topicmap-workspace (%project page path) "hyperdoc-page-authoring")
                        "Change work status")))
      (assert (member "Change work status to \"open\"" (mapcar #'car (%buttons again)) :test #'equal)))
    ;; A Point whose Topic no HTML declaration backs offers nothing.
    (let ((plain (tm:make-topicmap-workspace
                  (tm:make-topicmap-projection :topics (list (tm:make-topicmap-topic :id "plain" :label "Plain")))
                  "plain")))
      (assert (null (find "Change work status" (views:all-views plain)
                          :key #'views:view-title :test #'equal))))
    (assert (equal pages (work-page-sources)))))

(defun check-shared-selection (page path)
  "Inspector and gesture select Change work status on the same exact Work Topic
declaration as the same operation request, and completing that request is the
one way on."
  (let* ((source (%read path))
         (projection (%project page path))
         (topic (tm:topicmap-projection-topic-by-id projection "hyperdoc-page-authoring"))
         (workspace (tm:make-topicmap-workspace projection "hyperdoc-page-authoring"))
         (operation (w:change-work-status-operation))
         (inspector (ops:work-topic-operation-request operation topic))
         (bindings (m:workspace-action-sign-bindings (gt::%occurrence workspace topic :bindings nil))))
    ;; This image offers Change work status on the sign of a declared Work
    ;; Topic, and nothing on a Topic no HTML declaration backs.
    (assert (equal '("binding/radial-menu-change-work-status" "binding/learned-mark-change-work-status")
                   (mapcar #'w:gesture-binding-id bindings)))
    (assert (every (lambda (binding) (eq operation (w:gesture-binding-operation binding))) bindings))
    (let* ((plain (tm:make-topicmap-topic :id "plain" :label "Plain"))
           (elsewhere (tm:make-topicmap-workspace (tm:make-topicmap-projection :topics (list plain)) "plain")))
      (assert (null (m:workspace-action-sign-bindings (gt::%occurrence elsewhere plain :bindings nil)))))
    ;; A radial gesture and a mark on the sign select the Inspector's own
    ;; operation request: the same object, operation and declaration.
    (dolist (steps (list gt::*radial* gt::*mark*))
      (let ((sign (gt::%occurrence workspace topic :bindings bindings)))
        (gt::%feed sign steps)
        (let ((gesture (m:workspace-action-sign-selected-object sign)))
          (assert (eq inspector gesture))
          (assert (eq operation (r:operation-request-operation gesture)))
          (assert (eq (work:topic-source-occurrence topic) (r:operation-request-occurrence gesture))))))
    (assert (string= source (%read path)))
    ;; The selection's own view completes it; request, plan and effect follow.
    (let* ((view (%view inspector "Change work status"))
           (outcome (views:eval-thunk (cdr (assoc "Change work status to \"in progress\"" (%buttons view)
                                                  :test #'equal)))))
      (assert (eq :applied (a:work-status-change-outcome-status outcome)))
      (assert (eq inspector (a:work-status-change-outcome-selection outcome)))
      (assert (member inspector (mapcar #'cdr (views:view-references
                                                 (%view outcome "Work status change outcome")))
                      :test #'eq))
      (assert (equal "in progress" (%status (%project page path) "hyperdoc-page-authoring")))
      ;; The selection was of the page as it was: completing it again is
      ;; refused, and nothing relocates.
      (assert (typep (a:complete-work-status-change inspector "open") 'work:work-status-change-refused))
      (assert (equal "in progress" (%status (%project page path) "hyperdoc-page-authoring"))))))

(defun relationship-plan-refusal (thunk)
  (handler-case (progn (funcall thunk) (error "Expected a plan refusal."))
    (a:work-relationship-creation-plan-refused (condition) condition)))

(defun check-relationship-creation-plan (page path)
  "A relationship creation request gets a verified HTML plan: one statement
after the last authored one, reading and projecting as exactly the requested
relationship. Nothing is written, and no relationship occurrence is made."
  (let* ((pages (work-page-sources))
         (source (%read path))
         (projection (%project page path))
         (from (tm:topicmap-projection-topic-by-id projection "lisp-source-authoring"))
         (to (tm:topicmap-projection-topic-by-id projection "running-image-authoring"))
         (operation (w:create-relationship-operation))
         (selection (ops:work-topic-operation-request operation from))
         (request (work:request-work-relationship-creation selection to "work:relation/informs"))
         (statements (work:scan-work-relationships source page))
         (plan (a:plan-work-relationship-creation request))
         (position (a:work-relationship-creation-plan-position plan))
         (representation (a:work-relationship-creation-plan-representation plan)))
    ;; What the plan adds to the request: where, and what.
    (assert (eq request (a:work-relationship-creation-plan-request plan)))
    (assert (eq (work:work-relationship-creation-authority-snapshot request)
                (a:work-relationship-creation-plan-snapshot plan)))
    (assert (= position (cdr (work:relationship-occurrence-element-range (car (last statements))))))
    (assert (string= (format nil "~%<li data-from=\"lisp-source-authoring\" data-to=\"running-image-authoring\" data-relation=\"work:relation/informs\">Structural Lisp Source Authoring → Running Lisp Image Authoring: informs.</li>")
                     representation))
    (let ((slots (sb-mop:class-slots (find-class 'a:work-relationship-creation-plan))))
      (assert (equal '("REQUEST" "SNAPSHOT" "POSITION" "REPRESENTATION")
                     (mapcar (lambda (slot) (symbol-name (sb-mop:slot-definition-name slot))) slots)))
      (assert (notany (lambda (slot) (typep (slot-value plan (sb-mop:slot-definition-name slot))
                                            'work:work-relationship-source-occurrence))
                      slots)))
    ;; Nothing was written; the page states what it stated.
    (assert (string= source (%read path)))
    (assert (= (length statements) (length (work:scan-work-relationships (%read path) page))))
    ;; Read independently, the candidate is the page and one statement more.
    (let* ((candidate (concatenate 'string (subseq source 0 position) representation (subseq source position)))
           (read (work:scan-work-relationships candidate page))
           (after (work:project-work-breakdown candidate :source page))
           (added (car (last (tm:topicmap-projection-associations-of after)))))
      (assert (= (1+ (length statements)) (length read)))
      (assert (equal '("lisp-source-authoring" "work:relation/informs" "running-image-authoring")
                     (list (work:relationship-occurrence-from (car (last read)))
                           (work:relationship-occurrence-relation (car (last read)))
                           (work:relationship-occurrence-to (car (last read))))))
      (assert (equal "informs" (tm:topicmap-association-relation-label added)))
      (assert (= (1+ (length (tm:topicmap-projection-associations-of projection)))
                 (length (tm:topicmap-projection-associations-of after)))))
    ;; A plain relation word is its own label.
    (assert (search "Running Lisp Image Authoring: requires.</li>"
                    (a:work-relationship-creation-plan-representation
                     (a:plan-work-relationship-creation
                      (work:request-work-relationship-creation selection to "requires")))))
    ;; The Inspector shows where and what, and that nothing was applied.
    (let* ((view (%view plan "Relationship creation plan"))
           (html (views:view-html view)))
      (dolist (text '("Request" "Authority" "after the last authored relationship statement"
                      "a representation policy, not a relationship collection"
                      "data-relation=&quot;work:relation/informs&quot;"
                      "none -- only reading the written source would observe one" "no -- there is no writer"))
        (assert (search text html) () "The plan view lacks ~S." text))
      (assert (%no-actions-p view))
      (assert (member request (mapcar #'cdr (views:view-references view)) :test #'eq)))
    ;; Refusals.
    (flet ((refused (fragment thunk)
             (let ((condition (relationship-plan-refusal thunk)))
               (assert (search fragment (a:work-relationship-creation-plan-refused-reason condition)) ()
                       "Refusal ~S lacks ~S." (princ-to-string condition) fragment)
               condition)))
      ;; A relation the plain data-relation representation does not admit.
      (dolist (relation '("in\"forms" "informs & more" "a<b"))
        (let ((admitted (work:request-work-relationship-creation selection to relation)))
          (refused "is not admitted in the plain, unescaped data-relation representation"
                   (lambda () (a:plan-work-relationship-creation admitted)))))
      ;; The page changed after the request.
      (%write path (replace-once source "This page is the current work map" "This page is the present work map"))
      (assert (typep (a:work-relationship-creation-plan-refused-cause
                      (refused "the request no longer holds" (lambda () (a:plan-work-relationship-creation request))))
                     'work:work-relationship-creation-refused))
      ;; A page that states no relationship gives the policy no place.
      (let ((bare source))
        (dolist (statement (reverse statements))
          (let ((range (work:relationship-occurrence-element-range statement)))
            (setf bare (concatenate 'string (subseq bare 0 (car range)) (subseq bare (cdr range))))))
        (%write path bare)
        (let* ((bare-projection (%project page path))
               (bare-request (work:request-work-relationship-creation
                              (ops:work-topic-operation-request
                               operation (tm:topicmap-projection-topic-by-id bare-projection "lisp-source-authoring"))
                              (tm:topicmap-projection-topic-by-id bare-projection "running-image-authoring")
                              "develops")))
          (refused "states no relationship" (lambda () (a:plan-work-relationship-creation bare-request)))))
      (%write path source))
    (assert (equal pages (work-page-sources)))))

(defun %closure (name &optional seen)
  "Every system NAME depends on, by name, found without loading any."
  (let ((system (asdf:find-system name nil)))
    (if (or (null system) (member (asdf:component-name system) seen :test #'string=))
        seen
        (let ((seen (cons (asdf:component-name system) seen)))
          (dolist (dependency (asdf:system-depends-on system) seen)
            (let ((dependency-name
                    (cond ((stringp dependency) dependency)
                          ((symbolp dependency) (string-downcase dependency))
                          ((and (consp dependency) (eq :version (first dependency)))
                           (string-downcase (string (second dependency)))))))
              (when dependency-name
                (setf seen (%closure dependency-name seen)))))))))

(defun check-authoring-boundary ()
  "The Catalog, and the reading system that makes requests, cannot reach the
planner and writer."
  (dolist (reader '("dreyeck/catalog" "dreyeck/work/reading"))
    (let ((closure (%closure reader)))
      (assert (member reader closure :test #'string=))
      (assert (not (member "dreyeck/work/authoring" closure :test #'string=)))))
  (assert (member "dreyeck/work/reading" (%closure "dreyeck/work/authoring") :test #'string=))
  ;; Authorisation is the pinned authoring environment, which the Catalog
  ;; cannot reach either.
  (assert (member "dreyeck/workflow/authoring" (%closure "dreyeck/work/authoring") :test #'string=))
  (assert (not (member "dreyeck/workflow/authoring" (%closure "dreyeck/catalog") :test #'string=))))

(defun run-tests ()
  (let ((pages (work-page-sources)))
    (call-with-work-breakdown-fixture
     (lambda (page path)
       (check-planning page path)
       (check-stale-plans page path)
       (check-hand-built-plans page path)
       (check-applying page path)))
    (call-with-work-breakdown-fixture #'check-authoring-circle)
    (call-with-work-breakdown-fixture #'check-shared-selection)
    (call-with-work-breakdown-fixture #'check-relationship-creation-plan)
    (check-authoring-boundary)
    (assert (equal pages (work-page-sources))))
  (format t "~&WORK-AUTHORING-PASS: a valid request plans without writing; a stale ~
request, a moved declaration and a status the plain data-status representation does not admit plan ~
nothing; a change anywhere between plan and apply, the declaration still at its ~
offset, refuses without writing; a plan built by hand for such a status is ~
refused before installation, the page byte-identical; applied once, the ~
candidate verified before its atomic installation, only the status value's bytes ~
change, the reprojection changes only the target's status, the loaded page ~
shows it, and the plan and request are stale; neither the Catalog nor the ~
reading system reaches the writer; from a Work Topic at a Workspace Point, in ~
an image holding the pinned authoring environment, one action offered from ~
the page's observed statuses carries request, plan and authorised apply to ~
the written page, the reloaded page object and the projected Topic, all ~
connected in the outcome, while without that environment nothing is planned ~
or written; a Topic sign gesture, by menu or by mark, and the Inspector select ~
the same registry-backed operation request, whose own view completes it; a ~
relationship creation request gets a plan that inserts one statement after the ~
last authored one, verified to read and project as exactly the requested ~
relationship, writing nothing and making no occurrence, refused for an ~
unadmitted relation, a changed page and a page stating no relationship; the ~
repository's pages are untouched.~%")
  t)
