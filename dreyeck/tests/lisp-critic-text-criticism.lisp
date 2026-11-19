;;;; Tests of the text-passage records that need nothing but this repository's
;;;; two source files, Ironclad and Git: no HyperDoc, no critic engine.
;;;;
;;;; The claim tables some of these tests compare a reading with are written
;;;; here as data. They are test inputs, not records of any source, and the
;;;; tests that use them say so. The tests on the committed page and claims
;;;; file read those files as they are.

(defpackage #:dreyeck/lisp-critic/text-criticism/tests
  (:use #:cl)
  (:local-nicknames (#:passage #:dreyeck/lisp-critic/text-passage)
                    (#:criticism #:dreyeck/lisp-critic/text-criticism))
  (:export #:run-tests #:*effect*))

(in-package #:dreyeck/lisp-critic/text-criticism/tests)

(defvar *checks* 0)
(defvar *effect* nil
  "Set by source text in these tests, if any of it were ever evaluated.")

(defun check (value control &rest arguments)
  (incf *checks*)
  (unless value (error (apply #'format nil control arguments)))
  value)

(defun root () (asdf:system-source-directory "dreyeck"))

(defun octets (text) (sb-ext:string-to-octets text :external-format :utf-8))

(defun file-octets (relative)
  (with-open-file (stream (merge-pathnames relative (root)) :element-type '(unsigned-byte 8))
    (let ((octets (make-array (file-length stream) :element-type '(unsigned-byte 8))))
      (read-sequence octets stream)
      octets)))

(defun file-text (relative)
  (sb-ext:octets-to-string (file-octets relative) :external-format :utf-8))

(defparameter +page+ "dreyeck/pages/lisp-critic/The Fischer Critic as an Environment.html")
(defparameter +claims+ "dreyeck/src/lisp-critic-reading.lisp")

(defun status-of (role observation)
  (getf (find role (getf (getf observation :source-state) :files) :key (lambda (file) (getf file :role)))
        :status))

;;;; The committed sources

(defun check-committed-sources ()
  "The two files of this checkout are the recorded texts, the paragraph stands
once where it was recorded, and the records do not bear the paragraph out."
  (let* ((before (list (passage:sha256-of (file-octets +page+)) (passage:sha256-of (file-octets +claims+))))
         (observation (criticism:observe-now))
         (claims (getf (getf observation :claims) :result)))
    (check (eq :recorded-snapshot (status-of :page observation)) "The page is ~S." (status-of :page observation))
    (check (eq :recorded-snapshot (status-of :claims-source observation))
           "The claims source is ~S." (status-of :claims-source observation))
    (check (eq :matches-recorded (getf (getf observation :source-state) :content)) "Content does not match.")
    (check (eq :present-once (getf (getf observation :passage) :status)) "The paragraph is not present once.")
    (check (getf (getf observation :passage) :at-recorded-range-p) "The paragraph is not at its recorded characters.")
    (check (= 10 (getf claims :claims-citing-a-primary-paper)) "~S claims cite a primary paper."
           (getf claims :claims-citing-a-primary-paper))
    (check (equal '((:primary-paper . 5) (:none-observed . 5))
                  (sort (copy-list (getf claims :by-observed-evidence-kind)) #'string> :key #'car))
           "Observed evidence kinds are ~S." (getf claims :by-observed-evidence-kind))
    (check (equal '(:no-paper-read :first-claim-carried-by-a-secondary-note :every-other-claim-none-observed)
                  (mapcar (lambda (discrepancy) (getf discrepancy :assertion)) (getf observation :discrepancies)))
           "Discrepancies are ~S." (getf observation :discrepancies))
    (check (member (getf observation :scope) '(:verified-revision :recorded-content))
           "The scope is ~S." (getf observation :scope))
    ;; what was observed now is what was recorded
    (check (equal (getf (criticism:recorded-observation :claims) :result)
                  (list :claims-citing-a-primary-paper (getf claims :claims-citing-a-primary-paper)
                        :by-observed-evidence-kind
                        (sort (copy-list (getf claims :by-observed-evidence-kind)) #'string> :key #'car)
                        :first-claim (let ((row (first (getf claims :rows))))
                                       (list :subject (getf row :subject) :id (getf row :id)
                                             :observed-evidence-kind (getf row :observed-evidence-kind)))))
           "The recorded claims observation is not what is observed now.")
    (check (equal (getf (getf (criticism:recorded-observation :passage) :result) :range)
                  (getf (getf observation :passage) :range))
           "The recorded passage range is not what is observed now.")
    ;; observing changed nothing
    (check (equal before (list (passage:sha256-of (file-octets +page+)) (passage:sha256-of (file-octets +claims+))))
           "Observing changed a source file.")
    (check (null (find-package "LISP-CRITIC")) "A critic engine is loaded.")
    observation))

;;;; Revision membership is not content identity

(defun git (directory &rest arguments)
  (multiple-value-bind (output error-output code)
      (uiop:run-program (append (list "git" "-C" (uiop:native-namestring directory)) arguments)
                        :output :string :error-output :string :ignore-error-status t)
    (unless (eql 0 code) (error "git ~{~A~^ ~} failed: ~A" arguments error-output))
    (string-trim '(#\Newline) output)))

(defun call-with-temporary-directory (function)
  (let ((directory (uiop:ensure-directory-pathname
                    (merge-pathnames (format nil "dreyeck-text-passage-~36R/" (random (expt 36 10) (make-random-state t)))
                                     (uiop:temporary-directory)))))
    (ensure-directories-exist directory)
    (unwind-protect (funcall function directory)
      (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore))))

(defun write-octets (pathname octets)
  (ensure-directories-exist pathname)
  (with-open-file (stream pathname :direction :output :if-exists :supersede :element-type '(unsigned-byte 8))
    (write-sequence octets stream)))

(defun recorded-for (state page-octets claims-octets)
  (list :state state
        :files (list (list :role :page :path "page.html" :sha256 (passage:sha256-of page-octets)
                           :git-blob (passage:git-blob-id-of page-octets))
                     (list :role :claims-source :path "claims.lisp" :sha256 (passage:sha256-of claims-octets)
                           :git-blob (passage:git-blob-id-of claims-octets)))
        :passage (list :range (cons 3 10) :text "passage")))

(defun check-revision-membership ()
  "In a repository made for the test: the same content is :VERIFIED in the
commit that holds it, :CONTRADICTED in a commit that holds other content or
lacks the path, and :NOT-VERIFIED where Git cannot say."
  (check (ignore-errors (uiop:run-program '("git" "--version") :output :string))
         "These tests need Git, and Git could not be run.")
  (call-with-temporary-directory
   (lambda (directory)
     (let ((page (octets "<p>passage</p>")) (claims (octets "(defun historical-claims () (copy-tree '()))
")))
       (git directory "init" "--quiet")
       (git directory "config" "user.email" "test@example.invalid")
       (git directory "config" "user.name" "Test")
       (write-octets (merge-pathnames "page.html" directory) (octets "<p>earlier</p>"))
       (git directory "add" "page.html")
       (git directory "commit" "--quiet" "-m" "page only, other content")
       (let ((first-commit (git directory "rev-parse" "HEAD")))
         (write-octets (merge-pathnames "page.html" directory) page)
         (write-octets (merge-pathnames "claims.lisp" directory) claims)
         (git directory "add" "page.html" "claims.lisp")
         (git directory "commit" "--quiet" "-m" "both")
         (let ((second-commit (git directory "rev-parse" "HEAD")))
           (flet ((observe (state &optional (root directory))
                    (passage:observe-source-state (recorded-for state page claims) :root root)))
             ;; the git blob id computed here is the one Git computes
             (check (string= (passage:git-blob-id-of page) (git directory "rev-parse" "HEAD:page.html"))
                    "The computed blob id is not Git's.")
             (let ((observation (observe second-commit)))
               (check (eq :matches-recorded (getf observation :content)) "Content differs in the commit that holds it.")
               (check (eq :verified (getf observation :revision-binding)) "Membership is ~S."
                      (getf observation :revision-binding))
               (check (eq :verified-revision (getf (passage:source-coherence observation) :scope))
                      "Coherence is ~S." (passage:source-coherence observation)))
             ;; same content on disk, but the named commit holds other content and lacks one path
             (let ((observation (observe first-commit)))
               (check (eq :matches-recorded (getf observation :content)) "Content should still match.")
               (check (eq :contradicted (getf observation :revision-binding)) "Membership is ~S, not :CONTRADICTED."
                      (getf observation :revision-binding))
               (check (equal '(:commit-names-another-blob :path-absent-in-commit)
                             (mapcar (lambda (membership) (getf membership :reason))
                                     (getf observation :revision-membership)))
                      "Reasons are ~S." (getf observation :revision-membership))
               (check (eq :not-determined (getf (passage:source-coherence observation) :scope))
                      "A contradicted revision is not undetermined."))
             ;; a commit this repository does not have
             (let ((observation (observe "0123456789abcdef0123456789abcdef01234567")))
               (check (eq :not-verified (getf observation :revision-binding)) "An unknown commit is ~S."
                      (getf observation :revision-binding))
               (check (eq :recorded-content (getf (passage:source-coherence observation) :scope))
                      "Content identity without membership is ~S." (passage:source-coherence observation)))
             ;; a name that is not a full object id is never verified, even if it resolves
             (check (eq :not-verified (getf (observe "HEAD") :revision-binding)) "A moving name was verified.")
             (check (eq :not-verified (getf (observe (subseq second-commit 0 12)) :revision-binding))
                    "An abbreviated id was verified.")
             ;; a blob is not a commit
             (check (eq :contradicted (getf (observe (git directory "rev-parse" "HEAD:page.html")) :revision-binding))
                    "A blob id was accepted as a commit.")
             ;; the comparison itself: made in the commit that holds the texts, refused in the one that does not
             (flet ((criticise (state)
                      (passage:criticise-passage (recorded-for state page claims) (criticism:passage-reading)
                                                 :root directory)))
               (check (eq :verified-revision (getf (criticise second-commit) :scope))
                      "The verified commit gave scope ~S." (getf (criticise second-commit) :scope))
               (check (listp (getf (criticise second-commit) :discrepancies)) "The verified commit gave no comparison.")
               (check (eq :not-determined (getf (criticise first-commit) :discrepancies))
                      "A contradicted commit gave ~S." (getf (criticise first-commit) :discrepancies))
               (check (eq :recorded-content
                          (getf (criticise "0123456789abcdef0123456789abcdef01234567") :scope))
                      "An unverified commit gave a scope other than :RECORDED-CONTENT.")))))
       ;; the same files outside any repository
       (call-with-temporary-directory
        (lambda (plain)
          (write-octets (merge-pathnames "page.html" plain) page)
          (write-octets (merge-pathnames "claims.lisp" plain) claims)
          (let ((observation (passage:observe-source-state
                              (recorded-for "0123456789abcdef0123456789abcdef01234567" page claims) :root plain)))
            (check (eq :matches-recorded (getf observation :content)) "Content differs outside a repository.")
            (check (eq :not-verified (getf observation :revision-binding))
                   "Membership outside a repository is ~S." (getf observation :revision-binding)))))))))

;;;; Undetermined, never a discrepancy and never agreement

(defun check-undetermined ()
  "When a source is not the recorded text, or cannot be read, or the paragraph
does not stand once, nothing is derived: not a discrepancy, and not NIL."
  (flet ((observe (&rest octets) (criticism:observe-now :octets octets))
         (undetermined-p (observation)
           (and (eq :not-determined (getf observation :discrepancies))
                (eq :not-determined (getf observation :scope)))))
    (let ((page (file-text +page+)) (claims (file-text +claims+))
          (paragraph (getf (getf (criticism:recorded-source-state) :passage) :text)))
      ;; the page changed elsewhere, the claims did not
      (let ((observation (observe :page (octets (concatenate 'string page "<p>later</p>")))))
        (check (eq :changed (status-of :page observation)) "A changed page is ~S." (status-of :page observation))
        (check (eq :present-once (getf (getf observation :passage) :status)) "The paragraph should still stand once.")
        (check (undetermined-p observation) "A changed page gave ~S." (getf observation :discrepancies)))
      ;; the claims source changed, the page did not
      (let ((observation (observe :claims-source (octets (concatenate 'string claims ";; later
")))))
        (check (eq :changed (status-of :claims-source observation)) "A changed claims source is not :CHANGED.")
        (check (undetermined-p observation) "A changed claims source gave ~S." (getf observation :discrepancies)))
      ;; the paragraph was rewritten
      (let ((observation (observe :page (octets (let ((start (search paragraph page)))
                                                  (concatenate 'string (subseq page 0 start) "Rewritten."
                                                               (subseq page (+ start (length paragraph)))))))))
        (check (eq :absent (getf (getf observation :passage) :status)) "A rewritten paragraph is not :ABSENT.")
        (check (undetermined-p observation) "A rewritten paragraph gave ~S." (getf observation :discrepancies)))
      ;; the paragraph stands twice
      (let ((observation (observe :page (octets (concatenate 'string page paragraph)))))
        (check (eq :ambiguous (getf (getf observation :passage) :status)) "A doubled paragraph is not :AMBIGUOUS.")
        (check (undetermined-p observation) "A doubled paragraph gave ~S." (getf observation :discrepancies)))
      ;; octets that are not UTF-8: reported, not signalled
      (let ((observation (observe :page (coerce '(60 112 62 255 254 60 47 112 62) '(vector (unsigned-byte 8))))))
        (check (eq :unreadable (status-of :page observation)) "Invalid UTF-8 is ~S." (status-of :page observation))
        (check (eq :not-observed (getf (getf observation :passage) :status)) "An unreadable page has a passage.")
        (check (undetermined-p observation) "An unreadable page gave ~S." (getf observation :discrepancies)))
      ;; no files at all
      (call-with-temporary-directory
       (lambda (empty)
         (let ((observation (criticism:observe-now :root empty)))
           (check (eq :absent (status-of :page observation)) "A missing page is ~S." (status-of :page observation))
           (check (eq :absent (status-of :claims-source observation)) "A missing claims source is not :ABSENT.")
           (check (eq :claims-unreadable (getf (getf observation :claims) :status)) "Missing claims were read.")
           (check (undetermined-p observation) "Missing files gave ~S." (getf observation :discrepancies))))))))

;;;; Reading the table is not running the source

(defun table-source (table-text &key (body "(copy-tree '~A)") (before "") (after ""))
  (format nil "~A~%(defun historical-claims ()~%  \"Claims.\"~%  ~?)~%~A" before body (list table-text) after))

(defun check-structural-reading ()
  "The table is read out of one form and nothing in the text is evaluated: not
at read time, not the definition, and not the forms around it."
  (setf *effect* nil)
  (flet ((refused-p (text) (multiple-value-bind (table why) (passage:read-claim-table text)
                             (and (null table) why))))
    (let ((effect "(setf dreyeck/lisp-critic/text-criticism/tests:*effect* t)"))
      ;; a well-formed table is read, with forms around it that would have effects and name unknown packages
      (multiple-value-bind (table why)
          (passage:read-claim-table
           (table-source "((:subject :a :cited-source-kind :primary-paper :observed-evidence-kind :none-observed))"
                         :before (format nil "(no-such-package:run)~%(eval-when (:compile-toplevel :load-toplevel :execute) ~A)" effect)
                         :after effect))
        (check (and (null why) (equal '((:subject :a :cited-source-kind :primary-paper :observed-evidence-kind :none-observed))
                                      table))
               "A well-formed table was not read: ~S ~S" table why)
        (check (null *effect*) "Reading the table evaluated a form beside it."))
      ;; read-time evaluation inside the table is a reader error, not an evaluation
      (check (equal '(:reader-refused "UNSUPPORTED-SOURCE-SYNTAX")
                    (let ((why (refused-p (table-source (format nil "((:subject #.~A))" effect)))))
                      (and why (list (first why) (if (search "READER-ERROR" (second why)) "READER-ERROR" (second why))))))
             "Read-time evaluation was not refused by the reader.")
      (check (null *effect*) "A #. form was evaluated.")
      ;; a definition that computes its table is refused, not run
      (check (equal '(:unexpected-definition-shape)
                    (refused-p (table-source "((:subject :a))" :body (format nil "(progn ~A (copy-tree '~~A))" effect))))
             "A computing definition was accepted.")
      (check (equal '(:unexpected-definition-shape)
                    (refused-p (table-source "((:subject :a))" :body (format nil "(list ~A '~~A)" effect))))
             "A definition of another shape was accepted.")
      (check (null *effect*) "A definition body was evaluated.")
      ;; code inside the table is not literal data
      (check (equal '(:table-is-not-literal-data) (refused-p (table-source (format nil "((:subject ~A))" effect))))
             "A form inside the table was accepted as data.")
      (check (equal '(:table-is-not-literal-data) (refused-p (table-source "((:subject . :dotted))")))
             "A dotted record was accepted.")
      (check (eq :reader-refused (first (refused-p (table-source "((:subject #1=(:a . #1#)))"))))
             "A circular value was accepted.")
      (check (equal '(:table-is-not-literal-data) (refused-p (table-source "((subject :a))")))
             "A record with a non-keyword key was accepted.")
      ;; none, or more than one, definition
      (check (equal '(:definitions-found 0) (refused-p "(defun other () nil)")) "A missing definition was read.")
      (check (equal '(:definitions-found 2)
                    (refused-p (concatenate 'string (table-source "()") (table-source "()"))))
             "Two definitions were read as one.")
      ;; an unknown package inside the form
      (check (eq :table-is-not-literal-data (first (refused-p (table-source "((:subject no-such-package:x))"))))
             "A symbol of an unknown package was read.")
      (check (null *effect*) "Something was evaluated.")
      ;; reading leaves no package behind
      (check (notany (lambda (package) (uiop:string-prefix-p "DREYECK/TEXT-PASSAGE/READ-" (package-name package)))
                     (list-all-packages))
             "A reading package was left behind."))))

;;;; A reading the records bear out gives no discrepancy

(defun check-agreement-and-expectations ()
  "With a table that is as the paragraph describes it, the reading is borne out
and there is no criticism. The tables here are test data, not records."
  (flet ((claim (kind) (list :subject :s :cited-source-kind :primary-paper :observed-evidence-kind kind))
         (discrepancies (table) (passage:passage-discrepancies (criticism:passage-reading)
                                                               (passage:observe-claim-evidence table))))
    (check (null (discrepancies (list (claim :secondary-research-note) (claim :none-observed) (claim :none-observed)
                                      '(:subject :engine :cited-source-kind :source-file
                                        :observed-evidence-kind :source-file))))
           "A table as the paragraph describes it gave a discrepancy.")
    (check (equal '(:no-paper-read :every-other-claim-none-observed)
                  (mapcar (lambda (discrepancy) (getf discrepancy :assertion))
                          (discrepancies (list (claim :secondary-research-note) (claim :none-observed)
                                               (claim :none-observed) (claim :primary-paper)))))
           "One claim carried by a primary paper was not reported against the two assertions it contradicts.")
    (check (equal '(:first-claim-carried-by-a-secondary-note)
                  (mapcar (lambda (discrepancy) (getf discrepancy :assertion))
                          (discrepancies (list (claim :none-observed) (claim :none-observed)))))
           "A first claim without a secondary note was not reported.")
    ;; an expectation the comparison does not know is an error, not agreement
    (check (handler-case (progn (passage:passage-discrepancies
                                 '(:assertions ((:id :x :expects (:median :observed-evidence-kind :none-observed))))
                                 (passage:observe-claim-evidence (list (claim :none-observed))))
                                nil)
             (error () t))
           "An unknown expectation passed.")))

;;;; The records keep their kinds apart

(defun check-record-kinds ()
  (let ((judgement (criticism:judgement)) (recommendation (criticism:recommendation))
        (reading (criticism:passage-reading)))
    (check (eq :interpreted (getf judgement :evidence-status)) "The judgement is not :INTERPRETED.")
    (check (eq :interpreted (getf reading :evidence-status)) "The reading is not :INTERPRETED.")
    (check (null (getf recommendation :evidence-status)) "The recommendation declares an evidence status.")
    (check (null (getf recommendation :applied-p)) "The recommendation claims to be applied.")
    (check (every (lambda (observation) (eq :observed (getf observation :evidence-status)))
                  (criticism:recorded-observations))
           "A recorded observation is not :OBSERVED.")
    ;; what the federated context's resolver reads: :ID, :STATE and :TARGETS on observations, :BASIS and :TARGETS on the judgement
    (dolist (entry (getf judgement :basis))
      (let ((observation (criticism:recorded-observation (getf entry :observation))))
        (check (equal (getf entry :state) (getf observation :state)) "A basis entry names another state.")))
    (dolist (target (getf judgement :targets))
      (check (some (lambda (observation) (member target (getf observation :targets) :test #'equal))
                   (criticism:recorded-observations))
             "The judgement names ~A, which no recorded observation observed." target))
    ;; the recommendation's replacement is not in the page: nothing was applied
    (check (null (search (getf recommendation :replacement-text) (file-text +page+)))
           "The recommended text is in the page.")
    (unless (find-package "DREYECK/LISP-CRITIC/READING")
      (check (eq :reading-system-not-loaded (getf (criticism:image-agreement) :status))
             "Image agreement was claimed without the reading system."))))

(defun run-tests ()
  (let ((*checks* 0))
    (let ((observation (check-committed-sources)))
      (check-revision-membership)
      (check-undetermined)
      (check-structural-reading)
      (check-agreement-and-expectations)
      (check-record-kinds)
      (format t "~&TEXT-CRITICISM-SOURCE-STATE content ~(~A~), revision membership ~(~A~), scope ~(~A~)~%"
              (getf (getf observation :source-state) :content)
              (getf (getf observation :source-state) :revision-binding)
              (getf observation :scope)))
    (format t "~&TEXT-CRITICISM-PASS: ~D checks. No critic engine was loaded and no rule ran; the judgement-basis resolver of the federated context is exercised by the integration tests, not here.~%"
            *checks*)
    t))
