;;;; Presentation only: the reading's claim plists remain the source of truth.
(in-package #:dreyeck/lisp-critic/reading)

(defclass historical-claims-inspection ()
  ((data :initarg :data :reader inspection-data)
   (claims :reader inspection-claims))
  (:documentation "Presentation carrier for the existing example plist."))

(defclass historical-claim-inspection ()
  ((claim :initarg :claim :reader inspection-claim))
  (:documentation "Drill-down reference to an existing claim, without copying."))

(defmethod initialize-instance :after ((inspection historical-claims-inspection)
                                       &key)
  (setf (slot-value inspection 'claims)
        (mapcar (lambda (claim)
                  (make-instance 'historical-claim-inspection :claim claim))
                (getf (inspection-data inspection) :claims))))

(defun claim-display-text (value)
  (cond ((null value) "not observed")
        ((eq t value) "observed")
        ((eq :runtime-dependent value) "runtime-dependent")
        ((eq :none-observed value) "cited, not observed in this workspace")
        ((symbolp value) (substitute #\Space #\- (string-downcase value)))
        ((listp value) (format nil "~{~A~^, ~}" (mapcar #'claim-display-text value)))
        (t (princ-to-string value))))

(defun claim-observation-text (value)
  (if value "yes (observed)" "no (not observed)"))

(defun claim-assertion-text (claim)
  (if (eq :fischer-to-riesbeck (getf claim :subject))
      "no attribution/reference observed; no source-provenance link observed"
      (getf claim :assertion)))

(defun claim-view-row (label text)
  (html-inspector-views:html
    (:tr (:th (html-inspector-views:esc label))
         (:td (html-inspector-views:esc text)))))

(html-inspector-views:defview historical-claims-overview
    (inspection historical-claims-inspection)
  (html-inspector-views:html-view :title "Historical claims" :priority 1
    (html-inspector-views:html
      (:h2 "Historical claims")
      (:p "Select a claim to distinguish its citation, observed evidence and artifact status.")
      (dolist (subject (remove-duplicates
                       (mapcar (lambda (item) (getf (inspection-claim item) :subject))
                               (inspection-claims inspection))
                       :from-end t))
        (html-inspector-views:html
          (:h3 (html-inspector-views:esc (claim-display-text subject)))
          (:table :class "inspector-table"
            (:tr (:th "Claim type") (:th "Assertion / detail")
                 (:th "Observed evidence"))
            (dolist (item (inspection-claims inspection))
              (let ((claim (inspection-claim item)))
                (when (eq subject (getf claim :subject))
                  (html-inspector-views:html
                    (:tr
                     (:td (html-inspector-views:esc
                           (claim-display-text (getf claim :claim-type))))
                     (:td (html-inspector-views:object-ref
                           item :display (claim-assertion-text claim)))
                     (:td (html-inspector-views:esc
                           (claim-display-text (getf claim :observed-evidence-kind)))))))))))))))

(html-inspector-views:defview historical-claim-detail
    (inspection historical-claim-inspection)
  (html-inspector-views:html-view :title "Historical claim" :priority 1
    (let ((claim (inspection-claim inspection)))
      (html-inspector-views:html
        (:h2 "Claim")
        (:table :class "inspector-table"
          (claim-view-row "subject" (claim-display-text (getf claim :subject)))
          (claim-view-row "claim-type" (claim-display-text (getf claim :claim-type)))
          (claim-view-row "assertion" (claim-assertion-text claim)))
        (:h2 "Cited Source")
        (:table :class "inspector-table"
          (claim-view-row "cited-source-kind" (claim-display-text (getf claim :cited-source-kind)))
          (claim-view-row "locator" (claim-display-text (getf claim :locator)))
          (claim-view-row "locator observed" (claim-observation-text (getf claim :locator-observed-p)))
          (claim-view-row "witness" (claim-display-text (getf claim :witness))))
        ;; A locator that only names a source leaves the reader to go and
        ;; find it. Where a passage has been recorded, offer it directly.
        (let ((passage (source-passage-for claim)))
          (if passage
              (html-inspector-views:html
                (:p "Supporting passage: "
                    (html-inspector-views:object-ref passage)))
              (html-inspector-views:html
                (:p (html-inspector-views:esc
                     "No supporting passage has been recorded for this claim yet.")))))
        (:h2 "Observed Evidence")
        (:table :class "inspector-table"
          (claim-view-row "observed-evidence-kind" (claim-display-text (getf claim :observed-evidence-kind)))
          (claim-view-row "observed-locator" (claim-display-text (getf claim :observed-locator))))
        (:h2 "Artifact Status")
        (:table :class "inspector-table"
          (claim-view-row "source observed" (claim-observation-text (getf claim :source-observed-p)))
          (claim-view-row "executable-here-p"
                          (if (eq :runtime-dependent (getf claim :executable-here-p))
                              "runtime-dependent"
                              (if (getf claim :executable-here-p) "yes" "no")))
          (claim-view-row "executable" (if (resolve-executability claim) "yes" "no")))))))

(defun historical-raw-view (data)
  (html-inspector-views:html-view :title "Raw Lisp" :priority 90
    (html-inspector-views:html
      (:p (html-inspector-views:object-ref data :display "Inspect original plist / cons"))
      (:pre (html-inspector-views:esc (write-to-string data :pretty t))))))

(html-inspector-views:defview historical-claims-raw
    (inspection historical-claims-inspection)
  (historical-raw-view (inspection-data inspection)))

(html-inspector-views:defview historical-claim-raw
    (inspection historical-claim-inspection)
  (historical-raw-view (inspection-claim inspection)))

;; Adapt only the existing historical example envelope. Ordinary cons views
;; remain available, and the example's return value and data stay unchanged.
(html-inspector-views:defview historical-claims-example-overview (data cons)
  (when (and (eq :kind (first data))
             (consp (rest data))
             (eq :historical-claims (second data)))
    (let ((inspection (make-instance 'historical-claims-inspection :data data)))
      (list (historical-claims-overview inspection)
            (historical-claims-raw inspection)))))

;;
;; Station and discourse detail, for topics followed in a projection.
;;
;; Same approach as above: no domain classes, only presentation carriers
;; over the plists that already exist. Each view discriminates on the
;; plist's own leading key, so ordinary cons views stay available and
;; unrelated lists are untouched.
;;

(defun station-field-rows (station)
  (html-inspector-views:html
    (:table
     (claim-view-row "Name" (or (getf station :name) "unnamed"))
     (claim-view-row "Period" (or (getf station :period) "unspecified"))
     (claim-view-row "Authors"
                     (format nil "~{~A~^, ~}" (getf station :authors)))
     (claim-view-row "Language" (or (getf station :language) "unspecified"))
     (claim-view-row "Runtime" (or (getf station :runtime) "unspecified"))
     (claim-view-row "Source status"
                     (claim-display-text (getf station :source-availability)))
     (claim-view-row "Executable here"
                     (if (getf station :executable-here) "yes" "no")))))

(defun node-kind-label (station)
  "What kind of thing this node is, rather than the projection's word for it.

\"Station\" is how the topicmap types the node; it says where the thing
sits in a diagram, not what it is. A reader arriving at LISP-CRITIC needs
the second. Both answers below come from the node's own record."
  (if (eq :research (getf station :line))
      "System (documented, not present here)"
      "Codebase"))

(defun render-relation-list (edges empty)
  (html-inspector-views:html
    (if edges
        (html-inspector-views:html
          (:ul
           (dolist (edge edges)
             (let ((topic (cdr edge)))
               (html-inspector-views:html
                 (:li (html-inspector-views:esc
                       (claim-display-text (car edge)))
                      " → "
                      (if topic
                          (html-inspector-views:object-ref
                           (dreyeck/topicmap:topicmap-topic-object-of topic)
                           :display (dreyeck/topicmap:topicmap-topic-label-of
                                     topic))
                          (html-inspector-views:esc "(unknown node)"))))))))
        (html-inspector-views:html
          (:p (html-inspector-views:esc empty))))))

(html-inspector-views:defview genealogy-station-overview (station cons)
  (when (eq :station (first station))
    (let* ((relations (genealogy-node-relations (station-node-id station)))
           (subjects (claim-subjects-relevant-to-node (getf station :station)))
           (claims (apply #'claims-about-subjects subjects)))
      (list
       (html-inspector-views:html-view
           :title (node-kind-label station) :priority 1
         (station-field-rows station))
       (html-inspector-views:html-view :title "Relations" :priority 2
         (html-inspector-views:html
           (:p (html-inspector-views:esc
                "As the genealogy has them. This node may have several, of different kinds, in either direction."))
           (:h3 "Outgoing")
           (render-relation-list (getf relations :outgoing)
                                 "This node leads nowhere in the genealogy.")
           (:h3 "Incoming")
           (render-relation-list (getf relations :incoming)
                                 "Nothing in the genealogy leads here.")))
       (html-inspector-views:html-view :title "Related claims" :priority 3
         (html-inspector-views:html
           (if claims
               (html-inspector-views:html
                 (:ul (dolist (claim claims)
                        (html-inspector-views:html
                          (:li (html-inspector-views:object-ref claim))))))
               ;; What is true here is that nothing is linked, which is not
               ;; the same as nothing being argued. Claims speak about
               ;; stages and aspects under their own keys; a node with no
               ;; declared subjects simply has none pointed at it.
               (html-inspector-views:html
                 (:p (html-inspector-views:esc
                      "No claims are linked to this genealogy node."))))))
       (historical-raw-view station)))))

(html-inspector-views:defview documented-stage-overview (stage cons)
  (when (and (eq :kind (first stage))
             (eq :documented-stage (second stage)))
    (list
     (html-inspector-views:html-view :title "Documented stage" :priority 1
       (html-inspector-views:html
         (:p (html-inspector-views:esc (getf stage :label)))
         (:p (html-inspector-views:esc
              "No artifact for this stage is present in this workspace. It is documented by the claims below."))
         (:ul (dolist (claim (getf stage :claims))
                (html-inspector-views:html
                  (:li (html-inspector-views:object-ref claim)))))))
     (historical-raw-view stage))))

(html-inspector-views:defview discourse-claim-overview (claim cons)
  (when (and (eq :kind (first claim))
             (eq :discourse-claim (second claim)))
    (list
     (html-inspector-views:html-view :title "Claim" :priority 1
       (html-inspector-views:html
         (:p (html-inspector-views:esc (getf claim :statement)))
         (:table (claim-view-row "Support" (getf claim :support)))
         (:p (html-inspector-views:esc "Provenance records behind this claim:"))
         (:ul (dolist (record (getf claim :related-claims))
                (html-inspector-views:html
                  (:li (html-inspector-views:object-ref record)))))))
     (historical-raw-view claim))))

;;
;; The passage a claim rests on.
;;
;; The point of this view is comparison: the reader sees the claim and the
;; wording side by side and can tell whether the claim overstates it. That
;; only works if the view is honest about whether the wording itself was
;; read here.
;;

(html-inspector-views:defview source-passage-overview (passage cons)
  (when (and (eq :kind (first passage))
             (eq :source-passage (second passage)))
    (list
     (html-inspector-views:html-view :title "Source passage" :priority 1
       (html-inspector-views:html
         (:h2 (html-inspector-views:esc (getf passage :source)))
         (:table :class "inspector-table"
           (claim-view-row "title" (getf passage :title))
           (claim-view-row "published in" (getf passage :bibliographic))
           (claim-view-row "location" (getf passage :location)))
         (:h2 "Supports")
         (:p (html-inspector-views:esc (getf passage :supports)))
         (:h2 "Passage")
         (:blockquote (html-inspector-views:esc (getf passage :passage)))
         (:h2 "Status of this passage")
         (:table :class "inspector-table"
           (claim-view-row "read in this workspace"
                           (claim-observation-text
                            (getf passage :passage-observed-p)))
           (claim-view-row "how it got here"
                           (claim-display-text
                            (getf passage :passage-origin))))
         (unless (getf passage :passage-observed-p)
           (html-inspector-views:html
             (:p (html-inspector-views:esc
                  "This wording has not been read from the source in this workspace. It is shown so the claim can be compared against it, not as a verified quotation. Placing the paper in the workspace is what would change that."))))
         (let ((claim (claim-for-source-passage passage)))
           (when claim
             (html-inspector-views:html
               (:h2 "Claim")
               (:p "Back to the claim this supports: "
                   (html-inspector-views:object-ref claim)))))))
     (historical-raw-view passage))))
