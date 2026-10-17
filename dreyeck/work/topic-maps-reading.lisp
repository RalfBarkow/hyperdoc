;;;; Reading one CTM document with the topic-maps reader, and projecting its TMDM objects
(defpackage #:dreyeck/topic-maps-reading
  (:use #:cl)
  (:local-nicknames (#:tmdm #:topic-maps.tmdm)
                    (#:ctm #:topic-maps.ctm)
                    (#:cxtm #:topic-maps.cxtm)
                    (#:tm #:dreyeck/topicmap)
                    (#:v #:html-inspector-views)
                    (#:a #:dreyeck/work/item-edit-proposal))
  (:export #:read-ctm-reading #:ctm-reading #:reading-map #:reading-path #:reading-sha256 #:reading-fidelity
           #:reading-projection #:reading-workspace #:reading-variants #:topic-label
           #:projected-tmdm-topic #:projected-tmdm-association #:projection-origin
           #:tmdm-projection-error #:reading-error #:+document-iri+ #:+ctm-sha256+ #:default-ctm-path))
(in-package #:dreyeck/topic-maps-reading)

;; The TMDM objects are those of the existing topic-maps reader; nothing here parses
;; CTM or models Topics again. The projection into DREYECK/TOPICMAP is a presentation,
;; and each projected Topic keeps the TMDM object it stands for as its OBJECT. What E3
;; asks, how Associations, Roles and Role types are shown, is a content decision that
;; is open: the variants below are candidates, and none is chosen. Topic keys are
;; labels cut from the item identifiers, an illustration while E4 (the key policy) is open.

(defparameter +document-iri+
  "https://ctm-tests.example.invalid/cd165b150176c1d6842b37be9cc9051b40d4996b/ctm/in/association-binary.ctm")
(defparameter +ctm-sha256+ "bcc4a7eaf7ad88ae816a164712d44247aa51f85163447726895d74f181b193b8")
(defparameter +baseline-sha256+ "0419d8639795bce71c628a3c28fbd1264b475c37f77a570091d32b0b670d8e13")
(defparameter +topic-maps-observation+
  '(:branch "codex/ctm-slice-11" :commit "6a2f8446afca0915882f0d4a06cb891ccfcdc96d" :working-tree "clean" :remote "none"
    :observed "2026-10-17, by this session with git rev-parse and git status; not recomputed when a reading is made")
  "The checkout the example was read from. Which revision HyperDoc should pin is open (E1).")

(define-condition reading-error (error)
  ((reason :initarg :reason :reader reading-error-reason))
  (:report (lambda (c s) (format s "CTM reading refused: ~A" (reading-error-reason c)))))
(define-condition tmdm-projection-error (error)
  ((reason :initarg :reason :reader projection-error-reason))
  (:report (lambda (c s) (format s "TMDM projection refused: ~A" (projection-error-reason c)))))

(defun default-ctm-path ()
  (asdf:system-relative-pathname "topic-maps/ctm" "vendor/cxtm/ctm/in/association-binary.ctm"))
(defun baseline-path ()
  (asdf:system-relative-pathname "topic-maps/ctm" "vendor/cxtm/ctm/baseline/association-binary.ctm.cxtm"))
(defun file-digest (path) (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))
(defun file-octets (path)
  (with-open-file (in path :element-type '(unsigned-byte 8))
    (let ((octets (make-array (file-length in) :element-type '(unsigned-byte 8)))) (read-sequence octets in) octets)))

(defclass ctm-reading ()
  ((path :initarg :path :reader reading-path)
   (sha256 :initarg :sha256 :reader reading-sha256)
   (map :initarg :map :reader reading-map)
   (fidelity :initarg :fidelity :reader reading-fidelity)
   (projections :initform (make-hash-table :test 'equal) :reader reading-projections)
   (workspaces :initform (make-hash-table :test 'equal) :reader reading-workspaces))
  (:documentation "One CTM document read with the topic-maps reader: its TMDM Topic Map, and
whether its canonical form equals the unchanged baseline."))

(defun read-ctm-reading (&key (path (default-ctm-path)) (expected-sha256 +ctm-sha256+))
  "The TMDM objects of the CTM file PATH, if its digest is EXPECTED-SHA256. Reads only."
  (let ((sha (file-digest path)))
    (unless (equal sha expected-sha256)
      (error 'reading-error :reason (format nil "the CTM file has digest ~A, not the expected ~A" sha expected-sha256)))
    (let* ((map (ctm:deserialize-file path :document-iri +document-iri+ :source-name "association-binary.ctm"))
           (octets (cxtm:canonicalize-octets map :base-locator +document-iri+))
           (baseline (file-octets (baseline-path))))
      (make-instance 'ctm-reading :path path :sha256 sha :map map
                     :fidelity (list :canonical-octets (length octets) :baseline-octets (length baseline)
                                     :equal (and (equalp octets baseline) t)
                                     :baseline-sha256 (file-digest (baseline-path)))))))

;;; Projection

(defclass projected-tmdm-topic (tm:topicmap-topic)
  ((origin :initarg :origin :initform nil :accessor projection-origin))
  (:documentation "A projected HyperDoc Topic. Its OBJECT is the TMDM Topic or Association it stands for."))
(defclass projected-tmdm-association (tm:topicmap-association)
  ((origin :initarg :origin :initform nil :accessor projection-origin))
  (:documentation "A projected relation: a Role edge or an Association edge."))

(defun topic-label (topic)
  "A short label cut from TOPIC's first item identifier. A presentation key, not TMDM identity."
  (let ((identifier (first (tmdm:topic-item-identifiers topic))))
    (if identifier (subseq identifier (1+ (or (position #\# identifier :from-end t) -1))) "(no identifier)")))

(defun %projected-topic (id label type object x y kind reading)
  (make-instance 'projected-tmdm-topic :id id :label label :type type :object object :origin reading
                 :view-properties (list :kind kind :visible t :x x :y y)))

(defun %players (map)
  (remove-duplicates (loop for association in (tmdm:topic-map-associations map)
                           append (mapcar #'tmdm:association-role-player (tmdm:association-roles association))) :test #'eq))

(defun %project (reading variant show-type-topics)
  (let* ((map (reading-map reading))
         (associations (tmdm:topic-map-associations map))
         (shown (if show-type-topics (tmdm:topic-map-topics map) (%players map)))
         (topics nil) (edges nil) (n 0))
    (flet ((position-of () (prog1 (list (* 285 (mod n 4)) (* 120 (floor n 4))) (incf n))))
      (dolist (topic shown)
        (destructuring-bind (x y) (position-of)
          (push (%projected-topic (topic-label topic) (topic-label topic) :tmdm-topic topic x y "TMDM topic" reading) topics)))
      (loop for association in associations for index from 1
            for association-id = (format nil "association-~D" index)
            do (ecase variant
                 (:association-node
                  (destructuring-bind (x y) (position-of)
                    (push (%projected-topic association-id (format nil "association ~A" (topic-label (tmdm:association-type association)))
                                            :tmdm-association association x y "TMDM association" reading)
                          topics))
                  (dolist (role (tmdm:association-roles association))
                    (let ((player (tmdm:association-role-player role)) (role-type (tmdm:association-role-type role)))
                      (push (make-instance 'projected-tmdm-association
                                           :id (format nil "~A:~A:~A" association-id (topic-label role-type) (topic-label player))
                                           :type (topic-label role-type) :from association-id :to (topic-label player) :origin reading
                                           :properties (list :tmdm-role role :role-type role-type :tmdm-association association
                                                             :association-type (tmdm:association-type association)))
                            edges))))
                 (:association-edge
                  (let ((roles (tmdm:association-roles association)))
                    (unless (= 2 (length roles))
                      (error 'tmdm-projection-error
                             :reason (format nil "an Association drawn as one edge needs exactly two Roles; ~A has ~D" association-id (length roles))))
                    (push (make-instance 'projected-tmdm-association
                                         :id (format nil "~A:edge" association-id) :type (topic-label (tmdm:association-type association))
                                         :from (topic-label (tmdm:association-role-player (first roles)))
                                         :to (topic-label (tmdm:association-role-player (second roles))) :origin reading
                                         :properties (list :tmdm-association association :roles roles
                                                           :role-types (mapcar #'tmdm:association-role-type roles)
                                                           :association-type (tmdm:association-type association)))
                          edges))))))
    (tm:make-topicmap-projection :source reading :topics (nreverse topics) :associations (nreverse edges)
                                 :view-properties '(:width 1180 :height 380))))

(defun reading-variants ()
  "The four candidate projections: how the Association is drawn, and whether the type Topics are shown."
  '((:association-node t "Association as a node, type Topics shown")
    (:association-node nil "Association as a node, type Topics hidden")
    (:association-edge t "Association as an edge, type Topics shown")
    (:association-edge nil "Association as an edge, type Topics hidden")))

(defun reading-projection (reading &optional (variant :association-node) (show-type-topics t))
  (let ((key (list variant (and show-type-topics t))))
    (or (gethash key (reading-projections reading))
        (setf (gethash key (reading-projections reading)) (%project reading variant show-type-topics)))))
(defun reading-workspace (reading &optional (variant :association-node) (show-type-topics t))
  (let* ((key (list variant (and show-type-topics t))) (projection (reading-projection reading variant show-type-topics)))
    (or (gethash key (reading-workspaces reading))
        (setf (gethash key (reading-workspaces reading))
              (tm:make-topicmap-workspace projection (tm:topicmap-topic-id-of (first (tm:topicmap-projection-topics-of projection))))))))

(defmethod tm:topicmap-projection-of ((reading ctm-reading)) (reading-projection reading))
(defmethod v:text-representation ((reading ctm-reading)) "association-binary.ctm read with topic-maps")

;;; Inspection

(defun ref (object &optional label select)
  (v:html (v:object-ref object :display (or label (v:text-representation object)) :select select)))
(defun identifiers (topic) (format nil "~{~A~^ ; ~}" (tmdm:topic-item-identifiers topic)))

(v:defview anatomy-tmdm-example (anatomy a:proposal-anatomy)
  (v:html-view :title "TMDM example" :priority -3
    (let ((reading (read-ctm-reading)))
      (v:html
        (:h2 "What E3 is about, with real TMDM objects")
        (:p "Story Item E3 asks how Associations, Association nodes, Roles and Role types are shown. Its text is an open decision, and so is the answer. "
            "To see what is being decided, one CTM document of the topic-maps repository is read with its own reader, and its TMDM objects are projected in four candidate ways. "
            "No candidate is chosen here.")
        (:p (ref reading "association-binary.ctm, read with topic-maps" "TMDM objects"))
        (:p (ref (a:anatomy-item anatomy) "Return to Story Item E3" "Story item"))))))

(v:defview ctm-reading-objects (reading ctm-reading)
  (v:html-view :title "TMDM objects" :priority 0
    (let* ((map (reading-map reading)) (fidelity (reading-fidelity reading)))
      (v:html
        (:h2 "association-binary.ctm as TMDM objects")
        (:p (:code "assoctype(roletype1: topic1, roletype2 :topic2)") " read by " (:code "topic-maps.ctm:deserialize-file")
            ". The objects are the topic-maps reader's own structures; nothing here parses CTM or models Topics again.")
        (:table :class "inspector-table"
          (:tr (:td "File") (:td (:code "vendor/cxtm/ctm/in/association-binary.ctm") " in the topic-maps checkout"))
          (:tr (:td "SHA-256") (:td (:code (v:esc (reading-sha256 reading)))))
          (:tr (:td "Document IRI") (:td (:code (v:esc +document-iri+))))
          (:tr (:td "Checkout observed") (:td (v:esc (format nil "~{~(~A~): ~A~^; ~}" +topic-maps-observation+))))
          (:tr (:td "Canonical form") (:td (v:esc (format nil "CXTM: ~D octets, the unchanged baseline has ~D; equal: ~A"
                                                          (getf fidelity :canonical-octets) (getf fidelity :baseline-octets)
                                                          (if (getf fidelity :equal) "yes" "no"))))))
        (:h3 "The Topic Map")
        (:p (ref map "the TMDM Topic Map") (v:esc (format nil " — ~D Topics, ~D Association" (length (tmdm:topic-map-topics map)) (length (tmdm:topic-map-associations map)))))
        (:h3 "Topics")
        (:table :class "inspector-table"
          (:tr (:th "Label (cut from the identifier)") (:th "Topic") (:th "Item identifier") (:th "Roles played (computed)"))
          (dolist (topic (tmdm:topic-map-topics map))
            (v:html (:tr (:td (v:esc (topic-label topic))) (:td (ref topic "TMDM Topic"))
                         (:td (:code (v:esc (identifiers topic)))) (:td (v:esc (princ-to-string (length (tmdm:topic-roles-played topic)))))))))
        (:h3 "Association and Roles")
        (dolist (association (tmdm:topic-map-associations map))
          (v:html (:p (ref association "the Association") (v:esc (format nil ", type ~A" (topic-label (tmdm:association-type association)))))
            (:table :class "inspector-table"
              (:tr (:th "Role") (:th "Role type") (:th "Player"))
              (dolist (role (tmdm:association-roles association))
                (v:html (:tr (:td (ref role "TMDM Role")) (:td (ref (tmdm:association-role-type role) (topic-label (tmdm:association-role-type role))))
                             (:td (ref (tmdm:association-role-player role) (topic-label (tmdm:association-role-player role))))))))))
        (:p "A Role has no Topic of its own in TMDM; it belongs to its Association. A Topic's roles played are computed, not stored.")
        (:p (ref reading "Projections: four ways to show these objects" "Projections"))))))

(v:defview ctm-reading-projections (reading ctm-reading)
  (v:html-view :title "Projections" :priority -1
    (v:html
      (:h2 "Four candidate projections")
      (:p "Each projection is a " (:code "dreyeck/topicmap") " projection whose Topics keep the TMDM object they stand for as their object. "
          "They are candidates for E3's open questions: draw the Association as a node or as an edge, and show the type Topics or hide them. None is chosen. "
          "A projection is a presentation: its Topic keys are labels, not TMDM identity (E4 is open), and it has no layout authority: positions are a derived grid.")
      (:table :class "inspector-table"
        (:tr (:th "Candidate") (:th "Topics") (:th "Edges") (:th "Open it"))
        (loop for (variant show label) in (reading-variants)
              do (let ((projection (reading-projection reading variant show)))
                   (v:html (:tr (:td (v:esc label))
                                (:td (v:esc (princ-to-string (length (tm:topicmap-projection-topics-of projection)))))
                                (:td (v:esc (princ-to-string (length (tm:topicmap-projection-associations-of projection)))))
                                (:td (ref (reading-workspace reading variant show) "Topicmap workspace") " / " (ref projection "projection")))))))
      (:p "Role edges of the Association-as-node candidates carry the Role as a property; the edge candidate carries both Roles. "
          "Open a projected Topic to see the TMDM object it stands for.")
      (:ul (dolist (topic (tm:topicmap-projection-topics-of (reading-projection reading)))
             (v:html (:li (ref topic (format nil "~A (~A)" (tm:topicmap-topic-label-of topic) (getf (tm:topicmap-topic-view-properties-of topic) :kind))
                               "TMDM object or projected topic?")))))
      (:p (ref reading "Back to the TMDM objects" "TMDM objects")))))

(v:defview projected-topic-view (topic projected-tmdm-topic)
  (v:html-view :title "TMDM object or projected topic?" :priority 0
    (let* ((object (tm:topicmap-topic-object-of topic)) (reading (projection-origin topic)))
      (v:html
        (:h2 (v:esc (format nil "~A" (tm:topicmap-topic-label-of topic))))
        (:table :class "inspector-table"
          (:tr (:th "") (:th "TMDM object (topic-maps.tmdm)") (:th "Projected topic (dreyeck/topicmap)"))
          (:tr (:td "Object") (:td (ref object))
               (:td (ref topic "the projected Topic")))
          (:tr (:td "Identity")
               (:td (if (typep object 'tmdm:topic)
                        (v:html "item identifier " (:code (v:esc (identifiers object))) "; subject identifiers "
                                (v:esc (princ-to-string (length (tmdm:topic-subject-identifiers object)))) "; subject locators "
                                (v:esc (princ-to-string (length (tmdm:topic-subject-locators object)))))
                        (v:html "an Association has no identifier in this subset")))
               (:td "key " (:code (v:esc (tm:topicmap-topic-id-of topic))) ", a label cut from the identifier; E4, the key policy, is open"))
          (:tr (:td "Properties")
               (:td (if (typep object 'tmdm:topic)
                        (v:esc (format nil "names ~D, occurrences ~D, roles played ~D (computed)" (length (tmdm:topic-names object))
                                       (length (tmdm:topic-occurrences object)) (length (tmdm:topic-roles-played object))))
                        (v:esc (format nil "type ~A, ~D Roles" (topic-label (tmdm:association-type object)) (length (tmdm:association-roles object))))))
               (:td (v:esc (format nil "type ~S, kind ~A, position (~D, ~D), derived from a grid" (tm:topicmap-topic-type-of topic)
                                   (getf (tm:topicmap-topic-view-properties-of topic) :kind)
                                   (getf (tm:topicmap-topic-view-properties-of topic) :x) (getf (tm:topicmap-topic-view-properties-of topic) :y))))))
        (:p "The projected Topic's object is the TMDM item itself (EQ): "
            (v:esc (if (eq object (tm:topicmap-topic-object-of topic)) "yes" "no")) ". Opening the object gives its TMDM properties; opening the projected Topic gives its presentation.")
        (when (typep object 'tmdm:association)
          (v:html (:p "Its Roles, which a projection draws as edges or leaves to a property:")
            (:ul (dolist (role (tmdm:association-roles object))
                   (v:html (:li (ref role (format nil "~A: ~A" (topic-label (tmdm:association-role-type role)) (topic-label (tmdm:association-role-player role))))))))))
        (:p "A TMDM Topic is not a Work Topic and not a Story Item: it has no status, authorship or page. "
            "E3 is a Story Item that is about showing such objects.")
        (when reading (v:html (:p (ref reading "Back to the TMDM objects" "TMDM objects") " / " (ref reading "Projections" "Projections"))))))))

(v:defview projected-association-view (edge projected-tmdm-association)
  (v:html-view :title "TMDM object or projected edge?" :priority 0
    (let* ((properties (tm:topicmap-association-properties-of edge)) (reading (projection-origin edge)))
      (v:html
        (:h2 (v:esc (tm:topicmap-association-id-of edge)))
        (:p "A projected relation from " (:code (v:esc (tm:topicmap-association-from-of edge))) " to "
            (:code (v:esc (tm:topicmap-association-to-of edge))) ", labelled " (:code (v:esc (princ-to-string (tm:topicmap-association-type-of edge)))) ".")
        (:ul
          (when (getf properties :tmdm-role)
            (v:html (:li "the Role it stands for: " (ref (getf properties :tmdm-role) "TMDM Role")
                         ", its type " (ref (getf properties :role-type) (topic-label (getf properties :role-type))))))
          (when (getf properties :roles)
            (v:html (:li "both Roles: " (dolist (role (getf properties :roles)) (v:html (ref role "TMDM Role") " ")))))
          (:li "the Association: " (ref (getf properties :tmdm-association) "TMDM Association")
               ", its type " (ref (getf properties :association-type) (topic-label (getf properties :association-type)))))
        (:p "In TMDM the Role has no direction and no Topic of its own. The direction of this edge is presentation only.")
        (when reading (v:html (:p (ref reading "Back to the TMDM objects" "TMDM objects") " / " (ref reading "Projections" "Projections"))))))))
