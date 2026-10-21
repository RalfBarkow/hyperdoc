;;;; The Two-Page Example, Stage by Stage

(in-package #:dreyeck/traverse)

(hyperdoc:see
  (hyperdoc:page "From PageFold to Discourse Graph" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "From Git Revision to Nix Package" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "How TRAVERSE Enters Mech" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "What the Deployment Proves" :hyperbook "dreyeck/traverse/reading"))

(defclass example-run ()
  ((reading :initarg :reading :reader run-reading)
   (record :initarg :record :reader run-record)
   (stages :initarg :stages :reader run-stages))
  (:documentation "The retained Node run of the two-page fixture through the tested bundle, split into stages."))

(defclass example-stage ()
  ((name :initarg :name :reader stage-name)
   (value :initarg :value :reader stage-value)
   (source :initarg :source :initform nil :reader stage-source)
   (status :initarg :status :reader stage-status
           :documentation ":observed (present in the input), :derived (computed by the named source),
:handed-over (captured at the SOLO boundary) or :not-established.")
   (note :initarg :note :reader stage-note)))

(defun stage-of (run name)
  (or (find name (run-stages run) :key #'stage-name :test #'equal)
      (error "No example stage ~S" name)))

(defun json-equal (a b)
  (equal (with-output-to-string (s) (shasht:write-json a s))
         (with-output-to-string (s) (shasht:write-json b s))))

(defun check-run (value)
  "The retained run must show what the reading claims; otherwise loading fails."
  (let* ((stages (gethash "stages" value))
         (edges (gethash "edges" (gethash "extract" stages)))
         (traversed (gethash "traverse" stages))
         (graph (gethash "presentGraph" stages))
         (batch (gethash "data" (aref (gethash "solo" stages) 0)))
         (handed (gethash "graph" (aref (gethash "aspects" (aref (gethash "sources" batch) 0)) 0))))
    (unless (and (zerop (gethash "networkAttempts" value))
                 (equal "19b14c31c62f0ce92c4ecaacf78477b230d83f0fdefea48033128cb575190efd"
                        (gethash "sha256" (gethash "bundle" value)))
                 (= 1 (length edges))
                 (equal "claim" (gethash "role" (aref edges 0)))
                 (equal "companion.example+question" (gethash "fromId" (aref edges 0)))
                 (equal "companion.example+claim-a" (gethash "toId" (aref edges 0)))
                 (= 1 (length traversed))
                 (= 2 (length (gethash "nodes" graph)))
                 (equal "claim" (gethash "type" (aref (gethash "rels" graph) 0)))
                 (json-equal graph handed))
      (error "The retained example run does not show the expected relation"))
    value))

(hyperdoc:defexample two-page-example
  "Two Wiki pages, a Claims pagefold and one link, through EXTRACT, resolveEdges, traverse, presentGraph and SOLO."
  (let* ((reading (retained-reading))
         (record (record-of reading "example-run.json"))
         (value (check-run (record-value record)))
         (stages (gethash "stages" value))
         (observed (gethash "observedLink" stages)))
    (make-instance
     'example-run :reading reading :record record
     :stages
     (list
      (make-instance 'example-stage :name "observed link" :value observed :status :observed
                     :note "The story item text contains [[Claim A]]; it stands after a pagefold whose text is Claims. Both are page content, not interpretation.")
      (make-instance 'example-stage :name "EXTRACT" :value (gethash "extract" stages) :status :derived
                     :source (source-by-key reading "composition:extract_edges_from_story")
                     :note "EXTRACT derives the role claim from the fold label (Claims, canonicalized by canonicalize_fold) and names the target site+slug. It does not record the story item that holds the link.")
      (make-instance 'example-stage :name "resolveEdges" :value (gethash "resolveEdges" stages) :status :derived
                     :source (source-by-key reading "composition:resolveEdges")
                     :note "Both endpoints are listed in the declared site's sitemap, so both are resolved; nothing was looked up on another site.")
      (make-instance 'example-stage :name "traverse" :value (gethash "traverse" stages) :status :derived
                     :source (source-by-key reading "composition:traverse")
                     :note "Breadth-first from the page holding the Mech item, over the role claim only.")
      (make-instance 'example-stage :name "presentGraph" :value (gethash "presentGraph" stages) :status :derived
                     :source (source-by-key reading "composition:presentGraph")
                     :note "Two WikiPage nodes named site/slug and one relation of type claim.")
      (make-instance 'example-stage :name "SOLO" :value (gethash "solo" stages) :status :handed-over
                     :source (source-by-key reading "upstream:solo_emit")
                     :note "The batch posted to /plugins/solo/dialog/#; its graph equals presentGraph's. What Solo then draws is not part of this record.")
      (make-instance 'example-stage :name "asserted relation"
                     :value (list :statement "Claim A is a claim answering Question"
                                  :status :not-established
                                  :why "TRAVERSE presents a typed relation between two pages, derived from a fold label. Whether the author asserts that Claim A answers Question, and whether that is true, is not represented by any object of this run.")
                     :status :not-established
                     :source (source-by-key reading "composition:traverse-header")
                     :note "Kept apart on purpose: observed link, derived relation, asserted relation.")))))

(defmethod v:text-representation ((run example-run))
  "Two-page TRAVERSE example: retained run of the tested bundle")

(defmethod v:text-representation ((stage example-stage))
  (format nil "~A (~(~A~))" (stage-name stage) (stage-status stage)))

(v:defview example-run-view (run example-run)
  (v:html-view :title "Example" :priority 0
    (v:html
      (:p "Retained run of the bundle " (:code "19b14c31…") " in Node, without network access; read here, not re-run. "
          (v:object-ref (run-record run) :select "Record" :display "The run record"))
      (:p "Program on the page Question: " (:code (cl-who:esc (format nil "~{~A~^ / ~}" (coerce (gethash "program" (record-value (run-record run))) 'list)))))
      (:ol (dolist (stage (run-stages run))
             (v:html (:li (v:object-ref stage :select "Stage" :display (stage-name stage))
                          " — " (cl-who:esc (string-downcase (stage-status stage)))))))
      (:p "Status lines: " (:code (cl-who:esc (format nil "~{~A~^ | ~}" (coerce (gethash "statuses" (record-value (run-record run))) 'list)))))
      (reading-links))))

(v:defview example-stage-view (stage example-stage)
  (v:html-view :title "Stage" :priority 0
    (v:html
      (:h3 (cl-who:esc (stage-name stage)))
      (:p (:strong "Status: ") (cl-who:esc (string-downcase (stage-status stage))))
      (:p (cl-who:esc (stage-note stage)))
      (:p (v:object-ref (stage-value stage) :display "Inspect the recorded value"))
      (when (stage-source stage)
        (v:html (:p (v:object-ref (stage-source stage) :select "Source definition"
                                  :display (format nil "Defined by ~A" (n:source-definition (stage-source stage)))))))
      (reading-links))))
