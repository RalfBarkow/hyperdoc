;;;; A pinned Git commit's tree as a Nix store snapshot, verified without .git.
;;;;
;;;; A Nix source snapshot has no .git, so a Git check cannot run there. Instead, a manifest committed in HyperDoc
;;;; carries the commit's raw object and its root tree listing, and the snapshot's files are hashed as Git hashes
;;;; them: the commit object hashes to the pinned id, names the root tree, the listing hashes to that tree, and
;;;; every shipped entry's files hash to the listing. An excluded entry is named by its tree id; it is neither
;;;; shipped nor verified. The tree check is independent of where the tree lies; accepting it as the loaded
;;;; source is a separate policy that admits only a read-only /nix/store path. A Git checkout keeps its own checks.

(defpackage #:dreyeck/source-snapshot
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views))
  (:export #:snapshot-manifest #:read-snapshot-manifest #:find-snapshot-manifest #:manifest-pathname
           #:manifest-commit #:manifest-commit-object #:manifest-root-tree #:manifest-entries #:manifest-excluded
           #:manifest-nar-hash
           #:git-object-id #:snapshot-refused #:snapshot-refused-reason
           #:snapshot-verification #:verify-snapshot-tree #:verification-root #:verification-manifest
           #:verification-checks #:verification-blob-count #:verification-blob-id
           #:verification-started #:verification-finished
           #:source-kind #:verify-store-snapshot
           #:snapshot-file #:make-snapshot-file #:snapshot-file-verification #:snapshot-file-path
           #:snapshot-file-contents #:snapshot-path #:make-snapshot-path))
(in-package #:dreyeck/source-snapshot)

(define-condition snapshot-refused (error)
  ((reason :initarg :reason :reader snapshot-refused-reason))
  (:report (lambda (c s) (format s "Source snapshot refused: ~A" (snapshot-refused-reason c)))))
(defun refuse (control &rest arguments) (error 'snapshot-refused :reason (apply #'format nil control arguments)))

;;; The manifest

(defclass snapshot-manifest ()
  ((pathname :initarg :pathname :reader manifest-pathname)
   (commit :initarg :commit :reader manifest-commit)
   (commit-object :initarg :commit-object :reader manifest-commit-object)
   (root-tree :initarg :root-tree :reader manifest-root-tree)
   (entries :initarg :entries :reader manifest-entries)
   (excluded :initarg :excluded :reader manifest-excluded)
   (nar-hash :initarg :nar-hash :reader manifest-nar-hash))
  (:documentation "What scripts/topic-maps-snapshot.py recorded from the repository: the raw commit object, the root
tree as (mode type id name) in Git's order, the excluded root entries and the NAR hash Nix pins."))
(defmethod v:text-representation ((m snapshot-manifest))
  (format nil "Snapshot manifest of ~A" (subseq (manifest-commit m) 0 8)))

(defun read-snapshot-manifest (pathname)
  (let ((form (with-open-file (in pathname :external-format :utf-8)
                (with-standard-io-syntax
                  (let ((*read-eval* nil) (*package* (find-package :keyword)))
                    (prog1 (read in) (unless (eq :eof (read in nil :eof)) (refuse "~A holds more than one form." pathname))))))))
    (unless (equal (getf form :format) "hyperdoc-topic-maps-snapshot-1")
      (refuse "~A is not a snapshot manifest." pathname))
    (make-instance 'snapshot-manifest :pathname pathname :commit (getf form :commit) :commit-object (getf form :commit-object)
                   :root-tree (getf form :root-tree) :entries (getf form :entries) :excluded (getf form :excluded)
                   :nar-hash (getf form :nar-hash))))

(defun find-snapshot-manifest (commit)
  "HyperDoc's manifest for COMMIT, under nix/ in HyperDoc's own source."
  (let* ((pathname (asdf:system-relative-pathname "dreyeck/source-snapshot"
                                                  (format nil "nix/topic-maps-~A.manifest" (subseq commit 0 8))))
         (manifest (if (probe-file pathname) (read-snapshot-manifest pathname) (refuse "No manifest for ~A." commit))))
    (unless (equal commit (manifest-commit manifest)) (refuse "~A names ~A, not ~A." pathname (manifest-commit manifest) commit))
    manifest))

;;; Git's object hashing

(defun %octets (string) (sb-ext:string-to-octets string :external-format :utf-8))
(defun git-object-id (type octets)
  "Git's SHA-1 object id of OCTETS as an object of TYPE (\"blob\", \"tree\" or \"commit\")."
  (let ((digest (ironclad:make-digest :sha1)))
    (ironclad:update-digest digest (%octets (format nil "~A ~D" type (length octets))))
    (ironclad:update-digest digest (make-array 1 :element-type '(unsigned-byte 8) :initial-element 0))
    (ironclad:update-digest digest (coerce octets '(simple-array (unsigned-byte 8) (*))))
    (ironclad:byte-array-to-hex-string (ironclad:produce-digest digest))))

(defun %tree-octets (entries)
  "A tree object from ENTRIES (mode name hex-id), already in Git's order. Git writes a tree's mode as 40000."
  (let ((out (make-array 0 :element-type '(unsigned-byte 8) :adjustable t :fill-pointer 0)))
    (dolist (entry entries (coerce out '(simple-array (unsigned-byte 8) (*))))
      (destructuring-bind (mode name id) entry
        (loop for b across (%octets (format nil "~A ~A" (string-left-trim "0" mode) name)) do (vector-push-extend b out))
        (vector-push-extend 0 out)
        (loop for b across (ironclad:hex-string-to-byte-array id) do (vector-push-extend b out))))))

(defun %octets< (a b)
  (let ((m (mismatch a b)))
    (cond ((null m) nil) ((= m (length a)) t) ((= m (length b)) nil) (t (< (aref a m) (aref b m))))))
(defun %git-order (entries)
  "Git sorts a tree by name, comparing a subtree's name as if it ended in /."
  (sort (copy-list entries) #'%octets<
        :key (lambda (e) (%octets (if (string= (first e) "40000") (concatenate 'string (second e) "/") (second e))))))

;;; Reading a directory as Git would: names from readdir, kinds from lstat, never following a link

(defun %native (directory name) (concatenate 'string directory "/" name))
(defun %listing (native-directory)
  (let ((dir (sb-posix:opendir native-directory)) (names nil))
    (unwind-protect
         (loop for entry = (sb-posix:readdir dir)
               until (sb-alien:null-alien entry)
               do (let ((name (sb-posix:dirent-name entry)))
                    (unless (member name '("." "..") :test #'string=) (push name names))))
      (sb-posix:closedir dir))
    names))
(defun %kind (native)
  (let ((mode (sb-posix:stat-mode (sb-posix:lstat native))))
    (case (logand mode sb-posix:s-ifmt)
      (#.sb-posix:s-ifreg (if (logtest mode sb-posix:s-ixusr) "100755" "100644"))
      (#.sb-posix:s-ifdir "40000")
      (#.sb-posix:s-iflnk (refuse "~A is a symbolic link; the pinned tree has none." native))
      (t (refuse "~A is not a regular file or directory." native)))))
(defun %file-octets (native)
  (with-open-file (in (sb-ext:parse-native-namestring native) :element-type '(unsigned-byte 8))
    (let ((data (make-array (file-length in) :element-type '(unsigned-byte 8))))
      (unless (= (length data) (read-sequence data in)) (refuse "~A changed while it was read." native))
      data)))

(defun %tree-id (native relative blobs)
  "Git's tree id of the directory NATIVE; records each file's blob id in BLOBS under its relative path."
  (let ((entries (mapcar (lambda (name)
                           (let* ((path (%native native name)) (kind (%kind path))
                                  (rel (if relative (concatenate 'string relative "/" name) name)))
                             (list kind name (if (string= kind "40000")
                                                 (%tree-id path rel blobs)
                                                 (setf (gethash rel blobs) (git-object-id "blob" (%file-octets path)))))))
                         (%listing native))))
    (when (null entries) (refuse "~A is empty; Git records no empty directory." native))
    (git-object-id "tree" (%tree-octets (%git-order entries)))))

;;; Verification

(defclass snapshot-verification ()
  ((root :initarg :root :reader verification-root)
   (manifest :initarg :manifest :reader verification-manifest)
   (checks :initarg :checks :reader verification-checks)
   (blobs :initarg :blobs :reader %verification-blobs)
   (started :initarg :started :reader verification-started)
   (finished :initarg :finished :reader verification-finished))
  (:documentation "One verification, at one time, that the tree at ROOT is the manifest's commit without its excluded
entries. It holds the blob id of every shipped file as hashed then."))
(defmethod v:text-representation ((s snapshot-verification))
  (format nil "Topic Maps ~A, verified snapshot (~{~A/~^, ~} excluded)" (subseq (manifest-commit (verification-manifest s)) 0 8)
          (manifest-excluded (verification-manifest s))))
(defun verification-blob-count (verification) (hash-table-count (%verification-blobs verification)))
(defun verification-blob-id (verification path) (values (gethash path (%verification-blobs verification))))

(defun verify-snapshot-tree (root manifest)
  "Verify that the directory ROOT is MANIFEST's commit without its excluded root entries, or signal SNAPSHOT-REFUSED."
  (let* ((started (get-universal-time)) (checks nil) (blobs (make-hash-table :test #'equal))
         (native (string-right-trim "/" (sb-ext:native-namestring (uiop:ensure-directory-pathname root))))
         (commit-object (%octets (manifest-commit-object manifest)))
         (entries (manifest-entries manifest)) (excluded (manifest-excluded manifest)))
    (flet ((ok (label) (push label checks)))
      (unless (string= (manifest-commit manifest) (git-object-id "commit" commit-object))
        (refuse "The manifest's commit object does not hash to ~A." (manifest-commit manifest)))
      (ok :commit-object-hashes-to-commit)
      (unless (eql 0 (search (format nil "tree ~A~%" (manifest-root-tree manifest)) (manifest-commit-object manifest)))
        (refuse "The commit object does not name root tree ~A." (manifest-root-tree manifest)))
      (ok :commit-names-root-tree)
      (unless (string= (manifest-root-tree manifest)
                       (git-object-id "tree" (%tree-octets (mapcar (lambda (e) (list (first e) (fourth e) (third e))) entries))))
        (refuse "The manifest's root listing does not hash to tree ~A." (manifest-root-tree manifest)))
      (ok :root-listing-hashes-to-root-tree)
      (let ((shipped (remove-if (lambda (e) (member (fourth e) excluded :test #'string=)) entries))
            (present (%listing native)))
        (unless (every (lambda (name) (find name entries :key #'fourth :test #'string=)) excluded)
          (refuse "An excluded entry is not in the commit's root tree."))
        (unless (and (= (length present) (length shipped))
                     (every (lambda (e) (member (fourth e) present :test #'string=)) shipped))
          (refuse "The snapshot's root entries ~S are not the commit's shipped entries ~S." (sort (copy-list present) #'string<)
                  (sort (mapcar #'fourth shipped) #'string<)))
        (ok :root-entries-are-the-shipped-entries)
        (dolist (entry shipped)
          (destructuring-bind (mode type id name) entry
            (let* ((path (%native native name)) (kind (%kind path)))
              (unless (string= (string-left-trim "0" mode) kind) (refuse "~A has mode ~A, the commit ~A." name kind mode))
              (unless (string= id (if (string= type "tree")
                                      (%tree-id path name blobs)
                                      (setf (gethash name blobs) (git-object-id "blob" (%file-octets path)))))
                (refuse "~A does not hash to the commit's ~A ~A." name type id)))))
        (ok :shipped-entries-hash-to-the-commit))
      (make-instance 'snapshot-verification :root root :manifest manifest :checks (reverse checks) :blobs blobs
                     :started started :finished (get-universal-time)))))

;;; Which evidence a source location can give

(defun source-kind (root)
  "How ROOT can be identified: :GIT-CHECKOUT if it has .git (Git's checks apply, unchanged), :NIX-STORE-SNAPSHOT if it is
a read-only /nix/store path without .git, otherwise :UNVERIFIABLE."
  (let ((root (uiop:ensure-directory-pathname root)))
    (cond ((probe-file (merge-pathnames ".git" root)) :git-checkout)
          ((uiop:string-prefix-p "/nix/store/" (namestring (truename root))) :nix-store-snapshot)
          (t :unverifiable))))

(defun verify-store-snapshot (root commit)
  "Verify the /nix/store snapshot at ROOT against HyperDoc's manifest for COMMIT. Anything else is refused."
  (unless (eq :nix-store-snapshot (source-kind root))
    (refuse "~A is not a /nix/store snapshot without .git; it is ~(~A~)." root (source-kind root)))
  (verify-snapshot-tree (truename root) (find-snapshot-manifest commit)))

;;; A file of a verified snapshot, read on request

(defclass snapshot-file ()
  ((verification :initarg :verification :reader snapshot-file-verification)
   (path :initarg :path :reader snapshot-file-path))
  (:documentation "One shipped file of a verified snapshot. Its contents are read when asked and refused unless they
still hash to the blob id recorded by the verification."))
(defun make-snapshot-file (verification path)
  (unless (verification-blob-id verification path) (refuse "~A is not a shipped file of the snapshot." path))
  (make-instance 'snapshot-file :verification verification :path path))
(defmethod v:text-representation ((f snapshot-file))
  (format nil "~A at ~A (verified snapshot)" (snapshot-file-path f)
          (subseq (manifest-commit (verification-manifest (snapshot-file-verification f))) 0 8)))
(defun snapshot-file-contents (file)
  (let* ((verification (snapshot-file-verification file))
         (native (%native (string-right-trim "/" (sb-ext:native-namestring (verification-root verification))) (snapshot-file-path file)))
         (octets (%file-octets native)))
    (unless (string= (verification-blob-id verification (snapshot-file-path file)) (git-object-id "blob" octets))
      (refuse "~A no longer hashes to its verified blob." (snapshot-file-path file)))
    (sb-ext:octets-to-string octets :external-format :utf-8)))

;;; A file named in a store snapshot, verified only when its contents are shown

(defclass snapshot-path ()
  ((root :initarg :root :reader snapshot-path-root)
   (commit :initarg :commit :reader snapshot-path-commit)
   (path :initarg :path :reader snapshot-path-path))
  (:documentation "A path in the /nix/store snapshot of COMMIT at ROOT. Naming it hashes nothing; its Contents view
verifies the snapshot then and reads the file through that verification."))
(defun make-snapshot-path (root commit path) (make-instance 'snapshot-path :root root :commit commit :path path))
(defmethod v:text-representation ((p snapshot-path))
  (format nil "~A at ~A (store snapshot, verified when read)" (snapshot-path-path p) (subseq (snapshot-path-commit p) 0 8)))

;;; Views: what was verified, and how

(v:defview snapshot-verification-view (verification snapshot-verification)
  (v:html-view :title "Source snapshot" :priority -10
    (let ((manifest (verification-manifest verification)))
      (v:html
        (:h2 (v:esc (v:text-representation verification)))
        (:p (v:esc (format nil "Commit ~A, root tree ~A. Verified at ~A (universal time) without .git, from the files at ~A."
                           (manifest-commit manifest) (manifest-root-tree manifest) (verification-finished verification)
                           (namestring (verification-root verification)))))
        (:ul (dolist (check (verification-checks verification)) (v:html (:li (v:esc (string-downcase check))))))
        (:p (v:esc (format nil "~D shipped files hashed. Excluded, neither shipped nor verified: ~{~A~^, ~}."
                           (verification-blob-count verification)
                           (mapcar (lambda (name) (format nil "~A/ (tree ~A)" name (third (find name (manifest-entries manifest) :key #'fourth :test #'string=))))
                                   (manifest-excluded manifest)))))
        (:p (v:esc (format nil "Nix pins the same bytes independently by NAR hash ~A. Git's object ids are SHA-1." (manifest-nar-hash manifest))))
        (:p (v:object-ref manifest :display "The manifest"))))))

(v:defview snapshot-file-view (file snapshot-file)
  (v:html-view :title "Contents" :priority -10
    (v:html
      (:p (v:object-ref (snapshot-file-verification file) :display "From the verified snapshot" :select "Source snapshot"))
      (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc (snapshot-file-contents file))))))

(v:defview snapshot-path-view (path snapshot-path)
  (v:html-view :title "Contents" :priority -10
    (let ((file (make-snapshot-file (verify-store-snapshot (snapshot-path-root path) (snapshot-path-commit path))
                                    (snapshot-path-path path))))
      (v:html
        (:p (v:object-ref (snapshot-file-verification file) :display "Verified now" :select "Source snapshot"))
        (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc (snapshot-file-contents file)))))))
