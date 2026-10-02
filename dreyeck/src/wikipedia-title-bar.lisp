;;;; Wikipedia's Open in browser as a link: a temporary downstream adapter.
;;;;
;;;; Upstream owner: khinsen/hyperdoc, hyperbook-wikipedia/wikipedia.lisp, the
;;;; method TITLE-BAR-ACTION-BUTTONS for WIKIPEDIA-PAGE (as of 8a114919). It
;;;; offers Open in browser as an action button whose thunk calls
;;;; CLOG:OPEN-BROWSER, which starts a browser on the machine running the server.
;;;;
;;;; Downstream reason: a visitor to a served Catalog must not cause
;;;; CLOG:OPEN-BROWSER on the server. Following a URL needs no Lisp, so this
;;;; replaces that one method with an ordinary link that the visitor's own
;;;; browser follows, the same served and on a development server. Upstream's
;;;; source stays as it is, so the library-boundary test still holds.
;;;;
;;;; Temporary: delete this file, its test, its two systems in dreyeck.asd and
;;;; dreyeck/catalog's dependency on it once the pinned upstream method navigates
;;;; in the client. The test fails when the pinned upstream method changes.
;;;;
;;;; Technical debt meanwhile: HYPERBOOK/WIKIPEDIA::PAGE-URL is not exported. It
;;;; is called rather than copied, so there is one URL model, upstream's.

(defpackage #:dreyeck/wikipedia-title-bar
  (:use #:cl))

(in-package #:dreyeck/wikipedia-title-bar)

(defmethod html-inspector-views:title-bar-action-buttons
    ((page hyperbook/wikipedia::wikipedia-page))
  ;; A new tab keeps the Inspector's session. The href is escaped as an HTML
  ;; attribute and nothing else: CL-WHO writes a runtime attribute value
  ;; verbatim, and the percent-encoding stays whatever PAGE-URL gives.
  (html-inspector-views:html
    (:a :href (cl-who:escape-string (hyperbook/wikipedia::page-url page))
        :target "_blank"
        :class "inspector-action"
        "Open in browser")))
