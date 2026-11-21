;;;; Das Paket
;;;;
;;;; Der Zettelkasten-Kiosk als Projekt: Vorhaben (je ein Branch oder ein noch nicht begonnenes Stück Arbeit), ihre
;;;; Belege, offene Entscheidungen. Der nächste Schritt wird mit SHOP3 aus diesen Fakten berechnet; geplant wird nur,
;;;; ausgeführt wird nichts. Belege sagen, wer was wann bei welchem Commit beobachtet hat.
(defpackage #:zettelkasten-kiosk
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views) (#:dita #:dreyeck/dita-story-item)
                    (#:policy #:dreyeck/authority-policy))
  (:export #:project #:register #:load-register #:*register* #:project-facts #:plan-next #:offers #:recommended
           #:reasons #:item #:decision #:play-read-heads #:task-topic #:*head-reader*))
(in-package #:zettelkasten-kiosk)
