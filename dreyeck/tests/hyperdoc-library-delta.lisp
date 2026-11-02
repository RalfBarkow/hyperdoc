
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

;;; RalfBarkow/hyperdoc#13: the one deliberate change to a form of a hyperbook-fedwiki file that this contract meets after +PREVIOUS+.
;;;
;;; INITIALIZE-FEDWIKI keeps, as the site's status, the operational failures that belong to that one site. The resolver's answers "try again
;;; later" (EAI_AGAIN: no network, or failing name servers) and "cannot recover" were not among them, so such a condition left the site's
;;; thread and ended a process that runs without a debugger, as the packaged hyperdoc-catalog does. The change adds exactly
;;; USOCKET:NS-TRY-AGAIN-ERROR and USOCKET:NS-NO-RECOVERY-ERROR to the handler's list of conditions, next to the USOCKET:NS-HOST-NOT-FOUND-ERROR
;;; that was there. They are the other two conditions that the SBCL backend of usocket raises for a host name. USOCKET:NS-ERROR is not used:
;;; it would also admit NS-UNKNOWN-ERROR, which that backend never raises and which cannot even be printed. Connection failures
;;; (USOCKET:SOCKET-ERROR and its subclasses) are a different failure and not part of this change.
;;; Candidate upstream contribution: it changes nothing for a reachable host, and adds two entries to an existing list.
;;;
;;; This check is relative to +PREVIOUS+ and nothing else. The form is the same at +PREVIOUS+ and at the base of the change (0a7d4de), so its
;;; whole difference from +PREVIOUS+ is this change. It accepts no other difference: those that already exist in the four FedWiki files and in
;;; hyperbook.asd stay what they are, and the assertions below that name them still fail until they are reviewed (docs/fedwiki-dns-failure).

(defparameter +name-resolution-conditions-added+ '(usocket:ns-try-again-error usocket:ns-no-recovery-error))

(defun form-name (form)
  (and (consp form) (symbolp (second form)) (symbol-name (second form))))

(defun count-atoms (atoms tree)
  "How many times one of ATOMS occurs in TREE."
  (cond ((consp tree) (+ (count-atoms atoms (car tree)) (count-atoms atoms (cdr tree))))
        ((member tree atoms) 1)
        (t 0)))

(defun without-atoms (atoms tree)
  "TREE with every element that is one of ATOMS left out of its list."
  (cond ((atom tree) tree)
        ((member (car tree) atoms) (without-atoms atoms (cdr tree)))
        (t (cons (without-atoms atoms (car tree)) (without-atoms atoms (cdr tree))))))

(defun handler-clause-type-specifiers (form)
  "The type specifier (first element) of every clause of every HANDLER-CASE in FORM."
  (let ((found '()))
    (labels ((walk (x)
               (when (consp x)
                 (when (and (symbolp (car x)) (string= "HANDLER-CASE" (symbol-name (car x))))
                   (dolist (clause (cddr x)) (when (consp clause) (push (car clause) found))))
                 (loop for rest on x while (consp rest) do (walk (car rest))))))
      (walk form))
    (nreverse found)))

(defun check-initialize-fedwiki-dns-change (root)
  "INITIALIZE-FEDWIKI equals its form at +PREVIOUS+ plus exactly the two conditions, each once, nothing else, and where they stand: in the
type list of the handler clause that already names USOCKET:NS-HOST-NOT-FOUND-ERROR (a count and a difference could not tell that apart
from the same symbols moved to another element of the form)."
  (let* ((path "hyperbook-fedwiki/fedwiki.lisp")
         (before (find "INITIALIZE-FEDWIKI" (forms-at root +previous+ path) :key #'form-name :test #'equal))
         (after (find "INITIALIZE-FEDWIKI" (forms-at root nil path) :key #'form-name :test #'equal))
         (added +name-resolution-conditions-added+))
    (assert (and before after) () "INITIALIZE-FEDWIKI is missing from ~A, now or at +PREVIOUS+." path)
    (assert (zerop (count-atoms added before)) () "+PREVIOUS+ already has ~S: this change is stale." added)
    (dolist (condition added)
      (assert (= 1 (count-atoms (list condition) after)) ()
              "INITIALIZE-FEDWIKI must name ~S exactly once, in its handler; it names it ~D times."
              condition (count-atoms (list condition) after)))
    (assert (source-equal (without-atoms added after) before) ()
            "INITIALIZE-FEDWIKI differs from its form at +PREVIOUS+ in more than the two name-resolution conditions.")
    (assert (some (lambda (specifier)
                    (and (consp specifier) (symbolp (car specifier)) (string= "OR" (symbol-name (car specifier)))
                         (member 'usocket:ns-host-not-found-error specifier)
                         (every (lambda (condition) (member condition specifier)) added)))
                  (handler-clause-type-specifiers after))
            () "The two name-resolution conditions are not in the type list of the handler clause that names USOCKET:NS-HOST-NOT-FOUND-ERROR.")
    (format t "~&INITIALIZE-FEDWIKI-DNS-CHANGE: INITIALIZE-FEDWIKI equals its form at +PREVIOUS+ (~A) plus exactly ~{~(~A~)~^ and ~}.~%"
            (subseq +previous+ 0 9) added))
  t)

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/LIBRARY-TESTS:RUN-TESTS NIL
                   (DREYECK/HYPERDOC/LIBRARY-TESTS::CHECK-FEDWIKI-IMAGE-COMPATIBILITY)
                   (DREYECK/HYPERDOC/LIBRARY-TESTS::CHECK-INITIALIZE-FEDWIKI-DNS-CHANGE
                    (ASDF/SYSTEM:SYSTEM-SOURCE-DIRECTORY (ASDF/SYSTEM:FIND-SYSTEM "dreyeck")))
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
                                                                                                                                                             DREYECK/HYPERDOC/LIBRARY-TESTS::LOCAL
                                                                                                                                                             (DREYECK/HYPERDOC/LIBRARY-TESTS::FORMS-AT
                                                                                                                                                                                                       DREYECK/HYPERDOC/LIBRARY-TESTS::ROOT
                                                                                                                                                                                                       DREYECK/HYPERDOC/LIBRARY-TESTS::+PREVIOUS+
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
