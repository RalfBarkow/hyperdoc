;;;; From a work status change request to a checked HTML effect.
;;;; Every write here goes to a copy of Work Breakdown in a temporary
;;;; HyperDoc; the repository's pages are compared before and after.
(defpackage #:dreyeck/work/authoring/tests
  (:use #:cl)
  (:local-nicknames (#:a #:dreyeck/work/authoring)
                    (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap)
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
source cannot hold as written, plans nothing."
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
    ;; A request may propose any other status; this source cannot hold every one.
    (dolist (proposed '("in \"progress\"" "in progress & review" "in <progress>"))
      (let* ((request (%request page path proposed))
             (condition (plan-refusal (lambda () (a:plan-work-status-change request)))))
        (assert (equal proposed (work:work-status-change-proposed-status request)))
        (assert (search "cannot be written as a data-status value"
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
  (assert (member "dreyeck/work/reading" (%closure "dreyeck/work/authoring") :test #'string=)))

(defun run-tests ()
  (let ((pages (work-page-sources)))
    (call-with-work-breakdown-fixture
     (lambda (page path)
       (check-planning page path)
       (check-stale-plans page path)
       (check-applying page path)))
    (check-authoring-boundary)
    (assert (equal pages (work-page-sources))))
  (format t "~&WORK-AUTHORING-PASS: a valid request plans without writing; a stale ~
request, a moved declaration and a status the HTML cannot hold as written plan ~
nothing; a change anywhere between plan and apply, the declaration still at its ~
offset, refuses without writing; applied once, only the status value's bytes ~
change, the reprojection changes only the target's status, the loaded page ~
shows it, and the plan and request are stale; neither the Catalog nor the ~
reading system reaches the writer; the repository's pages are untouched.~%")
  t)
