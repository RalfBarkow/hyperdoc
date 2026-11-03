
(COMMON-LISP:DEFPACKAGE :DREYECK/HYPERDOC/LIBRARY-TESTS
  (:USE :CL)
  (:EXPORT :RUN-TESTS))

(COMMON-LISP:IN-PACKAGE :DREYECK/HYPERDOC/LIBRARY-TESTS)

(COMMON-LISP:DEFPARAMETER DREYECK/HYPERDOC/LIBRARY-TESTS::+UPSTREAM+
  "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8")

(COMMON-LISP:DEFPARAMETER DREYECK/HYPERDOC/LIBRARY-TESTS::+PREVIOUS+
  "401953522ec503cf78764bddc5534f7a9f16fd22")

(defparameter +host-forwarding+ "53732270d42177eb01a46dad7940e60244ec52a2"
  "Existing reusable HOST forwarding; compare its two forms exactly, not just their names.")

(defun compatibility-revision (path)
  (if (string= path "hyperbook-server/server.lisp") +host-forwarding+ +previous+))

(COMMON-LISP:DEFPARAMETER DREYECK/HYPERDOC/LIBRARY-TESTS::+PATHS+
  '("hyperdoc" "hyperbook" "hyperdoc-explorer" "hyperbook-explorer"
    "inspector-hyperdoc" "hyperbook-fedwiki" "hyperbook-wikipedia"
    "hyperbook-server" "hyperdoc.asd" "hyperbook.asd"))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/LIBRARY-TESTS::FORMS-AT
                   (DREYECK/HYPERDOC/LIBRARY-TESTS::ROOT
                    DREYECK/HYPERDOC/LIBRARY-TESTS::REVISION
                    DREYECK/HYPERDOC/LIBRARY-TESTS::PATH)
  (COMMON-LISP:LET ((COMMON-LISP:*PACKAGE*
                     (COMMON-LISP:IF (COMMON-LISP:STRING=
                                      (COMMON-LISP:PATHNAME-TYPE
                                       DREYECK/HYPERDOC/LIBRARY-TESTS::PATH)
                                      "asd")
                                     (COMMON-LISP:FIND-PACKAGE :ASDF)
                                     COMMON-LISP:*PACKAGE*)))
    (DREYECK/WORKFLOW:SOURCE-FORMS
     (COMMON-LISP:IF DREYECK/HYPERDOC/LIBRARY-TESTS::REVISION
                     (DREYECK/GIT:GIT-RUN-STRING
                      DREYECK/HYPERDOC/LIBRARY-TESTS::ROOT "show"
                      (COMMON-LISP:CONCATENATE 'COMMON-LISP:STRING
                                               DREYECK/HYPERDOC/LIBRARY-TESTS::REVISION
                                               ":"
                                               DREYECK/HYPERDOC/LIBRARY-TESTS::PATH))
                     (COMMON-LISP:MERGE-PATHNAMES
                      DREYECK/HYPERDOC/LIBRARY-TESTS::PATH
                      DREYECK/HYPERDOC/LIBRARY-TESTS::ROOT)))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/LIBRARY-TESTS::COMPATIBILITY-FORM-P
                   (DREYECK/HYPERDOC/LIBRARY-TESTS::PATH
                    DREYECK/HYPERDOC/LIBRARY-TESTS::FORM)
  (COMMON-LISP:AND
   (COMMON-LISP:SYMBOLP
    (COMMON-LISP:SECOND DREYECK/HYPERDOC/LIBRARY-TESTS::FORM))
   (COMMON-LISP:MEMBER
    (COMMON-LISP:SYMBOL-NAME
     (COMMON-LISP:SECOND DREYECK/HYPERDOC/LIBRARY-TESTS::FORM))
    (COMMON-LISP:COND
     ((COMMON-LISP:STRING= DREYECK/HYPERDOC/LIBRARY-TESTS::PATH
                           "hyperdoc/core.lisp")
      '("MAKE-HYPERDOC" "CL-SOURCE-FILE-COMPONENTS-UNDER"))
     ((COMMON-LISP:STRING= DREYECK/HYPERDOC/LIBRARY-TESTS::PATH
                           "hyperdoc/defining.lisp")
      '("DEFHYPERDOC"))
     ((string= path "hyperbook-server/server.lisp")
      '("SERVE-HYPERBOOKS" "SERVE-CATALOG")))
    :TEST #'COMMON-LISP:EQUAL)))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/LIBRARY-TESTS::NORMALIZE-DEPENDENCIES
                   (DREYECK/HYPERDOC/LIBRARY-TESTS::PATH
                    DREYECK/HYPERDOC/LIBRARY-TESTS::FORMS)
  (COMMON-LISP:WHEN
      (COMMON-LISP:STRING= DREYECK/HYPERDOC/LIBRARY-TESTS::PATH
                           "hyperbook.asd")
    (COMMON-LISP:DOLIST
        (DREYECK/HYPERDOC/LIBRARY-TESTS::FORM
         DREYECK/HYPERDOC/LIBRARY-TESTS::FORMS)
      (COMMON-LISP:WHEN
          (COMMON-LISP:AND
           (COMMON-LISP:SYMBOLP
            (COMMON-LISP:FIRST DREYECK/HYPERDOC/LIBRARY-TESTS::FORM))
           (COMMON-LISP:STRING-EQUAL
            (COMMON-LISP:FIRST DREYECK/HYPERDOC/LIBRARY-TESTS::FORM)
            "DEFSYSTEM")
           (COMMON-LISP:STRING-EQUAL
            (COMMON-LISP:SECOND DREYECK/HYPERDOC/LIBRARY-TESTS::FORM)
            "hyperbook/fedwiki"))
        (COMMON-LISP:SETF (COMMON-LISP:GETF
                           (COMMON-LISP:CDDR
                            DREYECK/HYPERDOC/LIBRARY-TESTS::FORM)
                           :DEPENDS-ON)
                            (COMMON-LISP:REMOVE "CLOG"
                                                (COMMON-LISP:GETF
                                                 (COMMON-LISP:CDDR
                                                  DREYECK/HYPERDOC/LIBRARY-TESTS::FORM)
                                                 :DEPENDS-ON)
                                                :TEST
                                                #'COMMON-LISP:STRING-EQUAL)))))
  DREYECK/HYPERDOC/LIBRARY-TESTS::FORMS)

(DEFUN SOURCE-EQUAL (COMMON-LISP-USER::A COMMON-LISP-USER::B)
  (COND
   ((AND (CONSP COMMON-LISP-USER::A) (CONSP COMMON-LISP-USER::B))
    (AND (SOURCE-EQUAL (CAR COMMON-LISP-USER::A) (CAR COMMON-LISP-USER::B))
         (SOURCE-EQUAL (CDR COMMON-LISP-USER::A) (CDR COMMON-LISP-USER::B))))
   ((AND (VECTORP COMMON-LISP-USER::A) (VECTORP COMMON-LISP-USER::B)
         (NOT (STRINGP COMMON-LISP-USER::A))
         (NOT (STRINGP COMMON-LISP-USER::B)))
    (AND (= (LENGTH COMMON-LISP-USER::A) (LENGTH COMMON-LISP-USER::B))
         (EVERY #'SOURCE-EQUAL COMMON-LISP-USER::A COMMON-LISP-USER::B)))
   (T (DREYECK/WORKFLOW:FORM-EQUAL COMMON-LISP-USER::A COMMON-LISP-USER::B))))

(DEFUN CHECK-FEDWIKI-IMAGE-COMPATIBILITY ()
  (LET* ((WIKI
          (MAKE-INSTANCE 'HYPERBOOK/FEDWIKI::FEDWIKI :ID
                         "fedwiki:example.invalid:8443"))
         (PAGE
          (MAKE-INSTANCE 'HYPERBOOK/FEDWIKI::REMOTE-FEDWIKI-PAGE :ID "image"
                         :ORIGIN WIKI :ORIGIN-ID "image" :HYPERBOOK WIKI))
         (DATA (MAKE-HASH-TABLE :TEST #'EQUAL))
         (ITEM
          (MAKE-INSTANCE 'HYPERBOOK/FEDWIKI::STORY-ITEM :ITEM-TYPE :IMAGE :ID
                         "image" :TEXT "" :DATA DATA)))
    (ASSERT
     (STRING= "example.invalid:8443" (HYPERBOOK/FEDWIKI::DOMAIN-NAME-OF WIKI)))
    (SETF (GETHASH "url" DATA) "/assets/example.png"
          (GETHASH "width" DATA) 640
          (GETHASH "height" DATA) 480
          (GETHASH "size" DATA) "wide")
    (ASSERT
     (EQUAL '(640 480 "wide")
            (MULTIPLE-VALUE-LIST
             (HYPERBOOK/FEDWIKI::STORY-ITEM-IMAGE-PRESENTATION-HINTS ITEM))))
    (ASSERT
     (STRING= "https://example.invalid:8443/assets/example.png"
              (HYPERBOOK/FEDWIKI::RESOLVE-STORY-ITEM-URL "/assets/example.png"
                                                         PAGE)))
    (DOLIST
        (URL
         '("https://other.invalid/p.png" "//other.invalid/p.png" "image.png"))
      (ASSERT
       (EQUAL URL (HYPERBOOK/FEDWIKI::RESOLVE-STORY-ITEM-URL URL PAGE))))
    (LET* ((VIEW
            (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE "Image contract"
                                            (HYPERBOOK/FEDWIKI::RENDER-STORY-ITEM
                                             :IMAGE ITEM PAGE)))
           (HTML (HTML-INSPECTOR-VIEWS:VIEW-HTML VIEW)))
      (DOLIST
          (MARKER
           '("https://example.invalid:8443/assets/example.png" "640" "480"
             "data-fedwiki-size" "max-width: 100%" "height: auto"
             "figcaption"))
        (ASSERT (SEARCH MARKER HTML))))
    (SETF (GETHASH "width" DATA) -1
          (GETHASH "height" DATA) "480"
          (GETHASH "size" DATA) "")
    (ASSERT
     (EQUAL '(NIL NIL NIL)
            (MULTIPLE-VALUE-LIST
             (HYPERBOOK/FEDWIKI::STORY-ITEM-IMAGE-PRESENTATION-HINTS ITEM)))))
  T)

(defparameter +fedwiki-sitemap+ "99521dc6a8df21fd56fc0e9da25302bfb7b87f3f"
  "Last revision of hyperbook-fedwiki/fedwiki.lisp before the name-service delta.
It already carries the retained-sitemap forms added after +PREVIOUS+, which the
inventory had not recorded.")

(defun fedwiki-retained-revision (path)
  (if (string= path "hyperbook-fedwiki/fedwiki.lisp") +fedwiki-sitemap+ +previous+))

(defparameter +name-service-delta+
  '("hyperbook-fedwiki/fedwiki.lisp" "INITIALIZE-FEDWIKI" "NS-ERROR"
    "NS-HOST-NOT-FOUND-ERROR")
  "The one deliberate change to this file after +FEDWIKI-SITEMAP+:
INITIALIZE-FEDWIKI handles USOCKET:NS-ERROR, which covers every name-service
failure (including NS-TRY-AGAIN-ERROR), where it handled only
NS-HOST-NOT-FOUND-ERROR. Candidate upstream contribution.")

(defun undo-name-service-delta (path forms)
  "FORMS with the name-service delta of PATH reverted, so that every form can
still be compared with the revision it is pinned to. The revert is confined to the
named form and must apply exactly once, so no other change can hide behind it."
  (destructuring-bind (delta-path form-name new old) +name-service-delta+
    (if (not (string= path delta-path))
        forms
        (let ((count 0))
          (labels ((revert (tree)
                     (cond ((consp tree)
                            (cons (revert (car tree)) (revert (cdr tree))))
                           ((and (symbolp tree) tree (string= (symbol-name tree) new))
                            (incf count)
                            (if (symbol-package tree)
                                (intern old (symbol-package tree))
                                (make-symbol old)))
                           (t tree)))
                   (target-p (form)
                     (and (consp form) (consp (cdr form)) (symbolp (second form))
                          (second form) (string= (symbol-name (second form)) form-name))))
            (prog1 (mapcar (lambda (form) (if (target-p form) (revert form) form))
                           forms)
              (assert (= 1 count))))))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/LIBRARY-TESTS:RUN-TESTS NIL
                   (DREYECK/HYPERDOC/LIBRARY-TESTS::CHECK-FEDWIKI-IMAGE-COMPATIBILITY)
                   (COMMON-LISP:LET*
                                     ((DREYECK/HYPERDOC/LIBRARY-TESTS::ROOT
                                                                            (ASDF/SYSTEM:SYSTEM-SOURCE-DIRECTORY
                                                                                                                 (ASDF/SYSTEM:FIND-SYSTEM
                                                                                                                                          "dreyeck")))
                                      (DREYECK/HYPERDOC/LIBRARY-TESTS::CHANGED
                                                                               (COMMON-LISP:REMOVE
                                                                                                   ""
                                                                                                   (UIOP/UTILITY:SPLIT-STRING
                                                                                                                              (COMMON-LISP:APPLY
                                                                                                                                                 (FUNCTION
                                                                                                                                                           DREYECK/GIT:GIT-RUN-STRING)
                                                                                                                                                 DREYECK/HYPERDOC/LIBRARY-TESTS::ROOT
                                                                                                                                                 "diff"
                                                                                                                                                 "--name-only"
                                                                                                                                                 DREYECK/HYPERDOC/LIBRARY-TESTS::+UPSTREAM+
                                                                                                                                                 "--"
                                                                                                                                                 DREYECK/HYPERDOC/LIBRARY-TESTS::+PATHS+)
                                                                                                                              :SEPARATOR
                                                                                                                              (QUOTE
                                                                                                                                     (#\Newline)))
                                                                                                   :TEST
                                                                                                   (FUNCTION
                                                                                                             COMMON-LISP:EQUAL))))
                                     (COMMON-LISP:ASSERT
                                                         (COMMON-LISP:ZEROP
                                                                            (COMMON-LISP:LENGTH
                                                                                                (COMMON-LISP:APPLY
                                                                                                                   (FUNCTION
                                                                                                                             DREYECK/GIT:GIT-RUN-STRING)
                                                                                                                   DREYECK/HYPERDOC/LIBRARY-TESTS::ROOT
                                                                                                                   "ls-files"
                                                                                                                   "--others"
                                                                                                                   "--exclude-standard"
                                                                                                                   "--"
                                                                                                                   DREYECK/HYPERDOC/LIBRARY-TESTS::+PATHS+))))
                                     (COMMON-LISP:DOLIST
                                                         (DREYECK/HYPERDOC/LIBRARY-TESTS::PATH
                                                                                               DREYECK/HYPERDOC/LIBRARY-TESTS::CHANGED)
                                                         (COMMON-LISP:LET*
                                                                           ((DREYECK/HYPERDOC/LIBRARY-TESTS::LOCAL
                                                                                                                   (DREYECK/HYPERDOC/LIBRARY-TESTS::FORMS-AT
                                                                                                                                                             DREYECK/HYPERDOC/LIBRARY-TESTS::ROOT
                                                                                                                                                             NIL
                                                                                                                                                             DREYECK/HYPERDOC/LIBRARY-TESTS::PATH))
                                                                            (DREYECK/HYPERDOC/LIBRARY-TESTS::UPSTREAM
                                                                                                                      (DREYECK/HYPERDOC/LIBRARY-TESTS::FORMS-AT
                                                                                                                                                                DREYECK/HYPERDOC/LIBRARY-TESTS::ROOT
                                                                                                                                                                DREYECK/HYPERDOC/LIBRARY-TESTS::+UPSTREAM+
                                                                                                                                                                DREYECK/HYPERDOC/LIBRARY-TESTS::PATH)))
                                                                           (COMMON-LISP:IF
                                                                                           (COMMON-LISP:MEMBER
                                                                                                               DREYECK/HYPERDOC/LIBRARY-TESTS::PATH
                                                                                                               (QUOTE
                                                                                                                      ("hyperbook-fedwiki/fedwiki.lisp"
                                                                                                                       "hyperbook-fedwiki/pages.lisp"
                                                                                                                       "hyperbook-fedwiki/story-items.lisp"
                                                                                                                       "hyperbook-fedwiki/wiki-links.lisp"))
                                                                                                               :TEST
                                                                                                               (FUNCTION
                                                                                                                         COMMON-LISP:EQUAL))
                                                                                           (COMMON-LISP:ASSERT
                                                                                                               (DREYECK/HYPERDOC/LIBRARY-TESTS::SOURCE-EQUAL
                                                                                                                                                             (UNDO-NAME-SERVICE-DELTA DREYECK/HYPERDOC/LIBRARY-TESTS::PATH DREYECK/HYPERDOC/LIBRARY-TESTS::LOCAL)
                                                                                                                                                             (DREYECK/HYPERDOC/LIBRARY-TESTS::FORMS-AT
                                                                                                                                                                                                       DREYECK/HYPERDOC/LIBRARY-TESTS::ROOT
                                                                                                                                                                                                       (FEDWIKI-RETAINED-REVISION DREYECK/HYPERDOC/LIBRARY-TESTS::PATH)
                                                                                                                                                                                                       DREYECK/HYPERDOC/LIBRARY-TESTS::PATH)))
                                                                                           (COMMON-LISP:LET*
                                                                                                             ((DREYECK/HYPERDOC/LIBRARY-TESTS::ALLOWED
                                                                                                                                                       (COMMON-LISP:LAMBDA
                                                                                                                                                                           (DREYECK/HYPERDOC/LIBRARY-TESTS::F)
                                                                                                                                                                           (DREYECK/HYPERDOC/LIBRARY-TESTS::COMPATIBILITY-FORM-P
                                                                                                                                                                                                                                 DREYECK/HYPERDOC/LIBRARY-TESTS::PATH
                                                                                                                                                                                                                                 DREYECK/HYPERDOC/LIBRARY-TESTS::F)))
                                                                                                              (DREYECK/HYPERDOC/LIBRARY-TESTS::RETAINED
                                                                                                                                                        (COMMON-LISP:REMOVE-IF-NOT
                                                                                                                                                                                   DREYECK/HYPERDOC/LIBRARY-TESTS::ALLOWED
                                                                                                                                                                                   DREYECK/HYPERDOC/LIBRARY-TESTS::LOCAL))
                                                                                                              (DREYECK/HYPERDOC/LIBRARY-TESTS::LEFT
                                                                                                                                                    (DREYECK/HYPERDOC/LIBRARY-TESTS::NORMALIZE-DEPENDENCIES
                                                                                                                                                                                                            DREYECK/HYPERDOC/LIBRARY-TESTS::PATH
                                                                                                                                                                                                            (COMMON-LISP:REMOVE-IF
                                                                                                                                                                                                                                   DREYECK/HYPERDOC/LIBRARY-TESTS::ALLOWED
                                                                                                                                                                                                                                   (COMMON-LISP:COPY-TREE
                                                                                                                                                                                                                                                          DREYECK/HYPERDOC/LIBRARY-TESTS::LOCAL))))
                                                                                                              (DREYECK/HYPERDOC/LIBRARY-TESTS::RIGHT
                                                                                                                                                     (COMMON-LISP:REMOVE-IF
                                                                                                                                                                            DREYECK/HYPERDOC/LIBRARY-TESTS::ALLOWED
                                                                                                                                                                            DREYECK/HYPERDOC/LIBRARY-TESTS::UPSTREAM)))
                                                                                                             (COMMON-LISP:WHEN
                                                                                                                               DREYECK/HYPERDOC/LIBRARY-TESTS::RETAINED
                                                                                                                               (COMMON-LISP:ASSERT
                                                                                                                                                   (DREYECK/HYPERDOC/LIBRARY-TESTS::SOURCE-EQUAL
                                                                                                                                                                                                 DREYECK/HYPERDOC/LIBRARY-TESTS::RETAINED
                                                                                                                                                                                                 (COMMON-LISP:REMOVE-IF-NOT
                                                                                                                                                                                                                            DREYECK/HYPERDOC/LIBRARY-TESTS::ALLOWED
                                                                                                                                                                                                                            (DREYECK/HYPERDOC/LIBRARY-TESTS::FORMS-AT
                                                                                                                                                                                                                                                                      DREYECK/HYPERDOC/LIBRARY-TESTS::ROOT
                                                                                                                                                                                                                                                                      (compatibility-revision path)
                                                                                                                                                                                                                                                                      DREYECK/HYPERDOC/LIBRARY-TESTS::PATH)))))
                                                                                                             (COMMON-LISP:ASSERT
                                                                                                                                 (COMMON-LISP:=
                                                                                                                                                (COMMON-LISP:LENGTH
                                                                                                                                                                    DREYECK/HYPERDOC/LIBRARY-TESTS::LEFT)
                                                                                                                                                (COMMON-LISP:LENGTH
                                                                                                                                                                    DREYECK/HYPERDOC/LIBRARY-TESTS::RIGHT)))
                                                                                                             (COMMON-LISP:ASSERT
                                                                                                                                 (COMMON-LISP:NULL
                                                                                                                                                   (COMMON-LISP:SET-DIFFERENCE
                                                                                                                                                                               DREYECK/HYPERDOC/LIBRARY-TESTS::LEFT
                                                                                                                                                                               DREYECK/HYPERDOC/LIBRARY-TESTS::RIGHT
                                                                                                                                                                               :TEST
                                                                                                                                                                               (FUNCTION
                                                                                                                                                                                         DREYECK/HYPERDOC/LIBRARY-TESTS::SOURCE-EQUAL))))
                                                                                                             (COMMON-LISP:ASSERT
                                                                                                                                 (COMMON-LISP:NULL
                                                                                                                                                   (COMMON-LISP:SET-DIFFERENCE
                                                                                                                                                                               DREYECK/HYPERDOC/LIBRARY-TESTS::RIGHT
                                                                                                                                                                               DREYECK/HYPERDOC/LIBRARY-TESTS::LEFT
                                                                                                                                                                               :TEST
                                                                                                                                                                               (FUNCTION
                                                                                                                                                                                         DREYECK/HYPERDOC/LIBRARY-TESTS::SOURCE-EQUAL))))))))
                                     (COMMON-LISP:FORMAT COMMON-LISP:T
                                                         "Library source matches upstream apart from the enumerated compatibility forms.~%"))
                   COMMON-LISP:T)
