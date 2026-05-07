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

(defun call-with-story-items-smoke-development-mode (development thunk)
  (let* ((pkg (find-package "HYPERBOOK/SERVER"))
         (server-parameters (and pkg
                                 (find-symbol "*SERVER-PARAMETERS*" pkg))))
    (if server-parameters
        (progv (list server-parameters)
            (list (list "700px" development))
          (funcall thunk))
        (funcall thunk))))

(defun make-story-items-smoke-json-table (&rest pairs)
  (let ((table (make-hash-table :test #'equal)))
    (loop for (key value) on pairs by #'cddr
          do (setf (gethash key table) value))
    table))

(defun call-with-localhost-story-items-page-fixture (thunk)
  (let* ((domain-name "story-items-smoke.localhost")
         (slug "graphviz-edit-fixture")
         (path (hyperbook/fedwiki::localhost-fedwiki-page-pathname-from-domain-and-slug
                domain-name
                slug))
         (directory (uiop:pathname-directory-pathname path))
         (page-json
          (make-story-items-smoke-json-table
           "title" "Graphviz edit fixture"
           "story" (list (make-story-items-smoke-json-table
                          "id" "fixture-graphviz"
                          "type" "graphviz"
                          "text" "digraph { a -> b }"))
           "journal" (list (make-story-items-smoke-json-table
                            "type" "create"
                            "date" 1000)
                           (make-story-items-smoke-json-table
                            "type" "add"
                            "date" 1001
                            "id" "fixture-graphviz"
                            "item" (make-story-items-smoke-json-table
                                    "id" "fixture-graphviz"
                                    "type" "graphviz"
                                    "text" "digraph { a -> b }")))))
         (wiki (make-instance 'hyperbook/fedwiki::fedwiki
                              :id (format nil "fedwiki:~A" domain-name)))
         (page (hyperbook/fedwiki::make-fedwiki-page wiki slug "Graphviz edit fixture")))
    (ensure-directories-exist path)
    (hyperbook/fedwiki::write-localhost-fedwiki-page-json-file path page-json)
    (unwind-protect
         (funcall thunk page path)
      (when (probe-file path)
        (delete-file path))
      (when (probe-file directory)
        (ignore-errors
          (uiop:delete-empty-directory directory)))
      (let ((root (ignore-errors
                    (uiop:pathname-parent-directory-pathname directory))))
        (when (and root (probe-file root))
          (ignore-errors
            (uiop:delete-empty-directory root)))))))

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

(defun render-story-item-to-string-with-page (page type text)
  (let ((item (make-story-items-smoke-item type text)))
    (with-output-to-string (stream)
      (let ((html-inspector-views::*html-stream* stream)
            (html-inspector-views::*view-accumulator*
             (make-instance 'html-inspector-views::view-accumulator)))
        (hyperbook/fedwiki::render-story-item type item page)))))

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

(defun run-fedwiki-story-item-graphviz-edit-persistence-smoke-test ()
  (call-with-story-items-smoke-development-mode
   t
   (lambda ()
     (let* ((directory (uiop:ensure-directory-pathname
                        (merge-pathnames "hyperdoc-fedwiki-story-item-smoke/"
                                         (uiop:temporary-directory))))
            (path (merge-pathnames "graphviz-edit-fixture" directory))
            (original-dot "digraph { a -> b }")
            (updated-dot "digraph { alpha -> beta; beta -> gamma }")
            (page-json
             (make-story-items-smoke-json-table
              "title" "Graphviz edit persistence fixture"
              "story" (list (make-story-items-smoke-json-table
                             "id" "fixture-graphviz"
                             "type" "graphviz"
                             "text" original-dot))
              "journal" (list (make-story-items-smoke-json-table
                               "type" "create"
                               "date" 1000)
                              (make-story-items-smoke-json-table
                               "type" "add"
                               "date" 1001
                               "id" "fixture-graphviz"
                               "item" (make-story-items-smoke-json-table
                                       "id" "fixture-graphviz"
                                       "type" "graphviz"
                                       "text" original-dot))))))
       (ensure-directories-exist path)
       (hyperbook/fedwiki::write-localhost-fedwiki-page-json-file path page-json)
       (let* ((updated
               (hyperbook/fedwiki::persist-localhost-fedwiki-story-item-text-edit-at-path
                path
                "fixture-graphviz"
                updated-dot
                :item-type :graphviz))
              (story-item (elt (gethash "story" updated) 0))
              (journal (hyperbook/fedwiki::json-array-elements
                        (gethash "journal" updated)))
              (last-entry (car (last journal)))
              (last-item (gethash "item" last-entry)))
         (assert-equal "graphviz"
                       (gethash "type" story-item)
                       "Persisted graphviz edits must preserve the story item type.")
         (assert-equal "fixture-graphviz"
                       (gethash "id" story-item)
                       "Persisted graphviz edits must preserve the stable story item id.")
         (assert-equal updated-dot
                       (gethash "text" story-item)
                       "Persisted graphviz edits must keep DOT in story item text.")
         (assert-equal "edit"
                       (gethash "type" last-entry)
                       "Persisted graphviz edits must append a journal edit action.")
         (assert-equal "fixture-graphviz"
                       (gethash "id" last-entry)
                       "Journal edit actions must be keyed by the stable story item id.")
         (assert-equal "graphviz"
                       (gethash "type" last-item)
                       "Journal edit payload must preserve graphviz item type.")
         (assert-equal "fixture-graphviz"
                       (gethash "id" last-item)
                       "Journal edit payload must preserve the stable story item id.")
         (assert-equal updated-dot
                       (gethash "text" last-item)
                       "Journal edit payload must store the updated DOT in text."))))))

(defun run-fedwiki-story-item-graphviz-development-mode-gating-smoke-test ()
  (call-with-localhost-story-items-page-fixture
   (lambda (page path)
     (declare (ignore path))
     (let ((html
            (call-with-story-items-smoke-development-mode
             t
             (lambda ()
               (render-story-item-to-string-with-page
                page
                :graphviz
                "digraph { a -> b }")))))
       (assert-true (search "hyperbook-fedwiki-graphviz-edit-button" html)
                    "Graphviz edit controls must render in development mode.")
       (assert-true (search "hyperbook-fedwiki-graphviz-editor" html)
                    "Graphviz edit textarea must render in development mode.")
       (assert-true (search "hyperbook-fedwiki-graphviz-save-button" html)
                    "Graphviz save controls must render in development mode.")))))

(defun run-fedwiki-story-item-graphviz-readonly-mode-smoke-test ()
  (call-with-localhost-story-items-page-fixture
   (lambda (page path)
     (let ((html
            (call-with-story-items-smoke-development-mode
             nil
             (lambda ()
               (render-story-item-to-string-with-page
                page
                :graphviz
                "digraph { a -> b }")))))
       (assert-true (search "data-inspector-graphviz=" html)
                    "Graphviz story items must still render in non-development mode.")
       (assert-true (not (search "hyperbook-fedwiki-graphviz-edit-button" html))
                    "Graphviz edit controls must be absent outside development mode.")
       (assert-true (not (search "hyperbook-fedwiki-graphviz-editor" html))
                    "Graphviz edit textarea must be absent outside development mode.")
       (assert-true (not (search "hyperbook-fedwiki-graphviz-save-button" html))
                    "Graphviz save controls must be absent outside development mode."))
     (let* ((before (hyperbook/fedwiki::read-localhost-fedwiki-page-json-file path))
            (error-signaled-p
             (call-with-story-items-smoke-development-mode
              nil
              (lambda ()
                (handler-case
                    (progn
                      (hyperbook/fedwiki::persist-localhost-fedwiki-story-item-text-edit-at-path
                       path
                       "fixture-graphviz"
                       "digraph { alpha -> beta }"
                       :item-type :graphviz)
                      nil)
                  (error () t)))))
            (after (hyperbook/fedwiki::read-localhost-fedwiki-page-json-file path)))
       (assert-true error-signaled-p
                    "Graphviz text edit persistence must fail closed outside development mode.")
       (assert-equal (gethash "text" (elt (gethash "story" before) 0))
                     (gethash "text" (elt (gethash "story" after) 0))
                     "Rejected non-development edits must not change the page JSON.")))))

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
                  "Missing video id must stay on the explicit adaptation-failure path.")
    (assert-equal '(:provider "YOUTUBE")
                  (hyperbook/fedwiki::adaptation-failure-partial-fields-of adapted)
                  "Missing video id must keep the parsed provider in partial-fields.")))

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
                  "Extra header tokens must stay on the explicit malformed-header failure path.")
    (assert-equal '(:provider "YOUTUBE" :video-id "UjPxDOEdsX8")
                  (hyperbook/fedwiki::adaptation-failure-partial-fields-of adapted)
                  "Malformed video headers must keep the parsed header fields in partial-fields.")))

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
                  "Unsupported providers must stay on the explicit adaptation-failure path.")
    (assert-equal '(:provider "VIMEO" :video-id "UjPxDOEdsX8")
                  (hyperbook/fedwiki::adaptation-failure-partial-fields-of adapted)
                  "Unsupported video providers must keep the parsed provider and id in partial-fields.")))

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
                  "Malformed frame HEIGHT must stay on the explicit malformed-height failure path.")
    (assert-equal '(:target-url "https://example.org/embed/widget"
                    :height-line "HEIGHT giant")
                  (hyperbook/fedwiki::adaptation-failure-partial-fields-of adapted)
                  "Malformed frame HEIGHT must keep the parsed URL and height line in partial-fields.")))

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
                  "Missing frame URL must stay on the explicit missing-url failure path.")
    (assert-equal nil
                  (hyperbook/fedwiki::adaptation-failure-partial-fields-of adapted)
                  "Missing frame URL should not invent partial-fields.")))

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
                  "Raw <iframe ...> HTML must be rejected explicitly instead of best-effort embedding.")
    (assert-equal '(:first-line "<iframe src=\"https://example.org/embed/widget\" height=\"420\"></iframe>")
                  (hyperbook/fedwiki::adaptation-failure-partial-fields-of adapted)
                  "Raw <iframe ...> HTML failures must keep the first line in partial-fields.")))

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

(defun run-fedwiki-story-item-audio-direct-media-adaptation-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :audio
       "https://example.org/audio.mp3
Episode notes for the direct media case.")
    (assert-true (typep adapted 'hyperbook/fedwiki::adapted-audio-snippet)
                 "A direct-media audio URL plus caption must adapt to an adapted-audio-snippet.")
    (assert-equal "https://example.org/audio.mp3"
                  (hyperbook/fedwiki::adapted-audio-snippet-target-url-of adapted)
                  "The adapted audio snippet must preserve the parsed target URL.")
    (assert-equal "Episode notes for the direct media case."
                  (hyperbook/fedwiki::adapted-audio-snippet-caption-of adapted)
                  "The adapted audio snippet must preserve the trailing caption/body text.")
    (assert-equal :direct-media
                  (hyperbook/fedwiki::adapted-audio-snippet-url-kind-of adapted)
                  "Direct media URLs must classify to the preferred direct-media path.")
    (assert-true (eq item
                     (hyperbook/fedwiki::adapted-audio-snippet-source-item-of adapted))
                 "The adapted audio snippet must retain the original source-faithful story item.")
    (assert-true (eq page
                     (hyperbook/fedwiki::adapted-audio-snippet-source-page-of adapted))
                 "The adapted audio snippet must retain the source page.")
    (assert-equal :audio
                  (hyperbook/fedwiki::item-type-of item)
                  "The original audio story item type must remain unchanged.")
    (assert-equal "https://example.org/audio.mp3
Episode notes for the direct media case."
                  (hyperbook/fedwiki::text-of item)
                  "The original audio story item text must remain source-faithful after adaptation.")))

(defun run-fedwiki-story-item-audio-direct-media-url-only-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :audio
       "https://example.org/audio.mp3")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::adapted-audio-snippet)
                 "A direct-media audio URL without caption must still adapt successfully.")
    (assert-equal :direct-media
                  (hyperbook/fedwiki::adapted-audio-snippet-url-kind-of adapted)
                  "A direct-media audio URL without caption must stay on the direct-media path.")
    (assert-equal ""
                  (hyperbook/fedwiki::adapted-audio-snippet-caption-of adapted)
                  "A URL-only audio snippet must produce an empty caption/body string.")))

(defun run-fedwiki-story-item-audio-fallback-only-adaptation-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :audio
       "https://www.listennotes.com/e/p/4308ac34a98a4027b735398ea21d3582/
Line one of the audio notes.
Line two with [https://example.org link].")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::adapted-audio-snippet)
                 "A valid non-direct-media audio reference must still adapt successfully.")
    (assert-equal :fallback-only
                  (hyperbook/fedwiki::adapted-audio-snippet-url-kind-of adapted)
                  "Semantically valid non-direct-media audio URLs must classify to the fallback-only path.")
    (assert-equal "Line one of the audio notes.
Line two with [https://example.org link]."
                  (hyperbook/fedwiki::adapted-audio-snippet-caption-of adapted)
                  "Fallback-only audio snippets must preserve the multiline body as caption text.")))

(defun run-fedwiki-story-item-audio-missing-url-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :audio
       "

")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::story-item-adaptation-failure)
                 "Audio snippets without a URL must produce a story-item-adaptation-failure.")
    (assert-equal :missing-url
                  (hyperbook/fedwiki::adaptation-failure-reason-of adapted)
                  "Missing audio URLs must stay on the explicit missing-url failure path.")
    (assert-equal nil
                  (hyperbook/fedwiki::adaptation-failure-partial-fields-of adapted)
                  "Missing audio URLs should not invent partial-fields.")))

(defun run-fedwiki-story-item-audio-non-http-url-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :audio
       "ftp://example.org/audio.mp3
Fallback body")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::story-item-adaptation-failure)
                 "Non-http(s) first lines must produce a story-item-adaptation-failure.")
    (assert-equal :non-http-url
                  (hyperbook/fedwiki::adaptation-failure-reason-of adapted)
                  "Non-http(s) first lines must stay on the explicit non-http-url failure path.")
    (assert-equal '(:first-line "ftp://example.org/audio.mp3")
                  (hyperbook/fedwiki::adaptation-failure-partial-fields-of adapted)
                  "Non-http(s) audio failures must keep the first line in partial-fields.")))

(defun run-fedwiki-story-item-audio-raw-html-unsupported-smoke-test ()
  (multiple-value-bind (adapted item page)
      (adapt-story-items-smoke-item
       :audio
       "<audio src=\"https://example.org/audio.mp3\"></audio>")
    (declare (ignore item page))
    (assert-true (typep adapted 'hyperbook/fedwiki::story-item-adaptation-failure)
                 "Raw <audio ...> HTML must stay on the explicit failure path in this slice.")
    (assert-equal :raw-audio-html-unsupported
                  (hyperbook/fedwiki::adaptation-failure-reason-of adapted)
                  "Raw <audio ...> HTML must be rejected explicitly instead of best-effort embedding.")
    (assert-equal '(:first-line "<audio src=\"https://example.org/audio.mp3\"></audio>")
                  (hyperbook/fedwiki::adaptation-failure-partial-fields-of adapted)
                  "Raw <audio ...> failures must keep the first line in partial-fields.")))

(defun run-fedwiki-story-item-audio-preferred-render-smoke-test ()
  (let ((html
         (render-story-item-to-string
          :audio
          "https://example.org/audio.mp3
Episode notes for the direct media case.")))
    (assert-true (search "<audio" html :test #'char-equal)
                 "Direct-media audio rendering must use the preferred HTML5 audio path.")
    (assert-true (search "https://example.org/audio.mp3" html :test #'char=)
                 "Direct-media audio rendering must include the source URL.")
    (assert-true (search "Episode notes for the direct media case." html :test #'char=)
                 "Direct-media audio rendering must include the caption/body text.")
    (assert-true (search "Open/download audio" html :test #'char=)
                 "Direct-media audio rendering must keep a visible open/download link.")
    (assert-true (not (search "External audio reference" html :test #'char=))
                 "Direct-media audio rendering must stay on the preferred path, not the fallback-only card.")
    (assert-true (not (search "Audio adaptation failed." html :test #'char=))
                 "Direct-media audio rendering must stay on the success path, not the failure path.")))

(defun run-fedwiki-story-item-audio-fallback-only-render-smoke-test ()
  (let ((html
         (render-story-item-to-string
          :audio
          "https://www.listennotes.com/e/p/4308ac34a98a4027b735398ea21d3582/
Line one of the audio notes.
Line two with [https://example.org link].")))
    (assert-true (not (search "<audio" html :test #'char-equal))
                 "Fallback-only audio references must not force an HTML5 audio element.")
    (assert-true (search "External audio reference" html :test #'char=)
                 "Fallback-only audio rendering must use the bounded external-audio reference card.")
    (assert-true (search "Open audio reference" html :test #'char=)
                 "Fallback-only audio rendering must expose the explicit open link.")
    (assert-true (search "Line one of the audio notes." html :test #'char=)
                 "Fallback-only audio rendering must preserve the first caption/body line.")
    (assert-true (search "Line two with" html :test #'char=)
                 "Fallback-only audio rendering must preserve later body lines.")
    (assert-true (not (search "Audio adaptation failed." html :test #'char=))
                 "Fallback-only audio rendering must stay on the success path, not the failure path.")))

(defun run-fedwiki-story-item-audio-failure-render-smoke-test ()
  (let ((html
         (render-story-item-to-string
          :audio
          "<audio src=\"https://example.org/audio.mp3\"></audio>")))
    (assert-true (search "Audio adaptation failed." html :test #'char=)
                 "Unsupported raw <audio ...> input must render an explicit audio failure block.")
    (assert-true (search "Raw &lt;audio ...&gt; HTML or HTML-contaminated audio lines are unsupported in this slice." html :test #'char=)
                 "The audio failure renderer must expose the explicit unsupported-html reason.")
    (assert-true (search "Original story item:" html :test #'char=)
                 "The audio failure renderer must keep the original story item inspectable.")
    (assert-true (search "&lt;audio src=&quot;https://example.org/audio.mp3&quot;&gt;&lt;/audio&gt;"
                         html
                         :test #'char=)
                 "The audio failure renderer must include raw source fallback from the original story item.")
    (assert-true (not (search "Open/download audio" html :test #'char=))
                 "The audio failure renderer must stay visibly separate from the direct-media success path.")
    (assert-true (not (search "External audio reference" html :test #'char=))
                 "The audio failure renderer must stay visibly separate from the fallback-only success path.")))

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
  (run-fedwiki-story-item-audio-direct-media-adaptation-smoke-test)
  (run-fedwiki-story-item-audio-direct-media-url-only-smoke-test)
  (run-fedwiki-story-item-audio-fallback-only-adaptation-smoke-test)
  (run-fedwiki-story-item-audio-missing-url-smoke-test)
  (run-fedwiki-story-item-audio-non-http-url-smoke-test)
  (run-fedwiki-story-item-audio-raw-html-unsupported-smoke-test)
  (run-fedwiki-story-item-audio-preferred-render-smoke-test)
  (run-fedwiki-story-item-audio-fallback-only-render-smoke-test)
  (run-fedwiki-story-item-audio-failure-render-smoke-test)
  (run-fedwiki-story-item-graphviz-render-smoke-test)
  (run-fedwiki-story-item-graphviz-development-mode-gating-smoke-test)
  (run-fedwiki-story-item-graphviz-readonly-mode-smoke-test)
  (run-fedwiki-story-item-graphviz-edit-persistence-smoke-test)
  (run-fedwiki-story-item-short-hash-negative-test)
  (run-fedwiki-story-item-non-hex-negative-test)
  (run-fedwiki-story-item-explicit-link-boundary-test)
  (format t "~&FedWiki story-item smoke tests passed.~%")
  t)
