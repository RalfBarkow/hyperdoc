;;;; Examples
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Example functions
;;

(see (page "Writing source code pages"))

;; An example is a function of zero arguments.

(defmacro defexample (name &body body)
  "Define an example function NAME with BODY. The syntax is the same as for
DEFUN, except that there is no lambda list because example functions take no
arguments."
  `(defun ,name () ,@body))

;;
;; Convenience functions for inserting assertions into examples
;;

(defun assert-test (fn x y &key (key #'identity))
  (assert (funcall fn (funcall key x) y))
  x)

(defun assert-equalp (x y &key (key #'identity))
  (assert-test #'equalp x y :key key))

(defun assert-equal (x y &key (key #'identity))
  (assert-test #'equal x y :key key))

(defun assert-eql (x y &key (key #'identity))
  (assert-test #'eql x y :key key))

(defun assert-within-tolerance (x y tolerance &key (key #'identity))
  (declare (type number y tolerance))
  (assert-test #'(lambda (x y)
                   (declare (type number x y))
                   (<= (abs (- x y)) tolerance))
               x y :key key))

;;
;; An example example function
;;

(defexample the-answer
  "The answer to the question of life, the universe, and everything."
  (-> 42
      (assert-equal 42)))

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
  "Report the checker findings for a page with chronology and revision issues."
  (let* ((page *journalmatic-example-page-with-chronology-error*)
         (results (journalmatic-example-check page)))
    (assert-equal '(:chronology :revision) results)
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
