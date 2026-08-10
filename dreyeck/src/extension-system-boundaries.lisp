;;;; Reusable source-ownership checks for Dreyeck extension systems.

(defpackage #:dreyeck/system-boundaries
  (:use #:cl)
  (:export
   #:*extension-system-boundaries*
   #:check-extension-system-boundary
   #:check-extension-system-boundaries))

(in-package #:dreyeck/system-boundaries)

(defparameter *extension-system-boundaries*
  '((:name :git-commit-inspection
     :definition-file "dreyeck.asd"
     :source-root "dreyeck/src/"
     :test-root "dreyeck/tests/"
     :source-systems ("dreyeck/git"
                      "dreyeck/inspector/git"
                      "dreyeck/extension-system-boundaries")
     :test-systems ("dreyeck/git/tests")
     :required-dependencies
     (("dreyeck/git" "hyperdoc")
      ("dreyeck/inspector/git" "dreyeck/git")
      ("dreyeck/inspector/git" "hyperdoc/inspector")
      ("dreyeck/git/tests" "dreyeck/inspector/git")
      ("dreyeck/git/tests" "dreyeck/extension-system-boundaries"))
     :upstream-systems ("hyperdoc" "hyperdoc/inspector"))
    (:name :fedwiki-navigation-trace
     :definition-file "dreyeck.asd"
     :source-root "dreyeck/src/"
     :test-root "dreyeck/tests/"
     :source-systems ("dreyeck/fedwiki-navigation"
                      "dreyeck/inspector/fedwiki-navigation")
     :test-systems ("dreyeck/fedwiki-navigation/tests")
     :required-dependencies
     (("dreyeck/fedwiki-navigation" "asdf")
      ("dreyeck/fedwiki-navigation" "hyperdoc")
      ("dreyeck/inspector/fedwiki-navigation"
       "dreyeck/fedwiki-navigation")
      ("dreyeck/inspector/fedwiki-navigation" "hyperdoc/inspector")
      ("dreyeck/fedwiki-navigation/tests"
       "dreyeck/inspector/fedwiki-navigation")
      ("dreyeck/fedwiki-navigation/tests"
       "dreyeck/extension-system-boundaries"))
     :upstream-systems ("hyperdoc" "hyperdoc/inspector")))
  "Declarative ownership boundaries for incubating Dreyeck extensions.")

(defun repository-root-for-system (system-designator)
  (uiop:pathname-directory-pathname
   (asdf:system-source-file (asdf:find-system system-designator))))

(defun canonical-namestring (pathname)
  (namestring (truename pathname)))

(defun same-pathname-p (left right)
  (string= (canonical-namestring left)
           (canonical-namestring right)))

(defun pathname-under-directory-p (pathname directory)
  (let ((pathname (canonical-namestring pathname))
        (directory
          (namestring
           (uiop:ensure-directory-pathname
            (truename directory)))))
    (and (<= (length directory) (length pathname))
         (string= directory pathname :end2 (length directory)))))

(defun source-component-pathnames (system-designator)
  (labels ((walk (component)
             (cond
               ((typep component 'asdf:cl-source-file)
                (list (asdf:component-pathname component)))
               (t
                (mapcan #'walk
                        (or (ignore-errors
                              (asdf:component-children component))
                            nil))))))
    (walk (asdf:find-system system-designator))))

(defun direct-dependency-names (system-designator)
  (mapcar #'string-downcase
          (asdf:system-depends-on
           (asdf:find-system system-designator))))

(defun require-boundary (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun check-definition-ownership
    (system-designators expected-definition-file repository-root)
  (let ((expected
          (merge-pathnames expected-definition-file repository-root)))
    (dolist (system-designator system-designators)
      (let ((actual
              (asdf:system-source-file
               (asdf:find-system system-designator))))
        (require-boundary
         (same-pathname-p actual expected)
         "System ~A is defined by ~A instead of ~A."
         system-designator actual expected))))
  t)

(defun check-component-ownership
    (system-designators expected-root repository-root kind)
  (let ((expected-directory
          (merge-pathnames expected-root repository-root))
        (records nil))
    (dolist (system-designator system-designators)
      (let ((pathnames
              (source-component-pathnames system-designator)))
        (require-boundary pathnames
                          "~A system ~A has no Lisp source components."
                          kind system-designator)
        (dolist (pathname pathnames)
          (require-boundary
           (pathname-under-directory-p pathname expected-directory)
           "~A component ~A of ~A is outside ~A."
           kind pathname system-designator expected-directory))
        (push (cons system-designator pathnames) records)))
    (nreverse records)))

(defun check-required-dependencies (requirements)
  (dolist (requirement requirements)
    (destructuring-bind (system dependency) requirement
      (let ((dependencies (direct-dependency-names system)))
        (require-boundary
         (member (string-downcase dependency) dependencies :test #'string=)
         "System ~A lacks required dependency ~A; found ~S."
         system dependency dependencies))))
  t)

(defun check-no-upstream-dreyeck-dependencies (upstream-systems)
  (dolist (system upstream-systems)
    (dolist (dependency (direct-dependency-names system))
      (require-boundary
       (not (uiop:string-prefix-p "dreyeck" dependency))
       "Upstream system ~A depends back on Dreyeck system ~A."
       system dependency)))
  t)

(defun check-extension-system-boundary (boundary)
  "Validate one declarative Dreyeck extension BOUNDARY and return evidence."
  (let* ((source-systems (getf boundary :source-systems))
         (test-systems (getf boundary :test-systems))
         (all-systems (append source-systems test-systems))
         (repository-root
           (repository-root-for-system (first source-systems)))
         (source-components
           (check-component-ownership
            source-systems
            (getf boundary :source-root)
            repository-root
            "Source"))
         (test-components
           (check-component-ownership
            test-systems
            (getf boundary :test-root)
            repository-root
            "Test")))
    (check-definition-ownership
     all-systems
     (getf boundary :definition-file)
     repository-root)
    (check-required-dependencies
     (getf boundary :required-dependencies))
    (check-no-upstream-dreyeck-dependencies
     (getf boundary :upstream-systems))
    (list :name (getf boundary :name)
          :definition-file :dreyeck.asd
          :source-components source-components
          :test-components test-components
          :dependency-direction :dreyeck-to-hyperdoc
          :passed t)))

(defun check-extension-system-boundaries
    (&optional (boundaries *extension-system-boundaries*))
  "Validate BOUNDARIES, making the check extensible by declarative entries."
  (mapcar #'check-extension-system-boundary boundaries))
