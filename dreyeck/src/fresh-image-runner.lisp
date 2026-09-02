
(defpackage #:dreyeck/fresh-image-runner
  (:use #:cl)
  (:export #:run-fresh-asdf-test))

(in-package #:dreyeck/fresh-image-runner)

(defun current-lisp-program ()
  (or (uiop/image:argv0) (first sb-ext:*posix-argv*)
      (error "Cannot determine the current SBCL program.")))


(DEFUN DREYECK/FRESH-IMAGE-RUNNER:RUN-FRESH-ASDF-TEST
       (DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-DESIGNATOR
        &KEY DREYECK/FRESH-IMAGE-RUNNER::ADDITIONAL-ASDS PACKAGE-NAME
        (DREYECK/FRESH-IMAGE-RUNNER::FUNCTION-NAME "RUN-TESTS")
        (DREYECK/FRESH-IMAGE-RUNNER::MARKER "DREYECK-FRESH-ASDF-TEST-PASSED"))
  (LET ((DREYECK/FRESH-IMAGE-RUNNER::SYSTEM
         (ASDF/SYSTEM:FIND-SYSTEM DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-DESIGNATOR
                                  NIL)))
    (UNLESS DREYECK/FRESH-IMAGE-RUNNER::SYSTEM
      (ERROR "Unknown ASDF system ~S."
             DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-DESIGNATOR))
    (LET* ((DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-NAME
            (ASDF/COMPONENT:COMPONENT-NAME DREYECK/FRESH-IMAGE-RUNNER::SYSTEM))
           (DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-ASD
            (ASDF/SYSTEM:SYSTEM-SOURCE-FILE
             DREYECK/FRESH-IMAGE-RUNNER::SYSTEM))
           (DREYECK/FRESH-IMAGE-RUNNER::EFFECTIVE-PACKAGE-NAME
            (OR PACKAGE-NAME
                (STRING-UPCASE DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-NAME)))
           (DREYECK/FRESH-IMAGE-RUNNER::PROGRAM
            (DREYECK/FRESH-IMAGE-RUNNER::CURRENT-LISP-PROGRAM))
           (DREYECK/FRESH-IMAGE-RUNNER::ASDS
            (REMOVE-DUPLICATES
             (CONS DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-ASD
                   DREYECK/FRESH-IMAGE-RUNNER::ADDITIONAL-ASDS)
             :TEST #'EQUAL))
           (DREYECK/FRESH-IMAGE-RUNNER::CHILD-FORM
            (ECLECTOR.READER:QUASIQUOTE
             (PROGN
              (REQUIRE :ASDF)
              (DOLIST
                  (DREYECK/FRESH-IMAGE-RUNNER::ASD
                   '(ECLECTOR.READER:UNQUOTE DREYECK/FRESH-IMAGE-RUNNER::ASDS))
                (ASDF/FIND-SYSTEM:LOAD-ASD DREYECK/FRESH-IMAGE-RUNNER::ASD))
              (ASDF/OPERATE:LOAD-SYSTEM
               (ECLECTOR.READER:UNQUOTE
                DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-NAME))
              (LET* ((PACKAGE
                      (FIND-PACKAGE
                       (ECLECTOR.READER:UNQUOTE
                        DREYECK/FRESH-IMAGE-RUNNER::EFFECTIVE-PACKAGE-NAME)))
                     (DREYECK/FRESH-IMAGE-RUNNER::RUNNER-SYMBOL
                      (AND PACKAGE
                           (FIND-SYMBOL
                            (ECLECTOR.READER:UNQUOTE
                             DREYECK/FRESH-IMAGE-RUNNER::FUNCTION-NAME)
                            PACKAGE)))
                     (DREYECK/FRESH-IMAGE-RUNNER::RUNNER
                      (AND DREYECK/FRESH-IMAGE-RUNNER::RUNNER-SYMBOL
                           (FBOUNDP DREYECK/FRESH-IMAGE-RUNNER::RUNNER-SYMBOL)
                           (SYMBOL-FUNCTION
                            DREYECK/FRESH-IMAGE-RUNNER::RUNNER-SYMBOL))))
                (UNLESS DREYECK/FRESH-IMAGE-RUNNER::RUNNER
                  (ERROR "Fresh child cannot resolve ~A::~A."
                         (ECLECTOR.READER:UNQUOTE
                          DREYECK/FRESH-IMAGE-RUNNER::EFFECTIVE-PACKAGE-NAME)
                         (ECLECTOR.READER:UNQUOTE
                          DREYECK/FRESH-IMAGE-RUNNER::FUNCTION-NAME)))
                (LET ((DREYECK/FRESH-IMAGE-RUNNER::RESULT
                       (FUNCALL DREYECK/FRESH-IMAGE-RUNNER::RUNNER)))
                  (UNLESS
                      (OR (EQ DREYECK/FRESH-IMAGE-RUNNER::RESULT T)
                          (AND (LISTP DREYECK/FRESH-IMAGE-RUNNER::RESULT)
                               (EQ :PASSED
                                   (GETF DREYECK/FRESH-IMAGE-RUNNER::RESULT
                                         :STATUS))))
                    (ERROR "Fresh test failed: ~S"
                           DREYECK/FRESH-IMAGE-RUNNER::RESULT))
                  (FORMAT T "~&~A~%"
                          (ECLECTOR.READER:UNQUOTE
                           DREYECK/FRESH-IMAGE-RUNNER::MARKER))
                  (FINISH-OUTPUT))))))
           (DREYECK/FRESH-IMAGE-RUNNER::COMMAND
            (LIST DREYECK/FRESH-IMAGE-RUNNER::PROGRAM "--noinform"
                  "--non-interactive" "--eval"
                  "(progn (require :asdf) (unless (find-package \"DREYECK/FRESH-IMAGE-RUNNER\") (make-package \"DREYECK/FRESH-IMAGE-RUNNER\" :use '(\"CL\"))))"
                  "--eval"
                  (PRIN1-TO-STRING DREYECK/FRESH-IMAGE-RUNNER::CHILD-FORM))))
      (ASSERT DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-ASD)
      (ASSERT
       (AND (STRINGP DREYECK/FRESH-IMAGE-RUNNER::PROGRAM)
            (PLUSP (LENGTH DREYECK/FRESH-IMAGE-RUNNER::PROGRAM))))
      (MULTIPLE-VALUE-BIND
          (DREYECK/FRESH-IMAGE-RUNNER::OUTPUT
           DREYECK/FRESH-IMAGE-RUNNER::ERROR-OUTPUT
           DREYECK/FRESH-IMAGE-RUNNER::STATUS)
          (UIOP/RUN-PROGRAM:RUN-PROGRAM DREYECK/FRESH-IMAGE-RUNNER::COMMAND
                                        :OUTPUT :STRING :ERROR-OUTPUT :OUTPUT
                                        :IGNORE-ERROR-STATUS T)
        (DECLARE (IGNORE DREYECK/FRESH-IMAGE-RUNNER::ERROR-OUTPUT))
        (UNLESS
            (AND (ZEROP DREYECK/FRESH-IMAGE-RUNNER::STATUS)
                 (STRINGP DREYECK/FRESH-IMAGE-RUNNER::OUTPUT)
                 (SEARCH DREYECK/FRESH-IMAGE-RUNNER::MARKER
                         DREYECK/FRESH-IMAGE-RUNNER::OUTPUT :TEST #'CHAR=))
          (ERROR "Fresh ASDF test failed for ~S (status ~S).~%~A"
                 DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-NAME
                 DREYECK/FRESH-IMAGE-RUNNER::STATUS
                 DREYECK/FRESH-IMAGE-RUNNER::OUTPUT))
        (LIST :STATUS :PASSED :SYSTEM DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-NAME
              :SYSTEM-ASD DREYECK/FRESH-IMAGE-RUNNER::SYSTEM-ASD
              :ADDITIONAL-ASDS DREYECK/FRESH-IMAGE-RUNNER::ADDITIONAL-ASDS
              :PACKAGE-NAME DREYECK/FRESH-IMAGE-RUNNER::EFFECTIVE-PACKAGE-NAME
              :FUNCTION-NAME DREYECK/FRESH-IMAGE-RUNNER::FUNCTION-NAME :PROGRAM
              DREYECK/FRESH-IMAGE-RUNNER::PROGRAM :MARKER
              DREYECK/FRESH-IMAGE-RUNNER::MARKER :CHILD-STATUS
              DREYECK/FRESH-IMAGE-RUNNER::STATUS :MARKER-OBSERVED-P T)))))
