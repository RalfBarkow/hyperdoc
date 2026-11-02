;;;; Reading one known Federated Wiki page when name resolution fails but a previously known IP endpoint answers.
;;;;
;;;; A small, inspectable record of what an experiment observed (docs/fedwiki-without-dns/README.md). It adds no wiki data structure and no
;;;; HTTP client: the page is fetched with drakma, the HTTP client HYPERBOOK/FEDWIKI already uses (its :REAL-HOST connects to a given
;;;; address while the URL, and with it the Host header, keeps the site's name), the JSON is installed with HYPERBOOK/FEDWIKI::SET-PAGE-DATA
;;;; on a HYPERBOOK/FEDWIKI::FEDWIKI-PAGE, and the digest comes from ironclad as in DREYECK/LOCAL-FEDWIKI-PAGE.
;;;;
;;;; Why not HYPERBOOK/FEDWIKI::FETCH-JSON: it takes no endpoint and returns only the parsed JSON, dropping the status and the octets whose
;;;; digest is the evidence. It is left as it is; this file does not touch the production client.
;;;;
;;;; Epistemic warrants. Every claim and every field is one of:
;;;;   :OBSERVED     measured by the observer when it made the request (a condition signalled, a status received, octets hashed)
;;;;   :DERIVED      computed from observed values (two digests compared)
;;;;   :INFERRED     a conclusion that goes beyond what was measured, with the assumption stated
;;;;   :HYPOTHESIZED not tested
;;;; No site identity is constructed from an IP address. Over HTTP without TLS the site's name is the one the observer put in the URL and
;;;; the Host header; nothing authenticates that the endpoint belongs to it.

(defpackage #:dreyeck/fedwiki-without-dns
  (:use #:cl)
  (:export #:+warrants+ #:warrant-p
           #:access-observation #:make-access-observation #:observation-id #:observation-role #:observation-site #:observation-slug
           #:observation-access #:observation-url #:observation-endpoint #:observation-endpoint-origin #:observation-dns
           #:observation-connection #:observation-http #:observation-tls #:observation-json-sha256 #:observation-octet-count
           #:observation-content #:observation-observed-at #:observation-warrant #:observation-verdict
           #:experiment-record #:record-title #:record-site #:record-slug #:record-fixture-sha256 #:record-fixture-octets
           #:record-recorded-at #:record-dns-failure #:record-environment #:record-observations #:record-limits #:find-observation
           #:claim #:claim-id #:claim-statement #:claim-warrant #:claim-basis #:derive-findings
           #:observe-access #:json-equal
           #:record-form #:read-record #:record-from-form #:observation-form #:observation-from-form #:write-form))
(in-package #:dreyeck/fedwiki-without-dns)

(defparameter +warrants+ '(:observed :derived :inferred :hypothesized))
(defun warrant-p (value) (and (member value +warrants+) t))

;;; The records

(defclass access-observation ()
  ((id :initarg :id :reader observation-id :documentation "A short label, unique in its record.")
   (role :initarg :role :reader observation-role
         :documentation ":BASELINE, :DNS-FAILURE, :EXPLICIT-ENDPOINT, or a control: :CONTROL-WRONG-ENDPOINT, :CONTROL-UNREACHABLE-ENDPOINT, :CONTROL-DIFFERENT-CONTENT.")
   (site :initarg :site :reader observation-site :documentation "The site identity as named: the host name of the URL.")
   (slug :initarg :slug :reader observation-slug)
   (access :initarg :access :reader observation-access :documentation ":ORDINARY-RESOLUTION or :EXPLICIT-ENDPOINT.")
   (url :initarg :url :reader observation-url)
   (endpoint :initarg :endpoint :initform nil :reader observation-endpoint :documentation "The address connected to instead of resolving the name, or NIL.")
   (endpoint-origin :initarg :endpoint-origin :initform nil :reader observation-endpoint-origin
                    :documentation "Where the endpoint mapping came from: (:EARLIER-RESOLUTION \"A\") or (:DECLARED \"text\"), or NIL.")
   (dns :initarg :dns :reader observation-dns
        :documentation "What a resolution of SITE gave when the observation was made: (:OUTCOME :RESOLVED :ADDRESSES (\"..\")) or (:OUTCOME :FAILED :CONDITION \"..\" :MESSAGE \"..\").")
   (connection :initarg :connection :reader observation-connection
               :documentation "(:OUTCOME :CONNECTED) or (:OUTCOME :FAILED :STAGE :NAME-RESOLUTION|:CONNECT|:TIMEOUT|:ERROR :CONDITION \"..\" :MESSAGE \"..\").")
   (http :initarg :http :initform nil :reader observation-http :documentation "(:STATUS 200), or NIL when no response was received.")
   (tls :initarg :tls :reader observation-tls :documentation "(:STATUS :NOT-PERFORMED :REASON \"..\") unless a TLS check was made.")
   (json-sha256 :initarg :json-sha256 :initform nil :reader observation-json-sha256 :documentation "SHA-256 of the response body octets, or NIL.")
   (octet-count :initarg :octet-count :initform nil :reader observation-octet-count)
   (content :initarg :content :initform nil :reader observation-content
            :documentation "(:RELATION :IDENTICAL-BYTES|:EQUIVALENT-JSON|:DIFFERENT|:NOT-JSON|:NOT-COMPARED :STORY-ITEMS n :JOURNAL-ENTRIES n :TITLE ..) compared with the stored page.")
   (observed-at :initarg :observed-at :reader observation-observed-at :documentation "Universal time.")
   (warrant :initarg :warrant :initform :observed :reader observation-warrant))
  (:documentation "One attempt to read the page, and what it observed."))

(defclass experiment-record ()
  ((title :initarg :title :reader record-title)
   (site :initarg :site :reader record-site)
   (slug :initarg :slug :reader record-slug)
   (fixture-sha256 :initarg :fixture-sha256 :reader record-fixture-sha256 :documentation "SHA-256 of the frozen stored page file.")
   (fixture-octets :initarg :fixture-octets :reader record-fixture-octets)
   (recorded-at :initarg :recorded-at :reader record-recorded-at)
   (dns-failure :initarg :dns-failure :reader record-dns-failure :documentation "How resolution was made to fail, as a string.")
   (environment :initarg :environment :initform nil :reader record-environment :documentation "A plist of strings describing the setup.")
   (observations :initarg :observations :reader record-observations)
   (limits :initarg :limits :initform nil :reader record-limits :documentation "Strings: what this record does not show."))
  (:documentation "The observations of one run of the experiment, in the order they were made."))

(defclass claim ()
  ((id :initarg :id :reader claim-id)
   (statement :initarg :statement :reader claim-statement)
   (warrant :initarg :warrant :reader claim-warrant)
   (basis :initarg :basis :initform nil :reader claim-basis :documentation "Observation ids and a note: what the claim rests on."))
  (:documentation "A statement about the record with the strength of its support."))

(defmethod print-object ((observation access-observation) stream)
  (print-unreadable-object (observation stream :type t)
    (format stream "~A ~A ~A" (observation-id observation) (observation-access observation) (observation-verdict observation))))
(defmethod print-object ((record experiment-record) stream)
  (print-unreadable-object (record stream :type t)
    (format stream "~A / ~A, ~D observations" (record-site record) (record-slug record) (length (record-observations record)))))
(defmethod print-object ((claim claim) stream)
  (print-unreadable-object (claim stream :type t) (format stream "~A ~A" (claim-id claim) (claim-warrant claim))))

(defun make-access-observation (&rest initargs) (apply #'make-instance 'access-observation initargs))

(defun find-observation (record id)
  (find id (record-observations record) :key #'observation-id :test #'equal))

(defun %get (plist key) (getf plist key))

(defun observation-verdict (observation)
  "What the observation amounts to, derived from its fields: :READ-IDENTICAL, :READ-DIFFERENT, :PAGE-ABSENT, :NOT-JSON, :RESOLUTION-FAILED, :UNREACHABLE or :FAILED."
  (let ((connection (observation-connection observation)) (status (%get (observation-http observation) :status)))
    (case (%get connection :outcome)
      (:connected (cond ((null status) :failed)
                        ((/= status 200) :page-absent)
                        (t (case (%get (observation-content observation) :relation)
                             ((:identical-bytes :equivalent-json) :read-identical)
                             (:different :read-different)
                             (:not-json :not-json)
                             (t :read-different)))))
      (:failed (case (%get connection :stage)
                 (:name-resolution :resolution-failed)
                 ((:connect :timeout) :unreachable)
                 (t :failed)))
      (t :failed))))

;;; Findings, derived from a record

(defun %claim (id statement warrant &rest basis) (make-instance 'claim :id id :statement statement :warrant warrant :basis basis))

(defun %hex (digest) (subseq digest 0 (min 12 (length digest))))

(defun derive-findings (record)
  "The claims a RECORD supports, each with its warrant. Computed from the observations only; a record that shows less supports fewer claims."
  (let* ((baseline (find :baseline (record-observations record) :key #'observation-role))
         (failed (find :dns-failure (record-observations record) :key #'observation-role))
         (explicit (find :explicit-endpoint (record-observations record) :key #'observation-role))
         (controls (remove-if-not (lambda (o) (member (observation-role o) '(:control-wrong-endpoint :control-unreachable-endpoint :control-different-content)))
                                  (record-observations record)))
         (claims '()))
    (flet ((add (&rest args) (push (apply #'%claim args) claims)))
      (when baseline
        (if (eq :read-identical (observation-verdict baseline))
            (add "baseline-read" (format nil "With working name resolution, ~A was read as ~A (HTTP ~A, SHA-256 ~A...)."
                                         (observation-site baseline) (observation-slug baseline)
                                         (%get (observation-http baseline) :status) (%hex (observation-json-sha256 baseline)))
                 :observed (observation-id baseline))
            (add "baseline-read" (format nil "The baseline did not read the stored page (~(~A~))." (observation-verdict baseline))
                 :observed (observation-id baseline))))
      (when failed
        (let ((dns (observation-dns failed)))
          (add "dns-failed"
               (if (eq :failed (%get dns :outcome))
                   (format nil "Under the controlled condition the name ~A did not resolve (~A); the ordinary retrieval made no connection and read nothing (~(~A~))."
                           (observation-site failed) (%get dns :condition) (observation-verdict failed))
                   (format nil "The controlled condition did not take effect: ~A still resolved." (observation-site failed)))
               :observed (observation-id failed))))
      (when explicit
        (let ((verdict (observation-verdict explicit)))
          (add "explicit-read"
               (format nil "Under the same failing resolution, a request for ~A with the given endpoint ~A ~A (HTTP ~A, SHA-256 ~A...)."
                       (observation-url explicit) (observation-endpoint explicit)
                       (ecase verdict (:read-identical "read the stored page") (:read-different "answered with other content")
                         (:page-absent "answered without the page") (:unreachable "did not answer") (:resolution-failed "failed to resolve")
                         (:not-json "answered with something that is not JSON") (:failed "failed"))
                       (or (%get (observation-http explicit) :status) "none")
                       (if (observation-json-sha256 explicit) (%hex (observation-json-sha256 explicit)) "none"))
               :observed (observation-id explicit))
          (when (and baseline (observation-json-sha256 baseline) (observation-json-sha256 explicit))
            (add "same-bytes"
                 (if (equal (observation-json-sha256 baseline) (observation-json-sha256 explicit))
                     "The octets read through the explicit endpoint have the same SHA-256 as those read through ordinary resolution."
                     "The octets read through the explicit endpoint differ from those read through ordinary resolution.")
                 :derived (observation-id baseline) (observation-id explicit)))
          (when (observation-json-sha256 explicit)
            (let ((relation (%get (observation-content explicit) :relation)))
              (add "same-as-stored"
                   (ecase relation
                     (:identical-bytes "The octets equal the frozen stored page file byte for byte.")
                     (:equivalent-json
                      (format nil "The JSON read equals the frozen stored page structurally (title, story and journal); the octets differ (~D against ~D in the file) because the original server serializes the page itself."
                              (observation-octet-count explicit) (record-fixture-octets record)))
                     ((:different :not-json :not-compared)
                      (format nil "The content differs from the frozen stored page (relation: ~(~A~))." relation)))
                   :derived (observation-id explicit) "stored page")))
          (add "same-site"
               (if (eq verdict :read-identical)
                   (format nil "The endpoint ~A served the page of ~A. Assumption: equal content is taken to show that this endpoint holds the same site's page; over HTTP without TLS nothing authenticates the endpoint, and the name is only the one the observer put in the URL."
                           (observation-endpoint explicit) (observation-site explicit))
                   (format nil "Nothing follows about whether ~A belongs to ~A: its answer was not the stored page." (observation-endpoint explicit) (observation-site explicit)))
               :inferred (observation-id explicit))))
      (dolist (control controls)
        (let ((verdict (observation-verdict control)) (id (observation-id control)) (endpoint (observation-endpoint control)))
          (flet ((control-claim (statement warrant) (add (format nil "control-~A" id) statement warrant id)))
            (ecase verdict
              (:page-absent (control-claim (format nil "Control ~A, the wrong endpoint ~A: it answered, with HTTP ~A and no page; it was not accepted."
                                                   id endpoint (%get (observation-http control) :status))
                                           :observed))
              (:unreachable (control-claim (format nil "Control ~A, the unreachable endpoint ~A: no connection (~(~A~): ~A); nothing was read."
                                                   id endpoint (%get (observation-connection control) :stage)
                                                   (%get (observation-connection control) :condition))
                                           :observed))
              (:read-different (control-claim (format nil "Control ~A, the endpoint ~A answered HTTP 200 with other content (SHA-256 ~A... against the stored ~A...); it was not accepted as the stored page."
                                                      id endpoint (%hex (observation-json-sha256 control)) (%hex (record-fixture-sha256 record)))
                                              :derived))
              (:read-identical (control-claim (format nil "Control ~A, the endpoint ~A: the stored page was read." id endpoint) :derived))
              ((:resolution-failed :not-json :failed)
               (control-claim (format nil "Control ~A, the endpoint ~A: ~(~A~)." id endpoint verdict) :observed))))))
      (add "tls" "No TLS check was made: the experiment used HTTP. A certificate check against the site name could authenticate the endpoint; that was not tested."
           :hypothesized)
      (add "other-conditions" "Other failures of name resolution, a production farm, and other pages were not tested; the result is shown for this site and this page only."
           :hypothesized))
    (nreverse claims)))

;;; Observing

(defun json-equal (a b)
  "Structural equality of two JSON values as SHASHT reads them (objects are hash tables, arrays vectors)."
  (typecase a
    (hash-table (and (hash-table-p b) (= (hash-table-count a) (hash-table-count b))
                     (loop for key being the hash-keys of a using (hash-value value)
                           always (multiple-value-bind (other present) (gethash key b)
                                    (and present (json-equal value other))))))
    (string (and (stringp b) (string= a b)))
    (vector (and (vectorp b) (not (stringp b)) (= (length a) (length b)) (every #'json-equal a b)))
    (t (equal a b))))

(defun %sha256 (octets) (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 octets)))

(defun %condition-text (condition) (remove #\Newline (princ-to-string condition)))
(defun %condition-name (condition) (let ((*package* (find-package :keyword))) (prin1-to-string (type-of condition))))

(defun %address-string (address)
  (if (stringp address) address (usocket:host-to-hostname address)))

(defun %resolve (site resolver)
  "What resolving SITE gives now. The RESOLVER is called with the name; any error is the answer."
  (handler-case (let ((addresses (funcall resolver site)))
                  (list :outcome :resolved :addresses (mapcar #'%address-string addresses)))
    (error (condition) (list :outcome :failed :condition (%condition-name condition) :message (%condition-text condition)))))

(defun %name-resolution-condition-p (condition)
  (or (typep condition 'usocket:ns-error)
      (typep condition (find-symbol "NAME-SERVICE-ERROR" "SB-BSD-SOCKETS"))))

(defun %get-octets (url endpoint timeout)
  "GET URL with drakma; with ENDPOINT, connect to that address while URL, and so the Host header, keeps the site's name. Returns the status and the octets."
  ;; drakma on SBCL has a connection timeout only; the whole request gets a bound of its own.
  (multiple-value-bind (body status)
      (sb-ext:with-timeout (* 3 timeout)
        (if endpoint
            (drakma:http-request url :method :get :force-binary t :redirect nil :real-host endpoint :connection-timeout timeout)
            (drakma:http-request url :method :get :force-binary t :redirect nil :connection-timeout timeout)))
    (values status body)))

(defun observe-access (site slug &key id (role :baseline) endpoint endpoint-origin stored-octets (timeout 5)
                                      (resolver #'usocket:get-hosts-by-name) (scheme "http"))
  "Try to read /SLUG.json of SITE and return the observation, and as a second value the FEDWIKI-PAGE built from the JSON, or NIL.
Without ENDPOINT the name is resolved as the client does; with ENDPOINT, that address is connected to and the URL keeps SITE's name.
STORED-OCTETS, the stored page file, is what the answer is compared with. Nothing is written. Never signals for a failed request."
  (check-type site string) (check-type slug string)
  (let* ((url (hyperbook/fedwiki::wiki-url site scheme (concatenate 'string "/" slug ".json")))
         (observed-at (get-universal-time))
         (dns (%resolve site resolver))
         (connection nil) (http nil) (sha nil) (count nil) (content nil) (page nil))
    (handler-case
        (multiple-value-bind (status octets) (%get-octets url endpoint timeout)
          (setf connection (list :outcome :connected) http (list :status status))
          (when (and octets (= status 200))
            (setf sha (%sha256 octets) count (length octets))
            (handler-case
                (let* ((json (shasht:read-json (sb-ext:octets-to-string octets :external-format :utf-8)))
                       (wiki (make-instance 'hyperbook/fedwiki::fedwiki :id (concatenate 'string "fedwiki:" site))))
                  (setf page (make-instance 'hyperbook/fedwiki::fedwiki-page :hyperbook wiki :id slug))
                  (hyperbook/fedwiki::set-page-data page json)
                  (setf content
                        (list :relation (cond ((null stored-octets) :not-compared)
                                              ((equal sha (%sha256 stored-octets)) :identical-bytes)
                                              ((json-equal json (shasht:read-json (sb-ext:octets-to-string stored-octets :external-format :utf-8)))
                                               :equivalent-json)
                                              (t :different))
                              :title (hyperbook:title-of page)
                              :story-items (length (hyperbook/fedwiki::story-of page))
                              :journal-entries (length (hyperbook/fedwiki::journal-of page)))))
              (error () (setf content (list :relation :not-json) page nil)))))
      ((or error sb-ext:timeout) (condition)
        (setf connection (list :outcome :failed
                               :stage (cond ((%name-resolution-condition-p condition) :name-resolution)
                                            ((or (typep condition 'usocket:timeout-error) (typep condition 'sb-ext:timeout)) :timeout)
                                            ((typep condition 'usocket:socket-error) :connect)
                                            ((typep condition 'stream-error) :connect)
                                            (t :error))
                               :condition (%condition-name condition) :message (%condition-text condition)))))
    (values (make-access-observation
             :id (or id (string (code-char (+ 64 (random 26)))))
             :role role :site site :slug slug :url url
             :access (if endpoint :explicit-endpoint :ordinary-resolution)
             :endpoint endpoint :endpoint-origin endpoint-origin
             :dns dns :connection connection :http http
             :tls (list :status :not-performed
                        :reason (if (equal scheme "https") "HTTPS requested but no certificate check implemented" "HTTP was used: no TLS, so no authenticated site identity"))
             :json-sha256 sha :octet-count count :content content :observed-at observed-at :warrant :observed)
            page)))

;;; The record as data: a form of keywords, strings and integers. Reading it evaluates nothing.


(defun observation-form (o)
  `(:observation :id ,(observation-id o) :role ,(observation-role o) :site ,(observation-site o) :slug ,(observation-slug o)
                 :access ,(observation-access o) :url ,(observation-url o) :endpoint ,(observation-endpoint o)
                 :endpoint-origin ,(observation-endpoint-origin o) :dns ,(observation-dns o) :connection ,(observation-connection o)
                 :http ,(observation-http o) :tls ,(observation-tls o) :json-sha256 ,(observation-json-sha256 o)
                 :octet-count ,(observation-octet-count o) :content ,(observation-content o)
                 :observed-at ,(observation-observed-at o) :warrant ,(observation-warrant o)))

(defun observation-from-form (form)
  (unless (and (consp form) (eq :observation (first form))) (error "Not an observation form: ~S" form))
  (destructuring-bind (&key id role site slug access url endpoint endpoint-origin dns connection http tls json-sha256 octet-count content
                         observed-at warrant) (rest form)
    (unless (warrant-p warrant) (error "Observation ~A has the warrant ~S, which is none of ~S." id warrant +warrants+))
    (make-access-observation :id id :role role :site site :slug slug :access access :url url :endpoint endpoint
                             :endpoint-origin endpoint-origin :dns dns :connection connection :http http :tls tls
                             :json-sha256 json-sha256 :octet-count octet-count :content content :observed-at observed-at :warrant warrant)))

(defun record-form (record)
  `(:fedwiki-without-dns-record :version 1 :title ,(record-title record) :site ,(record-site record) :slug ,(record-slug record)
                                :fixture-sha256 ,(record-fixture-sha256 record) :fixture-octets ,(record-fixture-octets record)
                                :recorded-at ,(record-recorded-at record) :dns-failure ,(record-dns-failure record)
                                :environment ,(record-environment record) :limits ,(record-limits record)
                                :observations ,(mapcar #'observation-form (record-observations record))))

(defun record-from-form (form)
  (unless (and (consp form) (eq :fedwiki-without-dns-record (first form))) (error "Not an experiment record form."))
  (destructuring-bind (&key version title site slug fixture-sha256 fixture-octets recorded-at dns-failure environment limits observations)
      (rest form)
    (unless (eql 1 version) (error "Unsupported record version ~S." version))
    (make-instance 'experiment-record :title title :site site :slug slug :fixture-sha256 fixture-sha256 :fixture-octets fixture-octets
                                      :recorded-at recorded-at :dns-failure dns-failure :environment environment :limits limits
                                      :observations (mapcar #'observation-from-form observations))))

(defun %plain-data-p (form)
  "Whether FORM holds only keywords, strings, integers, NIL, T and lists of them: data, which reading cannot have made into anything else."
  (typecase form
    (null t) ((eql t) t) (keyword t) (string t) (integer t)
    (cons (and (%plain-data-p (car form)) (%plain-data-p (cdr form))))
    (t nil)))

(defun read-record (pathname)
  "Read an experiment record file. The standard reader with *READ-EVAL* off, and only plain data accepted: no code runs, nothing is interned but keywords."
  (with-open-file (in pathname :external-format :utf-8)
    (let* ((*read-eval* nil) (*package* (find-package :cl-user)) (form (read in)))
      (when (read in nil nil) (error "~A holds more than one form." pathname))
      (unless (%plain-data-p form) (error "~A holds more than plain data." pathname))
      (record-from-form form))))

(defun write-form (form pathname)
  "Write FORM as one readable top-level form (plain data: keywords, strings, integers, NIL)."
  (with-open-file (out pathname :direction :output :if-exists :supersede :external-format :utf-8)
    (let ((*print-readably* nil) (*print-pretty* t) (*print-right-margin* 140) (*package* (find-package :cl-user)))
      (prin1 form out)
      (terpri out)))
  pathname)
