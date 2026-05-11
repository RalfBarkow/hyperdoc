;;;; Inspector views for implementation decision maps.

(in-package :hyperdoc/inspector)


(defmethod views:text-representation
           ((map hyperdoc::implementation-decision-map))
  (hyperbook:title-of map))


(defmethod views:text-representation ((option hyperdoc::implementation-option))
  (format nil "~A — ~A" (hyperbook:id-of option) (hyperbook:title-of option)))


(views:defview 👀overview (map hyperdoc::implementation-decision-map)
               (views:html-view :title "Overview" :priority 1
                                (views:html
                                  (:h3 (cl-who:esc (hyperbook:title-of map)))
                                  (:p
                                   (cl-who:esc
                                    (hyperdoc::problem-statement-of map)))
                                  (:h4 (cl-who:esc "Constraints"))
                                  (:ul
                                   (dolist
                                       (constraint
                                        (hyperdoc::constraints-of map))
                                     (views:html
                                       (:li (cl-who:esc constraint)))))
                                  (:h4 (cl-who:esc "Recommended path"))
                                  (:table :class "inspector-table"
                                   (:tr (:th (cl-who:esc "Step"))
                                    (:th (cl-who:esc "Option")))
                                   (loop common-lisp-user::for option common-lisp-user::in (hyperdoc::recommended-path-of
                                                                                            map)
                                         common-lisp-user::for index common-lisp-user::from 1
                                         do (views:html
                                              (:tr
                                               (:td
                                                (cl-who:esc
                                                 (format nil "~D" index)))
                                               (:td
                                                (views:object-ref
                                                 option)))))))))


(views:defview 👀matrix (map hyperdoc::implementation-decision-map)
               (views:html-view :title "Decision matrix" :priority 2
                                (views:html
                                  (:table :class "inspector-table"
                                   (:tr (:th (cl-who:esc "Option"))
                                    (:th (cl-who:esc "Family"))
                                    (:th (cl-who:esc "Effort"))
                                    (:th (cl-who:esc "Risk"))
                                    (:th (cl-who:esc "Embedded fit"))
                                    (:th (cl-who:esc "HyperDoc fit"))
                                    (:th (cl-who:esc "Status")))
                                   (dolist (option (hyperdoc::options-of map))
                                     (views:html
                                       (:tr (:td (views:object-ref option))
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (symbol-name
                                            (hyperdoc::family-of option)))))
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (symbol-name
                                            (hyperdoc::effort-of option)))))
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (symbol-name
                                            (hyperdoc::risk-of option)))))
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (symbol-name
                                            (hyperdoc::embedded-fit-of
                                             option)))))
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (symbol-name
                                            (hyperdoc::hyperdoc-fit-of
                                             option)))))
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (symbol-name
                                            (hyperdoc::status-of
                                             option))))))))))))


(views:defview 👀roadmap (map hyperdoc::implementation-decision-map)
               (views:html-view :title "Roadmap" :priority 3
                                (views:html
                                  (:table :class "inspector-table"
                                   (:tr (:th (cl-who:esc "From"))
                                    (:th (cl-who:esc "Kind"))
                                    (:th (cl-who:esc "To"))
                                    (:th (cl-who:esc "Rationale")))
                                   (dolist
                                       (relation (hyperdoc::relations-of map))
                                     (views:html
                                       (:tr
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (hyperdoc::from-option-id-of
                                            relation))))
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (symbol-name
                                            (hyperdoc::kind-of relation)))))
                                        (:td
                                         (:tt
                                          (cl-who:esc
                                           (hyperdoc::to-option-id-of
                                            relation))))
                                        (:td
                                         (cl-who:esc
                                          (hyperdoc::rationale-of
                                           relation))))))))))


(views:defview 👀overview (option hyperdoc::implementation-option)
               (views:html-view :title "Overview" :priority 1
                                (views:html
                                  (:h3 (cl-who:esc (hyperbook:title-of option)))
                                  (:p
                                   (cl-who:esc (hyperdoc::summary-of option)))
                                  (:table :class "inspector-table"
                                   (:tr (:td (cl-who:esc "ID"))
                                    (:td
                                     (:tt
                                      (cl-who:esc (hyperbook:id-of option)))))
                                   (:tr (:td (cl-who:esc "Family"))
                                    (:td
                                     (:tt
                                      (cl-who:esc
                                       (symbol-name
                                        (hyperdoc::family-of option))))))
                                   (:tr (:td (cl-who:esc "Effort"))
                                    (:td
                                     (:tt
                                      (cl-who:esc
                                       (symbol-name
                                        (hyperdoc::effort-of option))))))
                                   (:tr (:td (cl-who:esc "Risk"))
                                    (:td
                                     (:tt
                                      (cl-who:esc
                                       (symbol-name
                                        (hyperdoc::risk-of option))))))
                                   (:tr (:td (cl-who:esc "Embedded fit"))
                                    (:td
                                     (:tt
                                      (cl-who:esc
                                       (symbol-name
                                        (hyperdoc::embedded-fit-of option))))))
                                   (:tr (:td (cl-who:esc "HyperDoc fit"))
                                    (:td
                                     (:tt
                                      (cl-who:esc
                                       (symbol-name
                                        (hyperdoc::hyperdoc-fit-of option))))))
                                   (:tr (:td (cl-who:esc "Status"))
                                    (:td
                                     (:tt
                                      (cl-who:esc
                                       (symbol-name
                                        (hyperdoc::status-of option)))))))
                                  (:h4 (cl-who:esc "Deliverables"))
                                  (:ul
                                   (dolist
                                       (deliverable
                                        (hyperdoc::deliverables-of option))
                                     (views:html
                                       (:li (cl-who:esc deliverable)))))
                                  (:h4 (cl-who:esc "Pros"))
                                  (:ul
                                   (dolist (pro (hyperdoc::pros-of option))
                                     (views:html
                                       (:li (cl-who:esc pro)))))
                                  (:h4 (cl-who:esc "Cons"))
                                  (:ul
                                   (dolist (con (hyperdoc::cons-of option))
                                     (views:html
                                       (:li (cl-who:esc con))))))))

