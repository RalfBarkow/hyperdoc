;;;; Source-grounded term senses for Simon, Formen (2018), chapters 1--3.

(in-package :hyperdoc)

(defparameter +source-grounded-function-forms+
  '(:change :preservation :undetermined))

(defparameter +source-grounded-crossing-directions+
  '(:outside-to-inside :inside-to-outside))

(defparameter +source-grounded-temporal-dimensions+
  '(:event-duration :process-duration :effect-durability))

(defparameter +source-grounded-observation-roles+
  '(:operation-performer
    :operation-carrier
    :observed-referent
    :recording-system
    :attributing-observer
    :addressed-observer
    :responsible-actor))

(defclass source-grounded-term-sense (topic)
  ((source-term
    :accessor source-grounded-term-sense-source-term-of
    :initarg :source-term)
   (domain
    :accessor source-grounded-term-sense-domain-of
    :initarg :domain)
   (source-wording
    :accessor source-grounded-term-sense-source-wording-of
    :initarg :source-wording
    :initform nil)
   (normalized-sense
    :accessor source-grounded-term-sense-normalized-sense-of
    :initarg :normalized-sense)
   (source-reference
    :accessor source-grounded-term-sense-source-reference-of
    :initarg :source-reference)
   (definition-status
    :accessor source-grounded-term-sense-definition-status-of
    :initarg :definition-status)
   (technical-homonym-ids
    :accessor source-grounded-term-sense-technical-homonym-ids-of
    :initarg :technical-homonym-ids
    :initform nil)
   (temporal-dimensions
    :accessor source-grounded-term-sense-temporal-dimensions-of
    :initarg :temporal-dimensions
    :initform nil)
   (controlled-derivations
    :accessor source-grounded-term-sense-controlled-derivations-of
    :initarg :controlled-derivations
    :initform nil)
   (application-hypotheses
    :accessor source-grounded-term-sense-application-hypotheses-of
    :initarg :application-hypotheses
    :initform nil)
   (open-interpretation-questions
    :accessor source-grounded-term-sense-open-interpretation-questions-of
    :initarg :open-interpretation-questions
    :initform nil)))

(defun source-grounded-function-form-p (value)
  (not (null (member value +source-grounded-function-forms+))))

(defun source-grounded-crossing-direction-p (value)
  (not (null (member value +source-grounded-crossing-directions+))))

(defun source-grounded-temporal-dimension-p (value)
  (not (null (member value +source-grounded-temporal-dimensions+))))

(defun source-grounded-observation-role-p (value)
  (not (null (member value +source-grounded-observation-roles+))))

(defun source-grounded-role-value (role roles)
  (cdr (assoc role roles)))

(defun make-source-grounded-operation-observation
    (&key observed-referent
          boundary
          (before nil before-supplied-p)
          (after nil after-supplied-p)
          crossing-direction
          evidence)
  "Describe a Simon-operation hypothesis without classifying a bare state change."
  (unless observed-referent
    (error "A Simon-operation hypothesis needs an observed referent."))
  (unless boundary
    (error "A Simon-operation hypothesis needs a reconstructed hypothetical boundary."))
  (unless before-supplied-p
    (error "A Simon-operation hypothesis needs an explicit before observation."))
  (unless after-supplied-p
    (error "A Simon-operation hypothesis needs an explicit after observation."))
  (unless (source-grounded-crossing-direction-p crossing-direction)
    (error "A Simon-operation hypothesis needs crossing direction ~S, not ~S."
           +source-grounded-crossing-directions+
           crossing-direction))
  (list :kind :simon-operation-observation
        :observed-referent observed-referent
        :boundary boundary
        :before before
        :after after
        :crossing-direction crossing-direction
        :evidence evidence))

(defun make-source-grounded-function-attribution
    (&key function-form observed-referent attributing-observer evidence)
  "Attribute a concrete effect without confusing it with a Lisp function."
  (unless (source-grounded-function-form-p function-form)
    (error "Function form must be one of ~S, not ~S."
           +source-grounded-function-forms+
           function-form))
  (unless observed-referent
    (error "A function attribution needs an observed referent."))
  (unless attributing-observer
    (error "A function attribution needs an attributing observer."))
  (list :kind :function-attribution
        :function-form function-form
        :observed-referent observed-referent
        :attributing-observer attributing-observer
        :evidence evidence))

(defun make-source-grounded-temporal-profile
    (&key (event-duration nil event-duration-supplied-p)
          (process-duration nil process-duration-supplied-p)
          (effect-durability nil effect-durability-supplied-p))
  "Keep event duration, process duration, and effect durability separate."
  (append (when event-duration-supplied-p
            (list :event-duration event-duration))
          (when process-duration-supplied-p
            (list :process-duration process-duration))
          (when effect-durability-supplied-p
            (list :effect-durability effect-durability))))

(defun make-source-grounded-process-description
    (&key operations temporal-order coupling-criterion evidence)
  "Describe a process while preserving simultaneous or partial order."
  (unless operations
    (error "A process description needs at least one operation."))
  (unless temporal-order
    (error "A process description needs an explicit temporal order."))
  (unless coupling-criterion
    (error "A process description needs an explicit coupling criterion."))
  (list :kind :simon-process-description
        :operations operations
        :temporal-order temporal-order
        :coupling-criterion coupling-criterion
        :evidence evidence))

(defun make-source-grounded-application-hypothesis
    (&key id sense-ids operation-observation function-attribution
          process-description temporal-profile roles evidence)
  "Record a controlled application without presenting it as source wording."
  (unless (and (stringp id) (plusp (length id)))
    (error "An application hypothesis needs a non-empty string id."))
  (dolist (entry roles)
    (unless (and (consp entry)
                 (source-grounded-observation-role-p (car entry)))
      (error "Unknown source-grounded observation role: ~S" entry)))
  (unless (source-grounded-role-value :observed-referent roles)
    (error "An application hypothesis must expose its observed referent."))
  (unless (source-grounded-role-value :attributing-observer roles)
    (error "An application hypothesis must expose its attributing observer."))
  (list :kind :application-hypothesis
        :id id
        :sense-ids sense-ids
        :operation-observation operation-observation
        :function-attribution function-attribution
        :process-description process-description
        :temporal-profile temporal-profile
        :roles roles
        :evidence evidence))

(defun %source-grounded-reference
    (&key chapter section page page-status)
  (append (list :author "Fritz B. Simon"
                :work "Formen"
                :year 2018
                :chapter chapter
                :section section
                :page page
                :verification-kind :human-review-of-direct-page-scan
                :wording-status :normalized-paraphrase)
          (when page-status
            (list :page-status page-status))))

(defun %repository-contract-reference (pathname &key symbol)
  (append (list :source-kind :repository-contract
                :pathname pathname)
          (when symbol (list :symbol symbol))))

(defun %simon-sense-spec
    (id title summary source-term normalized-sense chapter section page
     &key page-status technical-homonym-ids temporal-dimensions
       controlled-derivations application-hypotheses
       open-interpretation-questions)
  (list :id id
        :title title
        :summary summary
        :references '("Operation, Funktion und Prozess bei Simon (2018)")
        :source-term source-term
        :domain :simon-2018-formen
        :source-wording nil
        :normalized-sense normalized-sense
        :source-reference (%source-grounded-reference
                           :chapter chapter
                           :section section
                           :page page
                           :page-status page-status)
        :definition-status :normalized-source-sense
        :technical-homonym-ids technical-homonym-ids
        :temporal-dimensions temporal-dimensions
        :controlled-derivations controlled-derivations
        :application-hypotheses application-hypotheses
        :open-interpretation-questions open-interpretation-questions))

(defun %technical-sense-spec
    (id title summary source-term normalized-sense pathname
     &key symbol technical-homonym-ids)
  (list :id id
        :title title
        :summary summary
        :references '("Operation, Funktion und Prozess bei Simon (2018)")
        :source-term source-term
        :domain :technical-homonym
        :source-wording nil
        :normalized-sense normalized-sense
        :source-reference (%repository-contract-reference pathname :symbol symbol)
        :definition-status :technical-contract
        :technical-homonym-ids technical-homonym-ids
        :temporal-dimensions nil
        :controlled-derivations nil
        :application-hypotheses nil
        :open-interpretation-questions nil))

(defparameter *simon-runtime-coherence-application-hypothesis*
  (make-source-grounded-application-hypothesis
   :id "hyperdoc:runtime-coherence-as-application-hypothesis"
   :sense-ids '("simon-2018:1.2:observer"
                "simon-2018:2.5:boundary"
                "simon-2018:3.1:operation"
                "simon-2018:3.2:function-of-operation")
   :operation-observation
   (make-source-grounded-operation-observation
    :observed-referent "one runtime-coherence dimension"
    :boundary "running Lisp image / recorded coherence report"
    :before "the probe has not yet recorded this dimension"
    :after "the report contains the probe result for this dimension"
    :crossing-direction :inside-to-outside
    :evidence '(:application-source "hyperdoc/runtime-coherence.lisp"))
   :function-attribution
   (make-source-grounded-function-attribution
    :function-form :change
    :observed-referent "the runtime-coherence report"
    :attributing-observer "human reviewer or operator"
    :evidence '(:application-status :hypothesis))
   :roles '((:operation-performer . "runtime-coherence probe function")
            (:operation-carrier . "running Lisp image")
            (:observed-referent . "one coherence dimension")
            (:recording-system . "runtime-coherence-report")
            (:attributing-observer . "human reviewer or operator")
            (:addressed-observer . "reader of the report")
            (:responsible-actor . "human operator"))
   :evidence '(:classification :application-hypothesis
               :not-a-source-quotation t)))

(defparameter *simon-formen-term-sense-specs*
  (list
   (%simon-sense-spec
    "simon-2018:1.2:observer"
    "Beobachter bei Simon (2018), 1.2"
    "Der Beobachter wird über den Vollzug einer bestimmten Beobachtungsoperation bestimmt."
    "Beobachter"
    "Wer oder was die spezifische Operation des Beobachtens vollzieht."
    1 "1.2" 13)
   (%simon-sense-spec
    "simon-2018:1.3:second-order-observing"
    "Beobachtung zweiter Ordnung bei Simon (2018), 1.3"
    "Beobachtung zweiter Ordnung beobachtet eine Beobachtung."
    "Beobachtung zweiter Ordnung"
    "Beobachten einer Beobachtung, ohne dafür einen anderen allgemeinen Operationstyp einzuführen."
    1 "1.3" 13
    :controlled-derivations
    '((:id "simon-2018:1.3:recursive-applicability"
       :source-ids ("simon-2018:1.3:second-order-observing")
       :statement "Allgemeine Bestimmungen des Beobachtens bleiben auf das Beobachten von Beobachtungen anwendbar.")))
   (%simon-sense-spec
    "simon-2018:1.4:reflexive-observation"
    "Reflexive Beobachtung bei Simon (2018), 1.4"
    "Eine Beschreibung von Beobachtung beobachtet selbst Beobachtung."
    "reflexive Beobachtung"
    "Eine Darstellung, die Beobachtung beschreibt, vollzieht selbst Beobachtung zweiter Ordnung."
    1 "1.4" 13
    :technical-homonym-ids '("hyperdoc:event-record"))
   (%simon-sense-spec
    "simon-2018:2.1:observing"
    "Beobachten bei Simon (2018), 2.1"
    "Beobachten koppelt Unterscheiden und Bezeichnen."
    "Beobachten"
    "Kopplung der Operationen Unterscheiden und Bezeichnen."
    2 "2.1" nil
    :page-status :not-recorded-in-current-slice
    :controlled-derivations
    '((:id "simon-2018:2.1:coupling-dependency"
       :source-ids ("simon-2018:2.2:distinguishing"
                    "simon-2018:2.3:indicating")
       :statement "Eine Beobachtungsrekonstruktion muss Unterscheidung und Bezeichnung getrennt ausweisen.")))
   (%simon-sense-spec
    "simon-2018:2.2:distinguishing"
    "Unterscheiden bei Simon (2018), 2.2"
    "Unterscheiden teilt einen beobachteten Raum in zwei Seiten."
    "Unterscheiden"
    "Operation, durch die ein Raum, Zustand oder Inhalt in zwei Seiten geteilt wird."
    2 "2.2" nil
    :page-status :not-recorded-in-current-slice)
   (%simon-sense-spec
    "simon-2018:2.2.2:inside-and-outside"
    "Innen und außen bei Simon (2018), 2.2.2"
    "Eine Unterscheidung erzeugt eine Innen- und eine Außenseite."
    "innen und außen"
    "Die beiden durch eine Unterscheidung hervorgebrachten Seiten."
    2 "2.2.2" nil
    :page-status :not-recorded-in-current-slice)
   (%simon-sense-spec
    "simon-2018:2.3:indicating"
    "Bezeichnen bei Simon (2018), 2.3"
    "Bezeichnen markiert eine Seite einer Unterscheidung."
    "Bezeichnen"
    "Operation, durch die eine Seite einer Unterscheidung markiert wird."
    2 "2.3" nil
    :page-status :not-recorded-in-current-slice)
   (%simon-sense-spec
    "simon-2018:2.5:boundary"
    "Grenze bei Simon (2018), 2.5"
    "Eine Grenze wird relativ zu einer hypothetischen Innen-außen-Unterscheidung rekonstruiert."
    "Grenze"
    "Hypothetische Innen-außen-Grenze, relativ zu der ein Ereignis als Veränderung beobachtet werden kann."
    2 "2.5" nil
    :page-status :not-recorded-in-current-slice)
   (%simon-sense-spec
    "simon-2018:2.6:observation"
    "Beobachtung bei Simon (2018), 2.6"
    "Eine Beobachtung ist ein bestimmtes Unterscheiden und Bezeichnen zu einem bestimmten Zeitpunkt."
    "Beobachtung"
    "Bestimmtes Unterscheiden und Bezeichnen eines Raums, Zustands oder Inhalts mit markierter Innen-, unmarkierter Außenseite und Beobachtungszeitpunkt."
    2 "2.6" nil
    :page-status :not-recorded-in-current-slice
    :controlled-derivations
    '((:id "simon-2018:2.6:identity-separation"
       :source-ids ("simon-2018:2.2:distinguishing"
                    "simon-2018:2.3:indicating")
       :statement "Die Bezeichnung bleibt von dem bezeichneten Sachverhalt verschieden.")))
   (%simon-sense-spec
    "simon-2018:3.1:operation"
    "Operation bei Simon (2018), 3.1"
    "Eine Operation ist ein Ereignis der Veränderung relativ zu einer hypothetischen Innen-außen-Grenze."
    "Operation"
    "Ereignis, das einer Veränderung relativ zu einer hypothetischen Innen-außen-Grenze entspricht."
    3 "3.1" 19
    :technical-homonym-ids '("asdf:operation")
    :temporal-dimensions '(:event-duration)
    :application-hypotheses
    (list *simon-runtime-coherence-application-hypothesis*)
    :open-interpretation-questions
    '("Wie wird die hypothetische Grenze in einer konkreten Anwendung evidenzgestützt rekonstruiert?"))
   (%simon-sense-spec
    "simon-2018:3.2:function-of-operation"
    "Funktion einer Operation bei Simon (2018), 3.2"
    "Funktion bezeichnet die einer Operation zugerechnete Wirkung."
    "Funktion"
    "Wirkung einer Operation."
    3 "3.2" 19
    :technical-homonym-ids '("common-lisp:function")
    :temporal-dimensions '(:effect-durability))
   (%simon-sense-spec
    "simon-2018:3.2.1:operation-consumes-time"
    "Zeitverbrauch einer Operation bei Simon (2018), 3.2.1"
    "Jede Operation verbraucht Zeit."
    "Zeitverbrauch"
    "Jede Operation verbraucht Zeit; diese Ereignisdauer ist von Prozessdauer und Wirkungshaltbarkeit getrennt."
    3 "3.2.1" 19
    :temporal-dimensions '(:event-duration))
   (%simon-sense-spec
    "simon-2018:3.2.2:change-as-function"
    "Veränderung als Funktion bei Simon (2018), 3.2.2"
    "Die Funktion einer Operation kann in einer Veränderung bestehen."
    "Veränderung als Funktion"
    "Eine Operation kann als Wirkung einen Wechsel zwischen außen und innen oder eine Zustandsveränderung hervorbringen."
    3 "3.2.2" 19
    :temporal-dimensions '(:effect-durability))
   (%simon-sense-spec
    "simon-2018:3.2.3:preservation-as-function"
    "Erhaltung als Funktion bei Simon (2018), 3.2.3"
    "Die Funktion einer Operation kann in der Verhinderung einer Veränderung bestehen."
    "Veränderungsverhinderung als Funktion"
    "Eine Operation kann als Wirkung einen Raum, Zustand oder Inhalt zeitüberdauernd erhalten, so dass vorher und nachher gleich beobachtet werden."
    3 "3.2.3" 19
    :temporal-dimensions '(:effect-durability)
    :controlled-derivations
    '((:id "simon-2018:3.2.3:operation-effect-form-separation"
       :source-ids ("simon-2018:3.1:operation"
                    "simon-2018:3.2:function-of-operation"
                    "simon-2018:3.2.3:preservation-as-function")
       :statement "Eine Operation kann eine Veränderung vollziehen, während ihre Funktion in der Erhaltung eines anderen Zustands besteht.")))
   (%simon-sense-spec
    "simon-2018:3.3:process"
    "Prozess bei Simon (2018), 3.3"
    "Ein Prozess verbindet zeitlich gekoppelte Operationen zu einer geordneten Einheit."
    "Prozess"
    "Geordnete Menge zeitlich gekoppelter Operationen, die gleichzeitig oder ungleichzeitig stattfinden können und zu einer größeren Einheit verbunden sind."
    3 "3.3" 19
    :technical-homonym-ids '("operating-system:process")
    :temporal-dimensions '(:process-duration)
    :open-interpretation-questions
    '("Welches Kopplungskriterium konstituiert in einer konkreten Anwendung die größere Einheit?"))
   (%simon-sense-spec
    "simon-2018:3.4:effect-durability"
    "Haltbarkeit der Wirkung bei Simon (2018), 3.4"
    "Durch Operationen oder Prozesse bewirkte Veränderungen können unterschiedlich haltbar sein."
    "Haltbarkeit der Wirkung"
    "Die durch Operation oder Prozess bewirkte Veränderung beziehungsweise Funktion kann unterschiedlich lange erhalten bleiben."
    3 "3.4" 19
    :temporal-dimensions '(:effect-durability))
   (%simon-sense-spec
    "simon-2018:3.4.1:event-momentariness"
    "Augenblicklichkeit des Ereignisses bei Simon (2018), 3.4.1"
    "Ein Ereignis ist augenblicklich und nicht mit der Haltbarkeit seiner Wirkung identisch."
    "Augenblicklichkeit des Ereignisses"
    "Ereignisse sind augenblicklich; ihre Wirkungen können fortdauern, ohne dass das Ereignis selbst fortdauert."
    3 "3.4.1" 20
    :technical-homonym-ids '("scxml:event" "hyperdoc:event-record")
    :temporal-dimensions '(:event-duration :effect-durability))
   (%simon-sense-spec
    "simon-2018:3.4.2:process-duration"
    "Prozessdauer bei Simon (2018), 3.4.2"
    "Prozesse können unterschiedlich lange dauern, weil sie aus Ereignissen zusammengesetzt sind."
    "Prozessdauer"
    "Die Dauer eines Prozesses ist von den Dauern seiner Ereignisse und von der Haltbarkeit seiner Wirkungen zu unterscheiden."
    3 "3.4.2" 20
    :technical-homonym-ids '("operating-system:process")
    :temporal-dimensions '(:process-duration :event-duration :effect-durability))

   (%technical-sense-spec
    "common-lisp:function"
    "Common-Lisp-Funktion"
    "Technischer Sinn eines aufrufbaren Lisp-Funktionsobjekts oder Funktionsnamens."
    "function"
    "Common-Lisp-Programmierbegriff; keine Wirkung einer Simon-Operation."
    "hyperdoc/core.lisp"
    :symbol "MAKE-HYPERDOC")
   (%technical-sense-spec
    "asdf:operation"
    "ASDF-Operation"
    "Technischer ASDF-Sinn einer Operationsklasse beziehungsweise Operationsbeschreibung."
    "operation"
    "ASDF-Programmierbegriff; eine Operationsbeschreibung ist kein beobachteter Ereignisvollzug im Sinne Simons."
   "hyperdoc.asd"
    :symbol "ASDF:TEST-OP")
   (%technical-sense-spec
    "asdf:action"
    "ASDF-Action"
    "Technischer ASDF-Planbegriff eines Paars aus Operation und Komponente."
    "action"
    "ASDF-Planobjekt aus Operationsobjekt und Komponente; weder die ASDF-Operationsklasse noch schon deren Vollzug oder Wirkung."
    "hyperbook-explorer/asdf-plan-view.lisp"
    :symbol "HTML-INSPECTOR-VIEWS/STANDARD::PLAN-ACTION-ROW-FROM-ACTION"
    :technical-homonym-ids '("asdf:operation"))
   (%technical-sense-spec
    "scxml:state"
    "SCXML-Zustandsbeschreibung"
    "Technischer SCXML-Sinn eines deklarativen Zustandsknotens."
    "state"
    "Deklarativer SCXML-AST-Zustand; weder eine Transition noch der beobachtete Vollzug eines Zustandswechsels."
    "hyperdoc-scxml/ast.lisp"
    :symbol "HYPERDOC/SCXML::SCXML-STATE"
    :technical-homonym-ids '("scxml:transition"))
   (%technical-sense-spec
    "scxml:event"
    "SCXML-Ereignistyp"
    "Technischer SCXML-Sinn eines Ereignisnamens oder Ereignistyps."
    "event"
    "SCXML-Begriff; eine Ereignisbezeichnung ist nicht der vergangene Ereignisvollzug."
    "hyperdoc-scxml/ast.lisp"
    :symbol "SCXML-TRANSITION-EVENT-OF")
   (%technical-sense-spec
    "scxml:transition"
    "SCXML-Transition"
    "Technischer SCXML-Sinn einer Übergangsbeschreibung."
    "transition"
    "SCXML-Übergangsdefinition; nicht automatisch eine Simon-Operation."
    "hyperdoc-scxml/ast.lisp"
    :symbol "SCXML-TRANSITION")
   (%technical-sense-spec
    "scxml:action-description"
    "SCXML-Aktionsbeschreibung"
    "Technischer SCXML-Sinn eines deklarativen Action-AST-Knotens."
    "action"
    "Deklarativer SCXML-AST-Knoten mit Art und Attributen; weder ein Inspector-Thunk noch dessen Aufruf oder Wirkung."
    "hyperdoc-scxml/ast.lisp"
    :symbol "HYPERDOC/SCXML::SCXML-ACTION"
    :technical-homonym-ids '("inspector:action-thunk"))
   (%technical-sense-spec
    "operating-system:process"
    "Betriebssystemprozess"
    "Technischer Sinn eines vom Betriebssystem verwalteten Prozesses."
    "process"
    "Betriebssystembegriff; nicht ohne zeitliche Kopplung und Ordnungsnachweis ein Prozess im Sinne Simons."
    "hyperdoc/examples.lisp"
    :symbol "UIOP:LAUNCH-PROGRAM")
   (%technical-sense-spec
    "hyperdoc:state-machine-run"
    "HyperDoc-State-Machine-Run"
    "Technischer HyperDoc-Sinn eines Laufobjekts einer Zustandsmaschine."
    "state-machine run"
    "HyperDoc-Laufobjekt mit Maschine, Zustand, Trace, Zeit- und Statusdaten; weder ein einzelner Ereignisdatensatz noch allein aufgrund seines Namens ein Simon-Prozess."
    "hyperdoc/state-machines.lisp"
    :symbol "HYPERDOC::STATE-MACHINE-RUN"
    :technical-homonym-ids '("hyperdoc:event-record"))
   (%technical-sense-spec
    "hyperdoc:event-record"
    "HyperDoc-Ereignisaufzeichnung"
    "Technischer Sinn eines gespeicherten Trace- oder Ereignisdatensatzes."
    "event record"
    "Aufzeichnung oder Bezeichnung eines Ereignisses; nicht das vergangene Ereignis selbst."
    "hyperdoc/shared-projection-ir.lisp"
    :symbol "SHARED-PROJECTION-JOURNAL-EVENT")
   (%technical-sense-spec
    "inspector:action-thunk"
    "Inspector-Aktions-Thunk"
    "Technischer Sinn einer später aufrufbaren Inspector-Aktion."
    "action"
    "Aufrufbare technische Aktion; nicht ohne Grenzrekonstruktion eine Simon-Operation."
    "hyperdoc-inspector/playground-eval.lisp"
    :symbol "EVAL-ACTION-THUNK")))

(defun make-source-grounded-term-sense
    (&key id title summary references source-term domain source-wording
          normalized-sense source-reference definition-status
          technical-homonym-ids temporal-dimensions controlled-derivations
          application-hypotheses open-interpretation-questions)
  (unless (and (stringp id) (plusp (length id)))
    (error "A source-grounded concept id must be a non-empty string: ~S" id))
  (unless (every #'source-grounded-temporal-dimension-p temporal-dimensions)
    (error "Unknown temporal dimension in ~S" temporal-dimensions))
  (let ((sense (gethash id *topics-by-id*)))
    (when (and sense (not (typep sense 'source-grounded-term-sense)))
      (error "Topic id ~S is already occupied by ~S." id (type-of sense)))
    (unless sense
      (setf sense (make-instance 'source-grounded-term-sense
                                 :id id
                                 :title title
                                 :summary summary
                                 :references references
                                 :source-term source-term
                                 :domain domain
                                 :source-wording source-wording
                                 :normalized-sense normalized-sense
                                 :source-reference source-reference
                                 :definition-status definition-status
                                 :technical-homonym-ids technical-homonym-ids
                                 :temporal-dimensions temporal-dimensions
                                 :controlled-derivations controlled-derivations
                                 :application-hypotheses application-hypotheses
                                 :open-interpretation-questions
                                 open-interpretation-questions)))
    (setf (id-of sense) id
          (title-of sense) title
          (summary-of sense) summary
          (references-of sense) references
          (source-grounded-term-sense-source-term-of sense) source-term
          (source-grounded-term-sense-domain-of sense) domain
          (source-grounded-term-sense-source-wording-of sense) source-wording
          (source-grounded-term-sense-normalized-sense-of sense) normalized-sense
          (source-grounded-term-sense-source-reference-of sense) source-reference
          (source-grounded-term-sense-definition-status-of sense) definition-status
          (source-grounded-term-sense-technical-homonym-ids-of sense)
          technical-homonym-ids
          (source-grounded-term-sense-temporal-dimensions-of sense)
          temporal-dimensions
          (source-grounded-term-sense-controlled-derivations-of sense)
          controlled-derivations
          (source-grounded-term-sense-application-hypotheses-of sense)
          application-hypotheses
          (source-grounded-term-sense-open-interpretation-questions-of sense)
          open-interpretation-questions)
    (%register-topic sense)))

(defun simon-formen-term-sense (id &key signal-error-p)
  (let ((spec (find id *simon-formen-term-sense-specs*
                    :key (lambda (entry) (getf entry :id))
                    :test #'string=)))
    (cond
      (spec (apply #'make-source-grounded-term-sense spec))
      (signal-error-p (error "No source-grounded term sense with id ~S." id))
      (t nil))))

(defun simon-formen-source-grounded-senses ()
  (mapcar (lambda (spec)
            (apply #'make-source-grounded-term-sense spec))
          *simon-formen-term-sense-specs*))

(defun source-grounded-term-sense-referenced-sense-ids (sense)
  (remove-duplicates
   (append
    (copy-list (source-grounded-term-sense-technical-homonym-ids-of sense))
    (loop for derivation
            in (source-grounded-term-sense-controlled-derivations-of sense)
          append (copy-list (getf derivation :source-ids)))
    (loop for hypothesis
            in (source-grounded-term-sense-application-hypotheses-of sense)
          append (copy-list (getf hypothesis :sense-ids))))
   :test #'string=))

;; Zero-argument factories keep every concept discoverable by the topic registry.
(defun simon-2018-1-2-observer-topic ()
  (simon-formen-term-sense "simon-2018:1.2:observer"))
(defun simon-2018-1-3-second-order-observing-topic ()
  (simon-formen-term-sense "simon-2018:1.3:second-order-observing"))
(defun simon-2018-1-4-reflexive-observation-topic ()
  (simon-formen-term-sense "simon-2018:1.4:reflexive-observation"))
(defun simon-2018-2-1-observing-topic ()
  (simon-formen-term-sense "simon-2018:2.1:observing"))
(defun simon-2018-2-2-distinguishing-topic ()
  (simon-formen-term-sense "simon-2018:2.2:distinguishing"))
(defun simon-2018-2-2-2-inside-and-outside-topic ()
  (simon-formen-term-sense "simon-2018:2.2.2:inside-and-outside"))
(defun simon-2018-2-3-indicating-topic ()
  (simon-formen-term-sense "simon-2018:2.3:indicating"))
(defun simon-2018-2-5-boundary-topic ()
  (simon-formen-term-sense "simon-2018:2.5:boundary"))
(defun simon-2018-2-6-observation-topic ()
  (simon-formen-term-sense "simon-2018:2.6:observation"))
(defun simon-2018-3-1-operation-topic ()
  (simon-formen-term-sense "simon-2018:3.1:operation"))
(defun simon-2018-3-2-function-of-operation-topic ()
  (simon-formen-term-sense "simon-2018:3.2:function-of-operation"))
(defun simon-2018-3-2-1-operation-consumes-time-topic ()
  (simon-formen-term-sense "simon-2018:3.2.1:operation-consumes-time"))
(defun simon-2018-3-2-2-change-as-function-topic ()
  (simon-formen-term-sense "simon-2018:3.2.2:change-as-function"))
(defun simon-2018-3-2-3-preservation-as-function-topic ()
  (simon-formen-term-sense "simon-2018:3.2.3:preservation-as-function"))
(defun simon-2018-3-3-process-topic ()
  (simon-formen-term-sense "simon-2018:3.3:process"))
(defun simon-2018-3-4-effect-durability-topic ()
  (simon-formen-term-sense "simon-2018:3.4:effect-durability"))
(defun simon-2018-3-4-1-event-momentariness-topic ()
  (simon-formen-term-sense "simon-2018:3.4.1:event-momentariness"))
(defun simon-2018-3-4-2-process-duration-topic ()
  (simon-formen-term-sense "simon-2018:3.4.2:process-duration"))
(defun common-lisp-function-sense-topic ()
  (simon-formen-term-sense "common-lisp:function"))
(defun asdf-operation-sense-topic ()
  (simon-formen-term-sense "asdf:operation"))
(defun asdf-action-sense-topic ()
  (simon-formen-term-sense "asdf:action"))
(defun scxml-state-sense-topic ()
  (simon-formen-term-sense "scxml:state"))
(defun scxml-event-sense-topic ()
  (simon-formen-term-sense "scxml:event"))
(defun scxml-transition-sense-topic ()
  (simon-formen-term-sense "scxml:transition"))
(defun scxml-action-description-sense-topic ()
  (simon-formen-term-sense "scxml:action-description"))
(defun operating-system-process-sense-topic ()
  (simon-formen-term-sense "operating-system:process"))
(defun hyperdoc-state-machine-run-sense-topic ()
  (simon-formen-term-sense "hyperdoc:state-machine-run"))
(defun hyperdoc-event-record-sense-topic ()
  (simon-formen-term-sense "hyperdoc:event-record"))
(defun inspector-action-thunk-sense-topic ()
  (simon-formen-term-sense "inspector:action-thunk"))
