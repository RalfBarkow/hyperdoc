;;;; Moldable Inspector views for source-backed FedWiki navigation traces.

(in-package #:dreyeck/fedwiki-navigation/prototype)

(defmethod html-inspector-views:text-representation
    ((trace navigation-trace))
  (format nil "FedWiki navigation trace (~D steps, ~A)"
          (length (navigation-trace-steps-of trace))
          (navigation-trace-result-of trace)))

(defmethod html-inspector-views:text-representation
    ((step navigation-step))
  (format nil "Step ~D: ~A"
          (navigation-step-number-of step)
          (navigation-step-command-text-of step)))

(defmethod html-inspector-views:text-representation
    ((position navigation-position))
  (format nil "~A / ~A"
          (navigation-position-current-page-slug-of position)
          (navigation-position-current-item-id-of position)))

(defmethod html-inspector-views:text-representation
    ((reference navigation-source-reference))
  (format nil "Implementation ~S"
          (navigation-source-reference-producer-symbol-of reference)))

(defmethod html-inspector-views:text-representation
    ((source navigation-source-file))
  (namestring (navigation-source-file-relative-pathname-of source)))

(defun render-navigation-row (label value &key object)
  (html-inspector-views:html
    (:tr
     (:td (html-inspector-views:esc label))
     (:td
      (if object
          (html-inspector-views:object-ref value)
          (html-inspector-views:html
            (:code
             (html-inspector-views:esc
              (prin1-to-string value)))))))))

(defun navigation-position-view (position title priority)
  (html-inspector-views:html-view :title title :priority priority
    (html-inspector-views:html
      (:table :class "inspector-table"
              (render-navigation-row
               "Page"
               (navigation-position-current-page-slug-of position))
              (render-navigation-row
               "Item"
               (navigation-position-current-item-id-of position))
              (render-navigation-row
               "Item number"
               (navigation-position-current-item-number position))
              (render-navigation-row
               "Lineup"
               (navigation-position-lineup-slugs position))
              (render-navigation-row
               "Location"
               (navigation-position-location-of position))))))

(html-inspector-views:defview navigation-trace-view
    (trace navigation-trace)
  (html-inspector-views:html-view :title "Trace" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (render-navigation-row
               "Initial session"
               (navigation-trace-initial-session-of trace)
               :object t)
              (render-navigation-row
               "Commands"
               (navigation-trace-commands-of trace))
              (render-navigation-row
               "Final session"
               (navigation-trace-final-session-of trace)
               :object t)
              (render-navigation-row
               "Result"
               (navigation-trace-result-of trace))))))

(html-inspector-views:defview navigation-trace-steps-view
    (trace navigation-trace)
  (html-inspector-views:html-view :title "Steps" :priority 2
    (html-inspector-views:html
      (:table :class "inspector-table"
              (:tr
               (:th (html-inspector-views:esc "#"))
               (:th (html-inspector-views:esc "Command"))
               (:th (html-inspector-views:esc "Before"))
               (:th (html-inspector-views:esc "After")))
              (dolist (step (navigation-trace-steps-of trace))
                (html-inspector-views:html
                  (:tr
                   (:td
                    (html-inspector-views:esc
                     (princ-to-string
                      (navigation-step-number-of step))))
                   (:td
                    (html-inspector-views:object-ref
                     step
                     :display
                     (navigation-step-command-text-of step)))
                   (:td
                    (html-inspector-views:esc
                     (navigation-position-current-item-id-of
                      (navigation-step-before-of step))))
                   (:td
                    (html-inspector-views:esc
                     (navigation-position-current-item-id-of
                      (navigation-step-after-of step)))))))))))

(html-inspector-views:defview navigation-step-before-view
    (step navigation-step)
  (navigation-position-view
   (navigation-step-before-of step) "Before" 1))

(html-inspector-views:defview navigation-step-command-view
    (step navigation-step)
  (html-inspector-views:html-view :title "Command" :priority 2
    (html-inspector-views:html
      (:table :class "inspector-table"
              (render-navigation-row
               "Original text"
               (navigation-step-command-text-of step))
              (render-navigation-row
               "Resolved operation"
               (navigation-step-operation-of step)
               :object t)
              (render-navigation-row
               "Arguments"
               (navigation-step-arguments-of step))
              (render-navigation-row
               "Outcome"
               (navigation-step-outcome-of step)
               :object t)))))

(html-inspector-views:defview navigation-step-after-view
    (step navigation-step)
  (navigation-position-view
   (navigation-step-after-of step) "After" 3))

(html-inspector-views:defview navigation-step-explanation-view
    (step navigation-step)
  (html-inspector-views:html-view :title "Explanation" :priority 4
    (html-inspector-views:html
      (:p
       (html-inspector-views:esc
        (navigation-step-explanation step)))
      (when (navigation-step-link-observation-of step)
        (html-inspector-views:html
          (:p
           (html-inspector-views:object-ref
            (navigation-step-link-observation-of step))))))))

(html-inspector-views:defview navigation-step-implementation-view
    (step navigation-step)
  (html-inspector-views:html-view :title "Implementation" :priority 5
    (html-inspector-views:html
      (:table :class "inspector-table"
              (render-navigation-row
               "Semantic producer"
               (navigation-step-implementation-of step)
               :object t)
              (render-navigation-row
               "Dispatcher"
               (navigation-step-dispatcher-implementation-of step)
               :object t)))))

(html-inspector-views:defview navigation-position-overview-view
    (position navigation-position)
  (navigation-position-view position "Overview" 1))

(html-inspector-views:defview navigation-source-reference-implementation-view
    (reference navigation-source-reference)
  (html-inspector-views:html-view :title "Implementation" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (render-navigation-row
               "Qualified producer symbol"
               (navigation-source-reference-producer-symbol-of reference)
               :object t)
              (render-navigation-row
               "Owning ASDF system"
               (navigation-source-reference-system reference)
               :object t)
              (render-navigation-row
               "ASDF component"
               (navigation-source-reference-component reference)
               :object t)))))

(html-inspector-views:defview navigation-source-reference-source-view
    (reference navigation-source-reference)
  (html-inspector-views:html-view :title "Source" :priority 2
    (html-inspector-views:html
      (:p
       (html-inspector-views:object-ref
        (navigation-source-reference-source-file reference)
        :display
        (namestring
         (navigation-source-reference-relative-pathname reference)))))))

(html-inspector-views:defview navigation-source-file-source-view
    (source navigation-source-file)
  (html-inspector-views:html-view :title "Source" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (render-navigation-row
               "ASDF component"
               (navigation-source-file-component-of source)
               :object t)
              (render-navigation-row
               "Relative pathname"
               (navigation-source-file-relative-pathname-of source))
              (render-navigation-row
               "Pathname"
               (navigation-source-file-pathname-of source))))))

(html-inspector-views:defview navigation-source-file-contents-view
    (source navigation-source-file)
  (html-inspector-views:rename
   (html-inspector-views:lisp-code-view
    (html-inspector-views:thunk
      (navigation-source-file-contents source))
    :title "Contents"
    :priority 2)
   :title "Contents"
   :priority 2))

(hyperdoc:defexample fedwiki-java-navigation-trace-example
  "Run the durable seven-step local FEDWIKI-JAVA navigation trace."
  (make-fedwiki-java-navigation-trace))
