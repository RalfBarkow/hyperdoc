;;;; The change workflow as a SHOP3 plan. Facts come from register.sexp (and from a read-only refresh of public hyperdoc
;;;; pull requests in this image); the plan offers, for every change, the next step of the DITA task. Nothing here merges,
;;;; deploys or opens a connection to a host.
(defpackage #:change-workflow
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views) (#:dita #:dreyeck/dita-story-item)
                    (#:policy #:dreyeck/authority-policy) (#:hb #:hyperbook))
  (:export #:open-task #:plan-next #:offers #:load-register #:*register* #:change-facts))
(in-package #:change-workflow)

;;; Register

(defun system-file (name) (asdf:system-relative-pathname "change-workflow" name))

(defun load-register (&optional (path (system-file "register.sexp")))
  (with-open-file (s path :external-format :utf-8)
    (let ((*read-eval* nil) (*package* (find-package '#:change-workflow)))
      (loop for form = (read s nil :eof) until (eq form :eof) collect form))))

(defvar *register* nil "The changes, as read from register.sexp, with observations added in this image.")
(defun register () (or *register* (setf *register* (load-register))))

(defun change (id) (find id (register) :key (lambda (c) (getf c :id))))
(defun has-fact (c fact) (assoc fact (getf c :facts)))
(defun has-flag (c flag) (member flag (getf c :flags)))
(defun merged-p (id) (let ((c (change id))) (and c (has-fact c :merged))))

;;; Facts for the planner: the recorded ones and those derived from them

(defun change-facts (&optional (changes (register)))
  (let ((facts nil))
    (flet ((add (&rest f) (push f facts)))
      (dolist (c changes)
        (let ((id (getf c :id)))
          (add 'change id)
          (add (if (eq (getf c :repo) :fleet) 'fleet 'hyperdoc) id)
          (dolist (f (getf c :facts)) (add (intern (symbol-name (first f)) '#:change-workflow) id))
          (dolist (d (getf c :depends-on)) (add 'depends-on id d))
          ;; Derived
          (let* ((waiting (some (lambda (d) (not (merged-p d))) (getf c :depends-on)))
                 (pin-stale (and (getf c :depends-on) (not waiting) (not (has-fact c :pin-on-merged))))
                 (blocked (and (eq (getf c :repo) :fleet)
                               (some (lambda (o) (and (not (eq o c)) (eq (getf o :repo) :fleet)
                                                      (has-fact o :staging-active) (not (has-fact o :merged))))
                                     changes)))
                 (unseen (and (has-flag c :needs-view) (not (has-fact c :seen))))
                 (ready (and (has-fact c :pr-open) (not (has-fact c :merged)) (not waiting) (not pin-stale)
                             (or (has-fact c :staging-accepted) (not (has-flag c :needs-staging)))))
                 (done (and (has-fact c :merged) (or (not (has-flag c :needs-production)) (has-fact c :production-done)))))
            (when waiting (add 'waiting id))
            (when pin-stale (add 'pin-stale id))
            (when blocked (add 'blocked-staging id))
            (when unseen (add 'unseen id))
            (when ready (add 'ready-to-merge id))
            (when (has-flag c :needs-staging) (add 'needs-staging id))
            (when (has-flag c :needs-production) (add 'needs-production id))
            (when done (add 'done id))))))
    (nreverse facts)))

;;; Domain: one method per kind of next step, so that every change needing a step is its own alternative plan

(shop3:defdomain (change-workflow :noset t)
  ((:operator (!offer ?step ?change) () () ((offered ?step ?change)))
   (:method (next-step) look ((unseen ?c)) ((!offer review ?c)))
   (:method (next-step) wait ((waiting ?c) (not (merged ?c))) ((!offer wait-for-dependency ?c)))
   (:method (next-step) open-pr
     ((change ?c) (not (pr-open ?c)) (not (merged ?c)) (not (unseen ?c)) (not (waiting ?c)) (not (pin-stale ?c)))
     ((!offer pull-request ?c)))
   (:method (next-step) accept
     ((needs-staging ?c) (pr-open ?c) (not (staging-accepted ?c)) (not (blocked-staging ?c)) (not (waiting ?c))
      (not (pin-stale ?c)))
     ((!offer staging ?c)))
   (:method (next-step) accept-blocked
     ((needs-staging ?c) (pr-open ?c) (not (staging-accepted ?c)) (blocked-staging ?c))
     ((!offer wait-for-staging ?c)))
   (:method (next-step) repin ((pin-stale ?c)) ((!offer repin ?c)))
   (:method (next-step) merge ((ready-to-merge ?c)) ((!offer merge ?c)))
   (:method (next-step) production ((merged ?c) (needs-production ?c) (not (production-done ?c))) ((!offer production ?c)))
   (:method (next-step) all-done ((forall (?c) ((change ?c)) ((done ?c)))) ())))

(defvar *planner-lock* (sb-thread:make-mutex :name "change workflow SHOP3"))

(defun plan-next (&optional (changes (register)))
  "The native plan result: every next step of every registered change, as alternatives."
  (sb-thread:with-mutex (*planner-lock*)
    (let* ((name (gensym "CHANGE-WORKFLOW-"))
           (facts (change-facts changes))
           (shop3::*problem* shop3::*problem*)
           (problem (shop3:make-problem (list name :domain 'change-workflow :silently t)
                                       (copy-tree facts) '((next-step)))))
      (unwind-protect
           (multiple-value-bind (raw seconds trees states)
               (shop3:find-plans problem :domain (shop3:find-domain 'change-workflow) :which :all
                                :verbose 0 :plan-tree nil :collect-state t)
             (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                            :problem-name name :raw-plans raw :plans (mapcar #'shop3:shorter-plan raw)
                            :time seconds :final-states states :initial-facts facts
                            :plan-trees trees :execution-mode :plan-only))
        (shop3:delete-problem problem)))))

(defun offers (&optional (plan (plan-next)))
  "(step change) for each first step of each plan, without duplicates."
  (remove-duplicates
   (loop for p in (dreyeck/shop3:plans-of plan)
         for s = (first p)
         when (and s (eq (first s) '!offer)) collect (list (second s) (third s)))
   :test #'equal))

;;; What each offered step means, and which step of the DITA task it is

(defparameter +steps+
  '((review "Im lokalen HyperDoc ansehen; danach :seen eintragen" "review")
    (pull-request "Pull Request anlegen" "pull-request")
    (wait-for-dependency "Warten, bis die Abhängigkeit gemergt ist" "merge")
    (staging "PR-Kopf auf staging abnehmen" "staging")
    (wait-for-staging "Warten: ein anderer fleet-Branch läuft ungemergt auf staging" "staging")
    (repin "fleet-Pin auf den gemergten Commit umstellen" "merge")
    (merge "Mergen (Operator)" "merge")
    (production "Auf Produktion ausrollen (Operator)" "production")))

(defun step-word (step) (or (second (assoc step +steps+)) (string-downcase step)))
(defun step-topic-id (step) (third (assoc step +steps+)))

;;; Why a step is offered: the method that offers it, the facts of the change it rests on, and what the derived facts mean

(defparameter +methods+
  '((review look (unseen)) (wait-for-dependency wait (waiting)) (pull-request open-pr ())
    (staging accept (needs-staging pr-open)) (wait-for-staging accept-blocked (blocked-staging))
    (repin repin (pin-stale)) (merge merge (ready-to-merge)) (production production (merged needs-production)))
  "Step -> (method, facts its precondition requires). Kept beside the domain; the tests check both agree.")

(defun facts-of (id facts)
  (loop for f in facts when (eq (second f) id) collect f))

(defun explain-fact (f)
  (let ((id (second f)))
    (case (first f)
      (waiting (format nil "wartet auf ~{~A~^, ~}"
                       (loop for d in (getf (change id) :depends-on) unless (merged-p d) collect (getf (change d) :title))))
      (blocked-staging (format nil "staging belegt durch ~{~A~^, ~}"
                               (loop for o in (register)
                                     when (and (not (eq (getf o :id) id)) (eq (getf o :repo) :fleet)
                                               (has-fact o :staging-active) (not (has-fact o :merged)))
                                       collect (getf o :title))))
      (pin-stale (format nil "Abhängigkeit gemergt, Pin zeigt noch nicht auf den Merge"))
      (unseen "noch nicht im lokalen HyperDoc angesehen")
      (ready-to-merge "PR offen, Abnahme vorhanden oder nicht nötig, keine offene Abhängigkeit, Pin aktuell")
      (t (let ((recorded (assoc (intern (symbol-name (first f)) :keyword) (getf (change id) :facts))))
           (if recorded
               (format nil "~(~A~) (~A, ~A)" (first f) (second recorded) (third recorded))
               (string-downcase (symbol-name (first f)))))))))

(defun reasons (step id facts)
  "Method and supporting facts for offering STEP for change ID, given the planner's initial FACTS."
  (destructuring-bind (method required) (rest (assoc step +methods+))
    (let* ((mine (facts-of id facts))
           (shown (remove-if-not (lambda (f) (member (first f) required)) mine))
           (absent (when (eq step 'pull-request) (list "kein PR im Register"))))
      (list* (format nil "Methode ~(~A~)" method)
             (append (mapcar #'explain-fact shown)
                     (when (eq step 'merge)
                       (mapcar #'explain-fact (remove-if-not (lambda (f) (member (first f) '(pr-open staging-accepted pin-on-merged)))
                                                             mine)))
                     absent)))))

;;; Play: read the state of public hyperdoc pull requests (GET only), and mark merges in this image

(defvar *message* nil)

(defun read-pull-request (number)
  (multiple-value-bind (out err code)
      (uiop:run-program (list "env" "-u" "LD_LIBRARY_PATH" "-u" "DYLD_LIBRARY_PATH" "curl" "-sS" "--max-time" "20"
                              "--proto" "=https" "-H" "Accept: application/vnd.github+json"
                              (format nil "https://api.github.com/repos/RalfBarkow/hyperdoc/pulls/~D" number))
                        :output :string :error-output :string :ignore-error-status t)
    (unless (zerop code) (error "curl ~D: ~A" code err))
    (let ((json (shasht:read-json out)))
      (list :state (gethash "state" json) :merged (gethash "merged" json)
            :head (let ((h (gethash "head" json))) (and h (gethash "sha" h)))))))

(defun refresh-pull-requests ()
  (let ((today (multiple-value-bind (s mi h d mo y) (decode-universal-time (get-universal-time) 0)
                 (declare (ignore s mi h)) (format nil "~D-~2,'0D-~2,'0D" y mo d)))
        (report nil))
    (dolist (c (register))
      (when (and (eq (getf c :repo) :hyperdoc) (getf c :pr))
        (let ((pr (read-pull-request (getf c :pr))))
          (push (format nil "#~D ~A~:[~; gemergt~] (Kopf ~A)" (getf c :pr) (getf pr :state) (getf pr :merged)
                        (subseq (or (getf pr :head) "?") 0 (min 8 (length (or (getf pr :head) "?")))))
                report)
          (when (and (getf pr :merged) (not (has-fact c :merged)))
            (push (list :merged today "von GitHub gelesen (Play, in diesem Image)") (getf c :facts))))))
    (format nil "~{~A~^ · ~}" (or (nreverse report) '("keine hyperdoc-PRs im Register")))))

(policy:register-reviewed-control "change-workflow/refresh"
  :effect "Reads the state of the public hyperdoc pull requests named in the register with one GET each and marks merged ones in this image."
  :audit "REFRESH-PULL-REQUESTS runs curl --proto =https against api.github.com; it writes no file and changes no repository.")

;;; Book

(defclass workflow-book (hb:hyperbook) ())
(defclass workflow-page (hb:page) ())
(defparameter +book-id+ "change-workflow")
(defmethod hb:title-of ((book workflow-book)) "Änderungen bis auf die Server")
(defmethod hb:title-of ((page workflow-page)) "Nächste Schritte")
(defmethod hb:main-page-id-of ((book workflow-book)) "overview")
(defmethod hb:find-page ((book workflow-book) id &key signal-error?)
  (cond ((equal id "overview") (make-instance 'workflow-page :id id :hyperbook book))
        (signal-error? (error 'hb:page-lookup-failure :hyperbook book :page-id id))))

(defun fact-text (c)
  (format nil "~:[—~;~:*~{~A~^; ~}~]"
          (mapcar (lambda (f) (format nil "~(~A~) ~A: ~A" (first f) (second f) (third f))) (getf c :facts))))

(v:defview workflow-view (page workflow-page)
  (v:html-view :title "Nächste Schritte" :priority -100
    (let* ((plan (plan-next)) (offers (offers plan)))
      (v:html
       (:p (v:object-ref plan :display "Nativer SHOP3-Plan") " · nur Vorschläge; gemergt und aktiviert wird durch den Operator.")
       (when *message* (v:html (:p :role "status" (v:esc *message*))))
       (:p (v:eval-button "Play" (policy:reviewed-thunk "change-workflow/refresh"
                                   (setf *message* (handler-case (refresh-pull-requests) (error (c) (princ-to-string c)))))
                          "PR-Stand der hyperdoc-PRs lesend von GitHub holen")
           " PR-Stand lesen (nur GET, nur öffentliche hyperdoc-PRs)")
       (:table :class "inspector-table"
        (:tr (:th "Änderung") (:th "Nächster Schritt") (:th "Begründung") (:th "Schritt im Task"))
        (dolist (o (sort (copy-list offers) #'string< :key (lambda (o) (string (second o)))))
          (let ((c (change (second o))))
            (v:html (:tr (:td (v:esc (getf c :title)) " " (:code (v:esc (getf c :branch))))
                         (:td (v:esc (step-word (first o))))
                         (:td (:ul (dolist (r (reasons (first o) (second o) (dreyeck/shop3::initial-facts-of plan)))
                                     (v:html (:li (v:esc r))))))
                         (:td (:code (v:esc (or (step-topic-id (first o)) "—")))))))))
       (when (null offers) (v:html (:p "Alles gemergt und ausgerollt.")))
       (:h3 "Register")
       (:table :class "inspector-table"
        (:tr (:th "Änderung") (:th "Repo") (:th "Branch · Kopf · PR") (:th "Fakten"))
        (dolist (c (register))
          (v:html (:tr (:td (v:esc (getf c :title)))
                       (:td (v:esc (string-downcase (getf c :repo))))
                       (:td (:code (v:esc (format nil "~A · ~A~@[ · #~D~]" (getf c :branch) (or (getf c :head) "—") (getf c :pr)))))
                       (:td (v:esc (fact-text c)))))))
       (:h3 "Der Task")
       (v:str (dita:render-dita-topic (uiop:read-file-string (system-file "change-workflow.dita") :external-format :utf-8)))))))

(defun page-paths (book)
  (list (cons "overview" (format nil "/~A/overview" (hyperbook/server::slug book)))))

(defun open-task (&key (port 18761))
  "Open the overview in this image's running CLOG server, or start a loopback Catalog on PORT. Return its URL."
  (let ((book (or (hb:find-hyperbook +book-id+) (make-instance 'workflow-book :id +book-id+))))
    (unless (clog:is-running-p)
      (hyperbook/server:serve-catalog :host "127.0.0.1" :port port :development nil :pane-width "850px"))
    (hb:register book)
    (loop for (id . path) in (page-paths book)
          do (let ((page-id id))
               (clog:set-on-new-window
                (lambda (body)
                  (clog-moldable-inspector:on-new-inspector
                   body :object (hb:find-page book page-id :signal-error? t) :pane-width "850px"
                        :title (hb:title-of book) :playground? (second hyperbook/server::*server-parameters*)))
                :path path)))
    (format nil "http://localhost:~D~A" clog:*clog-port* (cdr (first (page-paths book))))))
