;;;; Topicmap und Workspace
;;;;
;;;; Die Topic Map als Projektion für HyperDocs eigene Topicmap: Methoden oben in Leiterreihenfolge, darunter je Spalte
;;;; die Dateien, Werkzeuge, Begriffe und Achsen, die zuerst an dieser Stufe auftauchen, rechts fleet. Jedes Thema hält
;;;; das TMDM-Topic selbst; ein Klick im Workspace setzt den Point dorthin.
(in-package #:five-ways)

(defparameter +shown-types+ '("methode" "datei" "werkzeug" "begriff" "achse" "fleet-teil"))
(defparameter +from-roles+ '("vorher" "aufbauend" "methode-rolle" "ergaenzung" "fleet-rolle" "thema")
  "Of a binary statement, the player in one of these roles is drawn as the source of the edge.")

(defclass five-ways-map ()
  ((map :initarg :map :reader map-of)
   (focus :initarg :focus :initform nil :reader focus-of))
  (:documentation "The Topic Map, or the neighbourhood of one method, as a Topicmap projection."))

(defmethod v:text-representation ((m five-ways-map))
  (if (focus-of m) (format nil "Topicmap um ~A" (name-of (focus-of m))) "Topicmap: fünf Wege"))

(defun shown-p (topic map) (intersection (types-of topic map) +shown-types+ :test #'equal))
(defun topic-key (topic) (or (local-id topic) (si topic)))
(defun step-of (method) (parse-integer (or (occurrence method :stufe) "99")))

(defun home-step (topic map)
  "The lowest step of a method TOPIC is directly related to; NIL for none."
  (let ((steps (loop for (nil nil other) in (related topic map)
                     when (member "methode" (types-of other map) :test #'equal) collect (step-of other))))
    (and steps (reduce #'min steps))))

(defun selected-topics (graph)
  (let* ((map (map-of graph)) (focus (focus-of graph))
         (all (remove-if-not (lambda (tp) (shown-p tp map)) (tmdm:topic-map-topics map))))
    (if focus
        (let ((near (cons focus (mapcar #'third (related focus map)))))
          (remove-duplicates (append (methods map) (remove-if-not (lambda (tp) (member tp near)) all))))
        all)))

(defmethod tm:topicmap-projection-of ((graph five-ways-map))
  (let* ((map (map-of graph))
         (topics (selected-topics graph))
         (columns (make-hash-table)))
    (dolist (tp topics)
      (unless (member "methode" (types-of tp map) :test #'equal)
        (push tp (gethash (or (home-step tp map) 6) columns))))
    (flet ((topic-of (tp x y)
             (tm:make-topicmap-topic :id (topic-key tp) :label (name-of tp) :object tp
                                     :type (intern (string-upcase (first (intersection (types-of tp map) +shown-types+ :test #'equal))) :keyword)
                                     :view-properties (list :x x :y y :visible t :pinned t))))
      (let ((projected
              (append
               (loop for m in (methods map) collect (topic-of m (+ 40 (* 250 (1- (step-of m)))) 40))
               (loop for column being the hash-keys of columns using (hash-value members)
                     append (loop for tp in (sort (copy-list members) #'string< :key #'name-of)
                                  for row from 0
                                  collect (topic-of tp (+ 40 (* 250 (1- column))) (+ 150 (* 70 row)))))))
            (keys (mapcar #'topic-key topics))
            (edges nil) (n 0))
        (loop for (type . roles) in (statements map)
              when (= 2 (length roles))
                do (let* ((from (or (find-if (lambda (r) (member (car r) +from-roles+ :test #'equal)) roles) (first roles)))
                          (to (find from roles :test-not #'eq)))
                     (when (and (member (topic-key (cdr from)) keys :test #'equal)
                                (member (topic-key (cdr to)) keys :test #'equal))
                       (push (tm:make-topicmap-association :id (format nil "statement-~D" (incf n))
                                                           :type (intern (string-upcase type) :keyword)
                                                           :from (topic-key (cdr from)) :to (topic-key (cdr to)))
                             edges))))
        (tm:make-topicmap-projection
         :source graph :topics projected :associations (nreverse edges)
         :view-properties (list :width (+ 80 (* 250 6))
                                :height (+ 200 (* 70 (loop for m being the hash-values of columns maximize (length m))))
                                :point (topic-key (or (focus-of graph) (first (methods map))))))))))

(defun workspace (&optional focus)
  "A Topicmap Workspace over the whole Topic Map, or around the method FOCUS (a keyword such as :flakes)."
  (let* ((map (the-map))
         (graph (make-instance 'five-ways-map :map map :focus (and focus (topic focus map))))
         (projection (tm:topicmap-projection-of graph)))
    (tm:make-topicmap-workspace projection (getf (tm:topicmap-projection-view-properties-of projection) :point))))
