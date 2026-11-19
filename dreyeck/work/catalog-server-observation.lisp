;;;; An observation task on the same Server Topic, independent of a release.

(in-package #:dreyeck/work/catalog-deployment-pr52)

(defclass server-observation ()
  ((deployment :initarg :deployment :reader observation-deployment)
   (server :initform nil :accessor observed-server)
   (remotes :initform nil :accessor observed-remotes)
   (comparison :initform nil :accessor observed-comparison)
   (order :initform :server-first :accessor observation-order)
   (generation :initform 0 :accessor observation-generation)
   (message :initform nil :accessor observation-message)
   (lock :initform (sb-thread:make-mutex :name "Server observation") :reader observation-lock)))

(defvar *local-server-book* nil)

(defclass local-host-page (hb:page)
  ((name :initarg :name :reader local-host-name)
   (remote-host :initarg :remote-host :reader remote-host-of)))

(defmethod hb:title-of ((page local-host-page)) (local-host-name page))

(v:defview local-operator-host (page local-host-page)
  (let* ((remote-host (remote-host-of page))
         (deployment (deployment-of remote-host))
         (image-root (uiop:getenv "HYPERDOC_REPO_ROOT")))
    (v:html-view :title "Host" :priority -100
      (v:html (:h2 (v:esc (local-host-name page)))
              (:p (v:esc (format nil "Lokaler HyperDoc-Catalog · Port 8080 · PID ~D" (sb-unix:unix-getpid))))
              (:p "Image-Checkout " (:code (v:esc (or image-root "Unbekannt"))))
              (:p "Git-Repository für den Branch-Vergleich "
                  (:code (v:esc (namestring (repository-of deployment)))))
              (:p (v:object-ref remote-host :select "Host" :display "Host dreyeck.ch öffnen"))))))

(defun ensure-server-observation (deployment)
  (sb-thread:with-mutex ((lock-of deployment))
    (or (server-observation-of deployment)
        (setf (server-observation-of deployment)
              (make-instance 'server-observation :deployment deployment)))))

(shop3:defdomain (catalog-server-observation :noset t)
  ((:operator (!observe-server) () () ())
   (:operator (!observe-remotes) () () ())
   (:operator (!compare-revisions) () () ())
   (:method (observe-server-state)
     complete ((comparison-observed)) ()
     compare ((server-observed) (remotes-observed)) ((!compare-revisions))
     server-missing ((remotes-observed)) ((!observe-server) (!compare-revisions))
     remotes-missing ((server-observed)) ((!observe-remotes) (!compare-revisions))
     remotes-first ((observe-remotes-first))
     ((!observe-remotes) (!observe-server) (!compare-revisions))
     server-first () ((!observe-server) (!observe-remotes) (!compare-revisions)))))

(defun observation-plan (observation &optional (order (observation-order observation)))
  (sb-thread:with-mutex (*planner-lock*)
    (let* ((domain 'catalog-server-observation)
           (name (gensym "CATALOG-SERVER-OBSERVATION-"))
           (facts (append (when (observed-server observation) '((server-observed)))
                          (when (observed-remotes observation) '((remotes-observed)))
                          (when (observed-comparison observation) '((comparison-observed)))
                          (when (eq order :remotes-first) '((observe-remotes-first)))))
           (shop3::*problem* shop3::*problem*)
           (problem (shop3:make-problem (list name :domain domain :silently t)
                                        (copy-tree facts) '((observe-server-state)))))
      (unwind-protect
           (multiple-value-bind (raw seconds trees states)
               (shop3:find-plans problem :domain (shop3:find-domain domain) :which :all
                                 :verbose 0 :plan-tree (not (observed-comparison observation))
                                 :collect-state t)
             (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                            :problem-name name :raw-plans raw :plans (mapcar #'shop3:shorter-plan raw)
                            :time seconds :plan-trees trees :final-states states :initial-facts facts
                            :execution-mode :plan-only))
        (shop3:delete-problem problem)))))

(defun next-observation-step (plan)
  (destructuring-bind (plan-steps) (dreyeck/shop3:plans-of plan)
    (ecase (caar plan-steps)
      (!observe-server :observe-server)
      (!observe-remotes :observe-remotes)
      (!compare-revisions :compare-revisions)
      ((nil) nil))))

(defun parse-server-observation (output)
  (destructuring-bind (state revision system pid local-http public-http)
      (uiop:split-string (string-right-trim '(#\Newline #\Return) output) :separator '(#\Tab))
    (let ((service-pid (parse-integer pid))
          (local (parse-integer local-http))
          (public (parse-integer public-http)))
      (unless (and (member state '("active" "inactive" "failed" "activating"
                                  "deactivating" "reloading" "maintenance" "refreshing")
                           :test #'string=)
                   (or (equal revision "-") (hex-revision-p revision))
                   (system-path-p system) (<= 0 service-pid)
                   (<= 0 local 599) (<= 0 public 599))
        (error "Ungültige Iststand-Ausgabe von dreyeck.ch."))
      (list :at (get-universal-time) :state state :revision (unless (equal revision "-") revision)
            :system system :pid service-pid :http (list local public)))))

(defun read-server-observation (observation)
  (unless (server-readback-ssh-p (observation-deployment observation))
    (error "Aktiviere den lokalen SSH-Readback im mREPL mit ENABLE-SERVER-READBACK-SSH."))
  (with-input-from-string (input (deployment-script))
    (multiple-value-bind (output diagnostic exit)
        (uiop:run-program '("ssh" "-T" "-o" "BatchMode=yes" "-o" "StrictHostKeyChecking=yes"
                            "-o" "ConnectTimeout=10" "-o" "ClearAllForwardings=yes"
                            "root@dreyeck.ch" "bash -s -- observe")
                          :input input :output :string :error-output :string :ignore-error-status t)
      (unless (eql 0 exit)
        (error "Server-Iststand über SSH (Exit ~D): ~A" exit diagnostic))
      (parse-server-observation output))))

(defun parse-remote-heads (output)
  (loop for line in (uiop:split-string output :separator '(#\Newline))
        for fields = (uiop:split-string (string-right-trim '(#\Return) line) :separator '(#\Tab))
        unless (equal line "")
          collect (destructuring-bind (revision ref) fields
                    (unless (and (hex-revision-p revision) (uiop:string-prefix-p "refs/heads/" ref))
                      (error "Git lieferte einen ungültigen Branch-Ref."))
                    (list ref revision))))

(defun read-remote-observations (observation)
  (let* ((root (repository-of (observation-deployment observation)))
         (names (uiop:split-string (git:trim-git-output (git:git-run-string root "remote"))
                                  :separator '(#\Newline))))
    (list :at (get-universal-time)
          :peers (loop for remote in names
                       unless (equal remote "")
                         collect
                         (handler-case
                             (multiple-value-bind (out diagnostic exit)
                                 (git:git-run-values root "ls-remote" "--heads" "--" remote)
                               (declare (ignore diagnostic))
                               (if (eql 0 exit)
                                   (list remote :heads (parse-remote-heads out))
                                   (list remote :unavailable (format nil "Git Exit ~D" exit))))
                           (error () (list remote :unavailable "Git-Leseoperation fehlgeschlagen")))))))

(defun ancestor-status (root ancestor commit)
  (nth-value 2 (git:git-run-values root "--no-replace-objects" "merge-base"
                                   "--is-ancestor" ancestor commit)))

(defun compare-revisions (root running branch)
  (cond ((null running) :no-server-revision)
        ((equal running branch) :same)
        (t (let ((forward (ancestor-status root running branch))
                 (reverse (ancestor-status root branch running)))
             (cond ((eql forward 0) :branch-ahead)
                   ((eql reverse 0) :server-ahead)
                   ((and (eql forward 1) (eql reverse 1)
                         (equal "false" (git:trim-git-output
                                         (git:git-run-string root "rev-parse" "--is-shallow-repository"))))
                    :diverged)
                   (t :unknown))))))

(defun compare-observations (observation)
  (let ((root (repository-of (observation-deployment observation)))
        (running (getf (observed-server observation) :revision))
        (cache (make-hash-table :test #'equal)))
    (list :at (get-universal-time)
          :rows (loop for (peer kind value) in (getf (observed-remotes observation) :peers)
                      append (ecase kind
                               (:unavailable (list (list peer nil nil :unavailable value)))
                               (:heads
                                (if value
                                    (loop for (ref sha) in value
                                          collect (list peer ref sha
                                                        (or (gethash sha cache)
                                                            (setf (gethash sha cache)
                                                                  (compare-revisions root running sha)))))
                                    (list (list peer nil nil :no-branches)))))))))

(defun play-observation (observation step generation
                         &key (read-server #'read-server-observation)
                              (read-remotes #'read-remote-observations))
  (sb-thread:with-mutex ((observation-lock observation))
    ;; Two clicks on the same rendered button share a generation.
    (when (and (= generation (observation-generation observation))
               (eq step (next-observation-step (observation-plan observation))))
      (handler-case
          (progn
            (ecase step
              (:observe-server (setf (observed-server observation) (funcall read-server observation)))
              (:observe-remotes (setf (observed-remotes observation) (funcall read-remotes observation)))
              (:compare-revisions (setf (observed-comparison observation)
                                        (compare-observations observation))))
            (setf (observation-message observation) nil)
            (incf (observation-generation observation)))
        (error (condition)
          (setf (observation-message observation) (princ-to-string condition))))))
  observation)

(defun choose-observation-plan (observation order generation)
  (sb-thread:with-mutex ((observation-lock observation))
    (when (and (= generation (observation-generation observation))
               (member order '(:server-first :remotes-first))
               (not (or (observed-server observation) (observed-remotes observation))))
      (setf (observation-order observation) order)
      (incf (observation-generation observation))))
  observation)

(defun restart-observation (observation generation)
  (sb-thread:with-mutex ((observation-lock observation))
    (when (= generation (observation-generation observation))
      (setf (observed-server observation) nil
            (observed-remotes observation) nil
            (observed-comparison observation) nil
            (observation-message observation) nil)
      (incf (observation-generation observation))))
  observation)

(defun observation-time (universal-time)
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time universal-time 0)
    (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D UTC"
            year month day hour minute second)))

(defun relation-label (value)
  (ecase value
    (:same "Läuft auf dem Server")
    (:branch-ahead "Branch enthält die Serverrevision und weitere Commits")
    (:server-ahead "Serverrevision enthält den Branch und weitere Commits")
    (:diverged "Unterschiedliche Entwicklungslinien")
    (:no-server-revision "Server meldet keine Revision")
    (:unknown "Verwandtschaft lokal nicht belegt")
    (:unavailable "Remote nicht lesbar")
    (:no-branches "Keine Branches angeboten")))

(defun render-observed-server (observation)
  (let ((server (observed-server observation)))
    (when server
      (v:html (:h3 "Laufender Catalog")
              (:p (v:esc (observation-time (getf server :at))))
              (:p (v:esc (format nil "Dienst ~A · PID ~D" (getf server :state) (getf server :pid))))
              (:p (:code (v:esc (or (getf server :revision) "Keine gemeldete Revision"))))
              (:p (:code (v:esc (getf server :system))))
              (:p (v:esc (format nil "HTTP lokal ~D · öffentlich ~D"
                                 (first (getf server :http)) (second (getf server :http)))))))))

(v:defview observation-task (observation server-observation)
  (v:html-view :title "DITA Task" :priority -100
    (let* ((plan (observation-plan observation))
           (step (next-observation-step plan))
           (generation (observation-generation observation)))
      (v:html (:p (v:object-ref plan :display "Nativer SHOP3-Plan") " · "
                  (v:esc (format nil "~S" (or step :complete))))
              (when (observation-message observation)
                (v:html (:p :role "status" (v:esc (observation-message observation)))))
              (render-executable-task
               "catalog-server-observation" step
               (lambda ()
                 (v:eval-button "Play"
                                (policy:reviewed-thunk "catalog-server-observation/play"
                                  (play-observation observation step generation))
                                "Aktuellen SHOP3-Schritt ausführen")))
              (render-observed-server observation)
              (when (observed-comparison observation)
                (v:html (:p (v:object-ref observation :select "Branches" :display "Git-Branches vergleichen"))))))))

(v:defview observation-branches (observation server-observation)
  (v:html-view :title "Branches" :priority 0
    (render-observed-server observation)
    (let* ((comparison (observed-comparison observation))
           (rows (getf comparison :rows))
           (deployment (observation-deployment observation))
           (target (find-if (lambda (row)
                              (and (equal (first row) (remote-of deployment))
                                   (equal (second row) +target-ref+))) rows)))
      (v:html (:h3 "Git-Branches")
              (if comparison
                  (v:html
                    (:p "Remotes gelesen " (v:esc (observation-time (getf (observed-remotes observation) :at))))
                    (when target
                      (v:html (:p (v:esc (format nil "~A · ~A" (remote-of deployment) +target-ref+))
                                  " · " (v:esc (relation-label (fourth target))))))
                    (if rows
                        (v:html
                          (:table
                           (:thead (:tr (:th "Remote") (:th "Branch") (:th "Commit") (:th "Zum Serverstand")))
                           (:tbody
                            (dolist (row rows)
                              (destructuring-bind (remote ref revision relation &optional detail) row
                                (v:html
                                  (:tr (:td (v:esc remote))
                                       (:td (:code (v:esc (if ref (subseq ref (length "refs/heads/")) "—"))))
                                       (:td (:code (v:esc (or revision "—"))))
                                       (:td (v:esc (relation-label relation))
                                            (when detail (v:html " · " (v:esc detail)))))))))))
                        (v:html (:p "In diesem Checkout sind keine Remotes konfiguriert."))))
                  (v:html (:p (v:object-ref observation :select "DITA Task"
                                            :display "Iststand und Git-Branches beobachten"))))))))

(defun observation-plan-button (observation generation &optional order)
  (v:eval-button
   (case order (:server-first "Server zuerst wählen") (:remotes-first "Git-Remotes zuerst wählen")
         (otherwise "Neuen Beobachtungslauf öffnen"))
   (policy:reviewed-thunk "catalog-server-observation/plan"
     (if order
         (choose-observation-plan observation order generation)
         (restart-observation observation generation)))))

(v:defview observation-plan-options (observation server-observation)
  (v:html-view :title "SHOP3-Pläne" :priority 10
    (let ((generation (observation-generation observation)))
      (v:html
        (if (or (observed-server observation) (observed-remotes observation))
            (v:html (:p (v:object-ref (observation-plan observation) :display "Aktueller SHOP3-Plan"))
                    (:p (observation-plan-button observation generation)))
            (v:html
              (:ul
               (dolist (order '(:server-first :remotes-first))
                 (v:html
                   (:li (v:object-ref (observation-plan observation order)
                                     :display (if (eq order :server-first)
                                                  "Server → Git-Remotes → Vergleich"
                                                  "Git-Remotes → Server → Vergleich"))
                        " "
                        (if (eq order (observation-order observation))
                            (v:html "Gewählt")
                            (v:html (observation-plan-button observation generation order)))))))))))))

(defun open-local-host (&key (repository (asdf:system-source-directory "dreyeck"))
                             (remote "origin") server-readback-ssh)
  "Start the loopback Catalog on port 8080 with the local and remote Host views."
  (let* ((root (truename (uiop:ensure-directory-pathname repository)))
         (existing (and (clog:is-running-p) *local-server-book*))
         (book (or existing (make-instance 'deployment-book :id +task-book-id+))))
    (if existing
        (let ((deployment (deployment-of (server-page-of book))))
          (unless (and (equal root (repository-of deployment)) (equal remote (remote-of deployment)))
            (error "Dieser lokale Catalog beobachtet bereits einen anderen Checkout oder Zielremote."))
          (when server-readback-ssh
            (setf (server-readback-ssh-p deployment) t)))
        (progn
          (when (clog:is-running-p)
            (error "In diesem Lisp-Image läuft bereits ein Catalog. Starte den lokalen Catalog auf 8080 in einem frischen Image."))
          (let ((deployment (make-deployment :repository root :remote remote
                                             :server-readback-ssh server-readback-ssh)))
            (let ((remote-host (make-instance 'server-page :id +server-page-id+
                                              :hyperbook book :deployment deployment)))
              (setf (server-page-of book) remote-host
                    (local-host-page-of book)
                    (make-instance 'local-host-page :id "host-local" :hyperbook book
                                   :name (machine-instance) :remote-host remote-host))))
          (asdf:load-system "dreyeck/catalog-application")
          (uiop:symbol-call "DREYECK/CATALOG-APPLICATION" "START-CATALOG" :host "127.0.0.1" :port 8080)
          (hb:register book)
          (setf *local-server-book* book)))
    (values (format nil "http://localhost:8080/~A/~A"
                    (hyperbook/server::slug book) (hb:path-item-of (local-host-page-of book)))
            (ensure-server-observation (deployment-of (server-page-of book))))))

