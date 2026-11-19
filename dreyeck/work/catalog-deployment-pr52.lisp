(defpackage #:dreyeck/work/catalog-deployment-pr52
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views) (#:dita #:dreyeck/dita-story-item)
                    (#:policy #:dreyeck/authority-policy))
  (:export #:make-deployment #:plan-next #:record-receipt #:serve))
(in-package #:dreyeck/work/catalog-deployment-pr52)

(defconstant +pr-number+ 52)
(defparameter +reviewed-head+ "91e8fd65911e687472fb3e30d1574fa5e9119b1b")
(defparameter +github-api+ "https://api.github.com/repos/RalfBarkow/hyperdoc/")
(defvar *planner-lock* (sb-thread:make-mutex :name "PR 52 SHOP3 search"))

(defclass deployment ()
  ((observations :initform nil :accessor observations)
   (command :initform nil :accessor command)
   (message :initform nil :accessor message-of)
   (lock :initform (sb-thread:make-mutex :name "PR 52 deployment") :reader lock-of)))

(defun make-deployment () (make-instance 'deployment))

(shop3:defdomain (catalog-deployment-pr52 :noset t)
  ((:operator (!offer ?step) () () ((offered ?step)))
   (:method (next-deployment-step)
     read-merge ((not (observed :merge))) ((!offer :merge))
     read-baseline ((observed :merge) (not (observed :baseline))) ((!offer :baseline))
     build ((observed :baseline) (not (observed :build))) ((!offer :build))
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

(defun github-json (path)
  (shasht:read-json
   (uiop:run-program (list "curl" "-fsS" "--max-time" "15" "-H" "Accept: application/vnd.github+json"
                           (concatenate 'string +github-api+ path)) :output :string)))

(defun observe-merge ()
  (let* ((pr (github-json (format nil "pulls/~D" +pr-number+)))
         (rev (gethash "merge_commit_sha" pr)))
    (unless (and (equal +reviewed-head+ (gethash "sha" (gethash "head" pr)))
                 (equal "dreyeck.ch" (gethash "ref" (gethash "base" pr)))
                 (gethash "merged_at" pr) (stringp (gethash "merged_at" pr)) (hex-revision-p rev))
      (error "PR #52 muss mit dem geprüften HEAD in dreyeck.ch gemergt sein."))
    (unless (equal rev (gethash "sha" (gethash "commit" (github-json "branches/dreyeck.ch"))))
      (error "Der aktuelle dreyeck.ch-HEAD weicht vom Merge ab. Prüfe die zusätzlichen Änderungen."))
    (list rev +reviewed-head+)))

(defun target-revision (deployment)
  (second (assoc :merge (observations deployment))))

(defun server-command (deployment step)
  (let ((script (asdf:system-relative-pathname "dreyeck/work/catalog-deployment-pr52"
                                             "dreyeck/work/catalog-deployment-pr52.sh"))
        (dir (third (assoc :baseline (observations deployment)))))
    (format nil "bash -s -- ~A '~A'~@[ '~A'~] <<'HYPERDOC_PR52'~%~AHYPERDOC_PR52~%"
            (string-downcase (symbol-name step)) (target-revision deployment) dir
            (uiop:read-file-string script :external-format :utf-8))))

(defun play-step (deployment step)
  (sb-thread:with-mutex ((lock-of deployment))
    (handler-case
        (progn
          (unless (eq step (offered-step (plan-next deployment)))
            (error "Dieses Angebot ist veraltet. Aktualisiere das Pane."))
          (if (eq step :merge)
              (push (cons step (observe-merge)) (observations deployment))
              (setf (command deployment) (server-command deployment step)))
          (setf (message-of deployment) nil))
      (error (condition) (setf (message-of deployment) (princ-to-string condition)))))
  deployment)

(defun record-receipt (deployment evidence)
  "Record operator readback. Evidence is Lisp data, never an executable form."
  (sb-thread:with-mutex ((lock-of deployment))
    (destructuring-bind (step revision dir path &rest extra) evidence
      (let ((baseline (assoc :baseline (observations deployment)))
            (build (assoc :build (observations deployment))))
        (unless (and (command deployment) (eq step (offered-step (plan-next deployment)))
                     (equal revision (target-revision deployment))
                     (receipt-path-p dir) (system-path-p path)
                     (or (eq step :baseline) (equal dir (third baseline)))
                     (ecase step
                       (:baseline (and (= (length extra) 1) (hex-revision-p (first extra))))
                       (:build (null extra))
                       (:activate (and (null extra) (equal path (fourth build))))
                       (:verify (and (equal path (fourth build)) (= (length extra) 3)
                                     (typep (first extra) '(integer 1))
                                     (equal (rest extra) '(200 200))))))
          (error "Serverbeleg passt nicht zum angebotenen Schritt, zur Revision oder zum Systempfad."))
        (push (copy-tree evidence) (observations deployment))
        (setf (command deployment) nil (message-of deployment) nil))))
  (plan-next deployment))

(policy:register-reviewed-control "catalog-deployment-pr52/play"
  :effect "Reads public GitHub merge metadata or prepares an operator-owned shell command."
  :audit "PLAY-STEP checks the offered SHOP3 step before OBSERVE-MERGE or SERVER-COMMAND.")

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
          (v:html (v:str (subseq html 0 offset)) " "
                  (v:eval-button "Play" (policy:reviewed-thunk "catalog-deployment-pr52/play" (play-step deployment step))
                                 "SHOP3-Angebot ausführen")
                  (v:str (subseq html (+ offset (length marker)))))
          (v:html (v:str html))))))

(v:defview deployment-task (deployment deployment)
  (v:html-view :title "DITA Task" :priority -100
    (let* ((plan (plan-next deployment)) (step (offered-step plan)))
      (v:html (:p (v:object-ref plan :display "Nativer SHOP3-Plan") " · "
                  (v:esc (format nil "~S" (or step :complete))))
              (:p (:a :href "https://github.com/RalfBarkow/hyperdoc/pull/52" "PR #52"))
              (render-task deployment step)
              (when (message-of deployment) (v:html (:p (v:esc (message-of deployment)))))
              (when (command deployment)
                (v:html (:h3 "Befehl für die administrative Bash auf dreyeck.ch")
                        (:pre :style "white-space:pre-wrap" (v:esc (command deployment)))
                        (:p "Übernimm die abschliessende Belegliste in das mREPL mit RECORD-RECEIPT.")))
              (:h3 "Beobachtungen")
              (:pre (v:esc (format nil "~S" (reverse (observations deployment)))))))))

(defun serve (deployment &key (port 18752))
  "Open the local operator task in a fresh SLY image."
  (assert (not (clog:is-running-p)))
  (clog:initialize (lambda (body) (clog-moldable-inspector:on-new-inspector
                                   body :object deployment :pane-width "850px"))
                   :host "127.0.0.1" :port port)
  (format nil "http://127.0.0.1:~D/" port))
