;;;; Structural SCXML parser for HyperDoc compiler MVP
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/scxml)

(defun %blank-string-p (value)
  (or (null value)
      (string= ""
               (string-trim '(#\Space #\Tab #\Newline #\Return)
                            value))))

(defun %normalize-xml-attribute (value)
  (unless (%blank-string-p value)
    (string-trim '(#\Space #\Tab #\Newline #\Return) value)))

(defun xml-local-name (node-or-name)
  (let* ((raw
          (cond
            ((typep node-or-name 'plump-dom:element)
             (plump:tag-name node-or-name))
            ((symbolp node-or-name)
             (symbol-name node-or-name))
            (t
             node-or-name)))
         (name (string raw))
         (colon (position #\: name :from-end t))
         (brace (position #\} name :from-end t))
         (start
          (cond
            (brace (1+ brace))
            (colon (1+ colon))
            (t 0))))
    (string-downcase (subseq name start))))

(defun xml-attribute (element attribute-name)
  (let ((target-name (xml-local-name attribute-name))
        (result nil))
    (maphash (lambda (key value)
               (when (and (null result)
                          (string= (xml-local-name key)
                                   target-name))
                 (setf result value)))
             (plump:attributes element))
    result))

(defun xml-element-children (element)
  (loop for child across (plump:children element)
        when (typep child 'plump-dom:element)
        collect child))

(defun xml-first-child-element-named (element child-name)
  (let ((target-name (xml-local-name child-name)))
    (find target-name
          (xml-element-children element)
          :key #'xml-local-name
          :test #'string=)))

(defun xml-child-elements-named (element child-name)
  (let ((target-name (xml-local-name child-name)))
    (remove-if-not (lambda (child)
                     (string= target-name
                              (xml-local-name child)))
                   (xml-element-children element))))

(defun %record-parse-problem (collector severity code message &optional context)
  (funcall collector
           (list :severity severity
                 :code code
                 :message message
                 :context context)))

(defun %parse-onentry-actions (onentry-element state-id problem-collector)
  (let ((actions '()))
    (dolist (child (xml-element-children onentry-element))
      (let ((child-name (xml-local-name child)))
        (cond
          ((string= child-name "log")
           (push (make-instance 'scxml-action
                                :kind :log
                                :attributes
                                (list :label (xml-attribute child "label")
                                      :expr (xml-attribute child "expr")))
                 actions))
          ((string= child-name "raise")
           (let ((event (%normalize-xml-attribute
                         (xml-attribute child "event"))))
             (when (%blank-string-p event)
               (%record-parse-problem
                problem-collector
                :error
                :raise-missing-event
                "<raise> action must have a non-empty event attribute."
                (list :state state-id)))
             (push (make-instance 'scxml-action
                                  :kind :raise
                                  :attributes (list :event event))
                   actions)))
          (t
           (%record-parse-problem
            problem-collector
            :error
            :unsupported-onentry-action
            (format nil "Unsupported <onentry> child <~A> in MVP subset."
                    child-name)
            (list :state state-id
                  :element child-name))))))
    (nreverse actions)))

(defun %parse-transition-element (transition-element state-id problem-collector)
  (let* ((transition-id (%normalize-xml-attribute
                         (xml-attribute transition-element "id")))
         (event (%normalize-xml-attribute
                 (xml-attribute transition-element "event")))
         (target (%normalize-xml-attribute
                  (xml-attribute transition-element "target")))
         (cond-expression (%normalize-xml-attribute
                           (xml-attribute transition-element "cond"))))
    (when cond-expression
      (%record-parse-problem
       problem-collector
       :error
       :unsupported-transition-cond
       "Transition cond is not supported in MVP subset."
       (list :state state-id
             :transition-id transition-id
             :cond cond-expression)))
    (when (%blank-string-p event)
      (%record-parse-problem
       problem-collector
       :error
       :unsupported-eventless-transition
       "Eventless transitions are not supported in MVP subset."
       (list :state state-id
             :transition-id transition-id)))
    (when (%blank-string-p target)
      (%record-parse-problem
       problem-collector
       :error
       :transition-missing-target
       "Transition must define a non-empty target attribute."
       (list :state state-id
             :transition-id transition-id)))
    (when (and target
               (> (length (remove-if (lambda (token)
                                       (string= token ""))
                                     (uiop:split-string
                                      target
                                      :separator '(#\Space #\Tab #\Newline #\Return))))
                  1))
      (%record-parse-problem
       problem-collector
       :error
       :unsupported-multiple-transition-targets
       "Transitions with multiple targets are not supported in MVP subset."
       (list :state state-id
             :transition-id transition-id
             :target target)))
    (dolist (transition-child (xml-element-children transition-element))
      (%record-parse-problem
       problem-collector
       :error
       :unsupported-transition-child
       (format nil "Unsupported <transition> child <~A> in MVP subset."
               (xml-local-name transition-child))
       (list :state state-id
             :transition-id transition-id
             :element (xml-local-name transition-child))))
    (make-instance 'scxml-transition
                   :event event
                   :target target
                   :id transition-id
                   :source-state-id state-id)))

(defun %parse-state-element (state-element &key final-p problem-collector)
  (let* ((state-id (%normalize-xml-attribute
                    (xml-attribute state-element "id")))
         (onentry-actions '())
         (transitions '())
         (seen-onentry nil))
    (when (%blank-string-p state-id)
      (%record-parse-problem
       problem-collector
       :error
       :state-missing-id
       "State/final must define a non-empty id attribute."
       (list :element (if final-p "final" "state"))))
    (dolist (child (xml-element-children state-element))
      (let ((child-name (xml-local-name child)))
        (cond
          ((string= child-name "onentry")
           (if seen-onentry
               (%record-parse-problem
                problem-collector
                :error
                :multiple-onentry-blocks
                "Multiple <onentry> blocks per state are not supported in MVP subset."
                (list :state state-id))
               (setf onentry-actions
                     (%parse-onentry-actions child
                                             state-id
                                             problem-collector)
                     seen-onentry t)))
          ((string= child-name "transition")
           (push (%parse-transition-element child
                                            state-id
                                            problem-collector)
                 transitions))
          ((or (string= child-name "state")
               (string= child-name "final"))
           (%record-parse-problem
            problem-collector
            :error
            :unsupported-nested-state
            "Nested <state>/<final> is not supported in MVP subset."
            (list :state state-id
                  :element child-name)))
          ((member child-name
                   '("parallel" "history" "invoke" "send" "assign" "script" "datamodel")
                   :test #'string=)
           (%record-parse-problem
            problem-collector
            :error
            :unsupported-state-child
            (format nil "Unsupported state child <~A> in MVP subset."
                    child-name)
            (list :state state-id
                  :element child-name)))
          (t
           (%record-parse-problem
            problem-collector
            :error
            :unsupported-state-child
            (format nil "Unsupported state child <~A> in MVP subset."
                    child-name)
            (list :state state-id
                  :element child-name))))))
    (make-instance 'scxml-state
                   :id state-id
                   :final-p final-p
                   :onentry-actions onentry-actions
                   :transitions (nreverse transitions))))

(defun %find-scxml-root-element (dom)
  (find "scxml"
        (xml-element-children dom)
        :key #'xml-local-name
        :test #'string=))

(defun parse-scxml-string (string &key source-pathname)
  (let ((parse-problems '()))
    (flet ((collect-problem (problem)
             (push problem parse-problems)))
      (let* ((dom (plump:parse string))
             (root (%find-scxml-root-element dom)))
        (unless root
          (error "SCXML parser could not find <scxml> root element."))
        (let ((states '()))
          (dolist (child (xml-element-children root))
            (let ((child-name (xml-local-name child)))
              (cond
                ((string= child-name "state")
                 (push (%parse-state-element child
                                             :final-p nil
                                             :problem-collector #'collect-problem)
                       states))
                ((string= child-name "final")
                 (push (%parse-state-element child
                                             :final-p t
                                             :problem-collector #'collect-problem)
                       states))
                ((member child-name
                         '("parallel"
                           "history"
                           "invoke"
                           "send"
                           "assign"
                           "script"
                           "datamodel")
                         :test #'string=)
                 (%record-parse-problem
                  #'collect-problem
                  :error
                  :unsupported-chart-child
                  (format nil "Unsupported direct <scxml> child <~A> in MVP subset."
                          child-name)
                  (list :element child-name)))
                (t
                 (%record-parse-problem
                  #'collect-problem
                  :error
                  :unsupported-chart-child
                  (format nil "Unsupported direct <scxml> child <~A> in MVP subset."
                          child-name)
                  (list :element child-name))))))
          (make-instance 'scxml-chart
                         :name (%normalize-xml-attribute
                                (xml-attribute root "name"))
                         :initial-state (%normalize-xml-attribute
                                         (xml-attribute root "initial"))
                         :states (nreverse states)
                         :source-pathname source-pathname
                         :parse-problems (nreverse parse-problems)))))))

(defun parse-scxml-file (pathname)
  (let ((resolved-pathname (pathname pathname)))
    (parse-scxml-string (uiop:read-file-string resolved-pathname)
                        :source-pathname resolved-pathname)))
