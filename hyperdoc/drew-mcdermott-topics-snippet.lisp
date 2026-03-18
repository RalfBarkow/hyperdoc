;;;; Proposed topic additions for the Drew McDermott import slice.
;;;; Merge selectively if any of these titles already exist.

(in-package :hyperdoc)

(defun make-drew-mcdermott-topic (id title summary)
  (make-topic
   :id id
   :title title
   :summary summary
   :references '("Drew McDermott Lisp, Planning, and Software"
                 "Drew McDermott topic arrangement")))

(defun drew-mcdermott-topic ()
  (make-topic
   :id "drew-mcdermott"
   :title "Drew McDermott"
   :summary "Common Lisp, AI planning, ontology, and software author whose public site usefully exposes publications, manuals, and downloadable Lisp systems."
   :references '("Drew McDermott Lisp, Planning, and Software"
                 "Drew McDermott topic arrangement")))

(defun ytools-topic ()
  (make-drew-mcdermott-topic
   "ytools"
   "YTools"
   "Common Lisp utility layer with iteration, formatted I/O, file management, and other support code used by several McDermott software packages."))

(defun lexiparse-topic ()
  (make-drew-mcdermott-topic
   "lexiparse"
   "Lexiparse"
   "Lexicon-based or precedence-grammar parser framework for Lisp applications that depends on YTools."))

(defun nisp-topic ()
  (make-drew-mcdermott-topic
   "nisp"
   "Nisp"
   "Strongly typed dialect of Lisp implemented through macros."))

(defun ynisp-topic ()
  (make-drew-mcdermott-topic
   "ynisp"
   "YNisp"
   "Later YTools-based form of Nisp, described on the site as YTools plus ydecl."))

(defun nity-topic ()
  (make-drew-mcdermott-topic
   "nity"
   "Nity"
   "Polymorphic type system used by Opt and intended as a broader type substrate for McDermott's language stack."))

(defun opt-topic ()
  (make-drew-mcdermott-topic
   "opt"
   "Opt"
   "Knowledge-representation and planning language positioned as a successor to PDDL, with durative actions, autonomous processes, hierarchical planning notation, and stronger typing."))

(defun optop-topic ()
  (make-drew-mcdermott-topic
   "optop"
   "Optop"
   "Estimated-regression planner built on Opt and Nisp."))

(defun litlisp-topic ()
  (make-drew-mcdermott-topic
   "litlisp"
   "Litlisp"
   "Experimental literate-programming system whose directives are Lisp commands but whose target language need not be Lisp."))

(defun ontology-translation-topic ()
  (make-drew-mcdermott-topic
   "ontology-translation"
   "Ontology translation"
   "Translation or interoperability work across ontologies, especially in Semantic Web and agent settings."))

(defun estimated-regression-planning-topic ()
  (make-drew-mcdermott-topic
   "estimated-regression-planning"
   "Estimated-regression planning"
   "Planning approach used by McDermott's planner work, including web-service and multi-agent settings."))

(defun autonomous-process-topic ()
  (make-drew-mcdermott-topic
   "autonomous-process"
   "Autonomous process"
   "Planning-language construct for processes that evolve independently of direct planner action once enabled."))

(defun running-image-coherence-topic ()
  (make-topic
   :id "running-image-coherence"
   :title "Running image coherence"
   :summary "The problem of keeping a live Lisp image internally consistent and intelligible as definitions, dependencies, and loaded state evolve over time."
   :references '("A framework for maintaining the coherence of a running Lisp"
                 "Drew McDermott Lisp, Planning, and Software"
                 "Source-oriented and image-oriented development in Common Lisp")))
