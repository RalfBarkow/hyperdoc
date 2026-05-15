;;;; Goldberg Programmer-as-Reader topics, questions, and operations.

(in-package #:hyperdoc-goldberg-programmer-as-reader)

(defparameter *goldberg-source-title*
  "Adele Goldberg, Programmer as Reader, IEEE Software, 1987")

(defun goldberg-source-citation ()
  "Return a compact local citation string for the source paper."
  *goldberg-source-title*)

(defparameter *goldberg-layer-specs*
  '((:user-interface
     :title "User-interface layer"
     :summary "The interaction protocol: how a reader invokes a response and recognizes system feedback.")
    (:functionality
     :title "Functionality layer"
     :summary "The available actions and their requirements, ideally shown in-context rather than hidden in static manuals.")
    (:structure
     :title "Structure layer"
     :summary "The browseable organization of classes, messages, facts, examples, definitions, and dynamic cross-references.")
    (:language
     :title "Language / implementation layer"
     :summary "The runtime state, explanation, debugging, and why/why-not questions exposed through source-level inspection.")))

(defparameter *goldberg-topic-data*
  '(("goldberg-programmer-as-reader"
     "Goldberg Programmer as Reader"
     "A source-station topic for Adele Goldberg's claim that exploratory programming environments must help programmers read systems, not only write programs."
     "Goldberg Programmer as Reader.html"
     nil
     ("Goldberg Programmer as Reader topic arrangement" "Goldberg reading comprehension questions" "Goldberg reader operations"))
    ("goldberg-programmer-as-reader-arrangement"
     "Goldberg Programmer as Reader topic arrangement"
     "Arrangement surface preserving the paper's conceptual neighborhood: four layers, twelve comprehension questions, Smalltalk examples, and HyperDoc carry-forward topics."
     "Goldberg Programmer as Reader topic arrangement.html"
     nil
     ("Goldberg Programmer as Reader" "Topic arrangement in HyperDoc"))
    ("program-read-bug"
     "Program read bug"
     "A failure of understanding rather than execution: a program can run correctly and still fail as readable material for later maintenance or reuse."
     "Goldberg Programmer as Reader.html"
     nil
     ("Goldberg Programmer as Reader" "Debugging Reinvented in HyperDoc"))
    ("exploratory-programming-environment"
     "Exploratory programming environment"
     "A live environment in which programmers synthesize, execute, inspect, and revise programs while also accessing parts of the environment itself."
     "Goldberg Programmer as Reader.html"
     nil
     ("Source-oriented and image-oriented development in Common Lisp" "HyperDoc Runtime Model"))
    ("programming-by-incremental-refinement"
     "Programming by incremental refinement"
     "A development style in which new functionality grows by composing existing parts, decomposing existing functionality, and iteratively testing alternatives."
     "Goldberg Programmer as Reader.html"
     nil
     ("Running Image Coherence Rebuild Workflow" "McDermott Running Image Coherence Crosswalk"))
    ("readable-malleable-layer"
     "Readable malleable layer"
     "A system layer that the programmer can inspect, modify, reuse, and refine directly from within the development environment."
     "Goldberg Smalltalk to HyperDoc crosswalk.html"
     nil
     ("Smalltalk Browser Frame and Scene in HyperDoc" "HyperDoc Evaluation and Inspection Model"))
    ("hidden-protected-layer"
     "Hidden protected layer"
     "A lower implementation layer that remains outside the ordinary reader's modification path, often because it is implemented in a different language or exists for performance reasons."
     "Goldberg Smalltalk to HyperDoc crosswalk.html"
     nil
     ("Boundary" "Runtime Dispatch Seams in HyperDoc"))
    ("goldberg-reading-comprehension-question"
     "Goldberg reading comprehension question"
     "One of twelve environment-level questions a system should answer so programmers can read user interaction, functionality, structure, and implementation state."
     "Goldberg reading comprehension questions.html"
     nil
     ("Goldberg reader operations" "Inspectable Mech Runs"))
    ("goldberg-user-interface-layer"
     "Goldberg user-interface layer"
     "The layer that lets the reader ask how to invoke a response and how to interpret the visible system answer."
     "Goldberg reading comprehension questions.html"
     :user-interface
     ("Dock presentation state model" "Documentation Surfaces in HyperDoc"))
    ("goldberg-functionality-layer"
     "Goldberg functionality layer"
     "The layer that exposes what can be done now and what state is needed to do a specific function."
     "Goldberg reading comprehension questions.html"
     :functionality
     ("Capability-scoped Extensions for FedWiki" "Document capability as DITA-like click-through cluster"))
    ("goldberg-structure-layer"
     "Goldberg structure layer"
     "The layer that helps readers locate definitions, uses, examples, and the parts of the system that know about a token or responsibility."
     "Goldberg reading comprehension questions.html"
     :structure
     ("Code path graphs in HyperDoc" "Semantic-first anchor resolution"))
    ("goldberg-language-implementation-layer"
     "Goldberg language implementation layer"
     "The layer that exposes current state, execution context, and why/why-not explanations through debuggers, inspectors, and traces."
     "Goldberg reading comprehension questions.html"
     :language
     ("Stepper Debugger Surface" "Whyline Output Questions"))
    ("message-set-browser"
     "Message-set browser"
     "A browser view that answers structural questions by showing implementations of a selected message or senders that use it."
     "Goldberg Smalltalk to HyperDoc crosswalk.html"
     :structure
     ("Smalltalk Browser Frame and Scene in HyperDoc" "Code path graphs in HyperDoc"))
    ("program-as-dynamic-database"
     "Program as dynamic database"
     "A design stance in which executable code and queryable source metadata share one representation with multiple access paths rather than divergent databases."
     "Goldberg Smalltalk to HyperDoc crosswalk.html"
     :structure
     ("Authoritative Journal-Backed Page Store" "HyperDoc Evaluation and Inspection Model"))
    ("change-file-as-audit-trail"
     "Change file as audit trail"
     "A recoverable ordered record of evaluations and definitions that lets the reader reconstruct how the current image was reached."
     "Goldberg Smalltalk to HyperDoc crosswalk.html"
     :structure
     ("Journal Object Extensions" "Running Image Coherence Rebuild Workflow"))
    ("goldberg-why-question"
     "Goldberg why question"
     "The runtime explanation family asking why an event happened or why an expected event did not happen."
     "Goldberg reader operations.html"
     :language
     ("Failure as Inspectable Object" "Clickable Correction Path from Error to Merge"))
    ("reader-operation"
     "Reader operation"
     "A clickable, inspectable action that turns a comprehension question into a concrete HyperDoc query or example object."
     "Goldberg reader operations.html"
     nil
     ("Inspectability propagation in HyperDoc" "Surface and Artifact Answers"))))

(defparameter *goldberg-reader-question-data*
  '((:invoke-response 1 :user-interface
     "How do I invoke response?"
     "Show the gesture, command, or link that requests the visible response."
     "Turns UI affordances into discoverable protocol instead of relying on memory."
     :invoke-response-operation)
    (:what-can-i-do-now 2 :functionality
     "What specifically can I do now?"
     "List currently valid actions for the selected object or state."
     "Treats available functionality as a context-sensitive menu or operation set."
     :available-actions-operation)
    (:what-is-needed 3 :functionality
     "What is needed to do a specific function?"
     "Show preconditions, parameters, state requirements, and failure conditions."
     "Moves function requirements out of static prose and into inspectable operation metadata."
     :requirements-operation)
    (:what-is-that 4 :structure
     "What is that?"
     "Explain the selected token, object, page, class, operation, or visible artifact."
     "Provides point-and-ask explanation for symbols and visible runtime objects."
     :explain-token-operation)
    (:where-is-it 5 :structure
     "Where is it?"
     "Locate the definition, fact, code, example use, or algorithm that realizes a selected thing."
     "Turns system memory into a navigable source station."
     :locate-definition-operation)
    (:does-any-part-do-this 6 :structure
     "Does any part of the system do this?"
     "Search by responsibility or behavior rather than by exact name."
     "Supports reuse by finding latent functionality before new code is written."
     :behavior-search-operation)
    (:what-knows-about-that 7 :structure
     "What part of the system knows about that?"
     "Find implementors, senders, owners, pages, and backlinks that participate in the selected responsibility."
     "Maps knowledge ownership across code, topics, and documentation pages."
     :knowledge-owner-operation)
    (:how-did-i-get-here 8 :structure
     "How did I get here? What has been happening?"
     "Display the change path, provenance trail, or navigation route that produced the current state."
     "Makes history part of readability rather than external archaeology."
     :history-operation)
    (:how-can-i-get-back 9 :structure
     "How can I get back?"
     "Offer a return route, revert target, previous version, or recovery path."
     "Connects browsing, undo, and recovery to the reader's current context."
     :return-route-operation)
    (:current-state 10 :language
     "What is the current state of the system?"
     "Inspect live state, selected object slots, current index state, and relevant runtime facts."
     "Frames debugging as reading the image, not just reading files."
     :current-state-operation)
    (:why-happened 11 :language
     "Why did that happen?"
     "Show the event chain, calls, transitions, state changes, and evidence that led to an observed result."
     "Materializes successful or surprising events as explanation traces."
     :why-happened-operation)
    (:why-not-happened 12 :language
     "Why didn't that happen?"
     "Show the missing precondition, blocked transition, unavailable operation, or absent dispatch route."
     "Turns negative outcomes into inspectable failure objects."
     :why-not-operation)))

(defparameter *goldberg-operation-data*
  '((:invoke-response-operation
     "Invoke response"
     :invoke-response
     "Open an explanation object for the UI affordance that would cause a response."
     ("A visible command, link, token, or view is selected.")
     ("Resolve the selected affordance."
      "Show the expected response and the gesture that invokes it."
      "Offer the operation as a clickable expression link.")
     "A small reader-question object describing the invocation protocol."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :invoke-response)")
    (:available-actions-operation
     "Show available actions"
     :what-can-i-do-now
     "Return context-sensitive actions for the selected reader object."
     ("A page, topic, operation, or selected token is known.")
     ("Classify the context object."
      "Collect valid operations."
      "Return only operations that can be attempted from this state.")
     "An operation list suitable for menu or inspector rendering."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :what-can-i-do-now)")
    (:requirements-operation
     "Explain function requirements"
     :what-is-needed
     "Expose preconditions and required inputs for the selected function."
     ("An operation has been selected.")
     ("Read the operation preconditions."
      "Separate required state from optional parameters."
      "Report blocking conditions before execution.")
     "A precondition-focused operation report."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :what-is-needed)")
    (:explain-token-operation
     "Explain token"
     :what-is-that
     "Explain a selected token or visible object in the current HyperDoc surface."
     ("A token, title, link, code symbol, or DOM anchor is selected.")
     ("Resolve token identity."
      "Find the topic, page, code symbol, or operation that owns it."
      "Return a short explanation plus cross-reference links.")
     "A reader-facing explanation with links to definitions and examples."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :what-is-that)")
    (:locate-definition-operation
     "Locate definition or example"
     :where-is-it
     "Find the file, page, topic, function, or example where the selected thing is defined or used."
     ("A resolved token or responsibility is available.")
     ("Search authored topics and pages."
      "Search code symbols and examples."
      "Prefer exact owner before broader references.")
     "A source-station result with page and code pointers."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :where-is-it)")
    (:behavior-search-operation
     "Search behavior"
     :does-any-part-do-this
     "Search for existing behavior before writing new behavior."
     ("The desired behavior is described as words, examples, or a responsibility.")
     ("Normalize the responsibility."
      "Compare against operation summaries and topic summaries."
      "Return candidates with confidence notes.")
     "A reuse-first candidate list."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :does-any-part-do-this)")
    (:knowledge-owner-operation
     "Find knowledge owners"
     :what-knows-about-that
     "Find code, topics, pages, and examples that know about a selected responsibility."
     ("A selected responsibility, message, symbol, or title is available.")
     ("Find direct implementors."
      "Find senders or backlinks."
      "Find authored references and arrangement pages.")
     "A cross-reference object similar in spirit to a message-set browser."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :what-knows-about-that)")
    (:history-operation
     "Show how I got here"
     :how-did-i-get-here
     "Summarize the provenance and route that produced the current page or object."
     ("The page or operation records source and materialization metadata.")
     ("Read source claim."
      "Read materialization path."
      "Show previous route and adjacent arrangement page.")
     "A compact history report."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :how-did-i-get-here)")
    (:return-route-operation
     "Show how I can get back"
     :how-can-i-get-back
     "Return the safe navigation or recovery route from the current context."
     ("A current page, route, or failed operation exists.")
     ("Locate the parent arrangement."
      "List previous state or authoritative source."
      "Offer rollback/reopen route where available.")
     "A return-route operation object."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :how-can-i-get-back)")
    (:current-state-operation
     "Inspect current state"
     :current-state
     "Expose the current live slice state: topic count, question count, operation count, and materialization status."
     ("The ASDF system is loaded.")
     ("Count registered topics."
      "Count questions and operations."
      "Report whether page templates are available.")
     "A live slice summary object."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-zettel-summary)")
    (:why-happened-operation
     "Explain why it happened"
     :why-happened
     "Build an explanation trace for an observed result."
     ("An observed event or operation result is selected.")
     ("Read the operation steps."
      "Tie each step to preconditions and evidence."
      "Return the causal path that made the result expected.")
     "A why-trace object linking event to causes."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :why-happened)")
    (:why-not-operation
     "Explain why it did not happen"
     :why-not-happened
     "Build a why-not trace for an absent or blocked result."
     ("An expected event, failed operation, or absent page is selected.")
     ("Identify the desired event."
      "Check preconditions and route availability."
      "Return the first missing or blocked condition.")
     "A failure object with a precise blocking condition."
     "(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :why-not-happened)")))
