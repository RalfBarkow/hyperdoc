;;;; Following One Node Message

(IN-PACKAGE #:DREYECK/NESTED-ACTIONS)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Two Relations Hidden in One Nest" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Nested Actions in Solo" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "What Does a Nested Action Inherit?" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(DEFUN READ-MESSAGE-JSON (FILE)
  (WITH-OPEN-FILE
      (IN
       (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME "dreyeck/nested-actions/reading"
                                             FILE)
       :EXTERNAL-FORMAT :UTF-8)
    (SHASHT:READ-JSON* :STREAM IN :SINGLE-VALUE T :OBJECT-FORMAT :HASH-TABLE
                       :HASH-TABLE-TEST 'EQUAL :ARRAY-FORMAT :VECTOR
                       :TRUE-VALUE T :FALSE-VALUE NIL :NULL-VALUE NIL)))

(DEFCLASS MESSAGE-SOURCE NIL
          ((METADATA :INITARG :METADATA :READER SOURCE-METADATA)
           (TEXT :INITARG :TEXT :READER SOURCE-TEXT)
           (FILE :INITARG :FILE :READER SOURCE-FILE))
          (:DOCUMENTATION
           "Exact supplied or revision-backed source, with its own warrant and boundary."))

(HYPERDOC:DEFEXAMPLE MESSAGE-SOURCE-OBSERVATIONS
  "Read six retained source excerpts; verify their hashes before exposing their code."
  (MAP 'LIST
       (LAMBDA (METADATA)
         (LET* ((FILE
                 (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME
                  "dreyeck/nested-actions/reading" (GETHASH "file" METADATA)))
                (DIGEST
                 (IRONCLAD:BYTE-ARRAY-TO-HEX-STRING
                  (IRONCLAD:DIGEST-FILE :SHA256 FILE))))
           (UNLESS (EQUAL DIGEST (GETHASH "sha256" METADATA))
             (ERROR "Source observation hash mismatch: ~A" FILE))
           (MAKE-INSTANCE 'MESSAGE-SOURCE :METADATA METADATA :FILE FILE :TEXT
                          (UIOP/STREAM:READ-FILE-STRING FILE))))
       (READ-MESSAGE-JSON "dreyeck/nested-actions/sources/provenance.json")))

(HYPERDOC:DEFEXAMPLE PRODUCER-SOURCE
  (FIRST (MESSAGE-SOURCE-OBSERVATIONS)))

(DEFCLASS MESSAGE-WITNESS NIL
          ((CAPTURE :INITARG :CAPTURE :READER WITNESS-CAPTURE)
           (SOURCES :INITARG :SOURCES :READER WITNESS-SOURCES))
          (:DOCUMENTATION
           "Recorded native window/opener delivery to retained LISTEN, ending at an explicit revision gap."))

(HYPERDOC:DEFEXAMPLE EMITTED-MESSAGE-WITNESS
  "Inspect a recorded native-browser run of the exact supplied producer and retained LISTEN.
This reads a capture; it does not install listeners in the Catalog or run Ward's newer nested implementation."
  (MAKE-INSTANCE 'MESSAGE-WITNESS :CAPTURE
                 (READ-MESSAGE-JSON
                  "dreyeck/nested-actions/message-witness.json")
                 :SOURCES (MESSAGE-SOURCE-OBSERVATIONS)))

(DEFUN WITNESS-STAGE (WITNESS KEY &OPTIONAL (EVENT-INDEX 0))
  "The exact structured stage in one received event, or the shared emitter descriptor."
  (LET ((CAPTURE (WITNESS-CAPTURE WITNESS)))
    (IF (EQUAL KEY "emitter")
        (GETHASH KEY CAPTURE)
        (GETHASH KEY (AREF (GETHASH "events" CAPTURE) EVENT-INDEX)))))

(HYPERDOC:DEFEXAMPLE WARD-PROPAGATION-EVIDENCE
  (LIST :ORIGIN :WARD-FOLLOW-UP-TASK :REPORTS
        (LIST
         (LIST :STATUS :AUTHOR-REPORTED :CLAIM
               "LISTEN becomes operational as soon as it is rendered.")
         (LIST :STATUS :AUTHOR-REPORTED :CLAIM
               "A subsequent CLICK MESSAGE can be heard to the left, contrary to usual rightward or subordinate communication.")
         (LIST :STATUS :AUTHOR-REPORTED :CLAIM
               "Event broadcast forward and backward across the lineup is an intentional historical feature.")
         (LIST :STATUS :AUTHOR-REPORTED :CLAIM
               "This mixes scoped/subordinate execution and broadcast behavior."))
        :SCOPED-EMITTER
        (LIST :STATUS :DESIGN-PROPOSAL :REPLACEMENT-FOR "window" :MEANING
              :EVENT-EMITTER-REACH :IMPLEMENTED-P NIL :CLAIM
              "An alternative event emitter could provide LISTEN scope."
              :VARIABLE-SCOPE :NOT-ESTABLISHED)
        :REMAINING-GAP
        (LIST :STATUS :OPEN :TRANSITION
              :RECEIVED-NODE-MESSAGE-TO-NESTED-ACTION-INPUT
              :CURRENT-REPORT-LOOKUP :NOT-ESTABLISHED :RETAINED-REPORT-LOOKUP
              "state[args[0] || 'temperature']; REPORT title reads state.title"
              :RETAINED-LISTEN
              "Registers and filters on window; counts events; does not construct nested input.")))

(V:DEFVIEW MESSAGE-SOURCE-VIEW (SOURCE MESSAGE-SOURCE)
           (V:HTML-VIEW :TITLE "Source evidence" :PRIORITY 1
                        (V:HTML
                          (:P
                           (CL-WHO:ESC
                            (GETHASH "role" (SOURCE-METADATA SOURCE)))
                           " — "
                           (CL-WHO:ESC
                            (GETHASH "status" (SOURCE-METADATA SOURCE))))
                          (:P
                           (V:OBJECT-REF (SOURCE-METADATA SOURCE) :DISPLAY
                                         "Revision, coordinates and warrant")
                           " · "
                           (V:OBJECT-REF (SOURCE-FILE SOURCE) :DISPLAY
                                         "Retained source file"))
                          (:PRE (CL-WHO:ESC (SOURCE-TEXT SOURCE)))
                          (:P
                           (CL-WHO:ESC
                            (GETHASH "limitation" (SOURCE-METADATA SOURCE))))
                          (:P
                           (V:OBJECT-REF (EMITTED-MESSAGE-WITNESS) :DISPLAY
                                         "Follow the recorded emitted message"
                                         :SELECT "Message path"))
                          (:P
                           (V:OBJECT-REF
                            (HYPERDOC:PAGE "Two Relations Hidden in One Nest"
                                           :HYPERBOOK
                                           "dreyeck/nested-actions/reading")
                            :DISPLAY "Read the two relations" :SELECT
                            "Content")))))

(V:DEFVIEW MESSAGE-PATH-VIEW (WITNESS MESSAGE-WITNESS)
           (V:HTML-VIEW :TITLE "Message path" :PRIORITY 1
                        (V:HTML
                          (:P
                           "Recorded native popup/opener experiment. The supplied producer and retained LISTEN execute; the current nested-input handoff remains unestablished.")
                          (:P
                           (V:OBJECT-REF (WITNESS-CAPTURE WITNESS) :DISPLAY
                                         "Complete capture, two events and fixture limits"))
                          (:TABLE :CLASS "inspector-table"
                           (DOLIST
                               (ENTRY
                                '(("producer"
                                   "Producer props (synthetic sample)")
                                  ("emittedMessage"
                                   "Emitted publishSourceData message")
                                  ("emitter"
                                   "Native window/opener message channel")
                                  ("reception"
                                   "Native MessageEvent observation")
                                  ("listeners"
                                   "Retained LISTEN handlers and counts")
                                  ("listenerOutput"
                                   "Retained LISTEN produces no nested input")
                                  ("nestedInput"
                                   "Current nested action input: gap")
                                  ("reportLookupTarget"
                                   "Current REPORT lookup target: gap")))
                             (V:HTML
                               (:TR (:TD (CL-WHO:ESC (SECOND ENTRY)))
                                (:TD
                                 (V:OBJECT-REF
                                  (WITNESS-STAGE WITNESS (FIRST ENTRY))
                                  :DISPLAY (FIRST ENTRY)))))))
                          (:P
                           (V:OBJECT-REF
                            (WITNESS-STAGE WITNESS "receivedMessage") :DISPLAY
                            "Received node payload"))
                          (:P
                           (V:OBJECT-REF (WITNESS-SOURCES WITNESS) :DISPLAY
                                         "Actual supplied and retained source objects"))
                          (:P
                           (V:OBJECT-REF (TOPIC-WORKSPACE "witness") :DISPLAY
                                         "Follow this stage into the Topicmap"
                                         :SELECT "Topicmap"))
                          (:P
                           (V:OBJECT-REF
                            (HYPERDOC:PAGE "Two Relations Hidden in One Nest"
                                           :HYPERBOOK
                                           "dreyeck/nested-actions/reading")
                            :DISPLAY "Return to the reading" :SELECT
                            "Content")))))
