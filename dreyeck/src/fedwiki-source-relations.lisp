;;;; Source-backed facts about the FedWiki component-order observation.

(in-package #:dreyeck/fedwiki-source-relations)

(defparameter +fedwiki-source-relations-baseline+
  "56325b3e08581198649f9f47d7b23dc059ea671a")

(defparameter +fedwiki-source-relation-paths+
  '("hyperbook.asd"
    "hyperbook-fedwiki/fedwiki.lisp"
    "hyperbook-fedwiki/story-items.lisp"))

(defparameter +fedwiki-component-order+
  '("package" "utilities" "pages" "fedwiki" "story-items"
    "wiki-links" "plugins" "views"))

(defclass source-fragment-evidence ()
  ((file :reader source-fragment-file-of :initarg :file
         :type dreyeck/git:git-file-at-commit)
   (definition :reader source-fragment-definition-of :initarg :definition
               :type string)
   (kind :reader source-fragment-kind-of :initarg :kind :type symbol)
   (start-line :reader source-fragment-start-line-of :initarg :start-line
               :type integer)
   (end-line :reader source-fragment-end-line-of :initarg :end-line
             :type integer)
   (text :reader source-fragment-text-of :initarg :text :type string))
  (:documentation "An exact, unevaluated excerpt from one Git blob."))

(defclass definition-evidence ()
  ((id :reader definition-evidence-id-of :initarg :id :type string)
   (name :reader definition-evidence-name-of :initarg :name :type string)
   (kind :reader definition-evidence-kind-of :initarg :kind :type symbol)
   (role :reader definition-evidence-role-of :initarg :role
         :type (member :production :development-helper))
   (file :reader definition-evidence-file-of :initarg :file
         :type dreyeck/git:git-file-at-commit)
   (fragment :reader definition-evidence-fragment-of :initarg :fragment
             :type source-fragment-evidence))
  (:documentation "A named definition evidenced by an exact Git-blob excerpt."))

(defclass typed-source-relation ()
  ((id :reader typed-source-relation-id-of :initarg :id :type string)
   (type :reader typed-source-relation-type-of :initarg :type :type symbol)
   (source :reader typed-source-relation-source-of :initarg :source)
   (target :reader typed-source-relation-target-of :initarg :target)
   (role :reader typed-source-relation-role-of :initarg :role
         :type (member :production :development-helper))
   (phases :reader typed-source-relation-phases-of :initarg :phases
           :initform '(:structural) :type list)
   (ordering-constraint
    :reader typed-source-relation-ordering-constraint-of
    :initarg :ordering-constraint
    :initform :not-applicable
    :type (member :not-applicable
                  :none-observed
                  :observed-component-order
                  :required-component-order
                  :required-within-file))
   (ordering-basis
    :reader typed-source-relation-ordering-basis-of
    :initarg :ordering-basis
    :initform nil
    :type list)
   (fragment :reader typed-source-relation-fragment-of :initarg :fragment
             :type source-fragment-evidence)
   (derived-from :reader typed-source-relation-derived-from-of
                 :initarg :derived-from :initform nil))
  (:documentation "One typed fact or explicitly derived file-level relation."))

(defclass refactoring-hypothesis ()
  ((id :reader refactoring-hypothesis-id-of :initarg :id :type string)
   (title :reader refactoring-hypothesis-title-of :initarg :title :type string)
   (status :reader refactoring-hypothesis-status-of :initarg :status
           :type (member :not-executed))
   (moved-definitions :reader refactoring-hypothesis-moved-definitions-of
                      :initarg :moved-definitions :type list)
   (removed-relations :reader refactoring-hypothesis-removed-relations-of
                      :initarg :removed-relations :type list)
   (required-tests :reader refactoring-hypothesis-required-tests-of
                   :initarg :required-tests :type list)
   (falsifier :reader refactoring-hypothesis-falsifier-of :initarg :falsifier
              :type string)
   (notes :reader refactoring-hypothesis-notes-of :initarg :notes :type string))
  (:documentation "A proposed but deliberately unexecuted source refactoring."))

(defclass fedwiki-source-relations-observation ()
  ((commit :reader fedwiki-source-relations-commit-of :initarg :commit
           :type dreyeck/git:git-commit)
   (system-name :reader fedwiki-source-relations-system-name-of
                :initarg :system-name :type string)
   (files :reader fedwiki-source-relations-files-of :initarg :files :type list)
   (component-order :reader fedwiki-source-relations-component-order-of
                    :initarg :component-order :type list)
   (component-fragment
    :reader fedwiki-source-relations-component-fragment-of
    :initarg :component-fragment :type source-fragment-evidence)
   (definitions :reader fedwiki-source-relations-definitions-of
                :initarg :definitions :type list)
   (relations :reader fedwiki-source-relations-relations-of
              :initarg :relations :type list)
   (hypotheses :reader fedwiki-source-relations-hypotheses-of
               :initarg :hypotheses :type list)
   (task :reader fedwiki-source-relations-task-of :initarg :task :type string)
   (task-location :reader fedwiki-source-relations-task-location-of
                  :initarg :task-location :type string)
   (existing-routine :reader fedwiki-source-relations-existing-routine-of
                     :initarg :existing-routine :type string)
   (routine-effects :reader fedwiki-source-relations-routine-effects-of
                    :initarg :routine-effects :type list)
   (problem-status :reader fedwiki-source-relations-problem-status-of
                   :initarg :problem-status :type symbol)
   (problem-statement :reader fedwiki-source-relations-problem-statement-of
                      :initarg :problem-statement :type string))
  (:documentation "The complete source-backed FedWiki component-order observation."))

(defmethod print-object ((fragment source-fragment-evidence) stream)
  (print-unreadable-object (fragment stream :type t :identity nil)
    (format stream "~A lines ~D-~D"
            (source-fragment-definition-of fragment)
            (source-fragment-start-line-of fragment)
            (source-fragment-end-line-of fragment))))

(defmethod print-object ((evidence definition-evidence) stream)
  (print-unreadable-object (evidence stream :type t :identity nil)
    (format stream "~A" (definition-evidence-name-of evidence))))

(defmethod print-object ((relation typed-source-relation) stream)
  (print-unreadable-object (relation stream :type t :identity nil)
    (format stream "~A" (typed-source-relation-type-of relation))))

(defmethod print-object ((hypothesis refactoring-hypothesis) stream)
  (print-unreadable-object (hypothesis stream :type t :identity nil)
    (format stream "~A (~A)"
            (refactoring-hypothesis-title-of hypothesis)
            (refactoring-hypothesis-status-of hypothesis))))

(defmethod print-object ((observation fedwiki-source-relations-observation) stream)
  (print-unreadable-object (observation stream :type t :identity nil)
    (format stream "FedWiki source relations @ ~A"
            (subseq
             (dreyeck/git:git-commit-hash-of
              (fedwiki-source-relations-commit-of observation))
             0 12))))

(defun count-substring (needle source)
  (loop with count = 0
        for start = 0 then (+ position (length needle))
        for position = (search needle source :start2 start :test #'char-equal)
        while position
        do (incf count)
        finally (return count)))

(defun unique-marker-position (marker source)
  (let ((count (count-substring marker source)))
    (unless (= 1 count)
      (error "Expected one occurrence of ~S in observed blob, found ~D."
             marker count))
    (search marker source :test #'char-equal)))

(defun line-number-at (source position)
  (1+ (count #\Newline source :end position)))

(defun anchored-form-end (source start)
  "Return the end of the parenthesized form beginning at explicit START."
  (let ((depth 0)
        (in-string nil)
        (escaped nil)
        (line-comment nil)
        (started nil))
    (loop for position from start below (length source)
          for character = (char source position)
          do (cond
               (line-comment
                (when (find character '(#\Newline #\Return))
                  (setf line-comment nil)))
               (in-string
                (cond
                  (escaped (setf escaped nil))
                  ((char= character #\\) (setf escaped t))
                  ((char= character #\") (setf in-string nil))))
               ((char= character #\;) (setf line-comment t))
               ((char= character #\") (setf in-string t))
               ((char= character #\()
                (setf started t)
                (incf depth))
               ((char= character #\))
                (decf depth)
                (when (and started (zerop depth))
                  (return (1+ position)))))
          finally (error "Unterminated observed form at character ~D." start))))

(defun make-form-fragment (file source definition kind anchor)
  (let* ((start (unique-marker-position anchor source))
         (end (anchored-form-end source start))
         (text (subseq source start end)))
    (make-instance
     'source-fragment-evidence
     :file file
     :definition definition
     :kind kind
     :start-line (line-number-at source start)
     :end-line (line-number-at source end)
     :text text)))

(defun make-definition (id name kind role file source anchor)
  (make-instance
   'definition-evidence
   :id id
   :name name
   :kind kind
   :role role
   :file file
   :fragment (make-form-fragment file source name kind anchor)))

(defun require-reference-count (definition target expected)
  (let* ((fragment (definition-evidence-fragment-of definition))
         (actual (count-substring target (source-fragment-text-of fragment))))
    (unless (= expected actual)
      (error "Expected ~D reference(s) to ~A in ~A, found ~D."
             expected target (definition-evidence-name-of definition) actual)))
  t)

(defun validate-development-helper-position (source)
  (let* ((comment ";; find examples")
         (definition "(defun find-examples-for-story-item-types")
         (comment-position (unique-marker-position comment source))
         (definition-position (unique-marker-position definition source))
         (between
           (subseq source (+ comment-position (length comment))
                   definition-position)))
    (unless (and (< comment-position definition-position)
                 (every (lambda (character)
                          (find character '(#\Space #\Tab #\Newline #\Return)))
                        between))
      (error "FIND-EXAMPLES-FOR-STORY-ITEM-TYPES is not directly under the unique 'find examples' source heading.")))
  t)

(defun validate-component-order (fragment)
  (let* ((source (source-fragment-text-of fragment))
         (positions
           (mapcar
            (lambda (component)
              (unique-marker-position
               (format nil "(:file \"~A\")" component)
               source))
            +fedwiki-component-order+)))
    (unless (search ":serial t" source :test #'char-equal)
      (error "Observed HYPERBOOK/FEDWIKI system is not serial."))
    (unless (equal positions (sort (copy-list positions) #'<))
      (error "Observed FedWiki component order differs: ~S." positions))
    (unless (= 1 (- (position "story-items" +fedwiki-component-order+
                              :test #'string=)
		    (position "fedwiki" +fedwiki-component-order+
                              :test #'string=)))
      (error "FEDWIKI is not immediately before STORY-ITEMS.")))
  t)

(defun make-relation (id type source target role fragment
		      &key
			derived-from
			(phases
			 (if derived-from
			     (copy-list
			      (typed-source-relation-phases-of derived-from))
			     '(:structural)))
			(ordering-constraint
			 (if derived-from
			     (typed-source-relation-ordering-constraint-of derived-from)
			     :not-applicable))
			(ordering-basis
			 (if derived-from
			     (copy-list
			      (typed-source-relation-ordering-basis-of derived-from))
			     nil)))
  (make-instance
   'typed-source-relation
   :id id
   :type type
   :source source
   :target target
   :role role
   :phases phases
   :ordering-constraint ordering-constraint
   :ordering-basis ordering-basis
   :fragment fragment
   :derived-from derived-from))

(defun require-unique-ids (objects key label)
  (let ((ids (mapcar key objects)))
    (unless (= (length ids) (length (remove-duplicates ids :test #'string=)))
      (error "~A IDs are not unique: ~S." label ids)))
  t)

(defun fedwiki-source-relations-file (observation path)
  (find path
        (fedwiki-source-relations-files-of observation)
        :key #'dreyeck/git:git-file-path-of
        :test #'string=))

(defun fedwiki-source-relations-definition (observation id)
  (find id
        (fedwiki-source-relations-definitions-of observation)
        :key #'definition-evidence-id-of
        :test #'string=))

(defun fedwiki-source-relations-relation (observation id)
  (find id
        (fedwiki-source-relations-relations-of observation)
        :key #'typed-source-relation-id-of
        :test #'string=))

(defun make-fedwiki-source-relations-observation
    (&key (repository (dreyeck/git:make-current-git-repository-checkout)))
  "Construct a fresh, unevaluated observation of the fixed merge commit."
  (let* ((commit
           (dreyeck/git:make-git-commit
            :repository repository
            :commit-ish +fedwiki-source-relations-baseline+)))
    (unless (string= +fedwiki-source-relations-baseline+
                     (dreyeck/git:git-commit-hash-of commit))
      (error "FedWiki source baseline resolved to the wrong commit."))
    (let* ((files
             (mapcar
              (lambda (path)
                (dreyeck/git:make-git-file-at-commit
                 :commit commit :path path))
              +fedwiki-source-relation-paths+))
           (asdf-file (first files))
           (fedwiki-file (second files))
           (story-items-file (third files))
           (asdf-source (dreyeck/git:git-file-contents asdf-file))
           (fedwiki-source (dreyeck/git:git-file-contents fedwiki-file))
           (story-source (dreyeck/git:git-file-contents story-items-file))
           (component-fragment
             (make-form-fragment
              asdf-file asdf-source "hyperbook/fedwiki" :asdf-system
              "(defsystem #:hyperbook/fedwiki"))
           (fetch
             (make-definition
              "function:fetch-site-owner" "FETCH-SITE-OWNER" :function
              :production fedwiki-file fedwiki-source
              "(defun fetch-site-owner"))
           (neighborhood
             (make-definition
              "special:neighborhood" "*NEIGHBORHOOD*" :special-variable
              :production fedwiki-file fedwiki-source
              "(defvar *neighborhood*"))
           (process
             (make-definition
              "function:process-text-and-links" "PROCESS-TEXT-AND-LINKS"
              :function :production story-items-file story-source
              "(defun process-text-and-links"))
           (find-examples
             (make-definition
              "function:find-examples-for-story-item-types"
              "FIND-EXAMPLES-FOR-STORY-ITEM-TYPES" :function
              :development-helper story-items-file story-source
              "(defun find-examples-for-story-item-types"))
           (url-regex
             (make-definition
              "special:url-regex" "*URL-REGEX*" :special-variable
              :production story-items-file story-source
              "(defparameter *url-regex*"))
           (any-regex
             (make-definition
              "special:any-except-closing-bracket-regex"
              "*ANY-EXCEPT-CLOSING-BRACKET-REGEX*" :special-variable
              :production story-items-file story-source
              "(defparameter *any-except-closing-bracket-regex*"))
           (link-regex
             (make-definition
              "special:link-regex" "*LINK-REGEX*" :special-variable
              :production story-items-file story-source
              "(defparameter *link-regex*"))
           (definitions
             (list fetch process find-examples neighborhood
                   url-regex any-regex link-regex)))
      (validate-component-order component-fragment)
      (validate-development-helper-position story-source)
      (require-reference-count fetch "process-text-and-links" 1)
      (require-reference-count find-examples "*neighborhood*" 1)
      (require-reference-count process "*link-regex*" 1)
      (require-reference-count link-regex "*url-regex*" 1)
      (require-reference-count
       link-regex "*any-except-closing-bracket-regex*" 2)
      (require-unique-ids definitions #'definition-evidence-id-of "Definition")
      (let* ((defines-fetch
               (make-relation "defines:fedwiki:fetch-site-owner" :defines
                              fedwiki-file fetch :production
                              (definition-evidence-fragment-of fetch)))
             (defines-process
               (make-relation "defines:story-items:process-text-and-links"
                              :defines story-items-file process :production
                              (definition-evidence-fragment-of process)))
             (calls-process
	       (make-relation "calls:fetch-site-owner:process-text-and-links"
			      :calls fetch process :production
			      (definition-evidence-fragment-of fetch)
			      :phases '(:run-time)
			      :ordering-constraint :none-observed))
             (defines-find
               (make-relation
                "defines:story-items:find-examples-for-story-item-types"
                :defines story-items-file find-examples :development-helper
                (definition-evidence-fragment-of find-examples)))
             (defines-neighborhood
               (make-relation "defines:fedwiki:neighborhood" :defines
                              fedwiki-file neighborhood :production
                              (definition-evidence-fragment-of neighborhood)))
             (reads-neighborhood
	       (make-relation
		"reads-special:find-examples:neighborhood"
		:reads-special
		find-examples
		neighborhood
		:development-helper
		(definition-evidence-fragment-of find-examples)
		:phases '(:compile-time :run-time)
		:ordering-constraint :required-component-order
		:ordering-basis '(:special-proclamation)))
             (defines-link-regex
               (make-relation "defines:story-items:link-regex" :defines
                              story-items-file link-regex :production
                              (definition-evidence-fragment-of link-regex)))
             (reads-link-regex
	       (make-relation
		"reads-special:process-text-and-links:link-regex"
		:reads-special
		process
		link-regex
		:production
		(definition-evidence-fragment-of process)
		:phases '(:compile-time :run-time)
		:ordering-constraint :required-within-file
		:ordering-basis '(:special-proclamation)))
             (reads-url-regex
	       (make-relation
		"reads-special:link-regex:url-regex"
		:reads-special
		link-regex
		url-regex
		:production
		(definition-evidence-fragment-of link-regex)
		:phases '(:compile-time :load-time)
		:ordering-constraint :required-within-file
		:ordering-basis '(:special-proclamation :load-time-value)))
             (reads-any-regex
	       (make-relation
		"reads-special:link-regex:any-except-closing-bracket-regex"
		:reads-special
		link-regex
		any-regex
		:production
		(definition-evidence-fragment-of link-regex)
		:phases '(:compile-time :load-time)
		:ordering-constraint :required-within-file
		:ordering-basis '(:special-proclamation :load-time-value)))
             (loads-before
	       (make-relation
		"loads-before:fedwiki:story-items"
		:loads-before
		fedwiki-file
		story-items-file
		:production
		component-fragment
		:phases '(:system-definition)
		:ordering-constraint :observed-component-order
		:ordering-basis '(:asdf-dependency)))
             (forward-file-use
               (make-relation
                "uses-definition-from:fedwiki:story-items"
                :uses-definition-from fedwiki-file story-items-file :production
                (definition-evidence-fragment-of fetch)
                :derived-from calls-process))
             (reverse-file-use
               (make-relation
                "uses-definition-from:story-items:fedwiki"
                :uses-definition-from story-items-file fedwiki-file
                :development-helper
                (definition-evidence-fragment-of find-examples)
                :derived-from reads-neighborhood))
             (relations
               (list defines-fetch defines-process calls-process defines-find
                     defines-neighborhood reads-neighborhood defines-link-regex
                     reads-link-regex reads-url-regex reads-any-regex
                     loads-before forward-file-use reverse-file-use)))
        (require-unique-ids relations #'typed-source-relation-id-of "Relation")
        (let ((hypotheses
                (list
                 (make-instance
                  'refactoring-hypothesis
                  :id "hypothesis:development-helper-component"
                  :title "Move the development helper to a later component"
                  :status :not-executed
                  :moved-definitions (list find-examples)
                  :removed-relations (list reverse-file-use)
                  :required-tests
                  '("FedWiki system compile/load regression"
                    "Development-helper example discovery regression"
                    "No STORY-ITEMS to *NEIGHBORHOOD* source edge")
                  :falsifier
                  "The helper is required while STORY-ITEMS is compiled or loaded, or moving it changes supported runtime behavior."
                  :notes
                  "Its position under ';; find examples' supports a development-helper role; it is not claimed to be unused.")
                 (make-instance
                  'refactoring-hypothesis
                  :id "hypothesis:wiki-text-component"
                  :title "Extract the Wiki-text parser as one earlier component"
                  :status :not-executed
                  :moved-definitions
                  (list url-regex any-regex link-regex process)
                  :removed-relations (list forward-file-use)
                  :required-tests
                  '("Wiki-link title and slug contract"
                    "Wiki-text rendering and extraction regression"
                    "FETCH-SITE-OWNER owner extraction regression"
                    "ASDF component-order compile/load regression")
                  :falsifier
                  "The four definitions have additional ordering constraints that an earlier wiki-text component cannot satisfy."
                  :notes
                  "Moving only PROCESS-TEXT-AND-LINKS to utilities.lisp is incomplete because it reads *LINK-REGEX*, whose definition depends on *URL-REGEX* and *ANY-EXCEPT-CLOSING-BRACKET-REGEX*. A DECLAIM could document a compiler contract but would not decouple the files."))))
          (make-instance
           'fedwiki-source-relations-observation
           :commit commit
           :system-name "hyperbook/fedwiki"
           :files files
           :component-order (copy-list +fedwiki-component-order+)
           :component-fragment component-fragment
           :definitions definitions
           :relations relations
           :hypotheses hypotheses
           :task "Compile, load, and then use the complete hyperbook/fedwiki system."
           :task-location "The serial component contract of ASDF system hyperbook/fedwiki."
           :existing-routine ":serial t with fedwiki.lisp immediately before story-items.lisp."
           :routine-effects
	   '("*NEIGHBORHOOD* is established by a top-level DEFVAR before story-items.lisp is compiled; its special proclamation is therefore available to the compiler."
	     "The PROCESS-TEXT-AND-LINKS call occurs in a function body and does not by itself require story-items.lisp to precede fedwiki.lisp."
	     "The complete load makes PROCESS-TEXT-AND-LINKS available before FETCH-SITE-OWNER can call it at run time."
	     "The serial order therefore satisfies a FEDWIKI to STORY-ITEMS compile-time dependency while permitting the opposite run-time function call.")
           :problem-status :not-a-problem-under-current-load-and-use-contract
           :problem-statement
	   "The forward function call from fedwiki.lisp to PROCESS-TEXT-AND-LINKS does not establish a component-order requirement. The reverse use of *NEIGHBORHOOD* does: the top-level DEFVAR in fedwiki.lisp establishes the special proclamation needed when the corresponding reference in story-items.lisp is compiled. Under the current source shape, the observed serial order is therefore semantically relevant."))))))

(defun fedwiki-source-relations-example ()
  "Return a fresh source-backed observation without consulting a global cache."
  (make-fedwiki-source-relations-observation))

(defun relation-for-topicmap-p (relation)
  (member
   (typed-source-relation-id-of relation)
   '("defines:fedwiki:fetch-site-owner"
     "defines:story-items:process-text-and-links"
     "calls:fetch-site-owner:process-text-and-links"
     "defines:story-items:find-examples-for-story-item-types"
     "defines:fedwiki:neighborhood"
     "reads-special:find-examples:neighborhood"
     "defines:story-items:link-regex"
     "reads-special:process-text-and-links:link-regex"
     "loads-before:fedwiki:story-items")
   :test #'string=))

(defun topic-object (observation id)
  (cond
    ((string= id "component:fedwiki")
     (fedwiki-source-relations-file
      observation "hyperbook-fedwiki/fedwiki.lisp"))
    ((string= id "component:story-items")
     (fedwiki-source-relations-file
      observation "hyperbook-fedwiki/story-items.lisp"))
    (t (fedwiki-source-relations-definition observation id))))

(defun topic-position (id)
  (cdr
   (assoc id
          '(("component:fedwiki" . (40 180))
            ("function:fetch-site-owner" . (300 45))
            ("function:process-text-and-links" . (570 45))
            ("special:link-regex" . (840 45))
            ("component:story-items" . (40 430))
            ("function:find-examples-for-story-item-types" . (300 555))
            ("special:neighborhood" . (650 555)))
          :test #'string=)))

(defun topic-label (id)
  (cdr
   (assoc id
          '(("component:fedwiki" . "fedwiki.lisp")
            ("component:story-items" . "story-items.lisp")
            ("function:fetch-site-owner" . "FETCH-SITE-OWNER")
            ("function:process-text-and-links" . "PROCESS-TEXT-AND-LINKS")
            ("function:find-examples-for-story-item-types" .
             "FIND-EXAMPLES-FOR-STORY-ITEM-TYPES")
            ("special:neighborhood" . "*NEIGHBORHOOD*")
            ("special:link-regex" . "*LINK-REGEX*"))
          :test #'string=)))

(defmethod dreyeck/topicmap:topicmap-projection-of
    ((observation fedwiki-source-relations-observation))
  (let* ((topic-ids
           '("component:fedwiki"
             "component:story-items"
             "function:fetch-site-owner"
             "function:process-text-and-links"
             "function:find-examples-for-story-item-types"
             "special:neighborhood"
             "special:link-regex"))
         (topics
           (mapcar
            (lambda (id)
              (destructuring-bind (x y) (topic-position id)
                (dreyeck/topicmap:make-topicmap-topic
                 :id id
                 :type (if (uiop:string-prefix-p "component:" id)
                           :source-component
                           :source-definition)
                 :label (topic-label id)
                 :object (topic-object observation id)
                 :temporal-scope +fedwiki-source-relations-baseline+
                 :view-properties (list :x x :y y :visible t :pinned t))))
            topic-ids))
         (relations
           (remove-if-not #'relation-for-topicmap-p
                          (fedwiki-source-relations-relations-of observation)))
         (endpoint-id
           (lambda (endpoint)
             (etypecase endpoint
               (definition-evidence (definition-evidence-id-of endpoint))
               (dreyeck/git:git-file-at-commit
                (if (string= "hyperbook-fedwiki/fedwiki.lisp"
                             (dreyeck/git:git-file-path-of endpoint))
                    "component:fedwiki"
                    "component:story-items"))))))
    (dreyeck/topicmap:make-topicmap-projection
     :source observation
     :topics topics
     :associations
     (mapcar
      (lambda (relation)
        (dreyeck/topicmap:make-topicmap-association
         :id (format nil "association:~A"
                     (typed-source-relation-id-of relation))
         :type (typed-source-relation-type-of relation)
         :from (funcall endpoint-id
                        (typed-source-relation-source-of relation))
         :to (funcall endpoint-id
                      (typed-source-relation-target-of relation))
         :properties
         (list :role (typed-source-relation-role-of relation))))
      relations)
     :view-properties '(:width 1120 :height 700))))
