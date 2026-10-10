
(COMMON-LISP:DEFPACKAGE :DREYECK/HYPERDOC/BOUNDARY-TESTS
  (:USE :CL)
  (:EXPORT :RUN-TESTS))

(COMMON-LISP:IN-PACKAGE :DREYECK/HYPERDOC/BOUNDARY-TESTS)

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/BOUNDARY-TESTS::PAGE-HTML
                   (DREYECK/HYPERDOC/BOUNDARY-TESTS::BOOK
                    DREYECK/HYPERDOC/BOUNDARY-TESTS::PATH)
  (HTML-INSPECTOR-VIEWS:VIEW-HTML
   (HTML-INSPECTOR-VIEWS:👀CONTENT
    (HYPERDOC::MAKE-TEXT-PAGE DREYECK/HYPERDOC/BOUNDARY-TESTS::BOOK
                              DREYECK/HYPERDOC/BOUNDARY-TESTS::PATH))))

(DEFUN CONTENT-DISPATCHERS (BOOK)
  (HYPERBOOK::COLLECT-TAG-DISPATCHERS
   (REVERSE
    (HYPERBOOK::COLLECT-ASSETS (LIST (HYPERBOOK:HTML-PAGE-ASSETS-OF BOOK))))))

(DEFUN CONTENT-WITHOUT-DIRECTIVES (PAGE)
  "Exercise the actual Content View, including its assets and tag printers."
  (LET* ((VIEW (HTML-INSPECTOR-VIEWS:👀CONTENT PAGE))
         (HTML (HTML-INSPECTOR-VIEWS:VIEW-HTML VIEW))
         (DOM (PLUMP-PARSER:PARSE HTML)))
    (ASSERT (NULL (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME DOM "in-package")))
    (ASSERT (NOT (SEARCH "<in-package>" (PLUMP-DOM:TEXT DOM))))
    (ASSERT (NOT (SEARCH "&lt;in-package&gt;" HTML)))
    (ASSERT
     (NOTANY (LAMBDA (REF) (TYPEP (CDR REF) 'CONDITION))
             (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES VIEW)))
    VIEW))

(DEFUN FIXTURE-REFERENCE-ORDER (VIEW PAYLOADS)
  "Read native reference ids in rendered document order, not collector order."
  (LET ((VALUES NIL) (REFS (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES VIEW)))
    (LABELS ((WALK (NODE)
               (WHEN (PLUMP-DOM:ELEMENT-P NODE)
                 (LET* ((ID (PLUMP-DOM:ATTRIBUTE NODE "id"))
                        (VALUE (CDR (ASSOC ID REFS :TEST #'EQUAL))))
                   (WHEN (MEMBER VALUE PAYLOADS :TEST #'EQ)
                     (PUSH VALUE VALUES))))
               (WHEN (TYPEP NODE 'PLUMP-DOM:NESTING-NODE)
                 (LOOP FOR CHILD ACROSS (PLUMP-DOM:CHILDREN NODE)
                       DO (WALK CHILD)))))
      (WALK (PLUMP-PARSER:PARSE (HTML-INSPECTOR-VIEWS:VIEW-HTML VIEW))))
    (NREVERSE VALUES)))

(defun check-directive-fixture (book source packages expected payloads)
  (uiop:with-temporary-file (:stream out :pathname path :type "html")
    (write-string source out) (finish-output out)
    ;; Reproduce the previously failing ambient binding of an enclosing Content View.
    (let* ((plump:*tag-dispatchers* (content-dispatchers book))
           (page (hyperdoc::make-text-page book path))
           (dom (hyperbook:dom-of page))
           (default (aref (plump:children dom) 0)))
      (assert (plump:element-p default))
      (assert (equal "in-package" (plump:tag-name default)))
      (assert (equal "CL-USER" (plump:text default)))
      (assert (eq dom (plump:parent default)))
      (assert (equal packages
                     (mapcar #'plump:text (plump:get-elements-by-tag-name dom "in-package"))))
      (let* ((view (content-without-directives page))
             (html (html-inspector-views:view-html view)))
        (assert (equal expected (fixture-reference-order view payloads)))
        ;; Content consumes metadata without deleting it from the Parse Tree.
        (assert (eq default (aref (plump:children dom) 0)))
        (let* ((tree-view (find "Parse tree" (html-inspector-views:all-views page)
                               :key #'html-inspector-views:view-title :test #'equal)))
          (progn
            (assert (typep tree-view 'html-inspector-views:html-view))
            (html-inspector-views:view-html tree-view)
            (assert (member default (mapcar #'cdr (html-inspector-views:view-references tree-view)) :test #'eq)))
          (assert (eq default (aref (plump:children (hyperbook:dom-of page)) 0))))
        (let ((plump:*tag-dispatchers* plump:*html-tags*))
          (assert (search "<in-package>CL-USER</in-package>" (plump:serialize dom nil))))
        ;; Source remains the exact authored file, not the augmented in-memory DOM.
        (assert (equal source (uiop:read-file-string path)))
        (let ((source-view (find "Source" (html-inspector-views:all-views page)
                                 :key #'html-inspector-views:view-title :test #'equal)))
          (assert (typep source-view 'html-inspector-views:view))
          ;; Source uses the existing CLOG Ace file view, not an HTML-VIEW.
          (assert (equal (hyperdoc:file-of page) path)))
        (hyperdoc:load-page page)
        (assert (equal packages (mapcar #'plump:text
                               (plump:get-elements-by-tag-name (hyperbook:dom-of page) "in-package"))))
        (assert (equal expected (fixture-reference-order (content-without-directives page) payloads)))
        html))))



(DEFUN CHECK-PACKAGE-DIRECTIVES ()
  (LET* ((BOOK
          (MAKE-INSTANCE (FIND-SYMBOL "HYPERDOC" :DREYECK/HYPERDOC) :ID
                         "directive-boundary" :TITLE "Directives" :DIRECTORY
                         #P"/tmp/"))
         (A
          (MAKE-PACKAGE (SYMBOL-NAME (GENSYM "HYPERDOC-BOUNDARY-A-")) :USE
                        '("CL")))
         (B
          (MAKE-PACKAGE (SYMBOL-NAME (GENSYM "HYPERDOC-BOUNDARY-B-")) :USE
                        '("CL")))
         (NAME (SYMBOL-NAME (GENSYM "*DIRECTIVE-WITNESS-")))
         (DEFAULT-SYMBOL (INTERN NAME "CL-USER"))
         (DEFAULT (LIST :PACKAGE :DEFAULT))
         (PA (LIST :PACKAGE :A))
         (PB (LIST :PACKAGE :B)))
    (UNWIND-PROTECT
        (PROGN
         (SETF (SYMBOL-VALUE DEFAULT-SYMBOL) DEFAULT
               (SYMBOL-VALUE (INTERN NAME A)) PA
               (SYMBOL-VALUE (INTERN NAME B)) PB)
         (LET ((HTML
                (CHECK-DIRECTIVE-FIXTURE BOOK
                                         (FORMAT NIL
                                                 "<h1>Default</h1><html-expr>(format nil \"DEFAULT:~~A\" (package-name *package*))</html-expr><a expr='~A'>Default</a>"
                                                 NAME)
                                         '("CL-USER") (LIST DEFAULT)
                                         (LIST DEFAULT PA PB))))
           (ASSERT (SEARCH "DEFAULT:COMMON-LISP-USER" HTML)))
         (CHECK-DIRECTIVE-FIXTURE BOOK
                                  (FORMAT NIL
                                          "<h1>Explicit</h1><in-package>~A</in-package><a expr='~A'>A</a>"
                                          (PACKAGE-NAME A) NAME)
                                  (LIST "CL-USER" (PACKAGE-NAME A)) (LIST PA)
                                  (LIST DEFAULT PA PB))
         (CHECK-DIRECTIVE-FIXTURE BOOK
                                  (FORMAT NIL
                                          "<h1>Ordered</h1><a expr='~A'>Default</a><in-package>~A</in-package><a expr='~A'>A</a><in-package>~A</in-package><a expr='~A'>B</a><in-package>~A</in-package><a expr='~A'>A again</a>"
                                          NAME (PACKAGE-NAME A) NAME
                                          (PACKAGE-NAME B) NAME
                                          (PACKAGE-NAME A) NAME)
                                  (LIST "CL-USER" (PACKAGE-NAME A)
                                        (PACKAGE-NAME B) (PACKAGE-NAME A))
                                  (LIST DEFAULT PA PB PA) (LIST DEFAULT PA PB))
         (CHECK-DIRECTIVE-FIXTURE BOOK
                                  (FORMAT NIL
                                          "<h1>Default again</h1><a expr='~A'>Default</a>"
                                          NAME)
                                  '("CL-USER") (LIST DEFAULT)
                                  (LIST DEFAULT PA PB)))
      (UNINTERN DEFAULT-SYMBOL "CL-USER")
      (DELETE-PACKAGE A)
      (DELETE-PACKAGE B)))
  (FORMAT T
          "~&PACKAGE-DIRECTIVE-PASS: ambient renderer dispatch, CL-USER default, explicit/order semantics, native objects, truthful Source/Parse tree and reload.~%"))

(DEFUN CHECK-READING-CONTENT ()
  (ASDF/OPERATE:LOAD-SYSTEM "dreyeck/work/reading")
  (LET* ((WORK
          (HYPERBOOK:FIND-PAGE "dreyeck/work/reading"
                               "Federated Wiki deployment state" :SIGNAL-ERROR?
                               T))
         (WORK-VIEW (CONTENT-WITHOUT-DIRECTIVES WORK))
         (CONFIG
          (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-CONFIG :READING-PAGE
                                    "Reading FedWiki Configuration and Fork Behavior"))
         (CONFIG-VIEW (CONTENT-WITHOUT-DIRECTIVES CONFIG))
         (DEFAULT (AREF (PLUMP-DOM:CHILDREN (HYPERBOOK:DOM-OF CONFIG)) 0)))
    (ASSERT (PLUMP-DOM:ELEMENT-P DEFAULT))
    (ASSERT (EQUAL "CL-USER" (PLUMP-DOM:TEXT DEFAULT)))
    (ASSERT
     (EQUAL '("CL-USER" "dreyeck/fedwiki-config")
            (MAPCAR #'PLUMP-DOM:TEXT
                    (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME
                     (HYPERBOOK:DOM-OF CONFIG) "in-package"))))
    (ASSERT
     (MEMBER CONFIG
             (MAPCAR #'CDR (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES WORK-VIEW))
             :TEST #'EQ))
    (DOLIST (KEY '("localhost" "dreyeck" "ralfbarkow"))
      (ASSERT
       (FIND-IF
        (LAMBDA (OBJECT)
          (AND
           (TYPEP OBJECT
                  (FIND-SYMBOL "CONFIGURATION-BASE" :DREYECK/FEDWIKI-CONFIG))
           (EQUAL KEY
                  (GETHASH "key"
                           (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/FEDWIKI-CONFIG
                                                     :CONFIGURATION-RECORD
                                                     OBJECT)))))
        (MAPCAR #'CDR (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES CONFIG-VIEW)))))
    (DOLIST (TITLE '("wiki.ralfbarkow.ch deployment" "dreyeck.ch deployment"))
      (LET ((PAGE
             (HYPERBOOK:FIND-PAGE "dreyeck/work/reading" TITLE :SIGNAL-ERROR?
                                  T)))
        (CONTENT-WITHOUT-DIRECTIVES PAGE)))
    (FORMAT T
            "~&READING-DIRECTIVE-PASS: actual FedWiki/Work Content Views and native configuration/return links resolve without directive text.~%")))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/BOUNDARY-TESTS:RUN-TESTS NIL
                   (COMMON-LISP:ASSERT
                                       (COMMON-LISP:NOT
                                                        (ASDF/OPERATE:COMPONENT-LOADED-P
                                                                                         (ASDF/SYSTEM:FIND-SYSTEM
                                                                                                                  "dreyeck/hyperdoc"))))
                   (COMMON-LISP:ASSERT
                                       (COMMON-LISP:NOT
                                                        (COMMON-LISP:FIND-PACKAGE
                                                                                  :DREYECK/HYPERSPEC)))
                   (COMMON-LISP:ASSERT
                                       (COMMON-LISP:NOT
                                                        (COMMON-LISP:SEARCH
                                                                            "/hyperspec/"
                                                                            HTML-INSPECTOR-VIEWS/STANDARD::*HYPERSPEC-URL-TEMPLATE*)))
                   (COMMON-LISP:LET*
                                     ((DREYECK/HYPERDOC/BOUNDARY-TESTS::BASE
                                                                             (COMMON-LISP:MAKE-INSTANCE
                                                                                                        (QUOTE
                                                                                                               HYPERDOC:HYPERDOC)
                                                                                                        :ID
                                                                                                        "boundary"
                                                                                                        :TITLE
                                                                                                        "Boundary"
                                                                                                        :DIRECTORY
                                                                                                        #P"/tmp/"))
                                      (DREYECK/HYPERDOC/BOUNDARY-TESTS::LOADER
                                                                               (COMMON-LISP:FIND-METHOD
                                                                                                        (FUNCTION
                                                                                                                  HYPERDOC:LOAD-PAGE)
                                                                                                        NIL
                                                                                                        (COMMON-LISP:LIST
                                                                                                                          (COMMON-LISP:FIND-CLASS
                                                                                                                                                  (QUOTE
                                                                                                                                                         HYPERDOC:HTML-PAGE)))))
                                      (DREYECK/HYPERDOC/BOUNDARY-TESTS::RENDERER
                                                                                 (COMMON-LISP:FIND-METHOD
                                                                                                          (FUNCTION
                                                                                                                    HYPERBOOK:SERIALIZE-PAGE-DOM)
                                                                                                          NIL
                                                                                                          (COMMON-LISP:LIST
                                                                                                                            (COMMON-LISP:FIND-CLASS
                                                                                                                                                    (QUOTE
                                                                                                                                                           HYPERDOC:PAGE))))))
                                     (COMMON-LISP:ASSERT
                                                         (COMMON-LISP:EQ
                                                                         (HYPERDOC:PAGE-CLASS
                                                                                              DREYECK/HYPERDOC/BOUNDARY-TESTS::BASE
                                                                                              :HTML)
                                                                         (COMMON-LISP:FIND-CLASS
                                                                                                 (QUOTE
                                                                                                        HYPERDOC:HTML-PAGE))))
                                     (ASDF/OPERATE:LOAD-SYSTEM
                                                               "dreyeck/hyperdoc")
                                     (COMMON-LISP:ASSERT
                                                         (COMMON-LISP:EQ
                                                                         DREYECK/HYPERDOC/BOUNDARY-TESTS::LOADER
                                                                         (COMMON-LISP:FIND-METHOD
                                                                                                  (FUNCTION
                                                                                                            HYPERDOC:LOAD-PAGE)
                                                                                                  NIL
                                                                                                  (COMMON-LISP:LIST
                                                                                                                    (COMMON-LISP:FIND-CLASS
                                                                                                                                            (QUOTE
                                                                                                                                                   HYPERDOC:HTML-PAGE))))))
                                     (COMMON-LISP:ASSERT
                                                         (COMMON-LISP:EQ
                                                                         DREYECK/HYPERDOC/BOUNDARY-TESTS::RENDERER
                                                                         (COMMON-LISP:FIND-METHOD
                                                                                                  (FUNCTION
                                                                                                            HYPERBOOK:SERIALIZE-PAGE-DOM)
                                                                                                  NIL
                                                                                                  (COMMON-LISP:LIST
                                                                                                                    (COMMON-LISP:FIND-CLASS
                                                                                                                                            (QUOTE
                                                                                                                                                   HYPERDOC:PAGE))))))
                                     (COMMON-LISP:LET
                                                      ((DREYECK/HYPERDOC/BOUNDARY-TESTS::LOCAL
                                                                                               (COMMON-LISP:MAKE-INSTANCE
                                                                                                                          (COMMON-LISP:FIND-SYMBOL
                                                                                                                                                   "HYPERDOC"
                                                                                                                                                   :DREYECK/HYPERDOC)
                                                                                                                          :ID
                                                                                                                          "local-boundary"
                                                                                                                          :TITLE
                                                                                                                          "Local"
                                                                                                                          :DIRECTORY
                                                                                                                          #P"/tmp/")))
                                                      (COMMON-LISP:ASSERT
                                                                          (COMMON-LISP:EQ
                                                                                          (HYPERDOC:PAGE-CLASS
                                                                                                               DREYECK/HYPERDOC/BOUNDARY-TESTS::LOCAL
                                                                                                               :HTML)
                                                                                          (COMMON-LISP:FIND-CLASS
                                                                                                                  (COMMON-LISP:FIND-SYMBOL
                                                                                                                                           "HTML-PAGE"
                                                                                                                                           :DREYECK/HYPERDOC))))
                                                      (UIOP/STREAM:WITH-TEMPORARY-FILE
                                                                                       (:STREAM
                                                                                                COMMON-LISP:STREAM
                                                                                                :PATHNAME
                                                                                                DREYECK/HYPERDOC/BOUNDARY-TESTS::PATH
                                                                                                :TYPE
                                                                                                "html")
                                                                                       (COMMON-LISP:WRITE-STRING
                                                                                                                 "<h1>Boundary</h1><html-expr>(package-name *package*)</html-expr>"
                                                                                                                 COMMON-LISP:STREAM)
                                                                                       (COMMON-LISP:FINISH-OUTPUT
                                                                                                                  COMMON-LISP:STREAM)
                                                                                       (COMMON-LISP:ASSERT
                                                                                                           (COMMON-LISP:SEARCH
                                                                                                                               "COMMON-LISP<"
                                                                                                                               (DREYECK/HYPERDOC/BOUNDARY-TESTS::PAGE-HTML
                                                                                                                                                                           DREYECK/HYPERDOC/BOUNDARY-TESTS::BASE
                                                                                                                                                                           DREYECK/HYPERDOC/BOUNDARY-TESTS::PATH)))
                                                                                       (COMMON-LISP:ASSERT
                                                                                                           (COMMON-LISP:SEARCH
                                                                                                                               "COMMON-LISP-USER"
                                                                                                                               (DREYECK/HYPERDOC/BOUNDARY-TESTS::PAGE-HTML
                                                                                                                                                                           DREYECK/HYPERDOC/BOUNDARY-TESTS::LOCAL
                                                                                                                                                                           DREYECK/HYPERDOC/BOUNDARY-TESTS::PATH)))
                                                                                       (COMMON-LISP:LET
                                                                                                        ((DREYECK/HYPERDOC/BOUNDARY-TESTS::PAGE
                                                                                                                                                (HYPERDOC::MAKE-TEXT-PAGE
                                                                                                                                                                          DREYECK/HYPERDOC/BOUNDARY-TESTS::LOCAL
                                                                                                                                                                          DREYECK/HYPERDOC/BOUNDARY-TESTS::PATH)))
                                                                                                        (HYPERDOC:LOAD-PAGE
                                                                                                                            DREYECK/HYPERDOC/BOUNDARY-TESTS::PAGE)
                                                                                                        (COMMON-LISP:ASSERT
                                                                                                                            (COMMON-LISP:=
                                                                                                                                           1
                                                                                                                                           (COMMON-LISP:LENGTH
                                                                                                                                                               (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME
                                                                                                                                                                                                   (HYPERBOOK:DOM-OF
                                                                                                                                                                                                                     DREYECK/HYPERDOC/BOUNDARY-TESTS::PAGE)
                                                                                                                                                                                                   "in-package")))))
                                                                                       (COMMON-LISP:WITH-OPEN-FILE
                                                                                                                   (DREYECK/HYPERDOC/BOUNDARY-TESTS::OUT
                                                                                                                                                         DREYECK/HYPERDOC/BOUNDARY-TESTS::PATH
                                                                                                                                                         :DIRECTION
                                                                                                                                                         :OUTPUT
                                                                                                                                                         :IF-EXISTS
                                                                                                                                                         :SUPERSEDE)
                                                                                                                   (COMMON-LISP:WRITE-STRING
                                                                                                                                             "<h1>Explicit</h1><in-package>KEYWORD</in-package><html-expr>(cl:package-name cl:*package*)</html-expr>"
                                                                                                                                             DREYECK/HYPERDOC/BOUNDARY-TESTS::OUT))
                                                                                       (COMMON-LISP:ASSERT
                                                                                                           (COMMON-LISP:SEARCH
                                                                                                                               "KEYWORD"
                                                                                                                               (DREYECK/HYPERDOC/BOUNDARY-TESTS::PAGE-HTML
                                                                                                                                                                           DREYECK/HYPERDOC/BOUNDARY-TESTS::LOCAL
                                                                                                                                                                           DREYECK/HYPERDOC/BOUNDARY-TESTS::PATH))))))
                   (CHECK-PACKAGE-DIRECTIVES)
                   (CHECK-READING-CONTENT)
                   (ASDF/OPERATE:LOAD-SYSTEM "dreyeck/hyperspec")
                   (COMMON-LISP:ASSERT
                                       (COMMON-LISP:STRING= "/hyperspec/"
                                                            (UIOP/PACKAGE:SYMBOL-CALL
                                                                                      :DREYECK/HYPERSPEC
                                                                                      :HYPERSPEC-HTTP-ROOT)))
                   (COMMON-LISP:ASSERT
                                       (COMMON-LISP:NOT
                                                        (ASDF/OPERATE:COMPONENT-LOADED-P
                                                                                         (ASDF/SYSTEM:FIND-SYSTEM
                                                                                                                  "dreyeck/workflow/authoring"))))
                   (COMMON-LISP:FORMAT COMMON-LISP:T
                                       "Upstream-first page/loading and separate HyperSpec boundary passed.~%")
                   COMMON-LISP:T)
