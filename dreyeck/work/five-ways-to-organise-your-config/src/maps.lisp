;;;; Die Topic Maps lesen
;;;;
;;;; Jede Datei in ctm/ ist für sich lesbares CTM. Die ganze Topic Map ist ihre Verkettung; die Karte einer Stufe ist
;;;; Schema, Übersicht und die Datei der Stufe. Gelesen wird beim ersten Gebrauch und wieder, wenn sich eine Datei
;;;; geändert hat. Geschrieben wird nichts.
(in-package #:five-ways)

(defparameter +schema+ "tag:dreyeck.ch,2026:hyperdoc/five-ways/schema/")
(defparameter +topic+ "tag:dreyeck.ch,2026:hyperdoc/five-ways/topic/")
(defparameter +type-instance+ "http://psi.topicmaps.org/iso13250/model/type-instance")
(defparameter +type-role+ "http://psi.topicmaps.org/iso13250/model/type")
(defparameter +instance-role+ "http://psi.topicmaps.org/iso13250/model/instance")
(defparameter +files+ '("schema" "brewhouse" "vanilla" "flakes" "flake-parts" "dendritic" "den" "fleet"))

(defun ctm-pathname (name)
  (asdf:system-relative-pathname "five-ways-to-organise-your-config" (format nil "ctm/~A.ctm" name)))
(defun ctm-files () (mapcar #'ctm-pathname +files+))

(defun read-ctm (&rest names)
  "One TMDM Topic Map from the CTM files NAMES, read in this order."
  (ctm:deserialize-string
   (format nil "~{~A~%~}" (mapcar (lambda (n) (uiop:read-file-string (ctm-pathname n) :external-format :utf-8)) names))
   :document-iri (format nil "tag:dreyeck.ch,2026:hyperdoc/five-ways/document/~{~A~^+~}" names)))

(defvar *map* nil "The whole Topic Map, as last read.")
(defvar *map-stamp* nil)

(defun the-map ()
  "The whole Topic Map: all CTM files. Read again when a file changed."
  (let ((stamp (mapcar #'file-write-date (ctm-files))))
    (unless (and *map* (equal stamp *map-stamp*))
      (setf *map* (apply #'read-ctm +files+) *map-stamp* stamp))
    *map*))

(defun page-map (name)
  "The Topic Map of one page: schema, overview and the file NAME (a string such as \"flakes\")."
  (read-ctm "schema" "brewhouse" name))

;;; Reading topics

(defun si (topic) (first (tmdm:topic-subject-identifiers topic)))
(defun local-id (topic &optional (base +topic+))
  (let ((si (si topic))) (and si (uiop:string-prefix-p base si) (subseq si (length base)))))

(defun topic (id &optional (map (the-map)))
  "The topic with the local ID (a keyword or string such as :flakes) in MAP."
  (let ((iri (concatenate 'string +topic+ (string-downcase (string id)))))
    (find-if (lambda (tp) (member iri (tmdm:topic-subject-identifiers tp) :test #'string=)) (tmdm:topic-map-topics map))))

(defun name-of (topic)
  (let ((name (first (tmdm:topic-names topic)))) (if name (tmdm:topic-name-value name) (or (si topic) "(ohne Namen)"))))

(defun occurrences (topic type)
  "The values of TOPIC's occurrences of the schema type TYPE (a keyword such as :kann), in file order."
  (let ((iri (concatenate 'string +schema+ (string-downcase (string type)))))
    (loop for o in (tmdm:topic-occurrences topic)
          when (equal iri (si (tmdm:occurrence-type o))) collect (tmdm:occurrence-value o))))

(defun occurrence (topic type) (first (occurrences topic type)))

(defun roles (association)
  (mapcar (lambda (r) (cons (local-id (tmdm:association-role-type r) +schema+) (tmdm:association-role-player r)))
          (tmdm:association-roles association)))

(defun types-of (topic &optional (map (the-map)))
  "The local schema ids of TOPIC's types (from its isa statements)."
  (loop for a in (tmdm:topic-map-associations map)
        when (and (equal +type-instance+ (si (tmdm:association-type a)))
                  (some (lambda (r) (and (equal +instance-role+ (si (tmdm:association-role-type r)))
                                         (eq (tmdm:canonical-topic (tmdm:association-role-player r)) (tmdm:canonical-topic topic))))
                        (tmdm:association-roles a)))
          append (loop for r in (tmdm:association-roles a)
                       when (equal +type-role+ (si (tmdm:association-role-type r)))
                         collect (local-id (tmdm:association-role-player r) +schema+))))

(defun instances-of (type &optional (map (the-map)))
  (let ((type (string-downcase (string type))))
    (remove-if-not (lambda (tp) (member type (types-of tp map) :test #'equal)) (tmdm:topic-map-topics map))))

(defun statements (&optional (map (the-map)))
  "Every association other than type-instance, as (type-id . ((role-id . player) ...))."
  (loop for a in (tmdm:topic-map-associations map)
        unless (equal +type-instance+ (si (tmdm:association-type a)))
          collect (cons (local-id (tmdm:association-type a) +schema+) (roles a))))

(defun related (topic &optional (map (the-map)))
  "Every statement TOPIC takes part in, as (type-id role-id other-topic other-role-id)."
  (loop for (type . roles) in (statements map)
        for mine = (find-if (lambda (r) (eq (tmdm:canonical-topic (cdr r)) (tmdm:canonical-topic topic))) roles)
        when mine
          append (loop for r in roles unless (eq r mine) collect (list type (car mine) (cdr r) (car r)))))

(defun methods (&optional (map (the-map)))
  "The five methods in ladder order."
  (sort (copy-list (instances-of :methode map)) #'< :key (lambda (m) (parse-integer (or (occurrence m :stufe) "99")))))
