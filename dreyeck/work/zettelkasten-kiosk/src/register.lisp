;;;; Das Register lesen und Fakten bilden
;;;;
;;;; status.sexp hält Vorhaben und Entscheidungen. Daraus entstehen die Fakten für SHOP3: die eingetragenen (ein Beleg
;;;; zählt nur beim Commit, bei dem er gemacht wurde) und abgeleitete wie «veraltet», «wartet» und «blockiert».
(in-package #:zettelkasten-kiosk)

(defun system-file (name) (asdf:system-relative-pathname "zettelkasten-kiosk" name))

(defun load-register (&optional (path (system-file "status.sexp")))
  (with-open-file (s path :external-format :utf-8)
    (let ((*read-eval* nil) (*package* (find-package '#:zettelkasten-kiosk)))
      (loop for form = (read s nil :eof) until (eq form :eof) collect form))))

(defvar *register* nil "Vorhaben und Entscheidungen aus status.sexp, mit den in diesem Image beobachteten Köpfen.")
(defun register () (or *register* (setf *register* (load-register))))

(defun items (&optional (register (register))) (remove :item register :key #'first :test-not #'eq))
(defun decisions (&optional (register (register))) (remove :decision register :key #'first :test-not #'eq))
(defun item (id &optional (register (register))) (find id (items register) :key (lambda (i) (getf (rest i) :id))))
(defun decision (id &optional (register (register))) (find id (decisions register) :key (lambda (d) (getf (rest d) :id))))
(defun prop (entry key) (getf (rest entry) key))

(defvar *heads* nil "Item id -> Kopf, wie der Play-Knopf ihn in diesem Image von GitHub gelesen hat.")
(defun current-head (i) (or (cdr (assoc (prop i :id) *heads*)) (prop i :head)))

(defun same-commit-p (a b)
  "Zwei Commit-Angaben, kurz oder lang, bezeichnen denselben Commit, wenn die kürzere ein Präfix der längeren ist."
  (and a b (let ((n (min (length a) (length b)))) (and (>= n 7) (string-equal a b :end1 n :end2 n)))))

(defun evidence (i &optional kind)
  (remove-if-not (lambda (e) (or (null kind) (eq (first e) kind))) (prop i :evidence)))
(defun evidence-at-head (i kind)
  (remove-if-not (lambda (e) (same-commit-p (getf (nthcdr 4 e) :at) (current-head i))) (evidence i kind)))

(defun verified-p (i) (and (evidence-at-head i :verified) (not (evidence-at-head i :failed))))
(defun failed-p (i) (evidence-at-head i :failed))
(defun stale-p (i)
  "Geprüft wurde, aber bei keinem Commit, der jetzt Kopf ist."
  (and (current-head i) (not (verified-p i)) (not (failed-p i))
       (or (evidence i :verified) (evidence i :failed))))
(defun decision-open-p (id) (let ((d (decision id))) (and d (eq (prop d :status) :open))))

(defun project-facts (&optional (register (register)))
  "Die Fakten für den Planer: eingetragene und abgeleitete, je Vorhaben und Entscheidung."
  (let ((*register* register) (facts nil))
    (flet ((add (&rest f) (push f facts)))
      (dolist (d (decisions)) (when (decision-open-p (prop d :id)) (add 'decision-open (prop d :id))))
      (dolist (i (items))
        (let ((id (prop i :id)))
          (add 'item id)
          (when (current-head i) (add 'implemented id))
          (when (verified-p i) (add 'verified id))
          (when (failed-p i) (add 'failed id))
          (when (stale-p i) (add 'stale id))
          (when (member :pr (prop i :flags)) (add 'pr-target id))
          (when (member :needs-view (prop i :flags)) (add 'needs-view id))
          (when (evidence i :seen) (add 'seen id))
          (when (and (member :needs-view (prop i :flags)) (not (evidence i :seen))) (add 'unseen id))
          (when (evidence i :pr-open) (add 'pr-open id))
          (when (evidence i :merged) (add 'merged id))
          (dolist (d (prop i :depends-on))
            (add 'depends-on id d)
            (unless (and (item d) (verified-p (item d))) (add 'waiting id)))
          (dolist (d (prop i :blocked-by))
            (when (decision-open-p d) (add 'blocks d id) (add 'blocked id))))))
    (remove-duplicates (nreverse facts) :test #'equal :from-end t)))
