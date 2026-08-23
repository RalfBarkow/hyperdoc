(html-inspector-views:defview dreyeck/inspector/image::👀image-only-functions
                              (dreyeck/inspector/image::object
                               html-inspector-views/standard::image)
                              (arrow-macros:-> (mapcar
                                                (lambda (coordinate)
                                                  (find-symbol
                                                   (second coordinate)
                                                   (first coordinate)))
                                                (dreyeck/image-audit:image-function-audit-image-only-function-coordinates-of
                                                 (dreyeck/image-audit:audit-package-functions
                                                  "CL-USER"
                                                  '("dreyeck/issue"
                                                    "dreyeck/shop3"))))
                                (sort #'string< :key #'symbol-name)
                                html-inspector-views:thunk
                                (html-inspector-views:list-view :title
                                                                "Image-only functions"
                                                                :priority 9)))
