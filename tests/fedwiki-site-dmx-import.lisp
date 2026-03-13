;;;; Tests for FedWiki-to-DMX importer

(in-package :hyperdoc/tests)

(defun make-test-json-item (&key type text)
  (let ((item (make-hash-table :test #'equal)))
    (when type
      (setf (gethash "type" item) type))
    (when text
      (setf (gethash "text" item) text))
    item))

(defun make-test-json-page (&key title story journal)
  (let ((page (make-hash-table :test #'equal)))
    (setf (gethash "title" page) title
          (gethash "story" page) story
          (gethash "journal" page) journal)
    page))

(defun make-test-journal-entry (date)
  (let ((entry (make-hash-table :test #'equal)))
    (setf (gethash "date" entry) date)
    entry))

(defun make-test-fedwiki ()
  (make-instance 'hyperbook/fedwiki::fedwiki
                 :id "fedwiki:sfw.c2.com"))

(defun assert-string= (expected actual message)
  (unless (string= expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun run-fedwiki-summary-extraction-test ()
  (let* ((story (vector (make-test-json-item :type "image" :text "caption")
                        (make-test-json-item :type "paragraph"
                                             :text " First useful paragraph. ")
                        (make-test-json-item :type "paragraph"
                                             :text "Later paragraph")))
         (summary (hyperdoc::derive-fedwiki-summary-from-story story "Fallback")))
    (assert-string= "First useful paragraph."
                    summary
                    "Summary should prefer the first paragraph-like text item")))

(defun run-fedwiki-external-key-test ()
  (assert-string= "fedwiki:sfw.c2.com/welcome-visitors"
                  (hyperdoc::fedwiki-import-external-key "sfw.c2.com"
                                                         "welcome-visitors")
                  "External key must use site domain plus slug"))

(defun run-fedwiki-local-page-filter-test ()
  (let* ((wiki (make-test-fedwiki))
         (local (hyperbook/fedwiki::make-fedwiki-page wiki "alpha" "Alpha"))
         (remote (make-instance 'hyperbook/fedwiki::remote-fedwiki-page
                                :hyperbook wiki
                                :id "remote.example/beta"
                                :title "Beta"
                                :origin wiki
                                :origin-id "beta"))
         (plugin (make-instance 'hyperbook/fedwiki::fedwiki-plugin-page
                                :hyperbook wiki
                                :id "gamma"
                                :title "Gamma"
                                :plugin (make-instance 'hyperbook/fedwiki::fedwiki-plugin
                                                       :wiki wiki
                                                       :name "example"))))
    (setf (gethash "alpha" (hyperbook/fedwiki::pages-of wiki)) local
          (gethash "remote.example/beta" (hyperbook/fedwiki::pages-of wiki)) remote
          (gethash "gamma" (hyperbook/fedwiki::pages-of wiki)) plugin)
    (let ((pages (hyperdoc::collect-local-fedwiki-pages wiki)))
      (assert-equal 1 (length pages)
                    "Only local pages should be collected for import")
      (assert-string= "alpha"
                      (hyperbook:id-of (first pages))
                      "Collected page must be the local slug"))))

(defun run-fedwiki-dry-run-plan-test ()
  (let* ((wiki (make-test-fedwiki))
         (page-a (hyperbook/fedwiki::make-fedwiki-page wiki "alpha" "Alpha"))
         (page-b (hyperbook/fedwiki::make-fedwiki-page wiki "beta" "Beta"))
         (page-jsons (list (cons "alpha"
                                 (make-test-json-page
                                  :title "Alpha"
                                  :story (vector (make-test-json-item
                                                  :type "paragraph"
                                                  :text "Alpha summary"))
                                  :journal (vector (make-test-journal-entry 1000))))
                           (cons "beta"
                                 (make-test-json-page
                                  :title "Beta"
                                  :story (vector (make-test-json-item
                                                  :type "markdown"
                                                  :text "Beta summary"))
                                  :journal (vector (make-test-journal-entry 2000))))))
         (client (make-instance 'hyperdoc::memory-dmx-import-client))
         result)
    (setf (gethash "alpha" (hyperbook/fedwiki::pages-of wiki)) page-a
          (gethash "beta" (hyperbook/fedwiki::pages-of wiki)) page-b)
    (setf (gethash "fedwiki:sfw.c2.com/alpha"
                   (hyperdoc::topics-by-external-key-of client))
          '(:external-key "fedwiki:sfw.c2.com/alpha"))
    (setf result
          (hyperdoc::import-fedwiki-site-to-dmx
           :domain "sfw.c2.com"
           :dry-run t
           :limit 1
           :wiki wiki
           :client client
           :page-json-loader
           (lambda (fedwiki page)
             (declare (ignore fedwiki))
             (cdr (assoc (hyperbook:id-of page) page-jsons :test #'string=)))
           :now 123456))
    (assert-equal 2 (getf result :available-candidates)
                  "Dry-run should report all available local pages")
    (assert-equal 1 (getf result :selected-candidates)
                  "Limit mode should reduce the selected candidate count")
    (assert-equal 1 (getf result :skipped-candidates)
                  "Dry-run should report how many candidates were skipped by the limit")
    (assert-true (getf result :lookup-enabled)
                 "A non-null import client should enable lookup accounting")
    (assert-string= "https"
                    (getf result :resolved-protocol)
                    "An explicit test wiki should preserve its configured protocol")
    (assert-true (not (getf result :http-fallback-used))
                 "An explicit test wiki should not trigger the importer HTTP fallback")
    (assert-equal 0 (getf result :creates)
                  "Existing external key should be planned as update, not create")
    (assert-equal 1 (getf result :updates)
                  "Existing external key should produce one update plan entry")))

(defun run-fedwiki-dmx-payload-test ()
  (let* ((candidate (hyperdoc::make-fedwiki-import-candidate
                     :external-key "fedwiki:sfw.c2.com/alpha"
                     :domain "sfw.c2.com"
                     :slug "alpha"
                     :title "Alpha"
                     :canonical-html-url "https://sfw.c2.com/alpha.html"
                     :canonical-json-url "https://sfw.c2.com/alpha.json"
                     :summary "Alpha summary"
                     :source-kind "fedwiki-page"
                     :page-json (make-test-json-page
                                 :title "Alpha"
                                 :story (vector (make-test-json-item
                                                 :type "paragraph"
                                                 :text "Alpha summary")))
                     :raw-journal-timestamp 111
                     :last-sync-timestamp 222))
         (payload (hyperdoc::fedwiki-import-payload candidate))
         (children (getf payload :children))
         (encoded-page-json (gethash "fedwiki.page.json" children))
         (page-json (shasht:read-json encoded-page-json)))
    (assert-string= "fedwiki.page"
                    (getf payload :type-uri)
                    "FedWiki import payload must reuse the existing fedwiki.page type")
    (assert-string= "fedwiki:sfw.c2.com/alpha"
                    (getf payload :uri)
                    "FedWiki import payload must store the stable external key as topic URI")
    (assert-string= "alpha"
                    (gethash "fedwiki.slug" children)
                    "FedWiki import payload must store the page slug in the typed child topic")
    (assert-true (and encoded-page-json
                      (string= "sfw.c2.com"
                               (gethash "siteDomain" page-json))
                      (string= "fedwiki:sfw.c2.com/alpha"
                               (gethash "externalKey" page-json)))
                 "FedWiki import payload must preserve site provenance inside fedwiki.page.json")))

(defun run-fedwiki-import-duplicate-key-test ()
  (let* ((candidate-a (hyperdoc::make-fedwiki-import-candidate
                       :external-key "fedwiki:sfw.c2.com/dup"
                       :domain "sfw.c2.com"
                       :slug "dup"
                       :title "A"
                       :canonical-html-url "https://sfw.c2.com/dup.html"
                       :canonical-json-url "https://sfw.c2.com/dup.json"
                       :summary "A"
                       :source-kind "fedwiki-page"
                       :last-sync-timestamp 1))
         (candidate-b (hyperdoc::make-fedwiki-import-candidate
                       :external-key "fedwiki:sfw.c2.com/dup"
                       :domain "sfw.c2.com"
                       :slug "dup"
                       :title "B"
                       :canonical-html-url "https://sfw.c2.com/dup.html"
                       :canonical-json-url "https://sfw.c2.com/dup.json"
                       :summary "B"
                       :source-kind "fedwiki-page"
                       :last-sync-timestamp 1))
         (raised nil))
    (handler-case
        (hyperdoc::plan-fedwiki-site-dmx-import
         (list candidate-a candidate-b)
         (make-instance 'hyperdoc::null-dmx-import-client))
      (hyperdoc::duplicate-fedwiki-import-key ()
        (setf raised t)))
    (assert-true raised
                 "Duplicate external keys in one run must signal an error")))

(defun run-fedwiki-site-dmx-import-tests ()
  (run-fedwiki-summary-extraction-test)
  (run-fedwiki-external-key-test)
  (run-fedwiki-local-page-filter-test)
  (run-fedwiki-dry-run-plan-test)
  (run-fedwiki-dmx-payload-test)
  (run-fedwiki-import-duplicate-key-test)
  (format t "~&FedWiki site to DMX import tests passed.~%")
  t)

(defun run-hyperdoc-tests ()
  (run-dmx-topic-proxy-smoke-tests)
  (run-article-allegation-slice-smoke-tests)
  (run-fedwiki-materialization-smoke-tests)
  (run-fedwiki-site-dmx-import-tests)
  (run-fedwiki-story-items-smoke-tests)
  (run-check-runner-smoke-tests)
  (run-merged-doc-slices-smoke-tests)
  t)

(export '(run-fedwiki-site-dmx-import-tests run-hyperdoc-tests))
