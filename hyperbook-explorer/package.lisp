;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

;; No new package, we add to :hyperbook

(in-package :hyperbook)

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperbook)
(trivial-package-local-nicknames:add-package-local-nickname
 :views/standard :html-inspector-views/standard :hyperbook)
