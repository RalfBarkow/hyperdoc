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

(defun %source-forms (text)
  "Inert syntax only. Tokens are tagged strings, never interned or read by READ."
  (let ((position 0) (size (length text)))
    (labels ((peek () (and (< position size) (char text position)))
             (fail () (error "Unsupported or incomplete source at offset ~D" position))
             (spacep (c) (and c (find c '(#\Space #\Tab #\Newline #\Return #\Page))))
             (skip ()
               (loop
                 (cond ((spacep (peek)) (incf position))
                       ((eql (peek) #\;) (loop while (and (peek) (not (eql (peek) #\Newline))) do (incf position)))
                       ((and (eql (peek) #\#) (< (1+ position) size)
                             (char= #\| (char text (1+ position))))
                        (incf position 2)
                        (let ((depth 1))
                          (loop while (plusp depth) do
                            (unless (peek) (fail))
                            (cond ((and (< (1+ position) size)
                                        (string= text "#|" :start1 position :end1 (+ position 2)))
                                   (incf depth) (incf position 2))
                                  ((and (< (1+ position) size)
                                        (string= text "|#" :start1 position :end1 (+ position 2)))
                                   (decf depth) (incf position 2))
                                  (t (incf position))))))
                       (t (return)))))
             (form (depth)
               (when (> depth 128) (fail))
               (skip)
               (let ((c (peek)))
                 (unless c (fail))
                 (incf position)
                 (cond
                   ((char= c #\() (loop do (skip) (unless (peek) (fail))
                                       (when (eql (peek) #\)) (incf position) (return values))
                                       collect (form (1+ depth)) into values))
                   ((char= c #\)) (fail))
                   ((char= c #\")
                    (with-output-to-string (out)
                      (loop (unless (peek) (fail))
                            (let ((next (char text position)))
                              (incf position)
                              (when (char= next #\") (return))
                              (when (char= next #\\)
                                (unless (peek) (fail))
                                (setf next (char text position)) (incf position))
                              (write-char next out)))))
                   ((find c '(#\' #\` #\,))
                    (when (and (char= c #\,) (eql (peek) #\@)) (incf position))
                    (list (list :token (if (char= c #\') "QUOTE" "UNSUPPORTED-PREFIX"))
                          (form (1+ depth))))
                   ((char= c #\#)
                    (cond ((eql (peek) #\:)
                           (list (list :token "UNINTERNED-SYMBOL") (form (1+ depth))))
                          ((eql (peek) #\') (incf position)
                           (list (list :token "FUNCTION") (form (1+ depth))))
                          ((eql (peek) #\\)
                           ;; The first character is escaped even when it is a
                           ;; terminating macro character (e.g. semicolon or quote).
                           ;; Subsequent terminating characters belong to the source.
                           (incf position) (unless (peek) (fail))
                           (let ((start position))
                             (incf position)
                             (loop while (and (peek) (not (spacep (peek)))
                                              (not (find (peek) "();\"'`,")))
                                   do (incf position))
                             (let ((name (subseq text start position)))
                               (unless (or (= 1 (length name))
                                           (member name '("Space" "Newline" "Tab" "Return"
                                                          "Page" "Rubout" "Backspace")
                                                   :test #'string-equal))
                                 (fail))))
                           (list :token "UNSUPPORTED-CHARACTER"))
                          (t (fail))))
                   (t
                    (let ((start (1- position)))
                      (when (find c "|\\") (fail))
                      (loop while (and (peek) (not (spacep (peek))) (not (find (peek) "();\"'`,")))
                            do (when (find (peek) "#|\\") (fail)) (incf position))
                      (list :token (string-upcase (subseq text start position)))))))))
      (loop do (skip) (unless (peek) (return forms)) collect (form 0) into forms))))

(defun %token-is (node name)
  (and (consp node) (eq :token (first node)) (equal name (second node))))

(defun %literal-node-p (node depth)
  (and (not (minusp depth))
       (cond ((stringp node) t)
             ((and (consp node) (eq :token (first node)))
              (let ((name (second node)))
                (or (member name '("T" "NIL") :test #'equal)
                    (and (> (length name) 1) (char= #\: (char name 0))
                         (every (lambda (c) (or (alpha-char-p c) (digit-char-p c) (find c "-_*"))) (subseq name 1)))
                    (ignore-errors (parse-integer name :junk-allowed nil)))))
             ((listp node) (every (lambda (x) (%literal-node-p x (1- depth))) node)))))

(defun %literal-node-value (node)
  (cond ((stringp node) node)
        ((and (consp node) (eq :token (first node)))
         (let ((name (second node)))
           (cond ((equal name "NIL") nil) ((equal name "T") t)
                 ((char= #\: (char name 0)) (intern (subseq name 1) :keyword))
                 (t (parse-integer name)))))
        (t (mapcar #'%literal-node-value node))))

(defun read-claim-table (text)
  "Extract one active top-level literal definition using an inert structural grammar.
No Common Lisp reader, package lookup, constructor, feature conditional or evaluation is invoked.
Return TABLE,NIL or NIL,REASON. See docs/lisp-critic-reader-safety/README.md."
  (let* ((forms (handler-case (%source-forms text)
                  (error () (return-from read-claim-table (values nil '(:reader-refused "UNSUPPORTED-SOURCE-SYNTAX"))))))
         (candidates (remove-if-not
                      (lambda (form) (and (listp form) (%token-is (first form) "DEFUN")
                                          (%token-is (second form) "HISTORICAL-CLAIMS"))) forms)))
    (unless (= 1 (length candidates))
      (return-from read-claim-table (values nil (list :definitions-found (length candidates)))))
    (let* ((form (first candidates)) (body (car (last form))))
      (unless (and (member (length form) '(4 5)) (null (third form))
                   (or (= 4 (length form)) (stringp (fourth form)))
                   (listp body) (= 2 (length body)) (%token-is (first body) "COPY-TREE")
                   (listp (second body)) (= 2 (length (second body)))
                   (%token-is (first (second body)) "QUOTE"))
        (return-from read-claim-table (values nil '(:unexpected-definition-shape))))
      (let ((table (second (second body))))
        (unless (and (listp table) (%literal-node-p table 10)
                     (every (lambda (row)
                              (and (listp row) (evenp (length row))
                                   (loop for key in row by #'cddr
                                         always (and (consp key) (eq :token (first key))
                                                     (char= #\: (char (second key) 0)))))) table))
          (return-from read-claim-table (values nil '(:table-is-not-literal-data))))
        (values (%literal-node-value table) nil)))))

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
         (claims (and (not (eq :not-determined (getf coherence :scope)))
                      (getf claims-source :text)
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
          :claims (or claims (list :kind :probe-observation :status (if (and (getf claims-source :text) (eq :not-determined (getf coherence :scope)))
                                                        :claims-not-parsed :claims-unreadable)
                                  :why (or table-refusal (and (eq :not-determined (getf coherence :scope))
                                                             :source-state-not-coherent))))
          :coherence coherence
          :scope (if determined (getf coherence :scope) :not-determined)
          :discrepancies (if determined (passage-discrepancies reading claims) :not-determined)
          :derivation (list :rule :compare-a-reading-of-the-passage-with-the-claim-table
                            :status :derived :reading-status (getf reading :evidence-status)))))
