;;;; Revisions, Sources and the Nix Package

(defpackage #:dreyeck/traverse
  (:use #:cl)
  (:local-nicknames (#:tm #:dreyeck/topicmap)
                    (#:v #:html-inspector-views)
                    (#:n #:dreyeck/nested-actions)
                    (#:git #:dreyeck/git))
  (:export #:+book-id+ #:companion-page
           #:companion-reading #:retained-reading
           #:reading-manifest #:reading-revisions #:reading-sources #:reading-records
           #:traverse-source #:source-reading #:source-key #:source-by-key #:revision-of
           #:companion-record #:record-file #:record-kind #:record-phase #:record-origin
           #:record-sha256 #:record-value #:record-of
           #:package-chain
           #:traverse-entry
           #:example-run #:run-record #:run-stages #:example-stage #:stage-name #:stage-value
           #:stage-source #:stage-status #:stage-note #:stage-of #:two-page-example
           #:deployment-evidence
           #:source-projection #:dataflow-projection #:companion-workspace #:switch-projection))

(in-package #:dreyeck/traverse)

(hyperdoc:see
  (hyperdoc:page "From Git Revision to Nix Package" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "How TRAVERSE Enters Mech" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "From PageFold to Discourse Graph" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "What the Deployment Proves" :hyperbook "dreyeck/traverse/reading"))

(defparameter +book-id+ "dreyeck/traverse/reading")

(defun evidence-path (name)
  (asdf:system-relative-pathname "dreyeck/traverse/reading"
                                 (concatenate 'string "dreyeck/traverse/evidence/" name)))

(defun read-json (name)
  (with-open-file (in (evidence-path name) :external-format :utf-8)
    (shasht:read-json* :stream in :single-value t :object-format :hash-table
                       :hash-table-test 'equal :array-format :vector
                       :true-value t :false-value nil :null-value nil)))

(defun file-digest (path)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))

(defun text-digest (text)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence :sha256 (babel:string-to-octets text :encoding :utf-8))))

(defun companion-page (title)
  (hyperbook:find-page +book-id+ title :signal-error? t))

;;; The reading: revisions, source definitions and records, all read from retained bytes.

(defclass companion-reading ()
  ((manifest :initarg :manifest :reader reading-manifest)
   (revisions :initarg :revisions :reader reading-revisions
              :documentation "Alist of role name and Git revision reference (authority plus full OID).")
   (sources :initform nil :accessor reading-sources)
   (records :initform nil :accessor reading-records))
  (:documentation "Retained sources at fixed revisions and the records about them. Reading it runs nothing."))

(defclass traverse-source (n:message-source)
  ((reading :initarg :reading :reader source-reading))
  (:documentation "One definition excerpt of a file retained byte for byte from a fixed revision."))

(defun source-key (source) (gethash "key" (n:source-metadata source)))

(defclass companion-record ()
  ((file :initarg :file :reader record-file)
   (kind :initarg :kind :reader record-kind)
   (phase :initarg :phase :reader record-phase
          :documentation ":before-deployment, :after-deployment or :local-execution.")
   (origin :initarg :origin :reader record-origin)
   (sha256 :initarg :sha256 :reader record-sha256)
   (value :initarg :value :reader record-value))
  (:documentation "A retained record. Its phase says when it was made relative to the deployment."))

(defun source-by-key (reading key)
  (or (find key (reading-sources reading) :key #'source-key :test #'equal)
      (error "No retained TRAVERSE source ~S" key)))

(defun revision-of (reading role)
  (or (cdr (assoc role (reading-revisions reading) :test #'equal))
      (error "No revision for role ~S" role)))

(defun record-of (reading file)
  (or (find file (reading-records reading) :key #'record-file :test #'equal)
      (error "No retained record ~S" file)))

(defun phase-keyword (string)
  (cond ((equal string "before-deployment") :before-deployment)
        ((equal string "after-deployment") :after-deployment)
        ((equal string "local-execution") :local-execution)
        (t :provenance)))

(defun load-reading ()
  (let* ((manifest (read-json "sources.json"))
         (revisions
           (loop for role being the hash-keys of (gethash "revisions" manifest)
                   using (hash-value entry)
                 collect (cons role (git:make-git-revision-reference
                                     :authority (gethash "authority" entry)
                                     :oid (gethash "oid" entry)
                                     :role (intern (string-upcase role) :keyword)
                                     :web-url (format nil "~A/commit/~A" (gethash "authority" entry)
                                                      (gethash "oid" entry))))))
         (reading (make-instance 'companion-reading :manifest manifest
                                                    :revisions (sort revisions #'string< :key #'car))))
    (loop for entry across (gethash "files" manifest)
          do (unless (equal (file-digest (evidence-path (gethash "file" entry))) (gethash "sha256" entry))
               (error "Retained file differs from its recorded SHA-256: ~A" (gethash "file" entry))))
    (setf (reading-sources reading)
          (loop for metadata across (gethash "sources" manifest)
                for text = (uiop:read-file-string (evidence-path (gethash "file" metadata))
                                                  :external-format :utf-8)
                for excerpt = (subseq text (gethash "start" metadata) (gethash "end" metadata))
                for revision = (or (find (gethash "revision" metadata) (mapcar #'cdr revisions)
                                         :key #'git:git-commit-hash-of :test #'equal)
                                   (error "Unrecorded revision ~A" (gethash "revision" metadata)))
                for file = (git:ensure-git-evidence-file revision (gethash "path" metadata))
                do (unless (equal (text-digest excerpt) (gethash "sha256" metadata))
                     (error "Definition excerpt differs from its coordinates: ~A" (gethash "key" metadata)))
                collect (let ((source (make-instance 'traverse-source
                                                     :reading reading :metadata metadata
                                                     :file (evidence-path (gethash "file" metadata))
                                                     :text excerpt :definition (gethash "definition" metadata)
                                                     :revision revision :revision-file file)))
                          (git:add-git-evidence-location file source)
                          source)))
    (setf (reading-records reading)
          (loop for entry across (gethash "records" manifest)
                for name = (gethash "file" entry)
                do (unless (equal (file-digest (evidence-path name)) (gethash "sha256" entry))
                     (error "Retained record differs from its recorded SHA-256: ~A" name))
                collect (make-instance 'companion-record
                                       :file name :kind (gethash "kind" entry)
                                       :phase (phase-keyword (gethash "phase" entry))
                                       :origin (gethash "origin" entry) :sha256 (gethash "sha256" entry)
                                       :value (if (search ".json" name)
                                                  (read-json name)
                                                  (uiop:read-file-string (evidence-path name)
                                                                         :external-format :utf-8)))))
    ;; The consumer acceptance record is a file of the deployment branch itself, retained from Git.
    (push (make-instance 'companion-record
                         :file "dreyeck/mech-profile-consumer-acceptance-traverse.json"
                         :kind "consumer-acceptance" :phase :before-deployment
                         :origin "RalfBarkow/wiki 916ea5bf docs/mech-profile-consumer-acceptance-traverse.json"
                         :sha256 (file-digest (evidence-path "dreyeck/mech-profile-consumer-acceptance-traverse.json"))
                         :value (read-json "dreyeck/mech-profile-consumer-acceptance-traverse.json"))
          (reading-records reading))
    (check-pins reading)
    reading))

(defun check-pins (reading)
  "The retained sources must name each other's fixed revisions; a mismatch is a load error, not a view."
  (let ((composition (git:git-commit-hash-of (revision-of reading "composition")))
        (module (git:git-commit-hash-of (revision-of reading "module"))))
    (unless (search composition (n:source-text (source-by-key reading "dreyeck:mech-composition-input")))
      (error "flake.nix does not name the composition revision"))
    (unless (search composition (n:source-text (source-by-key reading "dreyeck:lock-node")))
      (error "flake.lock does not lock the composition revision"))
    (unless (search module (n:source-text (source-by-key reading "composition:pins-module")))
      (error "mech-pins.json does not name the module revision"))
    reading))

(defvar *reading* nil)

(hyperdoc:defexample retained-reading
  "Read and verify the retained sources and records once per image; nothing is built, fetched or run."
  (or *reading* (setf *reading* (load-reading))))

(hyperdoc:defexample package-chain
  "The chain from the deployment branch to the evaluated package, as retained sources and one record."
  (let* ((reading (retained-reading))
         (acceptance (record-value (record-of reading "dreyeck/mech-profile-consumer-acceptance-traverse.json")))
         (linux (gethash "x86_64-linux" acceptance)))
    (list :deployment-branch (revision-of reading "dreyeck")
          :flake-input (source-by-key reading "dreyeck:mech-composition-input")
          :lock-node (source-by-key reading "dreyeck:lock-node")
          :profile-packages (source-by-key reading "dreyeck:profile-packages")
          :with-mech (source-by-key reading "dreyeck:with-mech")
          :composition (revision-of reading "composition")
          :wiki-profile (source-by-key reading "composition:wiki-profile")
          :mech-nix (source-by-key reading "composition:mech-nix")
          :digest-checks (source-by-key reading "composition:mech-build-checks")
          :module-pin (source-by-key reading "composition:pins-module")
          :module-identity (source-by-key reading "composition:moduleIdentity")
          :module (revision-of reading "module")
          :evaluated-wiki-discourse (gethash "wiki-discourse" linux)
          :evaluated-not-built (gethash "evaluatedNotBuilt" linux)
          :bundle (gethash "mech-discourse client/mech.js" (gethash "bundles" acceptance)))))

;;; Views

(defmethod v:text-representation ((reading companion-reading))
  "TRAVERSE companion: retained sources at fixed revisions and their records")

(defmethod v:text-representation ((source traverse-source))
  (format nil "~A — ~A" (n:source-definition source) (gethash "path" (n:source-metadata source))))

(defmethod v:text-representation ((record companion-record))
  (format nil "~A (~(~A~))" (record-file record) (record-phase record)))

(defun reading-links ()
  (v:html
    (:p "Readings: "
        (v:object-ref (companion-page "From Git Revision to Nix Package") :select "Content" :display "Git to Nix")
        " · " (v:object-ref (companion-page "How TRAVERSE Enters Mech") :select "Content" :display "Entry")
        " · " (v:object-ref (companion-page "From PageFold to Discourse Graph") :select "Content" :display "Dataflow")
        " · " (v:object-ref (companion-page "What the Deployment Proves") :select "Content" :display "Deployment"))))

(v:defview traverse-source-view (source traverse-source)
  (v:html-view :title "Source definition" :priority 0
    (let ((metadata (n:source-metadata source)))
      (v:html
        (:h3 (cl-who:esc (n:source-definition source)))
        (:p (cl-who:esc (gethash "authority" metadata)) " · "
            (:code (cl-who:esc (gethash "path" metadata))) " · characters "
            (cl-who:esc (princ-to-string (gethash "start" metadata))) "–"
            (cl-who:esc (princ-to-string (gethash "end" metadata))))
        (:p (v:object-ref (n:source-revision source) :select "Evidence revision" :display "Repository-qualified full revision")
            " · " (v:object-ref (n:source-revision-file source) :select "Evidence locations" :display "File at revision and definitions")
            " · " (v:object-ref metadata :display "Coordinates and digests"))
        (:pre (cl-who:esc (n:source-text source)))
        (reading-links)))))

(v:defview companion-record-view (record companion-record)
  (v:html-view :title "Record" :priority 0
    (v:html
      (:h3 (cl-who:esc (record-file record)))
      (:p (:strong "Phase: ") (cl-who:esc (string-downcase (record-phase record)))
          " · " (:strong "Kind: ") (cl-who:esc (record-kind record)))
      (:p (:strong "Origin: ") (cl-who:esc (record-origin record)))
      (:p (:strong "SHA-256: ") (:code (cl-who:esc (record-sha256 record))))
      (if (stringp (record-value record))
          (v:html (:pre (cl-who:esc (record-value record))))
          (v:html (:p (v:object-ref (record-value record) :display "Inspect the parsed record"))))
      (reading-links))))

(v:defview companion-reading-view (reading companion-reading)
  (v:html-view :title "Companion" :priority 0
    (v:html
      (:p "Everything here is read from retained bytes whose SHA-256 was checked on load. Nothing is built, fetched or run.")
      (:h4 "Revisions")
      (:ul (dolist (entry (reading-revisions reading))
             (v:html (:li (cl-who:esc (car entry)) " "
                          (v:object-ref (cdr entry) :select "Evidence revision")))))
      (:h4 "Source definitions")
      (:ul (dolist (source (reading-sources reading))
             (v:html (:li (v:object-ref source :select "Source definition" :display (source-key source))))))
      (:h4 "Records")
      (:ul (dolist (record (reading-records reading))
             (v:html (:li (v:object-ref record :select "Record")))))
      (reading-links))))
