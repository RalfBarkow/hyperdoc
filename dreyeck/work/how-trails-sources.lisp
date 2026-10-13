;;;; Ward's page-specific plan-to-source navigation. No JavaScript execution.
(in-package #:dreyeck/work/trails-rendered-reading)

(defparameter *how-trails-coordinates*
  '(("f6ed717454f29690" "window.dochoose" 107 107 "#L107")
    ("d1b0aa5e1a47349e" "display" 182 227 "#L182-L227")
    ("fcbf4b3a2dcbe81b" "composite" 318 378 "#L318-L378")
    ("d41b9ef67e45521e" "dotify" 382 446 "#L382-L446")))
(defparameter *how-trails-revision*
  (dreyeck/git:make-git-revision-reference
   :authority "https://github.com/WardCunningham/wiki-plugin-solo"
   :oid "17915844349bada64c901bd5ea73472702c446f9"
   :role "Pinned source linked by Ward's How Trails Travel plan; not current runtime"
   :web-url "https://github.com/WardCunningham/wiki-plugin-solo/commit/17915844349bada64c901bd5ea73472702c446f9"))
(defparameter *how-trails-file*
  (dreyeck/git:ensure-git-evidence-file *how-trails-revision* "client/dialog/index.html"))
(defvar *how-trails-sources* (make-hash-table :test #'eq))

(defclass how-trails-source (trail-source-fragment)
  ((page :initarg :page :reader how-source-page)
   (item :initarg :item :reader how-source-item)
   (url :initarg :url :reader how-source-url)
   (name :initarg :name :reader how-source-name)))

(defun how-trails-page-p (page)
  (and (equal "how-trails-travel" (hyperbook/fedwiki::origin-id-of page))
       (equal "next.ward.dojo.fed.wiki"
              (hyperbook/fedwiki::domain-name-of (hyperbook/fedwiki::origin-of page)))))

(defun how-trails-sources (page)
  (assert (how-trails-page-p page))
  (hyperbook/fedwiki::load-page page)
  (let ((cached (gethash page *how-trails-sources*)))
    (if (eq (car cached) (hyperbook/fedwiki::story-of page))
        (cdr cached)
        (let* ((path (following-path "assets/hyperbook/fedwiki/mech-host/plugins/solo/dialog/index.html"))
               (digest (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))
               (lines (uiop:read-file-lines path)))
          (unless (equal digest "5a513f70546ced3e2af7f83c4f14fb73d30e27f22a295558cbff4b078871aed8")
            (error "Pinned Solo source digest mismatch; refusing source attribution."))
          (let ((sources
                  (loop for (id name start end anchor) in *how-trails-coordinates*
                        for item = (find id (hyperbook/fedwiki::story-of page)
                                         :key #'hyperbook/fedwiki::id-of :test #'equal)
                        for url = (concatenate 'string
                           "https://github.com/WardCunningham/wiki-plugin-solo/blob/17915844349bada64c901bd5ea73472702c446f9/client/dialog/index.html" anchor)
                        collect
                        (progn
                          (unless (and item (search (format nil "[~A github]" url)
                                                   (hyperbook/fedwiki::text-of item)))
                            (error "Original source reference changed or missing: ~A" id))
                          (make-instance 'how-trails-source :page page :item item :url url :name name
                            :revision-file *how-trails-file*
                            :metadata (alexandria:plist-hash-table
                              (list :site "next.ward.dojo.fed.wiki" :slug "how-trails-travel"
                                    :story-item-id id :github-url url :start-line start :end-line end
                                    :file-sha256 digest :role :verified-retained-source-range))
                            :text (format nil "~{~A~%~}" (subseq lines (1- start) end)))))))
            ;; On an explicit page reload, retire only this page's old locations.
            (dolist (old (cdr cached))
              (setf (dreyeck/git:git-evidence-file-locations-of *how-trails-file*)
                    (remove old (dreyeck/git:git-evidence-file-locations-of *how-trails-file*))))
            (dolist (source sources) (dreyeck/git:add-git-evidence-location *how-trails-file* source))
            (setf (gethash page *how-trails-sources*)
                  (cons (hyperbook/fedwiki::story-of page) sources))
            sources)))))

(defun how-trails-reading-link ()
  (html-inspector-views:object-ref
   (hyperbook:find-page (hyperbook:find-hyperbook "dreyeck/work/reading") "How Trails Travel")
   :display "Return to How Trails Travel" :select "Content"))

(html-inspector-views:defview how-trails-page-sources (page hyperbook/fedwiki::fedwiki-page)
  (when (how-trails-page-p page)
    (let ((sources (how-trails-sources page)))
      (html-inspector-views:html-view :title "Source references" :priority 3
        (html-inspector-views:html
          (:p "Ward's four original story references. The checked ranges identify the pinned source, not a deployed runtime.")
          (:p (how-trails-reading-link))
          (:ul (dolist (source sources)
                 (html-inspector-views:html
                   (:li (html-inspector-views:object-ref (how-source-item source)
                          :display (hyperbook/fedwiki::id-of (how-source-item source))
                          :select "Source reference")
                        " → "
                        (html-inspector-views:object-ref source :display (how-source-name source)
                                                       :select "Source reference"))))))))))

(html-inspector-views:defview how-trails-item-source (item hyperbook/fedwiki::story-item)
  (let ((source (loop for pair being the hash-values of *how-trails-sources*
                      thereis (find item (cdr pair) :key #'how-source-item :test #'eq))))
    (when source
      (html-inspector-views:html-view :title "Source reference" :priority 0
        (html-inspector-views:html
          (:p (html-inspector-views:object-ref source :display (how-source-name source)
                                                   :select "Source reference")))))))

(html-inspector-views:defview how-trails-source-view (source how-trails-source)
  (html-inspector-views:html-view :title "Source reference" :priority -1
    (html-inspector-views:html
      (:h2 (cl-who:esc (how-source-name source)))
      (:p (how-trails-reading-link))
      (:p (html-inspector-views:object-ref (how-source-page source) :display "Original Wiki page" :select "Story")
          " / " (html-inspector-views:object-ref (how-source-item source) :display "Original story item"))
      (:p (html-inspector-views:object-ref (fragment-metadata source) :display "Wiki identity, exact lines and digest"))
      (:p (:a :href (how-source-url source) "Original GitHub link"))
      (:p (html-inspector-views:object-ref *how-trails-revision* :display "Pinned Git revision" :select "Evidence revision")
          " / " (html-inspector-views:object-ref (fragment-revision-file source) :display "Source file" :select "Evidence locations"))
      (:p "Exact referenced range, verified against the full file digest. L107 is a single-line reference, not the whole dochoose definition.")
      (:pre (cl-who:esc (fragment-text source))))))

(defmethod html-inspector-views:text-representation ((source how-trails-source))
  (format nil "~A — ~A, L~A–~A" (how-source-name source)
          (hyperbook/fedwiki::id-of (how-source-item source))
          (gethash :start-line (fragment-metadata source))
          (gethash :end-line (fragment-metadata source))))
