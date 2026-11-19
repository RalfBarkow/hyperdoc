(defpackage #:dreyeck/work/catalog-deployment-pr52
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views) (#:dita #:dreyeck/dita-story-item)
                    (#:policy #:dreyeck/authority-policy) (#:git #:dreyeck/git)
                    (#:hb #:hyperbook) (#:tm #:dreyeck/topicmap))
  (:export #:make-deployment #:plan-next #:record-receipt #:serve
           #:open-task #:submit-receipt #:enable-server-readback-ssh))
(in-package #:dreyeck/work/catalog-deployment-pr52)

(defparameter +reviewed-head+ "91e8fd65911e687472fb3e30d1574fa5e9119b1b")
(defparameter +reviewed-base+ "1b3fbd3cc62ba27f00b76b48e4ea7246fe2106f8")
(defparameter +candidate-ref+ "refs/heads/codex/z11667-lisp-critic-a2-integration")
(defparameter +target-ref+ "refs/heads/dreyeck.ch")
(defparameter +task-book-id+ "z11667-catalog-deployment")
(defparameter +task-page-id+ "catalog-deployment-pr52")
(defparameter +server-topic-id+ "tag:dreyeck.ch,2026:hyperdoc/server/dreyeck.ch")
(defparameter +server-page-id+ "server-dreyeck-ch")
(defvar *planner-lock* (sb-thread:make-mutex :name "PR 52 SHOP3 search"))
(defvar *open-deployment* nil)

(defclass deployment ()
  ((repository :initarg :repository :reader repository-of)
   (remote :initarg :remote :reader remote-of)
   (source-remote :initarg :source-remote :reader source-remote-of)
   (push-endpoint-digest :initform nil :accessor push-endpoint-digest-of)
   (observations :initform nil :accessor observations)
   (command :initform nil :accessor command)
   (message :initform nil :accessor message-of)
   (server-topic :initform nil :accessor server-topic-of)
   (server-readback-ssh :initarg :server-readback-ssh :initform nil :accessor server-readback-ssh-p)
   (publish-enabled :initform nil :accessor publish-enabled-p)
   (lock :initform (sb-thread:make-mutex :name "PR 52 deployment") :reader lock-of)))

(defclass deployment-book (hb:hyperbook)
  ((task-page :initform nil :accessor task-page-of)
   (server-page :initform nil :accessor server-page-of)))

(defclass deployment-page (hb:page)
  ((deployment :initarg :deployment :reader deployment-of)))

(defclass server-topic (tm:topicmap-topic) ())

(defclass server-page (hb:page)
  ((task-page :initarg :task-page :reader task-page-of)))

(defun deployment-server-topic (deployment)
  (or (server-topic-of deployment)
      (setf (server-topic-of deployment)
            (make-instance 'server-topic :id +server-topic-id+ :label "dreyeck.ch"
                                         :type :nixos-server :object deployment))))

(defmethod hb:title-of ((book deployment-book)) "Catalog Deployment")
(defmethod hb:title-of ((page deployment-page)) "Geprüften HyperDoc-Stand in dreyeck.ch übernehmen")
(defmethod hb:title-of ((page server-page)) "Server dreyeck.ch")
(defmethod hb:main-page-id-of ((book deployment-book)) +server-page-id+)

(defun ensure-server-page (book)
  (or (server-page-of book)
      (when (task-page-of book)
        (setf (server-page-of book)
              (make-instance 'server-page :id +server-page-id+ :hyperbook book
                                          :task-page (task-page-of book))))))

(defmethod hb:find-page ((book deployment-book) id &key signal-error?)
  (or (cond ((equal id +task-page-id+) (task-page-of book))
            ((equal id +server-page-id+) (ensure-server-page book)))
      (when signal-error?
        (error 'hb:page-lookup-failure :hyperbook book :page-id id))))

(defun attach-task-page (book deployment)
  (setf (server-page-of book) nil)
  (setf (task-page-of book) (make-instance 'deployment-page :id +task-page-id+
                                                            :hyperbook book :deployment deployment)))

(defun make-deployment (&key (repository (asdf:system-source-directory "dreyeck"))
                             remote (source-remote remote) server-readback-ssh)
  "Bind the task to an existing Git checkout and explicitly selected Git remotes."
  (dolist (name (list remote source-remote))
    (unless (and (stringp name) (plusp (length name)) (char/= #\- (char name 0))
                 (every (lambda (c) (find c "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._/")) name))
      (error "Gib ein konfiguriertes Git-Remote mit :REMOTE an.")))
  (make-instance 'deployment :repository (uiop:ensure-directory-pathname repository)
                             :remote remote :source-remote source-remote
                             :server-readback-ssh server-readback-ssh))

(shop3:defdomain (catalog-deployment-pr52 :noset t)
  ((:operator (!offer ?step) () () ((offered ?step)))
   (:method (next-deployment-step)
     observe-git ((not (observed :observe-git))) ((!offer :observe-git))
     integrate ((observed :observe-git) (not (observed :integrate))) ((!offer :integrate))
     publish-ref ((observed :integrate) (not (observed :publish-ref))) ((!offer :publish-ref))
     complete-from-readback ((observed :publish-ref) (observed :active-readback)) ()
     read-baseline ((observed :publish-ref) (not (observed :active-readback))
                    (not (observed :baseline))) ((!offer :baseline))
     git-source ((observed :baseline) (not (observed :git-source))) ((!offer :git-source))
     build ((observed :git-source) (not (observed :build))) ((!offer :build))
     activate ((observed :build) (not (observed :activate))) ((!offer :activate))
     verify ((observed :activate) (not (observed :verify))) ((!offer :verify))
     complete ((observed :verify)) ())))

(defun plan-next (deployment)
  "Return the native plan result for operator evidence already recorded."
  (sb-thread:with-mutex (*planner-lock*)
    (let* ((name (gensym "CATALOG-PR52-"))
           (facts (loop for (step . values) in (observations deployment)
                        collect (list 'observed step) collect (list 'evidence step values)))
           (domain 'catalog-deployment-pr52)
           (shop3::*problem* shop3::*problem*)
           (problem (shop3:make-problem (list name :domain domain :silently t)
                                       (copy-tree facts) '((next-deployment-step)))))
      (unwind-protect
           (multiple-value-bind (raw seconds trees states)
               (shop3:find-plans problem :domain (shop3:find-domain domain) :which :all
                                :verbose 0 :plan-tree t :collect-state t)
             (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                            :problem-name name :raw-plans raw :plans (mapcar #'shop3:shorter-plan raw)
                            :time seconds :plan-trees trees :final-states states :initial-facts facts
                            :execution-mode :plan-only))
        (shop3:delete-problem problem)))))

(defun offered-step (plan)
  (destructuring-bind (offer) (dreyeck/shop3:plans-of plan)
    (when offer (destructuring-bind ((!offer step)) offer
                  (assert (eq !offer '!offer))
                  step))))

(defun hex-revision-p (value)
  (and (stringp value) (= (length value) 40)
       (every (lambda (char) (find char "0123456789abcdef")) value)))

(defparameter +safe-chars+ "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._+")

(defun receipt-path-p (value)
  (let ((prefix "/var/tmp/hyperdoc-pr52."))
    (and (stringp value) (uiop:string-prefix-p prefix value)
         (= (length value) (+ (length prefix) 8))
         (every (lambda (c) (find c (subseq +safe-chars+ 0 62)))
                (subseq value (length prefix))))))

(defun system-path-p (value)
  (let ((prefix "/nix/store/") (suffix "-nixos-system-dreyeck-"))
    (and (stringp value) (uiop:string-prefix-p prefix value)
         (let* ((name (subseq value (length prefix))) (end (+ 32 (length suffix))))
           (and (> (length name) end) (string= suffix name :start2 32 :end2 end)
                (every (lambda (c) (find c +safe-chars+)) name))))))

(defun local-git (deployment &rest arguments)
  (git:trim-git-output (apply #'git:git-run-string (repository-of deployment) "--no-replace-objects" arguments)))

(defun peer-git (deployment operation &rest arguments)
  (multiple-value-bind (out diagnostic exit)
      (apply #'git:git-run-values (repository-of deployment) operation arguments)
    (declare (ignore diagnostic))
    (unless (zerop exit)
      ;; A remote URL may carry credentials. Keep it out of the Inspector and receipts.
      (error "Git-Transport für ~A: ~A endete mit Exit ~D."
             (remote-of deployment) operation exit))
    (git:trim-git-output out)))

(defun git-remote-url (deployment remote &key push)
  (let* ((arguments (append '("get-url") (when push '("--push")) (list "--all" remote)))
         (url (apply #'peer-git deployment "remote" arguments)))
    (unless (and (plusp (length url)) (notany (lambda (ch) (find ch '(#\Newline #\Return))) url))
      (error "Wähle ein Git-Remote mit genau einem ~A-Endpunkt." (if push "Push" "Fetch")))
    url))

(defun endpoint-digest (url)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets url :external-format :utf-8))))

(defun git-ref-at (deployment url ref)
  (destructuring-bind (revision found-ref)
      (uiop:split-string (peer-git deployment "ls-remote" "--refs" "--exit-code" "--" url ref)
                         :separator '(#\Tab #\Newline #\Return))
    (assert (and (hex-revision-p revision) (equal ref found-ref)))
    revision))

(defun commit-present-p (deployment revision)
  (zerop (nth-value 2 (git:git-run-values (repository-of deployment) "cat-file" "-e"
                                       (format nil "~A^{commit}" revision)))))

(defun revision-lineage (deployment revision)
  (uiop:split-string (local-git deployment "rev-list" "--parents" "-n" "1" revision)
                     :separator '(#\Space)))

(defun revision-tree (deployment revision)
  (let ((tree (local-git deployment "rev-parse" "--verify" (format nil "~A^{tree}" revision))))
    (assert (hex-revision-p tree))
    tree))

(defun observe-git (deployment)
  (let ((url (git-remote-url deployment (remote-of deployment) :push t)))
    (unless (equal +reviewed-base+ (git-ref-at deployment url +target-ref+))
      (error "Der Git-Zielref dreyeck.ch weicht von der geprüften Basis ab."))
    (unless (commit-present-p deployment +reviewed-head+)
      (let ((source (git-remote-url deployment (source-remote-of deployment))))
        (unless (equal +reviewed-head+ (git-ref-at deployment source +candidate-ref+))
          (error "Der Git-Quellref enthält eine andere als die geprüfte Revision."))
        (peer-git deployment "fetch" "--no-tags" "--no-write-fetch-head" "--" source +candidate-ref+)))
    (unless (and (commit-present-p deployment +reviewed-head+)
                 (commit-present-p deployment +reviewed-base+)
                 (equal (list +reviewed-head+ +reviewed-base+)
                        (revision-lineage deployment +reviewed-head+)))
      (error "Die geprüfte Revision liegt nicht als direkter Nachfolger der geprüften Basis vor."))
    (setf (push-endpoint-digest-of deployment) (endpoint-digest url))
    (list +reviewed-base+ +reviewed-head+ (remote-of deployment))))

(defun check-integration (deployment revision)
  (unless (and (hex-revision-p revision)
               (equal (list revision +reviewed-base+ +reviewed-head+)
                      (revision-lineage deployment revision))
               (equal (revision-tree deployment revision)
                      (revision-tree deployment +reviewed-head+)))
    (error "Eltern und Baum stimmen nicht mit dem geprüften Integrationsstand überein."))
  revision)

(defun integrate (deployment)
  ;; The candidate is a direct child of the base. Its tested tree is the complete merge tree.
  ;; COMMIT-TREE leaves HEAD, the index, and all refs untouched.
  (let ((merge (local-git deployment "commit-tree" (revision-tree deployment +reviewed-head+)
                          "-p" +reviewed-base+ "-p" +reviewed-head+
                          "-m" "Integrate reviewed Lisp Critic reader A2 (Zettel 11667)")))
    (check-integration deployment merge)
    (list merge +reviewed-base+ +reviewed-head+)))

(defun publish-ref (deployment)
  (unless (publish-enabled-p deployment)
    (error "Starte den lokalen Operator-Inspector mit SERVE, um den Git-Push zu nutzen."))
  (let* ((merge (check-integration deployment (second (assoc :integrate (observations deployment)))))
         (url (git-remote-url deployment (remote-of deployment) :push t)))
    (unless (equal (push-endpoint-digest-of deployment) (endpoint-digest url))
      (error "Der konfigurierte Push-Endpunkt hat sich seit der Beobachtung geändert."))
    (let ((current (git-ref-at deployment url +target-ref+)))
      (unless (equal current merge)
        (unless (equal current +reviewed-base+)
          (error "Git-Zielref hat sich seit der Beobachtung geändert."))
        ;; The verified first parent makes this a fast-forward. The explicit lease
        ;; checks the old value at the receiver, including a concurrent push.
        (let ((exit (nth-value 2 (git:git-run-values (repository-of deployment)
                                                    "push" (format nil "--force-with-lease=~A:~A"
                                                                   +target-ref+ +reviewed-base+)
                                                    "--" url (format nil "~A:~A" merge +target-ref+)))))
          (unless (equal merge (git-ref-at deployment url +target-ref+))
            (error "Git-Zielref bestätigt den Integrationscommit nicht (Push-Exit ~D)." exit)))))
    (list merge +reviewed-base+ +reviewed-head+ (remote-of deployment))))

(defun target-revision (deployment)
  (second (assoc :publish-ref (observations deployment))))

(defun deployment-script ()
  (uiop:read-file-string (asdf:system-relative-pathname "dreyeck/work/catalog-deployment-pr52"
                                                       "dreyeck/work/catalog-deployment-pr52.sh")
                         :external-format :utf-8))

(defun server-command (deployment step)
  (let ((dir (third (assoc :baseline (observations deployment)))))
    (format nil "bash -s -- ~A '~A'~@[ '~A'~] <<'HYPERDOC_PR52'~%~AHYPERDOC_PR52~%"
            (string-downcase (symbol-name step)) (target-revision deployment) dir
            (deployment-script))))

(defun play-step (deployment step)
  (sb-thread:with-mutex ((lock-of deployment))
    (handler-case
        (progn
          (unless (eq step (offered-step (plan-next deployment)))
            (error "Dieses Angebot ist veraltet. Aktualisiere das Pane."))
          (setf (message-of deployment) nil)
          (case step
            (:observe-git
             (push (cons step (observe-git deployment)) (observations deployment)))
            (:integrate
             (push (cons step (integrate deployment)) (observations deployment)))
            (:publish-ref
             (push (cons step (publish-ref deployment)) (observations deployment))
             (setf (message-of deployment)
                   (format nil "Git bestätigt ~A auf ~A." (target-revision deployment) +target-ref+)))
            (otherwise (setf (command deployment) (server-command deployment step)))))
      (error (condition) (setf (message-of deployment) (princ-to-string condition)))))
  deployment)

(defun catalog-health-p (values)
  (and (= (length values) 3)
       (typep (first values) '(integer 1))
       (equal (rest values) '(200 200))))

(defun check-receipt (deployment evidence)
  (let ((offered (offered-step (plan-next deployment)))
        (target (target-revision deployment)))
    (when (eq :active-readback (first evidence))
      (destructuring-bind (revision path &rest health) (rest evidence)
        (return-from check-receipt
          (and (eq offered :baseline) (equal revision target)
               (system-path-p path) (catalog-health-p health)))))
    (destructuring-bind (step revision dir path &rest extra) evidence
      (let ((baseline (assoc :baseline (observations deployment)))
            (build (assoc :build (observations deployment))))
        (and (command deployment) (eq step offered)
             (equal revision target) (receipt-path-p dir) (system-path-p path)
             (or (eq step :baseline) (equal dir (third baseline)))
             (case step
               (:baseline (and (= (length extra) 2) (hex-revision-p (first extra))
                               (member (second extra) '(:git :other))))
               (:git-source (and (null extra) (equal path (fourth baseline))))
               (:build (null extra))
               (:activate (and (null extra) (equal path (fourth build))))
               (:verify (and (equal path (fourth build)) (catalog-health-p extra)))))))))

(defun record-receipt (deployment evidence)
  "Record operator readback as data for the current SHOP3 offer."
  (sb-thread:with-mutex ((lock-of deployment))
    (unless (and (eq :active-readback (first evidence))
                 (equal evidence (first (observations deployment))))
      (unless (check-receipt deployment evidence)
        (error "Serverbeleg passt nicht zum angebotenen Schritt, zur Revision oder zum Systempfad."))
      (push (copy-tree evidence) (observations deployment))
      (when (and (eq (first evidence) :baseline) (eq (sixth evidence) :git))
        (destructuring-bind (step revision dir path &rest extra) evidence
          (declare (ignore step extra))
          (push (list :git-source revision dir path) (observations deployment))))
      (setf (command deployment) nil (message-of deployment) nil))
    (plan-next deployment)))

(defun parse-ssh-readback (output)
  (destructuring-bind (revision system pid local-http public-http)
      (uiop:split-string (string-right-trim '(#\Newline #\Return) output) :separator '(#\Tab))
    (list :active-readback revision system (parse-integer pid)
          (parse-integer local-http) (parse-integer public-http))))

(defun play-server-readback (deployment)
  (handler-case
      (let ((revision (target-revision deployment)))
        (unless (and (publish-enabled-p deployment) (server-readback-ssh-p deployment)
                     (hex-revision-p revision) (eq :baseline (offered-step (plan-next deployment))))
          (error "Dieser Server-Readback gehört zu einem lokalen Angebot :BASELINE mit aktivierter SSH-Verbindung."))
        (with-input-from-string (input (deployment-script))
          (multiple-value-bind (output diagnostic exit)
              (uiop:run-program (list "ssh" "-T" "-o" "BatchMode=yes" "-o" "StrictHostKeyChecking=yes"
                                      "-o" "ConnectTimeout=10" "-o" "ClearAllForwardings=yes"
                                      "root@dreyeck.ch" (format nil "bash -s -- readback ~A" revision))
                                :input input :output :string :error-output :string :ignore-error-status t)
            (unless (eql 0 exit)
              (error "Server-Readback über SSH (Exit ~D): ~A" exit diagnostic))
            (record-receipt deployment (parse-ssh-readback output)))))
    (error (condition) (setf (message-of deployment) (princ-to-string condition))))
  (deployment-server-topic deployment))

(policy:register-reviewed-control "catalog-deployment-pr52/play"
  :effect "Observes selected Git refs, constructs a local commit object, or prepares an operator-owned server command."
  :audit "PLAY-STEP only dispatches the current native SHOP3 offer.")

(policy:register-reviewed-control "catalog-deployment-pr52/publish-ref"
  :effect "Publishes the verified Git merge commit to the configured peer's dreyeck.ch ref."
  :audit "PUBLISH-REF verifies parents and tree, uses an explicit old-value lease, and reads the ref back.")

(policy:register-reviewed-control "catalog-deployment-pr52/server-readback"
  :effect "Reads the active Catalog as the local operator via the fixed dreyeck.ch SSH route."
  :audit "PLAY-SERVER-READBACK uses only the fixed readback stage and validates its evidence against the published revision.")

(defun control-for (step)
  (case step
    (:publish-ref (values "Play · Git-Ref veröffentlichen" "catalog-deployment-pr52/publish-ref"))
    (otherwise (values "Play" "catalog-deployment-pr52/play"))))

(defun server-readback-button (deployment)
  (v:eval-button "Play · Laufenden Catalog lesen"
                 (policy:reviewed-thunk "catalog-deployment-pr52/server-readback"
                   (play-server-readback deployment))
                 "Liest Dienst, Revision und HTTP über die lokale SSH-Sitzung"))

(defun render-task (deployment step)
  (let* ((source (asdf:system-relative-pathname "dreyeck/work/catalog-deployment-pr52"
                                               "dreyeck/work/catalog-deployment-pr52.dita"))
         (root (dita:parse-dita-topic (uiop:read-file-string source :external-format :utf-8)))
         (node (and step (plump:get-element-by-id root (string-downcase (symbol-name step)))))
         (marker (and step (symbol-name (gensym "PR52-PLAY-")))))
    (assert (and (equal "task" (plump:tag-name root))
                 (equal "catalog-deployment-pr52" (plump:attribute root "id"))))
    (when step
      (assert (and node (equal "step" (plump:tag-name node))))
      (plump:make-text-node (plump:make-element (elt (plump:get-elements-by-tag-name node "cmd") 0) "ph") marker))
    (let* ((html (dita:render-dita-topic (plump:serialize root nil)))
           (offset (and step (or (search marker html) (error "DITA-Schritt kann kein Play anzeigen.")))))
      (if offset
          (multiple-value-bind (label identity) (control-for step)
            (v:html (v:str (subseq html 0 offset)) " "
                    (v:eval-button label (policy:reviewed-thunk identity (play-step deployment step))
                                   "Diesen SHOP3-Schritt ausführen")
                    (when (and (eq step :baseline) (server-readback-ssh-p deployment))
                      (v:html " " (server-readback-button deployment)))
                    (v:str (subseq html (+ offset (length marker))))))
          (v:html (v:str html))))))

(defun task-view (deployment)
  (v:html-view :title "DITA Task" :priority -100
    (let* ((plan (plan-next deployment)) (step (offered-step plan)))
      (v:html (:p (v:object-ref plan :display "Nativer SHOP3-Plan") " · "
                  (v:esc (format nil "~S" (or step :complete))))
              (when (message-of deployment) (v:html (:p :role "status" (v:esc (message-of deployment)))))
              (:p (v:object-ref (deployment-server-topic deployment) :select "Server"
                                :display "Server-Topic dreyeck.ch"))
              (:p "Git-Remote " (v:esc (remote-of deployment)) " · dreyeck.ch · geprüfter Commit "
                  (v:esc (subseq +reviewed-head+ 0 8)))
              (render-task deployment step)
              (when (command deployment)
                (v:html (:h3 "Befehl für die administrative Bash auf dreyeck.ch")
                        (:pre :style "white-space:pre-wrap" (v:esc (command deployment)))
                        (:p "Werte die letzte Ausgabezeile mit SUBMIT-RECEIPT im mREPL aus und aktualisiere dieses Pane.")))
              (:h3 "Beobachtungen")
              (:pre (v:esc (format nil "~S" (reverse (observations deployment)))))))))

(v:defview deployment-task (deployment deployment)
  (task-view deployment))

(v:defview deployment-page-task (page deployment-page)
  (task-view (deployment-of page)))

(defun catalog-server-view (topic task)
  (let* ((deployment (tm:topicmap-topic-object-of topic))
         (readback (or (assoc :active-readback (observations deployment))
                       (assoc :verify (observations deployment)))))
    (v:html-view :title "Server" :priority -100
      (v:html (:h2 (v:esc (tm:topicmap-topic-label-of topic)))
              (:p "NixOS · hyperdoc.service · Catalog auf Port 8080")
              (:p (:code (v:esc (tm:topicmap-topic-id-of topic))))
              (:p (v:object-ref task :select "DITA Task" :display "Catalog-Deployment öffnen"))
              (when (and (server-readback-ssh-p deployment)
                         (eq :baseline (offered-step (plan-next deployment))))
                (v:html (:p (server-readback-button deployment))))
              (when (message-of deployment)
                (v:html (:p :role "status" (v:esc (message-of deployment)))))
              (when readback
                (v:html (:h3 "Letzter Readback dieses Laufs")
                        (:pre (v:esc (format nil "~S" readback)))))))))

(v:defview server-topic-overview (topic server-topic)
  (catalog-server-view topic (tm:topicmap-topic-object-of topic)))

(v:defview server-page-overview (page server-page)
  (let ((task (task-page-of page)))
    (catalog-server-view (deployment-server-topic (deployment-of task)) task)))

(v:defview deployment-book-task (book deployment-book)
  (v:html-view :title "Server" :priority -100
    (v:html (:p (v:object-ref (ensure-server-page book) :select "Server"
                             :display "Server dreyeck.ch öffnen")))))

(defun serve (deployment &key (port 18752))
  "Register the task page in a local HyperBook Catalog and return its Inspector URL."
  (when (clog:is-running-p)
    (error "In diesem Image läuft bereits CLOG. Starte die Aufgabe im eigenen SLY-Image."))
  (let* ((book (or (hb:find-hyperbook +task-book-id+)
                   (make-instance 'deployment-book :id +task-book-id+)))
         (page (attach-task-page book deployment)))
    (hyperbook/server:serve-catalog :host "127.0.0.1" :port port :development nil :pane-width "850px")
    (hb:register book)
    (setf (publish-enabled-p deployment) t
          *open-deployment* deployment)
    (format nil "http://127.0.0.1:~D/~A/~A"
            port (hyperbook/server::slug book) (hb:path-item-of page))))

(defun open-task (&key (repository (asdf:system-source-directory "dreyeck"))
                       remote (source-remote remote) (port 18752) server-readback-ssh)
  "Create a local task in the Catalog. Return the direct task URL, the Catalog URL, and the task state."
  (let* ((deployment (make-deployment :repository repository :remote remote :source-remote source-remote
                                      :server-readback-ssh server-readback-ssh))
         (url (serve deployment :port port)))
    (values url (format nil "http://127.0.0.1:~D/" port) deployment)))

(defun submit-receipt (evidence)
  "Record the server readback in the task opened by OPEN-TASK."
  (record-receipt (or *open-deployment* (error "Öffne zuerst das Task Topic mit OPEN-TASK.")) evidence))

(defun enable-server-readback-ssh ()
  "Allow the local operator's readback button for the already open task."
  (let ((deployment (or *open-deployment* (error "Öffne zuerst das Task Topic mit OPEN-TASK."))))
    (setf (server-readback-ssh-p deployment) t)
    (deployment-server-topic deployment)))
