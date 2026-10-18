;;;; The Topic Map of an Item edit as a navigable Topicmap
(in-package #:dreyeck/item-edit-ctm)

;; The TMDM Topic Map that the topic-maps reader made of the CTM is drawn with the existing native Topicmap renderer and, on request, laid out by the
;; existing TALA integration. Nothing here draws or lays out anything; this file builds the PROJECTION that those components take:
;;
;;   Topics         the objects of the Item edit (visible), the Associations of the Item edit as nodes of their own (visible), and every other Topic of the
;;                  Topic Map, the schema Topics, kept out of the drawing (not visible) but in the projection, so that the legend lists them and
;;                  each stays inspectable
;;   Associations   one edge for each Role of each Association of the Item edit, from the Association node to the player, typed by the Role type, so a
;;                  Role type is not lost in an unqualified arrow. The type-instance Associations of the reader's isa are not drawn.
;;
;; Identity comes from the Topic Map: a Topic's key is the fragment of its item identifier (or the last segment of its subject identifier), an Association
;; node's key is its type and its Roles. Positions are a presentation: the objects of the Item edit have a fixed place, an Association node stands between
;; its players. TALA lays the same projection out again, and the Topic keys stay.
;;
;; The Workspace (Point, History) belongs to one projection. A projection is derived from the Lisp objects each time a view is shown; so that the Point
;; survives a refresh of the pane, CURRENT-PROJECTION keeps the last projection of an origin object (weakly, by that object) and gives it back while the
;; CTM it was made of is the same. A changed object gets a new projection.

(defclass item-edit-topic (tr:projected-tmdm-topic)
  ((spec :initarg :spec :initform nil :reader topic-spec)
   (statement :initarg :statement :initform nil :reader topic-statement)
   (schema-use :initarg :schema-use :initform nil :reader topic-schema-use))
  (:documentation "A projected Topic of an Item edit: an object of it (SPEC), an Association of it (STATEMENT), or a schema Topic (SCHEMA-USE says what it types)."))

(defparameter +positions+
  '(("the-proposal" 0 0) ("the-proposed-action" 0 280) ("the-preview" 520 280)
    ("the-completed-action" 0 560) ("the-completion" 520 560)
    ("the-expected-item" 0 840) ("the-signed-body" 520 840))
  "Where the objects of an Item edit stand, in two columns: the proposal above its Action, the preview and the completion to the right of the Actions, the signed body beside the
expected Item. The completion is near the middle, so that the drawing, which the native renderer centres on the Point, shows all of it when the Point is there.")

(defun %fragment (string) (let ((at (position #\# string :from-end t))) (and at (subseq string (1+ at)))))
(defun %last-segment (string) (subseq string (1+ (or (position #\/ string :from-end t) -1))))
(defun topic-key (topic)
  "The identity of TOPIC in its Topic Map: the fragment of its item identifier, else the last segment of its subject identifier."
  (let ((item (first (tmdm:topic-item-identifiers topic))) (subject (first (tmdm:topic-subject-identifiers topic))))
    (cond (item (or (%fragment item) item)) (subject (%last-segment subject))
          (t (refuse "a Topic of the Topic Map has neither an item nor a subject identifier")))))

(defun %role-keys (association)
  (sort (mapcar (lambda (role) (list (topic-key (tmdm:association-role-type role)) (topic-key (tmdm:association-role-player role))))
                (tmdm:association-roles association))
        #'string< :key #'first))
(defun %statement-for (c association)
  "The statement of C that ASSOCIATION of the Topic Map is: the same type, the same Role types and players. NIL for the reader's isa Associations."
  (let ((type (topic-key (tmdm:association-type association))) (roles (%role-keys association)))
    (find-if (lambda (statement)
               (and (equal type (statement-type statement))
                    (equal roles (sort (mapcar #'copy-list (statement-roles statement)) #'string< :key #'first))))
             (ctm-statements c))))
(defun association-key (association)
  (format nil "~A(~{~A=~A~^,~})" (topic-key (tmdm:association-type association))
          (loop for (role-type player) in (%role-keys association) append (list role-type player))))

(defun %schema-use (c topic)
  "What a Topic of the Topic Map that is not an object of the Item edit is used as, read from the Topic Map."
  (let* ((map (ctm-map c)) (key (topic-key topic))
         (statements (remove nil (mapcar (lambda (a) (%statement-for c a)) (tmdm:topic-map-associations map)))))
    (cond ((member key (mapcar #'statement-type statements) :test #'equal) "association type")
          ((member key (loop for s in statements append (mapcar #'first (statement-roles s))) :test #'equal) "role type")
          ((member key (loop for spec in (ctm-topics c) append (mapcar #'first (spec-occurrences spec))) :test #'equal) "occurrence type")
          ((member key '("observed" "derived") :test #'equal) "scope: how a statement is known")
          ((member key (mapcar #'spec-type (ctm-topics c)) :test #'equal) "class of an object of the Item edit")
          (t "TMDM core"))))

(defun %position (key) (let ((entry (assoc key +positions+ :test #'equal))) (if entry (values (second entry) (third entry)) (values 0 0))))

(defun build-projection (c)
  "The Topicmap projection of C's Topic Map: see the head of this file."
  (let* ((map (ctm-map c)) (topics nil) (edges nil)
         (specs (ctm-topics c)))
    (dolist (tmdm-topic (tmdm:topic-map-topics map))
      (let* ((key (topic-key tmdm-topic)) (spec (find key specs :key #'spec-id :test #'equal)))
        (multiple-value-bind (x y) (%position key)
          (push (if spec
                    (make-instance 'item-edit-topic :id key :label key :type :tmdm-topic :object tmdm-topic :origin c :spec spec
                                                    :view-properties (list :kind (spec-type spec) :status (class-word (spec-class spec)) :visible t :x x :y y))
                    (make-instance 'item-edit-topic :id key :label key :type :tmdm-topic :object tmdm-topic :origin c :schema-use (%schema-use c tmdm-topic)
                                                    :view-properties (list :kind (%schema-use c tmdm-topic) :visible nil :x 0 :y 0)))
                topics))))
    (dolist (association (tmdm:topic-map-associations map))
      (let ((statement (%statement-for c association)))
        (when statement
          (let* ((id (association-key association)) (roles (%role-keys association))
                 (xs (mapcar (lambda (r) (nth-value 0 (%position (second r)))) roles))
                 (ys (mapcar (lambda (r) (nth-value 1 (%position (second r)))) roles)))
            (push (make-instance 'item-edit-topic :id id :label (statement-type statement) :type :tmdm-association :object association :origin c
                                                  :statement statement
                                                  :view-properties (list :kind "association" :status (class-word (statement-class statement)) :visible t
                                                                         :x (round (reduce #'+ xs) (length xs)) :y (round (reduce #'+ ys) (length ys))))
                  topics)
            (dolist (role (tmdm:association-roles association))
              (let ((role-type (topic-key (tmdm:association-role-type role))) (player (topic-key (tmdm:association-role-player role))))
                (push (make-instance 'tr:projected-tmdm-association
                                     :id (format nil "~A:~A:~A" id role-type player) :type role-type :from id :to player :origin c
                                     :properties (list :tmdm-role role :role-type (tmdm:association-role-type role) :tmdm-association association
                                                       :association-type (tmdm:association-type association)))
                      edges)))))))
    (tm:make-topicmap-projection :source c :topics (nreverse topics) :associations (nreverse edges)
                                 :view-properties '(:width 1300 :height 1200))))

(defun native-projection (c) (or (%native c) (setf (%native c) (build-projection c))))
(defun ctm-workspace (c)
  "The Workspace of C's Topicmap: its Point starts at the object the Item edit was made from, and its History keeps the Points it left."
  (or (%workspace c)
      (setf (%workspace c)
            (tm:make-topicmap-workspace (native-projection c)
                                        (ecase (ctm-stage c) (:completion "the-completion") (:preview "the-preview") (:proposal "the-proposal"))))))

(defun visible-projection (c)
  "The projection without the schema Topics, as TALA takes it: flat and entirely visible."
  (let ((projection (native-projection c)))
    (tm:make-topicmap-projection
     :source c :associations (tm:topicmap-projection-associations-of projection)
     :topics (remove-if-not (lambda (topic) (getf (tm:topicmap-topic-view-properties-of topic) :visible t)) (tm:topicmap-projection-topics-of projection))
     :view-properties (tm:topicmap-projection-view-properties-of projection))))

(defvar *current* (make-hash-table :test 'eq :weakness :key)
  "The last projection of an origin object, so that a Workspace keeps its Point while a pane is refreshed. Weak: it dies with the object.")
(defun current-projection (origin)
  "The projection of ORIGIN: the one made before if the CTM is still the same, else a new one."
  (let ((fresh (project-item-edit origin)) (kept (gethash origin *current*)))
    (if (and kept (equal (ctm-text kept) (ctm-text fresh))) kept (setf (gethash origin *current*) fresh))))

(defun tala-layout (c &key (program "d2") (seed 44))
  "The TALA layout of C's visible projection, made now and once, on request: a TALA-RENDERING, or the evidence of the missing dependency."
  (let ((status (tala:tala-dependency-status :program program)))
    (if (eq :available (getf status :status))
        (tala:run-tala (tala:projection-tala-input (visible-projection c) :seed seed))
        status)))

;;; What a Topic or an Association node of the projection stands for

(defun %occurrence-rows (spec)
  (v:html
    (:table :class "inspector-table"
      (:tr (:th "Occurrence") (:th "Value") (:th "Known by") (:th "From"))
      (dolist (o (spec-occurrences spec))
        (v:html (:tr (:td (v:esc (first o))) (:td (:code (v:esc (princ-to-string (second o))))) (:td (v:esc (class-word (third o)))) (:td (v:esc (fourth o)))))))))

(defun %spec-of-key (c key) (find key (ctm-topics c) :key #'spec-id :test #'equal))

(defun provenance-html (topic)
  "What HyperDoc says the projected TOPIC is, and why: the Lisp object, how it is known and from where. The Scope of an Association in the Topic Map
names the class; the reason is this."
  (let ((c (tr:projection-origin topic)) (spec (topic-spec topic)) (statement (topic-statement topic)))
    (cond
      (spec
       (v:html
         (:h3 "Provenance in the HyperDoc projection")
         (:p "An object of the Item edit. Lisp object: " (ref (spec-object spec)) ". Known by: " (:strong (v:esc (class-word (spec-class spec)))) " — " (v:esc (spec-source spec)) ".")
         (:p "TMDM Topic: " (ref (tm:topicmap-topic-object-of topic) "TMDM Topic") ".")
         (%occurrence-rows spec)))
      (statement
       (v:html
         (:h3 "Provenance in the HyperDoc projection")
         (:p "An Association of the Item edit: " (:code (v:esc (statement-type statement))) ", " (:strong (v:esc (class-word (statement-class statement)))) ". "
             "Why HyperDoc states it: " (v:esc (statement-source statement)) ".")
         (:p "The Topic Map carries the class as the Scope of the Association; the reason is kept here, in the projection, and is not part of the Topic Map. TMDM Association: "
             (ref (tm:topicmap-topic-object-of topic) "TMDM Association") ".")
         (:table :class "inspector-table"
           (:tr (:th "Role") (:th "Role type") (:th "Player") (:th "Lisp object"))
           (dolist (role (tmdm:association-roles (tm:topicmap-topic-object-of topic)))
             (let* ((player (tmdm:association-role-player role)) (key (topic-key player)) (player-spec (%spec-of-key c key)))
               (v:html (:tr (:td (ref role "TMDM Role")) (:td (ref (tmdm:association-role-type role) (topic-key (tmdm:association-role-type role))))
                            (:td (ref player key)) (:td (when player-spec (ref (spec-object player-spec)))))))))))
      (t
       (v:html
         (:h3 "A schema Topic")
         (:p "Used as: " (v:esc (topic-schema-use topic)) ". It is in the Topic Map and not an object of the Item edit, so the drawing leaves it out; this view and the legend keep it inspectable. TMDM Topic: "
             (ref (tm:topicmap-topic-object-of topic) "TMDM Topic") "."))))))

(defmethod native::render-workspace-point-editor ((workspace tm:topicmap-workspace) (topic item-edit-topic))
  (provenance-html topic))

(v:defview item-edit-topic-provenance (topic item-edit-topic)
  (v:html-view :title "Provenance" :priority -1
    (v:html
      (:h2 (v:esc (tm:topicmap-topic-label-of topic)))
      (provenance-html topic)
      (:p (ref (tr:projection-origin topic) "Back to the Topicmap" "Topicmap")))))

;;; The Topicmap view

(defun %topicmap-section (origin)
  (let ((c (handler-case (current-projection origin) (item-edit-ctm-refused (condition) (princ-to-string condition)))))
    (if (stringp c) (v:html (:h2 "Topicmap") (:p (v:esc c))) (%topicmap-of c))))

(defun %topicmap-of (c)
  (progn
    (progn
        (let* ((workspace (ctm-workspace c)) (projection (tm:topicmap-projection-of workspace)))
          (v:html
            (:h2 (v:esc (format nil "Topicmap of the ~(~A~) of ~A" (ctm-stage c) (ctm-item-id c))))
            (:p "The Topic Map made of the CTM, drawn with the native Topicmap renderer. The objects of the Item edit are the Topics; each Association is a node of its own, "
                "joined to its players by one edge for each Role, named by the Role type. Its second word is how it is known: observed, read from a slot, or derived, computed from the objects. "
                "Click a sign to move the Point there; the Point's panel below the drawing names what it stands for and why, links the Lisp objects and lists its Roles. "
                "The schema Topics (types, Role types, Occurrence types, Scopes) are not drawn; the table at the end lists them.")
            (:p "Point: " (:code (v:esc (tm:topicmap-workspace-point-of workspace))) ". " (ref workspace "Open the Workspace as a pane")
                " / " (ref (ctm-map c) "the TMDM Topic Map") " / " (ref c "TMDM objects" "TMDM objects") " / " (ref (ctm-origin c) "the CTM text" "CTM"))
            (v:str (native::render-topicmap-html native:*topicmap-renderer* projection))
            (native::render-topicmap-workspace-associations projection)
            (:h3 "Layout")
            (:p "The places are fixed by this projection. TALA lays the same Topics and Associations out again when asked; it runs the external layout program D2 once, "
                "and the keys of the Topics stay. " (v:eval-button "Lay out with TALA" (v:thunk (tala-layout c))))
            (native::render-topicmap-legend projection))))))

(v:defview item-edit-proposal-topicmap (proposal p:item-edit-proposal)
  (v:html-view :title "Topicmap" :priority 5 (%topicmap-section proposal)))
(v:defview item-edit-preview-topicmap (preview p:item-edit-preview)
  (v:html-view :title "Topicmap" :priority 5 (%topicmap-section preview)))
(v:defview item-edit-completion-topicmap (completion x:item-edit-completion)
  (v:html-view :title "Topicmap" :priority 5 (%topicmap-section completion)))
(v:defview item-edit-ctm-topicmap (c item-edit-ctm)
  (v:html-view :title "Topicmap" :priority 5 (%topicmap-of c)))
