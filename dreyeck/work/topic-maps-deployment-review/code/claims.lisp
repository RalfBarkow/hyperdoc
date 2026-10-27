;;;; Claims and How Each Is Known
(in-package #:topic-maps-deployment-review)

;;; A claim says one thing about the candidate and how it is known:
;;;   :observed  a recorded run, or this reading when shown, saw it;
;;;   :derived   it follows from source or evaluation, nothing ran it;
;;;   :inferred  it is expected from other facts and still needs a test;
;;;   :open      it is not done or not known.
;;; Its evidence is recorded runs; its sources are the definitions it is about.

(defclass review-claim ()
  ((id :initarg :id :reader claim-id)
   (statement :initarg :statement :reader claim-statement)
   (class :initarg :class :reader claim-class)
   (evidence :initarg :evidence :initform nil :reader claim-evidence)
   (sources :initarg :sources :initform nil :reader claim-sources)
   (page :initarg :page :reader claim-page)
   (limit :initarg :limit :initform nil :reader claim-limit :documentation "What the evidence does not show.")))
(defmethod v:text-representation ((c review-claim)) (format nil "~A (~(~A~))" (claim-statement c) (claim-class c)))

(defun function-of (package name) (symbol-function (find-symbol name package)))

(defvar *claims* nil)
(defun claims ()
  (or *claims*
      (setf *claims*
            (flet ((claim (id class page statement evidence sources &optional limit)
                     (make-instance 'review-claim :id id :class class :page page :statement statement
                                    :evidence (mapcar #'evidence evidence) :sources sources :limit limit)))
              (list
               (claim "archive-is-the-commit" :observed "From Git Commit to Verified Snapshot"
                      "The archive holds exactly the files of b2eecffa without reports/: the same paths, modes and blob ids, no links, no submodules, no attribute that rewrites bytes."
                      '("archive-verification.json" "archive-controls.log")
                      (list (file-named "scripts/topic-maps-snapshot.py") (excerpt "snapshot:attributes") (file-named "nix/topic-maps-b2eecffa.manifest"))
                      "Checked against the local repository, which is the authority. Nothing is published.")
               (claim "snapshot-verified-without-git" :observed "What the Snapshot Verifier Establishes"
                      "The /nix/store snapshot hashes, without .git, to the commit's objects: commit, root tree, shipped entries; reports/ is named and not shipped."
                      '("package-check/lisp.log" "checkout-source-snapshot.log" "mutants.log")
                      (list #'snap:verify-snapshot-tree #'snap:verify-store-snapshot #'snap:source-kind (excerpt "nix:source"))
                      "Git's object ids are SHA-1; the SHA-256 NAR hash pins the same bytes independently. The commit's SSH signature is not verified.")
               (claim "git-checks-unchanged" :derived "What the Snapshot Verifier Establishes"
                      "Only the 22U reading and the CTM review accept a verified snapshot; their Git branch is the old Git check, and every other Git-only check is untouched."
                      '("checkout-review-22u.log")
                      (list #'ex:checked-source-evidence (file-named "dreyeck/work/topic-maps-project-example.lisp")
                            (function-of :dreyeck/work/tmdm-reading "CHECKED-REPOSITORY"))
                      "Read from the diff: no other Git check is in a changed file. The checkout suites show the Git branch still works.")
               (claim "origins-are-the-snapshot" :observed "Where ASDF Finds the Sources"
                      "In the package every Topic Maps system comes from the one verified store snapshot, and the registry holds exactly one topic-maps.asd."
                      '("package-check/lisp.log" "package-check/topic-maps-asd")
                      (list #'c:topic-maps-origins (excerpt "nix:wrapper") (excerpt "topic-maps.asd:ctm")))
               (claim "separate-package" :observed "Why a Separate Nix Package"
                      "hyperdoc-catalog is unchanged by the candidate apart from HyperDoc's own source path and the output path that follows from it."
                      '("catalog-unchanged-x86_64-linux.json" "catalog-unchanged-x86_64-darwin.json" "catalog-control-changed-wrapper.json" "production-check.log")
                      (list (excerpt "flake:production") (excerpt "nix:production-wrapper") (excerpt "flake:variant"))
                      "For x86_64-linux this comparison is an evaluation; the package and its check were built separately on Linux (see the Linux claim).")
               (claim "workspace-refused" :observed "Keeping the Project Workspace Out"
                      "The packaged executable refuses dreyeck/work/project, its subsystems and anything depending on them at startup, before the Catalog loads or serves anything, so its Topic Maps 5a4a668 binding never meets b2eecffa in one image."
                      '("after-guard-correction/executable.log" "after-guard-correction/contract-lisp.log")
                      (list #'c:refuse-project-workspace (excerpt "startup:guard") (excerpt "workspace:pin") (excerpt "asd:catalog-topic-maps"))
                      "At startup only, and for ASDF only: a load made later by other means, or a raw LOAD of the workspace's files, is not refused (see the claim on the guard's scope). Run by hand from a store copy of the source, not in a Nix sandbox build.")
               (claim "page-attached-loader-out" :observed "Keeping the Project Workspace Out"
                      "The one application path that loads a system named by a wiki page after startup, dreyeck/page-attached-hyperdoc, is refused as a catalog system, with the systems that depend on it, and is not in the optional runtime: a wiki page cannot name a system to load, the Project Workspace included."
                      '("after-guard-correction/contract-lisp.log" "after-guard-correction/asdf-methods.log")
                      (list #'c:loader-system-p #'c:refuse-project-workspace (excerpt "startup:guard"))
                      "The Lisp critic's loader and the reconstruction runner are in the runtime and refuse in a served runtime that is not in development mode: the contract checks that gate, not each loader.")
               (claim "guard-scope" :derived "Keeping the Project Workspace Out"
                      "The guard is a check of the Catalog's startup, made once. It does not stop a load made later by other means, such as asdf:load-system at a Lisp prompt in the running image; the executable has none."
                      nil (list #'c:refuse-project-workspace #'c:main (file-named "docs/topic-maps-deployment/staging.md"))
                      "Derived from the source: what the guard protects and what it does not is written in docs/topic-maps-deployment/staging.md.")
               (claim "guard-replaces-asdf-methods" :observed "Keeping the Project Workspace Out"
                      "The first version of the guard replaced two of ASDF's own methods, operate :before (t t) and perform :before (operation component). The corrected guard defines no method on any ASDF generic function: every ASDF method object is the same object before and after loading it."
                      '("after-guard-correction/asdf-methods.log") (list (method-origins) (excerpt "startup:guard-methods") (excerpt "startup:guard"))
                      "The first version's replacement is recorded by the collision probe (The ASDF Method Collision), whose records are kept unchanged. The corrected guard's evidence is a fresh-process test, run by hand with the pinned SBCL, not in a Nix sandbox build.")
               (claim "lineages-differ" :observed "Keeping the Project Workspace Out"
                      "5a4a668 is not an ancestor of b2eecffa: the two Topic Maps revisions are separate lineages."
                      nil (list (excerpt "workspace:pin"))
                      "Observed by asking Git in the topic-maps repository each time the subjects are projected; see the relation in the Topicmap.")
               (claim "loopback-only" :observed "Execution Authority"
                      "The packaged executable serves loopback only: 0.0.0.0, ::, localhost and dreyeck.ch are refused with exit 2 before anything is loaded."
                      '("package-check/executable.log") (list (excerpt "main:host")))
               (claim "plain-thunks-ungated" :derived "Execution Authority"
                      "Plain v:thunk run buttons, such as the 22U and CTM review buttons and this reading's own, are not gated by dreyeck/authority-policy in a served, non-development Catalog; DEFEXAMPLE buttons are."
                      nil (list (function-of :dreyeck/authority-policy "POLICY-ENFORCED-P") (function-of :dreyeck/authority-policy "EXAMPLE-INVOCATION-DECISION"))
                      "Derived from source. This reading lets you observe it: its run buttons are plain thunks, and Execution Authority says what to look for.")
               (claim "scheme-plus-preserved" :observed "Tested and Unverified"
                      "The CTM review still reads its control and refutes scheme-plus with INVALID-OCCURRENCE-LITERAL at character 3, from the checkout and from the store snapshot."
                      '("checkout-review-22u.log" "package-check/lisp.log" "browser-review-checkout.json" "browser-review-snapshot.json")
                      (list (function-of :dreyeck/work/topic-maps-ctm-review "RUN-CLAIM-EXPERIMENT")))
               (claim "production-startup-darwin" :observed "Tested and Unverified"
                      "The production Catalog's own startup check passes on the candidate tree."
                      '("production-check.log") (list (excerpt "flake:production")) "x86_64-darwin only.")
               (claim "fasl-cache-correction" :observed "Tested and Unverified"
                      "Earlier review runs compiled into the user-level ~/.cache/common-lisp, not into a temporary cache; the runs recorded here use a fresh XDG_CACHE_HOME or the sandbox's empty HOME."
                      '("package-check/lisp.log") (list (file-named "docs/topic-maps-22u-integration/README.md")))
               (claim "hyperdoc-revision-stated" :derived "Tested and Unverified"
                      "In the package, HyperDoc's own revision is the one the flake states (self.rev, or self.dirtyRev); the store source has no .git to check it."
                      nil (list (excerpt "nix:wrapper") (function-of :dreyeck/work/topic-maps-ctm-review "%HYPERDOC-STATE")))
               (claim "linux-unbuilt" :observed "Tested and Unverified"
                      "hyperdoc-catalog-topic-maps and its check build on x86_64-linux in an independent builder, not the production server, and the package contract passes there: the four Lisp suites, the fresh-process ASDF preservation test and the executable contract. The snapshot has the same store path and NAR hash there, reconstructed from its 1,033,963-octet archive."
                      '("after-guard-correction/x86_64-linux/nix-build.log" "after-guard-correction/x86_64-linux/contract-lisp.log"
                        "after-guard-correction/x86_64-linux/asdf-methods.log" "after-guard-correction/x86_64-linux/executable.log"
                        "after-guard-correction/x86_64-linux/builder-and-snapshot.txt")
                      (list (excerpt "nix:source") (file-named "nix/catalog-topic-maps-check.nix"))
                      "The builder is a local Docker Desktop Linux VM whose Nix sandbox is off (the image's setting), so this is a Nix build but not a sandboxed one. The tree built is identified in the records; the evidence index says how it relates to the commit.")
               (claim "linux-reading-packaged" :observed "Tested and Unverified"
                      "In the Linux package's runtime, with no .git, this reading loads and its three suites pass; the packaged executable serves it on 127.0.0.1 only, answers HTTP and stops cleanly on SIGTERM; and a browser reached and walked it through a forwarder to a published port."
                      '("after-guard-correction/x86_64-linux/packaged-reading.log" "after-guard-correction/x86_64-linux/browser-walk.json")
                      (list #'c:main (file-named "nix/catalog-topic-maps.nix"))
                      "The forwarder is the operator's tunnel pattern, not a deployment: the executable stayed bound to loopback inside the builder. The browser ran on the Mac, against the Linux-served reading.")
               (claim "unpublished" :open "Tested and Unverified"
                      "The archive is not published: the release URL in nix/topic-maps-source.nix does not exist, so a store without the snapshot cannot build the package from Nix inputs alone. A builder obtains it only by having it added to its store from the archive, as the Linux builder did."
                      nil (list (excerpt "nix:source") (file-named "docs/topic-maps-deployment/staging.md")) "Publication needs approval (D2).")
               (claim "not-deployed" :open "Tested and Unverified"
                      "Nothing is pushed or deployed and no server was touched; the candidate is committed locally. The staging module is evaluated and documented, not run."
                      nil (list (file-named "nix/nixos-staging.nix") (file-named "docs/topic-maps-deployment/staging.md")) "D4 and Phase D."))))))
(defun claim (id) (or (find id (claims) :key #'claim-id :test #'string=) (error "No claim ~S." id)))

(v:defview review-claim-view (claim review-claim)
  (v:html-view :title "Claim" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (claim-statement claim)))
       (:p (:strong (v:esc (string-downcase (claim-class claim))))
           (v:esc (ecase (claim-class claim)
                    (:observed " — a recorded run saw it, or this reading sees it when shown.")
                    (:derived " — it follows from source or evaluation; nothing ran it.")
                    (:inferred " — expected from other facts; still to be tested.")
                    (:open " — not done or not known."))))
       (when (claim-limit claim) (v:html (:p (:em "Limit: ") (v:esc (claim-limit claim)))))
       (:h3 "Evidence")
       (if (claim-evidence claim)
           (v:html (:ul (dolist (e (claim-evidence claim)) (v:html (:li (v:object-ref e :select "Record"))))))
           (v:html (:p "No recorded run.")))
       (:h3 "What it is about")
       (if (claim-sources claim)
           (v:html (:ul (dolist (s (claim-sources claim))
                          (v:html (:li (v:object-ref s :select (typecase s (function "Source code") (source-excerpt "Source excerpt")
                                                                 (candidate-file "Candidate file") (t nil))))))))
           (v:html (:p "Nothing to inspect.")))
       (:p "Explained in " (v:object-ref (review-page (claim-page claim)) :select "Content"))
       (reading-links)))))
