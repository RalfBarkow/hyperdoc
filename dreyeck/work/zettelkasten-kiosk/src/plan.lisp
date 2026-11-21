;;;; Der nächste Schritt aus SHOP3
;;;;
;;;; Eine Methode je Art von Schritt. Ihre Reihenfolge ist die Vorrangregel: zuerst Entscheidungen, die Vorhaben
;;;; blockieren; dann Defekte, veraltete und fehlende Prüfungen; dann das Ansehen durch den Operator; dann Pull Request
;;;; und Merge; dann Neues. Ein gemergtes Vorhaben braucht keinen Schritt mehr. SHOP3 liefert jede anwendbare Methode als eigene Alternative; die erste ist die Empfehlung.
(in-package #:zettelkasten-kiosk)

(shop3:defdomain (zettelkasten-kiosk :noset t)
  ((:operator (!offer ?step ?x) () () ((offered ?step ?x)))
   (:method (next-step) decide ((blocks ?d ?i)) ((!offer decide ?d)))
   (:method (next-step) fix ((failed ?i) (not (merged ?i)) (not (blocked ?i))) ((!offer fix ?i)))
   (:method (next-step) reverify ((stale ?i) (not (merged ?i)) (not (blocked ?i))) ((!offer reverify ?i)))
   (:method (next-step) verify
     ((implemented ?i) (not (merged ?i)) (not (verified ?i)) (not (failed ?i)) (not (stale ?i)) (not (blocked ?i))
      (not (waiting ?i)))
     ((!offer verify ?i)))
   (:method (next-step) review ((unseen ?i) (implemented ?i) (not (merged ?i))) ((!offer review ?i)))
   (:method (next-step) pull-request
     ((pr-target ?i) (verified ?i) (not (pr-open ?i)) (not (merged ?i)) (not (unseen ?i)) (not (waiting ?i))
      (not (blocked ?i)))
     ((!offer pull-request ?i)))
   (:method (next-step) merge ((pr-open ?i) (not (merged ?i))) ((!offer merge ?i)))
   (:method (next-step) implement ((item ?i) (not (implemented ?i)) (not (merged ?i)) (not (blocked ?i)) (not (waiting ?i)))
     ((!offer implement ?i)))
   (:method (next-step) wait-decision ((blocked ?i) (not (merged ?i))) ((!offer wait-for-decision ?i)))
   (:method (next-step) wait-dependency ((waiting ?i) (not (merged ?i)) (not (blocked ?i))) ((!offer wait-for-dependency ?i)))))

(defvar *planner-lock* (sb-thread:make-mutex :name "zettelkasten-kiosk SHOP3"))

(defun plan-next (&optional (register (register)))
  "Das native Planergebnis: jeder mögliche nächste Schritt als eigene Alternative, nur geplant."
  (sb-thread:with-mutex (*planner-lock*)
    (let* ((name (gensym "ZETTELKASTEN-KIOSK-"))
           (facts (project-facts register))
           (shop3::*problem* shop3::*problem*)
           (problem (shop3:make-problem (list name :domain 'zettelkasten-kiosk :silently t)
                                        (copy-tree facts) '((next-step)))))
      (unwind-protect
           (multiple-value-bind (raw seconds trees states)
               (shop3:find-plans problem :domain (shop3:find-domain 'zettelkasten-kiosk) :which :all
                                         :verbose 0 :plan-tree nil :collect-state t)
             (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                            :problem-name name :raw-plans raw :plans (mapcar #'shop3:shorter-plan raw)
                            :time seconds :final-states states :initial-facts facts
                            :plan-trees trees :execution-mode :plan-only))
        (shop3:delete-problem problem)))))

(defun offers (&optional (plan (plan-next)))
  "(SCHRITT ZIEL) je Plan, in der Reihenfolge, in der SHOP3 sie liefert, ohne Doppel."
  (remove-duplicates
   (loop for p in (dreyeck/shop3:plans-of plan)
         for s = (first p)
         when (and s (eq (first s) '!offer)) collect (list (second s) (third s)))
   :test #'equal :from-end t))

(defun recommended (&optional (plan (plan-next))) (first (offers plan)))

;;; Was ein Schritt bedeutet, wer ihn tut, und auf welche Fakten seine Methode sich stützt

(defparameter +steps+
  '((decide "Entscheiden" :operator "decide")
    (fix "Defekt beheben" :agent "implement")
    (reverify "Erneut prüfen: Kopf hat sich seit der Prüfung bewegt" :agent "verify")
    (verify "Prüfen und Beleg eintragen" :agent "verify")
    (review "Ansehen; danach :seen eintragen" :operator "review")
    (pull-request "Pull Request anlegen (auf Auftrag)" :agent "pull-request")
    (merge "Mergen" :operator "merge")
    (implement "Umsetzen" :agent "implement")
    (wait-for-decision "Warten auf eine Entscheidung" nil nil)
    (wait-for-dependency "Warten, bis die Abhängigkeit geprüft ist" nil nil)))

(defparameter +methods+
  '((decide decide (blocks)) (fix fix (failed)) (reverify reverify (stale)) (verify verify (implemented))
    (review review (unseen)) (pull-request pull-request (pr-target verified)) (merge merge (pr-open))
    (implement implement (item)) (wait-for-decision wait-decision (blocked))
    (wait-for-dependency wait-dependency (waiting)))
  "Schritt -> (Methode, Fakten ihrer Vorbedingung, die als Begründung gezeigt werden). Die Tests prüfen den Abgleich.")

(defun step-word (step) (or (second (assoc step +steps+)) (string-downcase step)))
(defun step-actor (step)
  (case (third (assoc step +steps+)) (:operator "Operator") (:agent "Agent") (t "—")))
(defun step-topic-id (step) (fourth (assoc step +steps+)))

(defun target-title (x)
  (let ((e (or (item x) (decision x)))) (if e (prop e :title) (string-downcase x))))

(defun evidence-text (e)
  (destructuring-bind (kind date who text &key at) e
    (format nil "~(~A~), ~A, ~A~@[ bei ~A~]: ~A" kind date (if (eq who :operator) "Operator" "Claude") at text)))

(defun explain (fact)
  (let ((x (second fact)))
    (case (first fact)
      (blocks (format nil "blockiert «~A»" (target-title (third fact))))
      (blocked (format nil "blockiert durch ~{«~A»~^, ~}"
                       (remove-if-not #'decision-open-p (prop (item x) :blocked-by))))
      (failed (format nil "nicht bestanden beim Kopf ~A: ~{~A~^ · ~}" (current-head (item x))
                      (mapcar #'evidence-text (evidence-at-head (item x) :failed))))
      (stale (format nil "Kopf ~A, geprüft nur bei ~{~A~^, ~}" (current-head (item x))
                     (remove-duplicates (loop for e in (append (evidence (item x) :verified) (evidence (item x) :failed))
                                              collect (getf (nthcdr 4 e) :at)) :test #'equal)))
      (verified (format nil "geprüft beim Kopf ~A: ~{~A~^ · ~}" (current-head (item x))
                        (mapcar #'evidence-text (evidence-at-head (item x) :verified))))
      (unseen "noch nicht vom Operator angesehen")
      (waiting (format nil "wartet auf ~{«~A»~^, ~}"
                       (loop for d in (prop (item x) :depends-on)
                             unless (and (item d) (verified-p (item d))) collect (target-title d))))
      (pr-target "soll als Pull Request eingereicht werden")
      (pr-open "Pull Request offen")
      (implemented (format nil "Branch ~A, Kopf ~A" (prop (item x) :branch) (current-head (item x))))
      (item "noch nicht begonnen")
      (t (string-downcase (symbol-name (first fact)))))))

(defun reasons (step target facts)
  "Methode und stützende Fakten dafür, STEP für TARGET anzubieten, aus den Anfangsfakten FACTS des Planers."
  (destructuring-bind (method required) (rest (assoc step +methods+))
    (let ((mine (remove-if-not (lambda (f) (and (member (first f) required) (eq (second f) target))) facts)))
      (cons (format nil "Methode ~(~A~)" method) (mapcar #'explain mine)))))
