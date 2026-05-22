;;;; Inspector views for FedWiki-attached ASDF system homes.

(in-package :hyperdoc/inspector)

(defun inspect-system-home-page (home)
  (clog-moldable-inspector:clog-inspect :object home))

(defmethod views:text-representation
    ((home hyperdoc:fedwiki-attached-asdf-system))
  (format nil "~A -> ~A"
          (hyperdoc:fedwiki-attached-asdf-system-slug home)
          (hyperdoc:fedwiki-attached-asdf-system-system-name home)))

(defmethod views:text-representation
    ((failure hyperdoc:fedwiki-asdf-system-lookup-failure))
  (format nil "FedWiki ASDF lookup failure for ~A"
          (hyperdoc:fedwiki-attached-asdf-system-system-name
           (hyperdoc:fedwiki-asdf-lookup-failure-home failure))))

(defun fedwiki-home-display-string (value)
  (cond
    ((null value) "n/a")
    ((eq value t) "true")
    ((keywordp value) (format nil ":~A" (symbol-name value)))
    ((pathnamep value) (namestring value))
    ((symbolp value) (format nil "~A" value))
    (t (format nil "~A" value))))

(defun render-fedwiki-home-cell (value)
  (cond
    ((pathnamep value)
     (views:object-ref value :display (namestring value)))
    ((typep value 'standard-object)
     (views:object-ref value))
    (t
     (views:html
      (:tt (views:esc (fedwiki-home-display-string value)))))))

(defun render-fedwiki-home-row (label value)
  (views:html
   (:tr
    (:th (views:esc label))
    (:td (render-fedwiki-home-cell value)))))

(defun render-fedwiki-home-list (items &optional (empty "None."))
  (if items
      (views:html
       (:ul
        (dolist (item items)
          (views:html
           (:li (views:esc (fedwiki-home-display-string item)))))))
      (views:html (:p (views:esc empty)))))

(defun render-fedwiki-home-code-list (items &optional (empty "None."))
  (if items
      (views:html
       (:ul
        (dolist (item items)
          (views:html
           (:li (:code (views:esc (fedwiki-home-display-string item))))))))
      (views:html (:p (views:esc empty)))))

(defun render-fedwiki-home-state-table (state)
  (views:html
   (:table :class "inspector-table"
           (render-fedwiki-home-row "Page identity"
                                    (getf state :page-identity))
           (render-fedwiki-home-row "Asset root"
                                    (getf state :asset-root))
           (render-fedwiki-home-row "ASDF entrypoint"
                                    (getf state :asdf-entrypoint))
           (render-fedwiki-home-row "System"
                                    (getf state :system))
           (render-fedwiki-home-row "Tests"
                                    (getf state :test-system))
           (render-fedwiki-home-row "Source file"
                                    (getf state :source-file))
           (render-fedwiki-home-row "Source directory"
                                    (getf state :source-directory))
           (render-fedwiki-home-row
            "Package"
            (format nil "~A ~:[missing~;present~]"
                    (getf state :package-name)
                    (getf state :package-present-p)))
           (render-fedwiki-home-row
            "State"
            (if (getf state :loaded-p) "loaded" "not loaded"))
           (render-fedwiki-home-row
            "Asset root exists"
            (if (getf state :asset-root-exists-p) "true" "false"))
           (render-fedwiki-home-row
            ".asd exists"
            (if (getf state :asd-exists-p) "true" "false"))
           (render-fedwiki-home-row
            "System found"
            (if (getf state :system-found-p) "true" "false"))
           (render-fedwiki-home-row
            "Tests found"
            (if (getf state :tests-found-p) "true" "false"))
           (render-fedwiki-home-row "sqlite status"
                                    (getf state :sqlite-status)))))

(defun render-fedwiki-home-reading-questions (questions)
  (views:html
   (:h4 "Reading questions")
   (:p "Goldberg Table 1 reading-comprehension prompts are rendered as the first explanation layer for this system home page.")
   (dolist (entry questions)
     (views:html
      (:section
       (:h5 (views:esc (getf entry :question)))
       (render-fedwiki-home-list (getf entry :answer)))))))

(defun render-fedwiki-home-routes (routes)
  (views:html
   (:table :class "inspector-table"
           (:tr
            (:th "Route")
            (:th "Path / system")
            (:th "Available")
            (:th "Tried")
            (:th "Recovery action")
            (:th "Explanation")
            (:th "Result / condition"))
           (dolist (route routes)
             (views:html
              (:tr
               (:td (views:esc (getf route :label)))
               (:td (:tt
                     (views:esc
                      (or (and (getf route :pathname)
                               (namestring (getf route :pathname)))
                          (fedwiki-home-display-string
                           (getf route :system-name))))))
               (:td (:tt (views:esc
                          (if (getf route :available-p)
                              "true"
                              "false"))))
               (:td (:tt (views:esc
                          (if (getf route :tried-p)
                              "true"
                              "false"))))
               (:td (:code (views:esc
                            (or (getf route :recovery-action) ""))))
               (:td (views:esc (or (getf route :explanation) "")))
               (:td (views:esc
                     (or (getf route :condition-message) "")))))))))

(defun render-fedwiki-home-overview (home)
  (let* ((page (hyperdoc:asdf-system-home-page-of home))
         (state (getf page :state)))
    (views:html
     (:h3 "FedWiki-attached ASDF system home page")
     (:p "The FedWiki client URL names the page identity only. The SLY and ASDF route uses local file-backed page assets.")
     (render-fedwiki-home-state-table state)
     (:h4 "Available actions")
     (render-fedwiki-home-code-list (getf page :actions))
     (:h4 "Available examples")
     (render-fedwiki-home-list (getf page :examples))
     (:h4 "Available tests")
     (render-fedwiki-home-code-list (getf page :tests))
     (:h4 "Lookup / recovery trace")
     (render-fedwiki-home-list (getf page :route-trace))
     (render-fedwiki-home-reading-questions
      (getf page :reading-questions)))))

(defmethod views:title-bar-action-buttons
    ((home hyperdoc:fedwiki-attached-asdf-system))
  (views:html
   (views:eval-button
    "Load"
    (views:thunk
     (hyperdoc:load-fedwiki-attached-asdf-system home))
    "Load the exact local FedWiki page-attached ASDF entrypoint.")
   " "
   (views:eval-button
    "Home model"
    (views:thunk
     (hyperdoc:asdf-system-home-page-of home))
    "Return the structured ASDF system home-page model.")
   (when (hyperdoc:fedwiki-attached-asdf-system-previous-object home)
     (views:html
      " "
      (views:eval-button
       "Back"
       (views:thunk
        (hyperdoc:fedwiki-attached-asdf-system-previous-object home))
       "Return to the previous inspected object.")))))

(views:defview 👀overview (home hyperdoc:fedwiki-attached-asdf-system)
  (views:html-view
   :title "Overview"
   :priority 1
   (render-fedwiki-home-overview home)))

(views:defview 👀routes (home hyperdoc:fedwiki-attached-asdf-system)
  (views:html-view
   :title "Lookup routes"
   :priority 2
   (views:html
    (:h3 "Lookup / recovery routes")
    (render-fedwiki-home-routes
     (hyperdoc:fedwiki-attached-asdf-system-candidate-routes home)))))

(views:defview 👀home-model (home hyperdoc:fedwiki-attached-asdf-system)
  (views:html-view
   :title "Home model"
   :priority 3
   (views:html
    (:pre
     (views:esc
      (hyperdoc:fedwiki-attached-asdf-system-home-page-text home))))))

(defmethod views:title-bar-action-buttons
    ((failure hyperdoc:fedwiki-asdf-system-lookup-failure))
  (views:html
   (views:eval-button
    "Inspect home"
    (views:thunk
     (hyperdoc:fedwiki-asdf-lookup-failure-home failure))
    "Open the failed FedWiki-attached ASDF home object.")
   " "
   (views:eval-button
    "Retry load"
    (views:thunk
     (hyperdoc:load-fedwiki-attached-asdf-system
      (hyperdoc:fedwiki-asdf-lookup-failure-home failure)))
    "Retry loading the exact local FedWiki page-attached ASDF entrypoint.")))

(views:defview 👀overview (failure hyperdoc:fedwiki-asdf-system-lookup-failure)
  (let ((home (hyperdoc:fedwiki-asdf-lookup-failure-home failure)))
    (views:html-view
     :title "Overview"
     :priority 1
     (views:html
      (:h3 "FedWiki ASDF lookup failure")
      (:p (views:esc
           "The page-attached ASDF route did not load. Inspect the candidate routes before retrying a fallback."))
      (:p (:strong "Package-reader consequence: ")
          "forms such as "
          (:code "kioskberrli:...")
          " fail at read time if the system did not load and the package does not exist.")
      (render-fedwiki-home-state-table
       (getf (hyperdoc:asdf-system-home-page-of home) :state))
      (:h4 "Candidate routes")
      (render-fedwiki-home-routes
       (hyperdoc:fedwiki-asdf-lookup-failure-routes failure))
      (render-fedwiki-home-reading-questions
       (getf (hyperdoc:asdf-system-home-page-of failure)
             :reading-questions))))))

(views:defview 👀text (failure hyperdoc:fedwiki-asdf-system-lookup-failure)
  (views:html-view
   :title "Failure text"
   :priority 2
   (views:html
    (:pre
     (views:esc
      (hyperdoc:fedwiki-asdf-lookup-failure-text failure))))))
