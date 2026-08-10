;;;; Source-backed execution traces for the FedWiki navigation prototype.

(in-package #:dreyeck/fedwiki-navigation/prototype)

(defstruct (navigation-position
             (:constructor make-navigation-position
                 (&key origin lineup-slugs current-page-slug
                       current-page-title current-item-id
                       current-item-number current-item-text location)))
  (origin "" :type string :read-only t)
  (lineup-slugs nil :type list :read-only t)
  (current-page-slug "" :type string :read-only t)
  (current-page-title "" :type string :read-only t)
  (current-item-id "" :type string :read-only t)
  (current-item-number 0 :type integer :read-only t)
  (current-item-text "" :type string :read-only t)
  (location "" :type string :read-only t))

(defstruct (navigation-link-observation
             (:constructor make-navigation-link-observation
                 (&key link-text link-slug source-location target-location)))
  (link-text "" :type string :read-only t)
  (link-slug "" :type string :read-only t)
  (source-location "" :type string :read-only t)
  (target-location "" :type string :read-only t))

(defstruct (navigation-source-reference
             (:constructor %make-navigation-source-reference
                 (&key producer-symbol system-name component-name)))
  (producer-symbol nil :type symbol :read-only t)
  (system-name nil :type symbol :read-only t)
  (component-name "" :type string :read-only t))

(defstruct (navigation-source-file
             (:constructor make-navigation-source-file
                 (&key component pathname relative-pathname)))
  component
  (pathname #P"" :type pathname :read-only t)
  (relative-pathname #P"" :type pathname :read-only t))

(defstruct (navigation-step
             (:constructor make-navigation-step
                 (&key number command-text operation arguments before
                       producer-symbol outcome after link-observation
                       implementation dispatcher-implementation)))
  (number 0 :type integer :read-only t)
  (command-text "" :type string :read-only t)
  (operation nil :type symbol :read-only t)
  (arguments nil :type list :read-only t)
  (before nil :type navigation-position :read-only t)
  (producer-symbol nil :type symbol :read-only t)
  outcome
  (after nil :type navigation-position :read-only t)
  (link-observation nil
                    :type (or null navigation-link-observation)
                    :read-only t)
  (implementation nil :type navigation-source-reference :read-only t)
  (dispatcher-implementation nil
                             :type navigation-source-reference
                             :read-only t))

(defstruct (navigation-trace
             (:constructor make-navigation-trace
                 (&key initial-session commands steps final-session result)))
  (initial-session nil :type navigation-position :read-only t)
  (commands nil :type list :read-only t)
  (steps nil :type list :read-only t)
  (final-session nil :type navigation-position :read-only t)
  (result nil :type symbol :read-only t))

(defstruct (navigation-trace-command
             (:constructor make-navigation-trace-command
                 (&key text executor-command operation arguments
                       producer-component)))
  (text "" :type string :read-only t)
  executor-command
  (operation nil :type symbol :read-only t)
  (arguments nil :type list :read-only t)
  (producer-component "" :type string :read-only t))

;; Public readers use the repository's established -OF naming convention.
(defun navigation-trace-initial-session-of (trace)
  (navigation-trace-initial-session trace))

(defun navigation-trace-commands-of (trace)
  (navigation-trace-commands trace))

(defun navigation-trace-steps-of (trace)
  (navigation-trace-steps trace))

(defun navigation-trace-final-session-of (trace)
  (navigation-trace-final-session trace))

(defun navigation-trace-result-of (trace)
  (navigation-trace-result trace))

(defun navigation-step-number-of (step)
  (navigation-step-number step))

(defun navigation-step-command-text-of (step)
  (navigation-step-command-text step))

(defun navigation-step-operation-of (step)
  (navigation-step-operation step))

(defun navigation-step-arguments-of (step)
  (navigation-step-arguments step))

(defun navigation-step-before-of (step)
  (navigation-step-before step))

(defun navigation-step-producer-symbol-of (step)
  (navigation-step-producer-symbol step))

(defun navigation-step-outcome-of (step)
  (navigation-step-outcome step))

(defun navigation-step-after-of (step)
  (navigation-step-after step))

(defun navigation-step-link-observation-of (step)
  (navigation-step-link-observation step))

(defun navigation-step-implementation-of (step)
  (navigation-step-implementation step))

(defun navigation-step-dispatcher-implementation-of (step)
  (navigation-step-dispatcher-implementation step))

(defun navigation-position-current-page-slug-of (position)
  (navigation-position-current-page-slug position))

(defun navigation-position-current-item-id-of (position)
  (navigation-position-current-item-id position))

(defun navigation-position-location-of (position)
  (navigation-position-location position))

(defun navigation-link-observation-link-slug-of (observation)
  (navigation-link-observation-link-slug observation))

(defun navigation-link-observation-source-location-of (observation)
  (navigation-link-observation-source-location observation))

(defun navigation-link-observation-target-location-of (observation)
  (navigation-link-observation-target-location observation))

(defun navigation-source-reference-producer-symbol-of (reference)
  (navigation-source-reference-producer-symbol reference))

(defun navigation-source-reference-system-name-of (reference)
  (navigation-source-reference-system-name reference))

(defun navigation-source-reference-component-name-of (reference)
  (navigation-source-reference-component-name reference))

(defun navigation-source-file-component-of (source-file)
  (navigation-source-file-component source-file))

(defun navigation-source-file-pathname-of (source-file)
  (navigation-source-file-pathname source-file))

(defun navigation-source-file-relative-pathname-of (source-file)
  (navigation-source-file-relative-pathname source-file))

(defparameter *fedwiki-java-navigation-trace-commands*
  (list
   (make-navigation-trace-command
    :text "case find pages we share"
    :executor-command '(:case "find pages we share")
    :operation 'record-navigation-case
    :arguments '("find pages we share")
    :producer-component "fedwiki-navigation")
   (make-navigation-trace-command
    :text "find share"
    :executor-command '(:find-next "share")
    :operation 'find-next
    :arguments '("share")
    :producer-component "fedwiki-navigation")
   (make-navigation-trace-command
    :text "next"
    :executor-command :move-next
    :operation 'move-next
    :arguments nil
    :producer-component "fedwiki-navigation")
   (make-navigation-trace-command
    :text "link"
    :executor-command :follow-link
    :operation 'follow-link
    :arguments nil
    :producer-component "fedwiki-navigation")
   (make-navigation-trace-command
    :text "find 2020"
    :executor-command '(:find-next "2020")
    :operation 'find-next
    :arguments '("2020")
    :producer-component "fedwiki-navigation")
   (make-navigation-trace-command
    :text "link"
    :executor-command :follow-link
    :operation 'follow-link
    :arguments nil
    :producer-component "fedwiki-navigation")
   (make-navigation-trace-command
    :text "test experience"
    :executor-command '(:test "experience")
    :operation 'assert-current-item
    :arguments '("experience")
    :producer-component "fedwiki-navigation")))

(defun copy-navigation-string (string)
  (copy-seq string))

(defun navigation-position-from-session (session)
  "Return a value snapshot with no mutable SESSION lists or strings shared."
  (let* ((panel (session-current-panel session))
         (page (navigation-panel-page panel))
         (item (session-current-item session)))
    (make-navigation-position
     :origin (copy-navigation-string (navigation-session-origin session))
     :lineup-slugs
     (mapcar
      (lambda (lineup-panel)
        (copy-navigation-string
         (navigation-page-slug (navigation-panel-page lineup-panel))))
      (navigation-session-lineup session))
     :current-page-slug
     (copy-navigation-string (navigation-page-slug page))
     :current-page-title
     (copy-navigation-string (navigation-page-title page))
     :current-item-id
     (copy-navigation-string (navigation-item-id item))
     :current-item-number (navigation-panel-item-number panel)
     :current-item-text
     (copy-navigation-string (navigation-item-text item))
     :location (copy-navigation-string (session-location session)))))

(defun make-navigation-source-reference
    (producer-symbol component-name)
  (check-type producer-symbol symbol)
  (unless (fboundp producer-symbol)
    (error "Navigation producer ~S is not function-bound." producer-symbol))
  (let* ((reference
           (%make-navigation-source-reference
            :producer-symbol producer-symbol
            :system-name :dreyeck/fedwiki-navigation
            :component-name component-name))
         (component (navigation-source-reference-component reference)))
    (unless (typep component 'asdf:cl-source-file)
      (error "Navigation source component ~S is not a Lisp source file."
             component-name))
    reference))

(defun navigation-source-reference-system (reference)
  (asdf:find-system
   (navigation-source-reference-system-name-of reference)))

(defun navigation-source-reference-component (reference)
  (or (asdf:find-component
       (navigation-source-reference-system reference)
       (navigation-source-reference-component-name-of reference))
      (error "No ASDF component ~S in system ~S."
             (navigation-source-reference-component-name-of reference)
             (navigation-source-reference-system-name-of reference))))

(defun navigation-source-reference-relative-pathname (reference)
  (let* ((system (navigation-source-reference-system reference))
         (repository-root
           (uiop:pathname-directory-pathname
            (asdf:system-source-file system)))
         (pathname
           (asdf:component-pathname
            (navigation-source-reference-component reference))))
    (pathname (enough-namestring pathname repository-root))))

(defun navigation-source-reference-source-file (reference)
  (let ((component (navigation-source-reference-component reference)))
    (make-navigation-source-file
     :component component
     :pathname (asdf:component-pathname component)
     :relative-pathname
     (navigation-source-reference-relative-pathname reference))))

(defun navigation-source-file-contents (source-file)
  (uiop:read-file-string (navigation-source-file-pathname-of source-file)))

(defun navigation-step-successful-p (step)
  (not (typep (navigation-step-outcome-of step)
              'navigation-test-failed)))

(defun navigation-step-explanation (step)
  "Derive an explanation from STEP's observed transition and outcome."
  (let ((before (navigation-step-before-of step))
        (after (navigation-step-after-of step))
        (outcome (navigation-step-outcome-of step)))
    (cond
      ((typep outcome 'navigation-case-outcome)
       (format nil "Recorded case ~S at ~A without changing navigation."
               (navigation-case-outcome-text outcome)
               (navigation-position-location-of before)))
      ((navigation-step-link-observation-of step)
       (let ((link (navigation-step-link-observation-of step)))
         (format nil "Followed ~S as slug ~S from ~A to ~A."
                 (navigation-link-observation-link-text link)
                 (navigation-link-observation-link-slug-of link)
                 (navigation-link-observation-source-location-of link)
                 (navigation-link-observation-target-location-of link))))
      ((typep outcome 'navigation-test-outcome)
       (format nil "Tested ~S against item ~S at ~A: ~:[failed~;passed~]."
               (navigation-test-outcome-fragment outcome)
               (navigation-position-current-item-id-of after)
               (navigation-position-location-of after)
               (navigation-test-outcome-passed-p outcome)))
      ((typep outcome 'navigation-test-failed)
       (format nil "Tested ~S at ~A: failed."
               (navigation-test-failed-fragment-of outcome)
               (navigation-position-location-of after)))
      (t
       (format nil "Executed ~S, moving from item ~S to ~S at ~A."
               (navigation-step-operation-of step)
               (navigation-position-current-item-id-of before)
               (navigation-position-current-item-id-of after)
               (navigation-position-location-of after))))))

(defun navigation-link-observation-for-transition
    (producer-symbol before-item before after)
  (when (eq producer-symbol 'follow-link)
    (make-navigation-link-observation
     :link-text
     (copy-navigation-string (navigation-item-text before-item))
     :link-slug
     (copy-navigation-string (navigation-item-link-slug before-item))
     :source-location
     (copy-navigation-string (navigation-position-location-of before))
     :target-location
     (copy-navigation-string (navigation-position-location-of after)))))

(defun run-navigation-trace (session command-records)
  "Execute COMMAND-RECORDS through the existing navigation executor."
  (let ((initial-session (navigation-position-from-session session))
        (steps nil))
    (loop
      for command in command-records
      for number from 1
      for before = (navigation-position-from-session session)
      for before-item = (session-current-item session)
      for outcome =
        (handler-case
            (execute-navigation-command
             session
             (navigation-trace-command-executor-command command))
          (navigation-test-failed (condition)
            condition))
      for after = (navigation-position-from-session session)
      for producer = (navigation-trace-command-operation command)
      do
         (push
          (make-navigation-step
           :number number
           :command-text
           (copy-navigation-string
            (navigation-trace-command-text command))
           :operation producer
           :arguments
           (copy-tree (navigation-trace-command-arguments command))
           :before before
           :producer-symbol producer
           :outcome outcome
           :after after
           :link-observation
           (navigation-link-observation-for-transition
            producer before-item before after)
           :implementation
           (make-navigation-source-reference
            producer
            (navigation-trace-command-producer-component command))
           :dispatcher-implementation
           (make-navigation-source-reference
            'execute-navigation-command
            "make-navigation-fixture"))
          steps))
    (let ((ordered-steps (nreverse steps)))
      (make-navigation-trace
       :initial-session initial-session
       :commands
       (mapcar
        (lambda (command)
          (copy-navigation-string
           (navigation-trace-command-text command)))
        command-records)
       :steps ordered-steps
       :final-session (navigation-position-from-session session)
       :result
       (if (every #'navigation-step-successful-p ordered-steps)
           :passed
           :failed)))))

(defun make-fedwiki-java-navigation-trace ()
  "Run the first seven local FEDWIKI-JAVA commands as an inspectable trace."
  (run-navigation-trace
   (make-navigation-fixture)
   *fedwiki-java-navigation-trace-commands*))

(hyperdoc:defexample fedwiki-java-navigation-trace-example
  "Run the durable seven-step local FEDWIKI-JAVA navigation trace."
  (make-fedwiki-java-navigation-trace))
