;;;; Journal gate helpers and examples
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

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
          :after "a1"
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
          :after "a1"
          :id "b1"
          :item (list :type :paragraph :id "b1" :text "Beta")
          :date 1050))))

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

(defun journalmatic-next-date-like-wiki-client
    (journal &key (now (journalmatic-current-epoch-millis)))
  (let ((last-date (loop for action in journal
                         for date = (getf action :date)
                         when date maximize date)))
    (if last-date
        (max now (1+ last-date))
        now)))

(defun journalmatic-normalize-dates-monotonic
    (journal &key (start-now (journalmatic-current-epoch-millis)))
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
  "Show exact commit-gate pass/fail results for one blocked and one passing page."
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
