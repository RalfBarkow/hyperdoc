;;;; Das Paket und seine Herkunft
;;;;
;;;; Quelle: The Nix Arms, The Brewhouse, «Five ways to organise your config» (https://nixarms.com/brewhouse/) und
;;;; ihre fünf Unterseiten, gelesen am 2026-11-20. Die Topic Maps in ctm/ geben sie auf Deutsch wieder; der Nix-Code
;;;; darin steht so auf den Seiten (MIT-Lizenz, LICENSE-nixarms.txt). ctm/fleet.ctm ist eine Einordnung, keine Quelle.
(defpackage #:five-ways
  (:use #:cl)
  (:local-nicknames (#:ctm #:topic-maps.ctm) (#:tmdm #:topic-maps.tmdm) (#:tm #:dreyeck/topicmap)
                    (#:v #:html-inspector-views))
  (:export #:the-map #:page-map #:ctm-files #:topic #:name-of #:occurrences #:methods #:workspace
           #:method-sheet #:tasting-board #:*map*))
(in-package #:five-ways)
