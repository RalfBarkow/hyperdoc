;;;; The Four Proposed Commits
(in-package #:topic-maps-integration-review)

;;; Four boundaries, each independently explainable. Their file sets are part of this reading, not read from Git: the reading's tests
;;; compare them with the paths the working tree changes, so a path no boundary names, or two boundaries claiming one, is found.
;;; Nothing here commits anything. The source identity of a boundary is the Git blob id (and SHA-256) of each of its files, asked
;;; when it is shown.

(defun repository-root () (asdf:system-source-directory "dreyeck"))
(defun repository-path (relative) (merge-pathnames relative (repository-root)))

(defclass repository-file ()
  ((path :initarg :path :reader repository-file-path))
  (:documentation "A file of HyperDoc's source, shown as the working tree holds it when asked."))
(defmethod v:text-representation ((f repository-file)) (repository-file-path f))
(defun file-line (relative) (make-instance 'repository-file :path relative))
(v:defview repository-file-view (file repository-file)
  (v:html-view :title "File" :priority -10
    (let* ((path (repository-file-path file)) (pathname (repository-path path)))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 (v:esc path))
         (if (probe-file pathname)
             (let* ((text (uiop:read-file-string pathname :external-format :utf-8)) (lines (uiop:split-string text :separator '(#\Newline))))
               (v:html (:p (v:esc (format nil "~D lines, ~D characters, read from the working tree now." (length lines) (length text))))
                       (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere;max-height:34em;overflow:auto" (v:esc text))))
             (v:html (:p "Missing from the working tree.")))
         (reading-links))))))

(defclass commit-boundary ()
  ((id :initarg :id :reader boundary-id)
   (title :initarg :title :reader boundary-title)
   (subject :initarg :subject :reader boundary-subject :documentation "The proposed subject line of the commit.")
   (purpose :initarg :purpose :reader boundary-purpose)
   (files :initarg :files :reader boundary-files :documentation "Paths committed whole.")
   (directory :initarg :directory :initform nil :reader boundary-directory :documentation "A directory of the repository committed whole, every file under it.")
   (hunks :initarg :hunks :initform nil :reader boundary-hunks :documentation "(path . what) for a path committed in part, by hunk.")
   (depends-on :initarg :depends-on :initform nil :reader boundary-depends-on)
   (tests :initarg :tests :reader boundary-tests :documentation "Strings and objects: the checks that show it holds at this commit.")
   (definitions :initarg :definitions :initform nil :reader boundary-definitions :documentation "The Lisp definitions it changes or relies on.")))
(defmethod v:text-representation ((b commit-boundary)) (format nil "Boundary ~A: ~A" (boundary-id b) (boundary-title b)))

(defparameter +earlier-review+ "dreyeck/work/topic-maps-deployment-review/")

(defvar *boundaries* nil)
(defun boundaries ()
  (or *boundaries*
      (setf *boundaries*
            (list
             (make-instance 'commit-boundary :id "1" :title "Topic Maps 6162ed68: pins, snapshot, and the earlier review's version-bound contract"
               :subject "Pin Topic Maps 6162ed68: snapshot manifest, pins and the earlier review's version-bound contract"
               :purpose "Move the one Topic Maps commit the packaged Catalog, the 22U reading and the CTM review name from b2eecffa to 6162ed68, with the snapshot that pins it. The earlier deployment review, whose contract compared the working tree with its 73 declared paths, is bound to the commit where its candidate is complete so that later work cannot break it or pass as it."
               :files (list "nix/topic-maps-6162ed68.manifest" "nix/topic-maps-source.nix" "dreyeck/work/topic-maps-project-example.lisp"
                            "dreyeck/tests/source-snapshot.lisp"
                            (concatenate 'string +earlier-review+ "code/candidate.lisp") (concatenate 'string +earlier-review+ "code/package.lisp")
                            (concatenate 'string +earlier-review+ "tests/review.lisp") (concatenate 'string +earlier-review+ "pages/Keeping the Project Workspace Out.html")
                            (concatenate 'string +earlier-review+ "asdf-collision/evidence/project-workspace-pin-at-8e64e718.lisp")
                            (concatenate 'string +earlier-review+ "asdf-collision/topic-maps-deployment-review-asdf-collision.asd"))
               :hunks '(("dreyeck.asd" . "the 6162ed68 manifest as a static file of dreyeck/source-snapshot")
                        ("dreyeck/src/catalog-topic-maps.lisp" . "+topic-maps-commit+ only"))
               :depends-on nil
               :tests (list "dreyeck/source-snapshot: 34 assertions on the Git-free snapshot" "22U reading: 41" "CTM review: 58"
                            "earlier deployment review, main suite: 344 assertions with 12 new controls (its second procedure fails as it did at 8e64e718)"
                            "Nix: checks.x86_64-darwin.catalog-topic-maps")
               :definitions (list #'snap:verify-store-snapshot #'c:topic-maps-origins #'topic-maps-deployment-review::declared-paths-agree-p
                                  #'topic-maps-deployment-review::tested-files-match-at-p #'topic-maps-deployment-review::protected-paths-drift))
             (make-instance 'commit-boundary :id "2" :title "The Project Workspace on 6162ed68"
               :subject "Bind the Project Workspace to Topic Maps 6162ed68 and identify a Git-free snapshot"
               :purpose "Bind the Project Workspace to the same commit, teach its source identity to tell a Git checkout, a verified Git-free snapshot and an unidentifiable directory apart, keep the Catalog's startup guard (only its message changes), and extend the browser test with the pin, the identity of a page object across two routes and the absent acceptance record."
               :files '("dreyeck/work/project/project-workspace.lisp" "dreyeck/work/project/project-ctm.lisp" "dreyeck/tests/project-ctm.lisp"
                        "scripts/run-project-workspace-integration.lisp" "scripts/test-project-workspace.mjs"
                        "dreyeck/tests/catalog-topic-maps.lisp" "tests/test_catalog_topic_maps_executable.py")
               :hunks '(("dreyeck.asd" . "dreyeck/work/project depends on dreyeck/source-snapshot")
                        ("dreyeck/src/catalog-topic-maps.lisp" . "the refusal's wording"))
               :depends-on '("1")
               :tests (list "Project suite on a Git checkout: 265 + 186 + 125 checks" "scripts/run-project-workspace-integration.lisp on a checkout and on the snapshot"
                            "scripts/test-project-workspace.mjs in a fresh process" "the same snapshot suites as boundary 1" "Nix: checks.x86_64-darwin.catalog-topic-maps")
               :definitions (list #'p::topic-maps-source-identity #'p::pinned-state-p #'c:refuse-project-workspace #'c:verify-startup))
             (make-instance 'commit-boundary :id "3" :title "This reading"
               :subject "Add the reading of the Topic Maps 6162ed68 integration"
               :purpose "The HyperDoc reading that lets a human follow the integration to the changed definitions, the independent evidence, the recorded runs and the project objects. It has its own .asd and changes no system of dreyeck.asd."
               :files nil :directory "dreyeck/work/topic-maps-integration-review/"
               :hunks nil :depends-on '("1" "2")
               :tests (list "topic-maps-integration-review/tests" "served on loopback and navigated in a browser")
               :definitions (list #'identify-topic-maps-source-now #'ask-whether-project-workspace-is-refused))
             (make-instance 'commit-boundary :id "4" :title "The integration record and the staging procedure"
               :subject "Document the Topic Maps 6162ed68 integration, its limits and the proposed staging procedure"
               :purpose "The prose record: the phases, the evidence, what is not verified, the commit boundaries and their rehearsal, and the staging procedure that stops before any server change."
               :files nil :directory "docs/topic-maps-6162ed68-integration/" :depends-on '("1" "2" "3")
               :tests (list "its links and its numbers are those of the records the reading checks") :definitions nil)))))
(defun boundary-present-p (boundary)
  "Whether BOUNDARY's files are in the tree. Boundary 4 (the documentation) comes after the reading, so at boundary 3 it is not there yet."
  (and (every (lambda (path) (probe-file (repository-path path))) (boundary-files boundary))
       (or (null (boundary-directory boundary)) (and (probe-file (repository-path (boundary-directory boundary))) t))))
(defun boundary (id) (or (find id (boundaries) :key #'boundary-id :test #'string=) (error "No boundary ~S." id)))

(defun directory-files-recursive-in (directory)
  (let ((files (uiop:directory-files directory)))
    (append files (loop for sub in (uiop:subdirectories directory) append (directory-files-recursive-in sub)))))
(defun boundary-all-files (boundary)
  "The files of BOUNDARY as paths relative to the repository: those committed whole, every file under its directory, and the paths split by hunk."
  (append (remove-duplicates
           (append (boundary-files boundary)
                   (and (boundary-directory boundary)
                        (loop for path in (directory-files-recursive-in (repository-path (boundary-directory boundary)))
                              collect (enough-namestring path (repository-root)))))
           :test #'string=)
          (mapcar #'car (boundary-hunks boundary))))
(defun boundary-file-identity (path)
  "(blob-id sha256) of PATH's bytes in the working tree now, or NIL if it is missing."
  (let ((pathname (repository-path path)))
    (and (probe-file pathname)
         (let ((octets (with-open-file (in pathname :element-type '(unsigned-byte 8))
                         (let ((data (make-array (file-length in) :element-type '(unsigned-byte 8)))) (read-sequence data in) data))))
           (list (snap:git-object-id "blob" octets) (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 octets)))))))

(v:defview commit-boundary-view (boundary commit-boundary)
  (v:html-view :title "Boundary" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (format nil "Boundary ~A: ~A" (boundary-id boundary) (boundary-title boundary))))
       (:p (:strong "Proposed subject line: ") (:code (v:esc (boundary-subject boundary))))
       (:p (v:esc (boundary-purpose boundary)))
       (:p (:strong "Depends on: ")
           (if (boundary-depends-on boundary)
               (dolist (id (boundary-depends-on boundary)) (v:html (v:object-ref (boundary id) :select "Boundary" :display (format nil "boundary ~A" id)) " "))
               (v:esc "nothing earlier: it applies to 8e64e718 as it is")))
       (:h3 "Relevant tests")
       (:ul (dolist (test (boundary-tests boundary)) (v:html (:li (v:esc test)))))
       (:h3 "The Lisp definitions it changes or relies on")
       (if (boundary-definitions boundary)
           (v:html (:ul (dolist (d (boundary-definitions boundary)) (v:html (:li (v:object-ref d :select "Source code"))))))
           (v:html (:p "None: it holds no code.")))
       (:h3 "Source identity: its files as the working tree holds them now")
       (:p "Git blob id and SHA-256 of each file's bytes, asked when this view is shown; a file committed by hunk is listed with its hunk, and its identity is that of the whole final file.")
       (:table :class "inspector-table"
        (:tr (:th "File") (:th "Committed") (:th "Git blob id") (:th "SHA-256"))
        (dolist (path (boundary-all-files boundary))
          (let ((hunk (cdr (assoc path (boundary-hunks boundary) :test #'string=))) (identity (boundary-file-identity path)))
            (v:html (:tr (:td (:code (v:esc path))) (:td (v:esc (if hunk (format nil "by hunk: ~A" hunk) "whole")))
                         (:td (:code (v:esc (or (first identity) "missing")))) (:td (:code (v:esc (if identity (subseq (second identity) 0 16) "missing")))))))))
       (:p "The rehearsal of boundaries 1 and 2 (committed in a scratch clone, tested at each commit): "
           (v:object-ref (record "phase-d-boundary-rehearsal.txt") :select "Record" :display "the record") ".")
       (reading-links)))))
