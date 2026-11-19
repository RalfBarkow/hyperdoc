(defpackage #:dreyeck/work/catalog-deployment-pr52
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views) (#:dita #:dreyeck/dita-story-item)
                    (#:policy #:dreyeck/authority-policy) (#:git #:dreyeck/git)
                    (#:hb #:hyperbook) (#:tm #:dreyeck/topicmap))
  (:export #:make-deployment #:plan-next #:record-receipt #:serve
           #:open-task #:open-local-host #:submit-receipt #:submit-service-observation))
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
   (expected-base :initarg :expected-base :initform +reviewed-base+ :reader expected-base-of)
   (candidate :initarg :candidate :initform +reviewed-head+ :reader candidate-of)
   (candidate-ref :initarg :candidate-ref :initform +candidate-ref+ :reader candidate-ref-of)
   (preassembled :initarg :preassembled :initform nil :reader preassembled-p)
   (push-endpoint-digest :initform nil :accessor push-endpoint-digest-of)
   (observations :initform nil :accessor observations)
   (command :initform nil :accessor command)
   (message :initform nil :accessor message-of)
   (server-topic :initform nil :accessor server-topic-of)
   (server-observation :initform nil :accessor server-observation-of)
   (catalog-service :initform nil :accessor catalog-service-of)
   (publish-enabled :initform nil :accessor publish-enabled-p)
   (lock :initform (sb-thread:make-mutex :name "PR 52 deployment") :reader lock-of)))

(defclass deployment-book (hb:hyperbook)
  ((task-page :initform nil :accessor task-page-of)
   (server-page :initform nil :accessor server-page-of)
   (local-host-page :initform nil :accessor local-host-page-of)))

(defclass deployment-page (hb:page)
  ((deployment :initarg :deployment :reader deployment-of)))

(defclass server-topic (tm:topicmap-topic) ())

(defclass server-page (hb:page)
  ((deployment :initarg :deployment :initform nil :reader deployment-of)
   (task-page :initarg :task-page :initform nil :reader task-page-of)))

(defun deployment-server-topic (deployment)
  (or (server-topic-of deployment)
      (setf (server-topic-of deployment)
            (make-instance 'server-topic :id +server-topic-id+ :label "dreyeck.ch"
                                         :type :nixos-server :object deployment))))

(defmethod hb:title-of ((book deployment-book)) "Catalog Deployment")
(defmethod hb:title-of ((page deployment-page)) "Geprüften HyperDoc-Stand in dreyeck.ch übernehmen")
(defmethod hb:title-of ((page server-page)) "Server dreyeck.ch")
(defmethod hb:main-page-id-of ((book deployment-book))
  (if (local-host-page-of book) (hb:id-of (local-host-page-of book)) +server-page-id+))

(defun ensure-server-page (book)
  (or (server-page-of book)
      (when (task-page-of book)
        (setf (server-page-of book)
              (make-instance 'server-page :id +server-page-id+ :hyperbook book
                                          :deployment (deployment-of (task-page-of book))
                                          :task-page (task-page-of book))))))

(defmethod hb:find-page ((book deployment-book) id &key signal-error?)
  (or (cond ((equal id +task-page-id+) (task-page-of book))
            ((equal id +server-page-id+) (ensure-server-page book))
            ((and (local-host-page-of book) (equal id (hb:id-of (local-host-page-of book))))
             (local-host-page-of book)))
      (when signal-error?
        (error 'hb:page-lookup-failure :hyperbook book :page-id id))))

(defun attach-task-page (book deployment)
  (setf (server-page-of book) nil)
  (setf (task-page-of book) (make-instance 'deployment-page :id +task-page-id+
                                                            :hyperbook book :deployment deployment)))

(defun make-deployment (&key (repository (asdf:system-source-directory "dreyeck"))
                             remote (source-remote remote)
                             candidate expected-base candidate-ref)
  "Bind the task to selected Git remotes and optionally to a preassembled candidate."
  (dolist (name (list remote source-remote))
    (unless (and (stringp name) (plusp (length name)) (char/= #\- (char name 0))
                 (every (lambda (c) (find c "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._/")) name))
      (error "Gib ein konfiguriertes Git-Remote mit :REMOTE an.")))
  (when (or candidate expected-base candidate-ref)
    (unless (and (hex-revision-p candidate) (hex-revision-p expected-base)
                 (not (string= candidate expected-base)) (stringp candidate-ref)
                 (uiop:string-prefix-p "refs/heads/" candidate-ref)
                 (> (length candidate-ref) (length "refs/heads/"))
                 (every (lambda (c) (find c "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._/"))
                        candidate-ref))
      (error "Gib :CANDIDATE und :EXPECTED-BASE als volle Git-SHAs und :CANDIDATE-REF als Branch-Ref an.")))
  (make-instance 'deployment :repository (uiop:ensure-directory-pathname repository)
                             :remote remote :source-remote source-remote
                             :expected-base (or expected-base +reviewed-base+)
                             :candidate (or candidate +reviewed-head+)
                             :candidate-ref (or candidate-ref +candidate-ref+)
                             :preassembled (not (null candidate))))

(shop3:defdomain (catalog-deployment-pr52 :noset t)
  ((:operator (!offer ?step) () () ((offered ?step)))
   (:method (next-deployment-step)
     observe-git ((not (observed :observe-git))) ((!offer :observe-git))
     review-candidate ((preassembled-candidate) (observed :observe-git)
                       (not (observed :review-candidate))) ((!offer :review-candidate))
     integrate ((not (preassembled-candidate)) (observed :observe-git)
                (not (observed :integrate))) ((!offer :integrate))
     publish-candidate ((observed :review-candidate) (not (observed :publish-ref))) ((!offer :publish-ref))
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
           (evidence (observations deployment))
           ;; SHOP3 4.3.1's tree extractor requires a nonempty primitive plan.
           (collect-trees-p (not (or (assoc :active-readback evidence)
                                     (assoc :verify evidence))))
           (facts (append (when (preassembled-p deployment) '((preassembled-candidate)))
                          (loop for (step . values) in evidence
                                collect (list 'observed step) collect (list 'evidence step values))))
           (domain 'catalog-deployment-pr52)
           (shop3::*problem* shop3::*problem*)
           (problem (shop3:make-problem (list name :domain domain :silently t)
                                       (copy-tree facts) '((next-deployment-step)))))
      (unwind-protect
           (multiple-value-bind (raw seconds trees states)
               (shop3:find-plans problem :domain (shop3:find-domain domain) :which :all
                                :verbose 0 :plan-tree collect-trees-p :collect-state t)
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

(defun check-candidate (deployment)
  (let ((candidate (candidate-of deployment)) (base (expected-base-of deployment)))
    (unless (and (commit-present-p deployment candidate) (commit-present-p deployment base)
                 (if (preassembled-p deployment)
                     (zerop (nth-value 2 (git:git-run-values (repository-of deployment)
                                                            "--no-replace-objects" "merge-base"
                                                            "--is-ancestor" base candidate)))
                     (equal (list candidate base) (revision-lineage deployment candidate))))
      (error "Der Kandidat kann nicht von der geprüften Git-Basis übernommen werden."))
    candidate))

(defun observe-git (deployment)
  (let* ((url (git-remote-url deployment (remote-of deployment) :push t))
         (target (git-ref-at deployment url +target-ref+))
         (base (expected-base-of deployment))
         (candidate (candidate-of deployment))
         (ref (candidate-ref-of deployment)))
    (unless (or (equal target base) (and (preassembled-p deployment) (equal target candidate)))
      (error "Der Git-Zielref dreyeck.ch weicht von der geprüften Basis ab."))
    (unless (commit-present-p deployment candidate)
      (let ((source (git-remote-url deployment (source-remote-of deployment))))
        (unless (equal candidate (git-ref-at deployment source ref))
          (error "Der Git-Quellref enthält eine andere als die geprüfte Revision."))
        (peer-git deployment "fetch" "--no-tags" "--no-write-fetch-head" "--" source ref)))
    (check-candidate deployment)
    (setf (push-endpoint-digest-of deployment) (endpoint-digest url))
    (list target candidate (remote-of deployment))))

(defun check-integration (deployment revision)
  (unless (and (hex-revision-p revision)
               (equal (list revision (expected-base-of deployment) (candidate-of deployment))
                      (revision-lineage deployment revision))
               (equal (revision-tree deployment revision)
                      (revision-tree deployment (candidate-of deployment))))
    (error "Eltern und Baum stimmen nicht mit dem geprüften Integrationsstand überein."))
  revision)

(defun integrate (deployment)
  ;; The candidate is a direct child of the base. Its tested tree is the complete merge tree.
  ;; COMMIT-TREE leaves HEAD, the index, and all refs untouched.
  (let ((merge (local-git deployment "commit-tree" (revision-tree deployment (candidate-of deployment))
                          "-p" (expected-base-of deployment) "-p" (candidate-of deployment)
                          "-m" "Integrate reviewed Lisp Critic reader A2 (Zettel 11667)")))
    (check-integration deployment merge)
    (list merge (expected-base-of deployment) (candidate-of deployment))))

(defun publish-ref (deployment)
  (unless (publish-enabled-p deployment)
    (error "Starte den lokalen Operator-Inspector mit SERVE, um den Git-Push zu nutzen."))
  (let* ((base (expected-base-of deployment))
         (candidate (candidate-of deployment))
         (merge (if (preassembled-p deployment)
                    (let ((checked (check-candidate deployment)))
                      (unless (equal checked (second (assoc :review-candidate (observations deployment))))
                        (error "Die Freigabe gilt nicht für diesen Kandidaten."))
                      checked)
                    (check-integration deployment (second (assoc :integrate (observations deployment))))))
         (url (git-remote-url deployment (remote-of deployment) :push t)))
    (unless (equal (push-endpoint-digest-of deployment) (endpoint-digest url))
      (error "Der konfigurierte Push-Endpunkt hat sich seit der Beobachtung geändert."))
    (let ((current (git-ref-at deployment url +target-ref+)))
      (unless (equal current merge)
        (unless (equal current base)
          (error "Git-Zielref hat sich seit der Beobachtung geändert."))
        ;; The verified ancestry makes this a fast-forward. The explicit lease
        ;; checks the old value at the receiver, including a concurrent push.
        (let ((exit (nth-value 2 (git:git-run-values (repository-of deployment)
                                                    "push" (format nil "--force-with-lease=~A:~A"
                                                                   +target-ref+ base)
                                                    "--" url (format nil "~A:~A" merge +target-ref+)))))
          (unless (equal merge (git-ref-at deployment url +target-ref+))
            (error "Git-Zielref bestätigt den Integrationscommit nicht (Push-Exit ~D)." exit)))))
    (list merge base candidate (remote-of deployment))))

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
            (:review-candidate
             (let ((candidate (check-candidate deployment)))
               (push (list step candidate (revision-tree deployment candidate))
                     (observations deployment))))
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

(defun deployment-step-button (deployment step)
  (case step
    (:publish-ref
     (v:eval-button "Play · Git-Ref veröffentlichen"
                    (policy:reviewed-thunk "catalog-deployment-pr52/publish-ref"
                      (play-step deployment step))))
    (otherwise
     (v:eval-button (if (eq step :review-candidate) "Play · Diesen Kandidaten freigeben" "Play")
                    (policy:reviewed-thunk "catalog-deployment-pr52/play"
                      (play-step deployment step))))))

(defun render-executable-task (task-id step render-buttons)
  (let* ((source (asdf:system-relative-pathname
                  "dreyeck/work/catalog-deployment-pr52"
                  (format nil "dreyeck/work/~A.dita" task-id)))
         (root (dita:parse-dita-topic (uiop:read-file-string source :external-format :utf-8)))
         (node (and step (plump:get-element-by-id root (string-downcase (symbol-name step)))))
         (marker (and step (symbol-name (gensym "PR52-PLAY-")))))
    (assert (and (equal "task" (plump:tag-name root))
                 (equal task-id (plump:attribute root "id"))))
    (when step
      (assert (and node (equal "step" (plump:tag-name node))))
      (plump:make-text-node (plump:make-element (elt (plump:get-elements-by-tag-name node "cmd") 0) "ph") marker))
    (let* ((html (dita:render-dita-topic (plump:serialize root nil)))
           (offset (and step (or (search marker html) (error "DITA-Schritt kann kein Play anzeigen.")))))
      (if offset
          (v:html (v:str (subseq html 0 offset)) " "
                  (funcall render-buttons)
                  (v:str (subseq html (+ offset (length marker)))))
          (v:html (v:str html))))))

(defun render-task (deployment step)
  (render-executable-task
   "catalog-deployment-pr52" step
   (lambda ()
     (v:html (deployment-step-button deployment step)
             (when (eq step :baseline)
               (v:html " " (service-observation-button (deployment-catalog-service deployment) :baseline)))))))

(defun task-view (deployment)
  (v:html-view :title "DITA Task" :priority -100
    (let* ((plan (plan-next deployment)) (step (offered-step plan)))
      (v:html (:p (v:object-ref plan :display "Nativer SHOP3-Plan") " · "
                  (v:esc (format nil "~S" (or step :complete))))
              (when (and step (message-of deployment))
                (v:html (:p :role "status" (v:esc (message-of deployment)))))
              (:p (v:object-ref (deployment-server-topic deployment) :select "Host"
                                :display "Host dreyeck.ch"))
              (:p "Git-Remote " (v:esc (remote-of deployment)) " · dreyeck.ch · Kandidat "
                  (:code (v:esc (candidate-of deployment))))
              (when (preassembled-p deployment)
                (v:html (:p "Erwartete Basis " (:code (v:esc (expected-base-of deployment))))))
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
         (observation (ensure-server-observation deployment))
         (readback (or (assoc :active-readback (observations deployment))
                       (assoc :verify (observations deployment)))))
    (v:html-view :title "Host" :priority -100
      (v:html (:h2 (v:esc (tm:topicmap-topic-label-of topic)))
              (:p "NixOS · hyperdoc.service · Catalog auf Port 8080")
              (:p (:code (v:esc (tm:topicmap-topic-id-of topic))))
              (:p (v:object-ref (deployment-catalog-service deployment) :select "Dienst"
                                :display "Dienst hyperdoc.service öffnen"))
              (:p (v:object-ref observation
                                :select "DITA Task" :display "Iststand und Git-Branches prüfen"))
              (render-observed-server observation)
              (when (and task (publish-enabled-p deployment))
                (v:html (:p (v:object-ref task :select "DITA Task" :display "Catalog-Deployment öffnen"))))
              (when (and (not readback) (message-of deployment))
                (v:html (:p :role "status" (v:esc (message-of deployment)))))
              (when readback
                (v:html (:h3 "Letzter Readback dieses Laufs")
                        (:pre (v:esc (format nil "~S" readback)))))))))

(v:defview server-topic-overview (topic server-topic)
  (catalog-server-view topic (tm:topicmap-topic-object-of topic)))

(v:defview server-page-overview (page server-page)
  (let* ((task (task-page-of page))
         (deployment (or (deployment-of page) (deployment-of task))))
    (catalog-server-view (deployment-server-topic deployment) task)))

(v:defview deployment-book-task (book deployment-book)
  (v:html-view :title "Host" :priority -100
    (let ((local-host (local-host-page-of book)))
      (v:html (:p (v:object-ref (or local-host (ensure-server-page book)) :select "Host"
                               :display (if local-host "Lokalen Host öffnen" "Host dreyeck.ch öffnen")))))))

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
                       remote (source-remote remote) (port 18752)
                       candidate expected-base candidate-ref)
  "Create a local task in the Catalog. Return the direct task URL, the Catalog URL, and the task state."
  (let* ((deployment (make-deployment :repository repository :remote remote :source-remote source-remote
                                      :candidate candidate :expected-base expected-base :candidate-ref candidate-ref))
         (url (serve deployment :port port)))
    (values url (format nil "http://127.0.0.1:~D/" port) deployment)))

(defun submit-receipt (evidence)
  "Record the server readback in the task opened by OPEN-TASK."
  (record-receipt (or *open-deployment* (error "Öffne zuerst das Task Topic mit OPEN-TASK.")) evidence))
