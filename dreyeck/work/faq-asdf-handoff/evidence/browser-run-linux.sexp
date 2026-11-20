;;;; Browser acceptance of the executable handoff, 2026-11-20, x86_64-linux, run as root in a container.
;;;; A Catalog was started on 127.0.0.1:18758 first, then OPEN-TASK registered the task in it, as in the white image.
;;;; Playwright (Chromium) clicked Play once per SHOP3 offer; the pane was reloaded before each click.
;;;; Tree: this commit without this file. C6 is skipped as root. Not macOS: step 3 ran in this Linux image.
(:FAQ "asdf-fasl-nix-store" :HANDOFF-COMMIT "07b7f51f13494d11cc48e16a72b01da65b77256c" :BRANCH
 "handoff/faq-asdf-fasl-nix-store-rev2" :REVISION "07b7f51f13494d11cc48e16a72b01da65b77256c" :CLEAN NIL
 :FLAKE-LOCK "019dcaff428e1abf426f165c3afd70fe163077454d1c348d4965d86a93a7e836" :NIXPKGS
 "50ab793786d9de88ee30ec4e4c24fb4236fc2674" :IMAGE-DREYECK
 ("/home/user/hd-handoff/" "07b7f51f13494d11cc48e16a72b01da65b77256c") :CHECK-ASDF
 (:PLATFORM "Linux-x86_64" :SBCL "SBCL 2.4.10" :CASES
  (("C1" "0"
    "/tmp/nix-shell.ZcfhJP/nix-shell.KSphXS/tmp.UYWAwT69KA/C1/.cache/common-lisp/sbcl-2.4.10-linux-x64/nix/store/00000000000000000000000000000000-faq-probe/package.fasl"
    "PASS: destination is outside the store and can be created.")
   ("C2" "0" "/nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/package.fasl"
    "PASS prebuilt: the compiled file is in the store; loading writes nothing, recompiling would fail.")
   ("C3" "0" "/nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/package.fasl"
    "PASS prebuilt: the compiled file is in the store; loading writes nothing, recompiling would fail.")
   ("C4" "1" "/nix/store/00000000000000000000000000000000-faq-probe/package.fasl"
    "FAIL store-destination: ASDF would have to write into the store.")
   ("C5" "1" "/nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/no-such-file.fasl"
    "FAIL store-destination: ASDF would have to write into the store.")
   ("C6" "skipped" "-" "root could create /nonexistent")
   ("C7" "0"
    "/tmp/nix-shell.ZcfhJP/nix-shell.KSphXS/tmp.UYWAwT69KA/C7/.cache/common-lisp/sbcl-2.4.10-linux-x64/nix/store/00000000000000000000000000000000-faq-probe/package.fasl"
    "PASS read-only: destination is outside the store; creatability not checked.")
   ("C8" "3" "-" "FAIL not-found: system or component not found.")
   ("C9" "0"
    "/tmp/nix-shell.ZcfhJP/nix-shell.KSphXS/tmp.UYWAwT69KA/C9/.cache/asdf-nix-store/00000000000000000000000000000000-faq-probe/package.fasl"
    "PASS: destination is outside the store and can be created.")
   ("C10" "0" "/nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/package.fasl"
    "PASS prebuilt: the compiled file is in the store; loading writes nothing, recompiling would fail.")
   ("C11" "0"
    "/tmp/nix-shell.ZcfhJP/nix-shell.KSphXS/tmp.UYWAwT69KA/C11/.cache/common-lisp/sbcl-2.4.10-linux-x64/nix/store/r40b3p08hidpxcf6cvdhfazlvlig1dyn-source/shop3/package.fasl"
    "PASS: destination is outside the store and can be created."))
  :RESTORE
  (("wrapper" "/nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/package.fasl")
   ("override"
    "/tmp/nix-shell.ZcfhJP/nix-shell.KSphXS/tmp.UYWAwT69KA/restore/.cache/common-lisp/sbcl-2.4.10-linux-x64/nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/package.fasl")
   ("without-argument"
    "/tmp/nix-shell.ZcfhJP/nix-shell.KSphXS/tmp.UYWAwT69KA/restore/.cache/common-lisp/sbcl-2.4.10-linux-x64/nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/package.fasl")
   ("with-nil" "/nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/package.fasl"))
  :DEVIATIONS NIL)
 :MAC-LIVE
 (:PLATFORM (:SOFTWARE "Linux" :MACHINE "X86-64" :LISP "2.4.10" :ASDF "3.3.1" :CATALOG-PORT 18758) :LINES
  ("lisp SBCL 2.4.10" "asdf 3.3.1" "env ASDF_OUTPUT_TRANSLATIONS set, 10474 characters, mentions salza2"
   "env CL_SOURCE_REGISTRY set, 11437 characters, mentions salza2" "env XDG_CACHE_HOME set, 86 characters"
   "env HOME set, 5 characters"
   "user-cache /tmp/claude-0/-home-user/3d6d8307-3084-5d7f-b90f-d41785c3279e/scratchpad/handoff/cache/common-lisp/sbcl-2.4.10-linux-x64/"
   "translations-initialized T"
   "store-probe-destination /tmp/claude-0/-home-user/3d6d8307-3084-5d7f-b90f-d41785c3279e/scratchpad/handoff/cache/common-lisp/sbcl-2.4.10-linux-x64/nix/store/00000000000000000000000000000000-faq-probe/package.lisp"
   "system salza2 registered"
   "system-source-file /nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/salza2.asd"
   "component package found"
   "component-source /nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/package.lisp present"
   "fasl-destination /nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/package.fasl present"))
 :MAC-FRESH
 (:PLATFORM "Linux-x86_64" :CASES
  (("R1" "0" "/nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1/package.fasl"
    "PASS prebuilt: the compiled file is in the store; loading writes nothing, recompiling would fail.")
   ("R2" "0"
    "/tmp/claude-0/-home-user/3d6d8307-3084-5d7f-b90f-d41785c3279e/scratchpad/handoff/cache/common-lisp/sbcl-2.4.10-linux-x64/nix/store/00000000000000000000000000000000-faq-probe/package.fasl"
    "PASS read-only: destination is outside the store; creatability not checked.")))
 :OPEN
 ("Lesediagnose im weissen SLY-Image auf einem Mac ausführen; dieser Lauf war nicht auf macOS."
  "Codex: PR #57 auf Basis von 07b7f51f13494d11cc48e16a72b01da65b77256c überarbeiten (Revision 2, Review-Befunde 1 bis 3)."
  "Öffentliche Auslieferung unter /faq/ im separaten fleet-PR für staging; Aktivierung durch den Operator."))
