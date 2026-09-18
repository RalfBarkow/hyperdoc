
(COMMON-LISP:DEFPACKAGE :DREYECK/HYPERSPEC
  (:USE :CL)
  (:EXPORT :HYPERSPEC-HTTP-ROOT :HYPERSPEC-ROOT-PATHNAME))

(COMMON-LISP:IN-PACKAGE :DREYECK/HYPERSPEC)

(COMMON-LISP:DEFPARAMETER DREYECK/HYPERSPEC::+HYPERSPEC-HTTP-ROOT+
  "/hyperspec/")

(COMMON-LISP:DEFPARAMETER
    DREYECK/HYPERSPEC::+HYPERSPEC-ROOT-ENVIRONMENT-VARIABLE+
  "HYPERDOC_HYPERSPEC_ROOT")

(COMMON-LISP:DEFPARAMETER DREYECK/HYPERSPEC::*HYPERSPEC-ROOT-OVERRIDE*
  :ENVIRONMENT
  "Test and diagnostic override for the HyperSpec filesystem root.

The value :ENVIRONMENT selects HYPERDOC_HYPERSPEC_ROOT. Any other value is
validated as the root designator itself; NIL therefore models a missing
configuration without changing process-global environment variables.")

(COMMON-LISP:DEFUN DREYECK/HYPERSPEC:HYPERSPEC-HTTP-ROOT ()
  "Return the same-origin HTTP root used for immutable HyperSpec content."
  DREYECK/HYPERSPEC::+HYPERSPEC-HTTP-ROOT+)

(COMMON-LISP:DEFUN DREYECK/HYPERSPEC::%CONFIGURED-HYPERSPEC-ROOT-DESIGNATOR ()
  (COMMON-LISP:IF (COMMON-LISP:EQ :ENVIRONMENT
                                  DREYECK/HYPERSPEC::*HYPERSPEC-ROOT-OVERRIDE*)
                  (UIOP/OS:GETENV
                   DREYECK/HYPERSPEC::+HYPERSPEC-ROOT-ENVIRONMENT-VARIABLE+)
                  DREYECK/HYPERSPEC::*HYPERSPEC-ROOT-OVERRIDE*))

(COMMON-LISP:DEFUN DREYECK/HYPERSPEC::%COMPLETE-HYPERSPEC-ROOT-P
                   (DREYECK/HYPERSPEC::ROOT)
  (COMMON-LISP:AND (UIOP/FILESYSTEM:DIRECTORY-EXISTS-P DREYECK/HYPERSPEC::ROOT)
                   (UIOP/FILESYSTEM:FILE-EXISTS-P
                    (COMMON-LISP:MERGE-PATHNAMES "Front/index.htm"
                                                 DREYECK/HYPERSPEC::ROOT))
                   (UIOP/FILESYSTEM:FILE-EXISTS-P
                    (COMMON-LISP:MERGE-PATHNAMES "Body/m_defmet.htm"
                                                 DREYECK/HYPERSPEC::ROOT))
                   (UIOP/FILESYSTEM:DIRECTORY-EXISTS-P
                    (COMMON-LISP:MERGE-PATHNAMES "Data/"
                                                 DREYECK/HYPERSPEC::ROOT))
                   (UIOP/FILESYSTEM:DIRECTORY-EXISTS-P
                    (COMMON-LISP:MERGE-PATHNAMES "Issues/"
                                                 DREYECK/HYPERSPEC::ROOT))))

(COMMON-LISP:DEFUN DREYECK/HYPERSPEC:HYPERSPEC-ROOT-PATHNAME ()
  "Return the validated HYPERDOC_HYPERSPEC_ROOT directory and a diagnostic.

The first value is NIL when the variable is absent, empty, invalid, or does
not contain the required HyperSpec 7.0 corpus. The second value then explains
the local configuration problem. This function performs filesystem checks
only and never consults an external HyperSpec service."
  (COMMON-LISP:LET ((DREYECK/HYPERSPEC::ROOT-DESIGNATOR
                     (DREYECK/HYPERSPEC::%CONFIGURED-HYPERSPEC-ROOT-DESIGNATOR)))
    (COMMON-LISP:COND
     ((COMMON-LISP:OR (COMMON-LISP:NULL DREYECK/HYPERSPEC::ROOT-DESIGNATOR)
                      (COMMON-LISP:AND
                       (COMMON-LISP:STRINGP DREYECK/HYPERSPEC::ROOT-DESIGNATOR)
                       (COMMON-LISP:ZEROP
                        (COMMON-LISP:LENGTH
                         DREYECK/HYPERSPEC::ROOT-DESIGNATOR))))
      (COMMON-LISP:VALUES COMMON-LISP:NIL
                          (COMMON-LISP:FORMAT COMMON-LISP:NIL "~A is not set."
                                              DREYECK/HYPERSPEC::+HYPERSPEC-ROOT-ENVIRONMENT-VARIABLE+)))
     (COMMON-LISP:T
      (COMMON-LISP:LET ((DREYECK/HYPERSPEC::ROOT
                         (COMMON-LISP:IGNORE-ERRORS
                          (UIOP/PATHNAME:ENSURE-DIRECTORY-PATHNAME
                           DREYECK/HYPERSPEC::ROOT-DESIGNATOR))))
        (COMMON-LISP:IF (COMMON-LISP:AND DREYECK/HYPERSPEC::ROOT
                                         (DREYECK/HYPERSPEC::%COMPLETE-HYPERSPEC-ROOT-P
                                          DREYECK/HYPERSPEC::ROOT))
                        (COMMON-LISP:VALUES DREYECK/HYPERSPEC::ROOT
                                            COMMON-LISP:NIL)
                        (COMMON-LISP:VALUES COMMON-LISP:NIL
                                            (COMMON-LISP:FORMAT COMMON-LISP:NIL
                                                                "~A does not contain a complete HyperSpec 7.0 corpus: ~A"
                                                                DREYECK/HYPERSPEC::+HYPERSPEC-ROOT-ENVIRONMENT-VARIABLE+
                                                                DREYECK/HYPERSPEC::ROOT-DESIGNATOR))))))))

(COMMON-LISP:DEFUN DREYECK/HYPERSPEC::%HYPERSPEC-ASSET-ROOT-PATHNAME
                   (DREYECK/HYPERSPEC::ROOT)
  "Return the lowercase CLOG route alias for the validated ROOT corpus."
  (COMMON-LISP:LET* ((DREYECK/HYPERSPEC::PARENT
                      (COMMON-LISP:MAKE-PATHNAME :NAME COMMON-LISP:NIL :TYPE
                                                 COMMON-LISP:NIL :DIRECTORY
                                                 (COMMON-LISP:BUTLAST
                                                  (COMMON-LISP:PATHNAME-DIRECTORY
                                                   DREYECK/HYPERSPEC::ROOT))
                                                 :DEFAULTS
                                                 DREYECK/HYPERSPEC::ROOT))
                     (DREYECK/HYPERSPEC::ASSET-ROOT
                      (COMMON-LISP:MERGE-PATHNAMES "hyperspec/"
                                                   DREYECK/HYPERSPEC::PARENT)))
    (COMMON-LISP:ASSERT
     (UIOP/FILESYSTEM:DIRECTORY-EXISTS-P DREYECK/HYPERSPEC::ASSET-ROOT))
    (COMMON-LISP:ASSERT
     (COMMON-LISP:EQUAL (COMMON-LISP:TRUENAME DREYECK/HYPERSPEC::ROOT)
                        (COMMON-LISP:TRUENAME DREYECK/HYPERSPEC::ASSET-ROOT)))
    DREYECK/HYPERSPEC::ASSET-ROOT))

(COMMON-LISP:DEFUN DREYECK/HYPERSPEC::%CONFIGURE-LOCAL-HYPERSPEC-URL-TEMPLATE
                   ()
  (COMMON-LISP:SETF HTML-INSPECTOR-VIEWS/STANDARD::*HYPERSPEC-URL-TEMPLATE*
                      (COMMON-LISP:CONCATENATE 'COMMON-LISP:STRING
                                               DREYECK/HYPERSPEC::+HYPERSPEC-HTTP-ROOT+
                                               "Body/~A.htm")))

(COMMON-LISP:EVAL-WHEN (:LOAD-TOPLEVEL :EXECUTE)
  (DREYECK/HYPERSPEC::%CONFIGURE-LOCAL-HYPERSPEC-URL-TEMPLATE))

(COMMON-LISP:DEFMETHOD HTML-INSPECTOR-VIEWS:👀CONTENT
                       (
                        (DREYECK/HYPERSPEC::PAGE
                         HTML-INSPECTOR-VIEWS/STANDARD::HYPERSPEC-PAGE))
  (COMMON-LISP:MULTIPLE-VALUE-BIND
      (DREYECK/HYPERSPEC::ROOT DREYECK/HYPERSPEC::CONFIGURATION-PROBLEM)
      (DREYECK/HYPERSPEC:HYPERSPEC-ROOT-PATHNAME)
    (COMMON-LISP:IF DREYECK/HYPERSPEC::ROOT
                    (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE "Content" :PRIORITY
                                                    1
                                                    (HTML-INSPECTOR-VIEWS:ADD-ASSET-PATH
                                                     DREYECK/HYPERSPEC::+HYPERSPEC-HTTP-ROOT+
                                                     (DREYECK/HYPERSPEC::%HYPERSPEC-ASSET-ROOT-PATHNAME
                                                      DREYECK/HYPERSPEC::ROOT))
                                                    (HTML-INSPECTOR-VIEWS:HTML
                                                      (:IFRAME :SRC
                                                       (COMMON-LISP:SLOT-VALUE
                                                        DREYECK/HYPERSPEC::PAGE
                                                        'HTML-INSPECTOR-VIEWS/STANDARD::URL)
                                                       :TITLE
                                                       (HTML-INSPECTOR-VIEWS:TEXT-REPRESENTATION
                                                        DREYECK/HYPERSPEC::PAGE)
                                                       :STYLE
                                                       "border:none;width:100%;height:100%")))
                    (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE
                                                    "HyperSpec not configured"
                                                    :PRIORITY 1
                                                    (HTML-INSPECTOR-VIEWS:HTML
                                                      (:DIV :CLASS
                                                       "hyperspec-not-configured"
                                                       (:H2
                                                        (CL-WHO:ESC
                                                         "HyperSpec not configured"))
                                                       (:P
                                                        (CL-WHO:ESC
                                                         DREYECK/HYPERSPEC::CONFIGURATION-PROBLEM))
                                                       (:P
                                                        (CL-WHO:ESC
                                                         "HyperDoc does not fall back to an external HyperSpec."))))))))
