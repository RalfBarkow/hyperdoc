;;;; Whyline-style output questions demo

(in-package :HYPERDOC)


(defclass whyline-demo-run nil
          ((id :initarg :id :reader whyline-demo-id-of)
           (title :initarg :title :reader whyline-demo-title-of)
           (observation :initarg :observation :reader
            whyline-demo-observation-of)
           (questions :initarg :questions :reader whyline-demo-questions-of)))


(defclass whyline-demo-question nil
          ((id :initarg :id :reader whyline-demo-id-of)
           (title :initarg :title :reader whyline-demo-title-of)
           (kind :initarg :kind :reader whyline-demo-kind-of)
           (observation :initarg :observation :reader
            whyline-demo-observation-of)
           (expected :initarg :expected :initform nil :reader
            whyline-demo-expected-of)))


(defclass whyline-demo-answer nil
          ((id :initarg :id :reader whyline-demo-id-of)
           (title :initarg :title :reader whyline-demo-title-of)
           (question :initarg :question :reader whyline-demo-question-of)
           (summary :initarg :summary :reader whyline-demo-summary-of)
           (events :initarg :events :reader whyline-demo-events-of)
           (graph :initarg :graph :reader whyline-demo-graph-of)))


(defmethod print-object ((object whyline-demo-run) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (whyline-demo-title-of object))))


(defmethod print-object ((object whyline-demo-question) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (whyline-demo-title-of object))))


(defmethod print-object ((object whyline-demo-answer) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (whyline-demo-title-of object))))


(defun whyline-color-demo-observation ()
  "Observed stroke color is purple. Expected behavior: the blue slider should contribute the blue component.")


(defun whyline-color-demo-questions ()
  (list
   (make-instance 'whyline-demo-question :id "why-did-purple" :title
                  "Why did the stroke color become purple?" :kind :why-did
                  :observation (whyline-color-demo-observation))
   (make-instance 'whyline-demo-question :id "why-not-blue-slider" :title
                  "Why didn’t the blue slider supply the blue component?" :kind
                  :why-not :observation (whyline-color-demo-observation)
                  :expected
                  "Blue component should come from the blue slider.")))


(defun whyline-run-questions (run) (whyline-demo-questions-of run))


(defun whyline-color-demo-events ()
  (list (list :event :read :source "red-slider" :value 192)
        (list :event :read :source "green-slider" :value 64 :note
              "used where blue was expected")
        (list :event :missing-read :source "blue-slider" :expected-value 255)
        (list :event :call :function "make-rgb-color")
        (list :event :call :function "paint-stroke")
        (list :event :output :property "stroke color" :value "purple")))


(defun whyline-color-demo-answer-code-path-graph ()
  (make-code-path-graph :id "whyline-color-demo-answer-graph" :title
                        "Whyline color demo answer graph" :summary
                        "Small Whyline-style answer graph: observed output back to value source and missed expected source."
                        :entrypoints
                        (list
                         (list :id "observed-output" :label "Observed output"
                               :summary
                               "The stroke rendered with the wrong color."))
                        :nodes
                        (list
                         (list :id "observed-output" :label
                               "Stroke color = purple" :role :runtime-value
                               :kind :observed-output)
                         (list :id "paint-stroke" :label
                               "paint-stroke used current color" :role
                               :runtime-step :kind :function-call
                               :source-function "paint-stroke")
                         (list :id "make-color" :label
                               "make-rgb-color assembled components" :role
                               :runtime-step :kind :function-call
                               :source-function "make-rgb-color")
                         (list :id "red-slider" :label "red slider value" :role
                               :runtime-input :kind :value-source)
                         (list :id "green-slider" :label
                               "green slider value used as blue component"
                               :role :runtime-input :kind :wrong-value-source)
                         (list :id "blue-slider" :label "blue slider value"
                               :role :runtime-input :kind
                               :expected-value-source))
                        :edges
                        (list
                         (list :from "red-slider" :to "make-color" :kind :read
                               :status :active)
                         (list :from "green-slider" :to "make-color" :kind
                               :read :status :active)
                         (list :from "blue-slider" :to "make-color" :kind :read
                               :status :suppressed)
                         (list :from "make-color" :to "paint-stroke" :kind
                               :result :status :active)
                         (list :from "paint-stroke" :to "observed-output" :kind
                               :terminal :status :active))
                        :trace-events (whyline-color-demo-events) :focus-paths
                        (list
                         (list :id "why-did-purple" :label
                               "Why did the stroke color become purple?"
                               :node-ids
                               '("green-slider" "make-color" "paint-stroke"
                                 "observed-output"))
                         (list :id "why-not-blue" :label
                               "Why didn’t the blue slider supply the blue component?"
                               :node-ids
                               '("blue-slider" "make-color" "paint-stroke"
                                 "observed-output")))))


(defun whyline-color-demo-why-did-answer ()
  (make-instance 'whyline-demo-answer :id "why-did-purple-answer" :title
                 "Why did the stroke color become purple?" :question
                 (first (whyline-color-demo-questions)) :summary
                 "The color constructor read the green slider value in the position where the blue slider value was expected."
                 :events (whyline-color-demo-events) :graph
                 (whyline-color-demo-answer-code-path-graph)))


(defun whyline-color-demo-why-not-answer ()
  (make-instance 'whyline-demo-answer :id "why-not-blue-slider-answer" :title
                 "Why didn’t the blue slider supply the blue component?"
                 :question (second (whyline-color-demo-questions)) :summary
                 "The expected blue-slider dependency is present in the intended path but suppressed in the observed path."
                 :events (whyline-color-demo-events) :graph
                 (whyline-color-demo-answer-code-path-graph)))


(defun whyline-answer-question (run question)
  (declare (ignore run))
  (ecase (whyline-demo-kind-of question)
    (:why-did (whyline-color-demo-why-did-answer))
    (:why-not (whyline-color-demo-why-not-answer))))


(defun whyline-color-demo-run ()
  (make-instance 'whyline-demo-run :id "whyline-color-demo-run" :title
                 "Whyline color demo run" :observation
                 (whyline-color-demo-observation) :questions
                 (whyline-color-demo-questions)))

