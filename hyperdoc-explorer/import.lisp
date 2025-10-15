;;;; Import additional symbols into package hyperdoc
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The system html-inspector-views is a dependency of system
;; "hyperdoc/explorer", but not of system "hyperdoc". Therefore it
;; could not be given a local nickname at package creation time.
;;

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperdoc)
(trivial-package-local-nicknames:add-package-local-nickname
 :views/standard :html-inspector-views/standard :hyperdoc)
