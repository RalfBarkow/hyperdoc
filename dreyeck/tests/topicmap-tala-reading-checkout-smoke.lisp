;;;; The TALA reading of the current repository, with and without one.

(in-package #:dreyeck/topicmap/tests)

(defparameter +repository-reading-examples+
  '(dreyeck/inspector/topicmap/tala::reading-workspace
    dreyeck/inspector/topicmap/tala::reading-projection
    dreyeck/inspector/topicmap/tala::reading-topic-identities
    dreyeck/inspector/topicmap/tala::reading-association-endpoints
    dreyeck/inspector/topicmap/tala::reading-layout-input
    dreyeck/inspector/topicmap/tala::reading-id-mapping
    dreyeck/inspector/topicmap/tala::reading-layout-result
    dreyeck/inspector/topicmap/tala::reading-geometry
    dreyeck/inspector/topicmap/tala::reading-invariant-report
    dreyeck/inspector/topicmap/tala::reading-comparison)
  "The examples whose subject is the current repository.")

(defun call-recording-git (function)
  "Call FUNCTION; return its value and the arguments of every Git it ran."
  (let ((original (symbol-function 'uiop:run-program))
        (calls nil))
    (unwind-protect
         (progn
           (setf (symbol-function 'uiop:run-program)
                 (lambda (command &rest arguments)
                   (when (and (consp command) (equal "git" (first command)))
                     (push (rest command) calls))
                   (apply original command arguments)))
           (values (funcall function) (reverse calls)))
      (setf (symbol-function 'uiop:run-program) original))))

(defun call-where-git-finds-no-repository (function)
  "Call FUNCTION while GIT_DIR names no repository, so Git finds none."
  (let ((previous (uiop:getenv "GIT_DIR")))
    (unwind-protect
         (progn
           (setf (uiop:getenv "GIT_DIR")
                 (namestring (merge-pathnames "dreyeck-no-such-git-dir/"
                                              (uiop:temporary-directory))))
           (funcall function))
      (if previous
          (setf (uiop:getenv "GIT_DIR") previous)
          (progn (require :sb-posix)
                 (uiop:symbol-call :sb-posix :unsetenv "GIT_DIR"))))))

(defun call-with-tala-dependency (status function)
  "Call FUNCTION while TALA-DEPENDENCY-STATUS answers STATUS; return its value
and how often the renderer was asked about."
  (let ((original (symbol-function 'dreyeck/topicmap/tala:tala-dependency-status))
        (asked 0))
    (unwind-protect
         (progn
           (setf (symbol-function 'dreyeck/topicmap/tala:tala-dependency-status)
                 (lambda (&rest arguments)
                   (declare (ignore arguments))
                   (incf asked)
                   status))
           (values (funcall function) asked))
      (setf (symbol-function 'dreyeck/topicmap/tala:tala-dependency-status) original))))

(defun hex-run-p (string length)
  (loop for start from 0 to (- (length string) length)
          thereis (loop for index from start below (+ start length)
                        always (digit-char-p (char string index) 16))))

(defun check-claims-no-repository (value)
  "VALUE names no commit, repository or CURRENT-HEAD and holds no object
that stands for one."
  (labels ((walk (part)
             (typecase part
               (cons (walk (car part)) (walk (cdr part)))
               (string
                (dolist (marker '("git-commit:" "git-repository:" "association:current-head:"))
                  (check (not (search marker part))
                         "A no-checkout observation carries the identity ~S." part))
                (check (not (hex-run-p part 40))
                       "A no-checkout observation carries a revision: ~S." part))
               ((or dreyeck/git:git-commit dreyeck/git:git-repository-checkout
                    dreyeck/topicmap:topicmap-topic dreyeck/topicmap:topicmap-association
                    dreyeck/topicmap:topicmap-projection dreyeck/topicmap:topicmap-workspace)
                (check nil "A no-checkout observation holds ~S." part)))))
    (walk value))
  (dolist (key '(:commit :hash :head :revision :repository :topics :associations))
    (check (null (getf value key))
           "A no-checkout observation answers ~S." key)))

(defun check-reading-of-a-live-checkout ()
  "Positive control: in a checkout the reading is the repository projection
the generic path makes, unchanged."
  (let ((checkout (dreyeck/inspector/topicmap/tala::reading-live-checkout)))
    (check (typep checkout 'dreyeck/git:git-repository-checkout)
           "The reading did not find the live checkout: ~S." checkout))
  (let* ((direct (dreyeck/topicmap/tala:projection-tala-input
                  (dreyeck/topicmap:topicmap-projection-of
                   (dreyeck/git:make-current-git-repository-checkout))
                  :seed 44))
         (reading (dreyeck/inspector/topicmap/tala::reading-layout-input)))
    (check (typep reading 'dreyeck/topicmap/tala:tala-input)
           "The reading's layout input is ~S." reading)
    (check (string= (dreyeck/topicmap/tala::tala-input-source direct)
                    (dreyeck/topicmap/tala::tala-input-source reading))
           "The reading's D2 source differs from the repository projection's.")
    (check (equal (dreyeck/topicmap/tala:tala-input-topics direct)
                  (dreyeck/topicmap/tala:tala-input-topics reading))
           "The reading's Topic identities differ.")
    (check (equal (dreyeck/topicmap/tala:tala-input-associations direct)
                  (dreyeck/topicmap/tala:tala-input-associations reading))
           "The reading's Association identities differ.")
    (check (equal '("git-commit:" "git-repository:")
                  (mapcar (lambda (entry)
                            (subseq (getf entry :id) 0 (1+ (position #\: (getf entry :id)))))
                          (dreyeck/topicmap/tala:tala-input-topics reading)))
           "The reading is not of a repository and its commit.")
    (check (every (lambda (entry) (eql 0 (search "association:current-head:" (getf entry :id))))
                  (dreyeck/topicmap/tala:tala-input-associations reading))
           "The reading lost its CURRENT-HEAD association.")
    (when (eq :available (getf (dreyeck/topicmap/tala:tala-dependency-status) :status))
      (let ((result (dreyeck/inspector/topicmap/tala::reading-layout-result)))
        (check (typep result 'dreyeck/topicmap/tala:tala-rendering)
               "A checkout with the renderer gave ~S." result)
        (check (dreyeck/topicmap/tala:validate-tala-svg
                (dreyeck/topicmap/tala:tala-rendering-input result)
                (dreyeck/topicmap/tala:tala-rendering-svg result))
               "The reading's rendering does not validate.")
        (check (string= (dreyeck/topicmap/tala:tala-rendering-svg
                         (dreyeck/topicmap/tala:run-tala direct))
                        (dreyeck/topicmap/tala:tala-rendering-svg result))
               "The reading's SVG differs from the repository projection's.")))))

(defun check-reading-without-a-live-checkout ()
  "No checkout is an observation: of a directory that is not one, and through
every repository example, each asking Git once and nothing further."
  (let ((directory (uiop:ensure-directory-pathname
                    (merge-pathnames (format nil "dreyeck-not-a-checkout-~36R/" (random (expt 36 8)))
                                     (uiop:temporary-directory)))))
    (ensure-directories-exist directory)
    (unwind-protect
         (let ((absence (dreyeck/inspector/topicmap/tala::live-git-checkout-absence directory)))
           (check (dreyeck/inspector/topicmap/tala::no-live-git-checkout-p absence)
                  "A directory that is not a checkout gave ~S." absence)
           (check (string= (namestring directory) (getf absence :examined))
                  "The observation does not name the directory examined.")
           (check (not (eql 0 (getf (getf absence :git) :exit-code)))
                  "The observation does not keep Git's answer.")
           (check (getf absence :requires) "The observation does not say what it requires.")
           (check (getf absence :remedy) "The observation names no remedy.")
           (check-claims-no-repository absence))
      (uiop:delete-empty-directory directory)))
  (call-where-git-finds-no-repository
   (lambda ()
     (dolist (example +repository-reading-examples+)
       (multiple-value-bind (value git)
           (call-recording-git (symbol-function example))
         (check (dreyeck/inspector/topicmap/tala::no-live-git-checkout-p value)
                "~S without a checkout gave ~S." example value)
         (check (equal '(("--no-lazy-fetch" "rev-parse" "--show-toplevel")) git)
                "~S without a checkout ran Git ~S." example git)
         (check-claims-no-repository value))))))

(defun check-no-checkout-is-not-a-missing-renderer ()
  "The two absences stay apart, in what they say and in which is reported."
  (let ((missing-renderer (dreyeck/topicmap/tala:tala-dependency-status
                           :program "d2-that-is-not-installed"))
        (no-checkout (call-where-git-finds-no-repository
                      #'dreyeck/inspector/topicmap/tala::reading-layout-result)))
    (check (eq :unavailable (getf missing-renderer :status))
           "An absent renderer reported ~S." missing-renderer)
    (check (not (dreyeck/inspector/topicmap/tala::no-live-git-checkout-p missing-renderer))
           "An absent renderer reads as a missing checkout.")
    (check (and (eq :no-live-git-checkout (getf no-checkout :kind))
                (null (getf no-checkout :status)))
           "A missing checkout reads as a renderer status: ~S." no-checkout)
    ;; A checkout without the renderer reports the renderer.
    (check (eq missing-renderer
               (call-with-tala-dependency
                missing-renderer #'dreyeck/inspector/topicmap/tala::reading-layout-result))
           "A checkout without the renderer did not report the renderer.")
    ;; Without a checkout the subject comes first; the renderer is not asked.
    (multiple-value-bind (value asked)
        (call-with-tala-dependency
         missing-renderer
         (lambda ()
           (call-where-git-finds-no-repository
            #'dreyeck/inspector/topicmap/tala::reading-layout-result)))
      (check (dreyeck/inspector/topicmap/tala::no-live-git-checkout-p value)
             "Without checkout or renderer the reading gave ~S." value)
      (check (zerop asked) "The renderer was asked about ~D time(s) without a checkout." asked))))

(defun check-tala-needs-no-git ()
  "An explicitly constructed projection lays out without Git."
  (let* ((projection
           (dreyeck/topicmap:make-topicmap-projection
            :source :explicit
            :topics (list (dreyeck/topicmap:make-topicmap-topic
                           :id "explicit:source" :type :explicit :label "source"
                           :view-properties '(:visible t))
                          (dreyeck/topicmap:make-topicmap-topic
                           :id "explicit:target" :type :explicit :label "target"
                           :view-properties '(:visible t)))
            :associations (list (dreyeck/topicmap:make-topicmap-association
                                 :id "association:explicit" :type :relates
                                 :from "explicit:source" :to "explicit:target"))))
         (available (eq :available (getf (dreyeck/topicmap/tala:tala-dependency-status) :status))))
    (multiple-value-bind (result git)
        (call-recording-git
         (lambda ()
           (let ((input (dreyeck/topicmap/tala:projection-tala-input projection :seed 44)))
             (if available (dreyeck/topicmap/tala:run-tala input) input))))
      (check (null git) "An explicit projection ran Git ~S." git)
      (if available
          (check (dreyeck/topicmap/tala:validate-tala-svg
                  (dreyeck/topicmap/tala:tala-rendering-input result)
                  (dreyeck/topicmap/tala:tala-rendering-svg result))
                 "An explicit projection's rendering does not validate.")
          (check (typep result 'dreyeck/topicmap/tala:tala-input)
                 "An explicit projection gave no layout input: ~S." result)))))

(defun run-reading-live-checkout-tests ()
  (check-reading-of-a-live-checkout)
  (check-reading-without-a-live-checkout)
  (check-no-checkout-is-not-a-missing-renderer)
  (check-tala-needs-no-git)
  (format t "TALA reading checkout tests passed: live checkout, none, not a renderer, TALA without Git.~%")
  t)
