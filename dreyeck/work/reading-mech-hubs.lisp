;;;; Reading Mech Hubs
(defpackage #:dreyeck/work/hubs
  (:use #:cl)
  (:local-nicknames (#:reading #:dreyeck/work/trails-rendered-reading)
                    (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap)
                    (#:views #:html-inspector-views)))
(in-package #:dreyeck/work/hubs)
(hyperdoc:see (hyperdoc:page "What Counts as a Hub?" :hyperbook "dreyeck/work/reading"))
(hyperdoc:see (hyperdoc:page "From Two Hubs to One Trail" :hyperbook "dreyeck/work/reading"))

(defvar *hub-record* nil)
(defvar *hub-sources* nil)
(defvar *hub-workspace* nil)
(defparameter *hub-library-digest* "a55269686c5941a5a058c08bef2e0ef3afcaa22c87f6b7bc61a0e10e34776a7b")
(defparameter *hub-revision*
  (dreyeck/git:make-git-revision-reference
   :authority "local:/Users/rgb/workspace/hyperdoc"
   :oid "9a1764250f31013a50965aad324dd72c0662b9cc"
   :role "Verified local HyperDoc Git tree containing the retained composed Mech module; not Ward's runtime revision"))
(defparameter *hub-file*
  (dreyeck/git:ensure-git-evidence-file *hub-revision*
    "assets/hyperbook/fedwiki/mech-host/plugins/mech/library.js"))

(defun checked-hub-json (path digest)
  (unless (equal digest (ironclad:byte-array-to-hex-string
                        (ironclad:digest-file :sha256 (reading::following-path path))))
    (error "Hub evidence digest mismatch: ~A" path))
  (reading::read-observation path))

(defun hub-record ()
  "Read retained synthetic evidence; rendering never starts Node or executes a Story."
  (or *hub-record*
      (setf *hub-record* (checked-hub-json "dreyeck/work/hubs-evidence/synthetic-selection.json"
                         "d263f1888f5f94f06a48ff8f1357b480a4b6950eb6637429c1de6c1313db2a52"))))

(defclass hub-source (reading::trail-source-fragment) ())
(defun hub-source-name (source) (gethash "name" (reading::fragment-metadata source)))

(hyperdoc:defexample hub-sources
  "Checked walks, hubs and blanket slices from the actual composed Mech module."
  (or *hub-sources*
      (let* ((path (reading::following-path "assets/hyperbook/fedwiki/mech-host/plugins/mech/library.js"))
             (text (uiop:read-file-string path :external-format :utf-8)))
        (unless (equal *hub-library-digest* (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))
          (error "Retained Mech module changed; refusing source attribution."))
        (setf *hub-sources*
          (loop for metadata across (gethash "functions" (hub-record)) collect
            (progn
              ;; These checked slices precede non-ASCII characters: verify exact substrings.
              (assert (equal (gethash "text" metadata)
                             (subseq text (gethash "start" metadata) (gethash "end" metadata))))
              (let ((source (make-instance 'hub-source :metadata metadata
                             :text (gethash "text" metadata) :revision-file *hub-file*)))
                (dreyeck/git:add-git-evidence-location *hub-file* source)
                source)))))))

(defun hub-function (name)
  (or (find name (hub-sources) :key #'hub-source-name :test #'equal)
      (error "No checked Hub source: ~A" name)))

(views:defview hub-source-view (source hub-source)
  (views:html-view :title "Hub source" :priority -1
    (views:html
      (:h2 (views:esc (format nil "Mech source: ~A" (hub-source-name source))))
      (:p "Observed retained source; full current-module digest " (views:esc *hub-library-digest*))
      (:p "The module composes a CODE/Discourse base and a bounded Ward topics intake. Its declared Mech base 0fc36fcd58a8d7c399d3e86d2ee2e9328cafba44 was unavailable in the local Git stores and returned HTTP 404 at the raw src/client/library.js URL during this investigation. The actual retained module is verified in the local HyperDoc Git tree; no whole-upstream or runtime equivalence is asserted.")
      (:p (views:object-ref *hub-revision* :display "Verified retained Git revision" :select "Evidence revision")
          " / " (views:object-ref *hub-file* :display "Retained Git file" :select "Evidence locations")
          " / " (views:object-ref (reading::following-path "assets/hyperbook/fedwiki/mech-host/plugins/mech/library.js")
                                  :display "Complete composed module" :select "Text"))
      (:p (views:object-ref (reading::fragment-metadata source) :display "Exact checked source coordinates"))
      (:p (views:object-ref (hub-function "walks") :display "walks" :select "Hub source")
          " → " (views:object-ref (hub-function "hubs") :display "hubs" :select "Hub source")
          " → " (views:object-ref (hub-function "blanket") :display "blanket" :select "Hub source"))
      (:p (views:object-ref (hub-selection) :display "Synthetic selection and expansion" :select "Hub selection"))
      (:p (views:object-ref (work:work-page "What Counts as a Hub?") :display "Return to What Counts as a Hub?" :select "Content"))
      (:pre (views:esc (reading::fragment-text source))))))

(defmethod views:text-representation ((source hub-source))
  (format nil "Mech ~A source" (hub-source-name source)))
