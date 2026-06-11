;;;; Inspector views for FedWiki page-attached ASDF capability relations.

(in-package :hyperdoc/inspector)

(defmethod html-inspector-views:text-representation
    ((relation hyperdoc:fedwiki-attached-asdf-capability-relation))
  (format nil "~A -> ~A ~A"
          (hyperdoc:fedwiki-attached-asdf-system-slug
           (hyperdoc:fedwiki-asdf-relation-from-home-of relation))
          (hyperdoc:fedwiki-attached-asdf-system-slug
           (hyperdoc:fedwiki-asdf-relation-to-home-of relation))
          (hyperdoc:fedwiki-asdf-relation-capability-of relation)))

(defun fedwiki-asdf-state-text (state)
  (with-output-to-string (out)
    (loop for (key value) on state by #'cddr
          do (format out "~A: ~S~%" key value))))

(defun fedwiki-asdf-relation-lines-text (relation)
  (with-output-to-string (out)
    (dolist (line (hyperdoc:fedwiki-asdf-relation-summary-lines relation))
      (format out "~A~%" line))))

(defun fedwiki-asdf-home-constructor-form-string (home)
  (format nil
          "(hyperdoc:make-fedwiki-attached-asdf-system~%~
           ~2T:slug ~S~%~
           ~2T:site-root ~S~%~
           ~2T:system ~S~%~
           ~2T:system-file ~S~%~
           ~2T:test-system ~S~%~
           ~2T:package-name ~S)"
          (hyperdoc:fedwiki-attached-asdf-system-slug home)
          (hyperdoc:fedwiki-attached-asdf-system-site-root home)
          (hyperdoc:fedwiki-attached-asdf-system-system-name home)
          (hyperdoc:fedwiki-attached-asdf-system-system-file home)
          (hyperdoc:fedwiki-attached-asdf-system-test-system-name home)
          (hyperdoc:fedwiki-attached-asdf-system-package-name home)))

(defun fedwiki-asdf-relation-constructor-form-string (relation)
  (format nil
          "(hyperdoc:make-fedwiki-attached-asdf-capability-relation~%~
           ~2T:from-home from-home~%~
           ~2T:to-home to-home~%~
           ~2T:capability ~S~%~
           ~2T:entry-package-name ~S~%~
           ~2T:entry-symbol-name ~S~%~
           ~2T:reason ~S~%~
           ~2T:load-policy ~S)"
          (hyperdoc:fedwiki-asdf-relation-capability-of relation)
          (hyperdoc:fedwiki-asdf-relation-entry-package-name-of relation)
          (hyperdoc:fedwiki-asdf-relation-entry-symbol-name-of relation)
          (hyperdoc:fedwiki-asdf-relation-reason-of relation)
          (hyperdoc:fedwiki-asdf-relation-load-policy-of relation)))

(defun fedwiki-asdf-relation-let-form-string (relation body-string)
  (format nil
          "(let* ((from-home~%~
           ~8T~A)~%~
           ~7T(to-home~%~
           ~8T~A)~%~
           ~7T(relation~%~
           ~8T~A))~%~
           ~2T~A)"
          (fedwiki-asdf-home-constructor-form-string
           (hyperdoc:fedwiki-asdf-relation-from-home-of relation))
          (fedwiki-asdf-home-constructor-form-string
           (hyperdoc:fedwiki-asdf-relation-to-home-of relation))
          (fedwiki-asdf-relation-constructor-form-string relation)
          body-string))

(defun fedwiki-asdf-relation-load-form-string (relation)
  (fedwiki-asdf-relation-let-form-string
   relation
   "(hyperdoc:fedwiki-asdf-relation-load-provider relation :force nil)"))

(defun fedwiki-asdf-relation-invoke-form-string (relation)
  (fedwiki-asdf-relation-let-form-string
   relation
   "(hyperdoc:invoke-fedwiki-attached-asdf-capability
   relation
   :load-provider nil
   :db-path #P\"/Users/rgb/workspace/hyperdoc/var/dmx-associative-mirror.sqlite\"
   :title \"Related Topics DMX SQL mirror topicmap\")"))

(html-inspector-views:defview fedwiki-asdf-relation-overview
    (relation hyperdoc:fedwiki-attached-asdf-capability-relation)
  (html-inspector-views:html-view :title "Overview" :priority 1
    (html-inspector-views:html
      (:h2 "FedWiki-attached ASDF relation")
      (:pre
       (html-inspector-views:esc
        (fedwiki-asdf-relation-lines-text relation))))))

(html-inspector-views:defview fedwiki-asdf-relation-state
    (relation hyperdoc:fedwiki-attached-asdf-capability-relation)
  (html-inspector-views:html-view :title "State" :priority 2
    (html-inspector-views:html
      (:h2 "Relation state")
      (:pre
       (html-inspector-views:esc
        (fedwiki-asdf-state-text
         (hyperdoc:fedwiki-asdf-relation-state relation)))))))

(html-inspector-views:defview fedwiki-asdf-relation-load
    (relation hyperdoc:fedwiki-attached-asdf-capability-relation)
  (html-inspector-views:html-view :title "Load" :priority 3
    (html-inspector-views:html
      (:h2 "Explicit provider load")
      (:p "This view intentionally does not perform the load.")
      (:p "Copy the whole parenthesized form below into SLY mREPL.")
      (:pre
       (html-inspector-views:esc
        (fedwiki-asdf-relation-load-form-string relation))))))

(html-inspector-views:defview fedwiki-asdf-relation-invoke
    (relation hyperdoc:fedwiki-attached-asdf-capability-relation)
  (html-inspector-views:html-view :title "Invoke" :priority 4
    (html-inspector-views:html
      (:h2 "Explicit provider invocation")
      (:p "This form assumes the provider has already been loaded.")
      (:p "It passes :LOAD-PROVIDER NIL so invocation does not hide a load step.")
      (:pre
       (html-inspector-views:esc
        (fedwiki-asdf-relation-invoke-form-string relation))))))
