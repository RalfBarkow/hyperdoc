;;;; Generic inspector views for first-class boundary objects
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun boundary-string (value)
  (cond
    ((null value) "n/a")
    ((typep value 'hyperdoc::boundary-definition)
     (hyperdoc::title-of value))
    ((typep value 'hyperdoc::boundary-instance)
     (or (hyperdoc::title-of value)
         (hyperdoc::title-of
          (hyperdoc::boundary-instance-definition-of value))))
    ((stringp value) value)
    ((keywordp value) (string-downcase (string value)))
    ((symbolp value) (string-downcase (string value)))
    ((and (listp value) (every #'consp value))
     (format nil "~{~A=~A~^; ~}"
             (mapcar (lambda (entry)
                       (format nil "~A" (cdr entry)))
                     value)))
    ((listp value)
     (format nil "~{~A~^, ~}" value))
    (t
     (format nil "~A" value))))

(defun boundary-lines-to-string (lines)
  (with-output-to-string (stream)
    (dolist (line lines)
      (write-string line stream)
      (terpri stream))))

(defun boundary-entry-lines (entries header key-specs)
  (if entries
      (cons
       header
       (mapcar
        (lambda (entry)
          (format nil "~{~A~^ | ~}"
                  (mapcar (lambda (key)
                            (boundary-string
                             (hyperdoc::boundary-item-value entry key)))
                          key-specs)))
        entries))
      (list "No entries recorded.")))

(defun boundary-definition-overview-lines (definition)
  (list
   (format nil "Title: ~A" (hyperdoc::title-of definition))
   (format nil "Boundary kind: ~A"
           (boundary-string
            (hyperdoc::boundary-definition-boundary-kind-of definition)))
   (format nil "Left side present: ~A"
           (if (hyperdoc::boundary-definition-left-side-of definition)
               "yes"
               "no"))
   (format nil "Right side present: ~A"
           (if (hyperdoc::boundary-definition-right-side-of definition)
               "yes"
               "no"))
   (format nil "Evidence kinds: ~D"
           (length (hyperdoc::boundary-definition-evidence-kinds-of definition)))
   (format nil "Failure classifications: ~D"
           (length (hyperdoc::boundary-definition-failure-classifications-of definition)))))

(defun boundary-definition-sides-lines (definition)
  (list
   (format nil "Left side: ~A"
           (boundary-string
            (hyperdoc::boundary-definition-left-side-of definition)))
   (format nil "Right side: ~A"
           (boundary-string
            (hyperdoc::boundary-definition-right-side-of definition)))
   (format nil "Crossing condition: ~A"
           (boundary-string
            (hyperdoc::boundary-definition-crossing-condition-of definition)))))

(defun boundary-definition-operations-lines (definition)
  (append
   (list "Permitted operations:"
         "")
   (boundary-entry-lines
    (hyperdoc::boundary-definition-permitted-operations-of definition)
    "phase | operation | detail"
    '(:phase :operation :detail))
   (list ""
         "Blocked operations:"
         "")
   (boundary-entry-lines
    (hyperdoc::boundary-definition-blocked-operations-of definition)
    "phase | operation | detail"
    '(:phase :operation :detail))))

(defun boundary-definition-failure-lines (definition)
  (append
   (list "Declared failure classifications:"
         "")
   (boundary-entry-lines
    (hyperdoc::boundary-definition-failure-classifications-of definition)
    "label | detail"
    '(:label :detail))
   (list ""
         "Structural findings:")
   (mapcar (lambda (entry)
             (format nil "- [~A] ~A: ~A"
                     (boundary-string
                      (hyperdoc::boundary-item-value entry :status))
                     (hyperdoc::boundary-item-value entry :label)
                     (hyperdoc::boundary-item-value entry :detail)))
           (hyperdoc::boundary-definition-findings definition))))

(defun boundary-definition-adjacent-lines (definition)
  (append
   (list "Adjacent surfaces:"
         "")
   (boundary-entry-lines
    (hyperdoc::boundary-definition-adjacent-surfaces-of definition)
    "surface | detail"
    '(:surface :detail))
   (list ""
         "Evidence kinds:")
   (if (hyperdoc::boundary-definition-evidence-kinds-of definition)
       (mapcar (lambda (kind)
                 (format nil "- ~A" (boundary-string kind)))
               (hyperdoc::boundary-definition-evidence-kinds-of definition))
       '("- none"))))

(defun boundary-definition-related-lines (definition)
  (boundary-entry-lines
   (hyperdoc::boundary-definition-related-boundaries-of definition)
   "boundary | detail"
   '(:boundary :detail))

  )

(defun boundary-source-evidence-lines (entries)
  (if entries
      (cons "layer | reference | detail"
            (mapcar
             (lambda (entry)
               (format nil "~A | ~A | ~A"
                       (boundary-string
                        (hyperdoc::boundary-item-value entry :layer))
                       (boundary-string
                        (hyperdoc::boundary-item-value entry :reference))
                       (boundary-string
                        (hyperdoc::boundary-item-value entry :detail))))
             entries))
      (list "No source evidence recorded.")))

(defun boundary-instance-overview-lines (instance)
  (list
   (format nil "Boundary: ~A"
           (hyperdoc::title-of
            (hyperdoc::boundary-instance-definition-of instance)))
   (format nil "Subject: ~A"
           (boundary-string
            (hyperdoc::boundary-instance-subject-of instance)))
   (format nil "Status: ~A"
           (boundary-string
            (hyperdoc::boundary-instance-status-of instance)))
   (format nil "Last reached stage: ~A"
           (boundary-string
            (hyperdoc::boundary-instance-last-reached-stage-of instance)))
   (format nil "Crossing attempted: ~A"
           (if (hyperdoc::boundary-instance-crossing-attempted-p-of instance)
               "yes"
               "no"))
   (format nil "Crossing succeeded: ~A"
           (if (hyperdoc::boundary-instance-crossing-succeeded-p-of instance)
               "yes"
               "no"))))

(defun boundary-instance-state-lines (instance)
  (append
   (list
    (format nil "Boundary kind: ~A"
            (boundary-string
             (hyperdoc::boundary-definition-boundary-kind-of
              (hyperdoc::boundary-instance-definition-of instance))))
    (format nil "Current status: ~A"
            (boundary-string
             (hyperdoc::boundary-instance-status-of instance)))
    (format nil "Last reached stage: ~A"
            (boundary-string
             (hyperdoc::boundary-instance-last-reached-stage-of instance)))
    ""
    "Auth context:")
   (if (hyperdoc::boundary-instance-auth-context-of instance)
       (boundary-entry-lines
        (hyperdoc::boundary-instance-auth-context-of instance)
        "key | value"
        '(:key :value))
       '("No auth context recorded."))))

(defun boundary-instance-crossing-lines (instance)
  (list
   (format nil "Crossing attempted: ~A"
           (if (hyperdoc::boundary-instance-crossing-attempted-p-of instance)
               "yes"
               "no"))
   (format nil "Crossing succeeded: ~A"
           (if (hyperdoc::boundary-instance-crossing-succeeded-p-of instance)
               "yes"
               "no"))
   (format nil "Crossing condition: ~A"
           (boundary-string
            (hyperdoc::boundary-definition-crossing-condition-of
             (hyperdoc::boundary-instance-definition-of instance))))
   (format nil "Failure classification: ~A"
           (boundary-string
            (hyperdoc::boundary-instance-failure-classification-of instance)))))

(defun boundary-instance-evidence-lines (instance)
  (boundary-entry-lines
   (hyperdoc::boundary-instance-evidence-of instance)
   "kind | detail"
   '(:kind :detail)))

(defun boundary-instance-failure-lines (instance)
  (append
   (list
    (format nil "Failure classification: ~A"
            (boundary-string
             (hyperdoc::boundary-instance-failure-classification-of instance)))
    ""
    "Boundary-instance findings:")
   (mapcar (lambda (entry)
             (format nil "- [~A] ~A: ~A"
                     (boundary-string
                      (hyperdoc::boundary-item-value entry :status))
                     (hyperdoc::boundary-item-value entry :label)
                     (hyperdoc::boundary-item-value entry :detail)))
           (hyperdoc::boundary-instance-findings instance))
   (if (hyperdoc::boundary-instance-notes-of instance)
       (append
        (list ""
              "Notes:")
        (mapcar (lambda (entry)
                  (format nil "- ~A: ~A"
                          (hyperdoc::boundary-item-value entry :label)
                          (hyperdoc::boundary-item-value entry :detail)))
                (hyperdoc::boundary-instance-notes-of instance)))
       '())))

(defun boundary-instance-adjacent-lines (instance)
  (append
   (list "Adjacent stages:"
         "")
   (boundary-entry-lines
    (hyperdoc::boundary-instance-adjacent-stages-of instance)
    "stage | detail"
    '(:stage :detail))
   (list ""
         "Related surfaces:"
         "")
   (boundary-entry-lines
    (hyperdoc::boundary-instance-related-surfaces-of instance)
    "surface | detail"
    '(:surface :detail))))

(defun boundary-preformatted-view (lines)
  (views:html
   (:pre (views:esc (boundary-lines-to-string lines)))))

(defmethod views:text-representation
    ((definition hyperdoc::boundary-definition))
  (or (hyperdoc::title-of definition)
      "Boundary"))

(defmethod views:text-representation
    ((instance hyperdoc::boundary-instance))
  (or (hyperdoc::title-of instance)
      (views:text-representation
       (hyperdoc::boundary-instance-definition-of instance))
      "Boundary instance"))

(views:defview 👀overview (definition hyperdoc::boundary-definition)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:p (views:esc
                         (or (hyperdoc::summary-of definition)
                             "Reusable boundary definition.")))
                    (boundary-preformatted-view
                     (boundary-definition-overview-lines definition)))))

(views:defview 👀sides-crossing-condition
    (definition hyperdoc::boundary-definition)
  (views:html-view :title "Sides and crossing condition" :priority 2
                   (boundary-preformatted-view
                    (boundary-definition-sides-lines definition))))

(views:defview 👀permitted-blocked-operations
    (definition hyperdoc::boundary-definition)
  (views:html-view :title "Permitted and blocked operations" :priority 3
                   (boundary-preformatted-view
                    (boundary-definition-operations-lines definition))))

(views:defview 👀failure-classifications
    (definition hyperdoc::boundary-definition)
  (views:html-view :title "Failure classifications" :priority 4
                   (boundary-preformatted-view
                    (boundary-definition-failure-lines definition))))

(views:defview 👀adjacent-surfaces-stages
    (definition hyperdoc::boundary-definition)
  (views:html-view :title "Adjacent surfaces and stages" :priority 5
                   (views:html
                    (:p (views:esc
                         "Definitions declare adjacent surfaces; concrete stages appear on boundary instances.")))
                   (boundary-preformatted-view
                    (boundary-definition-adjacent-lines definition))))

(views:defview 👀related-boundaries (definition hyperdoc::boundary-definition)
  (views:html-view :title "Related boundaries" :priority 6
                   (boundary-preformatted-view
                    (boundary-definition-related-lines definition))))

(views:defview 👀source-evidence-code-path
    (definition hyperdoc::boundary-definition)
  (views:html-view :title "Source evidence / code path" :priority 7
                   (boundary-preformatted-view
                    (boundary-source-evidence-lines
                     (hyperdoc::boundary-definition-source-evidence-of definition)))))

(views:defview 👀overview (instance hyperdoc::boundary-instance)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:p (views:esc
                         (or (hyperdoc::summary-of
                              (hyperdoc::boundary-instance-definition-of instance))
                             "Concrete realized boundary crossing or block.")))
                    (boundary-preformatted-view
                     (boundary-instance-overview-lines instance)))))

(views:defview 👀boundary-state (instance hyperdoc::boundary-instance)
  (views:html-view :title "Boundary state" :priority 2
                   (boundary-preformatted-view
                    (boundary-instance-state-lines instance))))

(views:defview 👀crossing-attempt (instance hyperdoc::boundary-instance)
  (views:html-view :title "Crossing attempt" :priority 3
                   (boundary-preformatted-view
                    (boundary-instance-crossing-lines instance))))

(views:defview 👀evidence (instance hyperdoc::boundary-instance)
  (views:html-view :title "Evidence" :priority 4
                   (boundary-preformatted-view
                    (boundary-instance-evidence-lines instance))))

(views:defview 👀failure-analysis (instance hyperdoc::boundary-instance)
  (views:html-view :title "Failure analysis" :priority 5
                   (boundary-preformatted-view
                    (boundary-instance-failure-lines instance))))

(views:defview 👀adjacent-stages-surfaces (instance hyperdoc::boundary-instance)
  (views:html-view :title "Adjacent stages and surfaces" :priority 6
                   (boundary-preformatted-view
                    (boundary-instance-adjacent-lines instance))))

(views:defview 👀source-evidence-code-path
    (instance hyperdoc::boundary-instance)
  (views:html-view :title "Source evidence / code path" :priority 7
                   (boundary-preformatted-view
                    (append
                     (list "Definition source evidence:")
                     (boundary-source-evidence-lines
                      (hyperdoc::boundary-definition-source-evidence-of
                       (hyperdoc::boundary-instance-definition-of instance)))
                     (if (hyperdoc::boundary-instance-source-evidence-of instance)
                         (append
                          (list ""
                                "Instance-specific source evidence:")
                          (boundary-source-evidence-lines
                           (hyperdoc::boundary-instance-source-evidence-of instance)))
                         '())))))
