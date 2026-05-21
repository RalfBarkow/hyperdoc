;;;; Kioskberrli DITA-style task topics

(in-package #:kioskberrli)

(defun %stringify (value)
  (if (stringp value)
      value
      (princ-to-string value)))

(defclass kioskbeerli-dita-task-step ()
  ((number :initarg :number :reader kioskbeerli-task-step-number-of)
   (description :initarg :description :reader kioskbeerli-task-step-description-of)
   (command :initarg :command :initform nil :reader kioskbeerli-task-step-command-of)
   (note :initarg :note :initform nil :reader kioskbeerli-task-step-note-of)))

(defclass kioskbeerli-dita-task-topic ()
  ((id :initarg :id :reader kioskbeerli-task-topic-id-of)
   (title :initarg :title :reader kioskbeerli-task-topic-title-of)
   (shortdesc :initarg :shortdesc :reader kioskbeerli-task-topic-shortdesc-of)
   (context :initarg :context :reader kioskbeerli-task-topic-context-of)
   (prerequisites :initarg :prerequisites :initform nil :reader kioskbeerli-task-topic-prerequisites-of)
   (steps :initarg :steps :initform nil :reader kioskbeerli-task-topic-steps-of)
   (result :initarg :result :reader kioskbeerli-task-topic-result-of)
   (postrequisites :initarg :postrequisites :initform nil :reader kioskbeerli-task-topic-postrequisites-of)
   (official-docs :initarg :official-docs :initform nil :reader kioskbeerli-task-topic-official-docs-of)
   (prerequisite-task-id :initarg :prerequisite-task-id :initform :boot-pi
                         :reader kioskbeerli-task-topic-prerequisite-task-id-of)
   (plan-task-id :initarg :plan-task-id :initform :verify-network
                 :reader kioskbeerli-task-topic-plan-task-id-of)
   (evidence-status :initarg :evidence-status :initform :missing-evidence
                    :reader kioskbeerli-task-topic-evidence-status-of)
   (scxml-event :initarg :scxml-event :initform "NETWORK_OK"
                :reader kioskbeerli-task-topic-scxml-event-of)
   (scxml-state :initarg :scxml-state :initform "network-verified"
                :reader kioskbeerli-task-topic-scxml-state-of)))

(defmethod print-object ((topic kioskbeerli-dita-task-topic) stream)
  (print-unreadable-object (topic stream :type t)
    (format stream "~A: ~A"
            (kioskbeerli-task-topic-id-of topic)
            (kioskbeerli-task-topic-evidence-status-of topic))))

(defmethod print-object ((step kioskbeerli-dita-task-step) stream)
  (print-unreadable-object (step stream :type t)
    (format stream "~D: ~A"
            (kioskbeerli-task-step-number-of step)
            (kioskbeerli-task-step-description-of step))))

(defun %task-step (number description &key command note)
  (make-instance 'kioskbeerli-dita-task-step
                 :number number
                 :description description
                 :command command
                 :note note))

(defun %doc (label url)
  (cons label url))

(defun kioskbeerli-semi-headless-set-password-task ()
  "DITA-style task topic for setting the temporary nixos password."
  (make-instance
   'kioskbeerli-dita-task-topic
   :id "kioskbeerli-semi-headless-set-password"
   :title "Set the temporary nixos SSH password during semi-headless bootstrap"
   :shortdesc "Use the local Pi console once to set a password for user nixos so SSH login can proceed."
   :context "The Pi has booted from the flashed NixOS SD image. The operator is logged in locally as user nixos. SSH from another machine asks for a password, but no password is known yet. This is a semi-headless bootstrap bridge, not proof of fully unattended first boot."
   :prerequisites
   '("Local HDMI/keyboard console access to the running Raspberry Pi."
     "The operator is already logged in locally as user nixos."
     "The boot-pi planner task has evidence.")
   :steps
   (list
    (%task-step 1 "Confirm that the local console session is user nixos."
                :command "whoami")
    (%task-step 2 "Set a temporary bootstrap password for user nixos."
                :command "sudo passwd nixos"
                :note "Type the new password twice. Nothing is displayed while typing.")
    (%task-step 3 "Confirm whether the SSH daemon is active."
                :command "systemctl is-active sshd")
    (%task-step 4 "If sshd is inactive, enable OpenSSH and temporary password authentication declaratively in /etc/nixos/configuration.nix."
                :command "services.openssh.enable = true;
services.openssh.settings.PasswordAuthentication = true;")
    (%task-step 5 "Build the next boot generation instead of silently mutating the running session."
                :command "sudo nixos-rebuild boot")
    (%task-step 6 "Reboot into the new generation."
                :command "sudo reboot")
    (%task-step 7 "From the maintenance machine, retry SSH login."
                :command "ssh nixos@<PI-IP-ADDRESS>"))
   :result "SSH login as nixos succeeds from the maintenance machine."
   :postrequisites
   '("Record verify-network evidence only after SSH login actually succeeds."
     "Replace temporary password authentication with authorized-key login after the bridge is confirmed."
     "Do not mark verify-kiosk-session or verify-landing-page from SSH evidence alone.")
   :official-docs
   (list
    (%doc "NixOS manual: changing configuration"
          "https://nixos.org/manual/nixos/stable/#sec-changing-config")
    (%doc "NixOS manual: switching systems / rebuilds"
          "https://nixos.org/manual/nixos/stable/#sec-switching-systems")
    (%doc "NixOS option: services.openssh.enable"
          "https://search.nixos.org/options?query=services.openssh.enable")
    (%doc "NixOS option: services.openssh.settings.PasswordAuthentication"
          "https://search.nixos.org/options?query=services.openssh.settings.PasswordAuthentication")
    (%doc "NixOS user options"
          "https://search.nixos.org/options?query=users.users.%3Cname%3E"))
   :prerequisite-task-id :boot-pi
   :plan-task-id :verify-network
   :evidence-status :missing-evidence
   :scxml-event "NETWORK_OK"
   :scxml-state "network-verified"))

(defun kioskbeerli-lookup-task-topic (id &key (errorp t))
  (let ((normalized (string-downcase (string id))))
    (cond
      ((member normalized
               '("kioskbeerli-semi-headless-set-password"
                 "kioskberrli-semi-headless-set-password"
                 "semi-headless-set-password"
                 "set-password"
                 "set-temporary-nixos-password")
               :test #'string=)
       (kioskbeerli-semi-headless-set-password-task))
      (errorp
       (error "Unknown Kioskberrli task topic: ~S" id))
      (t nil))))

(defun %safe-plan-task (task-id)
  (when task-id
    (handler-case
        (kioskbeerli-lookup-plan-task task-id)
      (error (e)
        (list :unavailable-plan-task task-id :error (princ-to-string e))))))

(defun %safe-task-progress (task)
  (when (and task
             (not (and (consp task)
                       (eq (first task) :unavailable-plan-task))))
    (handler-case
        (kioskbeerli-task-progress task)
      (error (e)
        (list :unavailable-progress :error (princ-to-string e))))))

(defun %safe-task-state-link (task)
  (when (and task
             (not (and (consp task)
                       (eq (first task) :unavailable-plan-task))))
    (handler-case
        (kioskbeerli-task-state-link task)
      (error (e)
        (list :unavailable-state-link :error (princ-to-string e))))))

(defun kioskbeerli-task-topic-prerequisite-plan-task (topic)
  (%safe-plan-task (kioskbeerli-task-topic-prerequisite-task-id-of topic)))

(defun kioskbeerli-task-topic-plan-task (topic)
  (%safe-plan-task (kioskbeerli-task-topic-plan-task-id-of topic)))

(defun kioskbeerli-task-topic-progress (topic)
  (let* ((prereq-task (kioskbeerli-task-topic-prerequisite-plan-task topic))
         (plan-task (kioskbeerli-task-topic-plan-task topic)))
    (list
     :topic topic
     :prerequisite-task prereq-task
     :prerequisite-progress (%safe-task-progress prereq-task)
     :plan-task plan-task
     :plan-task-progress (%safe-task-progress plan-task)
     :evidence-status (kioskbeerli-task-topic-evidence-status-of topic)
     :boundary "verify-network remains missing-evidence until SSH login succeeds")))

(defun kioskbeerli-task-topic-state-link (topic)
  (let ((plan-task (kioskbeerli-task-topic-plan-task topic)))
    (or (%safe-task-state-link plan-task)
        (list :task-topic (kioskbeerli-task-topic-id-of topic)
              :plan-task-id (kioskbeerli-task-topic-plan-task-id-of topic)
              :scxml-event (kioskbeerli-task-topic-scxml-event-of topic)
              :scxml-state (kioskbeerli-task-topic-scxml-state-of topic)
              :status "state link is declarative until progress evidence is recorded"))))

(defun %xml-escape (value)
  (with-output-to-string (out)
    (loop for ch across (%stringify value)
          do (case ch
               (#\< (write-string "&lt;" out))
               (#\> (write-string "&gt;" out))
               (#\& (write-string "&amp;" out))
               (#\" (write-string "&quot;" out))
               (#\' (write-string "&apos;" out))
               (otherwise (write-char ch out))))))

(defun kioskbeerli-task-topic-dita-view
    (&optional (topic (kioskbeerli-semi-headless-set-password-task)))
  (with-output-to-string (out)
    (format out "<task id=\"~A\">~%" (%xml-escape (kioskbeerli-task-topic-id-of topic)))
    (format out "  <title>~A</title>~%" (%xml-escape (kioskbeerli-task-topic-title-of topic)))
    (format out "  <shortdesc>~A</shortdesc>~%" (%xml-escape (kioskbeerli-task-topic-shortdesc-of topic)))
    (format out "  <taskbody>~%")
    (format out "    <context>~A</context>~%" (%xml-escape (kioskbeerli-task-topic-context-of topic)))
    (format out "    <prereq>~%")
    (dolist (p (kioskbeerli-task-topic-prerequisites-of topic))
      (format out "      <p>~A</p>~%" (%xml-escape p)))
    (format out "    </prereq>~%")
    (format out "    <steps>~%")
    (dolist (step (kioskbeerli-task-topic-steps-of topic))
      (format out "      <step>~%")
      (format out "        <cmd>~A</cmd>~%" (%xml-escape (kioskbeerli-task-step-description-of step)))
      (when (kioskbeerli-task-step-command-of step)
        (format out "        <codeblock>~A</codeblock>~%"
                (%xml-escape (kioskbeerli-task-step-command-of step))))
      (when (kioskbeerli-task-step-note-of step)
        (format out "        <info>~A</info>~%" (%xml-escape (kioskbeerli-task-step-note-of step))))
      (format out "      </step>~%"))
    (format out "    </steps>~%")
    (format out "    <result>~A</result>~%" (%xml-escape (kioskbeerli-task-topic-result-of topic)))
    (format out "    <postreq>~%")
    (dolist (p (kioskbeerli-task-topic-postrequisites-of topic))
      (format out "      <p>~A</p>~%" (%xml-escape p)))
    (format out "    </postreq>~%")
    (format out "  </taskbody>~%")
    (format out "</task>~%")))

(defun %clog-inspect (object)
  (let* ((pkg (find-package "CLOG-MOLDABLE-INSPECTOR"))
         (sym (and pkg (find-symbol "CLOG-INSPECT" pkg))))
    (unless (and sym (fboundp sym))
      (error "CLOG-MOLDABLE-INSPECTOR:CLOG-INSPECT is not available. Load :hyperdoc/server first."))
    (funcall sym :object object)))

(defun kioskbeerli-open-semi-headless-password-task-inspector ()
  (%clog-inspect (kioskbeerli-semi-headless-set-password-task)))

(defun kioskberrli-semi-headless-set-password-task ()
  (kioskbeerli-semi-headless-set-password-task))

(defun kioskberrli-lookup-task-topic (id &key (errorp t))
  (kioskbeerli-lookup-task-topic id :errorp errorp))

(defun kioskberrli-task-topic-plan-task (topic)
  (kioskbeerli-task-topic-plan-task topic))

(defun kioskberrli-task-topic-progress (topic)
  (kioskbeerli-task-topic-progress topic))

(defun kioskberrli-task-topic-state-link (topic)
  (kioskbeerli-task-topic-state-link topic))

(defun kioskberrli-task-topic-dita-view (&optional topic)
  (if topic
      (kioskbeerli-task-topic-dita-view topic)
      (kioskbeerli-task-topic-dita-view)))

(defun kioskberrli-open-semi-headless-password-task-inspector ()
  (kioskbeerli-open-semi-headless-password-task-inspector))

;;; Inspector views

(defclass kioskbeerli-dita-task-view (html-inspector-views:html-view)
  ())

(defmethod html-inspector-views:text-representation
    ((topic kioskbeerli-dita-task-topic))
  (format nil "DITA task: ~A"
          (kioskbeerli-task-topic-title-of topic)))

(defmethod html-inspector-views:text-representation
    ((step kioskbeerli-dita-task-step))
  (format nil "Step ~D: ~A"
          (kioskbeerli-task-step-number-of step)
          (kioskbeerli-task-step-description-of step)))

(defun %task-topic-docs-text (topic)
  (with-output-to-string (out)
    (dolist (doc (kioskbeerli-task-topic-official-docs-of topic))
      (format out "~A~%~A~%~%"
              (car doc)
              (cdr doc)))))

(defun %task-topic-steps-text (topic)
  (with-output-to-string (out)
    (dolist (step (kioskbeerli-task-topic-steps-of topic))
      (format out "~D. ~A~%"
              (kioskbeerli-task-step-number-of step)
              (kioskbeerli-task-step-description-of step))
      (when (kioskbeerli-task-step-command-of step)
        (format out "~A~%" (kioskbeerli-task-step-command-of step)))
      (when (kioskbeerli-task-step-note-of step)
        (format out "Note: ~A~%" (kioskbeerli-task-step-note-of step)))
      (terpri out))))

(html-inspector-views:defview kioskbeerli-dita-task-view
    (topic kioskbeerli-dita-task-topic)
  (make-instance
   'kioskbeerli-dita-task-view
   :html nil
   :references nil
   :assets nil
   :create-html
   (html-inspector-views:thunk
    (html-inspector-views:html-and-references
     (html-inspector-views:html
       (:div :class "kioskbeerli-dita-task"
        (:h2 (html-inspector-views:esc
              (%stringify (kioskbeerli-task-topic-title-of topic))))
        (:p
         (:strong "Short description: ")
         (html-inspector-views:esc
          (%stringify (kioskbeerli-task-topic-shortdesc-of topic))))
        (:h3 "Context")
        (:p (html-inspector-views:esc
             (%stringify (kioskbeerli-task-topic-context-of topic))))
        (:h3 "Prerequisites")
        (:pre
         (:code
          (html-inspector-views:esc
           (%stringify (format nil "~{~A~%~}"
                               (kioskbeerli-task-topic-prerequisites-of topic))))))
        (:h3 "Steps")
        (:pre
         (:code
          (html-inspector-views:esc
           (%stringify (%task-topic-steps-text topic)))))
        (:h3 "Expected result")
        (:p (html-inspector-views:esc
             (%stringify (kioskbeerli-task-topic-result-of topic))))
        (:h3 "Postrequisites")
        (:pre
         (:code
          (html-inspector-views:esc
           (%stringify (format nil "~{~A~%~}"
                               (kioskbeerli-task-topic-postrequisites-of topic))))))))))
   :title "DITA Task"
   :priority 1))

(defmethod html-inspector-views:view-specification
    ((view kioskbeerli-dita-task-view)
     (topic kioskbeerli-dita-task-topic))
  (make-instance
   'html-inspector-views:inspector-view-specification
   :view-id "kioskbeerli-dita-task-view"
   :view-title (html-inspector-views:view-title view)
   :subject-type 'kioskbeerli-dita-task-topic
   :reader-question
   "What should the operator do next, and what evidence proves completion?"
   :content-model
   '(:title :shortdesc :context :prerequisites :steps
     :expected-result :postrequisites :evidence)
   :box-contract
   '((:root-box
      :class "kioskbeerli-dita-task"
      :display :block
      :inline-size :available
      :block-size :auto
      :max-inline-size "100%"
      :overflow :auto)
     (:prose-boxes
      :content (:title :shortdesc :context :expected-result)
      :inline-size :available
      :max-inline-size "100%"
      :overflow-wrap :anywhere
      :margin-block :reader-rhythm)
     (:steps-list-boxes
      :content (:prerequisites :steps :postrequisites)
      :display :block
      :list-style :ordered
      :inline-size :available
      :max-inline-size "100%")
     (:code-boxes
      :content (:commands :configuration-snippets)
      :display :block
      :inline-size :available
      :max-inline-size "100%"
      :overflow :auto
      :white-space :pre-wrap
      :padding-inline :reader-rhythm))
   :priority-policy
   '(:mobile-primary t
     :operator-task-primary t
     :technical-secondary (:slots :print :operations)
     :short-title "Task")
   :actions
   '((:inspect-plan-task :navigation-only)
     (:inspect-progress :navigation-only)
     (:inspect-state-link :navigation-only)
     (:record-evidence :descriptive-only :external-mutation-not-performed))
   :evidence
   '((:layout-snapshot :missing-evidence)
     (:design-reference "DMX topic 978985")
     (:safety-boundary
      "This contract performs no SSH, build, flash, HTTP, DMX write, or device mutation."))
   :failure-modes
   '(:preformatted-prose
     :horizontal-overflow
     :title-bar-domination
     :hidden-affordance
     :missing-evidence
     :missing-layout-snapshot)))

(html-inspector-views:defview kioskbeerli-plan-progress-state-view
    (topic kioskbeerli-dita-task-topic)
  (html-inspector-views:html-view
      :title "Plan / Progress / State"
      :priority 2
    (let ((prereq-task (kioskbeerli-task-topic-prerequisite-plan-task topic))
          (plan-task (kioskbeerli-task-topic-plan-task topic))
          (progress (kioskbeerli-task-topic-progress topic))
          (state-link (kioskbeerli-task-topic-state-link topic)))
      (html-inspector-views:html
        (:table :class "inspector-table"
         (:tr
          (:td "Topic id")
          (:td (:code
                (html-inspector-views:esc
                 (%stringify (kioskbeerli-task-topic-id-of topic))))))
         (:tr
          (:td "Prerequisite plan task")
          (:td (html-inspector-views:object-ref prereq-task)))
         (:tr
          (:td "Related plan task")
          (:td (html-inspector-views:object-ref plan-task)))
         (:tr
          (:td "Evidence status")
          (:td (:code
                (html-inspector-views:esc
                 (%stringify (kioskbeerli-task-topic-evidence-status-of topic))))))
         (:tr
          (:td "SCXML event after evidence")
          (:td (:code
                (html-inspector-views:esc
                 (%stringify (kioskbeerli-task-topic-scxml-event-of topic))))))
         (:tr
          (:td "SCXML state after evidence")
          (:td (:code
                (html-inspector-views:esc
                 (%stringify (kioskbeerli-task-topic-scxml-state-of topic))))))
         (:tr
          (:td "Progress lookup")
          (:td (html-inspector-views:object-ref progress)))
         (:tr
          (:td "State link")
          (:td (html-inspector-views:object-ref state-link))))
        (:p :style "margin-top: 1em;"
            (:strong "Boundary: ")
            "This task does not verify the network until SSH login as nixos actually succeeds. It also does not verify the kiosk session or landing page.")))))

(html-inspector-views:defview kioskbeerli-official-docs-view
    (topic kioskbeerli-dita-task-topic)
  (html-inspector-views:html-view
      :title "Official docs"
      :priority 3
    (html-inspector-views:html
      (:h3 "Official NixOS docs/options")
      (:pre
       (:code
        (html-inspector-views:esc
         (%stringify (%task-topic-docs-text topic))))))))

(html-inspector-views:defview kioskbeerli-dita-xml-view
    (topic kioskbeerli-dita-task-topic)
  (html-inspector-views:html-view
      :title "DITA XML"
      :priority 4
    (html-inspector-views:html
      (:pre
       (:code
        (html-inspector-views:esc
         (%stringify (kioskbeerli-task-topic-dita-view topic)))))))

)
