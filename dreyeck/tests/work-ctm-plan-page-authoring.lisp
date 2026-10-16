(defpackage #:dreyeck/work/ctm-page-authoring/tests
  (:use #:cl)
  (:local-nicknames (#:c #:dreyeck/work/ctm-page-authoring) (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap) (#:v #:html-inspector-views)
                    (#:r #:dreyeck/work/trails-rendered-reading/tests))
  (:export #:run-tests))
(in-package #:dreyeck/work/ctm-page-authoring/tests)

(defun view (object title) (r::following-view object title))
(defun refs (object title) (mapcar #'cdr (v:view-references (view object title))))
(defun source (title)
  (uiop:read-file-string (hyperdoc:file-of (work:work-page title)) :external-format :utf-8))
(defun file-digest (title)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 (hyperdoc:file-of (work:work-page title)))))
(defun replaced (text old new)
  "TEXT with its one occurrence of OLD replaced, so a mutation cannot silently miss."
  (let ((at (search old text)))
    (assert at)
    (assert (null (search old text :start2 (1+ at))))
    (concatenate 'string (subseq text 0 at) new (subseq text (+ at (length old))))))
(defun reading-of (&key (plan (source c::+plan-page+)) (dictionary (source c::+dictionary-page+)))
  (c:read-ctm-authoring :plan-source plan :dictionary-source dictionary))
(defun refused (reason &rest sources)
  "The refusal of the mutated SOURCES, whose report names REASON."
  (let ((condition (handler-case (progn (apply #'reading-of sources) nil)
                     (c:ctm-authoring-structure-error (condition) condition))))
    (assert condition)
    (assert (search reason (princ-to-string condition)))
    condition))
(defun ids (subjects) (mapcar #'c::subject-id subjects))
(defun identity-keys (reading)
  "Serializable identities of one reading: never EQ across readings."
  (mapcar (lambda (subject)
            (list (c::subject-id subject) (c::subject-kind subject) (c::subject-status subject) (c::subject-label subject)
                  (work:topic-occurrence-element-range (work:topic-source-occurrence (c::subject-topic subject)))))
          (c::reading-subjects reading)))

(defun check-guards ()
  (let ((plan (source c::+plan-page+)) (dictionary (source c::+dictionary-page+)))
    ;; Positive control: the untouched sources read through the same harness.
    (assert (typep (reading-of :plan plan :dictionary dictionary) 'c::ctm-authoring-reading))
    ;; WBS and plan stay apart: a plan step cannot decompose the scope.
    (refused "joins" :plan (replaced plan "data-from=\"ctm-page-edit\" data-to=\"ctm-wp-1\""
                                     "data-from=\"ctm-plan-p1\" data-to=\"ctm-wp-1\""))
    ;; No fourth relation, in particular none that would read as an authorization.
    (refused "none of the plan page's three contracts"
             :plan (replaced plan "data-relation=\"work:relation/depends-on\">P5 → P4"
                             "data-relation=\"authorizes\">P5 → P4"))
    (refused "a cycle" :plan (replaced plan "P5 → P4: depends on.</li>"
                                       (format nil "P5 → P4: depends on.</li>~%<li data-from=\"ctm-plan-p1\" data-to=\"ctm-plan-p5\" data-relation=\"work:relation/depends-on\">P1 → P5: depends on.</li>")))
    ;; Work status: one vocabulary, and agreement with the dependencies.
    (refused "not one of" :plan (replaced plan "data-status=\"open\">P4 Verify" "data-status=\"approved\">P4 Verify"))
    (refused "is blocked, but" :plan (replaced plan "data-status=\"open\">P4 Verify" "data-status=\"blocked\">P4 Verify"))
    (refused "is blocked, but" :plan (replaced plan "data-topic=\"ctm-pre-content\" data-kind=\"precondition\" data-status=\"open\""
                                               "data-topic=\"ctm-pre-content\" data-kind=\"precondition\" data-status=\"verified\""))
    (let ((unverified (replaced plan "data-topic=\"ctm-pre-transfer\" data-kind=\"precondition\" data-status=\"verified\""
                                "data-topic=\"ctm-pre-transfer\" data-kind=\"precondition\" data-status=\"open\"")))
      (refused "is verified before everything it depends on" :plan unverified)
      (refused "is open, but" :plan (replaced unverified "data-topic=\"ctm-plan-p1\" data-kind=\"plan step\" data-status=\"verified\""
                                              "data-topic=\"ctm-plan-p1\" data-kind=\"plan step\" data-status=\"open\"")))
    ;; The same rule admits progress once the precondition is verified.
    (assert (typep (reading-of :plan (replaced (replaced plan "data-topic=\"ctm-pre-content\" data-kind=\"precondition\" data-status=\"open\""
                                                         "data-topic=\"ctm-pre-content\" data-kind=\"precondition\" data-status=\"verified\"")
                                               "data-topic=\"ctm-plan-p2\" data-kind=\"plan step\" data-status=\"blocked\""
                                               "data-topic=\"ctm-plan-p2\" data-kind=\"plan step\" data-status=\"open\""))
                   'c::ctm-authoring-reading))
    ;; Dictionary: one entry per package, known fields, every control, real test text.
    ;; A missing entry: deleting it leaves no other guard to refuse, unlike renaming it.
    (refused "ctm-wp-5 needs exactly one dictionary entry"
             :dictionary (let* ((start (search "<section data-wbs-entry=\"ctm-wp-5\">" dictionary))
                                (end (+ (search "</section>" dictionary :start2 start) (length "</section>"))))
                           (concatenate 'string (subseq dictionary 0 start) (subseq dictionary end))))
    (refused "unknown field" :dictionary (replaced dictionary "<p data-field=\"authority\">None to prepare."
                                                   "<p data-field=\"authorities\">None to prepare."))
    (refused "journal-continued is planned 0 times"
             :dictionary (replaced dictionary "data-control=\"journal-continued\"" "data-control=\"journal\""))
    (refused "does not occur in" :dictionary (replaced dictionary "data-marker=\"(refused :stale\""
                                                       "data-marker=\"(refused :stale-but-absent\""))))

(defun run-tests ()
  (let* ((titles (list c::+plan-page+ c::+dictionary-page+ "Work Breakdown"))
         (before (mapcar #'file-digest titles))
         (reading (c:read-ctm-authoring))
         (subjects (c::reading-subjects reading))
         (work (work:work-projection))
         (item (tm:topicmap-projection-topic-by-id work "ctm-plan-page-authoring"))
         (page (work:work-page c::+plan-page+)))
    ;; Work Breakdown: one new Work item, joined to the three named subjects.
    (assert item)
    (assert (eq page (tm:topicmap-topic-object-of item)))
    (assert (equal "work item" (getf (tm:topicmap-topic-view-properties-of item) :kind)))
    (assert (equal "open" (getf (tm:topicmap-topic-view-properties-of item) :status)))
    (dolist (id '("work:ctm-plan-page-authoring:applies:fedwiki-item-authoring"
                  "work:ctm-plan-page-authoring:applies:hyperdoc-authoring-interaction"
                  "work:dogfooding:current-work:ctm-plan-page-authoring"))
      (assert (find id (tm:topicmap-projection-associations-of work) :key #'tm:topicmap-association-id-of :test #'equal)))
    ;; WBS: one scope decomposed into the five deliverables, in authored order.
    (assert (equal '("One Item of the CTM plan page edited through HyperDoc")
                   (mapcar #'c::subject-label (c::%of-kind reading "deliverable"))))
    (assert (equal '("Verified page source" "Inspectable edit proposal" "Authorized single-item edit"
                     "Verified persisted result" "HyperDoc work evidence")
                   (mapcar #'c::subject-label (c::wbs-packages reading))))
    (assert (equal '(5 5 7) (mapcar (lambda (r) (length (c::%edges reading r))) (list c::+decomposes+ c::+produces+ c::+depends+))))
    ;; Plan objects: what each step needs first and what it yields.
    (flet ((subject (id) (c::%subject reading id)))
      (assert (equal '(("ctm-pre-transfer") ("ctm-plan-p1" "ctm-pre-content") ("ctm-plan-p2" "ctm-pre-authority")
                       ("ctm-plan-p3") ("ctm-plan-p4"))
                     (mapcar (lambda (s) (ids (c::step-dependencies s))) (c::plan-steps reading))))
      (loop for n from 1 to 5
            do (assert (equal (format nil "ctm-wp-~D" n)
                              (c::subject-id (c::step-result (subject (format nil "ctm-plan-p~D" n))))))
               (assert (eq (subject (format nil "ctm-plan-p~D" n))
                           (c::element-producer (c::step-result (subject (format nil "ctm-plan-p~D" n)))))))
      ;; Work status, separately: blocked exactly while a precondition is unmet. Verified
      ;; are the transfer, P1 and its package, by the user's reports of the productive Inspector.
      (assert (equal '("verified" "blocked" "blocked" "open" "open") (mapcar #'c::subject-status (c::plan-steps reading))))
      (assert (equal '(() ("ctm-pre-content") ("ctm-pre-authority") () ())
                     (mapcar (lambda (s) (ids (c::step-unmet-preconditions s))) (c::plan-steps reading))))
      (assert (equal '("ctm-plan-p1" "ctm-pre-transfer" "ctm-wp-1")
                     (sort (ids (remove "verified" subjects :key #'c::subject-status :test-not #'equal)) #'string<)))
      ;; The authority precondition stays blocked while Work Breakdown's authority items are not complete.
      (dolist (id '("production-authoring-authority" "authoring-listener-startup"))
        (assert (member (getf (tm:topicmap-topic-view-properties-of (tm:topicmap-projection-topic-by-id work id)) :status)
                        '("open" "blocked") :test #'equal)))
      (assert (equal "blocked" (c::subject-status (subject "ctm-pre-authority")))))
    ;; Authorization: none permitted; the projections carry only the Work reader's own Associations.
    (dolist (s (c::plan-steps reading))
      (assert (not (c::authorization-permitted-p (c::step-authorization s)))))
    (let* ((plan-edges (tm:topicmap-projection-associations-of (c::reading-projection reading)))
           (full (c:ctm-authoring-projection reading))
           (wbs (tm:topicmap-projection-of (make-instance 'c::ctm-wbs :reading reading)))
           (plan (tm:topicmap-projection-of (make-instance 'c::ctm-plan :reading reading))))
      (assert (equal '(14 6 13) (mapcar (lambda (p) (length (tm:topicmap-projection-topics-of p))) (list full wbs plan))))
      (assert (equal '(17 5 12) (mapcar (lambda (p) (length (tm:topicmap-projection-associations-of p))) (list full wbs plan))))
      (dolist (projection (list full wbs plan))
        (dolist (topic (tm:topicmap-projection-topics-of projection))
          (assert (typep (tm:topicmap-topic-object-of topic) 'c::ctm-subject)))
        (dolist (edge (tm:topicmap-projection-associations-of projection))
          (assert (member edge plan-edges :test #'eq))
          (assert (equal '(:source-occurrence :relation-contract)
                         (loop for key in (tm:topicmap-association-properties-of edge) by #'cddr collect key)))))
      (assert (every (lambda (e) (equal c::+decomposes+ (tm:topicmap-association-type-of e)))
                     (tm:topicmap-projection-associations-of wbs)))
      (assert (notany (lambda (e) (equal c::+decomposes+ (tm:topicmap-association-type-of e)))
                      (tm:topicmap-projection-associations-of plan))))
    ;; Dictionary: one entry per package with every field; each required control once.
    (assert (= 5 (length (c::reading-entries reading))))
    (dolist (package (c::wbs-packages reading))
      (let ((entry (c::element-entry package)))
        (dolist (field c::+fields+) (assert (plusp (length (c::entry-field entry field)))))))
    (let ((controls (mapcan (lambda (e) (copy-list (c::entry-controls e))) (c::reading-entries reading))))
      (assert (equal (sort (copy-list c::+required-controls+) #'string<)
                     (sort (mapcar #'c::control-id controls) #'string<)))
      (assert (equal '("fresh-reconstruction")
                     (mapcar #'c::control-id (remove "existing" controls :key #'c::control-coverage :test #'equal)))))
    (assert (search "Not granted" (c::entry-field (c::element-entry (c::%subject reading "ctm-wp-3")) "authority")))
    (check-guards)
    ;; Fresh reconstruction: new objects, the same source identities.
    (let ((again (c:read-ctm-authoring)))
      (assert (not (eq (first subjects) (first (c::reading-subjects again)))))
      (assert (equal (identity-keys reading) (identity-keys again))))
    ;; Native views and their references.
    (let ((plan (make-instance 'c::ctm-plan :reading reading))
          (wbs (make-instance 'c::ctm-wbs :reading reading))
          (p3 (c::%subject reading "ctm-plan-p3")))
      (assert (subsetp (c::plan-steps reading) (refs plan "Plan steps")))
      (assert (subsetp (c::wbs-packages reading) (refs wbs "WBS")))
      (view plan "Topicmap") (view wbs "Topicmap") (view reading "Topicmap")
      (let ((step-refs (refs p3 "Plan step")))
        (assert (member (c::step-result p3) step-refs :test #'eq))
        (assert (subsetp (c::step-dependencies p3) step-refs))
        (assert (find-if (lambda (o) (typep o 'c::step-authorization)) step-refs)))
      (dolist (subject subjects)
        (view subject (etypecase subject
                        (c::plan-step "Plan step") (c::plan-precondition "Precondition") (c::wbs-element "WBS element"))))
      (dolist (package (c::wbs-packages reading))
        (let ((element-refs (refs package "WBS element")))
          (assert (member (c::element-producer package) element-refs :test #'eq))
          (assert (subsetp (c::entry-controls (c::element-entry package)) element-refs)))
        (view (c::element-entry package) "WBS Dictionary entry")
        (dolist (control (c::entry-controls (c::element-entry package))) (view control "Planned control")))
      (assert (search "Permitted now" (v:view-html (view (c::step-authorization p3) "Authorization")))))
    ;; Reachable from the carrier page; the dictionary page renders.
    (assert (find-if (lambda (o) (typep o 'c::ctm-plan)) (refs page "Content")))
    (view (work:work-page c::+dictionary-page+) "Content")
    (assert (typep (work:work-page "Reading the CTM Plan Page Authoring Plan") 'hyperdoc::code-page))
    ;; Workspace Point and History over the actual objects.
    (let* ((workspace (c:ctm-authoring-workspace))
           (point (tm:topicmap-workspace-point-of workspace))
           (history (copy-list (tm:topicmap-workspace-history-of workspace))))
      (unwind-protect
           (progn
             (dolist (id '("ctm-wp-3" "ctm-plan-p3" "ctm-pre-authority"))
               (let ((previous (tm:topicmap-workspace-point-of workspace)))
                 (tm:topicmap-workspace-go-to workspace id)
                 (assert (equal previous (first (tm:topicmap-workspace-history-of workspace))))
                 (let ((object (tm:topicmap-workspace-current-object workspace)))
                   (assert (equal id (c::subject-id object)))
                   (assert (member object (refs workspace "Topicmap") :test #'eq)))))
             (let ((history-now (copy-list (tm:topicmap-workspace-history-of workspace))))
               (tm:topicmap-workspace-reproject workspace (c:ctm-authoring-projection (c:read-ctm-authoring)))
               (assert (equal "ctm-pre-authority" (tm:topicmap-workspace-point-of workspace)))
               (assert (equal history-now (tm:topicmap-workspace-history-of workspace)))))
        (setf (tm:topicmap-workspace-point-of workspace) point
              (tm:topicmap-workspace-history-of workspace) history)))
    ;; Nothing above wrote a source.
    (assert (equal before (mapcar #'file-digest titles))))
  (format t "~&CTM-PLAN-PAGE-AUTHORING-PASS: Work item with three links; WBS 1+5 with one dictionary entry each; plan P1-P5 with dependencies, results and preconditions; status agrees with unmet preconditions; no authorization permitted; 7 planned controls, 6 bound to existing tests; 12 refusals and 1 admitted progress against the untouched sources; fresh reconstruction; Point/History; no source written.~%"))
