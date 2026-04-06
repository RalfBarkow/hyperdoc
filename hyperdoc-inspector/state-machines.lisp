;;;; Generic inspector views for first-class state-machine objects
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun state-machine-plist-p (item)
  (and (listp item)
       (loop for cursor on item by #'cddr
             always (and cursor
                         (or (keywordp (first cursor))
                             (symbolp (first cursor))
                             (stringp (first cursor)))))))

(defun state-machine-item-value (item key)
  (cond
    ((null item) nil)
    ((hash-table-p item)
     (multiple-value-bind (value present-p)
         (gethash key item)
       (if present-p
           value
           (let ((string-key (string-downcase (string key))))
             (gethash string-key item)))))
    ((state-machine-plist-p item)
     (or (getf item key)
         (let ((string-key (string-downcase (string key))))
           (getf item string-key))))
    ((and (listp item) (every #'consp item))
     (or (cdr (assoc key item :test #'equal))
         (let ((string-key (string-downcase (string key))))
           (cdr (assoc string-key item :test #'string=)))))
    (t
     nil)))

(defun state-machine-string (value)
  (cond
    ((null value) "n/a")
    ((stringp value) value)
    ((keywordp value) (string-downcase (string value)))
    ((symbolp value) (string-downcase (string value)))
    ((and (listp value) (every #'consp value))
     (format nil "~{~A~^; ~}"
             (mapcar (lambda (entry)
                       (format nil "~A=~A" (car entry) (cdr entry)))
                     value)))
    ((listp value)
     (format nil "~{~A~^, ~}" value))
    (t
     (format nil "~A" value))))

(defun state-machine-lines-to-string (lines)
  (with-output-to-string (stream)
    (dolist (line lines)
      (write-string line stream)
      (terpri stream))))

(defun state-machine-state-role-label (machine state)
  (hyperdoc::state-machine-state-role machine state))

(defun state-machine-definition-overview-lines (machine)
  (list
   (format nil "Title: ~A" (hyperdoc::title-of machine))
   (format nil "Initial state: ~A"
           (hyperdoc::state-machine-definition-initial-state-of machine))
   (format nil "State count: ~D"
           (length (hyperdoc::state-machine-definition-states-of machine)))
   (format nil "Transition count: ~D"
           (length (hyperdoc::state-machine-definition-transitions-of machine)))
   (format nil "Multi-initial: ~A"
           (if (hyperdoc::state-machine-definition-multi-initial-p-of machine)
               "yes"
               "no"))
   (format nil "Terminal states present: ~A"
           (if (hyperdoc::state-machine-definition-terminal-states-of machine)
               "yes"
               "no"))
   (format nil "Failure states present: ~A"
           (if (hyperdoc::state-machine-definition-failure-states-of machine)
               "yes"
               "no"))))

(defun state-machine-definition-state-lines (machine)
  (cons "state-id | title | role | entry condition | exit condition | notes"
        (mapcar
         (lambda (state)
           (format nil "~A | ~A | ~A | ~A | ~A | ~A"
                   (hyperdoc::id-of state)
                   (hyperdoc::title-of state)
                   (state-machine-string
                    (state-machine-state-role-label machine state))
                   (state-machine-string
                    (hyperdoc::state-machine-state-entry-condition-of state))
                   (state-machine-string
                    (hyperdoc::state-machine-state-exit-condition-of state))
                   (state-machine-string
                    (hyperdoc::state-machine-state-notes-of state))))
         (hyperdoc::state-machine-definition-states-of machine))))

(defun state-machine-definition-transition-lines (machine)
  (cons "from | to | trigger / event | guard / predicate | emitted evidence | side effects | reversible"
        (mapcar
         (lambda (transition)
           (format nil "~A | ~A | ~A | ~A | ~A | ~A | ~A"
                   (hyperdoc::state-machine-transition-from-state-of transition)
                   (hyperdoc::state-machine-transition-to-state-of transition)
                   (state-machine-string
                    (hyperdoc::state-machine-transition-trigger-of transition))
                   (state-machine-string
                    (hyperdoc::state-machine-transition-guard-of transition))
                   (state-machine-string
                    (hyperdoc::state-machine-transition-emitted-evidence-of transition))
                   (state-machine-string
                    (hyperdoc::state-machine-transition-side-effects-of transition))
                   (if (hyperdoc::state-machine-transition-reversible-p-of transition)
                       "yes"
                       "no")))
         (hyperdoc::state-machine-definition-transitions-of machine))))

(defun state-machine-definition-graph-lines (machine)
  (append
   (list "Ordered states and outgoing guarded arrows:")
   (loop for state in (hyperdoc::state-machine-definition-states-of machine)
         append
         (let* ((state-id (hyperdoc::id-of state))
                (outgoing
                  (hyperdoc::state-machine-transitions-from-state machine state-id)))
           (cons
            (format nil "- ~A [~A]"
                    (hyperdoc::title-of state)
                    (state-machine-string
                     (state-machine-state-role-label machine state-id)))
            (if outgoing
                (mapcar
                 (lambda (transition)
                   (format nil "    -> ~A [event: ~A, guard: ~A]"
                           (hyperdoc::state-machine-transition-to-state-of transition)
                           (state-machine-string
                            (hyperdoc::state-machine-transition-trigger-of transition))
                           (state-machine-string
                            (hyperdoc::state-machine-transition-guard-of transition))))
                 outgoing)
                (list "    -> no outgoing transitions")))))))

(defun state-machine-definition-findings-lines (machine)
  (append
   (list "Declared invariants:")
   (if (hyperdoc::state-machine-definition-invariants-of machine)
       (mapcar (lambda (entry)
                 (format nil "- ~A: ~A"
                         (state-machine-item-value entry :label)
                         (state-machine-item-value entry :detail)))
               (hyperdoc::state-machine-definition-invariants-of machine))
       (list "- none"))
   (list ""
         "Structural findings:")
   (mapcar (lambda (entry)
             (format nil "- [~A] ~A: ~A"
                     (state-machine-string
                      (state-machine-item-value entry :status))
                     (state-machine-item-value entry :label)
                     (state-machine-item-value entry :detail)))
           (hyperdoc::state-machine-definition-findings machine))))

(defun state-machine-source-evidence-lines (entries)
  (if entries
      (cons "layer | reference | detail"
            (mapcar (lambda (entry)
                      (format nil "~A | ~A | ~A"
                              (state-machine-string
                               (state-machine-item-value entry :layer))
                              (state-machine-string
                               (state-machine-item-value entry :reference))
                              (state-machine-string
                               (state-machine-item-value entry :detail))))
                    entries))
      (list "No source evidence recorded.")))

(defun state-machine-transition-cell-label (machine from-state to-state)
  (let ((transition
          (find-if (lambda (candidate)
                     (and (equal (hyperdoc::state-machine-transition-from-state-of
                                  candidate)
                                 from-state)
                          (equal (hyperdoc::state-machine-transition-to-state-of
                                  candidate)
                                 to-state)))
                   (hyperdoc::state-machine-definition-transitions-of machine))))
    (cond
      ((null transition) "forbidden")
      ((hyperdoc::state-machine-transition-guard-of transition)
       (format nil "guarded: ~A"
               (hyperdoc::state-machine-transition-guard-of transition)))
      (t "permitted"))))

(defun state-machine-transition-matrix-lines (machine)
  (let ((state-ids (hyperdoc::state-machine-known-state-ids machine)))
    (cons
     (format nil "from\\to | ~{~A~^ | ~}" state-ids)
     (mapcar
      (lambda (source)
        (format nil "~A | ~{~A~^ | ~}"
                source
                (mapcar (lambda (destination)
                          (state-machine-transition-cell-label
                           machine
                           source
                           destination))
                        state-ids)))
      state-ids))))

(defun state-machine-run-terminal-p (run)
  (member (hyperdoc::state-machine-run-current-state-of run)
          (hyperdoc::state-machine-definition-terminal-states-of
           (hyperdoc::state-machine-run-machine-of run))
          :test #'equal))

(defun state-machine-run-failure-p (run)
  (member (hyperdoc::state-machine-run-current-state-of run)
          (hyperdoc::state-machine-definition-failure-states-of
           (hyperdoc::state-machine-run-machine-of run))
          :test #'equal))

(defun state-machine-run-status-label (run)
  (cond
    ((state-machine-run-failure-p run) "failure")
    ((state-machine-run-terminal-p run) "terminal")
    (t
     (state-machine-string
      (or (hyperdoc::state-machine-run-status-of run)
          :running)))))

(defun state-machine-trace-entry-lines (entries)
  (if entries
      (cons
       "timestamp | kind | transition | from | to | detail"
       (mapcar
        (lambda (entry)
          (format nil "~A | ~A | ~A | ~A | ~A | ~A"
                  (state-machine-string
                   (state-machine-item-value entry :timestamp))
                  (state-machine-string
                   (state-machine-item-value entry :kind))
                  (state-machine-string
                   (state-machine-item-value entry :transition-id))
                  (state-machine-string
                   (state-machine-item-value entry :from-state))
                  (state-machine-string
                   (state-machine-item-value entry :to-state))
                  (state-machine-string
                   (or (state-machine-item-value entry :detail)
                       (state-machine-item-value entry :evidence)))))
        entries))
      (list "No trace entries recorded.")))

(defun state-machine-run-timeline-entries (run)
  (sort (append (copy-list (hyperdoc::state-machine-run-transition-trace-of run))
                (copy-list (hyperdoc::state-machine-run-evidence-trace-of run)))
        #'<
        :key (lambda (entry)
               (or (state-machine-item-value entry :timestamp)
                   most-positive-fixnum))))

(defun state-machine-run-overview-lines (run)
  (list
   (format nil "Machine: ~A"
           (hyperdoc::title-of (hyperdoc::state-machine-run-machine-of run)))
   (format nil "Input summary: ~A"
           (state-machine-string (hyperdoc::state-machine-run-input-of run)))
   (format nil "Current state: ~A"
           (state-machine-string (hyperdoc::state-machine-run-current-state-of run)))
   (format nil "Status: ~A" (state-machine-run-status-label run))
   (format nil "Start time: ~A"
           (state-machine-string (hyperdoc::state-machine-run-start-time-of run)))
   (format nil "End time: ~A"
           (state-machine-string (hyperdoc::state-machine-run-end-time-of run)))))

(defun state-machine-run-trace-lines (run)
  (append
   (list (format nil "Visited states: ~{~A~^ -> ~}"
                 (hyperdoc::state-machine-run-visited-states-of run))
         "")
   (state-machine-trace-entry-lines
    (hyperdoc::state-machine-run-transition-trace-of run))))

(defun state-machine-run-evidence-lines (run)
  (state-machine-trace-entry-lines
   (hyperdoc::state-machine-run-evidence-trace-of run)))

(defun state-machine-run-failure-lines (run)
  (append
   (list
    (format nil "Failure classification: ~A"
            (state-machine-string
             (hyperdoc::state-machine-run-failure-classification-of run)))
    (format nil "Current state role: ~A"
            (state-machine-string
             (hyperdoc::state-machine-state-role
              (hyperdoc::state-machine-run-machine-of run)
              (hyperdoc::state-machine-run-current-state-of run))))
    ""
    "Run findings:")
   (mapcar (lambda (entry)
             (format nil "- [~A] ~A: ~A"
                     (state-machine-string
                      (state-machine-item-value entry :status))
                     (state-machine-item-value entry :label)
                     (state-machine-item-value entry :detail)))
           (hyperdoc::state-machine-run-findings run))
   (if (hyperdoc::state-machine-run-notes-of run)
       (append
        (list ""
              "Run notes:")
        (mapcar (lambda (entry)
                  (format nil "- ~A: ~A"
                          (state-machine-item-value entry :label)
                          (state-machine-item-value entry :detail)))
                (hyperdoc::state-machine-run-notes-of run)))
       '())))

(defun state-machine-preformatted-view (lines)
  (views:html
    (:pre (views:esc (state-machine-lines-to-string lines)))))

(defmethod views:text-representation
    ((machine hyperdoc::state-machine-definition))
  (or (hyperdoc::title-of machine)
      "State machine"))

(defmethod views:text-representation ((run hyperdoc::state-machine-run))
  (or (hyperdoc::title-of run)
      (views:text-representation
       (hyperdoc::state-machine-run-machine-of run))
      "State-machine run"))

(views:defview 👀overview (machine hyperdoc::state-machine-definition)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:p (views:esc
           (or (hyperdoc::summary-of machine)
               "Reusable state-machine definition.")))
      (state-machine-preformatted-view
       (state-machine-definition-overview-lines machine)))))

(views:defview 👀states (machine hyperdoc::state-machine-definition)
  (views:html-view :title "States" :priority 2
    (state-machine-preformatted-view
     (state-machine-definition-state-lines machine))))

(views:defview 👀transitions (machine hyperdoc::state-machine-definition)
  (views:html-view :title "Transitions" :priority 3
    (state-machine-preformatted-view
     (state-machine-definition-transition-lines machine))))

(views:defview 👀state-machine (machine hyperdoc::state-machine-definition)
  (views:html-view :title "State machine" :priority 4
    (views:html
      (:p (views:esc
           "Canonical teaching view of the ordered states, guarded arrows, and terminal/failure branches."))
      (state-machine-preformatted-view
       (state-machine-definition-graph-lines machine)))))

(views:defview 👀invariants-constraints (machine hyperdoc::state-machine-definition)
  (views:html-view :title "Invariants / constraints" :priority 5
    (state-machine-preformatted-view
     (state-machine-definition-findings-lines machine))))

(views:defview 👀source-evidence-code-path
    (machine hyperdoc::state-machine-definition)
  (views:html-view :title "Source evidence / code path" :priority 6
    (state-machine-preformatted-view
     (state-machine-source-evidence-lines
      (hyperdoc::state-machine-definition-source-evidence-of machine)))))

(views:defview 👀directed-graph (machine hyperdoc::state-machine-definition)
  (views:html-view :title "Directed graph" :priority 7
    (views:html
      (:p (views:esc
           "Derived graph view: nodes are states and edges are transitions labeled by event / guard."))
      (state-machine-preformatted-view
       (state-machine-definition-graph-lines machine)))))

(views:defview 👀graphviz (machine hyperdoc::state-machine-definition)
  (views:html-view :title "Graphviz" :priority 8
    (views:html
      (:p (views:esc
           "Browser-rendered Graphviz view derived from the machine definition. The machine object remains the source of truth; DOT is a derived rendering format, while Directed graph remains the teaching-oriented text view."))
      (views:graphviz-snippet
       (hyperdoc::state-machine-definition-dot-text machine)))))

(views:defview 👀transition-matrix (machine hyperdoc::state-machine-definition)
  (views:html-view :title "Transition matrix" :priority 9
    (state-machine-preformatted-view
     (state-machine-transition-matrix-lines machine))))

(views:defview 👀overview (run hyperdoc::state-machine-run)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:p (views:esc
           (or (hyperdoc::summary-of run)
               "Concrete run of a reusable state machine.")))
      (state-machine-preformatted-view
       (state-machine-run-overview-lines run)))))

(views:defview 👀trace (run hyperdoc::state-machine-run)
  (views:html-view :title "Trace" :priority 2
    (state-machine-preformatted-view
     (state-machine-run-trace-lines run))))

(views:defview 👀timeline (run hyperdoc::state-machine-run)
  (views:html-view :title "Timeline" :priority 3
    (views:html
      (:p (views:esc
           "Ordered state-entry and transition evidence events for this concrete run."))
      (state-machine-preformatted-view
       (state-machine-trace-entry-lines
        (state-machine-run-timeline-entries run))))))

(views:defview 👀evidence (run hyperdoc::state-machine-run)
  (views:html-view :title "Evidence" :priority 4
    (views:html
      (:p (views:esc
           "Evidence attached at state-entry and transition points."))
      (state-machine-preformatted-view
       (state-machine-run-evidence-lines run)))))

(views:defview 👀failure-analysis (run hyperdoc::state-machine-run)
  (views:html-view :title "Failure analysis" :priority 5
    (state-machine-preformatted-view
     (state-machine-run-failure-lines run))))

(views:defview 👀source-evidence-code-path (run hyperdoc::state-machine-run)
  (views:html-view :title "Source evidence / code path" :priority 6
    (state-machine-preformatted-view
     (append
      (list "Machine source evidence:")
      (state-machine-source-evidence-lines
       (hyperdoc::state-machine-definition-source-evidence-of
        (hyperdoc::state-machine-run-machine-of run)))
      (if (hyperdoc::state-machine-run-notes-of run)
          (append
           (list ""
                 "Run notes:")
           (mapcar (lambda (entry)
                     (format nil "- ~A: ~A"
                             (state-machine-item-value entry :label)
                             (state-machine-item-value entry :detail)))
                   (hyperdoc::state-machine-run-notes-of run)))
          '())))))
