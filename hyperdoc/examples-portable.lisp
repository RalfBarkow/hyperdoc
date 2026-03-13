;;;; Examples
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; fedwiki-java translation helpers
;;

(defun fedwiki-java-example-slug-char-p (char)
  (or (alpha-char-p char)
      (digit-char-p char)
      (char= char #\-)))

(defun fedwiki-java-example-slug (text)
  "Approximate the slug logic used in fedwiki-java's Item.links()."
  (coerce (loop for char across text
                for normalized = (if (char= char #\Space) #\- char)
                when (fedwiki-java-example-slug-char-p normalized)
                  collect (char-downcase normalized))
          'string))

(defun fedwiki-java-example-context (journal)
  "Collect distinct site values by walking the journal backward."
  (let (sites)
    (dolist (entry (reverse journal) (nreverse sites))
      (let ((site (getf entry :site)))
        (when (and site (not (member site sites :test #'equal)))
          (push site sites))))))

(defun fedwiki-java-example-resolution-order (origin journal &key item-site)
  "Model the site search order used when following a collaborative link."
  (let ((context (fedwiki-java-example-context journal)))
    (when item-site
      (setf context (remove item-site context :test #'equal))
      (push item-site context))
    (cons origin (remove origin context :test #'equal))))

(defexample fedwiki-java-slug-example
  "Translate a collaborative link label into the slug used for lookup."
  (let* ((input "Collaborative Link")
         (slug (-> input
                   fedwiki-java-example-slug
                   (assert-equal "collaborative-link"))))
    (list :input input
          :slug slug)))

(defexample fedwiki-java-context-example
  "Translate page journal provenance into an ordered context site list."
  (let* ((journal (list (list :site "alpha.example")
                        (list :site nil)
                        (list :site "beta.example")
                        (list :site "alpha.example")
                        (list :site "gamma.example")))
         (context (-> journal
                      fedwiki-java-example-context
                      (assert-equal '("gamma.example" "alpha.example" "beta.example")))))
    (list :journal journal
          :context context)))

(defexample fedwiki-java-resolution-order-example
  "Translate collaborative-link resolution into the ordered site search path."
  (let* ((origin "origin.example")
         (journal (list (list :site "beta.example")
                        (list :site "gamma.example")
                        (list :site "beta.example")))
         (item-site "item.example")
         (order (-> (fedwiki-java-example-resolution-order
                     origin journal :item-site item-site)
                    (assert-equal '("origin.example" "item.example" "beta.example" "gamma.example")))))
    (list :origin origin
          :item-site item-site
          :journal journal
          :resolution-order order)))

(defexample fedwiki-commit-link-example
  "Translate a full Git commit hash in story text into a Software Heritage revision link."
  (let* ((hash "0123456789abcdef0123456789abcdef01234567")
         (text (format nil "See ~A and [https://example.org Example]" hash))
         (wiki (make-instance 'hyperbook/fedwiki::fedwiki
                              :id "fedwiki:examples.example"))
         (page (hyperbook/fedwiki::make-fedwiki-page wiki "example-page" "Example Page"))
         (links (hyperbook/fedwiki::extract-links-from-wiki-text text page))
         (urls (mapcar #'hyperbook:url-of
                       (remove-if-not (lambda (link-object)
                                        (typep link-object 'hyperbook:web-link))
                                      links)))
         (swhid (hyperbook/fedwiki::software-heritage-revision-swhid hash))
         (swh-url (hyperbook/fedwiki::software-heritage-revision-url hash)))
    (assert (member swh-url urls :test #'string=))
    (assert (member "https://example.org" urls :test #'string=))
    (list :source-text text
          :swhid swhid
          :software-heritage-url swh-url
          :urls urls)))

;;
;; journalmatic translation helpers
;;

(defun journalmatic-example-fix-chronology (page)
  (let ((page (copy-tree page)))
    (setf (getf page :journal)
          (journalmatic-example-sort-journal (getf page :journal)))
    page))

(defun journalmatic-example-compact-journal (page &key (entry-time-span 300000))
  (let* ((journal-in (journalmatic-example-sort-journal (getf page :journal)))
         (journal-out '())
         (previous-action nil))
    (labels ((flush-previous ()
               (when previous-action
                 (push previous-action journal-out)
                 (setf previous-action nil))))
      (dolist (action journal-in)
        (case (getf action :type)
          (:create
           (flush-previous)
           (push action journal-out))
          (:edit
           (if (null previous-action)
               (setf previous-action action)
               (if (and (equal (getf previous-action :id) (getf action :id))
                        (eql (getf previous-action :type) :edit)
                        (< (- (getf action :date) (getf previous-action :date))
                           entry-time-span))
                   (setf previous-action action)
                   (progn
                     (flush-previous)
                     (setf previous-action action)))))
          ((:add :move :remove)
           (flush-previous)
           (push action journal-out))
          (:fork
           (when (getf action :site)
             (flush-previous)
             (push action journal-out)))
          (otherwise nil)))
      (flush-previous)
      (let ((page (copy-tree page)))
        (setf (getf page :journal) (nreverse journal-out))
        page))))

(defexample journalmatic-revision-example
  "Replay a small journal into the current page state."
  (let* ((page *journalmatic-example-page*)
         (revised (journalmatic-example-revision (getf page :journal)
                                                 :title (getf page :title))))
    (assert-equal (getf page :story) (getf revised :story))
    (list :title (getf revised :title)
          :story (getf revised :story))))

(defexample journalmatic-checker-example
  "Report the checker findings for a page with a chronology issue."
  (let* ((page *journalmatic-example-page-with-chronology-error*)
         (results (journalmatic-example-check page)))
    (assert-equal '(:chronology) results)
    (list :title (getf page :title)
          :results results)))

(defexample journalmatic-rectify-chronology-example
  "Sort a page journal by date to remove chronology errors."
  (let* ((page *journalmatic-example-page-with-chronology-error*)
         (fixed (journalmatic-example-fix-chronology page))
         (dates (mapcar #'(lambda (action) (getf action :date))
                        (getf fixed :journal))))
    (assert-equal '(1000 1050 1100) dates)
    (list :title (getf fixed :title)
          :journal-dates dates
          :results (journalmatic-example-check fixed))))

(defexample journalmatic-gentle-compactor-example
  "Keep only the last edit in a short run of edits to the same item."
  (let* ((page *journalmatic-example-page*)
         (compacted (journalmatic-example-compact-journal page))
         (types-and-ids (mapcar #'(lambda (action)
                                    (list (getf action :type) (getf action :id)))
                                (getf compacted :journal))))
    (assert-equal '((:create nil) (:add "a1") (:edit "a1") (:add "b1"))
                  types-and-ids)
    (list :title (getf compacted :title)
          :journal-actions types-and-ids)))

(defun journalmatic-make-page-with-journal (title story-items &key start-date fork-site)
  "Reproducible page generator: deterministic ids/date ordering from inputs."
  (let* ((date (or start-date 1000))
         (story (copy-tree story-items))
         (journal (list (list :type :create
                              :item (list :title title :story '())
                              :date date)))
         (after nil))
    (dolist (item story-items)
      (incf date)
      (let ((action (list :type :add
                          :id (getf item :id)
                          :item (copy-tree item)
                          :date date)))
        (when after
          (setf action (append action (list :after after))))
        (push action journal)
        (setf after (getf item :id))))
    (when fork-site
      (incf date)
      (push (list :type :fork :site fork-site :date date) journal))
    (list :title title
          :story story
          :journal (nreverse journal))))

(defun journalmatic-append-add-like-wiki-client (page item &key after (now (journalmatic-current-epoch-millis)))
  "Append an add action using wiki-client style date generation."
  (let* ((page (copy-tree page))
         (journal (or (getf page :journal) '()))
         (story (or (getf page :story) '()))
         (date (journalmatic-next-date-like-wiki-client journal :now now))
         (action (list :type :add
                       :id (getf item :id)
                       :item (copy-tree item)
                       :date date)))
    (when after
      (setf action (append action (list :after after))))
    (setf (getf page :story)
          (journalmatic-example-add story after (copy-tree item)))
    (setf (getf page :journal)
          (append journal (list action)))
    page))

(defexample journalmatic-page-generation-workflow-example
  "Generate a reproducible page JSON shape and verify chronology/fork ordering."
  (let* ((story (list (list :type :paragraph :id "a1" :text "Alpha")
                      (list :type :markdown :id "b1" :text "### Beta")))
         (page (journalmatic-make-page-with-journal "Workflow Example"
                                                    story
                                                    :start-date 1000
                                                    :fork-site "localhost:3000"))
         (dates (mapcar #'(lambda (action) (getf action :date))
                        (getf page :journal)))
         (checked (journalmatic-example-check page)))
    (assert-equal '(1000 1001 1002 1003) dates)
    (assert-equal '() checked)
    (list :title (getf page :title)
          :journal-dates dates
          :results checked)))

(defexample journalmatic-page-generation-wiki-client-style-example
  "Append a story item using max(now, last-date+1) date semantics."
  (let* ((seed (journalmatic-make-page-with-journal
                "Workflow Example"
                (list (list :type :paragraph :id "a1" :text "Alpha"))
                :start-date 1000))
         (now 995)
         (updated (journalmatic-append-add-like-wiki-client
                   seed
                   (list :type :paragraph :id "b1" :text "Beta")
                   :after "a1"
                   :now now))
         (dates (mapcar #'(lambda (action) (getf action :date))
                        (getf updated :journal))))
    (assert-equal '(1000 1001 1002) dates)
    (list :now now
          :journal-dates dates
          :last-date (car (last dates)))))
