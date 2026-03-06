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

(defun create-sd-card-from-playground-task-topic ()
  (make-topic
   :id "create-sd-card-from-playground-task"
   :title "Create NixOS SD card from HyperDoc Playground task"
   :summary "DITA-style task for producing and flashing a Raspberry Pi NixOS SD card using runbook-aligned command plans from Playground."
   :references '("Create NixOS SD Card from HyperDoc Playground"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Prepare the AArch64 image")))

(defun sd-card-command-plan-playground-topic ()
  (make-topic
   :id "sd-card-command-plan-playground"
   :title "SD card command plan in Playground"
   :summary "Inspectable command-plan and dry-run functions that mirror the official runbook sequence."
   :references '("Create NixOS SD Card from HyperDoc Playground"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "SBCL Process")))

(defun sd-card-procedure-step-raw-structure-fix-topic ()
  (make-topic
   :id "sd-card-procedure-step-raw-structure-fix"
   :title "SD-card procedure-step raw-structure fix"
   :summary "Raw Structure now derives from semantic step slots via computed raw-structure, preventing NIL views when id/title/summary/commands are present."
   :references '("Create NixOS SD Card from HyperDoc Playground"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "official-rpi-tutorial-step-raw-structure-regression-example"
                 "a735927")))

(defun semantic-navigation-visible-clickable-topic ()
  (make-topic
   :id "semantic-navigation-visible-clickable"
   :title "Semantic navigation visible and clickable"
   :summary "Primary navigation must stay semantic, visible, and clickable; raw structure is diagnostics-only and must not become the primary path."
   :references '("Create NixOS SD Card from HyperDoc Playground"
                 "Surface and Artifact Answers"
                 "Communication Surfaces Policy")))

(defun runbook-build-and-flash-sd-image-topic ()
  (make-topic
   :id "runbook-build-and-flash-sd-image"
   :title "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
   :summary "Operational sequence to obtain a named .img.zst artifact, decompress to .img, flash the .img, boot, and validate on Pi 4."
   :references '("Prepare the AArch64 image")))

(defun official-rpi-sd-image-tutorial-topic ()
  (make-topic
   :id "official-rpi-sd-image-tutorial"
   :title "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
   :summary "Upstream nix.dev SD-image workflow: preinstalled image, first rebuild with nixos-rebuild boot, then reboot."
   :references '("Prepare the AArch64 image")))

(defun sd-image-zstd-to-img-handoff-defect-topic ()
  (make-topic
   :id "sd-image-zstd-to-img-handoff-defect"
   :title "SD-image zstd-to-img handoff defect"
   :summary "Relation bug between official steps 1 and 2: download produces .zstd while flash requires .img; fixed by explicit decompression step, with .img.zst/.img coexistence treated as normal."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Create NixOS SD Card from HyperDoc Playground"
                 "Violated handoff"
                 "official-rpi-zstd-to-img-handoff-regression-example")))

(defun hydra-latest-filename-handoff-defect-topic ()
  (hydra-filename-loss-topic))

(defun hydra-filename-loss-topic ()
  (make-topic
   :id "hydra-filename-loss"
   :title "Hydra filename loss"
   :summary "Failure classification: naive latest/download/1 retrieval can save as file '1', losing artifact filename provenance and requiring recovery."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "SD-image zstd-to-img handoff defect"
                 "Create NixOS SD Card from HyperDoc Playground"
                 "official-rpi-hydra-filename-preservation-regression-example")))

(defun expr-string-quoting-regression-topic ()
  (make-topic
   :id "expr-string-quoting-regression"
   :title "Expr string quoting regression"
   :summary "Resolved regression where expr links with Lisp string args rendered visible labels but produced no clickable inspector refs."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "writing-pages.md"
                 "da8c815"
                 "3cf4ff4")))

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

(defun nixos-image-sd-card-26-05pre958232-80bdc1e5ce51-aarch64-linux-img-zst-topic ()
  (make-topic
   :id "nixos-image-sd-card-26-05pre958232-80bdc1e5ce51-aarch64-linux-img-zst"
   :title "nixos-image-sd-card-26.05pre958232.80bdc1e5ce51-aarch64-linux.img.zst"
   :summary "Concrete Hydra SD-image artifact filename selected for the current aarch64 preparation flow."
   :references '("Prepare the AArch64 image"
                 "Hydra build 323111513"
                 "https://hydra.nixos.org/build/323111513/download/1/nixos-image-sd-card-26.05pre958232.80bdc1e5ce51-aarch64-linux.img.zst")))

(defun hydra-click-path-hop-topic ()
  (make-topic
   :id "hydra-click-path-hop"
   :title "Hydra click-path hop"
   :summary "A single navigational step in the tutorial Hydra path: job page -> build page -> concrete artifact download."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Hydra latest SD-image job"
                 "Hydra build 323111513"
                 "nixos-image-sd-card-26.05pre958232.80bdc1e5ce51-aarch64-linux.img.zst")))

(defun hydra-latest-download-link-topic ()
  (make-topic
   :id "hydra-latest-download-link"
   :title "Hydra latest download link"
   :summary "Stable 'latest' download-by-type link for SD-image artifacts."
   :references '("https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download-by-type/file/sd-image"
                 "https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download/1")))

(defun hydra-download-artifact-procedure-topic ()
  (make-topic
   :id "hydra-download-artifact-procedure"
   :title "Download artifact from Hydra"
   :summary "Normative successful path: download named .img.zst via wget --trust-server-names, verify it, decompress to .img, and use .img as flash input while .img.zst may remain as preserved download identity."
   :references '("Prepare the AArch64 image"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Hydra artifact to flashable image handoff"
                 "Hydra latest SD-image job"
                 "Hydra latest download link"
                 "Hydra filename loss"
                 "hydra-filename-outcome-states-example")))

(defun hydra-artifact-to-flashable-image-handoff-topic ()
  (make-topic
   :id "hydra-artifact-to-flashable-image-handoff"
   :title "Hydra artifact to flashable image handoff"
   :summary "Decompression handoff transforms the downloaded .img.zst artifact into a flashable .img; both files may coexist afterward and only .img is flash input."
   :references '("Prepare the AArch64 image"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "hydra-filename-outcome-states-example")))

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
   :summary "Decompress the .img.zst artifact into a flashable .img using zstd/unzstd; .img.zst and .img may coexist afterward."
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

(defun journal-checker-commit-gate-topic ()
  (make-topic
   :id "journal-checker-commit-gate"
   :title "Journal checker commit gate"
   :summary "FedWiki page commits must pass creation/chronology/revision/malformed checks; syntax-only json.tool is not sufficient."
   :references '("Journalmatic Journal Checker"
                 "Journal Gate Script and Lisp Implementation"
                 "HyperBook Journal Tools"
                 "Python json.tool Source and Usage")))

(defun journal-gate-script-lisp-topic ()
  (make-topic
   :id "journal-gate-script-lisp"
   :title "Journal gate script and Lisp implementation"
   :summary "Lisp gate functions expose commit blocking for CREATION/CHRONOLOGY/REVISION/MALFORMED and provide inspectable pass/fail results."
   :references '("Journalmatic Journal Checker"
                 "Journal Gate Script and Lisp Implementation"
                 "HyperBook Journal Tools"
                 "journalmatic-commit-gate-script-example")))

(defun journal-date-origin-and-fork-chronology-topic ()
  (make-topic
   :id "journal-date-origin-and-fork-chronology"
   :title "Journal date origin and fork chronology"
   :summary "Action dates use runtime epoch millis with monotonic rule max(now, last-date + 1); avoid hardcoded timestamps to prevent fork-induced chronology errors."
   :references '("Journal Gate Script and Lisp Implementation"
                 "Journalmatic Journal Checker"
                 "journalmatic-date-origin-example")))

(defun journal-monotonic-normalization-topic ()
  (make-topic
   :id "journal-monotonic-normalization"
   :title "Journal monotonic normalization"
   :summary "Normalize journal action dates in existing action order so dates become monotonic and replay remains reconstructable."
   :references '("Journal Gate Script and Lisp Implementation"
                 "Journalmatic Repair Tools"
                 "journalmatic-monotonic-normalization-example")))

(defun fedwiki-page-generation-workflow-topic ()
  (make-topic
   :id "fedwiki-page-generation-workflow"
   :title "FedWiki page-generation workflow"
   :summary "Reproducible Lisp page generation uses deterministic story/journal construction plus wiki-client-style date assignment (max(now, last+1))."
   :references '("FedWiki Page-Generation Workflow"
                 "Journal Gate Script and Lisp Implementation"
                 "journalmatic-page-generation-workflow-example"
                 "journalmatic-page-generation-wiki-client-style-example"
                 "https://github.com/fedwiki/wiki-client/commit/d4420c72a49305ca52d18ce8203bc95bdd3f59d2")))

(defun git-blame-operation-topic ()
  (make-topic
   :id "git-blame-operation"
   :title "Git blame operation"
   :summary "Use git blame on exact file lines to prove which commit introduced timestamp behavior in wiki-client."
   :references '("FedWiki Page-Generation Workflow"
                 "wiki-client-blame-operation-example"
                 "https://github.com/fedwiki/wiki-client/commit/d4420c72a49305ca52d18ce8203bc95bdd3f59d2")))

(defun fedwiki-story-item-id-policy-topic ()
  (make-topic
   :id "fedwiki-story-item-id-policy"
   :title "FedWiki story item id policy"
   :summary "Use stable, opaque story item ids (canonical 16-hex form) in journaled pages; semantic labels belong in text, slugs, and topic ids."
   :references '("FedWiki Story Item IDs"
                 "Journalmatic Journal Checker"
                 "Python json.tool Source and Usage")))

(defun fedwiki-id-runtime-contract-topic ()
  (make-topic
   :id "fedwiki-id-runtime-contract"
   :title "FedWiki id runtime contract"
   :summary "Wiki client and server treat item ids as replay keys for add/edit/remove/move journal actions; id stability is a runtime contract."
   :references '("FedWiki Story Item IDs"
                 "Journalmatic Revision Replay"
                 "Journalmatic Journal Checker")))

(defun semantic-item-id-effects-topic ()
  (make-topic
   :id "semantic-item-id-effects"
   :title "Semantic item id effects"
   :summary "Semantic item ids can improve readability but increase coupling to wording and can raise replay breakage risk during refactors."
   :references '("FedWiki Story Item IDs"
                 "Journalmatic Repair Tools"
                 "Journalmatic Journal Checker")))

(defun fedwiki-id-normalization-map-topic ()
  (make-topic
   :id "fedwiki-id-normalization-map"
   :title "FedWiki id normalization map"
   :summary "Old-to-new story/journal id mapping artifacts preserve lookup after bulk semantic-to-opaque id normalization."
   :references '("FedWiki Story Item IDs"
                 "fedwiki-story-id-normalization-map-2026-03-06"
                 "Journalmatic Journal Checker")))

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

(defun sbcl-process-topic ()
  (make-topic
   :id "sbcl-process"
   :title "SBCL process"
   :summary "A running SBCL image with its own package state, loaded systems, source registry, and thread-local debugger context."
   :references '("SBCL Process"
                 "ASDF Components Workflow"
                 "HyperDoc Server")))

(defun sbcl-topic ()
  (make-topic
   :id "sbcl"
   :title "SBCL"
   :summary "Steel Bank Common Lisp implementation used to run HyperDoc systems, compile components, and host server/inspector runtime behavior."
   :references '("SBCL"
                 "SBCL Process"
                 "ASDF Components Workflow"
                 "HyperDoc Server")))

(defun isolated-evaluation-workers-topic ()
  (make-topic
   :id "isolated-evaluation-workers"
   :title "Isolated evaluation workers"
   :summary "Run risky evaluation in dedicated worker processes or sandboxes only where needed, while keeping main server state stable."
   :references '("SBCL Process"
                 "Stepper Debugger Surface"
                 "HyperDoc Server")))

(defun fedwiki-content-runtime-policy-split-topic ()
  (make-topic
   :id "fedwiki-content-runtime-policy-split"
   :title "FedWiki content and runtime policy split"
   :summary "Keep page identity and content in FedWiki; keep runtime execution policy in HyperDoc/inspector tooling."
   :references '("SBCL Process"
                 "FedWiki Story Item IDs"
                 "HyperDoc Server")))

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

(defun diagramming-debugger-surface-topic ()
  (make-topic
   :id "diagramming-debugger-surface"
   :title "Diagramming Debugger Surface"
   :summary "Playground diagramming debugger that records step events and derives collaboration/message traces."
   :references '("Diagramming Debugger Surface"
                 "Stepper Debugger Surface")))

(defun step-trace-message-events-topic ()
  (make-topic
   :id "step-trace-message-events"
   :title "Step trace message events"
   :summary "Each Playground step is captured as an event with form source, extracted call symbols, and success/error status."
   :references '("Diagramming Debugger Surface")))

(defun graphviz-sequence-export-topic ()
  (make-topic
   :id "graphviz-sequence-export"
   :title "Graphviz sequence export"
   :summary "Diagramming debugger exports Graphviz DOT text for collaboration-flow rendering."
   :references '("Diagramming Debugger Surface")))

;; Backward-compatibility alias.
(defun mermaid-sequence-export-topic ()
  (graphviz-sequence-export-topic))

(defun playground-stepper-class-layout-topic ()
  (make-topic
   :id "playground-stepper-class-layout"
   :title "Playground stepper class layout"
   :summary "Slot layout for playground-stepper state: object/package/source/forms/index/last-value/last-error/parse-report/done?."
   :references '("Diagramming Debugger Surface"
                 "Stepper Debugger Surface"
                 "hyperbook-server/playground-stepper.lisp")))

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

;; Topic objects for answer-surface distinction.
(defun surface-answer-topic ()
  (make-topic
   :id "surface-answer"
   :title "Surface Answer"
   :summary "Immediate terminal/Codex response that states the current result and decisions in the active session."
   :references '("Surface and Artifact Answers"
                 "Communication Surfaces Policy")))

(defun artifact-answer-topic ()
  (make-topic
   :id "artifact-answer"
   :title "Artifact Answer"
   :summary "Durable answer captured as HyperDoc/FedWiki/Lisp artifacts that can be replayed and inspected later."
   :references '("Surface and Artifact Answers"
                 "Communication Surfaces Policy")))

(defun reconstruction-protocol-topic ()
  (make-topic
   :id "reconstruction-protocol"
   :title "Reconstruction protocol"
   :summary "Protocol requiring each answer to include process trace, artifact deltas, and replay checks."
   :references '("Surface and Artifact Answers"
                 "Communication Surfaces Policy")))

(defun skillization-loop-topic ()
  (make-topic
   :id "skillization-loop"
   :title "Skillization loop"
   :summary "Recurring workflow extraction into callable Lisp/skill routines so repeated tasks move from ad-hoc execution to reusable runtime behavior."
   :references '("Surface and Artifact Answers"
                 "ASDF Components Workflow")))

(defun codex-resume-branch-context-topic ()
  (make-topic
   :id "codex-resume-branch-context"
   :title "Codex resume branch context"
   :summary "Codex resume exposes the related git branch per session; interpret and replay session outputs in that branch context."
   :references '("Surface and Artifact Answers"
                 "Communication Surfaces Policy")))

(defun hyperdoc-operating-environment-assessment-2026-03-06-topic ()
  (make-topic
   :id "hyperdoc-operating-environment-assessment-2026-03-06"
   :title "HyperDoc Operating Environment Assessment 2026-03-06"
   :summary "Assessment that frames HyperDoc as a documented operating environment with explicit maintenance doctrine, highlights three-surface drift risk, and recommends stronger semantic indexing and routine smoke checks."
   :references '("HyperDoc Operating Environment Assessment 2026-03-06"
                 "Communication Surfaces Policy"
                 "ASDF Components Workflow"
                 "HyperDoc Server"
                 "Stepper Debugger Surface"
                 "Diagramming Debugger Surface")))

(defun violated-handoff-topic ()
  (make-topic
   :id "violated-handoff"
   :title "Violated handoff"
   :summary "A handoff is violated when a claimed completed transfer lacks the artifacts, links, or replay checks needed for the receiver to continue without re-deriving context."
   :references '("Surface and Artifact Answers"
                 "Communication Surfaces Policy"
                 "Reconstruction protocol")))

(defun express-both-sides-of-handoff-without-manually-reversing-perspective-topic ()
  (make-topic
   :id "express-both-sides-handoff-without-manually-reversing-perspective"
   :title "Express both sides of a handoff without manually reversing perspective"
   :summary "Model a handoff as one inspectable relation object that exposes producer output and consumer precondition simultaneously, avoiding perspective-flip narration."
   :references '("Violated handoff"
                 "SD-image zstd-to-img handoff defect"
                 "Reconstruction protocol")))

(defun prose-to-object-bridge-topic ()
  (make-topic
   :id "prose-to-object-bridge"
   :title "Prose to object bridge"
   :summary "Operational claims in prose should expose clickable inspectable objects so execution and replay can start from semantic objects, not raw structure."
   :references '("Surface and Artifact Answers"
                 "Create NixOS SD Card from HyperDoc Playground"
                 "Communication Surfaces Policy")))

(defun display-argument-removal-topic ()
  (make-topic
   :id "display-argument-removal"
   :title "Remove :display argument"
   :summary "Remove explicit :display overrides and rely on each object's text representation for consistent semantic navigation labels."
   :references '("Surface and Artifact Answers"
                 "Writing text pages"
                 "Defining custom views")))

(defun semantic-object-ref-renderer-topic ()
  (make-topic
   :id "semantic-object-ref-renderer"
   :title "Semantic object-ref renderer"
   :summary "Confirmed: the SD-card command-plan renderer uses semantic object-ref links for navigation, with raw structure kept as diagnostics-only."
   :references '("Create NixOS SD Card from HyperDoc Playground"
                 "Surface and Artifact Answers"
                 "sd-card-primary-semantic-entrypoints-example")))

;; Kioskberrli hardware context topics.
(defun satechi-usbc-pro-hub-4k-hdmi-topic ()
  (make-topic
   :id "satechi-usbc-pro-hub-4k-hdmi"
   :title "Satechi USB-C Pro Hub (4K HDMI)"
   :summary "Display and peripheral adapter used in the Kioskberrli setup to provide HDMI output and hub functionality from USB-C."
   :references '("Kioskberrli"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun sd-card-topic ()
  (make-topic
   :id "sd-card"
   :title "SD card"
   :summary "Primary removable storage medium for flashing and booting kiosk images in the Kioskberrli workflow."
   :references '("Kioskberrli"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Prepare the AArch64 image")))

(defun micro-sd-card-topic ()
  (make-topic
   :id "micro-sd-card"
   :title "Micro SD card"
   :summary "Physical microSD form-factor card used by Raspberry Pi platforms for NixOS image boot media."
   :references '("Kioskberrli"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images")))

(defun transcend-16gb-micro-sd-card-topic ()
  (make-topic
   :id "transcend-16gb-micro-sd-card"
   :title "Transcend 16GB Micro SD Card"
   :summary "Concrete selected boot medium for the current Kioskberrli image/flash task."
   :references '("Kioskberrli"
                 "Prepare the AArch64 image"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun dita-task-topic-topic ()
  (make-topic
   :id "dita-task-topic"
   :title "DITA task topic"
   :summary "Task representation style using DITA task-topic structure (context, prerequisites, steps, result) for operational runbooks."
   :references '("Prepare the AArch64 image"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Surface and Artifact Answers")))

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
   :summary "Citation anchor: Ward Cunningham and Kent Beck, OOPSLA 1986 (Portland), frame object-collaboration diagrams as executable explanation work."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "https://c2.com/doc/case87.html")))

(defun ward-collaborating-objects-topic ()
  (make-topic
   :id "ward-collaborating-objects"
   :title "Collaborating objects diagrams"
   :summary "Ward first drew collaboration diagrams by hand in the Computer Research Lab to explain object behavior to colleagues."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "https://c2.com/doc/case87.html")))

(defun class-browser-inspector-debugger-triangulation-topic ()
  (make-topic
   :id "class-browser-inspector-debugger-triangulation"
   :title "Class browser/inspector/debugger triangulation"
   :summary "Diagram extraction combined three windows: class browser, object inspector, and single-step debugger."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Stepper Debugger Surface")))

(defun compiledmethod-interpretnextinstruction-topic ()
  (make-topic
   :id "compiledmethod-interpretnextinstruction"
   :title "CompiledMethod interpretNextInstructionFor: aContext"
   :summary "This stepping primitive exposed execution semantics; once identified, only drawing what it says remained."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "https://c2.com/doc/case87.html")))

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
                 "Diagramming Debugger")))

(defun mech-op-args-emit-dispatch-topic ()
  (make-topic
   :id "mech-op-args-emit-dispatch"
   :title "Mech op/args and emit dispatch"
   :summary "Mech mirrors the same seam: split command into op/args, assemble execution context, then dispatch to blocks[op].emit."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Mech Credible Maintenance Story")))

(defun python-json-tool-source-topic ()
  (make-topic
   :id "python-json-tool-source"
   :title "Python json.tool source"
   :summary "The json.tool CLI lives in the Python standard library module json/tool.py and can be inspected locally via json.tool.__file__."
   :references '("Python json.tool Source and Usage"
                 "https://github.com/python/cpython/blob/main/Lib/json/tool.py")))

;; Civilian resilience topics for autonomous-weapons threat environments.
(defun surviving-autonomous-weapons-environment-topic ()
  (make-topic
   :id "surviving-in-an-autonomous-weapons-environment"
   :title "Surviving in an Autonomous Weapons Environment"
   :summary "Civilian resilience baseline for preserving life, service continuity, and accountability under autonomous-threat conditions."
   :references '("Surviving in an Autonomous Weapons Environment"
                 "Autonomous Weapons Resilience Playbook"
                 "Post-Incident Recovery Under Autonomous Threat")))

(defun autonomous-weapons-resilience-playbook-topic ()
  (make-topic
   :id "autonomous-weapons-resilience-playbook"
   :title "Autonomous Weapons Resilience Playbook"
   :summary "Layered preparedness, protection, continuity, and recovery framework for civilian communities exposed to autonomous weapons risks."
   :references '("Autonomous Weapons Resilience Playbook"
                 "Surviving in an Autonomous Weapons Environment")))

(defun post-incident-recovery-under-autonomous-threat-topic ()
  (make-topic
   :id "post-incident-recovery-under-autonomous-threat"
   :title "Post-Incident Recovery Under Autonomous Threat"
   :summary "Post-incident stabilization and recovery model centered on evidence preservation, service restoration, and institutional learning."
   :references '("Post-Incident Recovery Under Autonomous Threat"
                 "Autonomous Weapons Resilience Playbook")))

(defun autonomous-weapons-civilian-resilience-topic ()
  (make-topic
   :id "autonomous-weapons-civilian-resilience"
   :title "Autonomous-weapons civilian resilience"
   :summary "Operational view of civilian resilience capabilities required when autonomous systems compress warning and response windows."
   :references '("Autonomous Weapons Resilience Playbook"
                 "Surviving in an Autonomous Weapons Environment")))

(defun autonomous-threat-risk-model-topic ()
  (make-topic
   :id "autonomous-threat-risk-model"
   :title "Autonomous-threat risk model"
   :summary "Risk model combining infrastructure dependency, warning reliability, and disruption impact under autonomous-threat scenarios."
   :references '("Autonomous Weapons Resilience Playbook")))

(defun protective-infrastructure-hardening-topic ()
  (make-topic
   :id "protective-infrastructure-hardening"
   :title "Protective infrastructure hardening"
   :summary "Practical hardening focus on shelters, power, communications, and medical services to reduce civilian harm."
   :references '("Autonomous Weapons Resilience Playbook")))

(defun civilian-alerting-fallback-channels-topic ()
  (make-topic
   :id "civilian-alerting-fallback-channels"
   :title "Civilian alerting fallback channels"
   :summary "Redundant alert and coordination channels used when primary communications are degraded or unavailable."
   :references '("Autonomous Weapons Resilience Playbook"
                 "Surviving in an Autonomous Weapons Environment")))

(defun disinformation-verification-loop-topic ()
  (make-topic
   :id "disinformation-verification-loop"
   :title "Disinformation verification loop"
   :summary "Structured verification cycle for filtering false reports and preserving trusted situational awareness."
   :references '("Autonomous Weapons Resilience Playbook")))

(defun continuity-of-care-under-disruption-topic ()
  (make-topic
   :id "continuity-of-care-under-disruption"
   :title "Continuity of care under disruption"
   :summary "Medical and social-care continuity planning for prolonged disruption and contested logistics."
   :references '("Autonomous Weapons Resilience Playbook"
                 "Post-Incident Recovery Under Autonomous Threat")))

(defun autonomous-weapons-governance-accountability-topic ()
  (make-topic
   :id "autonomous-weapons-governance-accountability"
   :title "Autonomous-weapons governance accountability"
   :summary "Governance requirement to preserve human accountability, evidence trails, and legal oversight during and after incidents."
   :references '("Autonomous Weapons Resilience Playbook"
                 "Post-Incident Recovery Under Autonomous Threat")))

(defun incident-ledger-and-evidence-topic ()
  (make-topic
   :id "incident-ledger-and-evidence"
   :title "Incident ledger and evidence"
   :summary "Structured incident ledger and chain-of-custody practices that support reliable recovery and review."
   :references '("Post-Incident Recovery Under Autonomous Threat")))

(defun service-restoration-prioritization-topic ()
  (make-topic
   :id "service-restoration-prioritization"
   :title "Service restoration prioritization"
   :summary "Prioritization model for restoring essential services under constrained resources after disruptive incidents."
   :references '("Post-Incident Recovery Under Autonomous Threat")))

(defun community-psychological-recovery-topic ()
  (make-topic
   :id "community-psychological-recovery"
   :title "Community psychological recovery"
   :summary "Community mental-health support and social-cohesion recovery operations after persistent high-stress incidents."
   :references '("Post-Incident Recovery Under Autonomous Threat")))

(defun after-action-learning-loop-topic ()
  (make-topic
   :id "after-action-learning-loop"
   :title "After-action learning loop"
   :summary "Closed-loop process for turning incident findings into revised procedures, training, and resilience improvements."
   :references '("Post-Incident Recovery Under Autonomous Threat"
                 "Autonomous Weapons Resilience Playbook")))

;;
