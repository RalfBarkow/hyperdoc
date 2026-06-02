;;;; Inspector views for executable S-expression prompt split views.

(in-package :hyperdoc/inspector)

(defmethod views:text-representation ((prompt hyperdoc:executable-prompt))
  (format nil "Executable prompt (~:[no program~;topicmap program~])"
          (hyperdoc:executable-prompt-topicmap-program-of prompt)))

(defmethod views:text-representation ((response hyperdoc:split-view-response))
  (let ((validation (hyperdoc:split-view-response-validation-result-of response)))
    (format nil "S-expression prompt split view: ~A"
            (or (getf validation :status) :unvalidated))))

(defun s-expression-prompt-view-escape (value)
  (let ((text (format nil "~A" value)))
    (with-output-to-string (stream)
      (loop for char across text
            do (write-string
                (case char
                  (#\< "&lt;")
                  (#\> "&gt;")
                  (#\& "&amp;")
                  (#\" "&quot;")
                  (t (string char)))
                stream)))))

(defun s-expression-prompt-view-story-item-summary (item)
  (cond
    ((getf item :topic-id)
     (format nil "topic-id: ~A" (getf item :topic-id)))
    ((getf item :relation-id)
     (format nil "relation-id: ~A" (getf item :relation-id)))
    (t
     "context")))

(defun s-expression-prompt-render-story-items-html (story-items stream)
  (write-string "<ol class='s-expression-prompt-story-items'>" stream)
  (dolist (item story-items)
    (format stream
            "<li><p>~A</p><small><tt>~A</tt></small></li>"
            (s-expression-prompt-view-escape (getf item :text))
            (s-expression-prompt-view-escape
             (s-expression-prompt-view-story-item-summary item))))
  (write-string "</ol>" stream))

(defun s-expression-prompt-render-validation-html (validation stream)
  (format stream
          "<table class='inspector-table'><tr><th>Status</th><td><tt>~A</tt></td></tr><tr><th>Topic ids</th><td><tt>~A</tt></td></tr><tr><th>Relation ids</th><td><tt>~A</tt></td></tr></table>"
          (s-expression-prompt-view-escape (getf validation :status))
          (if (getf validation :topic-ids-match-p) "match" "mismatch")
          (if (getf validation :relation-ids-match-p) "match" "mismatch"))
  (format stream
          "<pre>~A</pre>"
          (s-expression-prompt-view-escape validation)))

(defun s-expression-prompt-render-split-view-html (response)
  (with-output-to-string (stream)
    (write-string
     "<section class='s-expression-prompt-split-view'>"
     stream)
    (write-string "<h3>FedWiki story view</h3>" stream)
    (s-expression-prompt-render-story-items-html
     (hyperdoc:split-view-response-fedwiki-story-items-of response)
     stream)
    (write-string "<h3>Topic map program view</h3>" stream)
    (format stream
            "<pre class='s-expression-prompt-program'>~A</pre>"
            (s-expression-prompt-view-escape
             (hyperdoc:split-view-response-program-view response)))
    (write-string "<h3>Validation</h3>" stream)
    (s-expression-prompt-render-validation-html
     (or (hyperdoc:split-view-response-validation-result-of response)
         (hyperdoc:validate-split-view-response response))
     stream)
    (write-string "</section>" stream)))

(defun s-expression-prompt-split-view-html-view (response &key (priority 1))
  (views:html-view :title "Split view" :priority priority
    (views:html
      (views:str (s-expression-prompt-render-split-view-html response)))))

(defun s-expression-prompt-response-from-prompt (prompt)
  (let ((program (hyperdoc:executable-prompt-topicmap-program-of prompt)))
    (when program
      (hyperdoc:make-split-view-response
       :fedwiki-story-items
       (hyperdoc:topicmap-program-to-fedwiki-story-items program)
       :topicmap-program program))))

(views:defview s-expression-prompt-split-view
    (response hyperdoc:split-view-response)
  (s-expression-prompt-split-view-html-view response))

(views:defview s-expression-prompt-split-view
    (prompt hyperdoc:executable-prompt)
  (let ((response (s-expression-prompt-response-from-prompt prompt)))
    (if response
        (s-expression-prompt-split-view-html-view response)
        (views:html-view :title "Split view" :priority 1
          (views:html
            (:h3 "Executable prompt")
            (:p "This prompt has no topic map program yet.")
            (:pre (views:esc
                   (hyperdoc:topicmap-program-pretty-string
                    (hyperdoc:executable-prompt-program-form prompt)))))))))
