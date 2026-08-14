;; Explicit HyperDoc activation for local Federated Wiki pages

(in-package #:dreyeck/local-fedwiki-page/inspector)

(defun activate-page-attached-hyperdoc (page)
  "Explicitly activate the page-attached HyperDoc associated with PAGE."
  (check-type
   page
   dreyeck/local-fedwiki-page:local-fedwiki-page)
  (dreyeck/fedwiki-hyperdoc:activate-local-fedwiki-page-hyperdoc
   (dreyeck/local-fedwiki-page:local-fedwiki-page-site-root-of
    page)
   (hyperbook:id-of page)))

(defmethod html-inspector-views:title-bar-action-buttons
    ((page dreyeck/local-fedwiki-page:local-fedwiki-page))
  ;; LOCAL-FEDWIKI-PAGE has local provenance. Do not inherit FEDWIKI-PAGE's
  ;; network Reload/Open actions.
  (html-inspector-views:eval-button
   "Activate page-attached HyperDoc"
   (html-inspector-views:thunk
     (activate-page-attached-hyperdoc page))))
