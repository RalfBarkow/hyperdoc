;;;; Handoff run in the operator's white SLY image, 2026-11-20, x86_64-darwin, Catalog on port 8080.
;;;; Loaded with ASDF:LOAD-ASD from a worktree at a2cb1b11; steps 1 and 2 by Play, steps 3 and 4 by PLAY-STEP in the mREPL of the same image.
;;;; Unprivileged user, so C6 ran. Output of HANDOVER-RECEIPT, unchanged.
(:FAQ "asdf-fasl-nix-store" :HANDOFF-COMMIT "07b7f51f13494d11cc48e16a72b01da65b77256c" :BRANCH
 "handoff/faq-asdf-fasl-nix-store-rev2" :REVISION "a2cb1b11fb034ec73ec174f26ae77cd59503db6f" :CLEAN T
 :FLAKE-LOCK "019dcaff428e1abf426f165c3afd70fe163077454d1c348d4965d86a93a7e836" :NIXPKGS
 "50ab793786d9de88ee30ec4e4c24fb4236fc2674" :IMAGE-DREYECK
 ("/Users/rgb/workspace/hyperdoc-dreyeck-ch/" "a2cb1b11fb034ec73ec174f26ae77cd59503db6f") :CHECK-ASDF
 (:PLATFORM "Darwin-x86_64" :SBCL "SBCL 2.4.10" :CASES
  (("C1" "0"
    "/tmp/nix-shell.apJGMB/nix-shell.ERZRWp/tmp.u7egVf0pqc/C1/.cache/common-lisp/sbcl-2.4.10-macosx-x64/nix/store/00000000000000000000000000000000-faq-probe/package.fasl"
    "PASS: destination is outside the store and can be created.")
   ("C2" "0" "/nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/package.fasl"
    "PASS prebuilt: the compiled file is in the store; loading writes nothing, recompiling would fail.")
   ("C3" "0" "/nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/package.fasl"
    "PASS prebuilt: the compiled file is in the store; loading writes nothing, recompiling would fail.")
   ("C4" "1" "/nix/store/00000000000000000000000000000000-faq-probe/package.fasl"
    "FAIL store-destination: ASDF would have to write into the store.")
   ("C5" "1" "/nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/no-such-file.fasl"
    "FAIL store-destination: ASDF would have to write into the store.")
   ("C6" "2"
    "/nonexistent/.cache/common-lisp/sbcl-2.4.10-macosx-x64/nix/store/00000000000000000000000000000000-faq-probe/package.fasl"
    "FAIL not-creatable: /nonexistent/.cache/common-lisp/sbcl-2.4.10-macosx-x64/nix/store/00000000000000000000000000000000-faq-probe/ cannot be created (check HOME or XDG_CACHE_HOME).")
   ("C7" "0"
    "/tmp/nix-shell.apJGMB/nix-shell.ERZRWp/tmp.u7egVf0pqc/C7/.cache/common-lisp/sbcl-2.4.10-macosx-x64/nix/store/00000000000000000000000000000000-faq-probe/package.fasl"
    "PASS read-only: destination is outside the store; creatability not checked.")
   ("C8" "3" "-" "FAIL not-found: system or component not found.")
   ("C9" "0"
    "/tmp/nix-shell.apJGMB/nix-shell.ERZRWp/tmp.u7egVf0pqc/C9/.cache/asdf-nix-store/00000000000000000000000000000000-faq-probe/package.fasl"
    "PASS: destination is outside the store and can be created.")
   ("C10" "0" "/nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/package.fasl"
    "PASS prebuilt: the compiled file is in the store; loading writes nothing, recompiling would fail.")
   ("C11" "0"
    "/tmp/nix-shell.apJGMB/nix-shell.ERZRWp/tmp.u7egVf0pqc/C11/.cache/common-lisp/sbcl-2.4.10-macosx-x64/nix/store/r40b3p08hidpxcf6cvdhfazlvlig1dyn-source/shop3/package.fasl"
    "PASS: destination is outside the store and can be created."))
  :RESTORE
  (("wrapper" "/nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/package.fasl")
   ("override"
    "/tmp/nix-shell.apJGMB/nix-shell.ERZRWp/tmp.u7egVf0pqc/restore/.cache/common-lisp/sbcl-2.4.10-macosx-x64/nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/package.fasl")
   ("without-argument"
    "/tmp/nix-shell.apJGMB/nix-shell.ERZRWp/tmp.u7egVf0pqc/restore/.cache/common-lisp/sbcl-2.4.10-macosx-x64/nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/package.fasl")
   ("with-nil" "/nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/package.fasl"))
  :DEVIATIONS NIL)
 :MAC-LIVE
 (:PLATFORM (:SOFTWARE "Darwin" :MACHINE "X86-64" :LISP "2.4.10" :ASDF "3.3.1" :CATALOG-PORT 8080) :LINES
  ("lisp SBCL 2.4.10" "asdf 3.3.1" "env ASDF_OUTPUT_TRANSLATIONS set, 10474 characters, mentions salza2"
   "env CL_SOURCE_REGISTRY set, 11456 characters, mentions salza2" "env XDG_CACHE_HOME unset"
   "env HOME set, 10 characters" "user-cache /Users/rgb/.cache/common-lisp/sbcl-2.4.10-macosx-x64/"
   "translations-initialized T"
   "store-probe-destination /Users/rgb/.cache/common-lisp/sbcl-2.4.10-macosx-x64/nix/store/00000000000000000000000000000000-faq-probe/package.lisp"
   "system salza2 registered"
   "system-source-file /nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/salza2.asd"
   "component package found"
   "component-source /nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/package.lisp present"
   "fasl-destination /nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/package.fasl present"))
 :MAC-FRESH
 (:PLATFORM "Darwin-x86_64" :CASES
  (("R1" "0" "/nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1/package.fasl"
    "PASS prebuilt: the compiled file is in the store; loading writes nothing, recompiling would fail.")
   ("R2" "0"
    "/Users/rgb/.cache/common-lisp/sbcl-2.4.10-macosx-x64/nix/store/00000000000000000000000000000000-faq-probe/package.fasl"
    "PASS read-only: destination is outside the store; creatability not checked.")))
 :OPEN
 ("Codex: PR #57 auf Basis von 07b7f51f13494d11cc48e16a72b01da65b77256c überarbeiten (Revision 2, Review-Befunde 1 bis 3)."
  "Öffentliche Auslieferung unter /faq/ im separaten fleet-PR für staging; Aktivierung durch den Operator."))
