
(IN-PACKAGE :DREYECK/TOPICMAP/TESTS)

(defun tala-reading-widget-references (view)
  "The references of VIEW that are executable page widgets.
A page link retains the page object and an EXPR link retains the object
it names, so VIEW-REFERENCES answers a wider question than \"which
widgets does this page have\". Both kinds were observed on the TALA
reading pages; only a view is a widget."
  (remove-if-not (lambda (ref) (typep (cdr ref) 'html-inspector-views:view))
                 (html-inspector-views:view-references view)))

(DEFUN RUN-TALA-READING-TESTS NIL
       (LET*
             ((BOOK
                    (HYPERBOOK:FIND-HYPERBOOK "dreyeck/topicmap/tala/reading"
                                              :SIGNAL-ERROR? T))
              (ROOT
                    (ASDF/SYSTEM:SYSTEM-SOURCE-DIRECTORY
                                                         "dreyeck/topicmap/tala/reading"))
              (SOURCE
                      (MERGE-PATHNAMES "dreyeck/src/topicmap-tala-reading.lisp"
                                       ROOT))
              (CODE (HTML-INSPECTOR-VIEWS/STANDARD:PARSE-LISP-CODE SOURCE))
              (FORMS
                     (MAPCAR (FUNCTION HTML-INSPECTOR-VIEWS/STANDARD:S-EXP)
                             (HTML-INSPECTOR-VIEWS/STANDARD:TOP-LEVEL-FORMS-OF
                                                                               CODE)))
              (EXAMPLES
                        (LOOP FOR FORM IN FORMS WHEN
                              (AND (CONSP FORM)
                                   (EQ (FIRST FORM)
                                       (QUOTE HYPERDOC:DEFEXAMPLE)))
                              COLLECT (SECOND FORM))))
             (ASSERT (= 12 (LENGTH EXAMPLES)))
             (ASSERT (EVERY (FUNCTION FBOUNDP) EXAMPLES))
             (ASSERT
                     (= 1
                        (COUNT "dreyeck/topicmap/tala/reading"
                               (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*)
                               :KEY (FUNCTION HYPERBOOK:ID-OF) :TEST
                               (FUNCTION STRING=))))
             (PROGN (HYPERDOC::ENSURE-PAGES-LOADED BOOK)
                    (ASSERT
                            (HYPERBOOK:FIND-PAGE BOOK
                                                 "Executable TALA reading examples"
                                                 :SIGNAL-ERROR? T))
                    (ASSERT (NOT (GETHASH "" (HYPERDOC:PAGES-OF BOOK)))))
             (LET*
                   ((PAGE
                          (HYPERBOOK:FIND-PAGE BOOK
                                               "Reading TALA as a Layout Layer"
                                               :SIGNAL-ERROR? T))
                    (VIEW
                          (FIND "Content" (HTML-INSPECTOR-VIEWS:ALL-VIEWS PAGE)
                                :KEY (FUNCTION HTML-INSPECTOR-VIEWS:VIEW-TITLE)
                                :TEST (FUNCTION STRING=)))
                    (HTML
                          (CONCATENATE (QUOTE STRING)
                                       (HTML-INSPECTOR-VIEWS:VIEW-HTML VIEW)
                                       (FORMAT NIL "~{~A~}"
                                               (MAPCAR
                                                       (LAMBDA (REF)
                                                               (HTML-INSPECTOR-VIEWS:VIEW-HTML
                                                                                               (CDR
                                                                                                    REF)))
                                                       (tala-reading-widget-references VIEW))))))
                   (ASSERT
                           (SEARCH "d5a51743b6d5c00f1ec6f8340003f5d5a6ba4eda"
                                   HTML))
                   (DOLIST (EXAMPLE EXAMPLES)
                           (ASSERT
                                   (SEARCH (SYMBOL-NAME EXAMPLE) HTML :TEST
                                           (FUNCTION CHAR-EQUAL))))
                   (PROGN (ASSERT (SEARCH "inspector-action" HTML))
                          (LET
                               ((WIDGETS
                                         (MAPCAR (FUNCTION CDR)
                                                 (tala-reading-widget-references VIEW)))
                                (CLICKS 0))
                               (ASSERT (= 12 (LENGTH WIDGETS)))
                               (DOLIST (WIDGET WIDGETS)
                                       (LET
                                            ((ACTIONS
                                                      (REMOVE-IF-NOT
                                                                     (LAMBDA
                                                                             (REF)
                                                                             (TYPEP
                                                                                    (CDR
                                                                                         REF)
                                                                                    (QUOTE
                                                                                           HTML-INSPECTOR-VIEWS:THUNK)))
                                                                     (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES
                                                                                                           WIDGET))))
                                            (ASSERT (= 1 (LENGTH ACTIONS)))
                                            (ASSERT
                                                    (HTML-INSPECTOR-VIEWS:EVAL-THUNK
                                                                                     (CDAR
                                                                                           ACTIONS)))
                                            (INCF CLICKS)))
                               (ASSERT (= 12 CLICKS))))
                   (ASSERT
                           (NOTANY
                                   (LAMBDA (REF)
                                           (TYPEP (CDR REF)
                                                  (QUOTE
                                                         DREYECK/TOPICMAP/TALA:TALA-RENDERING)))
                                   (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES
                                                                         VIEW))))
             (DOLIST (EXAMPLE EXAMPLES)
                     (LET ((VALUE (FUNCALL EXAMPLE))) (ASSERT VALUE)
                          (CASE (INTERN (SYMBOL-NAME EXAMPLE) :KEYWORD)
                                (:READING-WORKSPACE
                                                    (ASSERT
                                                            (TYPEP VALUE
                                                                   (QUOTE
                                                                          DREYECK/TOPICMAP:TOPICMAP-WORKSPACE))))
                                (:READING-PROJECTION
                                                     (ASSERT
                                                             (TYPEP VALUE
                                                                    (QUOTE
                                                                           DREYECK/TOPICMAP:TOPICMAP-PROJECTION))))
                                (:READING-ID-MAPPING
                                                     (ASSERT
                                                             (EVERY
                                                                    (LAMBDA
                                                                            (PAIR)
                                                                            (EQUAL
                                                                                   (FIRST
                                                                                          PAIR)
                                                                                   (SECOND
                                                                                           PAIR)))
                                                                    (GETF VALUE
                                                                          :ROUNDTRIPS))))
                                (:READING-LAYOUT-INPUT
                                                       (ASSERT
                                                               (TYPEP VALUE
                                                                      (QUOTE
                                                                             DREYECK/TOPICMAP/TALA:TALA-INPUT))))
                                (:READING-LAYOUT-RESULT
                                                        (ASSERT
                                                                (TYPEP VALUE
                                                                       (QUOTE
                                                                              DREYECK/TOPICMAP/TALA:TALA-RENDERING))))
                                (:READING-GEOMETRY
                                                   (ASSERT
                                                           (GETF VALUE
                                                                 :TOPICS))
                                                   (ASSERT
                                                           (GETF VALUE
                                                                 :ASSOCIATIONS)))
                                (:READING-INVARIANT-REPORT
                                                           (ASSERT
                                                                   (EQ :PASSED
                                                                       (GETF
                                                                             VALUE
                                                                             :STATUS))))
                                (:READING-COMPARISON
                                                     (CHECK-TALA-COMPARISON-NAVIGATION
                                                                                       VALUE))
                                (:READING-SOURCE-WORKSPACE
                                                           (ASSERT
                                                                   (TYPEP VALUE
                                                                          (QUOTE
                                                                                 DREYECK/TOPICMAP:TOPICMAP-WORKSPACE)))
                                                           (ASSERT
                                                                   (= 4
                                                                      (LENGTH
                                                                              (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                                                                                                                                    (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-OF
                                                                                                                                                                             VALUE)))))))))
             (FORMAT T
                     "TALA reading tests passed: source-backed page and 12 real executable examples.~%")
             T))
