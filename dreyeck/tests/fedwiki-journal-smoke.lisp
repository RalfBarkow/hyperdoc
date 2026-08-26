
(IN-PACKAGE :DREYECK/FEDWIKI-JOURNAL/TESTS)
(defun run-fedwiki-journal-repair-test ()
  (labels ((make-entry-data (type date)
             (let ((data (make-hash-table :test #'equal)))
               (setf (gethash "type" data) type
                     (gethash "date" data) date)
               data))
           (copy-entry-data (entry)
             (let ((copy (make-hash-table :test #'equal)))
               (maphash (lambda (key value) (setf (gethash key copy) value))
                        entry)
               copy)))
    (let* ((wiki (make-instance 'hyperbook/fedwiki::fedwiki :id "repair-test"))
           (page
            (hyperbook/fedwiki::make-fedwiki-page wiki "repair-test"
                                                  "Repair Test"))
           (raw-good-data (make-entry-data "create" 1781148995000))
           (raw-bad-data (make-entry-data "add" 3990137795000))
           (page-json (make-hash-table :test #'equal)))
      (setf (gethash "journal" page-json) (vector raw-good-data raw-bad-data))
      (setf (slot-value page 'hyperbook/fedwiki::journal)
              (vector
               (hyperbook/fedwiki::make-journal-entry
                (copy-entry-data raw-good-data))
               (hyperbook/fedwiki::make-journal-entry
                (copy-entry-data raw-bad-data))))
      (let* ((candidate
              (dreyeck/fedwiki-journal::repair-journal-date-domain page
                                                                   page-json
                                                                   :now
                                                                   3996668473))
             (repairs (dreyeck/fedwiki-journal::repairs-of candidate))
             (repaired-json
              (dreyeck/fedwiki-journal::repaired-page-json-of candidate))
             (repaired-journal (gethash "journal" repaired-json))
             (repaired-page
              (hyperbook/fedwiki::make-fedwiki-page wiki "repaired"
                                                    "Repaired")))
        (setf (slot-value repaired-page 'hyperbook/fedwiki::journal)
                (map 'vector
                     (lambda (raw-entry)
                       (hyperbook/fedwiki::make-journal-entry
                        (copy-entry-data raw-entry)))
                     repaired-journal))
        (let ((repair (first repairs)))
          (and (= 1 (length repairs)) (= 1 (getf repair :entry-index))
               (string= "add" (getf repair :entry-type))
               (= 3990137795000 (getf repair :from))
               (= 1781148995000 (getf repair :to))
               (= 3990137795000 (gethash "date" raw-bad-data))
               (= 1781148995000 (gethash "date" (elt repaired-journal 1)))
               (null (journal-check repaired-page :now 3996668473))))))))

(defun run-fedwiki-journal-tests ()
  (and
   (let* ((wiki (make-instance 'hyperbook/fedwiki::fedwiki :id "test"))
          (page (hyperbook/fedwiki::make-fedwiki-page wiki "test" "Test"))
          (good-data (make-hash-table :test #'equal))
          (bad-data (make-hash-table :test #'equal)))
     (setf (gethash "type" good-data) "create"
           (gethash "date" good-data) 1781148995000
           (gethash "type" bad-data) "add"
           (gethash "date" bad-data) 3990137795000)
     (let ((good (hyperbook/fedwiki::make-journal-entry good-data))
           (bad (hyperbook/fedwiki::make-journal-entry bad-data)))
       (setf (slot-value page 'hyperbook/fedwiki::journal) (vector good bad))
       (let ((findings (journal-check page :now 3996668473)))
         (and (= 1 (length findings))
              (eq bad (fedwiki-journal-finding-entry-of (first findings)))
              (eq :date-domain
                  (fedwiki-journal-finding-kind-of (first findings)))))))
   (run-fedwiki-journal-repair-test)))