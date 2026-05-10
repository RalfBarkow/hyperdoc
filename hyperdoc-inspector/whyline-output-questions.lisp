;;;; Inspector views for Whyline-style output questions

(in-package :HYPERDOC/INSPECTOR)


(defmethod views:text-representation ((run hyperdoc::whyline-demo-run))
  (hyperdoc::whyline-demo-title-of run))


(defmethod views:text-representation
           ((question hyperdoc::whyline-demo-question))
  (hyperdoc::whyline-demo-title-of question))


(defmethod views:text-representation ((answer hyperdoc::whyline-demo-answer))
  (hyperdoc::whyline-demo-title-of answer))


(views:defview whyline-demo-run-overview (run hyperdoc::whyline-demo-run)
               (views:html-view :title "Overview" :priority 1
                                (views:html
                                  (:h3
                                   (cl-who:esc
                                    (hyperdoc::whyline-demo-title-of run)))
                                  (:p
                                   (cl-who:esc
                                    (hyperdoc::whyline-demo-observation-of
                                     run))))))


(views:defview whyline-demo-run-questions (run hyperdoc::whyline-demo-run)
               (let ((why-did (hyperdoc::whyline-color-demo-why-did-answer))
                     (why-not (hyperdoc::whyline-color-demo-why-not-answer)))
                 (declare (ignore run))
                 (views:html-view :title "Questions" :priority 0
                                  (views:html
                                    (:p
                                     "Choose the question from the observed output, not from a guessed source location.")
                                    (:ul
                                     (:li
                                      (views:object-ref why-did :display
                                                        "Why did the stroke color become purple?"
                                                        :select
                                                        "Answer graph"))
                                     (:li
                                      (views:object-ref why-not :display
                                                        "Why didn’t the blue slider supply the blue component?"
                                                        :select
                                                        "Answer graph")))))))


(views:defview whyline-demo-answer-overview
               (answer hyperdoc::whyline-demo-answer)
               (views:html-view :title "Overview" :priority 1
                                (views:html
                                  (:h3
                                   (cl-who:esc
                                    (hyperdoc::whyline-demo-title-of answer)))
                                  (:p
                                   (cl-who:esc
                                    (hyperdoc::whyline-demo-summary-of
                                     answer))))))


(views:defview whyline-demo-answer-graph (answer hyperdoc::whyline-demo-answer)
               (let ((graph (hyperdoc::whyline-demo-graph-of answer)))
                 (views:html-view :title "Answer graph" :priority 0
                                  (views:html
                                    (:p
                                     "The answer is represented as the existing HyperDoc code-path graph object.")
                                    (:ul
                                     (:li
                                      (views:object-ref graph :display
                                                        "Open graph overview"
                                                        :select "Overview"))
                                     (:li
                                      (views:object-ref graph :display
                                                        "Open focused paths"
                                                        :select
                                                        "Focused paths"))
                                     (:li
                                      (views:object-ref graph :display
                                                        "Open DOT export"
                                                        :select
                                                        "DOT export")))))))


(views:defview whyline-demo-answer-events
               (answer hyperdoc::whyline-demo-answer)
               (views:html-view :title "Events" :priority 2
                                (views:html
                                  (:table :class "inspector-table"
                                   (:tr (:th "Event") (:th "Source")
                                    (:th "Value / note"))
                                   (dolist
                                       (event
                                        (hyperdoc::whyline-demo-events-of
                                         answer))
                                     (views:html
                                       (:tr
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (format nil "~A"
                                                   (getf event :event)))))
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (or (getf event :source)
                                               (getf event :function)
                                               (getf event :property) ""))))
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (format nil "~S"
                                                   (or (getf event :value)
                                                       (getf event
                                                             :expected-value)
                                                       (getf event :note)
                                                       ""))))))))))))


(views:defview whyline-demo-answer-dot (answer hyperdoc::whyline-demo-answer)
               (views:html-view :title "DOT export" :priority 3
                                (views:html
                                  (:pre
                                   (cl-who:esc
                                    (hyperdoc::code-path-graph-dot-text
                                     (hyperdoc::whyline-demo-graph-of
                                      answer)))))))

