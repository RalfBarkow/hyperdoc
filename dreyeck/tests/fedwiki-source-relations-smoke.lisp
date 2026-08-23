;;;; Durable source, Topicmap, Inspector, and Catalog tests.

(defpackage #:dreyeck/fedwiki-source-relations/tests
  (:use #:cl)
  (:export #:run-fedwiki-source-relations-tests))

(in-package #:dreyeck/fedwiki-source-relations/tests)

(defparameter +baseline+
  "56325b3e08581198649f9f47d7b23dc059ea671a")

(defparameter +paths+
  '("hyperbook.asd"
    "hyperbook-fedwiki/fedwiki.lisp"
    "hyperbook-fedwiki/story-items.lisp"))

(defparameter +component-order+
  '("package" "utilities" "pages" "fedwiki" "story-items"
    "wiki-links" "plugins" "views"))

(defparameter +topic-ids+
  '("component:fedwiki"
    "component:story-items"
    "function:fetch-site-owner"
    "function:process-text-and-links"
    "function:find-examples-for-story-item-types"
    "special:neighborhood"
    "special:link-regex"))

(defparameter +view-titles+
  '("Overview"
    "Component order"
    "Source relations"
    "Topicmap"
    "Refactoring hypotheses"))

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun count-substring (needle source)
  (loop with count = 0
        for start = 0 then (+ position (length needle))
        for position = (search needle source :start2 start :test #'char-equal)
        while position
        do (incf count)
        finally (return count)))

(defun view-named (title object)
  (find title
        (html-inspector-views:all-views object)
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun view-reference-values (view)
  (mapcar #'cdr (html-inspector-views:view-references view)))

(defun relation-named (id observation)
  (find id
        (dreyeck/fedwiki-source-relations:fedwiki-source-relations-relations-of
         observation)
        :key
        #'dreyeck/fedwiki-source-relations:typed-source-relation-id-of
        :test #'string=))

(defun definition-named (id observation)
  (check
   (dreyeck/fedwiki-source-relations:fedwiki-source-relations-definition
    observation id)
   "Definition evidence ~S is absent."
   id))

(defun loaded-system-names ()
  (sort (copy-list (asdf:already-loaded-systems)) #'string<))

(defun check-source-observation (observation)
  (let* ((commit
           (dreyeck/fedwiki-source-relations:fedwiki-source-relations-commit-of
            observation))
         (files
           (dreyeck/fedwiki-source-relations:fedwiki-source-relations-files-of
            observation))
         (definitions
           (dreyeck/fedwiki-source-relations:fedwiki-source-relations-definitions-of
            observation))
         (relations
           (dreyeck/fedwiki-source-relations:fedwiki-source-relations-relations-of
            observation))
         (fetch (definition-named "function:fetch-site-owner" observation))
         (process
           (definition-named
            "function:process-text-and-links" observation))
         (find-examples
           (definition-named
            "function:find-examples-for-story-item-types" observation))
         (neighborhood
           (definition-named "special:neighborhood" observation))
         (url-regex (definition-named "special:url-regex" observation))
         (any-regex
           (definition-named
            "special:any-except-closing-bracket-regex" observation))
         (link-regex (definition-named "special:link-regex" observation)))
    (check
     (string= +baseline+ (dreyeck/git:git-commit-hash-of commit))
     "Observed the wrong baseline commit: ~A."
     (dreyeck/git:git-commit-hash-of commit))
    (check
     (equal +paths+ (mapcar #'dreyeck/git:git-file-path-of files))
     "Observed Git paths differ: ~S."
     (mapcar #'dreyeck/git:git-file-path-of files))
    (dolist (file files)
      (check (eq commit (dreyeck/git:git-file-commit-of file))
             "Git file ~A is not tied to the baseline commit."
             (dreyeck/git:git-file-path-of file)))
    (check
     (equal
      +component-order+
      (dreyeck/fedwiki-source-relations:fedwiki-source-relations-component-order-of
       observation))
     "FedWiki component order differs.")
    (check
     (= 1
        (- (position "story-items" +component-order+ :test #'string=)
           (position "fedwiki" +component-order+ :test #'string=)))
     "FEDWIKI is not immediately before STORY-ITEMS.")
    (check (= 7 (length definitions))
           "Observation has ~D definitions instead of seven."
           (length definitions))
    (check (= 13 (length relations))
           "Observation has ~D relations instead of thirteen."
           (length relations))
    (dolist (definition definitions)
      (let* ((fragment
               (dreyeck/fedwiki-source-relations:definition-evidence-fragment-of
                definition))
             (file
               (dreyeck/fedwiki-source-relations:definition-evidence-file-of
                definition)))
        (check
         (eq file
             (dreyeck/fedwiki-source-relations:source-fragment-file-of
              fragment))
         "Definition ~A and its fragment refer to different Git files."
         (dreyeck/fedwiki-source-relations:definition-evidence-name-of
          definition))
        (check (member file files :test #'eq)
               "Definition ~A is not backed by one of the three Git files."
               (dreyeck/fedwiki-source-relations:definition-evidence-name-of
                definition))
        (check
         (plusp
          (length
           (dreyeck/fedwiki-source-relations:source-fragment-text-of
            fragment)))
         "Definition ~A has an empty authoritative fragment."
         (dreyeck/fedwiki-source-relations:definition-evidence-name-of
          definition))))
    (flet ((fragment-text (definition)
             (dreyeck/fedwiki-source-relations:source-fragment-text-of
              (dreyeck/fedwiki-source-relations:definition-evidence-fragment-of
               definition))))
      (check (= 1 (count-substring "process-text-and-links"
                                   (fragment-text fetch)))
             "FETCH-SITE-OWNER call evidence is not unique.")
      (check (= 1 (count-substring "*neighborhood*"
                                   (fragment-text find-examples)))
             "Development-helper *NEIGHBORHOOD* read is not unique.")
      (check (= 1 (count-substring "*link-regex*"
                                   (fragment-text process)))
             "PROCESS-TEXT-AND-LINKS *LINK-REGEX* read is not unique.")
      (check (= 1 (count-substring "*url-regex*"
                                   (fragment-text link-regex)))
             "*LINK-REGEX* does not uniquely use *URL-REGEX*.")
      (check (= 2 (count-substring "*any-except-closing-bracket-regex*"
                                   (fragment-text link-regex)))
             "*LINK-REGEX* does not contain the two expected bracket-regex references."))
    (check
     (eq :development-helper
         (dreyeck/fedwiki-source-relations:definition-evidence-role-of
          find-examples))
     "FIND-EXAMPLES-FOR-STORY-ITEM-TYPES is not a development helper.")
    (dolist (definition (list fetch process find-examples neighborhood
                              url-regex any-regex link-regex))
      (check definition "A required definition object is absent."))
    (let ((file-relations
            (remove-if-not
             (lambda (relation)
               (eq :uses-definition-from
                   (dreyeck/fedwiki-source-relations:typed-source-relation-type-of
                    relation)))
             relations)))
      (check (= 2 (length file-relations))
             "Expected two derived file uses, found ~D."
             (length file-relations))
      (check
       (every
        #'dreyeck/fedwiki-source-relations:typed-source-relation-derived-from-of
        file-relations)
       "A file-level relation is not explicitly derived.")
      (let ((paths
              (mapcar
               (lambda (relation)
                 (list
                  (dreyeck/git:git-file-path-of
                   (dreyeck/fedwiki-source-relations:typed-source-relation-source-of
                    relation))
                  (dreyeck/git:git-file-path-of
                   (dreyeck/fedwiki-source-relations:typed-source-relation-target-of
                    relation))))
               file-relations)))
        (check
         (equal
          '(("hyperbook-fedwiki/fedwiki.lisp"
             "hyperbook-fedwiki/story-items.lisp")
            ("hyperbook-fedwiki/story-items.lisp"
             "hyperbook-fedwiki/fedwiki.lisp"))
          paths)
         "Derived file uses are not the two opposing paths: ~S."
         paths)))
    (dolist
        (spec
         '(("calls:fetch-site-owner:process-text-and-links"
            (:run-time)
            :none-observed
            nil)
           ("reads-special:find-examples:neighborhood"
            (:compile-time :run-time)
            :required-component-order
            (:special-proclamation))
           ("reads-special:process-text-and-links:link-regex"
            (:compile-time :run-time)
            :required-within-file
            (:special-proclamation))
           ("reads-special:link-regex:url-regex"
            (:compile-time :load-time)
            :required-within-file
            (:special-proclamation :load-time-value))
           ("reads-special:link-regex:any-except-closing-bracket-regex"
            (:compile-time :load-time)
            :required-within-file
            (:special-proclamation :load-time-value))
           ("loads-before:fedwiki:story-items"
            (:system-definition)
            :observed-component-order
            (:asdf-dependency))))
      (destructuring-bind
          (id phases ordering-constraint ordering-basis)
          spec
        (let ((relation (relation-named id observation)))
          (check relation
                 "Relation ~S is absent."
                 id)
          (check
           (equal
            phases
            (dreyeck/fedwiki-source-relations:typed-source-relation-phases-of
             relation))
           "Relation ~S has phases ~S instead of ~S."
           id
           (dreyeck/fedwiki-source-relations:typed-source-relation-phases-of
            relation)
           phases)
          (check
           (eq
            ordering-constraint
            (dreyeck/fedwiki-source-relations:typed-source-relation-ordering-constraint-of
             relation))
           "Relation ~S has ordering constraint ~S instead of ~S."
           id
           (dreyeck/fedwiki-source-relations:typed-source-relation-ordering-constraint-of
            relation)
           ordering-constraint)
          (check
           (equal
            ordering-basis
            (dreyeck/fedwiki-source-relations:typed-source-relation-ordering-basis-of
             relation))
           "Relation ~S has ordering basis ~S instead of ~S."
           id
           (dreyeck/fedwiki-source-relations:typed-source-relation-ordering-basis-of
            relation)
           ordering-basis))))
    observation))


(defun check-hypotheses (observation)
  (let* ((hypotheses
           (dreyeck/fedwiki-source-relations:fedwiki-source-relations-hypotheses-of
            observation))
         (helper
           (find "hypothesis:development-helper-component" hypotheses
                 :key
                 #'dreyeck/fedwiki-source-relations:refactoring-hypothesis-id-of
                 :test #'string=))
         (parser
           (find "hypothesis:wiki-text-component" hypotheses
                 :key
                 #'dreyeck/fedwiki-source-relations:refactoring-hypothesis-id-of
                 :test #'string=)))
    (check (= 2 (length hypotheses))
           "Expected two hypotheses, found ~D."
           (length hypotheses))
    (check helper "Development-helper hypothesis is absent.")
    (check parser "Wiki-text parser hypothesis is absent.")
    (dolist (hypothesis hypotheses)
      (check
       (eq :not-executed
           (dreyeck/fedwiki-source-relations:refactoring-hypothesis-status-of
            hypothesis))
       "Hypothesis ~A is not marked :NOT-EXECUTED."
       (dreyeck/fedwiki-source-relations:refactoring-hypothesis-title-of
        hypothesis))
      (check
       (dreyeck/fedwiki-source-relations:refactoring-hypothesis-removed-relations-of
        hypothesis)
       "Hypothesis ~A identifies no relation intended to change."
       (dreyeck/fedwiki-source-relations:refactoring-hypothesis-title-of
        hypothesis))
      (check
       (dreyeck/fedwiki-source-relations:refactoring-hypothesis-required-tests-of
        hypothesis)
       "Hypothesis ~A identifies no required regressions."
       (dreyeck/fedwiki-source-relations:refactoring-hypothesis-title-of
        hypothesis))
      (check
       (plusp
        (length
         (dreyeck/fedwiki-source-relations:refactoring-hypothesis-falsifier-of
          hypothesis)))
       "Hypothesis ~A identifies no falsifier."
       (dreyeck/fedwiki-source-relations:refactoring-hypothesis-title-of
        hypothesis)))
    (check
     (equal
      '("special:url-regex"
        "special:any-except-closing-bracket-regex"
        "special:link-regex"
        "function:process-text-and-links")
      (mapcar
       #'dreyeck/fedwiki-source-relations:definition-evidence-id-of
       (dreyeck/fedwiki-source-relations:refactoring-hypothesis-moved-definitions-of
        parser)))
     "Wiki-text parser hypothesis does not move all four coupled definitions.")
    t))

(defun check-topicmap (observation)
  (let* ((projection
           (dreyeck/topicmap:topicmap-projection-of observation))
         (topics
           (dreyeck/topicmap:topicmap-projection-topics-of projection))
         (associations
           (dreyeck/topicmap:topicmap-projection-associations-of projection))
         (topic-ids
           (mapcar #'dreyeck/topicmap:topicmap-topic-id-of topics))
         (association-ids
           (mapcar #'dreyeck/topicmap:topicmap-association-id-of associations))
         (association-types
           (mapcar #'dreyeck/topicmap:topicmap-association-type-of
                   associations)))
    (check (= 7 (length topics))
           "Topicmap has ~D topics instead of seven." (length topics))
    (check (= 9 (length associations))
           "Topicmap has ~D associations instead of nine."
           (length associations))
    (check (equal +topic-ids+ topic-ids)
           "Topic IDs differ: ~S." topic-ids)
    (check (= 7 (length (remove-duplicates topic-ids :test #'string=)))
           "Topic IDs are not unique: ~S." topic-ids)
    (check (= 9 (length (remove-duplicates association-ids :test #'string=)))
           "Association IDs are not unique: ~S." association-ids)
    (dolist (type '(:loads-before :defines :calls :reads-special))
      (check (member type association-types)
             "Topicmap lacks association type ~S." type))
    (check (= 5 (count :defines association-types))
           "Topicmap does not have five :DEFINES associations.")
    (DOLIST (ASSOCIATION ASSOCIATIONS)
      (LET* ((TYPE (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF ASSOCIATION))
             (PROPERTIES
              (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-PROPERTIES-OF ASSOCIATION))
             (PRESENTATION (GETF PROPERTIES :PRESENTATION :RELATION)))
        (IF (EQ TYPE :DEFINES)
            (PROGN
             (CHECK (EQ PRESENTATION :STRUCTURAL-CONTAINMENT)
                    "Definition association ~A has presentation ~S instead of :STRUCTURAL-CONTAINMENT."
                    (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-ID-OF ASSOCIATION)
                    PRESENTATION)
             (CHECK (EQ (GETF PROPERTIES :CONTAINED-ENDPOINT) :TO)
                    "Definition association ~A has contained endpoint ~S instead of :TO."
                    (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-ID-OF ASSOCIATION)
                    (GETF PROPERTIES :CONTAINED-ENDPOINT)))
            (CHECK (EQ PRESENTATION :RELATION)
                   "Non-definition association ~A of type ~S has presentation ~S instead of :RELATION."
                   (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-ID-OF ASSOCIATION) TYPE
                   PRESENTATION))))
    (check (= 1 (count :calls association-types))
           "Topicmap does not have one :CALLS association.")
    (check (= 2 (count :reads-special association-types))
           "Topicmap does not have two :READS-SPECIAL associations.")
    (check (= 1 (count :loads-before association-types))
           "Topicmap does not have one :LOADS-BEFORE association.")
    (dolist (topic topics)
      (check
       (string= +baseline+
                (dreyeck/topicmap:topicmap-topic-temporal-scope-of topic))
       "Topic ~A has the wrong temporal scope."
       (dreyeck/topicmap:topicmap-topic-id-of topic))
      (let ((properties
              (dreyeck/topicmap:topicmap-topic-view-properties-of topic)))
        (dolist (key '(:x :y :visible :pinned))
          (check (member key properties)
                 "Topic ~A lacks manual view property ~S."
                 (dreyeck/topicmap:topicmap-topic-id-of topic) key))))
    projection))

(defun check-inspector-views (observation)
  (let* ((views (html-inspector-views:all-views observation))
         (titles (mapcar #'html-inspector-views:view-title views)))
    (dolist (title +view-titles+)
      (check (= 1 (count title titles :test #'string=))
             "Required view ~S occurs ~D times in ~S."
             title (count title titles :test #'string=) titles))
    (check
     (equal +view-titles+ (subseq titles 0 (length +view-titles+)))
     "Required views are not first in their specified relative order: ~S."
     titles)
    (dolist (title +view-titles+)
      (check
       (plusp (length (html-inspector-views:view-html
                       (view-named title observation))))
       "View ~S rendered no HTML." title))
    (let* ((overview-view (view-named "Overview" observation))
           (overview-references (view-reference-values overview-view))
           (source-view (view-named "Source relations" observation))
           (source-references (view-reference-values source-view))
           (topicmap-view (view-named "Topicmap" observation))
           (topicmap-html (html-inspector-views:view-html topicmap-view)))
      (dolist
          (object
	   (dreyeck/fedwiki-source-relations:fedwiki-source-relations-files-of
	    observation))
        (check (member object overview-references :test #'eq)
               "Overview does not retain inspectable Git file ~S."
               object))
      (dolist
          (object
	   (append
	    (rest
	     (dreyeck/fedwiki-source-relations:fedwiki-source-relations-files-of
	      observation))
	    (dreyeck/fedwiki-source-relations:fedwiki-source-relations-definitions-of
	     observation)))
        (check (member object source-references :test #'eq)
               "Source-relations view does not retain inspectable ~S."
               object))
      (dolist (marker
	       '("dreyeck-topicmap-canvas"
		 "data-topic-id='component:fedwiki'"
		 "data-topic-id='function:fetch-site-owner'"
		 "data-association-type='LOADS-BEFORE'"
		 "data-association-type='DEFINES'"
		 "data-association-type='CALLS'"
		 "data-association-type='READS-SPECIAL'"
		 "data-temporal-scope='56325b3e08581198649f9f47d7b23dc059ea671a'"))
        (check (search marker topicmap-html :test #'char-equal)
               "Topicmap HTML lacks marker ~S." marker)))
    t))

(defun check-hyperdoc-and-catalog ()
  (let* ((book
           (hyperbook:find-hyperbook
            "dreyeck/fedwiki-source-relations" :signal-error? t))
         (members (hyperbook:hyperbooks-of hyperbook:*catalog*)))
    (check
     (= 1
        (count "dreyeck/fedwiki-source-relations" members
               :key #'hyperbook:id-of :test #'string=))
     "FedWiki source-relations HyperDoc is not registered exactly once.")
    (check
     (string= "FedWiki Component Order and Source Relations"
              (hyperbook:title-of book))
     "FedWiki source-relations HyperDoc has the wrong title.")
    (check
     (string= "FedWiki Component Order and Source Relations"
              (hyperbook:main-page-id-of book))
     "FedWiki source-relations HyperDoc has the wrong main page.")
    (hyperdoc::ensure-pages-loaded book)
    (check (= 1 (hash-table-count (hyperdoc:pages-of book)))
           "FedWiki source-relations HyperDoc is not one-sided.")
    (let* ((page
             (hyperbook:find-page
              book "FedWiki Component Order and Source Relations"
              :signal-error? t))
           (content-view (view-named "Content" page)))
      (check page "FedWiki source-relations main page did not load.")
      (check content-view
             "FedWiki source-relations main page has no Content view.")
      (let ((html (html-inspector-views:view-html content-view)))
        (check (search "56325b3e08581198649f9f47d7b23dc059ea671a" html)
               "Rendered main page lacks the fixed baseline.")
        (check (search "FEDWIKI-SOURCE-RELATIONS-EXAMPLE" html
                       :test #'char-equal)
               "Rendered main page lacks the executable example/source handoff.")
        (dolist (marker
                 '("ASDF order is an observation, not yet an explanation"
                   "A forward function call does not establish the component order"
                   "A relation in the opposite direction does constrain compilation"
                   "Phase-sensitive source relations"
                   "Current analysis boundary"))
          (check
           (search marker html)
           "Rendered main page lacks content marker ~S."
           marker)))
      (let ((observations
              (remove-if-not
               (lambda (reference)
                 (typep
                  reference
                  'dreyeck/fedwiki-source-relations:fedwiki-source-relations-observation))
               (view-reference-values content-view))))
        (check (= 6 (length observations))
               "Main page retained ~D observations instead of six."
               (length observations))
        (check (= 6 (length (remove-duplicates observations :test #'eq)))
               "Main page reused an observation between executable examples."))
      )
    t))

(defun run-fedwiki-source-relations-tests ()
  (let* ((fedwiki-system (asdf:find-system "hyperbook/fedwiki"))
         (fedwiki-loaded-before (asdf:component-loaded-p fedwiki-system))
         (loaded-before (loaded-system-names))
         (first
           (dreyeck/fedwiki-source-relations:fedwiki-source-relations-example))
         (second
           (dreyeck/fedwiki-source-relations:fedwiki-source-relations-example)))
    (check (not (eq first second))
           "FEDWIKI-SOURCE-RELATIONS-EXAMPLE reused a cached observation.")
    (check-source-observation first)
    (check-hypotheses first)
    (check-topicmap first)
    (check-inspector-views first)
    (check-hyperdoc-and-catalog)
    (check
     (eql fedwiki-loaded-before (asdf:component-loaded-p fedwiki-system))
     "Git observation changed the HYPERBOOK/FEDWIKI load state.")
    (check (equal loaded-before (loaded-system-names))
           "Observation or rendering loaded additional ASDF systems: ~S."
           (set-difference (loaded-system-names) loaded-before
                           :test #'string=)))
  (format t "FedWiki source-relations tests passed.~%")
  t)
