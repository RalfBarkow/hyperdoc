;;;; The code ownership inventory of upstream's library paths, per definition.
;;;;
;;;; Two things are kept apart. A MANIFEST is what upstream's library has at a reference commit: for every Lisp and ASDF file, the key and the digest of every
;;;; top-level definition (digests of canonical source trees, so formatting and comments do not count). It is made once from Git objects and stored as plain data, so
;;;; that checking the fork needs no Git history: a Nix build has none. An INVENTORY says, for every definition in which the fork's library paths differ from the
;;;; manifest, why: its origin, its owner, whether the difference is accepted, pending or migrated, and where it should stand.
;;;;
;;;; The check scans the fork's files (as syntax; nothing is loaded) and compares them with the manifest. A difference that is not in the inventory is a failure; so is an
;;;; entry whose difference is gone or has changed since it was accepted; a definition that was migrated is verified at its new place.

(in-package #:dreyeck/code-ownership)

(defparameter +library-paths+ ua:+library-paths+)

(defun library-path-p (path paths)
  (some (lambda (p) (or (string= path p) (uiop:string-prefix-p (concatenate 'string p "/") path))) paths))

(defun code-file-p (path) (member (pathname-type path) '("lisp" "asd") :test #'equal))

(defun library-files-at (repository ref paths)
  "The Lisp and ASDF files under PATHS at REF, from Git objects."
  (sort (remove-if-not #'code-file-p
                       (remove "" (uiop:split-string
                                   (apply #'g:git-run-string (g:git-repository-root-of repository) "ls-tree" "-r" "--name-only" ref "--" paths)
                                   :separator '(#\Newline))
                               :test #'string=))
        #'string<))

(defun current-library-files (root paths)
  "The Lisp and ASDF files under PATHS in the work tree at ROOT, as paths relative to it."
  (let ((root (uiop:ensure-directory-pathname root)) (files '()))
    (dolist (p paths)
      (let ((full (merge-pathnames p root)))
        (cond ((uiop:directory-exists-p (uiop:ensure-directory-pathname full))
               (dolist (file (directory (merge-pathnames "**/*.*" (uiop:ensure-directory-pathname full))))
                 (when (code-file-p (namestring file)) (push (enough-namestring file root) files))))
              ((and (probe-file full) (code-file-p p)) (push p files)))))
    (sort (remove-duplicates files :test #'string=) #'string<)))

(defun blob-definitions (repository ref path)
  (let ((text (ua::blob-text repository ref path))) (and text (ua:top-level-definitions text :path path))))

(defun definition-form (definition)
  (list (ua:source-definition-key definition) (ua:source-definition-kind definition) (ua:source-definition-digest definition)))

(defun build-manifest (repository ref &optional (paths +library-paths+))
  "The manifest of upstream's library at REF: every file's definitions by key, kind and digest."
  (let ((sha (g:trim-git-output (g:git-run-string (g:git-repository-root-of repository) "rev-parse" (format nil "~A^{commit}" ref)))))
    (list :library-manifest :version 1 :reference sha :paths paths
          :files (loop for path in (library-files-at repository sha paths)
                       collect (list :path path :definitions (mapcar #'definition-form (blob-definitions repository sha path)))))))

(defun manifest-form (manifest) manifest)
(defun manifest-reference (manifest) (getf (rest manifest) :reference))
(defun manifest-files (manifest) (getf (rest manifest) :files))
(defun manifest-paths (manifest) (getf (rest manifest) :paths))
(defun read-manifest (pathname) (ua::read-plain-data pathname))
(defun write-manifest (manifest pathname) (ua::write-plain-data manifest pathname))

;;; The differences

(defstruct deviation path key kind upstream-digest current-digest origin)

(defun file-text (root path)
  (and (probe-file (merge-pathnames path root)) (uiop:read-file-string (merge-pathnames path root) :external-format :utf-8)))

(defun current-deviations (root manifest)
  "Every definition in which the files under the manifest's paths at ROOT differ from the manifest: changed, added (also in an added file) or removed (also with a removed
file). Git-free: the fork's files are scanned as syntax."
  (let* ((root (uiop:ensure-directory-pathname root)) (deviations '())
         (upstream (let ((table (make-hash-table :test #'equal))) (dolist (f (manifest-files manifest) table) (setf (gethash (getf f :path) table) (getf f :definitions)))))
         (paths (sort (remove-duplicates (append (loop for f in (manifest-files manifest) collect (getf f :path))
                                                 (current-library-files root (manifest-paths manifest)))
                                         :test #'string=)
                      #'string<)))
    (dolist (path paths)
      (let* ((before (gethash path upstream)) (text (file-text root path))
             (after (and text (mapcar #'definition-form (ua:top-level-definitions text :path path))))
             (before-table (let ((table (make-hash-table :test #'equal))) (dolist (d before table) (setf (gethash (first d) table) d))))
             (after-table (let ((table (make-hash-table :test #'equal))) (dolist (d after table) (setf (gethash (first d) table) d)))))
        (dolist (d after)
          (let ((old (gethash (first d) before-table)))
            (cond ((null old) (push (make-deviation :path path :key (first d) :kind :added :current-digest (third d)) deviations))
                  ((not (equal (third old) (third d)))
                   (push (make-deviation :path path :key (first d) :kind :changed :upstream-digest (third old) :current-digest (third d)) deviations)))))
        (dolist (d before)
          (unless (gethash (first d) after-table)
            (push (make-deviation :path path :key (first d) :kind :removed :upstream-digest (third d)) deviations)))))
    (nreverse deviations)))

(defun deviation-origin-commit (repository path digest)
  "The first commit, oldest first among those that touched PATH, whose version of the file has a definition with DIGEST: where the fork's current form first stood."
  (let ((commits (remove "" (uiop:split-string (g:git-run-string (g:git-repository-root-of repository) "log" "--format=%H" "--reverse" "--" path) :separator '(#\Newline)) :test #'string=)))
    (dolist (commit commits)
      (let ((definitions (blob-definitions repository commit path)))
        (when (find digest definitions :key #'ua:source-definition-digest :test #'equal)
          (return (values commit (g:trim-git-output (g:git-run-string (g:git-repository-root-of repository) "show" "-s" "--format=%s" commit)))))))))

;;; The inventory

(defun read-decisions (pathname) (ua::read-plain-data pathname))

(defun decision-rule-for (decisions path key)
  "The rule of DECISIONS (plain data) that covers the definition KEY of PATH, or NIL."
  (find-if (lambda (rule) (and (equal path (getf rule :path))
                               (let ((keys (getf rule :keys))) (or (eq keys :all) (member key keys :test #'equal)))))
           (getf (rest decisions) :rules)))

(defun build-inventory (root repository manifest decisions)
  "The inventory for the fork at ROOT: one PENDING entry for every difference from MANIFEST, joined with the rule of DECISIONS that covers it, the ASDF owner of its file
and the commit where its current form first stood (from REPOSITORY's history). A difference no rule covers is an error: nobody has said what it is."
  (let* ((deviations (current-deviations root manifest)) (index (ua:make-fork-index root)) (origins (make-hash-table :test #'equal)) (entries '()))
    ;; the origin of an added or changed form: where its digest first stood. A removed form takes the origin of what replaced it in the same file.
    (dolist (d deviations)
      (when (deviation-current-digest d)
        (multiple-value-bind (sha subject) (deviation-origin-commit repository (deviation-path d) (deviation-current-digest d))
          (setf (gethash (list (deviation-path d) (deviation-key d)) origins) (list sha subject)))))
    (dolist (d deviations)
      (let* ((rule (decision-rule-for decisions (deviation-path d) (deviation-key d)))
             (own (gethash (list (deviation-path d) (deviation-key d)) origins))
             (origin (or own
                         (loop for other in deviations
                               for found = (and (equal (deviation-path other) (deviation-path d)) (gethash (list (deviation-path other) (deviation-key other)) origins))
                               when (and found (first found)) return found)))
             (owners (if (uiop:string-prefix-p "system:" (deviation-key d))
                         (list (subseq (deviation-key d) (length "system:")))   ; an ASDF system definition is owned by itself
                         (ua:system-owners-of index (deviation-path d)))))
        (unless rule (error "No ownership rule covers ~A ~A." (deviation-path d) (deviation-key d)))
        (push (list :path (deviation-path d) :key (deviation-key d) :kind (deviation-kind d)
                    :upstream-digest (deviation-upstream-digest d) :current-digest (deviation-current-digest d)
                    :status :pending :nature (getf rule :nature) :category (getf rule :category) :owner-now (or owners (list "none"))
                    :target-system (getf rule :target-system) :proposed-target (getf rule :proposed-target) :priority (getf rule :priority)
                    :basis (getf rule :basis) :plan (getf rule :plan) :documented-in (getf rule :documented-in)
                    :origin-commit (first origin) :origin-subject (second origin))
              entries)))
    (list :library-inventory :version 1 :reference (manifest-reference manifest) :entries (nreverse entries))))

(defun read-inventory (pathname) (ua::read-plain-data pathname))
(defun write-inventory (inventory pathname) (ua::write-plain-data inventory pathname))
(defun inventory-entries (inventory) (getf (rest inventory) :entries))

(defstruct inventory-report lines problems counts)

(defun entry-key (entry) (list (getf entry :path) (getf entry :key)))

(defun check-entry-shape (entry)
  "The fields an entry must give, by status."
  (let ((missing '()))
    (flet ((need (field) (unless (getf entry field) (push field missing))))
      (mapc #'need '(:path :key :kind :status :category :owner-now :basis))
      (ecase (getf entry :status)
        (:accepted (mapc #'need '(:justification :origin-commit :target-system)))
        (:pending (mapc #'need '(:origin-commit :proposed-target :plan :priority)))
        (:migrated (mapc #'need '(:moved-to :justification)))))
    (nreverse missing)))

(defun definition-at-path (root path key)
  (let ((text (file-text (uiop:ensure-directory-pathname root) path)))
    (and text (find key (ua:top-level-definitions text :path path) :key #'ua:source-definition-key :test #'equal))))

(defun check-library-inventory (root manifest inventory)
  "Compare the fork's library files at ROOT with MANIFEST and INVENTORY. Returns an INVENTORY-REPORT: one line per difference with its status, and the problems:
:UNINVENTORIED (a difference nobody recorded), :STALE (an entry whose difference is gone, or whose form changed after it was recorded), :INCOMPLETE (an entry without the
fields its status needs), :MIGRATION (a migrated definition that is not at its new place, or still in the library). Pending entries are reported, not accepted."
  (let* ((deviations (current-deviations root manifest)) (entries (inventory-entries inventory)) (lines '()) (problems '())
         (counts (list :accepted 0 :pending 0 :migrated 0 :uninventoried 0)))
    (flet ((problem (kind &rest details) (push (list* kind details) problems)))
      (when (not (equal (manifest-reference manifest) (getf (rest inventory) :reference)))
        (problem :reference "The inventory and the manifest do not name the same upstream reference."))
      (dolist (d deviations)
        (let ((entry (find (list (deviation-path d) (deviation-key d)) entries :key #'entry-key :test #'equal)))
          (cond
            ((null entry)
             (incf (getf counts :uninventoried))
             (push (format nil "UNINVENTORIED  ~(~A~)  ~A  ~A" (deviation-kind d) (deviation-path d) (deviation-key d)) lines)
             (problem :uninventoried (deviation-path d) (deviation-key d) (deviation-kind d)))
            ((eq :migrated (getf entry :status))
             (push (format nil "STALE          ~A  ~A is recorded as migrated but still differs in the library" (deviation-path d) (deviation-key d)) lines)
             (problem :migration (deviation-path d) (deviation-key d) "still differs in the library path"))
            (t
             (let ((missing (check-entry-shape entry)))
               (when missing (problem :incomplete (deviation-path d) (deviation-key d) missing)))
             (cond ((not (and (eq (getf entry :kind) (deviation-kind d))
                              (equal (getf entry :upstream-digest) (deviation-upstream-digest d))
                              (equal (getf entry :current-digest) (deviation-current-digest d))))
                    (push (format nil "STALE          ~A  ~A changed after it was recorded" (deviation-path d) (deviation-key d)) lines)
                    (problem :stale (deviation-path d) (deviation-key d) "the difference is not the one recorded"))
                   (t (incf (getf counts (getf entry :status)))
                      (push (format nil "~14A ~(~A~)  ~A  ~A  [~(~A~), ~A]" (string-upcase (symbol-name (getf entry :status))) (deviation-kind d) (deviation-path d) (deviation-key d)
                                    (getf entry :category) (or (getf entry :owner-now) "-"))
                            lines)))))))
      ;; entries with no difference left
      (dolist (entry entries)
        (let ((there (find (entry-key entry) deviations :key (lambda (d) (list (deviation-path d) (deviation-key d))) :test #'equal)))
          (cond ((and (null there) (eq :migrated (getf entry :status)))
                 (destructuring-bind (&key path key digest &allow-other-keys) (getf entry :moved-to)
                   (let ((moved (definition-at-path root path key)))
                     (cond ((null moved) (problem :migration (getf entry :path) (getf entry :key) (format nil "not at its new place ~A ~A" path key))
                            (push (format nil "STALE          ~A  ~A migrated, but not at ~A" (getf entry :path) (getf entry :key) path) lines))
                           ((and digest (not (equal digest (ua:source-definition-digest moved))))
                            (problem :migration (getf entry :path) (getf entry :key) (format nil "the form at ~A differs from the one migrated" path))
                            (push (format nil "STALE          ~A  ~A at its new place ~A differs from the form migrated" (getf entry :path) (getf entry :key) path) lines))
                           (t (incf (getf counts :migrated))
                              (push (format nil "MIGRATED       ~A  ~A  now ~A ~A  [~(~A~)]" (getf entry :path) (getf entry :key) path key (getf entry :category)) lines))))))
                ((null there)
                 (problem :stale (getf entry :path) (getf entry :key) "no difference left: remove the entry or record it as migrated")
                 (push (format nil "STALE          ~A  ~A has no difference from upstream any more" (getf entry :path) (getf entry :key)) lines))))))
    (make-inventory-report :lines (nreverse lines) :problems (nreverse problems) :counts counts)))

(defun inventory-report-ok-p (report) (null (inventory-report-problems report)))
(defun inventory-report-clean-p (report) (and (inventory-report-ok-p report) (zerop (getf (inventory-report-counts report) :pending))))

(defun print-inventory-report (report &optional (stream *standard-output*))
  (dolist (line (inventory-report-lines report)) (format stream "  ~A~%" line))
  (destructuring-bind (&key accepted pending migrated uninventoried) (inventory-report-counts report)
    (format stream "  accepted: ~D, pending (not accepted): ~D, migrated and verified: ~D, uninventoried: ~D; problems: ~D~%"
            accepted pending migrated uninventoried (length (inventory-report-problems report)))))
