;;;; Comparing the change-workflow Topic Maps with a Zettelkasten (Daniel Lüdecke's Zettelkasten 3, .zkn3).
;;;;
;;;; Read only. The .zkn3 file is a ZIP; its keywordFile.xml holds one <entry> per keyword, and keyword N is the Nth
;;;; entry (deleted keywords stay as empty entries). zknFile.xml holds one <zettel> per note, note N being the Nth;
;;;; its <keywords> element lists keyword numbers separated by commas. Source: RalfBarkow/zettelkasten 030df37,
;;;; SaveFileTask.java (compact XMLOutputter, the ZIP entry names) and Daten.java (retrieveElement: position - 1 in the
;;;; root's content; keywords split on ",").
(in-package #:change-workflow)

;;; Reading the Zettelkasten

(defstruct zkn-note number title keywords)   ; KEYWORDS: the keyword strings

(defclass zettelkasten ()
  ((path :initarg :path :reader zkn-path)
   (keywords :initarg :keywords :reader zkn-keywords :documentation "Vector; element N-1 is keyword N, \"\" if deleted.")
   (notes :initarg :notes :reader zkn-notes)
   (read-at :initarg :read-at :reader zkn-read-at)))

(defmethod v:text-representation ((z zettelkasten))
  (format nil "Zettelkasten ~A (~D Zettel, ~D Schlagwörter)" (file-namestring (zkn-path z)) (length (zkn-notes z))
          (count "" (zkn-keywords z) :test-not #'equal)))

(defun zip-entry-text (zipfile name)
  (let ((entry (zip:get-zipfile-entry name zipfile)))
    (unless entry (error "~A fehlt in der Zettelkasten-Datei." name))
    (sb-ext:octets-to-string (zip:zipfile-entry-contents entry) :external-format :utf-8)))

(defun root-children (xml)
  "The element children of the document element of XML, in order."
  ;; XML, not HTML: in HTML mode plump would treat <link> (an attachment of a note) as an empty element.
  (let* ((root (let ((plump:*tag-dispatchers* plump:*xml-tags*))
                 (find-if (lambda (n) (typep n 'plump:element)) (plump:children (plump:parse xml))))))
    (unless root (error "Kein Wurzelelement."))
    (coerce (remove-if-not (lambda (n) (typep n 'plump:element)) (plump:children root)) 'list)))

(defun child-text (element tag)
  (let ((child (find tag (plump:children element) :key (lambda (n) (and (typep n 'plump:element) (plump:tag-name n)))
                                                    :test #'equal)))
    (if child (plump:text child) "")))

(defun read-zettelkasten (path)
  "Read the keywords and the notes (number, title, keywords) of the .zkn3 file PATH. Opens it for reading only."
  (let ((path (or (probe-file path) (error "Datei ~A fehlt." path))))
    (zip:with-zipfile (z path)
      (let* ((keywords (map 'vector #'plump:text (root-children (zip-entry-text z "keywordFile.xml"))))
             (notes (loop for element in (root-children (zip-entry-text z "zknFile.xml"))
                          for number from 1
                          collect (make-zkn-note
                                   :number number :title (child-text element "title")
                                   :keywords (loop for part in (uiop:split-string (child-text element "keywords") :separator ",")
                                                   for n = (ignore-errors (parse-integer part))
                                                   when (and n (<= 1 n (length keywords)) (plusp (length (aref keywords (1- n)))))
                                                     collect (aref keywords (1- n)))))))
        (make-instance 'zettelkasten :path path :keywords keywords :notes notes :read-at (get-universal-time))))))

;;; Reading the Topic Maps

(defparameter +topic-files+ '("schema" "register" "play-button" "provenance" "codepath-transfer" "side-chat"))
(defparameter +topic-base+ "tag:dreyeck.ch,2026:hyperdoc/change-workflow/topic/")
(defparameter +keyword-type+ "tag:dreyeck.ch,2026:hyperdoc/change-workflow/schema/keyword")

(defun topic-map ()
  (topic-maps.ctm:deserialize-string
   (format nil "~{~A~%~}" (mapcar (lambda (n) (uiop:read-file-string (system-file (format nil "topics/~A.ctm" n))
                                                                     :external-format :utf-8))
                                  +topic-files+))
   :document-iri "tag:dreyeck.ch,2026:hyperdoc/change-workflow/document/topics"))

(defun first-si (x) (first (topic-maps.tmdm:topic-subject-identifiers x)))

(defun topic-keywords (&optional (map (topic-map)))
  "(name keyword ...) for every topic of the change-workflow topic maps that has keyword candidates."
  (loop for tp in (topic-maps.tmdm:topic-map-topics map)
        for si = (first-si tp)
        for kws = (loop for o in (topic-maps.tmdm:topic-occurrences tp)
                        when (equal +keyword-type+ (first-si (topic-maps.tmdm:occurrence-type o)))
                          collect (topic-maps.tmdm:occurrence-value o))
        when (and si (uiop:string-prefix-p +topic-base+ si) kws)
          collect (cons (topic-maps.tmdm:topic-name-value (first (topic-maps.tmdm:topic-names tp))) kws)))

;;; Comparing

(defun normalize (s) (string-downcase (string-trim '(#\Space #\Tab #\Newline) s)))

(defclass zettelkasten-alignment ()
  ((zettelkasten :initarg :zettelkasten :reader alignment-zettelkasten)
   (keywords :initarg :keywords :reader alignment-keywords
             :documentation "Per keyword candidate: (:keyword k :status :exact|:case|:absent :zkn-form f :notes (zkn-note ...) :topics (name ...)).")
   (topics :initarg :topics :reader alignment-topics
           :documentation "Per topic: (:topic name :by-keyword (zkn-note ...) :by-title (zkn-note ...)).")))

(defmethod v:text-representation ((a zettelkasten-alignment))
  (let ((ks (alignment-keywords a)))
    (format nil "Abgleich mit ~A: ~D von ~D Schlagwörtern vorhanden" (file-namestring (zkn-path (alignment-zettelkasten a)))
            (count :absent ks :key (lambda (k) (getf k :status)) :test-not #'eq) (length ks))))

(defun align (zettelkasten &optional (topics (topic-keywords)))
  "Compare the keyword candidates and topic names of TOPICS with the keywords and titles of ZETTELKASTEN."
  (let* ((zkn-keywords (remove "" (coerce (zkn-keywords zettelkasten) 'list) :test #'equal))
         (titles (mapcar (lambda (note) (cons note (normalize (zkn-note-title note)))) (zkn-notes zettelkasten)))
         (by-keyword (make-hash-table :test #'equal))
         (candidates (make-hash-table :test #'equal)))
    (dolist (note (zkn-notes zettelkasten))
      (dolist (k (zkn-note-keywords note)) (push note (gethash k by-keyword))))
    (loop for (name . kws) in topics
          do (dolist (k kws) (push name (gethash k candidates))))
    (make-instance
     'zettelkasten-alignment
     :zettelkasten zettelkasten
     :keywords (loop for k in (sort (loop for k being the hash-keys of candidates collect k) #'string-lessp)
                     for exact = (find k zkn-keywords :test #'string=)
                     for loose = (or exact (find (normalize k) zkn-keywords :key #'normalize :test #'string=))
                     collect (list :keyword k :status (cond (exact :exact) (loose :case) (t :absent)) :zkn-form loose
                                   :notes (and loose (reverse (gethash loose by-keyword)))
                                   :topics (sort (remove-duplicates (gethash k candidates) :test #'equal) #'string-lessp)))
     :topics (loop for (name . kws) in topics
                   collect (list :topic name
                                 :by-keyword (remove-duplicates
                                              (loop for k in kws
                                                    for zk = (find (normalize k) zkn-keywords :key #'normalize :test #'string=)
                                                    when zk append (gethash zk by-keyword)))
                                 :by-title (let ((needle (normalize name)))
                                             (loop for (note . title) in titles
                                                   when (search needle title) collect note)))))))

;;; Views

(defun note-label (note) (format nil "~D ~A" (zkn-note-number note) (zkn-note-title note)))

(defparameter +shown-notes+ 8)

(defun note-list (notes)
  (format nil "~{~A~^; ~}~@[ … (~D insgesamt)~]"
          (mapcar #'note-label (subseq notes 0 (min +shown-notes+ (length notes))))
          (and (> (length notes) +shown-notes+) (length notes))))

(defun status-label (status)
  (ecase status (:exact "vorhanden") (:case "vorhanden, andere Schreibung") (:absent "neu")))

(v:defview alignment-keywords-view (a zettelkasten-alignment)
  (v:html-view :title "Schlagwörter" :priority -100
    (v:html
     (:p (v:esc (format nil "Die Schlagwort-Kandidaten der Topic Maps (topics/*.ctm) gegen ~A, gelesen ~A."
                        (namestring (zkn-path (alignment-zettelkasten a))) (time-string (zkn-read-at (alignment-zettelkasten a))))))
     (:table :class "inspector-table"
      (:tr (:th "Kandidat") (:th "Im Zettelkasten") (:th "Zettel mit diesem Schlagwort") (:th "Topics"))
      (dolist (k (alignment-keywords a))
        (v:html (:tr (:td (v:esc (getf k :keyword)))
                     (:td (v:esc (format nil "~A~@[ («~A»)~]" (status-label (getf k :status))
                                         (and (eq :case (getf k :status)) (getf k :zkn-form)))))
                     (:td (v:esc (note-list (getf k :notes))))
                     (:td (v:esc (format nil "~{~A~^; ~}" (getf k :topics)))))))))))

(v:defview alignment-topics-view (a zettelkasten-alignment)
  (v:html-view :title "Topics und Zettel" :priority -90
    (v:html
     (:p "Je Topic die Zettel, die eines seiner Schlagwörter tragen, und die Zettel, deren Titel den Topic-Namen enthält. Kandidaten zum Lesen, keine Zuordnung.")
     (:table :class "inspector-table"
      (:tr (:th "Topic") (:th "über Schlagwort") (:th "über Titel"))
      (dolist (row (alignment-topics a))
        (v:html (:tr (:td (v:esc (getf row :topic)))
                     (:td (v:esc (note-list (getf row :by-keyword))))
                     (:td (v:esc (note-list (getf row :by-title)))))))))))

;;; The page in the workflow book, with its Play

(defvar *alignments* nil "Every alignment made in this image, newest first.")

(defun configured-zettelkasten ()
  "The .zkn3 file named by HYPERDOC_ZETTELKASTEN_FILE, or NIL."
  (let ((value (uiop:getenv "HYPERDOC_ZETTELKASTEN_FILE")))
    (and value (plusp (length value)) value)))

(defun play-align (&optional (path (configured-zettelkasten)))
  (unless path (error "HYPERDOC_ZETTELKASTEN_FILE ist nicht gesetzt; ohne Datei gibt es keinen Abgleich."))
  (let ((a (align (read-zettelkasten path))))
    (push a *alignments*)
    a))

(policy:register-reviewed-control "change-workflow/zettelkasten-align"
  :effect "Reads the .zkn3 file named by HYPERDOC_ZETTELKASTEN_FILE and the change-workflow topic maps, and returns their comparison."
  :audit "PLAY-ALIGN opens the file for reading only (zip:with-zipfile) and writes nothing; without the variable it refuses.")

(defclass zettelkasten-page (hb:page) ())
(defmethod hb:title-of ((page zettelkasten-page)) "Zettelkasten-Abgleich")
(pushnew (cons "zettelkasten" 'zettelkasten-page) *pages* :test #'equal :key #'car)

(v:defview zettelkasten-page-view (page zettelkasten-page)
  (v:html-view :title "Zettelkasten-Abgleich" :priority -100
    (v:html
     (v:str (dita:render-dita-topic (uiop:read-file-string (system-file "zettelkasten.dita") :external-format :utf-8)))
     (:p (v:esc (format nil "Datei: ~A" (or (configured-zettelkasten) "HYPERDOC_ZETTELKASTEN_FILE nicht gesetzt"))))
     (:p (v:eval-button "Play" (policy:reviewed-thunk "change-workflow/zettelkasten-align" (play-align))
                        "Zettelkasten lesen und mit den Topic Maps abgleichen")
         " Abgleichen (liest die Datei, schreibt nichts)")
     (when *alignments*
       (v:html (:p "Abgleiche in diesem Image: "
                   (loop for a in *alignments* for i from 0 below 5
                         do (v:html (v:object-ref a :display (time-string (zkn-read-at (alignment-zettelkasten a)))) " "))))))))
