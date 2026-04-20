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

(defun make-story-items-smoke-item (type text &optional data)
  (make-instance 'hyperbook/fedwiki::story-item
                 :item-type type
                 :id "item-1"
                 :text text
                 :data data))

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

(defun render-html-fragment-to-string-and-assets (thunk)
  (let ((accumulator (make-instance 'html-inspector-views::view-accumulator)))
    (values
     (with-output-to-string (stream)
       (let ((html-inspector-views::*html-stream* stream)
             (html-inspector-views::*view-accumulator* accumulator))
         (funcall thunk)))
     (html-inspector-views::accumulator-assets accumulator))))

(defun adapt-story-items-smoke-item (type text)
  (let* ((page (make-story-items-smoke-page))
         (item (make-story-items-smoke-item type text))
         (adapted (hyperbook/fedwiki::adapt-plugin-like-story-item type item page)))
    (values adapted item page)))

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

(defun run-fedwiki-story-item-video-adaptation-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :video
       "YOUTUBE UjPxDOEdsX8
Published Dec 1, 2007.")
    (assert-true (typep adapted 'hyperbook/fedwiki::adapted-video-snippet)
                 "Valid YOUTUBE <video-id> input must adapt to an adapted-video-snippet.")
    (assert-equal :youtube
                  (hyperbook/fedwiki::adapted-video-snippet-provider-of adapted)
                  "The adapted video snippet must normalize the provider to :youtube.")
    (assert-equal "UjPxDOEdsX8"
                  (hyperbook/fedwiki::adapted-video-snippet-video-id-of adapted)
                  "The adapted video snippet must preserve the parsed video id.")
    (assert-equal "Published Dec 1, 2007."
                  (hyperbook/fedwiki::adapted-video-snippet-caption-of adapted)
                  "The adapted video snippet must extract the remaining lines as caption text.")
    (assert-equal "https://www.youtube.com/watch?v=UjPxDOEdsX8"
                  (hyperbook/fedwiki::adapted-video-snippet-canonical-url-of adapted)
                  "The adapted video snippet must derive the canonical YouTube watch URL.")
    (assert-equal "https://www.youtube.com/embed/UjPxDOEdsX8"
                  (hyperbook/fedwiki::adapted-video-snippet-embed-url-of adapted)
                  "The adapted video snippet must derive the YouTube embed URL.")
    (assert-true (eq item
                     (hyperbook/fedwiki::adapted-video-snippet-source-item-of adapted))
                 "The adapted video snippet must retain the original source-faithful story item.")
    (assert-true (eq page
                     (hyperbook/fedwiki::adapted-video-snippet-source-page-of adapted))
                 "The adapted video snippet must retain the source page.")
    (assert-equal :video
                  (hyperbook/fedwiki::item-type-of item)
                  "The original story item type must remain unchanged.")
    (assert-equal "YOUTUBE UjPxDOEdsX8
Published Dec 1, 2007."
                  (hyperbook/fedwiki::text-of item)
                  "The original story item text must remain source-faithful after adaptation.")
    (assert-true
     (null (hyperbook/fedwiki::adapt-plugin-like-story-item
            :paragraph
            (make-story-items-smoke-item :paragraph "plain paragraph")
            page))
     "The default adaptation method must stay inert for non-plugin story-item kinds.")))

(defun run-fedwiki-story-item-video-missing-id-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :video
       "YOUTUBE
Published Dec 1, 2007.")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::story-item-adaptation-failure)
                 "Missing video id must produce a story-item-adaptation-failure.")
    (assert-equal :missing-video-id
                  (hyperbook/fedwiki::adaptation-failure-reason-of adapted)
                  "Missing video id must stay on the explicit adaptation-failure path.")))

(defun run-fedwiki-story-item-video-malformed-header-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :video
       "YOUTUBE UjPxDOEdsX8 EXTRA
Published Dec 1, 2007.")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::story-item-adaptation-failure)
                 "Malformed video headers must produce a story-item-adaptation-failure.")
    (assert-equal :malformed-header
                  (hyperbook/fedwiki::adaptation-failure-reason-of adapted)
                  "Extra header tokens must stay on the explicit malformed-header failure path.")))

(defun run-fedwiki-story-item-video-unsupported-provider-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :video
       "VIMEO UjPxDOEdsX8
Published Dec 1, 2007.")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::story-item-adaptation-failure)
                 "Unsupported providers must produce a story-item-adaptation-failure.")
    (assert-equal :unsupported-provider
                  (hyperbook/fedwiki::adaptation-failure-reason-of adapted)
                  "Unsupported providers must stay on the explicit adaptation-failure path.")))

(defun run-fedwiki-story-item-video-preferred-render-smoke-test ()
  (let ((html
          (render-story-item-to-string
           :video
           "YOUTUBE UjPxDOEdsX8
Published Dec 1, 2007.")))
    (assert-true (search "<iframe" html :test #'char-equal)
                 "Successful video rendering must use the preferred embedded player path.")
    (assert-true (search "https://www.youtube.com/embed/UjPxDOEdsX8" html :test #'char=)
                 "Successful video rendering must include the YouTube embed URL.")
    (assert-true (search "Published Dec 1, 2007." html :test #'char=)
                 "Successful video rendering must include the caption.")
    (assert-true (search "https://www.youtube.com/watch?v=UjPxDOEdsX8" html :test #'char=)
                 "Successful video rendering must keep a visible safe fallback link.")
    (assert-true (not (search "Video adaptation failed." html :test #'char=))
                 "Successful video rendering must stay on the success path, not the failure path.")))

(defun run-fedwiki-story-item-video-fallback-render-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :video
       "YOUTUBE UjPxDOEdsX8
Published Dec 1, 2007.")
    (declare (ignore item))
    (multiple-value-bind (html assets)
        (render-html-fragment-to-string-and-assets
         (lambda ()
           (hyperbook/fedwiki::render-video-snippet-fallback adapted page)))
      (declare (ignore assets))
      (assert-true (search "https://www.youtube.com/watch?v=UjPxDOEdsX8" html :test #'char=)
                   "The explicit video fallback renderer must point to the canonical watch URL.")
      (assert-true (search "Published Dec 1, 2007." html :test #'char=)
                   "The explicit video fallback renderer must preserve the caption.")
      (assert-true (not (search "<iframe" html :test #'char-equal))
                   "The explicit video fallback renderer must stay separate from the embed path."))))

(defun run-fedwiki-story-item-video-failure-render-smoke-test ()
  (let ((html
          (render-story-item-to-string
           :video
           "VIMEO UjPxDOEdsX8
Published Dec 1, 2007.")))
    (assert-true (search "Video adaptation failed." html :test #'char=)
                 "Malformed or unsupported video input must render an explicit failure block.")
    (assert-true (search "Unsupported video provider VIMEO." html :test #'char=)
                 "The failure renderer must expose the adaptation failure reason.")
    (assert-true (search "Original story item:" html :test #'char=)
                 "The failure renderer must keep the original story item inspectable.")
    (assert-true (search "VIMEO UjPxDOEdsX8" html :test #'char=)
                 "The failure renderer must include raw source fallback from the original story item.")
    (assert-true (not (search "https://www.youtube.com/embed/UjPxDOEdsX8" html :test #'char=))
                 "The failure renderer must not silently fall into the success embed path.")
    (assert-true (not (search "Fallback: watch on YouTube" html :test #'char=))
                 "The failure renderer must stay visibly separate from the success/fallback video render path.")))

(defun run-fedwiki-story-item-frame-adaptation-with-height-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :frame
       "https://example.org/embed/widget
HEIGHT 420")
    (assert-true (typep adapted 'hyperbook/fedwiki::adapted-frame-snippet)
                 "Valid frame URL plus HEIGHT must adapt to an adapted-frame-snippet.")
    (assert-equal "https://example.org/embed/widget"
                  (hyperbook/fedwiki::adapted-frame-snippet-target-url-of adapted)
                  "The adapted frame snippet must preserve the parsed target URL.")
    (assert-equal 420
                  (hyperbook/fedwiki::adapted-frame-snippet-height-of adapted)
                  "The adapted frame snippet must preserve the parsed HEIGHT value.")
    (assert-true (eq item
                     (hyperbook/fedwiki::adapted-frame-snippet-source-item-of adapted))
                 "The adapted frame snippet must retain the original source-faithful story item.")
    (assert-true (eq page
                     (hyperbook/fedwiki::adapted-frame-snippet-source-page-of adapted))
                 "The adapted frame snippet must retain the source page.")
    (assert-equal :frame
                  (hyperbook/fedwiki::item-type-of item)
                  "The original frame story item type must remain unchanged.")
    (assert-equal "https://example.org/embed/widget
HEIGHT 420"
                  (hyperbook/fedwiki::text-of item)
                  "The original frame story item text must remain source-faithful after adaptation.")))

(defun run-fedwiki-story-item-frame-adaptation-url-only-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :frame
       "https://example.org/embed/widget")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::adapted-frame-snippet)
                 "A frame snippet with URL only must still adapt successfully.")
    (assert-equal "https://example.org/embed/widget"
                  (hyperbook/fedwiki::adapted-frame-snippet-target-url-of adapted)
                  "URL-only frame snippets must preserve the target URL.")
    (assert-equal 300
                  (hyperbook/fedwiki::adapted-frame-snippet-height-of adapted)
                  "URL-only frame snippets must use the default height for this slice.")))

(defun run-fedwiki-story-item-frame-malformed-height-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :frame
       "https://example.org/embed/widget
HEIGHT giant")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::story-item-adaptation-failure)
                 "Malformed frame HEIGHT must produce a story-item-adaptation-failure.")
    (assert-equal :malformed-height
                  (hyperbook/fedwiki::adaptation-failure-reason-of adapted)
                  "Malformed frame HEIGHT must stay on the explicit malformed-height failure path.")))

(defun run-fedwiki-story-item-frame-missing-url-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :frame
       "

")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::story-item-adaptation-failure)
                 "Frame snippets without a URL must produce a story-item-adaptation-failure.")
    (assert-equal :missing-url
                  (hyperbook/fedwiki::adaptation-failure-reason-of adapted)
                  "Missing frame URL must stay on the explicit missing-url failure path.")))

(defun run-fedwiki-story-item-frame-raw-iframe-html-unsupported-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :frame
       "<iframe src=\"https://example.org/embed/widget\" height=\"420\"></iframe>")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::story-item-adaptation-failure)
                 "Raw <iframe ...> HTML must stay on the explicit failure path in this slice.")
    (assert-equal :raw-iframe-html-unsupported
                  (hyperbook/fedwiki::adaptation-failure-reason-of adapted)
                  "Raw <iframe ...> HTML must be rejected explicitly instead of best-effort embedding.")))

(defun run-fedwiki-story-item-frame-preferred-render-smoke-test ()
  (let ((html
          (render-story-item-to-string
           :frame
           "https://example.org/embed/widget
HEIGHT 420")))
    (assert-true (search "<iframe" html :test #'char-equal)
                 "Successful frame rendering must use the preferred iframe path.")
    (assert-true (search "https://example.org/embed/widget" html :test #'char=)
                 "Successful frame rendering must include the frame target URL.")
    (assert-true (search "height='420'" html :test #'char-equal)
                 "Successful frame rendering must include the parsed iframe height.")
    (assert-true (search "Open frame target" html :test #'char=)
                 "Successful frame rendering must keep a visible direct-open fallback link.")
    (assert-true (not (search "Frame adaptation failed." html :test #'char=))
                 "Successful frame rendering must stay on the success path, not the failure path.")))

(defun run-fedwiki-story-item-frame-fallback-render-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :frame
       "https://example.org/embed/widget
HEIGHT 420")
    (declare (ignore item page))
    (multiple-value-bind (html assets)
        (render-html-fragment-to-string-and-assets
         (lambda ()
           (hyperbook/fedwiki::render-frame-snippet-fallback adapted)))
      (declare (ignore assets))
      (assert-true (search "https://example.org/embed/widget" html :test #'char=)
                   "The explicit frame fallback renderer must point to the target URL.")
      (assert-true (search "Open frame target" html :test #'char=)
                   "The explicit frame fallback renderer must expose the direct-open link.")
      (assert-true (search "Frame height: 420 px" html :test #'char=)
                   "The explicit frame fallback renderer must expose the parsed height.")
      (assert-true (not (search "<iframe" html :test #'char-equal))
                   "The explicit frame fallback renderer must stay separate from the iframe path."))))

(defun run-fedwiki-story-item-frame-failure-render-smoke-test ()
  (let ((html
          (render-story-item-to-string
           :frame
           "<iframe src=\"https://example.org/embed/widget\" height=\"420\"></iframe>")))
    (assert-true (search "Frame adaptation failed." html :test #'char=)
                 "Unsupported raw <iframe ...> input must render an explicit frame failure block.")
    (assert-true (search "Raw &lt;iframe ...&gt; HTML is unsupported in this slice." html :test #'char=)
                 "The frame failure renderer must expose the explicit unsupported-html reason.")
    (assert-true (search "Original story item:" html :test #'char=)
                 "The frame failure renderer must keep the original story item inspectable.")
    (assert-true (search "&lt;iframe src=&quot;https://example.org/embed/widget&quot; height=&quot;420&quot;&gt;&lt;/iframe&gt;"
                         html
                         :test #'char=)
                 "The frame failure renderer must include raw source fallback from the original story item.")
    (assert-true (not (search "Open frame target" html :test #'char=))
                 "The frame failure renderer must stay visibly separate from the success/fallback frame render path.")))

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
  (run-fedwiki-story-item-video-adaptation-smoke-test)
  (run-fedwiki-story-item-video-missing-id-smoke-test)
  (run-fedwiki-story-item-video-malformed-header-smoke-test)
  (run-fedwiki-story-item-video-unsupported-provider-smoke-test)
  (run-fedwiki-story-item-video-preferred-render-smoke-test)
  (run-fedwiki-story-item-video-fallback-render-smoke-test)
  (run-fedwiki-story-item-video-failure-render-smoke-test)
  (run-fedwiki-story-item-frame-adaptation-with-height-smoke-test)
  (run-fedwiki-story-item-frame-adaptation-url-only-smoke-test)
  (run-fedwiki-story-item-frame-malformed-height-smoke-test)
  (run-fedwiki-story-item-frame-missing-url-smoke-test)
  (run-fedwiki-story-item-frame-raw-iframe-html-unsupported-smoke-test)
  (run-fedwiki-story-item-frame-preferred-render-smoke-test)
  (run-fedwiki-story-item-frame-fallback-render-smoke-test)
  (run-fedwiki-story-item-frame-failure-render-smoke-test)
  (run-fedwiki-story-item-graphviz-render-smoke-test)
  (run-fedwiki-story-item-short-hash-negative-test)
  (run-fedwiki-story-item-non-hex-negative-test)
  (run-fedwiki-story-item-explicit-link-boundary-test)
  (format t "~&FedWiki story-item smoke tests passed.~%")
  t)
