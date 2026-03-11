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
                      (assert-equal '("alpha.example" "beta.example" "gamma.example")))))
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

;;
;; journalmatic translation helpers
;;

(defun journalmatic-example-order (story)
  (mapcar #'(lambda (item) (getf item :id)) story))

(defun journalmatic-example-add (story after item)
  (let ((index (if after
                   (1+ (or (position after (journalmatic-example-order story)
                                     :test #'equal)
                           -1))
                   0)))
    (append (subseq story 0 index)
            (list item)
            (subseq story index))))

(defun journalmatic-example-remove (story id)
  (remove id story :key #'(lambda (item) (getf item :id)) :test #'equal))

(defun journalmatic-example-apply-action (page action)
  (let* ((page (copy-tree page))
         (story (copy-list (getf page :story))))
    (setf (getf page :story) story)
    (case (getf action :type)
      (:create
       (let ((item (getf action :item)))
         (when (getf item :title)
           (setf (getf page :title) (getf item :title)))
         (setf (getf page :story) (copy-list (or (getf item :story) '())))))
      (:add
       (setf (getf page :story)
             (journalmatic-example-add (getf page :story)
                                       (getf action :after)
                                       (getf action :item))))
      (:edit
       (let* ((story (getf page :story))
              (id (getf action :id))
              (index (position id story
                               :key #'(lambda (item) (getf item :id))
                               :test #'equal)))
         (if index
             (setf (nth index story) (getf action :item))
             (setf (getf page :story)
                   (append story (list (getf action :item)))))))
      (:remove
       (setf (getf page :story)
             (journalmatic-example-remove (getf page :story)
                                          (getf action :id))))
      (:move
       (let* ((order (getf action :order))
              (id (getf action :id))
              (index (position id order :test #'equal))
              (after (and index (plusp index) (nth (1- index) order)))
              (story (getf page :story))
              (item (find id story :key #'(lambda (entry) (getf entry :id))
                         :test #'equal)))
         (when item
           (setf story (journalmatic-example-remove story id))
           (setf (getf page :story)
                 (journalmatic-example-add story after item)))))
      (otherwise nil))
    page))

(defun journalmatic-example-revision (journal &key title (rev-index (length journal)))
  (let ((page (list :title title :story '())))
    (dolist (action (subseq journal 0 rev-index) page)
      (setf page (journalmatic-example-apply-action page action)))))

(defun journalmatic-example-compare-actions (a b)
  (let ((date-a (getf a :date))
        (date-b (getf b :date)))
    (cond ((and date-a date-b (< date-a date-b)) t)
          ((and date-a date-b (> date-a date-b)) nil)
          (t nil))))

(defun journalmatic-example-sort-journal (journal)
  (sort (copy-list journal) #'journalmatic-example-compare-actions))

(defun journalmatic-example-check (page)
  (let ((results '())
        (story (or (getf page :story) '()))
        (journal (or (getf page :journal) '())))
    (when (and story
               (not (null story))
               (every #'(lambda (item)
                          (or (null item) (null (getf item :type))))
                      story))
      (push :nulls results))
    (when (or (null journal)
              (null (first journal))
              (not (eql (getf (first journal) :type) :create)))
      (push :creation results))
    (loop with previous-date = nil
          for action in journal
          for date = (getf action :date)
          do (when (and previous-date date (> previous-date date))
               (pushnew :chronology results))
             (setf previous-date date))
    (dolist (action journal)
      (case (getf action :type)
        (:create
         (unless (and (getf action :item) (getf action :date))
           (pushnew :malformed results)))
        ((:add :edit)
         (unless (and (getf action :item) (getf action :id) (getf action :date))
           (pushnew :malformed results)))
        (:move
         (unless (and (getf action :order) (getf action :id) (getf action :date))
           (pushnew :malformed results)))
        (:remove
         (unless (and (getf action :id) (getf action :date))
           (pushnew :malformed results)))
        (:fork
         (unless (getf action :date)
           (pushnew :malformed results)))
        (otherwise nil)))
    (let* ((revision-journal (if (member :chronology results)
                                 (journalmatic-example-sort-journal journal)
                                 journal))
           (revised (journalmatic-example-revision revision-journal
                                                   :title (getf page :title))))
      (unless (equal (getf page :story) (getf revised :story))
        (pushnew :revision results)))
    (nreverse results)))

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

(defparameter *journalmatic-example-page*
  (list
   :title "Example Journal Page"
   :story (list (list :type :paragraph :id "a1" :text "Alpha revised")
                (list :type :paragraph :id "b1" :text "Beta"))
   :journal
   (list
    (list :type :create
          :item (list :title "Example Journal Page" :story '())
          :date 1000)
    (list :type :add
          :id "a1"
          :item (list :type :paragraph :id "a1" :text "Alpha")
          :date 1010)
    (list :type :edit
          :id "a1"
          :item (list :type :paragraph :id "a1" :text "Alpha draft")
          :date 1040)
    (list :type :edit
          :id "a1"
          :item (list :type :paragraph :id "a1" :text "Alpha revised")
          :date 1050)
    (list :type :add
          :id "b1"
          :item (list :type :paragraph :id "b1" :text "Beta")
          :date 1060))))

(defparameter *journalmatic-example-page-with-chronology-error*
  (list
   :title "Chronology Example"
   :story (list (list :type :paragraph :id "a1" :text "Alpha")
                (list :type :paragraph :id "b1" :text "Beta"))
   :journal
   (list
    (list :type :create
          :item (list :title "Chronology Example" :story '())
          :date 1000)
    (list :type :add
          :id "a1"
          :item (list :type :paragraph :id "a1" :text "Alpha")
          :date 1100)
    (list :type :add
          :id "b1"
          :item (list :type :paragraph :id "b1" :text "Beta")
          :date 1050))))

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

(defparameter +journalmatic-commit-gate-findings+
  '(:creation :chronology :revision :malformed))

(defun journalmatic-commit-gate-findings (page)
  (let ((findings (journalmatic-example-check page)))
    (remove-if-not #'(lambda (finding)
                       (member finding +journalmatic-commit-gate-findings+))
                   findings)))

(defun journalmatic-commit-gate-pass-p (page)
  (null (journalmatic-commit-gate-findings page)))

(defun journalmatic-current-epoch-millis ()
  (* 1000 (- (get-universal-time) 2208988800)))

(defun journalmatic-next-date-like-wiki-client (journal &key (now (journalmatic-current-epoch-millis)))
  (let ((last-date (loop for action in journal
                         for date = (getf action :date)
                         when date maximize date)))
    (if last-date
        (max now (1+ last-date))
        now)))

(defun journalmatic-normalize-dates-monotonic (journal &key (start-now (journalmatic-current-epoch-millis)))
  "Normalize action dates in existing order, forcing monotonic progression."
  (let ((date (1- start-now))
        (normalized '()))
    (dolist (action journal (nreverse normalized))
      (let ((copy (copy-tree action))
            (existing (getf action :date)))
        (setf date (max (1+ date) (or existing 0)))
        (setf (getf copy :date) date)
        (push copy normalized)))))

(defexample journalmatic-commit-gate-script-example
  "Gate FedWiki page commits on creation/chronology/revision/malformed findings."
  (let* ((bad-page *journalmatic-example-page-with-chronology-error*)
         (good-page *journalmatic-example-page*)
         (bad-findings (journalmatic-commit-gate-findings bad-page))
         (good-findings (journalmatic-commit-gate-findings good-page)))
    (assert-equal '(:chronology) bad-findings)
    (assert-equal '() good-findings)
    (list :gate-findings +journalmatic-commit-gate-findings+
          :bad-page (list :title (getf bad-page :title)
                          :findings bad-findings
                          :pass? (journalmatic-commit-gate-pass-p bad-page))
          :good-page (list :title (getf good-page :title)
                           :findings good-findings
                           :pass? (journalmatic-commit-gate-pass-p good-page)))))

(defexample journalmatic-date-origin-example
  "Show Date.now-style millis and monotonic next-date behavior."
  (let* ((journal '((:type :create :date 1000)
                    (:type :add :id "a1" :date 1001)))
         (now 950)
         (next-date (journalmatic-next-date-like-wiki-client journal :now now)))
    (assert-equal 1002 next-date)
    (list :date-origin "epoch-millis"
          :now now
          :last-date 1001
          :next-date next-date)))

(defexample journalmatic-monotonic-normalization-example
  "Normalize out-of-order dates while preserving action order."
  (let* ((journal '((:type :create :date 1000)
                    (:type :add :id "a1" :date 1100)
                    (:type :fork :site "localhost:3000" :date 1050)))
         (normalized (journalmatic-normalize-dates-monotonic journal :start-now 1000))
         (dates (mapcar #'(lambda (action) (getf action :date)) normalized)))
    (assert-equal '(1000 1100 1101) dates)
    (list :before '(1000 1100 1050)
          :after dates)))

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
