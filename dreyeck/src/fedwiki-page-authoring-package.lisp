;;;; Capability-scoped edits of one local Federated Wiki page

(defpackage #:dreyeck/fedwiki-page-authoring
  (:use #:cl)
  (:local-nicknames (#:fa #:dreyeck/fedwiki-assets)
                    (#:mat #:dreyeck/fedwiki-page-materialization)
                    (#:bt #:bordeaux-threads)
                    (#:views #:html-inspector-views))
  (:export #:fedwiki-page-authoring-capability
           #:make-fedwiki-page-authoring-capability
           #:capability-site-root #:capability-slugs #:capability-actions
           #:edit-fedwiki-page-item
           #:fedwiki-page-edit
           #:page-edit-capability #:page-edit-slug #:page-edit-item-id
           #:page-edit-previous-item #:page-edit-action
           #:fedwiki-page-edit-refused
           #:page-edit-refusal-reason #:page-edit-refusal-detail))
