;;;; Operator-owned readback on the Catalog service Topic.

(in-package #:dreyeck/work/catalog-deployment-pr52)

(defclass catalog-service-topic (tm:topicmap-topic)
  ((latest :initform nil :accessor latest-service-observation)
   (pending :initform nil :accessor pending-service-observation)))

(defclass service-observation-request ()
  ((id :initarg :id :reader service-request-id)
   (service :initarg :service :reader service-request-service)
   (purpose :initarg :purpose :reader service-request-purpose)
   (consumer :initarg :consumer :reader service-request-consumer)
   (accept :initarg :accept :reader service-request-accept)
   (status :initform :prepared :accessor service-request-status)
   (evidence :initform nil :accessor service-request-evidence)))

(defvar *service-requests* (make-hash-table :test #'equal))
(defvar *service-requests-lock* (sb-thread:make-mutex :name "Catalog service read requests"))

(defun deployment-catalog-service (deployment)
  (sb-thread:with-mutex ((lock-of deployment))
    (or (catalog-service-of deployment)
        (setf (catalog-service-of deployment)
              (make-instance 'catalog-service-topic
                             :id "tag:dreyeck.ch,2026:hyperdoc/service/dreyeck.ch/hyperdoc.service"
                             :label "hyperdoc.service" :type :systemd-service :object deployment)))))

(defgeneric prepare-service-observation (service &key purpose consumer accept)
  (:documentation "Prepare a bounded observation of SERVICE for an operator to execute locally."))

(defmethod prepare-service-observation ((service catalog-service-topic)
                                        &key (purpose :inventory) consumer accept)
  (check-type purpose (member :baseline :inventory))
  (when (eq purpose :baseline)
    (let ((deployment (tm:topicmap-topic-object-of service)))
      (unless (and (publish-enabled-p deployment)
                   (eq :baseline (offered-step (plan-next deployment))))
        (error "Der Deployment-Plan bietet keine Bestandsaufnahme für diesen Dienst an."))))
  (sb-thread:with-mutex (*service-requests-lock*)
    (let ((pending (pending-service-observation service)))
      (when pending
        (if (and (eq purpose (service-request-purpose pending))
                 (equal consumer (service-request-consumer pending)))
            (return-from prepare-service-observation pending)
            (progn
              (remhash (service-request-id pending) *service-requests*)
              (setf (service-request-status pending) :superseded)))))
    (let* ((id (ironclad:byte-array-to-hex-string (ironclad:random-data 16)))
           (request (make-instance 'service-observation-request :id id :service service
                                   :purpose purpose :consumer consumer :accept accept)))
      (setf (gethash id *service-requests*) request
            (pending-service-observation service) request)
      request)))

(defun validate-service-observation (state revision system pid local-http public-http)
  (unless (and (member state '("active" "inactive" "failed" "activating"
                              "deactivating" "reloading" "maintenance" "refreshing")
                       :test #'equal)
               (or (equal revision "-") (hex-revision-p revision))
               (system-path-p system) (typep pid '(integer 0 *))
               (or (plusp pid) (equal revision "-"))
               (or (eql local-http 0) (typep local-http '(integer 100 599)))
               (or (eql public-http 0) (typep public-http '(integer 100 599))))
    (error "Ungültiger Beobachtungsbeleg für hyperdoc.service auf dreyeck.ch."))
  (list :at (get-universal-time) :state state :revision (unless (equal revision "-") revision)
        :system system :pid pid :http (list local-http public-http)))

(defun accept-service-baseline (service evidence)
  (let* ((deployment (tm:topicmap-topic-object-of service))
         (revision (getf evidence :revision))
         (receipt (list* :active-readback revision (getf evidence :system)
                         (getf evidence :pid) (getf evidence :http))))
    (when (and (equal "active" (getf evidence :state))
               (check-receipt deployment receipt))
      (record-receipt deployment receipt))))

(defun submit-service-observation (receipt)
  "Accept one operator-supplied receipt bound to a prepared service request."
  (destructuring-bind (id state revision system pid local-http public-http) receipt
    (check-type id string)
    (let* ((evidence (validate-service-observation state revision system pid local-http public-http))
           (request
             (sb-thread:with-mutex (*service-requests-lock*)
               (let* ((request (or (gethash id *service-requests*)
                                   (error "Dienstauftrag fehlt, wurde ersetzt oder bereits verwendet.")))
                      (service (service-request-service request)))
                 (remhash id *service-requests*)
                 (setf (pending-service-observation service) nil
                       (latest-service-observation service) evidence
                       (service-request-status request) :recorded
                       (service-request-evidence request) evidence)
                 request))))
      (when (eq :baseline (service-request-purpose request))
        (accept-service-baseline (service-request-service request) evidence))
      (when (service-request-accept request)
        (funcall (service-request-accept request) evidence))
      request)))

(defun service-observation-button (service purpose)
  (v:eval-button "Play · Lokale Dienstabfrage vorbereiten"
                 (policy:reviewed-thunk "catalog-service-status/prepare"
                   (prepare-service-observation service :purpose purpose))
                 "Erstellt einen lesenden Auftrag für hyperdoc.service auf dreyeck.ch"))

(defun render-service-evidence (evidence)
  (when evidence
    (v:html (:h3 "Laufender Catalog")
            (:p (v:esc (format nil "Beleg übernommen ~A" (observation-time (getf evidence :at)))))
            (:p (v:esc (format nil "Dienst ~A · PID ~D" (getf evidence :state) (getf evidence :pid))))
            (:p (:code (v:esc (or (getf evidence :revision) "Keine gemeldete Revision"))))
            (:p (:code (v:esc (getf evidence :system))))
            (:p (v:esc (format nil "HTTP lokal ~D · öffentlich ~D"
                               (first (getf evidence :http)) (second (getf evidence :http))))))))

(v:defview catalog-service-overview (service catalog-service-topic)
  (v:html-view :title "Dienst" :priority -100
    (v:html (:h2 "hyperdoc.service")
            (:p "Host dreyeck.ch · systemd · Catalog auf Port 8080")
            (:p (v:object-ref (deployment-server-topic (tm:topicmap-topic-object-of service))
                              :select "Host" :display "Host dreyeck.ch öffnen"))
            (render-service-evidence (latest-service-observation service))
            (:p (service-observation-button service :inventory)))))

(defun service-observation-script ()
  (uiop:read-file-string
   (asdf:system-relative-pathname "dreyeck/work/catalog-deployment-pr52"
                                  "dreyeck/work/catalog-service-status.sh")
   :external-format :utf-8))

(v:defview service-observation-instructions (request service-observation-request)
  (let ((service (service-request-service request)))
    (v:html-view :title "Auftrag" :priority -100
      (v:html (:h2 "Iststand von hyperdoc.service lesen")
              (:p "Host dreyeck.ch · Dienstzustand, PID, Quellrevision, aktive Generation und HTTP-Status")
              (:p (v:object-ref service :select "Dienst" :display "Dienst hyperdoc.service"))
              (ecase (service-request-status request)
                (:recorded (render-service-evidence (service-request-evidence request)))
                (:superseded (v:html (:p "Der Auftrag wurde durch einen neueren Auftrag ersetzt.")))
                (:prepared
                 (v:html
                   (:p "Führe den Befehl in einer bereits autorisierten administrativen Sitzung direkt auf dreyeck.ch aus.")
                   (:p "Die letzte Ausgabezeile im lokalen mREPL auswerten, um den Beleg diesem Auftrag zuzuordnen.")
                   (:pre :style "white-space:pre-wrap"
                         (v:esc (format nil "bash -s -- '~A' <<'HYPERDOC_SERVICE_STATUS'~%~AHYPERDOC_SERVICE_STATUS~%"
                                        (service-request-id request) (service-observation-script)))))))))))
