;;;; Ansichten
;;;;
;;;; PROJECT ist das Objekt hinter den Seiten. Seine Ansichten: der nächste Schritt (Empfehlung und Alternativen, je mit
;;;; Begründung und Rolle), die Vorhaben mit ihren Belegen, die Entscheidungen. Der native SHOP3-Plan und jede
;;;; Beobachtung lassen sich im Inspector öffnen.
(in-package #:zettelkasten-kiosk)

(defclass project () () (:documentation "Der Zettelkasten-Kiosk als Projekt; seine Daten stehen im Register."))
(defun project () (make-instance 'project))
(defmethod v:text-representation ((p project))
  (let ((r (recommended))) (format nil "Zettelkasten-Kiosk · nächster Schritt: ~A" (if r (offer-text r) "keiner"))))

(defun offer-text (o) (format nil "~A: ~A" (step-word (first o)) (target-title (second o))))

(defun status-word (i)
  (cond ((evidence i :merged) "gemergt")
        ((evidence i :pr-open) "PR offen")
        ((failed-p i) "nicht bestanden")
        ((stale-p i) "Prüfung veraltet")
        ((verified-p i) "geprüft")
        ((current-head i) "umgesetzt, ungeprüft")
        (t "nicht begonnen")))

(defun play-button ()
  (v:html (:p (v:eval-button "Play" (policy:reviewed-thunk "zettelkasten-kiosk/read-heads" (play-read-heads))
                             "Branch-Köpfe lesend von GitHub holen")
              " Branch-Köpfe lesen (nur GET auf die öffentliche GitHub-API; schreibt nichts)")))

(v:defview next-step-view (p project)
  (v:html-view :title "Nächster Schritt" :priority -100
    (let* ((plan (plan-next)) (offers (offers plan)) (facts (dreyeck/shop3:initial-facts-of plan)))
      (v:html
       (:p (v:object-ref plan :display "Nativer SHOP3-Plan") " · nur Vorschläge; entschieden, gemergt und aktiviert wird durch den Operator.")
       (when *message* (v:html (:p :role "status" (v:esc *message*))))
       (when *observations*
         (v:html (:p "Beobachtungen in diesem Image: "
                     (loop for o in *observations* for n from 0 below 5
                           do (v:html (v:object-ref o :display (time-string (observation-time o))) " ")))))
       (play-button)
       (if (null offers)
           (v:html (:p "Kein offener Schritt: alles gemergt."))
           (v:html
            (:h4 "Empfehlung")
            (:p (:b (v:esc (offer-text (first offers)))) " · " (v:esc (step-actor (first (first offers)))))
            (:ul (dolist (r (reasons (first (first offers)) (second (first offers)) facts)) (v:html (:li (v:esc r)))))
            (:h4 "Alle Alternativen, in der Reihenfolge der Vorrangregel")
            (:table :class "inspector-table"
             (:tr (:th "#") (:th "Schritt") (:th "Ziel") (:th "Wer") (:th "Begründung") (:th "Im Task"))
             (loop for o in offers for n from 1
                   do (v:html (:tr (:td (v:esc (princ-to-string n)))
                                   (:td (v:esc (step-word (first o))))
                                   (:td (v:esc (target-title (second o))))
                                   (:td (v:esc (step-actor (first o))))
                                   (:td (:ul (dolist (r (reasons (first o) (second o) facts)) (v:html (:li (v:esc r))))))
                                   (:td (:code (v:esc (or (step-topic-id (first o)) "—"))))))))))))))

(v:defview items-view (p project)
  (v:html-view :title "Vorhaben und Belege" :priority -90
    (v:html
     (:table :class "inspector-table"
      (:tr (:th "Vorhaben") (:th "Repo · Branch · Kopf") (:th "Stand") (:th "Belege"))
      (dolist (i (items))
        (v:html (:tr (:td (v:esc (prop i :title)))
                     (:td (:code (v:esc (format nil "~A · ~A · ~A" (prop i :repo) (or (prop i :branch) "—")
                                                (or (current-head i) "—")))))
                     (:td (v:esc (status-word i)))
                     (:td (if (evidence i)
                              (v:html (:ul (dolist (e (evidence i)) (v:html (:li (v:esc (evidence-text e)))))))
                              (v:esc "—"))))))))))

(v:defview decisions-view (p project)
  (v:html-view :title "Entscheidungen" :priority -80
    (v:html
     (dolist (d (decisions))
       (v:html (:h4 (v:esc (format nil "~A (~A)" (prop d :title) (if (eq (prop d :status) :open) "offen" "getroffen"))))
               (:p (v:esc (prop d :question)))
               (:table :class "inspector-table"
                (:tr (:th "Option") (:th "Folge"))
                (dolist (o (prop d :options))
                  (v:html (:tr (:td (v:esc (getf o :label))
                                    (when (eq (getf o :id) (prop d :recommended)) (v:html " " (:b "(empfohlen)")))
                                    (when (eq (getf o :id) (prop d :choice)) (v:html " " (:b "(gewählt)"))))
                               (:td (v:esc (getf o :consequence))))))))))))

(v:defview observation-view (o head-observation)
  (v:html-view :title "Beobachtung" :priority -100
    (v:html
     (:p (v:esc (format nil "Gelesen ~A, je Branch eine GET-Anfrage an die GitHub-API." (time-string (observation-time o)))))
     (:table :class "inspector-table"
      (:tr (:th "Branch") (:th "Im Register") (:th "Auf GitHub") (:th "Bewegt"))
      (dolist (e (observation-entries o))
        (v:html (:tr (:td (:code (v:esc (format nil "~A ~A" (getf e :repo) (getf e :branch)))))
                     (:td (:code (v:esc (or (getf e :recorded) "—"))))
                     (:td (v:esc (or (getf e :error) (short (getf e :observed)))))
                     (:td (v:esc (cond ((getf e :error) "?") ((getf e :moved) "ja") (t "nein"))))))))
     (:h4 "Vorschläge vorher")
     (:ul (dolist (x (offers-before o)) (v:html (:li (v:esc (offer-text x))))))
     (:h4 "Vorschläge nachher")
     (:ul (dolist (x (offers-after o)) (v:html (:li (v:esc (offer-text x)))))))))

;;; Der Projekt-Task als DITA-Topic

(defclass task-topic () () (:documentation "Der DITA-Task project-task.dita: welche Schritte es gibt und wer sie tut."))
(defun task-topic () (make-instance 'task-topic))
(defmethod v:text-representation ((o task-topic)) "DITA-Task «Den Zettelkasten-Kiosk fertigstellen»")
(v:defview task-view (o task-topic)
  (v:html-view :title "Task" :priority -100
    (v:str (dita:render-dita-topic (uiop:read-file-string (system-file "project-task.dita") :external-format :utf-8)))))
