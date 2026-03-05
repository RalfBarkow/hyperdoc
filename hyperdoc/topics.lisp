;;;; HyperDoc inspectable topic objects
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;; Inspectable topic objects used by expr links in HyperDoc pages.
(defclass topic ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (references :reader references-of :initarg :references :initform nil)))

(defun make-topic (&key id title summary references)
  (make-instance 'topic
                 :id id
                 :title title
                 :summary summary
                 :references references))

;; Core topic objects for Concepts/DMX/Topic Maps page.
(defun concept-operational-definition ()
  (make-topic
   :id "concept-operational-definition"
   :title "Concept"
   :summary "A concept is an identifiable subject with stable identity, names, occurrences, and associations."
   :references '("Operational Definition of Subject Identity"
                 "Concepts, DMX Topics, and Topic Maps")))

(defun topic-map-operational-definition ()
  (make-topic
   :id "topic-map-operational-definition"
   :title "Topic Map"
   :summary "A topic map is a graph of topics that separates subject identity from any single document or rendering."
   :references '("Concepts, DMX Topics, and Topic Maps")))

(defun dmx-topic-operational-definition ()
  (make-topic
   :id "dmx-topic-operational-definition"
   :title "DMX Topic"
   :summary "A DMX topic is an addressable runtime topic object with type/value/association structure."
   :references '("Concepts, DMX Topics, and Topic Maps")))

;; Topic objects for AArch64 SD-image preparation flow.
(defun prepare-aarch64-image-topic ()
  (make-topic
   :id "prepare-aarch64-image"
   :title "Prepare the AArch64 image"
   :summary "Preparation phase for obtaining and validating an aarch64 NixOS SD-image artifact before flashing."
   :references '("Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
                 "Two Installation Models: SD Image vs Classic Installer")))

(defun runbook-build-and-flash-sd-image-topic ()
  (make-topic
   :id "runbook-build-and-flash-sd-image"
   :title "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
   :summary "Operational sequence to build/obtain, flash, boot, and validate the SD image on Pi 4."
   :references '("Prepare the AArch64 image")))

(defun official-rpi-sd-image-tutorial-topic ()
  (make-topic
   :id "official-rpi-sd-image-tutorial"
   :title "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
   :summary "Upstream nix.dev SD-image workflow: preinstalled image, first rebuild with nixos-rebuild boot, then reboot."
   :references '("Prepare the AArch64 image")))

(defun preflight-rpi-sd-image-checklist-topic ()
  (make-topic
   :id "preflight-rpi-sd-image-checklist"
   :title "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
   :summary "Checks before reboot to verify boot partition state, extlinux files, and partition labels."
   :references '("Prepare the AArch64 image")))

(defun two-installation-models-topic ()
  (make-topic
   :id "two-installation-models-sd-vs-classic"
   :title "Two Installation Models: SD Image vs Classic Installer"
   :summary "Distinguishes prebuilt SD-image workflow from classic installer workflow to avoid command-model drift."
   :references '("Prepare the AArch64 image")))

(defun dmx-topic-912138 ()
  (make-topic
   :id "dmx-topic-912138"
   :title "DMX Topic 912138"
   :summary "External DMX topic reference for the AArch64 image preparation context."
   :references '("https://dmx.ralfbarkow.ch/systems.dmx.webclient/#/topicmap/912102/topic/912138/info")))

;; Command and artifact topics for the tutorial sequence.
(defun nix-shell-topic ()
  (make-topic
   :id "nix-shell"
   :title "nix-shell"
   :summary "Ephemeral environment launcher used to provide wget/zstd for image preparation."
   :references '("Prepare the AArch64 image")))

(defun wget-topic ()
  (make-topic
   :id "wget"
   :title "wget"
   :summary "Downloader used to fetch the selected Hydra SD-image artifact."
   :references '("Prepare the AArch64 image")))

(defun zstd-topic ()
  (make-topic
   :id "zstd"
   :title "zstd"
   :summary "Compression tool used for .img.zst artifacts."
   :references '("Prepare the AArch64 image")))

(defun unzstd-topic ()
  (make-topic
   :id "unzstd-d"
   :title "unzstd -d"
   :summary "Decompression command to convert .img.zst into a flashable .img."
   :references '("Prepare the AArch64 image")))

(defun dmesg-follow-topic ()
  (make-topic
   :id "dmesg-follow"
   :title "dmesg --follow"
   :summary "Kernel log follow mode used to observe SD-card device attach events."
   :references '("Prepare the AArch64 image")))

(defun hydra-latest-job-topic ()
  (make-topic
   :id "hydra-latest-job"
   :title "Hydra latest SD-image job"
   :summary "Hydra unstable job endpoint used to select the latest successful aarch64 SD-image build."
   :references '("https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux")))

(defun hydra-build-323111513-topic ()
  (make-topic
   :id "hydra-build-323111513"
   :title "Hydra build 323111513"
   :summary "Concrete chosen build artifact for the current preparation pass."
   :references '("https://hydra.nixos.org/build/323111513")))

(defun hydra-latest-download-link-topic ()
  (make-topic
   :id "hydra-latest-download-link"
   :title "Hydra latest download link"
   :summary "Stable 'latest' download-by-type link for SD-image artifacts."
   :references '("https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download-by-type/file/sd-image"
                 "https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download/1")))

(defun hydra-sha256-topic ()
  (make-topic
   :id "hydra-sha256"
   :title "Hydra artifact SHA-256"
   :summary "Integrity hash used to verify the downloaded .img.zst artifact before decompression and flashing."
   :references '("6c0f8bffdac01aa95e66505180d51b3557b04f3ad43cf0900376528837b62d0f")))

;; Procedure-step topics for "Prepare the AArch64 image".
(defun aarch64-procedure-select-source-topic ()
  (make-topic
   :id "aarch64-procedure-select-source"
   :title "Procedure step 1: select one source of truth"
   :summary "Choose exactly one source for the SD image artifact: official prebuilt image or project build output."
   :references '("Prepare the AArch64 image"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun aarch64-procedure-record-provenance-topic ()
  (make-topic
   :id "aarch64-procedure-record-provenance"
   :title "Procedure step 2: record provenance"
   :summary "Download or build the artifact and capture provenance metadata (URL/build/commit/date)."
   :references '("Prepare the AArch64 image"
                 "Hydra latest SD-image job"
                 "Hydra build 323111513")))

(defun aarch64-procedure-decompress-topic ()
  (make-topic
   :id "aarch64-procedure-decompress"
   :title "Procedure step 3: decompress image"
   :summary "Decompress the .img.zst artifact into a flashable .img using zstd/unzstd."
   :references '("Prepare the AArch64 image"
                 "zstd"
                 "unzstd -d")))

(defun aarch64-procedure-verify-integrity-topic ()
  (make-topic
   :id "aarch64-procedure-verify-integrity"
   :title "Procedure step 4: verify integrity"
   :summary "Verify downloaded artifact integrity using file size and/or SHA-256 checksum before flashing."
   :references '("Prepare the AArch64 image"
                 "Hydra artifact SHA-256")))

(defun aarch64-procedure-confirm-architecture-topic ()
  (make-topic
   :id "aarch64-procedure-confirm-architecture"
   :title "Procedure step 5: confirm architecture"
   :summary "Confirm artifact naming and target architecture include aarch64-linux."
   :references '("Prepare the AArch64 image")))

;; Journal integrity findings as inspectable topics.
(defun chronology-violation-topic ()
  (make-topic
   :id "chronology-violation"
   :title "Chronology violation"
   :summary "Journal action dates go backward, so action order is no longer monotonic."
   :references '("Journalmatic Journal Checker"
                 "Journalmatic Repair Tools"
                 "journalmatic-rectify-chronology-example")))

(defun replay-precondition-violation-topic ()
  (make-topic
   :id "replay-precondition-violation"
   :title "Replay precondition violation"
   :summary "Journal replay preconditions fail (e.g. add/edit/remove references unseen ids), so revision reconstruction can fail."
   :references '("Journalmatic Journal Checker"
                 "Journalmatic Revision Replay"
                 "journalmatic-checker-example")))

;; ASDF workflow topics for runtime loading and undefined-function triage.
(defun asdf-system-topic ()
  (make-topic
   :id "asdf-system"
   :title "ASDF system"
   :summary "Top-level ASDF unit loaded via asdf:load-system; controls transitive dependencies and component graph."
   :references '("ASDF Components Workflow"
                 "Creating a HyperDoc")))

(defun asdf-component-topic ()
  (make-topic
   :id "asdf-component"
   :title "ASDF component"
   :summary "An ASDF component is a file/module/system entry in the .asd graph that must include the code you expect at runtime."
   :references '("ASDF Components Workflow"
                 "Reloading HyperDoc After Adding Lisp Objects")))

(defun asdf-module-serial-order-topic ()
  (make-topic
   :id "asdf-module-serial-order"
   :title "ASDF module serial order"
   :summary "When :serial t is used, component order defines load order and therefore definition availability."
   :references '("ASDF Components Workflow"
                 "Creating a HyperDoc")))

(defun asdf-load-system-force-topic ()
  (make-topic
   :id "asdf-load-system-force"
   :title "asdf:load-system :force t"
   :summary "Forces recompilation/reload of components to refresh a stale image when new definitions were added."
   :references '("ASDF Components Workflow"
                 "Reloading HyperDoc After Adding Lisp Objects")))

(defun asdf-find-system-topic ()
  (make-topic
   :id "asdf-find-system"
   :title "asdf:find-system"
   :summary "Resolves whether a named system is visible in the current source registry before load/operation."
   :references '("ASDF Components Workflow"
                 "HyperDoc Server")))

(defun undefined-function-triage-topic ()
  (make-topic
   :id "undefined-function-triage"
   :title "Undefined-function triage"
   :summary "Diagnostic path: verify symbol binding, verify component inclusion in .asd, then reload/restart."
   :references '("ASDF Components Workflow"
                 "Reloading HyperDoc After Adding Lisp Objects")))

;; Topic objects for Playground/debugger runtime surfaces.
(defun playground-eval-surface-topic ()
  (make-topic
   :id "playground-eval-surface"
   :title "Playground eval surface"
   :summary "Runtime wiring for Playground eval/inspect/step/debug actions and action-thunk behavior."
   :references '("hyperdoc-inspector/playground-eval.lisp"
                 "Stepper Debugger Surface"
                 "Playground restarts")))

(defun playground-debug-report-surface-topic ()
  (make-topic
   :id "playground-debug-report-surface"
   :title "Playground debug report surface"
   :summary "Lightweight debug report object with condition/source/backtrace and retry/abort recovery actions."
   :references '("hyperdoc-inspector/playground-debug.lisp"
                 "Playground restarts")))

(defun web-debugger-surface-topic ()
  (make-topic
   :id "web-debugger-surface"
   :title "Web debugger surface"
   :summary "Session-based web debugger registry for paused-thread debugger flow and restart invocation."
   :references '("hyperdoc-inspector/web-debugger.lisp"
                 "Stepper Debugger Surface"
                 "Playground restarts")))

(defun playground-stepper-surface-topic ()
  (make-topic
   :id "playground-stepper-surface"
   :title "Playground stepper surface"
   :summary "Stepper model and run/step/reset operations used by the Playground execution flow."
   :references '("hyperbook-server/playground-stepper.lisp"
                 "Stepper Debugger Surface"
                 "Playground restarts")))

;; Topic objects for Konrad feedback thread (2026-03-05).
(defun graph-based-discovery-and-traversal-topic ()
  (make-topic
   :id "graph-based-discovery-and-traversal"
   :title "Graph-based discovery and traversal"
   :summary "HyperDoc/HyperBook usage where humans and programs discover and traverse content through graph links."
   :references '("Konrad Feedback on Communication Pages"
                 "Concepts, DMX Topics, and Topic Maps")))

(defun hyperbook-interface-no-media-discontinuity-topic ()
  (make-topic
   :id "hyperbook-interface-no-media-discontinuity"
   :title "HyperBook interface without media discontinuity"
   :summary "The HyperBook interface keeps browsing, running, and inspecting in one medium instead of splitting prose and runtime."
   :references '("Konrad Feedback on Communication Pages"
                 "HyperDoc Server")))

(defun uniform-robot-access-topic ()
  (make-topic
   :id "uniform-robot-access"
   :title "Uniform robot access"
   :summary "Robot code can access the same graph and objects as humans, through the same interface conventions."
   :references '("Konrad Feedback on Communication Pages"
                 "Communication Surfaces Policy")))

(defun human-written-robot-code-topic ()
  (make-topic
   :id "human-written-robot-code"
   :title "Human-written robot code"
   :summary "Processing code is authored by humans and stored as first-class HyperDoc content."
   :references '("Konrad Feedback on Communication Pages")))

(defun processing-code-inside-hyperdoc-topic ()
  (make-topic
   :id "processing-code-inside-hyperdoc"
   :title "Processing code inside HyperDoc"
   :summary "Processing code should live inside HyperDoc and be browsable, runnable, and inspectable by other code."
   :references '("Konrad Feedback on Communication Pages"
                 "Stepper Debugger Surface"
                 "Playground restarts")))

(defun topic-map-work-alignment-topic ()
  (make-topic
   :id "topic-map-work-alignment"
   :title "Topic-map work alignment"
   :summary "Existing topic-map work aligns with HyperDoc's graph-centric discovery and traversal model."
   :references '("Konrad Feedback on Communication Pages"
                 "Concepts, DMX Topics, and Topic Maps")))

(defun concept-graph-leaf-for-humans-and-robots-topic ()
  (make-topic
   :id "concept-graph-leaf-for-humans-and-robots"
   :title "Concept-graph leaf for humans and robots"
   :summary "A page is a leaf in a larger concept graph that both humans and robots can reach via search/traversal."
   :references '("Konrad Feedback on Communication Pages"
                 "Communication Surfaces Policy")))

(defun second-order-hypertext-topic ()
  (make-topic
   :id "second-order-hypertext"
   :title "Second-order hypertext"
   :summary "Hypertext where pages describe and operationalize the graph and traversal logic that produces their own context."
   :references '("Konrad Feedback on Communication Pages"
                 "Concepts, DMX Topics, and Topic Maps")))

;; Topic objects for Smalltalk browser frame/scene discussion and HyperDoc adaptation.
(defun four-pane-browser-metaphor-topic ()
  (make-topic
   :id "four-pane-browser-metaphor"
   :title "Four-pane browser metaphor"
   :summary "The enduring class/category/protocol/method browser frame that preserves static code context."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun static-context-frame-topic ()
  (make-topic
   :id "static-context-frame"
   :title "Static context frame"
   :summary "A structured code frame (class/package/method neighborhood) that keeps local orientation while editing."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun dynamic-investigation-scene-topic ()
  (make-topic
   :id "dynamic-investigation-scene"
   :title "Dynamic investigation scene"
   :summary "The evolving thread across debugger, inspector, senders/implementors, playground, and decisions."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Stepper Debugger Surface")))

(defun message-flow-navigation-topic ()
  (make-topic
   :id "message-flow-navigation"
   :title "Message-flow navigation"
   :summary "Behavior understanding by following call/message flow across objects and tools rather than within one browser pane."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Stepper Debugger Surface")))

(defun ide-composition-gap-topic ()
  (make-topic
   :id "ide-composition-gap"
   :title "IDE composition gap"
   :summary "Tools coexist but do not carry context seamlessly, creating friction between powerful islands."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Communication Surfaces Policy")))

(defun investigation-thread-memory-topic ()
  (make-topic
   :id "investigation-thread-memory"
   :title "Investigation thread memory"
   :summary "Need to preserve where we came from, what we tried, and why decisions were made."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun frankenstein-tool-problem-topic ()
  (make-topic
   :id "frankenstein-tool-problem"
   :title "Frankenstein tool problem"
   :summary "Feature accretion without holistic redesign yields powerful but hard-to-master tools."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun hermit-tool-problem-topic ()
  (make-topic
   :id "hermit-tool-problem"
   :title "Hermit tool problem"
   :summary "Each tool behaves like an island; transitions lose context."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun alien-tool-problem-topic ()
  (make-topic
   :id "alien-tool-problem"
   :title "Alien tool problem"
   :summary "Image-local workflows can clash with OS conventions where mismatch is accidental rather than essential."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun saturated-environment-problem-topic ()
  (make-topic
   :id "saturated-environment-problem"
   :title "Saturated environment problem"
   :summary "Scale growth raises navigation/discoverability costs and lowers signal-to-noise."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun workspace-as-graph-topic ()
  (make-topic
   :id "workspace-as-graph"
   :title "Workspace as graph"
   :summary "Treat active work as a graph of related tools, objects, and steps rather than independent windows."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Graph-Rooted Publishing")))

(defun scene-graph-node-topic ()
  (make-topic
   :id "scene-graph-node"
   :title "Scene graph node"
   :summary "A node in the investigation scene graph: tool state, object, code location, experiment, or decision."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun scene-graph-edge-topic ()
  (make-topic
   :id "scene-graph-edge"
   :title "Scene graph edge"
   :summary "Typed relation between scene nodes (e.g. led-to, inspected, retried, rejected, superseded)."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Concepts, DMX Topics, and Topic Maps")))

(defun scene-graph-edit-cycle-topic ()
  (make-topic
   :id "scene-graph-edit-cycle"
   :title "Scene graph edit cycle"
   :summary "Operational cycle: capture step -> link to prior state -> annotate outcome -> branch or merge."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun hyperdoc-scene-graph-adaptation-topic ()
  (make-topic
   :id "hyperdoc-scene-graph-adaptation"
   :title "HyperDoc scene graph adaptation"
   :summary "Adapt Smalltalk IDE lessons by making navigation/debugging steps first-class inspectable graph objects in HyperDoc."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Konrad Feedback on Communication Pages")))

(defun human-written-robot-process-graphs-topic ()
  (make-topic
   :id "human-written-robot-process-graphs"
   :title "Human-written robot process graphs"
   :summary "Human-authored process graphs guide automated traversal while staying inspectable/editable by humans."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Konrad Feedback on Communication Pages")))

;; Topic objects for Ward Cunningham input on Smalltalk tooling lineage.
(defun ward-beck-diagram-1986-topic ()
  (make-topic
   :id "ward-beck-diagram-1986"
   :title "Ward/Beck diagram for object-oriented programs (1986)"
   :summary "Cunningham and Beck's OOPSLA 1986 diagram work frames object collaboration as first-class explanatory structure."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "https://c2.com/doc/case87.html")))

(defun ward-collaborating-objects-topic ()
  (make-topic
   :id "ward-collaborating-objects"
   :title "Collaborating objects diagrams"
   :summary "Hand-drawn collaboration diagrams were used to explain object behavior across tool boundaries."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun class-browser-inspector-debugger-triangulation-topic ()
  (make-topic
   :id "class-browser-inspector-debugger-triangulation"
   :title "Class browser/inspector/debugger triangulation"
   :summary "Behavior understanding required combining three windows: class browser, object inspector, and single-step debugger."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Stepper Debugger Surface")))

(defun compiledmethod-interpretnextinstruction-topic ()
  (make-topic
   :id "compiledmethod-interpretnextinstruction"
   :title "CompiledMethod interpretNextInstructionFor: aContext"
   :summary "The stepping primitive exposed execution semantics that enabled direct diagram extraction from runtime behavior."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun expanding-tools-literate-environment-topic ()
  (make-topic
   :id "expanding-tools-literate-environment"
   :title "Expanding the Role of Tools in a Literate Programming Environment"
   :summary "CASE'87 line of work: tools should compose around explanation, not just editing, anticipating scene-level workflow support."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "https://c2.com/doc/case87.html")))

(defun ward-diagramming-debugger-remembrance-topic ()
  (make-topic
   :id "ward-diagramming-debugger-remembrance"
   :title "Ward diagramming-debugger remembrance"
   :summary "Ward's later recollection ties diagram generation directly to debugger stepping and executable explanation."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "http://code.fed.wiki.org/view/diagramming-debugger")))

(defun python-json-tool-source-topic ()
  (make-topic
   :id "python-json-tool-source"
   :title "Python json.tool source"
   :summary "The json.tool CLI lives in the Python standard library module json/tool.py and can be inspected locally via json.tool.__file__."
   :references '("Python json.tool Source and Usage"
                 "https://github.com/python/cpython/blob/main/Lib/json/tool.py")))

;;
