;;;; Inspector views of the reading typography objects. Relations are references to objects, not strings that name them.
(in-package #:dreyeck/ccnx-federated-wiki)

(defparameter +typography-view-priority+ 20
  "Content (priority 1) comes first; the Typography view of a page is a perspective on the reading, not its replacement.")

(defun %label (object)
  "What an object of this model is called where it is referenced: its id, not its address."
  (flet ((short (text) (if (> (length text) 70) (concatenate 'string (subseq text 0 67) "...") text)))
    (typecase object
      (typography-finding (format nil "~A: ~A" (typography-finding-id-of object) (short (typography-finding-problem-of object))))
      (presentation-variant (format nil "~A: ~A" (presentation-variant-id-of object) (short (presentation-variant-change-of object))))
      (legibility-case (format nil "~A  ~A" (legibility-case-id-of object) (or (legibility-case-string-of object) "")))
      (text-unit (text-unit-id-of object))
      (reading-task (reading-task-name-of object))
      (t object))))

(defun %relations-view (title pairs &key (priority 1))
  (hv:html-view :title title :priority priority
    (hv:html
      (:table
       (dolist (pair pairs)
         (hv:html
           (:tr (:th (hv:esc (car pair)))
                (:td (let ((value (cdr pair)))
                       (if (stringp value) (hv:esc value) (hv:object-ref value :display (lambda (o) (%label o)))))))))))))

(hv:defview reading-task-view (task reading-task)
  (%relations-view "Reading task"
    (append (list (cons "Name" (reading-task-name-of task))
                  (cons "Supports" (reading-task-supports-of task))
                  (cons "Basis" (reading-task-basis-of task)))
            (loop for f in (typography-findings) when (eq task (typography-finding-task-of f)) collect (cons "Finding" f)))))

(hv:defview text-unit-view (unit text-unit)
  (%relations-view "Text unit"
    (append (list (cons "Kind" (string-downcase (symbol-name (text-unit-kind-of unit))))
                  (cons "Page" (text-unit-page-of unit))
                  (cons "Element" (text-unit-element-of unit))
                  (cons "Text now (read from the page)" (let ((text (text-unit-text-of unit))) (subseq text 0 (min 240 (length text))))))
            (loop for f in (typography-findings) when (eq unit (typography-finding-unit-of f)) collect (cons "Finding" f))
            (loop for c in (legibility-cases) when (eq unit (legibility-case-unit-of c)) collect (cons "Legibility case" c)))))

(hv:defview legibility-case-view (case legibility-case)
  (%relations-view "Legibility case"
    (append (list (cons "String" (or (legibility-case-string-of case) ""))
                  (cons "Where" (legibility-case-unit-of case))
                  (cons "Conditions" (legibility-case-conditions-of case))
                  (cons "Status" (string-downcase (symbol-name (legibility-case-status-of case))))
                  (cons "Observation" (legibility-case-observation-of case)))
            (mapcar (lambda (f) (cons "Finding" f)) (legibility-case-findings-of case)))))

(hv:defview typography-finding-view (finding typography-finding)
  (%relations-view "Typography finding"
    (append (list (cons "Where" (typography-finding-unit-of finding))
                  (cons "Reading task" (typography-finding-task-of finding))
                  (cons "Problem" (typography-finding-problem-of finding))
                  (cons "Status" (string-downcase (symbol-name (typography-finding-status-of finding))))
                  (cons "Observation" (typography-finding-observation-of finding))
                  (cons "Proposed change" (typography-finding-proposal-of finding))
                  (cons "Grounds (design hypothesis)" (typography-finding-rationale-of finding)))
            (mapcar (lambda (c) (cons "Legibility case" c)) (typography-finding-cases-of finding))
            (mapcar (lambda (v) (cons "Presentation variant" v)) (typography-finding-variants-of finding)))))

(hv:defview presentation-variant-view (variant presentation-variant)
  (%relations-view "Presentation variant"
    (list (cons "Finding" (presentation-variant-finding-of variant))
          (cons "Change" (presentation-variant-change-of variant))
          (cons "CSS block (dreyeck/ccnx-federated-wiki/assets/ccnx-reading/css/reading.css)" (presentation-variant-css-label-of variant))
          (cons "Before / after (docs/ccnx-federated-wiki/evidence/typography/)"
                (format nil "~A  ->  ~A" (presentation-variant-before-of variant) (presentation-variant-after-of variant)))
          (cons "Check" (presentation-variant-check-of variant)))))

;;; From a page of the reading to what was found about how it is read.
(hv:defview typography-of-page-view (page hyperdoc::html-page)
  (let ((book (hyperbook:hyperbook-of page)))
    (when (and book (equal (hyperbook:id-of book) +book-id+))
      (let ((findings (typography-findings page)))
        (when findings
          ;; An analytical view of the page, after the reading: Content has priority 1 and views are ordered by ascending priority.
          (%relations-view "Typography"
            (mapcar (lambda (f) (cons (typography-finding-id-of f) f)) findings)
            :priority +typography-view-priority+))))))
