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

;; The ordinary paragraph renderer offers only external hyperlinks. Add the
;; existing object-ref affordance for these four actual items, leaving their
;; original text/link rendering untouched. Establish provenance before the item
;; is opened, even when no page-wide Source references view has been evaluated.
(defmethod hyperbook/fedwiki::render-story-item :after
    ((type (eql :paragraph)) (item hyperbook/fedwiki::story-item)
     (page hyperbook/fedwiki::fedwiki-page))
  (when (and (how-trails-page-p page)
             (find (hyperbook/fedwiki::id-of item) *how-trails-coordinates*
                   :key #'first :test #'equal)
             (find item (hyperbook/fedwiki::story-of page) :test #'eq))
    (let ((source (find item (how-trails-sources page) :key #'how-source-item :test #'eq)))
      (when source
        (html-inspector-views:html
          (:p (:small (html-inspector-views:object-ref item :select "Data"
                        :display (format nil "Inspect story item ~A"
                                         (hyperbook/fedwiki::id-of item))))))))))

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
      (:p (html-inspector-views:object-ref (how-source-item source) :display "Return to original plan step" :select "Plan step"))
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

;; Page-local commentary keyed by original item identity, not a plan language.
;; Each row separates pinned implementation, retained execution, intent and gap.
(defparameter *how-trails-plan-notes*
  '(("f6ed717454f29690"
     "dochoose selects checked beam entries and calls display(chosen), L107–113. Ward links only L107."
     "The record contains chosen aspects; it is not an event trace of dochoose."
     "Ward uses this selection as the starting point for his plan."
     "Where should selected trail identity be captured?" "chosen")
    ("d60bd1c1d8fdd32b"
     "The inputs carry relations of type Trail; no chosen-trail detector is established here."
     "chosen preserves separate aspect graphs and Trail relations."
     "Detect trails within chosen using relation type Trail."
     "What constitutes one ordered trail, including shared edges?" "chosen")
    ("fc195fe5fbc3592f"
     "composite returns {graph:comp, merged}, with no trails field."
     "overlap and overlap-removed lose duplicate membership in the same complex result."
     "Add chosen trails[] to complex. This is proposed, not implemented."
     "How will multiple memberships survive deduplication?" "complex" "relationMap")
    ("d1b0aa5e1a47349e"
     "display calls composite(chosen), then dotify(complex), then asynchronous Graphviz layout."
     "The retained record exposes complex, dot and SVG output, not a general lifecycle guarantee."
     "Ward places trail preservation along this flow."
     "At which boundary should additional trail data be retained?" "complex" "dot" "svg")
    ("fcbf4b3a2dcbe81b"
     "composite matches nodes by type/name and relations by type and directed mapped endpoints."
     "overlap collapses a shared relation; reverse order changes the winning source property."
     "Carry chosen trails alongside the merged graph."
     "How should source-qualified occurrences map to composite identifiers?" "complex" "relationMap")
    ("d41b9ef67e45521e"
     "dotify consumes graph and merged and returns DOT; it does not consume trails[]."
     "Retained dot and SVG identify composite nodes/relations, not original trail membership."
     "Ward considers the DOT boundary in his trail rendering plan."
     "How will later rendering recover ordered trail occurrences?" "dot" "svg")
    ("db592e6139141964"
     "No const trails occurs in the checked dotify range L382–446."
     "No removal experiment is recorded."
     "Remove const trails."
     "Which experimental source revision contains the declaration Ward means?")
    ("93dc48d83a96cd61"
     "display calls hpccWasm.graphviz.layout(window.dot, svg, dot) and installs returned SVG."
     "The recorded SVG titles identify composite indices; zoom changes transform, not those identifiers."
     "Ward places subsequent trail drawing after Graphviz."
     "No arbitrary relayout, reload or rename guarantee follows." "svg" "zoom")
    ("8771026b69762044"
     "The referenced display range does not establish the diagnostic dots mentioned here."
     "No diagnostic-dot removal is tested."
     "Remove diagnostic dots."
     "Which experimental renderer contains these dots?")
    ("aac36e1826b25199"
     "display installs SVG and initializes pan/zoom; no chosen trails[] overlay is established."
     "The retained zoom observation records a viewport transform only."
     "Render chosen trails[] in a group sharing the transform. Not implemented by this investigation."
     "Polyline geometry and transform coupling remain unverified." "zoom")))

(defvar *how-trails-execution* nil)
(defun how-trails-execution ()
  (or *how-trails-execution*
      (setf *how-trails-execution* (read-observation "dreyeck/work/solo-trail-identity.json"))))

(defun how-trails-section (page name)
  "Return original item objects in document order, bounded by pagefolds."
  (hyperbook/fedwiki::load-page page)
  (loop with active = nil
        for item across (hyperbook/fedwiki::story-of page)
        if (eq :pagefold (hyperbook/fedwiki::item-type-of item))
          do (setf active (equal name (hyperbook/fedwiki::text-of item)))
        else when active collect item))

(defun how-trails-item-context (item)
  ;; Established by the native page views; exact objects, never an ID-only match.
  (loop for page being the hash-keys of *how-trails-sources*
        when (find item (hyperbook/fedwiki::story-of page) :test #'eq)
          return page))

(defun how-trails-step-content (page item)
  (let* ((id (hyperbook/fedwiki::id-of item))
         (notes (assoc id *how-trails-plan-notes* :test #'equal))
         (source (find item (how-trails-sources page) :key #'how-source-item :test #'eq)))
    (html-inspector-views:html
      (:blockquote (cl-who:esc (hyperbook/fedwiki::text-of item)))
      (when notes
        (loop for label in '("Existing implementation" "Executed observation" "Ward's announced change" "Open question")
              for text in (subseq notes 1 5) do
          (html-inspector-views:html (:p (:strong (cl-who:esc label)) ": " (cl-who:esc text)))))
      (when source
        (html-inspector-views:html
          (:p (html-inspector-views:object-ref source :display (how-source-name source) :select "Source reference"))))
      (when (nthcdr 5 notes)
        (html-inspector-views:html
          (:p "Retained offline execution, not a new run: "
              (html-inspector-views:object-ref (how-trails-execution) :display "Execution record and provenance"))
          (:ul (loop for case across (gethash "cases" (how-trails-execution)) do
            (html-inspector-views:html
              (:li (html-inspector-views:object-ref case :display (gethash "label" case))
                (dolist (key (nthcdr 5 notes))
                  (when (gethash key case)
                    (html-inspector-views:html " / "
                      (html-inspector-views:object-ref (gethash key case)
                        :display (format nil "~A: ~A" (gethash "label" case) key))))))))))))))

(html-inspector-views:defview how-trails-plan (page hyperbook/fedwiki::fedwiki-page)
  (when (how-trails-page-p page)
    (how-trails-sources page)
    (html-inspector-views:html-view :title "Plan" :priority 4
      (html-inspector-views:html
        (:h2 "Ward's plan — original order")
        (:p "Original paragraphs below the plan pagefold. Commentary distinguishes the pinned implementation from proposed work; opening this view executes no JavaScript.")
        (:p (how-trails-reading-link))
        (:ol (dolist (item (how-trails-section page "plan"))
               (html-inspector-views:html
                 (:li (html-inspector-views:object-ref item :select "Plan step"
                        :display (format nil "Plan step ~A" (hyperbook/fedwiki::id-of item)))
                      (how-trails-step-content page item)))))))))

(html-inspector-views:defview how-trails-step (item hyperbook/fedwiki::story-item)
  (let ((page (how-trails-item-context item)))
    (when (and page (member item (how-trails-section page "plan") :test #'eq))
      (html-inspector-views:html-view :title "Plan step" :priority 1
        (html-inspector-views:html
          (:h2 (cl-who:esc (format nil "Plan step ~A" (hyperbook/fedwiki::id-of item))))
          (how-trails-step-content page item)
          (:p (html-inspector-views:object-ref page :select "Plan" :display "Return to original plan")
              " / " (html-inspector-views:object-ref item :select "Data" :display "Original item data")))))))

(html-inspector-views:defview how-trails-refactor (page hyperbook/fedwiki::fedwiki-page)
  (when (how-trails-page-p page)
    (let ((sources (how-trails-sources page)))
      (html-inspector-views:html-view :title "Refactor" :priority 5
        (html-inspector-views:html
          (:h2 "Ward's architecture question")
          (dolist (item (how-trails-section page "refactor"))
            (html-inspector-views:html
              (:blockquote (cl-who:esc (hyperbook/fedwiki::text-of item)))
              (:p (html-inspector-views:object-ref item :display "Original refactor paragraph" :select "Data"))))
          (:h3 "Existing implementation — pinned source")
          (:p "dochoose → display(chosen); display → composite(chosen) → {graph, merged}; display → dotify(complex) → DOT; display → asynchronous Graphviz layout → SVG → target.innerHTML, clickready and pan/zoom. Graphviz is called by display, not by dotify. L107 alone is not the complete dochoose body; inspect the full retained file for L107–113.")
          (:ul (dolist (source sources)
            (html-inspector-views:html (:li (html-inspector-views:object-ref source :display (how-source-name source) :select "Source reference")))))
          (:p (html-inspector-views:object-ref *how-trails-file* :select "Evidence locations" :display "Pinned file and source coordinates")
              " / " (html-inspector-views:object-ref
                       (following-path "assets/hyperbook/fedwiki/mech-host/plugins/solo/dialog/index.html")
                       :select "Text" :display "Full retained source"))
          (:h3 "Executed observation")
          (:p "Shared directed relations lose multiple membership in the retained counterexample. Derived maps are witness data, not Solo return fields. "
              (html-inspector-views:object-ref (how-trails-execution) :display "Execution record and provenance"))
          (:h3 "Ward's announced change")
          (:p "Ward asks whether this flow could be made more overt and proposes carrying chosen trails through it. The paragraph's Croquet history is Ward's account, not independently established by this source comparison.")
          (:h3 "Open question")
          (:p "A possible refactor would make selection, composition and rendering boundaries explicit. This is an interpretive proposal, not implemented architecture. Where to retain trail occurrences before merge and how to render them after Graphviz remain open.")
          (:p (html-inspector-views:object-ref page :select "Plan" :display "Return to original plan")
              " / " (how-trails-reading-link)))))))
