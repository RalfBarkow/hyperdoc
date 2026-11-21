;;; Projektstatus des Zettelkasten-Kiosks. Von Hand geführt: Claude trägt nach jedem Schritt ein, der Operator nach
;;; seinen Beobachtungen. Der Play-Knopf liest nur die aktuellen Branch-Köpfe von GitHub (in diesem Image).
;;;
;;; (:item ...)      ein Vorhaben. :head ist der Commit, auf den sich das Register bezieht; NIL = noch nicht begonnen.
;;;                  :flags (:pr = soll als Pull Request eingereicht werden, :needs-view = der Operator sieht es an).
;;;                  :evidence je Beleg (ART DATUM WER TEXT :at COMMIT). ART ist :verified (geprüft, bestanden),
;;;                  :failed (geprüft, nicht bestanden), :seen (vom Operator angesehen), :pr-open, :merged.
;;;                  WER ist :claude oder :operator. Ein Beleg gilt nur für den Commit, bei dem er gemacht wurde.
;;; (:decision ...)  eine offene oder getroffene Entscheidung; :status :open oder :decided (mit :choice).

(:item :id :kiosk :title "Nix-Paket, Kiosk-Modul und VM-Test"
 :repo "RalfBarkow/zettelkasten" :branch "nix/package-kiosk" :head "accb7d6"
 :flags (:pr)
 :evidence ((:verified "2026-11-21" :claude "nix build .#zettelkasten auf x86_64-linux: 103 JUnit-Tests (8 übersprungen) und 55 TestNG-Tests (3 übersprungen) bestanden" :at "05267c9")
            (:verified "2026-11-21" :claude "checks.kiosk, NixOS-VM ohne KVM emuliert: Kiosk startet als unprivilegierter Benutzer, Fenster per OCR gefunden, kein TCP-Port offen; Bildschirmfoto zettelkasten-kiosk.png" :at "accb7d6")
            (:verified "2026-11-21" :operator "nix run github:RalfBarkow/zettelkasten/nix/package-kiosk auf dem Mac; Info-Fenster «Zettelkasten 3.2026.11 (Build accb7d6)», öffnete [rgb] mit 11 874 Zetteln (Bildschirmfoto 08.22.56)" :at "accb7d6")
            (:seen "2026-11-21" :operator "auf dem Mac gestartet und angesehen" :at "accb7d6")))

(:item :id :repomix :title "repomix aus Repo und Dev-Shell entfernen"
 :repo "RalfBarkow/zettelkasten" :branch "chore/remove-repomix-config" :head "23c95c8"
 :flags (:pr)
 :evidence ((:verified "2026-11-21" :claude "nix flake check bestanden; nix develop startet mit JDK 25, Maven und IntelliJ, ohne repomix; lässt sich konfliktfrei mit nix/package-kiosk zusammenführen (git merge-tree)" :at "23c95c8")))

(:item :id :remote-screen :title "Fernbildschirm: wayvnc nur zum Ansehen, Anmeldung über RSA-AES"
 :repo "RalfBarkow/zettelkasten" :branch "nix/remote-screen" :head "75bac1b"
 :depends-on (:kiosk) :blocked-by (:rsa-aes-variant)
 :flags (:pr)
 :evidence ((:failed "2026-11-21" :claude "checks.remote-screen, Lauf 2: Ablehnung ohne Zugangsdaten und mit zu offenen Rechten bestanden; wayvnc nur auf 127.0.0.1:5900, Passwort in keiner Befehlszeile. Abbruch bei der fremden Origin: WebSocket 1006 (Testfehler: Subprotokoll angefragt)" :at "5188269")
            (:failed "2026-11-21" :claude "Handshake-Probe ausserhalb der VM (kopfloses cage, wayvnc 0.8.0 und 0.10.2): angebotene Sicherheitstypen [129, 5]; noVNC 1.4.0 und 1.7.0 kennen unter RSA-AES nur 6 (RA2ne). Kein gemeinsamer Typ, noVNC kommt nicht zur Anmeldung" :at "75bac1b")))

(:item :id :concept :title "Concept-Topic «Lokaler Fernbildschirm»"
 :repo "RalfBarkow/hyperdoc" :branch "docs/start-local-hyperdoc" :head "dd6420ec"
 :file "docs/operator/local-remote-screen.dita"
 :flags (:needs-view)
 :evidence ((:verified "2026-11-21" :claude "XML wohlgeformt; Schreibung de-CH (kein ß); Befund zur RSA-AES-Lücke als Hinweis eingetragen" :at "dd6420ec")))

(:item :id :acceptance-steps :title "Abnahme als SHOP3-Plan und DITA-Tasks mit Play (:CONFIGURE-AUTH … :ACCEPT-REMOTE-DISPLAY)"
 :repo "RalfBarkow/hyperdoc" :branch nil :head nil
 :depends-on (:remote-screen) :blocked-by (:rsa-aes-variant)
 :evidence ())

(:item :id :hyperdoc-frame :title "HyperDoc-Seite, die noVNC in einem Frame zeigt"
 :repo "RalfBarkow/hyperdoc" :branch nil :head nil
 :depends-on (:remote-screen) :blocked-by (:rsa-aes-variant)
 :evidence ())

(:decision :id :rsa-aes-variant :title "RSA-AES-Lücke zwischen wayvnc und noVNC"
 :status :open :date "2026-11-21"
 :question "wayvnc/neatvnc bieten nur RA2_256 (129) und RA2 (5) an, noVNC kennt nur RA2ne (6): Zugangsdaten verschlüsselt, Bildstrom danach nicht. Wie soll der Fernbildschirm die Anmeldung umsetzen?"
 :options ((:id :patch-neatvnc-ra2ne :label "neatvnc um RA2ne (6) erweitern"
            :consequence "Anmeldung über RSA-AES, Bildstrom unverschlüsselt nur über Loopback; Vertragspunkt 1 wird angepasst; eigener Patch an sicherheitskritischem C-Code")
           (:id :native-client :label "Nativer VNC-Client statt noVNC"
            :consequence "Vertrag voll erfüllbar, falls der Client RA2_256 beherrscht (ungeprüft); kein Frame im HyperDoc")
           (:id :extend-novnc :label "noVNC um RA2 mit Sitzungsverschlüsselung erweitern"
            :consequence "eigene Kryptografie im Browser-Client; abgeraten"))
 :recommended :patch-neatvnc-ra2ne)
