(defpackage #:dreyeck/work/deployment-reading/tests
  (:use #:cl)
  (:local-nicknames (#:reading #:dreyeck/work/deployment-reading)
                    (#:views #:html-inspector-views))
  (:export #:run-tests))
(in-package #:dreyeck/work/deployment-reading/tests)

(defun render-page (book title)
  (let* ((page (hyperbook:find-page book title :signal-error? t))
         (view (find "Content" (views:all-views page)
                     :key #'views:view-title :test #'equal)))
    (assert view)
    (views:view-html view)
    (assert (notany (lambda (reference) (typep (cdr reference) 'condition))
                    (views:view-references view)))
    (values page view)))

(defun record-by-id (evidence category id)
  (let ((matches (remove-if-not (lambda (record) (equal id (getf record :id)))
                                 (getf evidence category))))
    (assert (= 1 (length matches)))
    (first matches)))

(defun check-evidence (evidence)
  (let* ((facts (getf evidence :observed))
         (wiki (first facts))
         (checkout (record-by-id evidence :observed "dreyeck-checkout"))
         (service (record-by-id evidence :observed "hyperdoc-service"))
         (inference (record-by-id evidence :inferred "hyperdoc-started-from-checkout")))
    (assert (equal (getf evidence :provenance)
                   '(:kind :operator-supplied :observation-time :not-supplied
                     :scope :reported-snapshot :host-probe :not-performed)))
    (assert (equal wiki
                   '(:subject "wiki.ralfbarkow.ch" :kind :deployment-witness
                     :source-commit "b42eb888d6e5d59803667c6320e0779523fc265c"
                     :artifact "/nix/store/q8ppar443gy3ahm33hbbp3b5kwf4j930-wiki-p41-0.41.0-rc.3"
                     :service "wiki.service" :active-state "active" :sub-state "running"
                     :exec-start-program "/nix/store/q8ppar443gy3ahm33hbbp3b5kwf4j930-wiki-p41-0.41.0-rc.3/bin/wiki")))
    (assert (equal (getf checkout :path) "/home/rgb/workspace/hyperdoc"))
    (assert (equal (getf checkout :head) "84ee991aa4591a873a63753b89b37737ba5f2efc"))
    (assert (eq :checkout (getf checkout :kind)))
    (assert (eq :service (getf service :kind)))
    (assert (equal (getf service :working-directory) (getf checkout :path)))
    (assert (equal (getf service :exec-start) "nix develop .#tala -c ./scripts/serve-catalog.sh 8080"))
    (assert (equal (getf service :active-state) "active"))
    (assert (equal (getf service :sub-state) "running"))
    (assert (not (eq checkout service)))
    (assert (notany (lambda (r) (eq :service-working-directory (getf r :relation)))
                    (getf evidence :unresolved)))
    ;; Check this before cardinality: promotion to observed must fail semantically.
    (dolist (record facts)
      (when (equal "dreyeck.ch" (getf record :subject))
        (assert (not (eq :service-source-commit (getf record :relation))))
        (when (getf record :service)
          (assert (not (getf record :source-commit)))
          (assert (not (getf record :head))))))
    (assert (eq :service-source-commit (getf inference :relation)))
    (assert (equal (getf inference :source-commit) (getf checkout :head)))
    (assert (eq :not-directly-observed (getf inference :verification)))
    (assert (equal (getf inference :basis)
                   '("dreyeck-checkout" "hyperdoc-service" "checkout-fast-forward"
                     "sbcl-process-start" "hyperdoc-service-start")))
    (dolist (id (getf inference :basis)) (record-by-id evidence :observed id))
    (dolist (spec
             '(("checkout-fast-forward" :kind :checkout-transition :transition :fast-forward
                :checkout "dreyeck-checkout" :to "84ee991aa4591a873a63753b89b37737ba5f2efc"
                :at "2026-09-28 06:25:03 +0200")
               ("sbcl-process-start" :kind :process-start :runtime "SBCL"
                :time "06:25:13" :precision :approximate)
               ("hyperdoc-service-start" :kind :service-start :service "hyperdoc.service"
                :at "2026-09-28 06:25:14 CEST")
               ("nginx-exact-host" :host "dreyeck.ch" :match :exact
                :upstream "127.0.0.1:8080" :observed-paths ("/" "/clog"))
               ("nginx-wildcard-host" :host "*.dreyeck.ch" :match :wildcard :upstream "127.0.0.1:3000")
               ("nginx-mcp-host" :host "mcp.dreyeck.ch" :match :exact :upstream "127.0.0.1:8787")
               ("nginx-tls" :kind :tls-termination :host "dreyeck.ch" :terminator "nginx")
               ("hyperdoc-listener" :kind :listener :runtime "HyperDoc" :address "0.0.0.0:8080")
               ("fedwiki-listener" :kind :listener :runtime "Node/FedWiki" :address "*:3000")
               ("mcp-listener" :kind :listener :runtime "MCP/SBCL" :address "127.0.0.1:8787")
               ("nginx-listeners" :kind :listener :runtime "nginx" :addresses (":80" ":443"))
               ("nixos-firewall" :allowed-tcp-ports (80 443))
               ("external-8080" :origin :external :destination "dreyeck.ch:8080" :result :timed-out)
               ("fedwiki-config" :service "wiki.service" :user "rgb"
                :config "/home/rgb/.wiki/config.json" :farm t :security-type "friends"
                :not-explicitly-configured (:data :root :wiki-domains))
               ("fedwiki-pages" :path "/home/rgb/.wiki/dreyeck.ch/pages" :exists t)))
      (let ((record (record-by-id evidence :observed (first spec))))
        (loop for (key value) on (rest spec) by #'cddr
              do (assert (equal value (getf record key))))))
    (let ((route (record-by-id evidence :derived "public-apex-route")))
      (assert (eq :observed-public-nginx-routing (getf route :scope)))
      (assert (equal "127.0.0.1:8080" (getf route :reaches)))
      (assert (equal "Node/FedWiki :3000" (getf route :does-not-reach)))
      (assert (search "Local/operator-side requests remain possible" (getf route :limit)))
      (dolist (id (getf route :basis)) (record-by-id evidence :observed id)))
    (dolist (category '(:observed :derived :inferred :hypothesized :unresolved))
      (assert (member category evidence)))
    (assert (null (getf evidence :hypothesized)))
    (assert (= 18 (length facts)))
    (assert (= 1 (length (getf evidence :derived)) (length (getf evidence :inferred))))
    (assert (equal (getf evidence :unresolved)
                   '((:subject "dreyeck.ch" :relation :service-source-commit
                      :status :not-directly-observed :inference "hyperdoc-started-from-checkout")
                     (:subject "dreyeck.ch" :relation :external-8080-filtering-cause
                      :status :not-established :basis ("nixos-firewall" "external-8080")
                      :limit "Other network filtering was not excluded; the timeout does not prove that the firewall alone protects port 8080."))))
    (let ((text (string-downcase (prin1-to-string evidence))))
      (dolist (forbidden '("/authoring/v1/" "signed-authoring" "authoring-authority"))
        (assert (not (search forbidden text)))))
    (dolist (record facts)
      (when (and (eq :nginx-route (getf record :kind))
                 (equal "dreyeck.ch" (getf record :host)))
        (assert (equal "127.0.0.1:8080" (getf record :upstream))))))
  t)

(defun check-positive-controls ()
  (dolist (tamper
           (list
            (lambda (e) (push (first (getf e :inferred)) (getf e :observed)))
            (lambda (e)
              (push '(:subject "dreyeck.ch" :relation :service-working-directory
                      :status :not-established) (getf e :unresolved)))
            (lambda (e)
              (let ((record (record-by-id e :observed "nginx-exact-host")))
                (setf (getf record :upstream) "127.0.0.1:3000")))
            (lambda (e)
              (let ((record (record-by-id e :observed "hyperdoc-service")))
                (setf (getf record :exec-start) "signed-authoring /authoring/v1/")))))
    (let ((changed (reading:deployment-evidence)))
      (funcall tamper changed)
      (assert (handler-case (progn (check-evidence changed) nil)
                (error () t)))))
  (format t "~&DEPLOYMENT-EVIDENCE-CONTROLS-PASS: observed-commit promotion, stale unresolved WorkingDirectory, public Node route and target authoring rejected.~%"))

;;; The confirmation of 2026-10-01 is a separate observation. It is checked
;;; on its own and against the snapshot, which CHECK-EVIDENCE keeps as reported.

(defun check-confirmation (confirmation evidence)
  (let ((program (record-by-id confirmation :observed "hyperdoc-service-program"))
        (current (record-by-id confirmation :derived "current-service-start")))
    (assert (equal (getf confirmation :provenance)
                   '(:kind :operator-supplied :observation-time "2026-10-01"
                     :scope :operator-confirmation :host-probe :not-performed)))
    (assert (= 1 (length (getf confirmation :observed))))
    (assert (eq :service (getf program :kind)))
    (assert (equal "hyperdoc.service" (getf program :service)))
    (assert (equal "hyperdoc-catalog" (getf program :exec-start-program)))
    ;; The confirmation names the program; it does not supply a command line.
    (assert (eq :not-supplied (getf program :exec-start)))
    (assert (eq :current-service-start-command (getf current :relation)))
    (assert (equal (getf program :exec-start-program) (getf current :starts)))
    ;; Its basis is its own observation and the snapshot's service record,
    ;; resolved in the snapshot; what it no longer starts is what that
    ;; record reported.
    (destructuring-bind (own earlier) (getf current :basis)
      (assert (eq program (record-by-id confirmation :observed own)))
      (destructuring-bind (example category id) earlier
        (assert (eq 'reading:deployment-evidence example))
        (assert (equal (getf current :no-longer-starts)
                       (getf (record-by-id evidence category id) :exec-start)))))
    (assert (search "only which command currently starts" (getf current :limit)))
    (assert (equal (getf confirmation :unresolved)
                   '((:subject "dreyeck.ch" :relation :current-exec-start-arguments
                      :status :not-established
                      :limit "The confirmation names the program, not its store path, arguments, port or working directory."))))
    ;; Not merged into the snapshot.
    (assert (notany (lambda (record) (equal "hyperdoc-service-program" (getf record :id)))
                    (getf evidence :observed))))
  t)

(defun check-confirmation-controls ()
  (dolist (tamper
           (list
            (lambda (c e) (declare (ignore e))
              (let ((provenance (getf c :provenance)))
                (setf (getf provenance :observation-time) :not-supplied)))
            (lambda (c e) (declare (ignore e))
              (let ((record (record-by-id c :derived "current-service-start")))
                (setf (getf record :no-longer-starts) "nix run .#catalog")))
            (lambda (c e) (declare (ignore e))
              (let ((record (record-by-id c :derived "current-service-start")))
                (setf (getf record :limit) "Supersedes the snapshot.")))
            (lambda (c e)
              (push (first (getf c :observed)) (getf e :observed)))))
    (let ((confirmation (reading:service-start-confirmation))
          (evidence (reading:deployment-evidence)))
      (funcall tamper confirmation evidence)
      (assert (handler-case (progn (check-confirmation confirmation evidence) nil)
                (error () t)))))
  (format t "~&SERVICE-START-CONFIRMATION-CONTROLS-PASS: undated confirmation, a superseded command the snapshot never reported, an unlimited supersession and a merge into the snapshot rejected.~%"))

(defun check-preserved-observation-sources ()
  ;; Pin the exact DEFEXAMPLE forms at 548f73d0, including their evidence and
  ;; docstrings. This catches even changes the semantic checks do not cover.
  (let ((source (uiop:read-file-string
                 (asdf:system-relative-pathname "dreyeck/work/reading"
                                                "dreyeck/work/deployment-reading.lisp")))
        (*package* (find-package :dreyeck/work/deployment-reading)))
    (dolist (spec '((reading:deployment-evidence
                    "d1fc93f5008be13d60f03cbf236306e42f0bf3a744f4016811ddb3d99eb794dc")
                   (reading:service-start-confirmation
                    "b210379b8d3c766b3413b6c38f518138472321e29be6cc548af570b6618ff2b7")))
      (let ((start (search (format nil "(hyperdoc:defexample ~A~%"
                                  (string-downcase (symbol-name (first spec))))
                           source)))
        (assert start)
        (let ((tail (subseq source start)))
          (with-input-from-string (stream tail)
            (read-preserving-whitespace stream)
            (assert (equal (second spec)
                           (ironclad:byte-array-to-hex-string
                            (ironclad:digest-sequence
                             :sha256 (babel:string-to-octets
                                      (subseq tail 0 (file-position stream))
                                      :encoding :utf-8))))))))))
  (format t "~&DEPLOYMENT-SOURCES-PRESERVED-PASS: both earlier DEFEXAMPLE forms are byte-for-byte unchanged from 548f73d0.~%"))

(defun check-update-observation (observation)
  (assert (equal (getf observation :provenance)
                 '(:kind :operator-supplied :observation-time "2026-10-03"
                   :recorded-at "2026-10-03" :scope :command-output
                   :host-probe :not-performed)))
  (assert (= 1 (length (getf observation :observed))))
  (let* ((operation (record-by-id observation :observed "dreyeck-update-2026-10-03"))
         (steps (getf operation :steps)))
    (assert (equal "dreyeck.ch" (getf operation :subject)))
    (assert (eq :deployment-operation (getf operation :kind)))
    (assert (eq :update-and-activate (getf operation :operation)))
    (assert (equal "/etc/nixos" (getf operation :directory)))
    ;; Ordered steps retain the input revision transition separately from
    ;; the activation result. Successful activation supplies no ExecStart.
    (assert (= 2 (length steps)))
    (destructuring-bind (update activation) steps
      (assert (eq :flake-input-update (getf update :kind)))
      (assert (equal "nix flake update hyperdoc" (getf update :command)))
      (assert (equal "hyperdoc" (getf update :input)))
      (assert (equal "/etc/nixos/flake.lock" (getf update :lock-file)))
      (assert (equal "384fab636fd2695109aea626b12963cd58bbdcac"
                     (getf update :revision-before)))
      (assert (equal "548f73d09826795cbeaea1eae38da9a4b6e8a9e7"
                     (getf update :revision-after)))
      (assert (eq :nixos-activation (getf activation :kind)))
      (assert (equal "nixos-rebuild switch --flake /etc/nixos#dreyeck"
                     (getf activation :command)))
      (assert (equal "/etc/nixos#dreyeck" (getf activation :flake)))
      (assert (equal '("hyperdoc-catalog") (getf activation :built)))
      (assert (equal '("hyperdoc.service") (getf activation :rebuilt-units)))
      (let* ((result (getf activation :result))
             (transition (getf result :transition)))
        (assert (eq :completed-successfully (getf result :status)))
        (assert (equal '((:kind :service-stop :service "hyperdoc.service")
                         (:kind :configuration-activation :flake "/etc/nixos#dreyeck")
                         (:kind :service-start :service "hyperdoc.service"))
                       transition))
        (dolist (record (append (list operation update activation result) transition))
          (loop for key in '(:exec-start :exec-start-program :working-directory)
                do (assert (not (member key record))))))))
  ;; No inference or current-service-start derivation is added, so this
  ;; observation cannot supersede the confirmation or rewrite the snapshot.
  (dolist (category '(:derived :inferred :hypothesized))
    (assert (member category observation))
    (assert (null (getf observation category))))
  (assert (equal (getf observation :unresolved)
                 '((:subject "dreyeck.ch" :relation :post-activation-verification
                    :status :not-established :basis ("dreyeck-update-2026-10-03")
                    :outside-observation (:exec-start :working-directory :proxy-state
                                          :browser-reachability :application-health)
                    :limit "This update output does not establish the service's ExecStart, WorkingDirectory, proxy state, browser reachability or application-level health after restart; each needs a separate observation."))))
  t)

(defun check-update-controls ()
  (dolist (tamper
           (list
            (lambda (observation)
              (let ((update (first (getf (first (getf observation :observed)) :steps))))
                (rotatef (getf update :revision-before) (getf update :revision-after))))
            (lambda (observation)
              (let ((steps (getf (first (getf observation :observed)) :steps)))
                (setf (getf (second steps) :exec-start) "invented hyperdoc-catalog 8080")))
            (lambda (observation)
              (let* ((operation (first (getf observation :observed)))
                     (result (getf (second (getf operation :steps)) :result)))
                (setf (getf (first (getf observation :observed)) :transition)
                      (getf result :transition))
                (remf result :transition)))))
    (let ((changed (reading:deployment-update-observation)))
      (funcall tamper changed)
      (assert (not (equal changed (reading:deployment-update-observation))))
      (assert (handler-case (progn (check-update-observation changed) nil)
                (error () t)))))
  ;; Controls modify their own copies, not the recorded observation or either
  ;; earlier evidence object.
  (check-update-observation (reading:deployment-update-observation))
  (check-evidence (reading:deployment-evidence))
  (check-confirmation (reading:service-start-confirmation) (reading:deployment-evidence))
  (format t "~&DEPLOYMENT-UPDATE-CONTROLS-PASS: reversed revisions, invented ExecStart and a transition detached from the activation result rejected.~%"))

(defun check-preserved-update-observation-source ()
  ;; Pin the 2026-10-03 DEFEXAMPLE form as it is at fab21433, the commit the
  ;; 2026-10-08 observation was added to, in the same way as the two above.
  (let* ((source (uiop:read-file-string
                  (asdf:system-relative-pathname "dreyeck/work/reading"
                                                 "dreyeck/work/deployment-reading.lisp")))
         (*package* (find-package :dreyeck/work/deployment-reading))
         (start (search (format nil "(hyperdoc:defexample deployment-update-observation~%")
                        source)))
    (assert start)
    (let ((tail (subseq source start)))
      (with-input-from-string (stream tail)
        (read-preserving-whitespace stream)
        (assert (equal "a4e3e853e1c5e8b97b8331f35ad98642d408bdf258b6916d075436e43131de55"
                       (ironclad:byte-array-to-hex-string
                        (ironclad:digest-sequence
                         :sha256 (babel:string-to-octets
                                  (subseq tail 0 (file-position stream))
                                  :encoding :utf-8))))))))
  (format t "~&DEPLOYMENT-UPDATE-SOURCE-PRESERVED-PASS: the 2026-10-03 DEFEXAMPLE form is byte-for-byte unchanged from fab21433.~%"))

;;; The served-state observation of 2026-10-08 is a fourth object. It keeps
;;; the process, the service, the locked source, the store source, the assets
;;; copy, the routes and the listeners apart, and leaves the earlier objects
;;; exactly as they were reported.

(defparameter +served-state-kinds+
  '(:process :service :nixos-generation :flake-input-lock :store-source
    :source-text :assets-copy :fedwiki-page :nginx-route :listener
    :host-boot :checkout :served-catalog :served-route-response))

(defun record-ids (evidence &rest categories)
  (loop for category in categories
        append (remove nil (mapcar (lambda (record) (getf record :id))
                                   (getf evidence category)))))

(defun records-of-kind (evidence kind)
  (remove-if-not (lambda (record) (eq kind (getf record :kind)))
                 (getf evidence :observed)))

(defun check-served-state (observation evidence)
  (let ((facts (getf observation :observed))
        (lock (record-by-id observation :observed "hyperdoc-input-lock"))
        (store (record-by-id observation :observed "hyperdoc-store-source"))
        (service (record-by-id observation :observed "served-service"))
        (assets (record-by-id observation :observed "served-assets-copy"))
        (inference (record-by-id observation :inferred "generation-698-started-service")))
    (assert (equal (getf observation :provenance)
                   '(:kind :operator-supplied :observation-time "2026-10-08T03:29:16Z"
                     :recorded-at "2026-10-08" :scope :read-only-command-output
                     :host-probe :operator-run-read-only
                     :supplements
                     ((:kind :browser-observation :observer "Claude"
                       :observation-time :not-recorded :after "2026-10-08T03:29:16Z"
                       :records ("served-catalog" "view-route-response"))
                      (:kind :content-comparison :where :away-from-host
                       :records ("store-source-is-commit" "assets-copy-content-is-commit"))))))
    (dolist (category '(:observed :derived :inferred :hypothesized :unresolved))
      (assert (member category observation)))
    (assert (null (getf observation :hypothesized)))
    ;; Every record has a declared kind, and each required subject is present
    ;; as its own record.
    (dolist (record facts)
      (assert (member (getf record :kind) +served-state-kinds+)))
    (dolist (kind '(:process :service :flake-input-lock :store-source
                    :assets-copy :nginx-route :listener))
      (assert (records-of-kind observation kind)))
    ;; Observed records state no relation; relations are derived or inferred.
    (dolist (record facts)
      (assert (not (member :relation record))))
    ;; A running process carries no source revision; a service carries none either.
    (dolist (kind '(:process :service))
      (dolist (record (records-of-kind observation kind))
        (dolist (key '(:rev :source-commit :commit :head :nar-hash))
          (assert (not (member key record))))))
    ;; A locked or stored source carries no process identity.
    (dolist (kind '(:flake-input-lock :store-source))
      (dolist (record (records-of-kind observation kind))
        (dolist (key '(:pid :main-pid :ppid :pids))
          (assert (not (member key record))))))
    ;; The assets copy is explicitly unversioned and mutable.
    (assert (member :versioned assets))
    (assert (null (getf assets :versioned)))
    (assert (member :git-checkout assets))
    (assert (null (getf assets :git-checkout)))
    (assert (eq :mutable-copy (getf assets :mutability)))
    (assert (= 12 (length (getf assets :files))))
    ;; The answers this object gives.
    (assert (equal "127.0.0.1:8080"
                   (getf (record-by-id observation :observed "hyperdoc-loopback-listener")
                         :address)))
    (assert (equal "fab214334279bc5d3df0f2f624d34e6a1bdc1897" (getf lock :rev)))
    (assert (equal (getf lock :nar-hash) (getf store :nar-hash)))
    (assert (eq :not-set (getf service :working-directory)))
    (assert (equal "127.0.0.1:8080"
                   (getf (record-by-id observation :observed "apex-route") :upstream)))
    ;; Derived, inferred and unresolved records rest on records of this object.
    (let ((ids (record-ids observation :observed :derived)))
      (dolist (category '(:derived :inferred :unresolved))
        (dolist (record (getf observation category))
          (dolist (id (getf record :basis))
            (assert (member id ids :test #'equal))))))
    ;; Comparisons made away from the host say so.
    (dolist (id '("store-source-is-commit" "assets-copy-content-is-commit"))
      (assert (eq :away-from-host
                  (getf (getf (record-by-id observation :derived id) :computation) :where))))
    (assert (search "not provenance"
                    (getf (record-by-id observation :derived "assets-copy-content-is-commit")
                          :limit)))
    ;; The one inference stays an inference.
    (assert (= 1 (length (getf observation :inferred))))
    (assert (eq :not-directly-observed (getf inference :verification)))
    (assert (not (member (getf inference :id) (record-ids observation :observed :derived)
                         :test #'equal)))
    ;; The earlier snapshot keeps its own answers, and nothing is merged into it.
    (assert (equal "0.0.0.0:8080"
                   (getf (record-by-id evidence :observed "hyperdoc-listener") :address)))
    (record-by-id evidence :inferred "hyperdoc-started-from-checkout")
    (let ((new-ids (record-ids observation :observed :derived :inferred)))
      (dolist (id (record-ids evidence :observed :derived :inferred))
        (assert (not (member id new-ids :test #'equal))))))
  t)

(defun check-served-state-controls ()
  (dolist (tamper
           (list
            (lambda (o)
              (nconc (record-by-id o :observed "served-process")
                     (list :rev "fab214334279bc5d3df0f2f624d34e6a1bdc1897")))
            (lambda (o)
              (nconc (record-by-id o :observed "hyperdoc-store-source")
                     (list :pid 1062025)))
            (lambda (o)
              (let ((record (record-by-id o :observed "served-assets-copy")))
                (setf (getf record :versioned) t)))
            (lambda (o) (push (first (getf o :inferred)) (getf o :observed)))
            (lambda (o)
              (let ((provenance (getf o :provenance)))
                (setf (getf provenance :observation-time) :not-supplied)))))
    (let ((changed (reading:served-state-observation-2026-10-08)))
      (funcall tamper changed)
      (assert (not (equal changed (reading:served-state-observation-2026-10-08))))
      (assert (handler-case
                  (progn (check-served-state changed (reading:deployment-evidence)) nil)
                (error () t)))))
  (check-served-state (reading:served-state-observation-2026-10-08)
                      (reading:deployment-evidence))
  (format t "~&SERVED-STATE-CONTROLS-PASS: a revision on the process, a PID on the store source, a versioned assets copy, a promoted inference and an undated observation rejected.~%"))

(defun run-tests nil (check-preserved-observation-sources)
       (check-preserved-update-observation-source)
       (check-evidence (reading:deployment-evidence)) (check-positive-controls)
       (check-confirmation (reading:service-start-confirmation)
                           (reading:deployment-evidence))
       (check-confirmation-controls)
       (check-update-observation (reading:deployment-update-observation))
       (check-update-controls)
       (check-served-state (reading:served-state-observation-2026-10-08)
                           (reading:deployment-evidence))
       (check-served-state-controls)
       (check-evidence (reading:deployment-evidence))
       (let ((changed (reading:deployment-evidence)))
            (let ((record (record-by-id changed :observed "hyperdoc-service")))
                 (setf (getf record :active-state) "changed"))
            (check-evidence (reading:deployment-evidence)))
       (let*
             ((book
                    (hyperbook:find-hyperbook "dreyeck/work/reading"
                                              :signal-error? t))
              (titles
                      (quote
                             ("Federated Wiki deployment state"
                              "wiki.ralfbarkow.ch deployment"
                              "dreyeck.ch deployment"
                              "Cookie Secret"))))
             (assert (equal "Working on HyperDoc" (hyperbook:title-of book)))
             (assert (equal "Work Breakdown" (hyperbook:main-page-id-of book)))
             (assert
                     (null
                           (hyperbook:find-hyperbook
                                                     "dreyeck/working-on-hyperdoc")))
             (assert
                     (typep
                            (hyperbook:find-page book "Working on HyperDoc"
                                                 :signal-error? t)
                            (quote hyperdoc::code-page)))
             (multiple-value-bind (landing view)
                                  (render-page book "Work Breakdown")
                                  (declare (ignore landing))
                                  (dolist (title titles)
                                          (let*
                                                ((page
                                                       (render-page book
                                                                    title))
                                                 (source
                                                         (uiop:read-file-string
                                                                                (hyperdoc:file-of
                                                                                                  page))))
                                                (assert
                                                        (member page
                                                                (mapcar
                                                                        (function
                                                                                  cdr)
                                                                        (views:view-references
                                                                                               view))
                                                                :test
                                                                (function eq)))
                                                (assert
                                                        (not
                                                             (search
                                                                     "data-topic="
                                                                     source)))
                                                (assert
                                                        (not
                                                             (search
                                                                     "data-from="
                                                                     source))))))
             (multiple-value-bind (page view)
                                  (render-page book
                                               "Federated Wiki deployment state")
                                  (declare (ignore page))
                                  (assert
                                          (member (reading:deployment-evidence)
                                                  (mapcar (function cdr)
                                                          (views:view-references
                                                                                 view))
                                                  :test (function equal))))
             (multiple-value-bind (page view)
                                  (render-page book "dreyeck.ch deployment")
                                  (declare (ignore page))
                                  (let
                                       ((references
                                                    (mapcar (function cdr)
                                                            (views:view-references
                                                                                   view))))
                                       (assert
                                               (member
                                                       (reading:deployment-evidence)
                                                       references :test
                                                       (function equal)))
                                       (assert
                                               (member
                                                       (reading:service-start-confirmation)
                                                       references :test
                                                       (function equal)))
                                       (assert
                                               (member
                                                       (reading:deployment-update-observation)
                                                       references :test
                                                       (function equal)))
                                       (assert
                                               (member
                                                       (reading:served-state-observation-2026-10-08)
                                                       references :test
                                                       (function equal))))
                                  (let ((html (views:view-html view)))
                                       (dolist
                                               (text
                                                     (quote
                                                            ("Which applications serve"
                                                             "Lisp-based HyperDoc"
                                                             "separate Node Federated Wiki farm"
                                                             "28 September"
                                                             "1 October"
                                                             "3 October"
                                                             "8 October"
                                                             "operator supplied command output"
                                                             "Successful activation alone"
                                                             "03:29:16 UTC"
                                                             "127.0.0.1:8080"
                                                             "not a live monitor"
                                                             "did not report its own revision"
                                                             "does not establish who made the copy"
                                                             "wiki.service"
                                                             "newer Wiki declaration")))
                                               (assert (search text html)))))
             (let
                  ((source
                           (uiop:read-file-string
                                                  (hyperdoc:file-of
                                                                    (hyperbook:find-page
                                                                                         book
                                                                                         "Cookie Secret"
                                                                                         :signal-error?
                                                                                         t)))))
                  (assert
                          (search
                                  "Cookie Secret → Session → Session Cookie → wiki-security-friends"
                                  source))
                  (assert
                          (search "b42eb888d6e5d59803667c6320e0779523fc265c"
                                  source)))
             (let ((projection (dreyeck/work/reading:work-projection)))
                  (assert
                          (= 23
                             (length
                                     (dreyeck/topicmap:topicmap-projection-topics-of
                                                                                     projection))))
                  (assert
                          (= 22
                             (length
                                     (dreyeck/topicmap:topicmap-projection-associations-of
                                                                                           projection))))))
       (format t
               "~&WORK-DEPLOYMENT-READING-PASS: preserved snapshot/confirmation, dated update with activation result, page navigation and unchanged Work graph.~%")
       t)
