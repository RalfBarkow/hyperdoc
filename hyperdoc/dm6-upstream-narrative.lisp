;;; Read-only dm6 upstream narrative inspector.
;;; Generated from the SLY MREPL to materialize topic 968908.

(in-package #:hyperdoc)

(defparameter *dm6-upstream-default-repo* #P"/Users/rgb/workspace/dm6-elm/")

(defun dm6-narrative-trim (string)
  (string-trim '(#\  #\Tab #\Newline #\Return) (or string "")))

(defun dm6-narrative-lines (string)
  (remove-if (lambda (line) (string= "" (dm6-narrative-trim line)))
             (uiop/utility:split-string (or string "") :separator
                                        '(#\Newline #\Return))))

(defun dm6-narrative-tabs (string)
  (uiop/utility:split-string string :separator '(#\Tab)))

(defun dm6-narrative-git-output (repo &rest args)
  "Run git in REPO and return stdout. Intended for read-only git commands."
  (let ((out (make-string-output-stream)))
    (uiop/run-program:run-program (cons "git" args) :directory repo :output out
                                  :error-output t)
    (get-output-stream-string out)))

(defun dm6-narrative-git-output/soft (repo &rest args)
  "Run git in REPO and return stdout/stderr without debugger on non-zero exit.
Useful for grep commands with no matches."
  (let ((out (make-string-output-stream)))
    (uiop/run-program:run-program (cons "git" args) :directory repo :output out
                                  :error-output out :ignore-error-status t)
    (get-output-stream-string out)))

(defun dm6-narrative-rev (repo ref)
  (dm6-narrative-trim (dm6-narrative-git-output repo "rev-parse" ref)))

(defun dm6-narrative-merge-base (repo local upstream)
  (dm6-narrative-trim
   (dm6-narrative-git-output repo "merge-base" local upstream)))

(defun dm6-narrative-dirty-status (repo)
  (dm6-narrative-git-output/soft repo "status" "--short"))

(defun dm6-narrative-ahead-behind (repo local upstream)
  (dm6-narrative-trim
   (dm6-narrative-git-output repo "rev-list" "--left-right" "--count"
    (format nil "~A...~A" local upstream))))

(defclass dm6-commit-story nil
          ((hash :initarg :hash :accessor dm6-commit-hash)
           (author :initarg :author :accessor dm6-commit-author)
           (date :initarg :date :accessor dm6-commit-date)
           (subject :initarg :subject :accessor dm6-commit-subject)
           (files :initarg :files :accessor dm6-commit-files)
           (categories :initarg :categories :accessor dm6-commit-categories)))

(defclass dm6-file-delta nil
          ((path :initarg :path :accessor dm6-file-delta-path)
           (added :initarg :added :accessor dm6-file-delta-added)
           (deleted :initarg :deleted :accessor dm6-file-delta-deleted)
           (categories :initarg :categories :accessor
            dm6-file-delta-categories)))

(defclass dm6-upstream-narrative nil
          ((repo :initarg :repo :accessor dm6-narrative-repo)
           (local :initarg :local :accessor dm6-narrative-local)
           (upstream :initarg :upstream :accessor dm6-narrative-upstream)
           (local-head :initarg :local-head :accessor dm6-narrative-local-head)
           (upstream-head :initarg :upstream-head :accessor
            dm6-narrative-upstream-head)
           (merge-base :initarg :merge-base :accessor
            dm6-narrative-merge-base-ref)
           (ahead-behind :initarg :ahead-behind :accessor
            dm6-narrative-ahead-behind-summary)
           (dirty-status :initarg :dirty-status :accessor
            dm6-narrative-dirty-status-summary)
           (commit-stories :initarg :commit-stories :accessor
            dm6-narrative-commit-stories)
           (file-deltas :initarg :file-deltas :accessor
            dm6-narrative-file-deltas)))

(defun dm6-short-hash (hash)
  (if (and hash (>= (length hash) 8))
      (subseq hash 0 8)
      hash))

(defmethod print-object ((object dm6-upstream-narrative) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A -> ~A base=~A commits=~D files=~D"
            (dm6-narrative-local object) (dm6-narrative-upstream object)
            (dm6-short-hash (dm6-narrative-merge-base-ref object))
            (length (dm6-narrative-commit-stories object))
            (length (dm6-narrative-file-deltas object)))))

(defmethod print-object ((object dm6-commit-story) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A" (dm6-short-hash (dm6-commit-hash object))
            (dm6-commit-subject object))))

(defmethod print-object ((object dm6-file-delta) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "+~A -~A ~A" (or (dm6-file-delta-added object) "?")
            (or (dm6-file-delta-deleted object) "?")
            (dm6-file-delta-path object))))

(defun dm6-path-categories (path)
  (let ((categories nil))
    (labels ((add (category)
               (pushnew category categories)))
      (cond ((search "AppEmbed" path) (add :embed-abi))
            ((search "Storage" path) (add :persistence))
            ((search "TopicMap/Mouse" path) (add :drag-input))
            ((search "Feature/Mouse" path) (add :drag-input))
            ((search "Shared/Events" path) (add :event-plumbing))
            ((search "TopicMap/Controller" path) (add :controller))
            ((search "TopicMap/Geometry" path) (add :geometry))
            ((search "TopicMap/View" path) (add :renderer))
            ((search "TopicList" path) (add :alternate-renderer))
            ((search "Feature/Sel" path) (add :selection))
            ((search "Feature/Search" path) (add :search-selection))
            ((search "Feature/Nav" path) (add :navigation))
            ((search "Feature/Tool" path) (add :tooling))
            ((search "ExtManager" path) (add :extension-seam))
            ((search "Extension" path) (add :extension-seam))
            ((search "Main.elm" path) (add :app-dispatch))
            ((search "Model" path) (add :model))
            ((search "Box" path) (add :containment))
            ((search "Compat" path) (add :compatibility))
            ((search "FedWiki" path) (add :fedwiki-import))))
    (or (nreverse categories) '(:unclassified))))

(defun dm6-union-categories (paths)
  (remove-duplicates
   (loop for path in paths
         append (dm6-path-categories path))
   :test #'eq))

(defun dm6-commit-files-for-hash (repo hash)
  (dm6-narrative-lines
   (dm6-narrative-git-output repo "show" "--name-only" "--format="
    "--no-renames" hash)))

(defun dm6-upstream-commit-stories (repo base upstream)
  (loop for line in (dm6-narrative-lines
                     (dm6-narrative-git-output repo "log" "--reverse"
                      "--date=iso-strict" "--format=%H%x09%an%x09%ad%x09%s"
                      (format nil "~A..~A" base upstream)))
        for parts = (dm6-narrative-tabs line)
        for hash = (first parts)
        for author = (second parts)
        for date = (third parts)
        for subject = (format nil "~{~A~^	~}" (cdddr parts))
        for files = (dm6-commit-files-for-hash repo hash)
        collect (make-instance 'dm6-commit-story :hash hash :author author
                               :date date :subject subject :files files
                               :categories (dm6-union-categories files))))

(defun dm6-parse-numstat-field (value)
  (if (or (null value) (string= value "-"))
      nil
      (parse-integer value :junk-allowed t)))

(defun dm6-upstream-file-deltas (repo base upstream)
  (loop for line in (dm6-narrative-lines
                     (dm6-narrative-git-output repo "diff" "--numstat"
                      (format nil "~A..~A" base upstream)))
        for parts = (dm6-narrative-tabs line)
        for added = (dm6-parse-numstat-field (first parts))
        for deleted = (dm6-parse-numstat-field (second parts))
        for path = (third parts)
        when path
        collect (make-instance 'dm6-file-delta :path path :added added :deleted
                               deleted :categories (dm6-path-categories path))))

(defun make-dm6-upstream-narrative
       (
        &key (repo *dm6-upstream-default-repo*) (local "main")
        (upstream "upstream/master"))
  (let* ((local-head (dm6-narrative-rev repo local))
         (upstream-head (dm6-narrative-rev repo upstream))
         (base (dm6-narrative-merge-base repo local upstream)))
    (make-instance 'dm6-upstream-narrative :repo repo :local local :upstream
                   upstream :local-head local-head :upstream-head upstream-head
                   :merge-base base :ahead-behind
                   (dm6-narrative-ahead-behind repo local upstream)
                   :dirty-status (dm6-narrative-dirty-status repo)
                   :commit-stories
                   (dm6-upstream-commit-stories repo base upstream)
                   :file-deltas (dm6-upstream-file-deltas repo base upstream))))

(defun dm6-category-line (categories) (format nil "~{~A~^, ~}" categories))

(defun dm6-narrative-summary (n)
  (with-output-to-string (out)
    (format out "dm6 upstream narrative~%")
    (format out "======================~%~%")
    (format out "repo:      ~A~%" (dm6-narrative-repo n))
    (format out "local:     ~A  ~A~%" (dm6-narrative-local n)
            (dm6-short-hash (dm6-narrative-local-head n)))
    (format out "upstream:  ~A  ~A~%" (dm6-narrative-upstream n)
            (dm6-short-hash (dm6-narrative-upstream-head n)))
    (format out "base:      ~A~%"
            (dm6-short-hash (dm6-narrative-merge-base-ref n)))
    (format out "ahead/behind: ~A~%" (dm6-narrative-ahead-behind-summary n))
    (format out "upstream commits: ~D~%"
            (length (dm6-narrative-commit-stories n)))
    (format out "changed files:    ~D~%"
            (length (dm6-narrative-file-deltas n)))
    (when
        (plusp
         (length (dm6-narrative-trim (dm6-narrative-dirty-status-summary n))))
      (format out "~%dirty status:~%~A~%"
              (dm6-narrative-dirty-status-summary n)))))

(defun dm6-narrative-commit-story-report (n)
  (with-output-to-string (out)
    (format out "Jörg upstream story, oldest first~%")
    (format out "===============================~%~%")
    (loop for commit in (dm6-narrative-commit-stories n)
          for index from 1
          do (format out "~D. ~A  ~A~%" index
                     (dm6-short-hash (dm6-commit-hash commit))
                     (dm6-commit-subject commit)) (format out "   author: ~A~%"
                                                          (dm6-commit-author
                                                           commit)) (format out
                                                                            "   date:   ~A~%"
                                                                            (dm6-commit-date
                                                                             commit)) (format
                                                                                       out
                                                                                       "   areas:  ~A~%"
                                                                                       (dm6-category-line
                                                                                        (dm6-commit-categories
                                                                                         commit))) (format
                                                                                                    out
                                                                                                    "   files:  ~D~%~%"
                                                                                                    (length
                                                                                                     (dm6-commit-files
                                                                                                      commit))))))

(defun dm6-narrative-file-delta-report (n)
  (with-output-to-string (out)
    (format out "File deltas~%")
    (format out "===========~%~%")
    (loop for delta in (dm6-narrative-file-deltas n)
          do (format out "~A  +~:[?~;~:*~D~] -~:[?~;~:*~D~]  ~A~%"
                     (dm6-category-line (dm6-file-delta-categories delta))
                     (dm6-file-delta-added delta)
                     (dm6-file-delta-deleted delta)
                     (dm6-file-delta-path delta)))))

(defun dm6-narrative-hyperdoc-impact-report (n)
  (let* ((deltas (dm6-narrative-file-deltas n))
         (categories
          (remove-duplicates
           (loop for d in deltas
                 append (dm6-file-delta-categories d))
           :test #'eq)))
    (labels ((touched-p (category)
               (if (member category categories)
                   "yes"
                   "no")))
      (with-output-to-string (out)
        (format out "HyperDoc impact~%")
        (format out "===============~%~%")
        (format out "AppEmbed ABI touched upstream: ~A~%"
                (touched-p :embed-abi))
        (format out "Storage chokepoint touched:    ~A~%"
                (touched-p :persistence))
        (format out "Mouse/drag touched:            ~A~%"
                (touched-p :drag-input))
        (format out "Selection touched:             ~A~%"
                (touched-p :selection))
        (format out "Controller touched:            ~A~%"
                (touched-p :controller))
        (format out "Renderer touched:              ~A~%"
                (touched-p :renderer))
        (format out "~%Recommendation:~%")
        (format out "  Keep AppEmbed as the public ABI.~%")
        (format out
                "  Re-anchor store evidence at Storage.* only after merge.~%")
        (format out
                "  Re-anchor drag/select evidence at the new mouse/selection seams.~%")
        (format out
                "  Define cross-boundary evidence from before/after containment, not message names.~%")))))

(defun dm6-narrative-report (n)
  (with-output-to-string (out)
    (format out "~A~%~%" (dm6-narrative-summary n))
    (format out "~A~%~%" (dm6-narrative-hyperdoc-impact-report n))
    (format out "~A~%~%" (dm6-narrative-commit-story-report n))
    (format out "~A~%" (dm6-narrative-file-delta-report n))))

(defun dm6-narrative-diff-for-file (n file)
  (dm6-narrative-git-output/soft (dm6-narrative-repo n) "diff"
   (format nil "~A..~A" (dm6-narrative-merge-base-ref n)
           (dm6-narrative-upstream n))
   "--" file))

(defun dm6-narrative-show-commit (n commit-hash)
  (dm6-narrative-git-output/soft (dm6-narrative-repo n) "show" "--stat"
   "--patch" commit-hash))

(defun dm6-narrative-grep-upstream (n pattern)
  (let ((result
         (dm6-narrative-git-output/soft (dm6-narrative-repo n) "grep" "-n"
          pattern (dm6-narrative-upstream n))))
    (if (plusp (length (dm6-narrative-trim result)))
        result
        (format nil "No upstream matches for ~S in ~A.~%" pattern
                (dm6-narrative-upstream n)))))

(defun inspect-dm6-upstream-narrative!
       (
        &key (repo *dm6-upstream-default-repo*) (local "main")
        (upstream "upstream/master"))
  (let ((narrative
         (make-dm6-upstream-narrative :repo repo :local local :upstream
                                      upstream)))
    (let* ((pkg (find-package :clog-moldable-inspector))
           (sym (and pkg (find-symbol "CLOG-INSPECT" pkg))))
      (when (and sym (fboundp sym)) (funcall sym :object narrative)))
    narrative))

