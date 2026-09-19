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
