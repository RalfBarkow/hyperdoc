;;;; A passage of a text page as the target of a criticism, and the records it
;;;; restates, each bound to an identified source state.
;;;;
;;;; A page sometimes says in prose what records in the source already say as
;;;; data. Whether the two agree can be observed, but only between texts that
;;;; are known to be the texts meant. This file reads two source texts as
;;;; octets, says how each relates to a recorded source state, and compares a
;;;; declared reading of the passage with the records.
;;;;
;;;; Five things are kept apart, and none stands in for another:
;;;;
;;;;   content identity     the octets read now have the recorded SHA-256 and
;;;;                        Git blob id. Computed here; needs no Git.
;;;;   revision membership  Git, asked now, names that blob at that path in the
;;;;                        recorded commit: :VERIFIED, :NOT-VERIFIED (it could
;;;;                        not be asked, or does not know the commit) or
;;;;                        :CONTRADICTED. Equal content does not establish it.
;;;;   observation          what the passage and the records read as, now.
;;;;   reading              what a passage is taken to assert. An
;;;;                        interpretation, supplied by its author as data.
;;;;   discrepancy          derived by comparing a reading with the records. A
;;;;                        list, NIL when the records bear the reading out, or
;;;;                        :NOT-DETERMINED when the sources are not the
;;;;                        recorded ones. Missing evidence is never NIL.
;;;;
;;;; Nothing here loads or evaluates the source it reads. The records are
;;;; read from the text of their definition with the standard reader and
;;;; *READ-EVAL* false, one form only, and are accepted only when that form
;;;; has exactly the expected shape and holds nothing but literal data.
;;;;
;;;; No critic rule runs, and there is no Evaluation Record and no Critique
;;;; among these records.

(defpackage #:dreyeck/lisp-critic/text-passage
  (:use #:cl)
  (:export #:sha256-of #:git-blob-id-of
           #:observe-source-state #:source-coherence
           #:observe-passage
           #:read-claim-table #:observe-claim-evidence
           #:passage-discrepancies
           #:criticise-passage))

(in-package #:dreyeck/lisp-critic/text-passage)

;;;; Content identity

(defun sha256-of (octets)
  (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 octets)))

(defun git-blob-id-of (octets)
  "The SHA-1 object id Git gives a blob with these OCTETS. Computed, not asked."
  (let ((digest (ironclad:make-digest :sha1)))
    (ironclad:update-digest
     digest (sb-ext:string-to-octets (format nil "blob ~D~C" (length octets) (code-char 0))
                                     :external-format :latin-1))
    (ironclad:update-digest digest octets)
    (ironclad:byte-array-to-hex-string (ironclad:produce-digest digest))))

(defun %file-octets (pathname)
  "The octets of the file at PATHNAME, or NIL when there is no such file."
  (when (and pathname (uiop:file-exists-p pathname))
    (with-open-file (stream pathname :element-type '(unsigned-byte 8))
      (let ((octets (make-array (file-length stream) :element-type '(unsigned-byte 8))))
        (read-sequence octets stream)
        octets))))

(defun %decode-utf-8 (octets)
  "OCTETS as text, or NIL and why. Text is accepted only when encoding it again
gives the same octets, so a replacement character cannot pass as the source."
  (handler-case
      (let ((text (sb-ext:octets-to-string octets :external-format :utf-8)))
        (if (equalp octets (sb-ext:string-to-octets text :external-format :utf-8))
            (values text nil)
            (values nil "decoding and encoding again does not give the same octets")))
    (error (condition)
      (values nil (format nil "~A: ~A" (type-of condition) condition)))))

(defun %iso-time (universal-time)
  (multiple-value-bind (second minute hour day month year) (decode-universal-time universal-time 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ" year month day hour minute second)))

(defun %executed ()
  "Who observed, and when: this runtime, executing a probe."
  (list :kind :executed-probe
        :runtime (format nil "~A ~A" (lisp-implementation-type) (lisp-implementation-version))
        :observation-time (%iso-time (get-universal-time))))

;;;; Revision membership

(defun %full-object-id-p (text)
  (and (stringp text) (= 40 (length text))
       (every (lambda (char) (digit-char-p char 16)) text)
       (string= text (string-downcase text))))

(defun %git (root &rest arguments)
  "Run Git in ROOT without replacement objects. Two values: its exit code, or
NIL when it could not be run at all, and its trimmed output."
  (handler-case
      (multiple-value-bind (output error-output code)
          (uiop:run-program (append (list "git" "--no-replace-objects" "-C" (uiop:native-namestring root))
                                    arguments)
                            :output :string :error-output :string :ignore-error-status t)
        (declare (ignore error-output))
        (values code (string-trim '(#\Space #\Newline #\Return) output)))
    (error () (values nil ""))))

(defun %revision-membership (state path recorded-blob root)
  "Whether Git, asked now in ROOT, names RECORDED-BLOB at PATH in commit STATE.
:VERIFIED only when it does. :CONTRADICTED when it knows the commit and names
another blob there, or none. :NOT-VERIFIED when the question could not be put."
  (flet ((answer (binding reason &optional git-answer)
           (list :path path :revision-binding binding :reason reason :git-answer git-answer)))
    (cond
      ((not (%full-object-id-p state)) (answer :not-verified :revision-is-not-a-full-object-id))
      ((null root) (answer :not-verified :no-repository-given))
      (t
       (multiple-value-bind (code type) (%git root "cat-file" "-t" state)
         (cond
           ((null code) (answer :not-verified :git-could-not-be-run))
           ((/= 0 code) (answer :not-verified :commit-not-in-this-repository))
           ((string/= "commit" type) (answer :contradicted :revision-is-not-a-commit type))
           (t
            (multiple-value-bind (code blob)
                (%git root "rev-parse" "--verify" "--quiet" (format nil "~A:~A" state path))
              (cond
                ((null code) (answer :not-verified :git-could-not-be-run))
                ((/= 0 code) (answer :contradicted :path-absent-in-commit))
                ((string= blob recorded-blob) (answer :verified :commit-names-the-recorded-blob blob))
                (t (answer :contradicted :commit-names-another-blob blob)))))))))))

;;;; The source state, observed

(defun %observe-file (entry root octets)
  "How the file ENTRY names relates to its recorded identity. OCTETS, when
given, are read in place of the file: the same path, other content."
  (let* ((path (getf entry :path))
         (octets (or octets (and root (%file-octets (merge-pathnames path root))))))
    (if (null octets)
        (list :role (getf entry :role) :path path :status :absent)
        (multiple-value-bind (text why) (%decode-utf-8 octets)
          (let ((sha256 (sha256-of octets)) (blob (git-blob-id-of octets)))
            (list :role (getf entry :role) :path path
                  :status (cond ((null text) :unreadable)
                                ((and (string= sha256 (getf entry :sha256))
                                      (string= blob (getf entry :git-blob)))
                                 :recorded-snapshot)
                                (t :changed))
                  :sha256 sha256 :git-blob blob :condition why :text text))))))

(defun observe-source-state (recorded &key root octets)
  "Each file RECORDED names, as it reads now under ROOT, against its recorded
identity; and, separately, whether Git names the recorded blobs in the
recorded commit. OCTETS is a plist from role to octets read in place of that
role's file. Reads; writes nothing and loads nothing."
  (let* ((state (getf recorded :state))
         (files (mapcar (lambda (entry) (%observe-file entry root (getf octets (getf entry :role))))
                        (getf recorded :files)))
         (memberships (mapcar (lambda (entry)
                                (%revision-membership state (getf entry :path) (getf entry :git-blob) root))
                              (getf recorded :files)))
         (bindings (mapcar (lambda (membership) (getf membership :revision-binding)) memberships)))
    (list :kind :source-state-observation :state state :files files
          :content (if (every (lambda (file) (eq :recorded-snapshot (getf file :status))) files)
                       :matches-recorded
                       :differs)
          :revision-binding (cond ((member :contradicted bindings) :contradicted)
                                  ((every (lambda (binding) (eq :verified binding)) bindings) :verified)
                                  (t :not-verified))
          :revision-membership memberships
          :provenance (%executed) :evidence-status :observed)))

(defun source-coherence (observation)
  "What a comparison of these sources may be said to be about. :VERIFIED-REVISION
when both texts are the recorded ones and Git names them in the recorded
commit; :RECORDED-CONTENT when they are the recorded texts and membership in
the commit was not verified here; otherwise :NOT-DETERMINED, with why."
  (let ((content (getf observation :content)) (binding (getf observation :revision-binding)))
    (cond ((eq :contradicted binding)
           (list :scope :not-determined :reason :revision-membership-contradicted))
          ((not (eq :matches-recorded content))
           (list :scope :not-determined
                 :reason (mapcar (lambda (file) (list (getf file :role) (getf file :status)))
                                 (remove :recorded-snapshot (getf observation :files)
                                         :key (lambda (file) (getf file :status))))))
          ((eq :verified binding) (list :scope :verified-revision :state (getf observation :state)))
          (t (list :scope :recorded-content
                   :reason :revision-membership-not-verified-here)))))

;;;; The passage

(defun %occurrences (needle text)
  (loop with start = 0
        for position = (search needle text :start2 start)
        while position
        collect position
        do (setf start (1+ position))))

(defun observe-passage (passage text)
  "Where PASSAGE's text stands in TEXT: once, not at all, or more than once."
  (let* ((needle (getf passage :text))
         (found (%occurrences needle text))
         (range (getf passage :range)))
    (list :kind :passage-observation
          :status (case (length found) (0 :absent) (1 :present-once) (t :ambiguous))
          :occurrences (length found)
          :range (and (= 1 (length found))
                      (cons (first found) (+ (first found) (length needle))))
          :at-recorded-range-p (and (= 1 (length found)) (eql (first found) (car range))
                                    (eql (+ (first found) (length needle)) (cdr range)))
          :provenance (%executed) :evidence-status :observed)))

;;;; The records, read from the text of their definition

(defparameter +definition-prefix+ "(defun historical-claims"
  "How the one definition this reads begins, at the start of a line.")

(defun %definition-starts (text)
  "The positions in TEXT at which a line begins with the definition."
  (loop for position in (%occurrences +definition-prefix+ text)
        for end = (+ position (length +definition-prefix+))
        when (and (or (zerop position) (char= #\Newline (char text (1- position))))
                  (< end (length text))
                  (member (char text end) '(#\Space #\Newline #\Tab)))
          collect position))

(defun %proper-list-p (object)
  (and (listp object) (handler-case (list-length object) (error () nil)) t))

(defun %literal-p (value depth)
  "Whether VALUE is data that says the same wherever it is read: a keyword, a
string, T, NIL, an integer, or a proper list of such, not nested beyond DEPTH."
  (cond ((minusp depth) nil)
        ((or (keywordp value) (stringp value) (integerp value) (eq t value) (null value)) t)
        ((consp value)
         (and (%proper-list-p value)
              (every (lambda (element) (%literal-p element (1- depth))) value)))
        (t nil)))

(defun %claim-record-p (record)
  (and (%proper-list-p record) (evenp (length record))
       (loop for (key value) on record by #'cddr
             always (and (keywordp key) (%literal-p value 8)))))

(defun read-claim-table (text)
  "The quoted table inside the one definition of HISTORICAL-CLAIMS in TEXT, as
data. Two values: the table and NIL, or NIL and why it was refused.

Reads one form, with the standard readtable and *READ-EVAL* false, so #. is a
reader error and nothing is evaluated at read time; symbols are read into a
package made for the purpose and deleted afterwards. The form is never
evaluated, compiled or loaded: the table is taken out of it only when the form
is exactly (DEFUN HISTORICAL-CLAIMS () [docstring] (COPY-TREE (QUOTE table)))
and the table is a list of property lists with keyword keys and literal
values. Anything else is refused, not interpreted."
  (let ((starts (%definition-starts text)))
    (unless (= 1 (length starts))
      (return-from read-claim-table (values nil (list :definitions-found (length starts)))))
    (let ((package (make-package (format nil "DREYECK/TEXT-PASSAGE/READ-~36R" (random (expt 36 10)))
                                 :use '(#:common-lisp))))
      (unwind-protect
           (let ((form (handler-case
                           (with-standard-io-syntax
                             (let ((*read-eval* nil) (*package* package))
                               (with-input-from-string (stream text :start (first starts))
                                 (read stream))))
                         (error (condition)
                           (return-from read-claim-table
                             (values nil (list :reader-refused (format nil "~A" (type-of condition)))))))))
             (unless (and (%proper-list-p form)
                          (member (length form) '(4 5))
                          (eq 'defun (first form))
                          (symbolp (second form))
                          (string= "HISTORICAL-CLAIMS" (symbol-name (second form)))
                          (null (third form))
                          (or (= 4 (length form)) (stringp (fourth form))))
               (return-from read-claim-table (values nil (list :unexpected-definition-shape))))
             (let ((body (first (last form))))
               (unless (and (%proper-list-p body) (= 2 (length body)) (eq 'copy-tree (first body))
                            (%proper-list-p (second body)) (= 2 (length (second body)))
                            (eq 'quote (first (second body))))
                 (return-from read-claim-table (values nil (list :unexpected-definition-shape))))
               (let ((table (second (second body))))
                 (if (and (%proper-list-p table) (every #'%claim-record-p table))
                     (values table nil)
                     (values nil (list :table-is-not-literal-data))))))
        (delete-package package)))))

(defun observe-claim-evidence (table)
  "What TABLE records as the observed evidence of each claim that cites a
primary paper, in the table's order, with counts."
  (let* ((rows (loop for claim in table
                     when (eq :primary-paper (getf claim :cited-source-kind))
                       collect (list :subject (getf claim :subject) :id (getf claim :id)
                                     :observed-evidence-kind (getf claim :observed-evidence-kind)
                                     :locator-observed-p (getf claim :locator-observed-p))))
         (kinds (remove-duplicates (mapcar (lambda (row) (getf row :observed-evidence-kind)) rows))))
    (list :kind :probe-observation :probe 'observe-claim-evidence
          :question "What do the records give as the observed evidence of each claim that cites a primary paper?"
          :result (list :claims-citing-a-primary-paper (length rows)
                        :by-observed-evidence-kind
                        (mapcar (lambda (kind)
                                  (cons kind (count kind rows :key (lambda (row) (getf row :observed-evidence-kind)))))
                                kinds)
                        :rows rows)
          :provenance (%executed) :evidence-status :observed)))

;;;; Reading against records

(defun %assertion-observed (expects rows)
  "What ROWS show where the assertion EXPECTS something, and whether they bear
it out. An expectation this does not know is an error, not a pass."
  (flet ((kind (row) (getf row :observed-evidence-kind)))
    (destructuring-bind (form field &rest arguments) expects
      (unless (eq :observed-evidence-kind field)
        (error "Unknown field in expectation ~S." expects))
      (ecase form
        (:count (destructuring-bind (kind number) arguments
                  (let ((observed (count kind rows :key #'kind)))
                    (values (= number observed) observed))))
        (:first (destructuring-bind (kind) arguments
                  (let ((observed (and rows (kind (first rows)))))
                    (values (and rows (eq kind observed)) observed))))
        (:rest (destructuring-bind (kind) arguments
                 (let ((observed (mapcar #'kind (rest rows))))
                   (values (every (lambda (other) (eq kind other)) observed)
                           (remove kind observed)))))))))

(defun passage-discrepancies (reading claim-observation)
  "The assertions of READING that the records in CLAIM-OBSERVATION do not bear
out. NIL when they bear out all of them. Derived by comparison; it says that
the two disagree, never which of them is wrong."
  (let ((rows (getf (getf claim-observation :result) :rows)))
    (loop for assertion in (getf reading :assertions)
          for (holds observed) = (multiple-value-list
                                  (%assertion-observed (getf assertion :expects) rows))
          unless holds
            collect (list :assertion (getf assertion :id) :statement (getf assertion :statement)
                          :expected (getf assertion :expects) :observed observed))))

(defun criticise-passage (recorded reading &key root octets)
  "Observe the two sources RECORDED names, and compare READING with the records
only when both are the recorded texts. :DISCREPANCIES is a list, NIL, or
:NOT-DETERMINED; :SCOPE says what a list or NIL is about, and is
:VERIFIED-REVISION only when Git confirmed the commit."
  (let* ((source (observe-source-state recorded :root root :octets octets))
         (coherence (source-coherence source))
         (files (getf source :files))
         (page (find :page files :key (lambda (file) (getf file :role))))
         (claims-source (find :claims-source files :key (lambda (file) (getf file :role))))
         (passage (and (getf page :text) (observe-passage (getf recorded :passage) (getf page :text))))
         (table-refusal nil)
         (claims (and (getf claims-source :text)
                      (multiple-value-bind (table why) (read-claim-table (getf claims-source :text))
                        (setf table-refusal why)
                        (and (null why) (observe-claim-evidence table)))))
         (determined (and (not (eq :not-determined (getf coherence :scope)))
                          passage (eq :present-once (getf passage :status))
                          claims)))
    (list :kind :text-criticism-observation
          :source-state (list* :files (mapcar (lambda (file) (let ((copy (copy-list file)))
                                                               (remf copy :text)
                                                               copy))
                                              files)
                               (let ((copy (copy-list source))) (remf copy :files) copy))
          :passage (or passage (list :kind :passage-observation :status :not-observed))
          :claims (or claims (list :kind :probe-observation :status :claims-unreadable :why table-refusal))
          :coherence coherence
          :scope (if determined (getf coherence :scope) :not-determined)
          :discrepancies (if determined (passage-discrepancies reading claims) :not-determined)
          :derivation (list :rule :compare-a-reading-of-the-passage-with-the-claim-table
                            :status :derived :reading-status (getf reading :evidence-status)))))
