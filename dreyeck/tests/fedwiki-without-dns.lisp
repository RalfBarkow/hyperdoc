;;;; The record of reading a Wiki page without DNS: its data, its derivations, and the observer against a loopback server.
;;;; No external network, no wiki site. The loopback part is the small, process-local experiment: the resolver is injected, so it shows
;;;; that a request with a given endpoint reads the page while the name is unresolved; it does not show a DNS failure of the real stack
;;;; (that is the experiment in tests/fedwiki-without-dns, in two network namespaces).
(defpackage #:dreyeck/fedwiki-without-dns/tests
  (:use #:cl)
  (:local-nicknames (#:x #:dreyeck/fedwiki-without-dns))
  (:export #:run-tests))
(in-package #:dreyeck/fedwiki-without-dns/tests)

(defun rejects (thunk) (handler-case (progn (funcall thunk) nil) (error () t)))

(defparameter +page+ "{\"title\":\"T\",\"story\":[{\"id\":\"1\",\"type\":\"paragraph\",\"text\":\"a\"}],\"journal\":[{\"type\":\"create\",\"id\":\"2\",\"item\":{\"title\":\"T\"},\"date\":1}]}")
(defun octets (string) (sb-ext:string-to-octets string :external-format :utf-8))
(defun sha (string) (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 (octets string))))

(defun check-json-equal ()
  (flet ((json (string) (shasht:read-json string)))
    (assert (x:json-equal (json +page+) (json (concatenate 'string "  " +page+ (string #\Newline)))))
    (assert (not (x:json-equal (json +page+) (json (substitute #\b #\a +page+ :start 40)))))
    (assert (not (x:json-equal (json "[1,2]") (json "[1,2,3]"))))
    (assert (not (x:json-equal (json "{\"a\":1}") (json "{\"a\":1,\"b\":2}"))))
    (assert (x:json-equal (json "{\"a\":[1,{\"b\":\"c\"}]}") (json "{\"a\":[1,{\"b\":\"c\"}]}")))
    (assert (not (x:json-equal (json "\"1\"") (json "1")))))
  t)

;;; A loopback server whose answers a test chooses: path -> (status . body), the body a string.

(defclass test-acceptor (hunchentoot:acceptor)
  ((answers :initarg :answers :accessor answers)
   (hosts :initform '() :accessor hosts :documentation "The Host header of each request as the server received it, newest first.")))
(defmethod hunchentoot:acceptor-dispatch-request ((acceptor test-acceptor) request)
  (push (hunchentoot:host request) (hosts acceptor))
  (let ((answer (assoc (hunchentoot:script-name request) (answers acceptor) :test #'string=)))
    (cond (answer (setf (hunchentoot:return-code*) (second answer)
                        (hunchentoot:content-type*) "application/json")
                  (third answer))
          (t (setf (hunchentoot:return-code*) 404) "not found"))))

(defmacro with-server ((port answers) &body body)
  "Run BODY with PORT bound to a loopback server; the symbol ACCEPTOR is bound to it too, so that a test can ask what it received."
  `(let ((acceptor (make-instance 'test-acceptor :address "127.0.0.1" :port 0 :answers ,answers :access-log-destination nil :message-log-destination nil)))
     (hunchentoot:start acceptor)
     (unwind-protect (let ((,port (hunchentoot:acceptor-port acceptor))) ,@body)
       (hunchentoot:stop acceptor))))

(defun failing-resolver (name) (declare (ignore name)) (error 'usocket:ns-try-again-error :socket nil :host-or-ip "x"))

(defun check-observer-against-loopback ()
  (let ((slug "page") (altered (substitute #\b #\a +page+ :start 40)))
    (with-server (port `(("/page.json" 200 ,+page+) ("/other.json" 200 ,altered) ("/notjson.json" 200 "<html>")))
      (let ((stored (octets +page+)) (name (format nil "wiki.without-dns.test:~D" port)))
        ;; ordinary resolution: localhost resolves without a network (hosts file)
        (let ((o (x:observe-access (format nil "localhost:~D" port) slug :id "A" :stored-octets stored)))
          (assert (eq :read-identical (x:observation-verdict o)) () "~S" o)
          (assert (equal (sha +page+) (x:observation-json-sha256 o)))
          (assert (eq :identical-bytes (getf (x:observation-content o) :relation)))
          (assert (equal '(:status :not-performed) (subseq (x:observation-tls o) 0 2)))
          (assert (null (x:observation-endpoint o))) (assert (eq :ordinary-resolution (x:observation-access o))))
        ;; the name does not resolve (injected), the endpoint is given: the page is read, and the site stays the site named in the URL
        (multiple-value-bind (o page)
            (x:observe-access name slug :id "C" :role :explicit-endpoint :endpoint "127.0.0.1" :stored-octets stored
                                        :endpoint-origin '(:declared "loopback") :resolver #'failing-resolver)
          (assert (eq :failed (getf (x:observation-dns o) :outcome)))
          (assert (search "NS-TRY-AGAIN-ERROR" (getf (x:observation-dns o) :condition)))
          (assert (eq :connected (getf (x:observation-connection o) :outcome)))
          (assert (eq :read-identical (x:observation-verdict o)))
          (assert (eq :explicit-endpoint (x:observation-access o)))
          (assert (equal name (x:observation-site o)) () "the site identity is the name that was put in the URL")
          (assert (not (search "127.0.0.1" (x:observation-site o))) () "no site identity from an address")
          (assert (search name (x:observation-url o)))
          ;; the library's own page class holds what was read
          (assert (typep page 'hyperbook/fedwiki::fedwiki-page))
          (assert (= 1 (length (hyperbook/fedwiki::story-of page))))
          (assert (equal "T" (hyperbook:title-of page))))
        ;; The Host header the server received: the site's name with the port, whatever address was connected to; the address is never the Host
        (let ((hosts (reverse (hosts acceptor))))
          (assert (equal (list (format nil "localhost:~D" port) name) (subseq hosts 0 2)) () "Host headers received: ~S" hosts)
          (assert (notany (lambda (host) (search "127.0.0.1" host)) hosts) () "the address reached the server as Host: ~S" hosts))
        ;; negative controls
        (let ((o (x:observe-access name "missing" :id "D" :role :control-wrong-endpoint :endpoint "127.0.0.1" :stored-octets stored)))
          (assert (eq :page-absent (x:observation-verdict o))) (assert (null (x:observation-json-sha256 o))))
        (let ((o (x:observe-access name "other" :id "F" :role :control-different-content :endpoint "127.0.0.1" :stored-octets stored)))
          (assert (eq :read-different (x:observation-verdict o)))
          (assert (eq :different (getf (x:observation-content o) :relation)))
          (assert (not (equal (sha +page+) (x:observation-json-sha256 o)))))
        (let ((o (x:observe-access name "notjson" :id "G" :endpoint "127.0.0.1" :stored-octets stored)))
          (assert (eq :not-json (x:observation-verdict o))))
        ;; the same bytes in another layout are the same JSON
        (with-server (port2 `(("/page.json" 200 ,(concatenate 'string "  " +page+ (string #\Newline)))))
          (let ((o (x:observe-access (format nil "localhost:~D" port2) slug :stored-octets stored)))
            (assert (eq :equivalent-json (getf (x:observation-content o) :relation)))
            (assert (eq :read-identical (x:observation-verdict o)))
            (assert (not (equal (sha +page+) (x:observation-json-sha256 o))))))))
    ;; nothing listens: unreachable, and no condition escapes
    (let ((o (x:observe-access "wiki.without-dns.test:1" slug :id "E" :endpoint "127.0.0.1" :stored-octets (octets +page+) :timeout 2)))
      (assert (eq :unreachable (x:observation-verdict o)) () "~S" (x:observation-connection o))
      (assert (null (x:observation-http o)))
      (assert (member (getf (x:observation-connection o) :stage) '(:connect :timeout)))))
  t)

;;; Derivations over records made by hand

(defun observation (id role access &key endpoint dns connection status sha content)
  (x:make-access-observation :id id :role role :site "wiki.test" :slug "p" :access access :url "http://wiki.test/p.json"
                             :endpoint endpoint :dns (or dns '(:outcome :resolved :addresses ("10.0.0.1")))
                             :connection (or connection '(:outcome :connected)) :http (and status (list :status status))
                             :tls '(:status :not-performed :reason "http") :json-sha256 sha :octet-count (and sha 10)
                             :content content :observed-at 1 :warrant :observed))

(defun record (&rest observations)
  (make-instance 'x:experiment-record :title "t" :site "wiki.test" :slug "p" :fixture-sha256 "FFFF" :fixture-octets 12 :recorded-at 1
                                      :dns-failure "servfail" :observations observations :limits '("a limit")))

(defparameter +same+ '(:relation :identical-bytes))
(defparameter +failed-dns+ '(:outcome :failed :condition "USOCKET:NS-TRY-AGAIN-ERROR" :message "m"))

(defun warrants-of (claims) (mapcar (lambda (c) (cons (x:claim-id c) (x:claim-warrant c))) claims))

(defun check-derivations ()
  (let* ((a (observation "A" :baseline :ordinary-resolution :status 200 :sha "FFFF" :content +same+))
         (b (observation "B" :dns-failure :ordinary-resolution :dns +failed-dns+
                         :connection '(:outcome :failed :stage :name-resolution :condition "USOCKET:NS-TRY-AGAIN-ERROR" :message "m")))
         (c (observation "C" :explicit-endpoint :explicit-endpoint :endpoint "10.0.0.1" :dns +failed-dns+ :status 200 :sha "FFFF" :content +same+))
         (claims (x:derive-findings (record a b c))) (warrants (warrants-of claims)))
    (assert (eq :resolution-failed (x:observation-verdict b)))
    (assert (equal '((("baseline-read" . :observed) ("dns-failed" . :observed) ("explicit-read" . :observed) ("same-bytes" . :derived)
                      ("same-as-stored" . :derived) ("same-site" . :inferred) ("tls" . :hypothesized) ("other-conditions" . :hypothesized)))
                   (list warrants))
            () "~S" warrants)
    (assert (every (lambda (c) (x:warrant-p (x:claim-warrant c))) claims))
    ;; the identity is inferred, never observed, and the claim says what it assumes
    (assert (search "Assumption" (x:claim-statement (find "same-site" claims :key #'x:claim-id :test #'string=)))))
  ;; the endpoint answered, but with something else: nothing follows about the site
  (let* ((a (observation "A" :baseline :ordinary-resolution :status 200 :sha "FFFF" :content +same+))
         (c (observation "C" :explicit-endpoint :explicit-endpoint :endpoint "10.0.0.9" :dns +failed-dns+ :status 200 :sha "EEEE"
                         :content '(:relation :different)))
         (claims (x:derive-findings (record a c))))
    (assert (eq :read-different (x:observation-verdict c)))
    (assert (search "Nothing follows" (x:claim-statement (find "same-site" claims :key #'x:claim-id :test #'string=))))
    (assert (search "differ" (x:claim-statement (find "same-bytes" claims :key #'x:claim-id :test #'string=)))))
  ;; the endpoint did not answer
  (let* ((c (observation "C" :explicit-endpoint :explicit-endpoint :endpoint "10.0.0.9" :dns +failed-dns+
                         :connection '(:outcome :failed :stage :timeout :condition "USOCKET:TIMEOUT-ERROR" :message "m")))
         (claims (x:derive-findings (record c))))
    (assert (eq :unreachable (x:observation-verdict c)))
    (assert (search "did not answer" (x:claim-statement (find "explicit-read" claims :key #'x:claim-id :test #'string=))))
    (assert (null (find "same-as-stored" claims :key #'x:claim-id :test #'string=))))
  ;; the failure condition did not take effect: the record says so instead of claiming a failure
  (let* ((b (observation "B" :dns-failure :ordinary-resolution :status 200 :sha "FFFF" :content +same+))
         (claim (find "dns-failed" (x:derive-findings (record b)) :key #'x:claim-id :test #'string=)))
    (assert (search "did not take effect" (x:claim-statement claim))))
  ;; controls
  (let* ((d (observation "D" :control-wrong-endpoint :explicit-endpoint :endpoint "10.0.0.3" :dns +failed-dns+ :status 404))
         (e (observation "E" :control-unreachable-endpoint :explicit-endpoint :endpoint "10.0.0.9" :dns +failed-dns+
                         :connection '(:outcome :failed :stage :connect :condition "X" :message "m")))
         (f (observation "F" :control-different-content :explicit-endpoint :endpoint "10.0.0.4" :dns +failed-dns+ :status 200 :sha "EEEE"
                         :content '(:relation :different)))
         (claims (x:derive-findings (record d e f))))
    (assert (equal '(("control-D" . :observed) ("control-E" . :observed) ("control-F" . :derived))
                   (remove-if-not (lambda (p) (uiop:string-prefix-p "control-" (car p))) (warrants-of claims)))))
  t)

;;; The record as data

(defun check-record-data ()
  (let* ((a (observation "A" :baseline :ordinary-resolution :status 200 :sha "FFFF" :content +same+))
         (record (record a))
         (file (merge-pathnames (format nil "without-dns-record-~D.lisp-data" (random 1000000 (make-random-state t))) (uiop:temporary-directory))))
    (unwind-protect
         (progn
           (x:write-form (x:record-form record) file)
           (let ((back (x:read-record file)))
             (assert (equal (x:record-form record) (x:record-form back)))
             (assert (equal "A" (x:observation-id (first (x:record-observations back))))))
           ;; reading evaluates nothing and accepts only plain data
           (flet ((write-text (text) (with-open-file (out file :direction :output :if-exists :supersede) (write-string text out))))
             (let ((canary (merge-pathnames "without-dns-canary" (uiop:temporary-directory))))
               (ignore-errors (delete-file canary))
               (write-text (format nil "(:fedwiki-without-dns-record :version 1 :title #.(with-open-file (o ~S :direction :output) \"x\"))" (namestring canary)))
               (assert (rejects (lambda () (x:read-record file))))
               (assert (not (probe-file canary)) () "reading evaluated code"))
             (write-text "(:fedwiki-without-dns-record :version 1 :title SOME-SYMBOL)")
             (assert (rejects (lambda () (x:read-record file))))
             (write-text "(:fedwiki-without-dns-record :version 2)")
             (assert (rejects (lambda () (x:read-record file))))
             (write-text "(:something-else)")
             (assert (rejects (lambda () (x:read-record file))))
             (write-text "()")
             (assert (rejects (lambda () (x:read-record file))))
             ;; a warrant outside the four is refused
             (let ((form (x:observation-form a)))
               (setf (getf (rest form) :warrant) :certain)
               (assert (rejects (lambda () (x:observation-from-form form)))))))
      (ignore-errors (delete-file file))))
  t)

(defun run-tests ()
  (check-json-equal)
  (check-derivations)
  (check-record-data)
  (check-observer-against-loopback)
  (format t "~&FEDWIKI-WITHOUT-DNS-PASS: JSON equality, derivations by warrant, the record as plain data, the observer against a loopback server.~%")
  t)
