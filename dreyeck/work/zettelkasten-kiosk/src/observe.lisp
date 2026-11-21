;;;; Play: die Branch-Köpfe lesen
;;;;
;;;; Je Vorhaben mit Branch eine GET-Anfrage an die öffentliche GitHub-API. Steht ein anderer Kopf auf GitHub als im
;;;; Register, gilt in diesem Image der gelesene; Belege, die zu einem älteren Commit gehören, zählen dann als veraltet.
;;;; Jeder Druck liefert eine HEAD-OBSERVATION mit den Antworten und den Vorschlägen vorher und nachher. Geschrieben
;;;; wird nichts: weder status.sexp noch ein Repository.
(in-package #:zettelkasten-kiosk)

(defun branch-url (repo branch)
  (format nil "https://api.github.com/repos/~A/branches/~A" repo
          (with-output-to-string (s)
            (loop for ch across branch do (if (char= ch #\/) (write-string "%2F" s) (write-char ch s))))))

(defun read-branch-head (repo branch)
  "Eine GET-Anfrage: der volle SHA des Branch-Kopfs."
  (multiple-value-bind (out err code)
      (uiop:run-program (list "env" "-u" "LD_LIBRARY_PATH" "-u" "DYLD_LIBRARY_PATH" "curl" "-sS" "--max-time" "20"
                              "--proto" "=https" "-H" "Accept: application/vnd.github+json" (branch-url repo branch))
                        :output :string :error-output :string :ignore-error-status t)
    (unless (zerop code) (error "curl ~D: ~A" code err))
    (let* ((json (shasht:read-json out))
           (commit (and (hash-table-p json) (gethash "commit" json)))
           (sha (and (hash-table-p commit) (gethash "sha" commit))))
      (unless sha
        (error "GitHub gab für ~A ~A keinen Kopf zurück~@[: ~A~]" repo branch
               (and (hash-table-p json) (gethash "message" json))))
      sha)))

(defvar *head-reader* 'read-branch-head "Funktion von Repo und Branch; die Tests ersetzen sie und brauchen kein Netz.")

(defclass head-observation ()
  ((time :initarg :time :reader observation-time)
   (entries :initarg :entries :reader observation-entries
            :documentation "Je Vorhaben: (:item :repo :branch :recorded :observed :moved :url :error).")
   (offers-before :initarg :offers-before :reader offers-before)
   (offers-after :initarg :offers-after :reader offers-after))
  (:documentation "Ein Druck auf Play: die gelesenen Branch-Köpfe und die Vorschläge vorher und nachher."))

(defvar *observations* nil "Jede Beobachtung in diesem Image, neueste zuerst.")
(defvar *message* nil)

(defun time-string (universal)
  (multiple-value-bind (s mi h d mo y) (decode-universal-time universal 0)
    (format nil "~D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D UTC" y mo d h mi s)))

(defun short (sha) (and sha (subseq sha 0 (min 8 (length sha)))))

(defmethod v:text-representation ((o head-observation))
  (let ((moved (remove-if-not (lambda (e) (getf e :moved)) (observation-entries o)))
        (errors (remove-if-not (lambda (e) (getf e :error)) (observation-entries o))))
    (format nil "Köpfe gelesen ~A: ~D Branches, ~:[keiner bewegt~;~:*~{~A~^, ~} bewegt~]~[~:;, ~:*~D Fehler~]"
            (time-string (observation-time o)) (length (observation-entries o))
            (mapcar (lambda (e) (getf e :branch)) moved) (length errors))))

(defun read-heads ()
  (let* ((before (offers))
         (entries
           (loop for i in (items)
                 when (prop i :branch)
                   collect (let ((repo (prop i :repo)) (branch (prop i :branch)) (recorded (prop i :head)))
                             (handler-case
                                 (let ((sha (funcall *head-reader* repo branch)))
                                   (setf *heads* (acons (prop i :id) sha (remove (prop i :id) *heads* :key #'car)))
                                   (list :item (prop i :id) :repo repo :branch branch :recorded recorded :observed sha
                                         :moved (not (same-commit-p sha recorded)) :url (branch-url repo branch)))
                               (error (e) (list :item (prop i :id) :repo repo :branch branch :recorded recorded
                                                :url (branch-url repo branch) :error (princ-to-string e)))))))
         (o (make-instance 'head-observation :time (get-universal-time) :entries entries
                                             :offers-before before :offers-after (offers))))
    (push o *observations*)
    o))

(defun play-read-heads ()
  "Der Play-Knopf: beobachten, die Zusammenfassung für die Seite merken, die Beobachtung für den Inspector liefern."
  (let ((o (read-heads)))
    (setf *message* (v:text-representation o))
    o))

(policy:register-reviewed-control "zettelkasten-kiosk/read-heads"
  :effect "Reads the current head of each branch named in the Zettelkasten-kiosk register with one GET to the public GitHub API, and uses it in this image."
  :audit "PLAY-READ-HEADS runs curl --proto =https against api.github.com; it writes no file and changes no repository. It returns a HEAD-OBSERVATION.")

;;;; Play im Task «Lokal öffnen»: zeigt das Image den aktuellen Stand?
;;;;
;;;; Das verpackte Image kennt die Revision, aus der Nix es gebaut hat (HYPERDOC_SOURCE_REVISION; «…-dirty» bei
;;;; ungesicherten Änderungen). Play liest mit einer GET-Anfrage den Kopf des Branches dieses Systems und vergleicht.

(defparameter +own-repo+ "RalfBarkow/hyperdoc")
(defparameter +own-branch+ "work/zettelkasten-kiosk")
(defvar *revision-reader* (lambda () (uiop:getenv "HYPERDOC_SOURCE_REVISION"))
  "Funktion ohne Argumente: die Revision, aus der dieses Image gebaut ist, oder NIL.")

(defclass image-observation ()
  ((time :initarg :time :reader observation-time)
   (revision :initarg :revision :reader image-revision)
   (head :initarg :head :reader image-branch-head)
   (error :initarg :error :initform nil :reader image-error)
   (status :initarg :status :reader image-status
           :documentation ":current, :behind, :dirty, :unknown (keine Revision, etwa in der Dev-Shell) oder :error.")
   (system-directory :initarg :system-directory :reader image-system-directory))
  (:documentation "Ein Druck auf Play im Task «Lokal öffnen»: gebaute Revision gegen den Branch-Kopf auf GitHub."))

(defun image-status-text (status)
  (ecase status
    (:current "Aktuell: das Image ist aus dem Kopf des Branches gebaut.")
    (:behind "Der Branch ist weitergegangen: den Befehl aus Schritt 1 mit «nix run --refresh» neu starten.")
    (:dirty "Gebaut aus einem Arbeitsbaum mit ungesicherten Änderungen; kein Vergleich möglich.")
    (:unknown "Keine Revision angegeben: dieses Image läuft nicht aus dem verpackten Catalog (etwa SLY in der Dev-Shell).")
    (:error "Der Branch-Kopf liess sich nicht lesen.")))

(defmethod v:text-representation ((o image-observation))
  (format nil "Image-Prüfung ~A: ~A" (time-string (observation-time o)) (image-status-text (image-status o))))

(defun check-image ()
  (let* ((revision (let ((r (funcall *revision-reader*))) (and r (plusp (length r)) r)))
         (head nil) (error nil))
    (handler-case (setf head (funcall *head-reader* +own-repo+ +own-branch+))
      (error (e) (setf error (princ-to-string e))))
    (make-instance 'image-observation
                   :time (get-universal-time) :revision revision :head head :error error
                   :system-directory (namestring (asdf:system-source-directory "zettelkasten-kiosk"))
                   :status (cond ((null revision) :unknown)
                                 ((search "dirty" revision) :dirty)
                                 (error :error)
                                 ((same-commit-p revision head) :current)
                                 (t :behind)))))

(defvar *image-observations* nil "Jede Image-Prüfung in diesem Image, neueste zuerst.")
(defun play-check-image ()
  (let ((o (check-image))) (push o *image-observations*) o))

(policy:register-reviewed-control "zettelkasten-kiosk/check-image"
  :effect "Compares the revision this image was built from with the head of the branch work/zettelkasten-kiosk, read with one GET to the public GitHub API."
  :audit "PLAY-CHECK-IMAGE reads HYPERDOC_SOURCE_REVISION and runs curl --proto =https against api.github.com; it writes no file. It returns an IMAGE-OBSERVATION.")
