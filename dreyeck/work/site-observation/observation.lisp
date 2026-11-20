;;;; Site observation: read-only HTTPS checks of the Dreyeck hosts and sites, one Play per site.
;;;; Play runs curl from this image and records what the site served. It opens no SSH session and
;;;; sends nothing but GET requests. Host-internal checks (active system, running nginx) are a later step.
(defpackage #:site-observation
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views) (#:dita #:dreyeck/dita-story-item)
                    (#:policy #:dreyeck/authority-policy) (#:hb #:hyperbook))
  (:export #:open-task #:trust-staging-roots #:source-state #:observe-site #:plan-next #:offered-sites #:*sites* #:site-host
           #:observations-of #:latest-observation #:*max-age-seconds*))
(in-package #:site-observation)

;;; What should be served. Source: fleet 03b6c71 (PR #5) and staging 2bab5ba pin RalfBarkow/wiki 7dd4055,
;;; whose package is wiki 0.41.1. Update these values with the fleet pin.
(defparameter +expected-wiki+ "0.41.1")
(defparameter +dialog-fix+ "event.origin !== window.location.origin")
(defvar *max-age-seconds* (* 24 60 60))

(defclass site ()
  ((id :initarg :id :reader site-id)
   (host :initarg :host :reader site-host)
   (machine :initarg :machine :reader site-machine)
   (kind :initarg :kind :reader site-kind)          ; :fedwiki or :hyperdoc-catalog
   (ca-file :initarg :ca-file :initform nil :accessor site-ca-file)
   (observations :initform nil :accessor observations-of)))

(defun make-site (id host machine kind)
  (make-instance 'site :id id :host host :machine machine :kind kind))

(defvar *sites*
  (list (make-site :dreyeck-ch "dreyeck.ch" "dreyeck.ch" :hyperdoc-catalog)
        (make-site :hyperdoc-dreyeck-ch "hyperdoc.dreyeck.ch" "dreyeck.ch" :fedwiki)
        (make-site :discourse-dreyeck-ch "discourse.dreyeck.ch" "dreyeck.ch" :fedwiki)
        (make-site :wiki-ralfbarkow-ch "wiki.ralfbarkow.ch" "wiki.ralfbarkow.ch" :fedwiki)
        ;; Let's Encrypt staging certificate: set SITE-CA-FILE to the staging roots to observe it.
        (make-site :staging-dreyeck-ch "staging.dreyeck.ch" "staging.dreyeck.ch" :fedwiki)))

(defun find-site (id) (find id *sites* :key #'site-id))
(defun latest-observation (site) (first (observations-of site)))

;;; Fetching

(defun curl (site path &rest options)
  "Run curl for https://HOST/PATH; return stdout and exit code. The image's library path is not inherited."
  (multiple-value-bind (out err exit)
      (uiop:run-program (append (list "env" "-u" "LD_LIBRARY_PATH" "-u" "DYLD_LIBRARY_PATH"
                                      "curl" "-sS" "--max-time" "20" "--proto" "=https")
                                (when (site-ca-file site) (list "--cacert" (namestring (site-ca-file site))))
                                options
                                (list (format nil "https://~A~A" (site-host site) path)))
                        :output :string :error-output :string :ignore-error-status t)
    (values out exit (string-trim '(#\Newline #\Space) err))))

(defun field-line (text prefix)
  (loop for line in (uiop:split-string text :separator '(#\Newline))
        when (uiop:string-prefix-p prefix line)
          return (string-trim " " (subseq line (length prefix)))))

(defun wiki-version (json)
  (handler-case (let ((data (shasht:read-json json)))
                  (and (hash-table-p data) (gethash "wiki" data)))
    (error () nil)))

(defun version>= (version minimum)
  (flet ((parts (s) (mapcar (lambda (p) (or (parse-integer p :junk-allowed t) 0))
                            (uiop:split-string s :separator '(#\.)))))
    (and (stringp version)
         (loop for a in (parts version) for b in (parts minimum)
               when (> a b) return t when (< a b) return nil finally (return t)))))

(defun main-path (site) (if (eq (site-kind site) :fedwiki) "/view/welcome-visitors" "/"))

(defun observe-site (site)
  "Read the site over HTTPS and return an observation plist; also record it."
  (let* ((head (curl site (main-path site) "-o" "/dev/null" "-w" "%{http_code} %{http_version}"))
         (status-version (uiop:split-string (string-trim " " head) :separator '(#\Space)))
         (certs (curl site (main-path site) "-o" "/dev/null" "-w" "%{certs}"))
         (observation
           (list :time (get-universal-time)
                 :host (site-host site)
                 :status (first status-version) :http (second status-version)
                 :issuer (field-line certs "Issuer:") :expires (field-line certs "Expire date:"))))
    (if (eq (site-kind site) :fedwiki)
        (setf observation
              (append observation
                      (let* ((answer (curl site "/system/version.json" "-w" (format nil "~%%{http_code}")))
                             (cut (position #\Newline answer :from-end t))
                             (code (string-trim " " (subseq answer (1+ (or cut -1))))))
                        ;; Some wikis answer 403 here (observed on staging); then the version is
                        ;; unverified, not deviating, and the dialog fix is the remaining content evidence.
                        (if (equal code "200")
                            (list :wiki (wiki-version (subseq answer 0 (or cut 0))))
                            (list :wiki :unverified :version-status code)))
                      (list
                            :dialog-fix (and (search +dialog-fix+ (curl site "/dialog/index.html" "-f")) t))))
        (setf observation
              (append observation (list :catalog (and (search "/js/boot.js" (curl site "/" "-f")) t)))))
    (setf observation (append observation (list :deviations (deviations site observation))))
    (push observation (observations-of site))
    observation))

(defun deviations (site observation)
  "Every difference from what should be served; NIL when the site serves the expected state."
  (append
   (unless (equal "200" (getf observation :status)) (list (list :status (getf observation :status))))
   (unless (equal "2" (getf observation :http)) (list (list :http (getf observation :http))))
   (unless (getf observation :expires) (list (list :certificate :unreadable)))
   (case (site-kind site)
     (:fedwiki
      (append
       (unless (or (eq :unverified (getf observation :wiki))
                   (version>= (getf observation :wiki) +expected-wiki+))
         (list (list :wiki (getf observation :wiki) :expected +expected-wiki+)))
       (unless (getf observation :dialog-fix) (list (list :dialog-fix :missing)))))
     (:hyperdoc-catalog
      (unless (getf observation :catalog) (list (list :catalog :not-recognized)))))))

;;; Where this code comes from: a repository checkout, or a page copy of one commit

(defun system-directory () (asdf:system-source-directory "site-observation"))

(defun file-sha256 (path)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))

(defun source-state (&optional (directory (system-directory)))
  "Repository checkout, or the page copy with its commit and whether every file still matches SHA256SUMS."
  (let ((source (merge-pathnames "SOURCE" directory))
        (sums (merge-pathnames "SHA256SUMS" directory)))
    (if (not (probe-file source))
        (list :origin :repository-checkout :directory (namestring directory))
        (let* ((fields (loop for line in (uiop:read-file-lines source)
                             for colon = (position #\: line)
                             when colon collect (cons (subseq line 0 colon)
                                                      (string-trim " " (subseq line (1+ colon))))))
               (changed (and (probe-file sums)
                             (loop for line in (uiop:read-file-lines sums)
                                   for (hash name) = (let ((p (position #\Space line)))
                                                       (list (subseq line 0 p)
                                                             (string-left-trim " *" (subseq line p))))
                                   for path = (merge-pathnames name directory)
                                   unless (and (probe-file path) (equal hash (file-sha256 path)))
                                     collect name))))
          (list :origin :page-copy :commit (cdr (assoc "commit" fields :test #'equal))
                :attached (cdr (assoc "attached" fields :test #'equal))
                :intact (and (probe-file sums) (null changed)) :changed changed)))))

;;; The plan: which site to observe next

(shop3:defdomain (site-observation :noset t)
  ((:operator (!offer ?site) () () ((offered ?site)))
   ;; Separate methods, so that every site needing attention is an alternative plan
   ;; (the branches of one method would stop at the first that applies).
   (:method (next-observation) never-observed ((site ?s) (not (observed ?s))) ((!offer ?s)))
   (:method (next-observation) stale ((site ?s) (observed ?s) (not (fresh ?s))) ((!offer ?s)))
   (:method (next-observation) deviating ((site ?s) (fresh ?s) (deviating ?s)) ((!offer ?s)))
   (:method (next-observation)
     all-current ((forall (?s) ((site ?s)) ((fresh ?s) (not (deviating ?s))))) ())))

(defvar *planner-lock* (sb-thread:make-mutex :name "site observation SHOP3"))

(defun facts (&optional (now (get-universal-time)))
  (loop for site in *sites*
        for id = (site-id site)
        for last = (latest-observation site)
        collect (list 'site id)
        when last collect (list 'observed id)
        when (and last (< (- now (getf last :time)) *max-age-seconds*)) collect (list 'fresh id)
        when (and last (getf last :deviations)) collect (list 'deviating id)))

(defun plan-next ()
  "The native plan result: every site that should be observed now, as alternatives."
  (sb-thread:with-mutex (*planner-lock*)
    (let* ((name (gensym "SITE-OBSERVATION-"))
           (facts (facts))
           (shop3::*problem* shop3::*problem*)
           (problem (shop3:make-problem (list name :domain 'site-observation :silently t)
                                       (copy-tree facts) '((next-observation)))))
      (unwind-protect
           (multiple-value-bind (raw seconds trees states)
               (shop3:find-plans problem :domain (shop3:find-domain 'site-observation) :which :all
                                :verbose 0 :plan-tree nil :collect-state t)
             (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                            :problem-name name :raw-plans raw :plans (mapcar #'shop3:shorter-plan raw)
                            :time seconds :final-states states :initial-facts facts
                            ;; The Read the Plan view reads this slot; without it the view stays empty.
                            :plan-trees trees :execution-mode :plan-only))
        (shop3:delete-problem problem)))))

(defun offered-sites (plan)
  (remove-duplicates
   (loop for p in (dreyeck/shop3:plans-of plan)
         for step = (first p)
         when (and step (eq (first step) '!offer)) collect (second step))))

;;; Play

(defvar *messages* (make-hash-table))

(defun play-observe (site)
  (setf (gethash (site-id site) *messages*)
        (handler-case
            (let ((o (observe-site site)))
              (if (getf o :deviations)
                  (format nil "Abweichung: ~S" (getf o :deviations))
                  "Wie erwartet."))
          (error (c) (princ-to-string c))))
  site)

(policy:register-reviewed-control "site-observation/observe"
  :effect "Reads one Dreyeck site over HTTPS with GET requests from this image and records the observation."
  :audit "PLAY-OBSERVE runs curl with --proto =https against the site's fixed host; no SSH, no writes, no credentials.")

;;; DITA

(defun topic-path () (asdf:system-relative-pathname "site-observation" "observe-site.dita"))

(defun render-task (site)
  (let* ((xml (uiop:frob-substrings (uiop:read-file-string (topic-path) :external-format :utf-8)
                                    '("SITE-HOST") (site-host site)))
         (root (dita:parse-dita-topic xml))
         (node (plump:get-element-by-id root "observe-https"))
         (marker (symbol-name (gensym "SITE-PLAY-"))))
    (plump:make-text-node (plump:make-element (elt (plump:get-elements-by-tag-name node "cmd") 0) "ph") marker)
    (let* ((html (dita:render-dita-topic (plump:serialize root nil)))
           (offset (search marker html)))
      (v:html (v:str (subseq html 0 offset)) " "
              (v:eval-button "Play" (policy:reviewed-thunk "site-observation/observe" (play-observe site))
                             (format nil "~A über HTTPS lesen" (site-host site)))
              (v:str (subseq html (+ offset (length marker))))))))

;;; Pages: one overview, one page per machine

(defclass observation-book (hb:hyperbook) ())
(defclass machine-page (hb:page) ((machine :initarg :machine :reader machine-of)))
(defclass overview-page (hb:page) ())

(defparameter +book-id+ "dreyeck-site-observation")
(defun machines () (remove-duplicates (mapcar #'site-machine *sites*) :test #'equal :from-end t))
(defun machine-page-id (machine) (substitute #\- #\. machine))

(defmethod hb:title-of ((book observation-book)) "Site-Beobachtung")
(defmethod hb:title-of ((page overview-page)) "Übersicht")
(defmethod hb:title-of ((page machine-page)) (format nil "Host ~A" (machine-of page)))
(defmethod hb:main-page-id-of ((book observation-book)) "overview")

(defmethod hb:find-page ((book observation-book) id &key signal-error?)
  (or (and (equal id "overview") (make-instance 'overview-page :id "overview" :hyperbook book))
      (let ((machine (find id (machines) :key #'machine-page-id :test #'equal)))
        (and machine (make-instance 'machine-page :id id :hyperbook book :machine machine)))
      (when signal-error? (error 'hb:page-lookup-failure :hyperbook book :page-id id))))

(defun time-string (universal)
  (multiple-value-bind (s mi h d mo y) (decode-universal-time universal 0)
    (format nil "~D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D UTC" y mo d h mi s)))

(defun site-summary (site)
  (let ((o (latest-observation site)))
    (cond ((null o) "noch nicht beobachtet")
          ((getf o :deviations) (format nil "~A · Abweichung ~S" (time-string (getf o :time)) (getf o :deviations)))
          (t (format nil "~A · wie erwartet~@[ · wiki ~A~] · Zertifikat bis ~A"
                     (time-string (getf o :time)) (getf o :wiki) (getf o :expires))))))

(v:defview overview-view (page overview-page)
  (v:html-view :title "Übersicht" :priority -100
    (let ((plan (plan-next)))
      (v:html (:p (v:object-ref plan :display "Nativer SHOP3-Plan") " · als Nächstes beobachten: "
                  (v:esc (format nil "~{~(~A~)~^, ~}" (or (offered-sites plan) '(:keine)))))
              (let ((state (source-state)))
                (v:html (:p "Quelle: "
                            (v:esc (if (eq :page-copy (getf state :origin))
                                       (format nil "Seitenkopie von Commit ~A (~A)~:[ · GEÄNDERT: ~{~A~^, ~}~;~*, unverändert~]"
                                               (getf state :commit) (getf state :attached)
                                               (getf state :intact) (getf state :changed))
                                       (format nil "Repository-Checkout ~A" (getf state :directory)))))))
              (:p "Erwartet: wiki " (:code (v:esc +expected-wiki+)) " mit Dialog-Korrektur; Belege gelten "
                  (v:esc (princ-to-string (floor *max-age-seconds* 3600))) " Stunden.")
              (:table
               (dolist (site *sites*)
                 (v:html (:tr (:td (:code (v:esc (site-host site))))
                              (:td (v:esc (site-machine site)))
                              (:td (v:esc (site-summary site)))))))))))

(v:defview machine-view (page machine-page)
  (v:html-view :title "Beobachtung" :priority -100
    (v:html
     (:p "Host " (:code (v:esc (machine-of page))) ": lesende HTTPS-Prüfung je Site. "
         "Die Prüfung auf dem Host (aktives System, laufendes nginx) folgt als eigener Schritt.")
     (dolist (site (remove (machine-of page) *sites* :key #'site-machine :test-not #'equal))
       (v:html (:h3 (v:esc (site-host site)))
               (:p (v:esc (site-summary site)))
               (let ((message (gethash (site-id site) *messages*)))
                 (when message (v:html (:p :role "status" (v:esc message)))))
               (render-task site)
               (:pre :style "white-space:pre-wrap"
                     (v:esc (let ((*print-right-margin* 110))
                              (format nil "~S" (subseq (observations-of site) 0
                                                       (min 3 (length (observations-of site)))))))))))))

(defun page-paths (book)
  (let ((slug (hyperbook/server::slug book)))
    (loop for id in (cons "overview" (mapcar #'machine-page-id (machines)))
          collect (cons id (format nil "/~A/~A" slug id)))))

(defun add-routes (book)
  "One exact CLOG route per page. Works whoever started CLOG, with or without a HyperBook Catalog."
  (loop for (id . path) in (page-paths book)
        do (let ((page-id id))
             (clog:set-on-new-window
              (lambda (body)
                (clog-moldable-inspector:on-new-inspector
                 body :object (hb:find-page book page-id :signal-error? t)
                      :pane-width "850px" :title (hb:title-of book) :playground? nil))
              :path path))))

(defun open-task (&key (port 18759))
  "Open the overview in this image's running CLOG server (for example the white image), or start a
loopback Catalog on PORT when CLOG is not running. Return the overview URL."
  (let ((book (or (hb:find-hyperbook +book-id+) (make-instance 'observation-book :id +book-id+))))
    (unless (clog:is-running-p)
      (hyperbook/server:serve-catalog :host "127.0.0.1" :port port :development nil :pane-width "850px"))
    (hb:register book)
    (add-routes book)
    (format nil "http://127.0.0.1:~D~A" clog:*clog-port* (cdr (first (page-paths book))))))

(defun trust-staging-roots (pem)
  "Let curl verify staging.dreyeck.ch against the Let's Encrypt staging roots in the file PEM."
  (let ((path (or (probe-file pem) (error "Datei ~A fehlt." pem))))
    (setf (site-ca-file (find-site :staging-dreyeck-ch)) path)))
