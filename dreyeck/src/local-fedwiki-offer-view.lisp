;;;; Read an observed attachment before deciding whether to load it.
(in-package #:dreyeck/local-fedwiki-view)

(defparameter +page-offer-style+
  ".page-system-offer {
  container-type: inline-size;
  box-sizing: border-box;
  max-width: 70ch;
  padding: .5rem 1rem 1rem;
  line-height: 1.5;
  text-align: start;
}
.page-system-offer h2 { font-size: 1.3em; line-height: 1.25; margin: .4em 0 .8em; }
.page-system-offer dl {
  display: grid;
  grid-template-columns: max-content minmax(0, 1fr);
  gap: .3rem 1.25rem;
  margin: 0;
}
.page-system-offer dt { font-weight: 600; }
.page-system-offer dd { margin: 0; }
.page-system-offer h2, .page-system-offer dd, .page-system-offer a, .page-system-offer .inspector-inspect {
  overflow-wrap: anywhere;
  white-space: normal;
}
.page-system-offer code { font: .92em ui-monospace, Menlo, Consolas, monospace; }
.page-system-offer a, .page-system-offer .inspector-inspect {
  color: #12408f;
  text-decoration: underline;
  text-underline-offset: .15em;
  cursor: pointer;
}
.page-system-offer p { margin: 1em 0 0; }
@container (max-width: 32rem) {
  .page-system-offer dl { grid-template-columns: minmax(0, 1fr); gap: 0; }
  .page-system-offer dd + dt { margin-top: .65em; }
}")

(defgeneric page-offer-destination (page offer)
  (:documentation "Return the inspectable target, its link text and an optional view title.")
  (:method (page offer)
    (declare (ignore page))
    (values offer "Workspace-Angebot ansehen" nil)))

(html-inspector-views:defview 👀systemangebot (page dreyeck/local-fedwiki-page:local-fedwiki-page)
  (when (dreyeck/fedwiki-assets:assets-story-items (hyperbook/fedwiki::raw-json-of page))
    (let* ((observation (dreyeck/local-fedwiki-page:local-fedwiki-page-asdf-discovery page))
           (offer (find (format nil "workspace:~A" (getf observation :slug))
                        (hyperbook:hyperbooks-of hyperbook:*catalog*) :test #'equal :key #'hyperbook:id-of)))
      (when (and offer (or (getf observation :asdf-archive)
                           (find (getf observation :slug) (getf observation :asdf-files)
                                 :test #'equal :key #'pathname-name)))
        (let* ((slug (getf observation :slug))
               (archive (getf observation :asdf-archive))
               (definition (or (getf archive :member) (format nil "~A.asd" slug))))
          (html-inspector-views:html-view :title "Systemangebot" :priority 4
            (multiple-value-bind (target label selection) (page-offer-destination page offer)
              (html-inspector-views:html
                (:style (html-inspector-views:str +page-offer-style+))
                (:section :class "page-system-offer" :lang "de"
                  (:h2 (html-inspector-views:esc (hyperbook:title-of page)))
                  (:dl (:dt "ASDF-System") (:dd (:code (html-inspector-views:esc slug)))
                       (when archive
                         (html-inspector-views:html
                          (:dt "Seitenanhang")
                          (:dd (:a :href (archive-url slug) :download (file-namestring (getf archive :zip))
                                   (html-inspector-views:esc (file-namestring (getf archive :zip)))))))
                       (:dt "Systemdefinition") (:dd (:code (html-inspector-views:esc definition))))
                  (:p (html-inspector-views:object-ref target :display label :select selection)))))))))))

(defmethod hyperbook/fedwiki::render-story-item
    ((type (eql :assets)) item (page dreyeck/local-fedwiki-page:local-fedwiki-page))
  (let* ((archive (getf (dreyeck/local-fedwiki-page:local-fedwiki-page-asdf-discovery page)
                        :asdf-archive)))
    (if (and archive (equal (getf archive :item-id) (hyperbook/fedwiki::id-of item)))
        (html-inspector-views:html
          (:p (:a :href (archive-url (hyperbook:id-of page)) :download (file-namestring (getf archive :zip))
                  (html-inspector-views:esc (file-namestring (getf archive :zip))))))
        (call-next-method))))
