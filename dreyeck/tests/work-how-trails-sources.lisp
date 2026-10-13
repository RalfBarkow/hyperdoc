(in-package #:dreyeck/work/trails-rendered-reading/tests)

(defun seed-how-trails-page ()
  "Fresh-runtime navigation fixture: exact retained original JSON, not a live fetch."
  (let* ((wiki (make-instance 'hyperbook/fedwiki::fedwiki :id "fedwiki:next.ward.dojo.fed.wiki"))
         (page (hyperbook/fedwiki::make-fedwiki-page wiki "how-trails-travel" "How Trails Travel")))
    (setf (hyperbook/fedwiki::status-of wiki) t
          (gethash "next.ward.dojo.fed.wiki" hyperbook/fedwiki::*neighborhood*) wiki
          (gethash "how-trails-travel" (hyperbook/fedwiki::pages-of wiki)) page)
    (setf (hyperbook::hyperbooks-of hyperbook::*catalog*)
          (remove "fedwiki:next.ward.dojo.fed.wiki"
                  (hyperbook::hyperbooks-of hyperbook::*catalog*)
                  :key #'hyperbook:id-of :test #'equal))
    ;; Only a navigation skeleton for the separate, uninspected Wiki-link target.
    ;; No claim about that page's content; original How Trails Travel stays exact.
    (setf (gethash "graceful-polyline" (hyperbook/fedwiki::pages-of wiki))
          (hyperbook/fedwiki::make-fedwiki-page wiki "graceful-polyline" "Graceful Polyline"))
    (hyperbook/fedwiki::set-page-data page
      (reading::read-observation "dreyeck/work/trails-rendered-evidence/next.ward.dojo.fed.wiki--how-trails-travel.json"))
    page))

(defun check-how-trails-sources ()
  (let* ((original-catalog hyperbook::*catalog*)
         (hyperbook::*catalog* (make-instance 'hyperbook::catalog))
         (hyperbook/fedwiki::*neighborhood* (make-hash-table :test #'equal)))
    (setf (hyperbook::factories-of hyperbook::*catalog*)
          (hyperbook::factories-of original-catalog)
          (hyperbook::hyperbooks-of hyperbook::*catalog*)
          (copy-list (hyperbook::hyperbooks-of original-catalog)))
  (let* ((page (seed-how-trails-page))
         (before (hyperbook/fedwiki::copy-page-json (hyperbook/fedwiki::raw-json-of page)))
         (sources (reading::how-trails-sources page))
         (book (hyperbook:find-hyperbook "dreyeck/work/reading")))
    (assert (eq sources (reading::how-trails-sources page)))
    (assert (= 4 (length sources)))
    (multiple-value-bind (text view) (render-page book "How Trails Travel")
      (declare (ignore text))
      (assert (member page (mapcar #'cdr (views:view-references view)) :test #'eq))
      (assert (find-if (lambda (o) (and (hash-table-p o) (gethash "cases" o)))
                      (mapcar #'cdr (views:view-references view)))))
    (let ((story (views:view-html (following-view page "Story")))
          (links (views:view-html (hyperbook::👀links (hyperbook:links-of page)))))
      (dolist (source sources)
        (assert (search (reading::how-source-url source) story))
        (assert (search (reading::how-source-url source) links))))
    (following-view page "Links")
    (following-view page "Source references")
    (loop for source in sources
          for (id name start end anchor) in
          '(("f6ed717454f29690" "window.dochoose" 107 107 "#L107")
            ("d1b0aa5e1a47349e" "display" 182 227 "#L182-L227")
            ("fcbf4b3a2dcbe81b" "composite" 318 378 "#L318-L378")
            ("d41b9ef67e45521e" "dotify" 382 446 "#L382-L446")) do
      (assert (equal name (reading::how-source-name source)))
      (assert (equal anchor (subseq (reading::how-source-url source)
                                   (- (length (reading::how-source-url source)) (length anchor)))))
      (assert (typep source 'reading::trail-source-fragment))
      (assert (equal id (hyperbook/fedwiki::id-of (reading::how-source-item source))))
      (assert (= start (gethash :start-line (reading::fragment-metadata source))))
      (assert (= end (gethash :end-line (reading::fragment-metadata source))))
      (assert (equal (reading::fragment-text source)
                     (format nil "~{~A~%~}"
                             (subseq (uiop:read-file-lines
                                      (reading::following-path "assets/hyperbook/fedwiki/mech-host/plugins/solo/dialog/index.html"))
                                     (1- start) end))))
      (let ((refs (mapcar #'cdr (views:view-references
                                (following-view (reading::how-source-item source) "Source reference")))))
        (assert (member source refs :test #'eq)))
      (let ((refs (mapcar #'cdr (views:view-references (following-view source "Source reference")))))
        (assert (member reading::*how-trails-revision* refs :test #'eq))
        (assert (member reading::*how-trails-file* refs :test #'eq))
        (assert (member (hyperbook:find-page book "How Trails Travel") refs :test #'eq))))
    (assert (equal (dreyeck/git:git-revision-identity reading::*how-trails-revision*)
                   '("https://github.com/WardCunningham/wiki-plugin-solo"
                     "17915844349bada64c901bd5ea73472702c446f9")))
    (assert (equal "client/dialog/index.html" (dreyeck/git:git-file-path-of reading::*how-trails-file*)))
    (following-view reading::*how-trails-file* "Evidence locations")
    (following-view reading::*how-trails-revision* "Evidence revision")
    ;; A same-slug page on another site and an unrelated item get no added views.
    (let* ((wiki (make-instance 'hyperbook/fedwiki::fedwiki :id "fedwiki:example.invalid"))
           (other (hyperbook/fedwiki::make-fedwiki-page wiki "how-trails-travel" "Other")))
      (assert (null (reading::how-trails-page-sources other)))
      (assert (null (reading::how-trails-page-sources
                     (hyperbook/fedwiki::make-fedwiki-page (hyperbook:hyperbook-of page)
                                                         "another-page" "Another page"))))
      (assert (null (reading::how-trails-item-source
                     (hyperbook/fedwiki::make-story-item
                      (alexandria:plist-hash-table '("type" "paragraph" "id" "f6ed717454f29690" "text" "Other") :test 'equal))))))
    (assert (equalp before (hyperbook/fedwiki::raw-json-of page)))
    (dolist (entry '(("dreyeck/work/trails-rendered-evidence/next.ward.dojo.fed.wiki--how-trails-travel.json" "2a98c388653c40c02dd44eb51b55067483dc1e6539e8b5b4074bfc8e8a613b79")
                     ("dreyeck/work/solo-trail-identity.json" "912d7ab4c1b7ed062107a18890eff36f625c154fa9e46969f2fd5f1206d2ce84")))
      (assert (equal (second entry) (ironclad:byte-array-to-hex-string
                    (ironclad:digest-file :sha256 (reading::following-path (first entry))))))))
  (format t "~&HOW-TRAILS-SOURCES-PASS: original Story/Links, four exact ranges, Git/source/reading navigation, page-local scope, unchanged evidence.~%")))
