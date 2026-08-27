
(IN-PACKAGE :DREYECK/FEDWIKI-JOURNAL/TESTS)
(defun run-fedwiki-journal-copy-comparison-test ()
  (labels ((entry (type date)
             (let ((data (make-hash-table :test #'equal)))
               (setf (gethash "type" data) type
                     (gethash "date" data) date)
               (hyperbook/fedwiki::make-journal-entry data)))
           (page (wiki id &rest entries)
             (let ((page (hyperbook/fedwiki::make-fedwiki-page wiki id id)))
               (setf (slot-value page 'hyperbook/fedwiki::journal)
                       (coerce entries 'vector))
               page)))
    (let* ((wiki
            (make-instance 'hyperbook/fedwiki::fedwiki :id
                           "journal-comparison-test"))
           (left (page wiki "left" (entry "create" 1781148995000)))
           (same (page wiki "same" (entry "create" 1781148995000)))
           (later (page wiki "later" (entry "create" 1781148996000)))
           (extra
            (page wiki "extra" (entry "create" 1781148995000)
             (entry "fork" 1781148997000)))
           (date-mismatch
            (first
             (dreyeck/fedwiki-journal:journal-date-mismatches left later)))
           (extra-mismatch
            (first
             (dreyeck/fedwiki-journal:journal-date-mismatches left extra)))
           (comparison
            (dreyeck/fedwiki-journal:make-fedwiki-journal-copy-comparison
             "left" left "extra" extra)))
      (and (null (dreyeck/fedwiki-journal:journal-date-mismatches left same))
           (= 1 (getf date-mismatch :delta-seconds))
           (= 1 (getf extra-mismatch :index))
           (null (getf (getf extra-mismatch :left) :type))
           (eq :fork (getf (getf extra-mismatch :right) :type))
           (null (getf extra-mismatch :delta-seconds))
           (string= "left"
                    (dreyeck/fedwiki-journal:journal-comparison-left-name-of
                     comparison))
           (eq left
               (dreyeck/fedwiki-journal:journal-comparison-left-page-of
                comparison))
           (string= "extra"
                    (dreyeck/fedwiki-journal:journal-comparison-right-name-of
                     comparison))
           (eq extra
               (dreyeck/fedwiki-journal:journal-comparison-right-page-of
                comparison))
           (equal (dreyeck/fedwiki-journal:journal-date-mismatches left extra)
                  (dreyeck/fedwiki-journal:journal-comparison-mismatches-of
                   comparison))))))

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
   (and (run-fedwiki-journal-copy-comparison-test)
        (run-fedwiki-journal-repair-test))))