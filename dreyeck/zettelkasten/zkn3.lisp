(in-package #:dreyeck.zettelkasten)

(defparameter *default-zkn3-work-directory*
  #P"/tmp/hyperdoc-zkn3-read/")

(defun zkn3-result-status (result)
  (getf result :status))

(defun zkn3-result-next-task (result)
  (getf result :next-task))

(defun file-size-bytes (pathname)
  (when (probe-file pathname)
    (with-open-file (in pathname
                        :direction :input
                        :element-type '(unsigned-byte 8))
      (file-length in))))

(defun read-file-string/utf-8 (pathname)
  (with-open-file (in pathname
                      :direction :input
                      :external-format :utf-8)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun read-file-prefix-string (pathname max-chars)
  (when (probe-file pathname)
    (with-open-file (in pathname
                        :direction :input
                        :external-format :utf-8)
      (let* ((size (min max-chars (file-length in)))
             (s (make-string size)))
        (read-sequence s in)
        s))))

(defun write-string-file (pathname text)
  (ensure-directories-exist pathname)
  (with-open-file (out pathname
                       :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create
                       :external-format :utf-8)
    (write-string text out))
  pathname)

(defun zkn3-container-p (pathname)
  (and (probe-file pathname)
       (not (uiop:directory-pathname-p pathname))
       (string-equal (pathname-type pathname) "zkn3")))

(defun zkn3-work-path (relative &key (work-directory *default-zkn3-work-directory*))
  (merge-pathnames relative
                   (uiop:ensure-directory-pathname work-directory)))

(defun run-program/result (program args)
  (handler-case
      (multiple-value-bind (out err code)
          (uiop:run-program
           (cons program args)
           :output :string
           :error-output :string
           :ignore-error-status t)
        (list :program program
              :args args
              :exit-code code
              :stdout out
              :stderr err))
    (error (e)
      (list :program program
            :args args
            :status :failed
            :condition (princ-to-string e)))))

(defun extract-zkn3-member
    (container member &key
       (output-path (zkn3-work-path member))
       (unzip-program "/usr/bin/unzip"))
  (ensure-directories-exist output-path)
  (let ((result
          (run-program/result
           unzip-program
           (list "-p" (namestring container) member))))
    (cond
      ((not (eql (getf result :exit-code) 0))
       (list :task (list '!extract-zkn3-member (namestring container) member)
             :status :failed
             :reason :zkn3-member-extraction-failed
             :container (namestring container)
             :member member
             :output-path (namestring output-path)
             :tool-result result
             :current-task (list '!extract-zkn3-member (namestring container) member)
             :next-task nil))
      (t
       (write-string-file output-path (getf result :stdout))
       (list :task (list '!extract-zkn3-member (namestring container) member)
             :status :passed
             :container (namestring container)
             :member member
             :output-path (namestring output-path)
             :bytes (file-size-bytes output-path)
             :done (list '!extract-zkn3-member (namestring container) member)
             :next-task (list '!parse-zkn-file-xml (namestring output-path)))))))

(defun whitespace-char-p (ch)
  (member ch '(#\Space #\Tab #\Newline #\Return #\Page) :test #'char=))

(defun xml-start-tag-name-at (text start)
  (when (and start (< start (length text)) (char= (char text start) #\<))
    (let ((i (1+ start)))
      (when (and (< i (length text))
                 (not (member (char text i) '(#\/ #\? #\!) :test #'char=)))
        (let ((j i))
          (loop while
                (and (< j (length text))
                     (not (or (whitespace-char-p (char text j))
                              (member (char text j) '(#\> #\/) :test #'char=))))
                do (incf j))
          (subseq text i j))))))

(defun first-xml-start-tags (text &key (limit 30))
  (let ((tags nil)
        (pos 0))
    (loop while (and (< pos (length text)) (< (length tags) limit))
          for next = (position #\< text :start pos)
          while next
          do (let ((name (xml-start-tag-name-at text next)))
               (when name (pushnew name tags :test #'string=))
               (setf pos (1+ next))))
    (nreverse tags)))

(defun count-substring (needle haystack)
  (let ((count 0)
        (start 0))
    (loop for pos = (search needle haystack :start2 start)
          while pos
          do (incf count)
             (setf start (+ pos (length needle)))
          finally (return count))))

(defun parse-zkn-file-xml (zkn-file &key (prefix-chars 65536))
  (cond
    ((null (probe-file zkn-file))
     (list :task (list '!parse-zkn-file-xml (namestring zkn-file))
           :status :failed
           :reason :zkn-file-missing
           :pathname (namestring zkn-file)
           :current-task (list '!parse-zkn-file-xml (namestring zkn-file))
           :next-task nil))
    (t
     (let* ((prefix (read-file-prefix-string zkn-file prefix-chars))
            (first-tags (first-xml-start-tags prefix :limit 30))
            (counts (list :zettel-open-tags-in-prefix (count-substring "<zettel" prefix)
                          :entry-open-tags-in-prefix (count-substring "<entry" prefix)
                          :zknid-attributes-in-prefix (count-substring "zknid=" prefix)
                          :id-attributes-in-prefix (count-substring "id=" prefix)))
            (xml-declaration
              (let ((end (search "?>" prefix)))
                (when (and end (search "<?xml" prefix :end2 (min (length prefix) 20)))
                  (subseq prefix 0 (+ end 2))))))
       (list :task (list '!parse-zkn-file-xml (namestring zkn-file))
             :status :passed
             :pathname (namestring zkn-file)
             :bytes (file-size-bytes zkn-file)
             :xml-declaration xml-declaration
             :first-start-tags first-tags
             :prefix-counts counts
             :done (list '!parse-zkn-file-xml (namestring zkn-file))
             :next-task (list '!resolve-zkn3-zettel-reference
                              (namestring zkn-file)
                              '?zettel-id))))))

(defun run-xmllint-xpath-string (xml-file xpath &key (xmllint-program "/usr/bin/xmllint"))
  (let ((result
          (run-program/result
           xmllint-program
           (list "--xpath" xpath (namestring xml-file)))))
    (list :xpath xpath
          :exit-code (getf result :exit-code)
          :stdout (getf result :stdout)
          :stderr (getf result :stderr)
          :tool-result result)))

(defun run-xmllint-xpath-to-file
    (xml-file xpath output-path &key (xmllint-program "/usr/bin/xmllint"))
  (ensure-directories-exist output-path)
  (let ((result
          (run-program/result
           xmllint-program
           (list "--xpath" xpath (namestring xml-file)))))
    (cond
      ((not (eql (getf result :exit-code) 0))
       (let ((stdout (or (getf result :stdout) "")))
         (list :xpath xpath
               :status :failed
               :exit-code (getf result :exit-code)
               :stderr (getf result :stderr)
               :stdout-prefix (subseq stdout 0 (min (length stdout) 500)))))
      (t
       (write-string-file output-path (getf result :stdout))
       (list :xpath xpath
             :status :passed
             :exit-code (getf result :exit-code)
             :output-path (namestring output-path)
             :bytes (file-size-bytes output-path)
             :preview (read-file-prefix-string output-path 1000))))))

(defun resolve-zkn3-zettel-reference
    (zkn-file zettel-ordinal &key
       (work-directory *default-zkn3-work-directory*)
       (by-id-path
        (zkn3-work-path
         (format nil "zettel-~A-by-id.xml" zettel-ordinal)
         :work-directory work-directory))
       (by-position-path
        (zkn3-work-path
         (format nil "zettel-~A-by-position.xml" zettel-ordinal)
         :work-directory work-directory)))
  (let* ((id (princ-to-string zettel-ordinal))
         (by-id-xpath (format nil "//zettel[@zknid='~A' or @id='~A']" id id))
         (by-position-xpath (format nil "(//zettel)[~A]" id))
         (count-all (run-xmllint-xpath-string zkn-file "count(//zettel)"))
         (count-by-id
          (run-xmllint-xpath-string
           zkn-file
           (format nil "count(//zettel[@zknid='~A' or @id='~A'])" id id)))
         (by-id (run-xmllint-xpath-to-file zkn-file by-id-xpath by-id-path))
         (by-position
          (run-xmllint-xpath-to-file zkn-file by-position-xpath by-position-path))
         (by-id-title
          (run-xmllint-xpath-string
           zkn-file
           (format nil "string((//zettel[@zknid='~A' or @id='~A']/title)[1])" id id)))
         (by-position-title
          (run-xmllint-xpath-string
           zkn-file
           (format nil "string(((//zettel)[~A]/title)[1])" id)))
         (by-position-zknid
          (run-xmllint-xpath-string
           zkn-file
           (format nil "string(((//zettel)[~A]/@zknid)[1])" id)))
         (chosen
          (cond
            ((eq (getf by-position :status) :passed) :ordinal-position)
            ((eq (getf by-id :status) :passed) :xml-identifier)
            (t nil)))
         (selected-entry-path
          (cond
            ((eq chosen :ordinal-position) (namestring by-position-path))
            ((eq chosen :xml-identifier) (namestring by-id-path))
            (t nil))))
    (list :task (list '!resolve-zkn3-zettel-reference (namestring zkn-file) id)
          :status (if chosen :passed :failed)
          :reference-ambiguity '(:identifier-vs-ordinal-position)
          :chosen-reference chosen
          :count-all-zettel-elements count-all
          :count-by-id count-by-id
          :candidate-by-id by-id
          :candidate-by-id-title by-id-title
          :candidate-by-position by-position
          :candidate-by-position-title by-position-title
          :candidate-by-position-zknid by-position-zknid
          :selected-entry-path selected-entry-path
          :done (list '!resolve-zkn3-zettel-reference (namestring zkn-file) id)
          :next-task
          (when chosen
            (list '!extract-zkn3-zettel-text selected-entry-path id)))))

(defun between-tags (text tag)
  (let* ((open (format nil "<~A>" tag))
         (close (format nil "</~A>" tag))
         (start (search open text))
         (end (and start (search close text :start2 (+ start (length open))))))
    (when (and start end)
      (subseq text (+ start (length open)) end))))

(defun attribute-value-from-open-tag (text attribute)
  (let* ((needle (format nil "~A=\"" attribute))
         (start (search needle text))
         (value-start (and start (+ start (length needle))))
         (value-end (and value-start (position #\" text :start value-start))))
    (when (and value-start value-end)
      (subseq text value-start value-end))))

(defun extract-zkn3-zettel-text (entry-file zettel-ordinal)
  (cond
    ((null (probe-file entry-file))
     (list :task (list '!extract-zkn3-zettel-text (namestring entry-file) zettel-ordinal)
           :status :failed
           :reason :selected-zettel-entry-missing
           :entry-file (namestring entry-file)
           :current-task (list '!extract-zkn3-zettel-text (namestring entry-file) zettel-ordinal)
           :next-task nil))
    (t
     (let* ((xml (read-file-string/utf-8 entry-file))
            (title (between-tags xml "title"))
            (content (between-tags xml "content"))
            (keywords (between-tags xml "keywords"))
            (manlinks (between-tags xml "manlinks"))
            (luhmann (between-tags xml "luhmann"))
            (zknid (attribute-value-from-open-tag xml "zknid"))
            (ok (and title content)))
       (list :task (list '!extract-zkn3-zettel-text (namestring entry-file) zettel-ordinal)
             :status (if ok :passed :failed)
             :reason (unless ok :title-or-content-missing)
             :selected-reference :ordinal-position
             :ordinal-id (princ-to-string zettel-ordinal)
             :zknid zknid
             :entry-file (namestring entry-file)
             :title title
             :content content
             :keywords keywords
             :manlinks manlinks
             :luhmann luhmann
             :done (list '!extract-zkn3-zettel-text (namestring entry-file) zettel-ordinal)
             :next-task (when ok (list '!read-zettel-text zettel-ordinal)))))))

(defun read-through-zkn3-zettel
    (zettel-ordinal zkn3-container &key
       (work-directory *default-zkn3-work-directory*))
  (let* ((zkn-file (zkn3-work-path "zknFile.xml" :work-directory work-directory))
         (extract
          (extract-zkn3-member
           zkn3-container
           "zknFile.xml"
           :output-path zkn-file))
         (parse
          (when (eq (getf extract :status) :passed)
            (parse-zkn-file-xml zkn-file)))
         (resolve
          (when (and parse (eq (getf parse :status) :passed))
            (resolve-zkn3-zettel-reference
             zkn-file
             zettel-ordinal
             :work-directory work-directory)))
         (entry-file
          (and resolve (getf resolve :selected-entry-path)))
         (text
          (when (and entry-file (probe-file entry-file))
            (extract-zkn3-zettel-text
             (pathname entry-file)
             zettel-ordinal))))
    (list :task (list '!read-through-zkn3-zettel
                      zettel-ordinal
                      (namestring zkn3-container))
          :status (if (and text (eq (getf text :status) :passed)) :passed :failed)
          :htn
          (list :initial-task-network
                (list (list 'read-through-zkn3-zettel
                            zettel-ordinal
                            (namestring zkn3-container)))
                :selected-plan
                (list
                 (list '!extract-zkn3-member
                       (namestring zkn3-container)
                       "zknFile.xml")
                 (list '!parse-zkn-file-xml
                       (namestring zkn-file))
                 (list '!resolve-zkn3-zettel-reference
                       (namestring zkn-file)
                       zettel-ordinal)
                 (list '!extract-zkn3-zettel-text
                       entry-file
                       zettel-ordinal)
                 (list '!read-zettel-text zettel-ordinal)))
          :steps (list extract parse resolve text)
          :zettel text
          :next-task
          (when (and text (eq (getf text :status) :passed))
            (list '!read-zettel-text zettel-ordinal)))))
