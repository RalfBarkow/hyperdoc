;;;; Generic inspector views for first-class surface objects
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun surface-plist-pairs (plist)
  (loop for (key value) on plist by #'cddr
        collect (cons key value)))

(defun surface-string (value)
  (cond
    ((null value) "n/a")
    ((typep value 'hyperdoc::surface-definition)
     (hyperdoc::title-of value))
    ((typep value 'hyperdoc::surface-instance)
     (or (hyperdoc::title-of value)
         (hyperdoc::title-of
          (hyperdoc::surface-instance-definition-of value))))
    ((stringp value) value)
    ((keywordp value) (string-downcase (string value)))
    ((symbolp value) (string-downcase (string value)))
    ((and (listp value) (hyperdoc::surface-plist-p value))
     (surface-string (surface-plist-pairs value)))
    ((and (listp value) (every #'consp value))
     (format nil "~{~A=~A~^; ~}"
             (mapcar (lambda (entry)
                       (format nil "~A"
                               (surface-string (cdr entry))))
                     value)))
    ((listp value)
     (format nil "~{~A~^, ~}" (mapcar #'surface-string value)))
    (t
     (format nil "~A" value))))

(defun surface-lines-to-string (lines)
  (with-output-to-string (stream)
    (dolist (line lines)
      (write-string line stream)
      (terpri stream))))

(defun surface-entry-lines (entries header key-specs)
  (if entries
      (cons
       header
       (mapcar
        (lambda (entry)
          (format nil "~{~A~^ | ~}"
                  (mapcar (lambda (key)
                            (surface-string
                             (hyperdoc::surface-item-value entry key)))
                          key-specs)))
        entries))
      (list "No entries recorded.")))

(defun surface-definition-overview-lines (definition)
  (list
   (format nil "Title: ~A" (hyperdoc::title-of definition))
   (format nil "Surface kind: ~A"
           (surface-string
            (hyperdoc::surface-definition-surface-kind-of definition)))
   (format nil "Layer: ~A"
           (surface-string
            (hyperdoc::surface-definition-layer-of definition)))
   (format nil "Access mode: ~A"
           (surface-string
            (hyperdoc::surface-definition-access-mode-of definition)))
   (format nil "Audience: ~A"
           (surface-string
            (hyperdoc::surface-definition-audience-of definition)))
   (format nil "Scope: ~A"
           (surface-string
            (hyperdoc::surface-definition-scope-of definition)))))

(defun surface-definition-classification-lines (definition)
  (append
   (list
    (format nil "Surface kind: ~A"
            (surface-string
             (hyperdoc::surface-definition-surface-kind-of definition)))
    (format nil "Layer: ~A"
            (surface-string
             (hyperdoc::surface-definition-layer-of definition)))
    (format nil "Access mode: ~A"
            (surface-string
             (hyperdoc::surface-definition-access-mode-of definition)))
    ""
    "Structural findings:")
   (mapcar
    (lambda (entry)
      (format nil "- [~A] ~A: ~A"
              (surface-string
               (hyperdoc::surface-item-value entry :status))
              (hyperdoc::surface-item-value entry :label)
              (hyperdoc::surface-item-value entry :detail)))
    (hyperdoc::surface-definition-findings definition))))

(defun surface-definition-capability-lines (definition)
  (surface-entry-lines
   (hyperdoc::surface-definition-capabilities-of definition)
   "capability | mode | detail"
   '(:capability :mode :detail)))

(defun surface-definition-io-lines (definition)
  (append
   (list "Inputs:"
         "")
   (surface-entry-lines
    (hyperdoc::surface-definition-inputs-of definition)
    "input | detail"
    '(:input :detail))
   (list ""
         "Outputs:"
         "")
   (surface-entry-lines
    (hyperdoc::surface-definition-outputs-of definition)
    "output | detail"
    '(:output :detail))
   (list ""
         "Evidence kinds:")
   (if (hyperdoc::surface-definition-evidence-kinds-of definition)
       (mapcar (lambda (kind)
                 (format nil "- ~A" (surface-string kind)))
               (hyperdoc::surface-definition-evidence-kinds-of definition))
       '("- none"))))

(defun surface-definition-boundary-lines (definition)
  (surface-entry-lines
   (hyperdoc::surface-definition-boundary-rules-of definition)
   "rule | detail"
   '(:rule :detail)))

(defun surface-definition-related-lines (definition)
  (surface-entry-lines
   (hyperdoc::surface-definition-related-surfaces-of definition)
   "surface | detail"
   '(:surface :detail)))

(defun surface-source-evidence-lines (entries)
  (if entries
      (cons
       "layer | reference | detail"
       (mapcar
        (lambda (entry)
          (format nil "~A | ~A | ~A"
                  (surface-string
                   (hyperdoc::surface-item-value entry :layer))
                  (surface-string
                   (hyperdoc::surface-item-value entry :reference))
                  (surface-string
                   (hyperdoc::surface-item-value entry :detail))))
        entries))
      (list "No source evidence recorded.")))

(defun surface-instance-overview-lines (instance)
  (list
   (format nil "Surface: ~A"
           (hyperdoc::title-of
            (hyperdoc::surface-instance-definition-of instance)))
   (format nil "Subject: ~A"
           (surface-string
            (hyperdoc::surface-instance-subject-of instance)))
   (format nil "Status: ~A"
           (surface-string
            (hyperdoc::surface-instance-status-of instance)))
   (format nil "Access mode: ~A"
           (surface-string
            (hyperdoc::surface-definition-access-mode-of
             (hyperdoc::surface-instance-definition-of instance))))
   (format nil "Current boundary state entries: ~D"
           (length (hyperdoc::surface-instance-current-boundary-state-of instance)))))

(defun surface-instance-boundary-lines (instance)
  (append
   (list
    (format nil "Status: ~A"
            (surface-string
             (hyperdoc::surface-instance-status-of instance)))
    ""
    "Current boundary state:")
   (surface-entry-lines
    (hyperdoc::surface-instance-current-boundary-state-of instance)
    "label | detail"
    '(:label :detail))
   (list ""
         "Auth requirements:")
   (surface-entry-lines
    (hyperdoc::surface-instance-auth-requirements-of instance)
    "requirement | detail"
    '(:requirement :detail))))

(defun surface-instance-capability-lines (instance)
  (append
   (surface-entry-lines
    (hyperdoc::surface-instance-active-capabilities-of instance)
    "capability | detail"
    '(:capability :detail))
   (list ""
         "Entrypoints:")
   (surface-entry-lines
    (hyperdoc::surface-instance-entrypoints-of instance)
    "entrypoint | detail"
    '(:entrypoint :detail))))

(defun surface-instance-evidence-lines (instance)
  (surface-entry-lines
   (hyperdoc::surface-instance-visible-evidence-of instance)
   "kind | detail"
   '(:kind :detail)))

(defun surface-instance-failure-lines (instance)
  (append
   (surface-entry-lines
    (hyperdoc::surface-instance-failure-surfaces-of instance)
    "surface | detail"
    '(:surface :detail))
   (list ""
         "Surface-instance findings:")
   (mapcar
    (lambda (entry)
      (format nil "- [~A] ~A: ~A"
              (surface-string
               (hyperdoc::surface-item-value entry :status))
              (hyperdoc::surface-item-value entry :label)
              (hyperdoc::surface-item-value entry :detail)))
    (hyperdoc::surface-instance-findings instance))))

(defun surface-instance-adjacent-lines (instance)
  (surface-entry-lines
   (hyperdoc::surface-instance-adjacent-surfaces-of instance)
   "surface | detail"
   '(:surface :detail)))

(defun surface-preformatted-view (lines)
  (views:html
    (:pre (views:esc (surface-lines-to-string lines)))))

(defmethod views:text-representation ((definition hyperdoc::surface-definition))
  (or (hyperdoc::title-of definition)
      "Surface"))

(defmethod views:text-representation ((instance hyperdoc::surface-instance))
  (or (hyperdoc::title-of instance)
      (views:text-representation
       (hyperdoc::surface-instance-definition-of instance))
      "Surface instance"))

(views:defview 👀overview (definition hyperdoc::surface-definition)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:p (views:esc
           (or (hyperdoc::summary-of definition)
               "Reusable surface definition.")))
      (surface-preformatted-view
       (surface-definition-overview-lines definition)))))

(views:defview 👀classification (definition hyperdoc::surface-definition)
  (views:html-view :title "Classification" :priority 2
    (surface-preformatted-view
     (surface-definition-classification-lines definition))))

(views:defview 👀capabilities (definition hyperdoc::surface-definition)
  (views:html-view :title "Capabilities" :priority 3
    (surface-preformatted-view
     (surface-definition-capability-lines definition))))

(views:defview 👀inputs-outputs (definition hyperdoc::surface-definition)
  (views:html-view :title "Inputs and outputs" :priority 4
    (surface-preformatted-view
     (surface-definition-io-lines definition))))

(views:defview 👀boundary-rules (definition hyperdoc::surface-definition)
  (views:html-view :title "Boundary rules" :priority 5
    (surface-preformatted-view
     (surface-definition-boundary-lines definition))))

(views:defview 👀related-surfaces (definition hyperdoc::surface-definition)
  (views:html-view :title "Related surfaces" :priority 6
    (surface-preformatted-view
     (surface-definition-related-lines definition))))

(views:defview 👀source-evidence-code-path
    (definition hyperdoc::surface-definition)
  (views:html-view :title "Source evidence / code path" :priority 7
    (surface-preformatted-view
     (surface-source-evidence-lines
      (hyperdoc::surface-definition-source-evidence-of definition)))))

(views:defview 👀overview (instance hyperdoc::surface-instance)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:p (views:esc
           (or (hyperdoc::summary-of
                (hyperdoc::surface-instance-definition-of instance))
               "Concrete realized surface instance.")))
      (surface-preformatted-view
       (surface-instance-overview-lines instance)))))

(views:defview 👀boundary-state (instance hyperdoc::surface-instance)
  (views:html-view :title "Boundary state" :priority 2
    (surface-preformatted-view
     (surface-instance-boundary-lines instance))))

(views:defview 👀active-capabilities (instance hyperdoc::surface-instance)
  (views:html-view :title "Active capabilities" :priority 3
    (surface-preformatted-view
     (surface-instance-capability-lines instance))))

(views:defview 👀evidence (instance hyperdoc::surface-instance)
  (views:html-view :title "Evidence" :priority 4
    (surface-preformatted-view
     (surface-instance-evidence-lines instance))))

(views:defview 👀failure-surfaces (instance hyperdoc::surface-instance)
  (views:html-view :title "Failure surfaces" :priority 5
    (surface-preformatted-view
     (surface-instance-failure-lines instance))))

(views:defview 👀adjacent-surfaces (instance hyperdoc::surface-instance)
  (views:html-view :title "Adjacent surfaces" :priority 6
    (surface-preformatted-view
     (surface-instance-adjacent-lines instance))))

(views:defview 👀source-evidence-code-path
    (instance hyperdoc::surface-instance)
  (views:html-view :title "Source evidence / code path" :priority 7
    (surface-preformatted-view
     (surface-source-evidence-lines
      (hyperdoc::surface-instance-source-evidence-of instance)))))
