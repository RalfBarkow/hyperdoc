;;;; Steckbriefe und Verkostungstafel
;;;;
;;;; Zwei Ansichten, beide aus der Topic Map gerechnet, wenn sie gezeigt werden: der Steckbrief einer Methode (was sie
;;;; ist, für wen, was sie kann und kostet, ihr Steam-Beispiel, was sie einführt) und die Verkostungstafel der Quelle.
(in-package #:five-ways)

(defclass method-sheet () ((method :initarg :method :reader sheet-method)))
(defmethod v:text-representation ((s method-sheet)) (format nil "Steckbrief: ~A" (name-of (sheet-method s))))
(defun method-sheet (id) (make-instance 'method-sheet :method (or (topic id) (error "Keine Methode ~S in der Topic Map." id))))

(defun related-of-type (topic type)
  (loop for (statement nil other) in (related topic) when (equal statement type) collect other))

(defun topic-list (topics)
  (v:html (:ul (dolist (tp topics)
                 (v:html (:li (v:object-ref tp :display (name-of tp))
                              (let ((d (occurrence tp :beschreibung))) (when d (v:html ": " (v:esc d))))))))))

(v:defview method-sheet-view (sheet method-sheet)
  (v:html-view :title "Steckbrief" :priority -100
    (let* ((m (sheet-method sheet)))
      (v:html
       (:h2 (v:esc (format nil "Stufe ~A · ~A" (occurrence m :stufe) (name-of m))) " "
            (:small (v:esc (format nil "«~A»" (occurrence m :bild)))))
       (:p (v:esc (occurrence m :beschreibung)))
       (:p (:b "Für wen: ") (v:esc (occurrence m :fuer-wen)))
       (:p (:b "Eine Stufe höher, wenn: ") (v:esc (occurrence m :weiter-wenn)))
       (:h3 "Was es gut kann") (:ul (dolist (x (occurrences m :kann)) (v:html (:li (v:esc x)))))
       (:h3 "Was es kostet") (:ul (dolist (x (occurrences m :kostet)) (v:html (:li (v:esc x)))))
       (:h3 "Steam einschalten (Code der Quelle)")
       (:pre :style "white-space:pre-wrap" (v:esc (occurrence m :steam-beispiel)))
       (when (occurrences m :befehl)
         (v:html (:p (:b "Befehle: ") (dolist (c (occurrences m :befehl)) (v:html (:code (v:esc c)) " ")))))
       (:h3 "Führt ein") (topic-list (related-of-type m "fuehrt-ein"))
       (:h3 "Dateien") (topic-list (related-of-type m "verwendet-datei"))
       (let ((tools (related-of-type m "verwendet-werkzeug")))
         (when tools (v:html (:h3 "Werkzeuge") (topic-list tools))))
       (:p (:b "Ordnet nach: ") (v:esc (format nil "~{~A~^, ~}" (mapcar #'name-of (related-of-type m "ordnet-nach")))))
       (:p (v:object-ref (workspace (intern (string-upcase (local-id m)) :keyword)) :display "Topicmap um diese Stufe" :select "Topicmap")
           " · Quelle: "
           (let ((page (first (related-of-type m "beschrieben-auf"))))
             (if page
                 (let ((url (first (tmdm:topic-subject-locators page))))
                   (v:html (:a :href url :target "_blank" (v:esc url))))
                 (v:esc "nicht verzeichnet")))
           " · " (v:esc (or (occurrence m :geprueft) "")))))))

(defclass tasting-board () ())
(defmethod v:text-representation ((b tasting-board)) "Die Verkostungstafel")
(defun tasting-board () (make-instance 'tasting-board))

(defparameter +board-columns+
  '((:erster-sud "Guter erster Sud?") (:braucht-flakes "Braucht Flakes?")
    (:mehrere-maschinen "Mehrere Maschinen") (:lernkurve "Lernkurve")))

(v:defview tasting-board-view (board tasting-board)
  (v:html-view :title "Verkostungstafel" :priority -100
    (v:html
     (:p "Die fünf Methoden nebeneinander, Zelle für Zelle aus " (:code "ctm/brewhouse.ctm") ", so wie die Quelle sie schreibt.")
     (:table :class "inspector-table"
      (:tr (:th "Methode") (dolist (c +board-columns+) (v:html (:th (v:esc (second c))))))
      (dolist (m (methods))
        (v:html (:tr (:td (v:object-ref (make-instance 'method-sheet :method m) :display (name-of m) :select "Steckbrief"))
                     (dolist (c +board-columns+) (v:html (:td (v:esc (or (occurrence m (first c)) "—"))))))))))))
