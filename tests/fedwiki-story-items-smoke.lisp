;;;; Smoke tests for FedWiki story-item rendering
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-FEDWIKI-STORY-ITEMS-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defparameter *story-items-smoke-commit-hash*
  "0123456789abcdef0123456789abcdef01234567")

(defun make-story-items-smoke-page ()
  (let ((wiki (make-instance 'hyperbook/fedwiki::fedwiki
                             :id "fedwiki:smoke.example")))
    (hyperbook/fedwiki::make-fedwiki-page wiki "smoke-page" "Smoke Page")))

(defun make-story-items-smoke-item (type text)
  (make-instance 'hyperbook/fedwiki::story-item
                 :item-type type
                 :id "item-1"
                 :text text
                 :data nil))

(defun web-link-urls (links)
  (mapcar #'hyperbook:url-of
          (remove-if-not (lambda (link)
                           (typep link 'hyperbook:web-link))
                         links)))

(defun meaningful-links (links)
  (remove nil links))

(defun render-story-item-to-string (type text)
  (let* ((page (make-story-items-smoke-page))
         (item (make-story-items-smoke-item type text)))
    (with-output-to-string (stream)
      (let ((html-inspector-views::*html-stream* stream)
            (html-inspector-views::*view-accumulator*
              (make-instance 'html-inspector-views::view-accumulator)))
        (hyperbook/fedwiki::render-story-item type item page)))))

(defun render-story-item-to-string-and-assets (type text)
  (let* ((page (make-story-items-smoke-page))
         (item (make-story-items-smoke-item type text))
         (accumulator (make-instance 'html-inspector-views::view-accumulator)))
    (values
     (with-output-to-string (stream)
       (let ((html-inspector-views::*html-stream* stream)
             (html-inspector-views::*view-accumulator* accumulator))
         (hyperbook/fedwiki::render-story-item type item page)))
     (html-inspector-views::accumulator-assets accumulator))))

(defun asset-urls-of-type (assets type)
  (loop for asset in assets
        when (eq (car asset) type)
          collect (cdr asset)))

(defun asset-script-present-p (assets fragment)
  (loop for asset in assets
        thereis (and (eq (car asset) :script)
                     (search fragment (cdr asset)))))

(defun run-fedwiki-story-item-link-extraction-smoke-test ()
  (let* ((page (make-story-items-smoke-page))
         (text (format nil "See ~A and [https://example.org Example] and [[Wiki Link]]"
                       *story-items-smoke-commit-hash*))
         (links (meaningful-links
                 (hyperbook/fedwiki::extract-links-from-wiki-text text page)))
         (urls (web-link-urls links))
         (swh-url (hyperbook/fedwiki::software-heritage-revision-url
                   *story-items-smoke-commit-hash*))
         (wiki-links (remove-if-not (lambda (link)
                                      (typep link 'hyperbook/fedwiki::wiki-link))
                                    links)))
    (assert-equal 3 (length links)
                  "Plain text with one URL, one commit hash, and one wiki link should yield three links")
    (assert-equal 2 (length urls)
                  "One normal URL plus one Software Heritage URL should be extracted as web links")
    (assert-true (member swh-url urls :test #'string=)
                 "Full commit hash must become one Software Heritage revision URL")
    (assert-true (member "https://example.org" urls :test #'string=)
                 "Ordinary external URL must remain present")
    (assert-equal 1 (length wiki-links)
                  "Wiki links must remain present")
    (assert-equal "wiki-link"
                  (hyperbook/fedwiki::target-slug-of (first wiki-links))
                  "Wiki link slug should be preserved")))

(defun run-fedwiki-story-item-paragraph-render-smoke-test ()
  (let* ((html (render-story-item-to-string
                :paragraph
                (format nil "See ~A and [https://example.org Example]"
                        *story-items-smoke-commit-hash*)))
         (swh-url (hyperbook/fedwiki::software-heritage-revision-url
                   *story-items-smoke-commit-hash*)))
    (assert-true (search swh-url html)
                 "Paragraph render must contain the Software Heritage link")
    (assert-true (search "https://example.org" html)
                 "Paragraph render must preserve the ordinary external URL")))

(defun run-fedwiki-story-item-markdown-render-smoke-test ()
  (let* ((html (render-story-item-to-string
                :markdown
                (format nil "Commit ~A with **markdown** text"
                        *story-items-smoke-commit-hash*)))
         (swh-url (hyperbook/fedwiki::software-heritage-revision-url
                   *story-items-smoke-commit-hash*)))
    (assert-true (search swh-url html)
                 "Markdown render must contain the Software Heritage link")
    (assert-true (search "markdown" html)
                 "Markdown render must preserve the markdown item label")))

(defun run-fedwiki-story-item-graphviz-render-smoke-test ()
  (multiple-value-bind (html assets)
      (render-story-item-to-string-and-assets
       :graphviz
       "digraph { a -> b }")
    (assert-true (search "data-inspector-graphviz=" html)
                 "Graphviz story items must render through the shared Graphviz placeholder")
    (assert-true (search "data-inspector-graphviz-dot=" html)
                 "Graphviz story items must carry DOT through the shared transport attribute")
    (assert-true (search "Raw DOT source" html)
                 "Graphviz story items must keep the shared raw DOT fallback")
    (assert-true (search "digraph { a -&gt; b }" html)
                 "Graphviz story item fallback must preserve the DOT text")
    (assert-true (not (search "background-color: #eee;" html))
                 "Graphviz story items must not fall through to the generic raw-text fallback")
    (assert-true (member "/html-inspector-views/js/viz-standalone.js"
                         (asset-urls-of-type assets :js)
                         :test #'equal)
                 "Graphviz story items must include the shared Viz.js runtime")
    (assert-true (member "/html-inspector-views/js/graphviz.js"
                         (asset-urls-of-type assets :js)
                         :test #'equal)
                 "Graphviz story items must include the shared Graphviz runtime")
    (assert-true (member "/html-inspector-views/css/graphviz.css"
                         (asset-urls-of-type assets :css)
                         :test #'equal)
                 "Graphviz story items must include the shared Graphviz CSS")
    (assert-true (asset-script-present-p assets "window.inspectorGraphviz.initCurrentView")
                 "Graphviz story items must include the shared init script")))

(defun run-fedwiki-story-item-short-hash-negative-test ()
  (let* ((page (make-story-items-smoke-page))
         (links (meaningful-links
                 (hyperbook/fedwiki::extract-links-from-wiki-text
                  "Short hash abcdef12 should stay plain text."
                  page))))
    (assert-equal 0 (length links)
                  "Short hashes must not become Software Heritage links")))

(defun run-fedwiki-story-item-non-hex-negative-test ()
  (let* ((page (make-story-items-smoke-page))
         (links (meaningful-links
                 (hyperbook/fedwiki::extract-links-from-wiki-text
                  "Non-hex aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaag should stay plain text."
                  page))))
    (assert-equal 0 (length links)
                  "Non-hex 40-character text must not become Software Heritage links")))

(defun run-fedwiki-story-item-explicit-link-boundary-test ()
  (let* ((page (make-story-items-smoke-page))
         (text (format nil "[https://example.org ~A]"
                       *story-items-smoke-commit-hash*))
         (links (meaningful-links
                 (hyperbook/fedwiki::extract-links-from-wiki-text text page)))
         (urls (web-link-urls links))
         (swh-url (hyperbook/fedwiki::software-heritage-revision-url
                   *story-items-smoke-commit-hash*)))
    (assert-equal 1 (length urls)
                  "Existing explicit external links must not be double-linkified")
    (assert-true (member "https://example.org" urls :test #'string=)
                 "Explicit external link URL must remain unchanged")
    (assert-true (not (member swh-url urls :test #'string=))
                 "Commit hash inside explicit external link text must not become a second link")))

(defun run-fedwiki-story-items-smoke-tests ()
  (run-fedwiki-story-item-link-extraction-smoke-test)
  (run-fedwiki-story-item-paragraph-render-smoke-test)
  (run-fedwiki-story-item-markdown-render-smoke-test)
  (run-fedwiki-story-item-graphviz-render-smoke-test)
  (run-fedwiki-story-item-short-hash-negative-test)
  (run-fedwiki-story-item-non-hex-negative-test)
  (run-fedwiki-story-item-explicit-link-boundary-test)
  (format t "~&FedWiki story-item smoke tests passed.~%")
  t)
