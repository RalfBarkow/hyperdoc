# Den v2 (Den on Gen) delivery outlook

Das ASDF-System `den-v2-delivery-outlook` in Version 0.1.7 enthält eine
SHOP3-Domäne zum Lieferentwurf vom 16. November 2026 (Zettel 11781).
Die Quellrevision ist im Planbefund hinterlegt. Die [DITA Map](dita/den-v2-delivery-outlook.ditamap)
verbindet das Konzept, den Planungstermin und die Freigabeprüfung.

Version 0.1.1 kennzeichnet absichtlich einmal verwendete SHOP3-Variablen als
anonym. Die Domäne lässt sich im laufenden Image erneut laden. Die
Prüfung kontrolliert auch die konkreten Argumente im erzeugten Plan.

## HyperDoc-Topic öffnen

Speichere das ZIP unter seinem Namen in `~/Downloads/`. Werte im SLY mREPL
des lokalen HyperDoc-Images auf Port 8080 einmal diese Form aus.

```lisp
(let* ((downloads (merge-pathnames "Downloads/" (user-homedir-pathname)))
       (zip (merge-pathnames "den-v2-delivery-outlook.zip" downloads)))
  (unless (probe-file zip)
    (error "ZIP fehlt unter ~A." zip))
  (let* ((template (merge-pathnames "den-v2-topic.XXXXXXXX" downloads))
         (stage
           (uiop:ensure-directory-pathname
            (uiop:run-program
             (list "/usr/bin/mktemp" "-d" (namestring template))
             :output '(:string :stripped t))))
         (root (merge-pathnames "den-v2-delivery-outlook/" stage))
         (asd (merge-pathnames "den-v2-delivery-outlook.asd" root))
         (asdf:*central-registry* (cons root asdf:*central-registry*)))
    (uiop:run-program
     (list "/usr/bin/unzip" "-q" (namestring zip) "-d" (namestring stage)))
    (let* ((topic (asdf:find-system "den-v2-delivery-outlook/topic" nil))
           (source (and topic (asdf:system-source-file topic))))
      (unless (and source (equal (probe-file source) (truename asd)))
        (error "Topic nicht aus ~A aufgelöst. ASDF meldet ~S." asd source))
      (asdf:load-system topic)
      (multiple-value-bind (url page-source)
          (uiop:symbol-call "DEN-V2-OUTLOOK-TOPIC" "TOPIC-URL")
        (list :version (asdf:component-version topic)
              :source source
              :page-source page-source
              :url url)))))
```

Öffne die URL aus dem Feld `:url` in einem neuen Tab. Das Feld `:source`
zeigt die ASDF-Datei und `:page-source` die registrierte HTML-Datei aus dem
entpackten Archiv. Der Catalog führt die Seite unter
**Den v2 Delivery Outlook → ZIP entpacken und Plansystem laden**.
Die [Quelle des Topics](pages/ZIP%20entpacken%20und%20Plansystem%20laden.html)
enthält die Formen zum Entpacken und Laden, Prüfen der Planfälle und Lesen des
Checkpoint-Plans. Der lokale Entwicklungsmodus bietet ▶ direkt an der Form
an. Für den Checkpoint-Plan kannst du dieselbe Form im SLY mREPL oder im
Tab **Playground** auswerten. Füge sie im Playground allein in den Editor
ein und klicke auf **Eval**.

## Planfälle

| Fall | Was SHOP3 prüft oder vorschlägt |
| --- | --- |
| `:checkpoint` | Belege und Blockaden erfassen, drei Konstruktionen klären, Prognose-Eingaben anfordern und den fehlenden Lieferkorridor festhalten. |
| `:roadmap` | Arbeit bis zur Freigabeprüfung zerlegen. `:unordered` erlaubt Interleaving. Pro Paritätsklasse kommt die Konstruktion vor der Integration. |
| `:forecast-ready` | Mit Beispieldaten Lieferkorridor berechnen und Neujahrsziel neu beurteilen lassen. |
| `:target-unrealistic` | Mit Beispielbeleg eine Korrektur des kommunizierten Ziels als ersten Schritt vorschlagen. |
| `:release-review` | Kandidat identifizieren oder fehlende Nachweise für genau diesen Kandidaten anfordern. |
| `:release` | Freigabeentscheidung für den per `:candidate` gewählten Kandidaten vorschlagen, sofern alle geforderten Belege vorliegen. |
| `:release-blocked` | Beleg für Recovery gehört zu einem anderen Kandidaten. Erwartet wird `NIL`. |
| `:release-ready` | Vollständige Beispielbelege für `:rc-example`. Erwartet wird ein Vorschlag zur Freigabeentscheidung. |
| `:support` | Support und Fehlerkorrekturen für das laufende Den bis einschließlich Q1 2027 einplanen. |
| `:xmsg`, `:xmsg-verified` | Verfügbarkeit und gemessenen Beitrag erheben bzw. verifizierte Kapazität für die Planung prüfen. |
| `:evidence-reuse`, `:evidence-reusable` | Wiederholung einplanen bzw. Wiederverwendung bei identischem Prüfkontext und positiv belegter Ausnahme prüfen. |

`RUN-PLAN` nimmt über `:facts` den vollständigen Satz der aktuellen
Belegfakten für den Fall entgegen. `CASE-FACTS` liefert die veränderbare
Eingabe eines Beispielfalls. Beleg-IDs mit `:example-…` stehen für
synthetische Nachweise. `:parity-1` bis `:parity-3` sind Modell-IDs für die im
Entwurf unbenannten Klassen.

```lisp
(let ((facts (uiop:symbol-call "DEN-V2-DELIVERY-OUTLOOK" "CASE-FACTS"
                                :release-blocked)))
  (uiop:symbol-call "CLOG-MOLDABLE-INSPECTOR" "CLOG-INSPECT"
                   :object (uiop:symbol-call "DEN-V2-DELIVERY-OUTLOOK" "RUN-PLAN"
                                              :release-review :facts facts)))
```

Der Planmodus ist `:plan-only`. Die Operationen formulieren anstehende
Arbeit oder Entscheidungen. Die Prognoseberechnung braucht die tatsächlichen
Aufwände, Abhängigkeiten und Integrationsdaten. Die Review-Aufgabe kann mit
`(NIL)` enden, wenn alle Belege bereits vorhanden sind. `NIL` im
Freigabeproblem bedeutet, dass SHOP3 keine zulässige Freigabeentscheidung
vorschlagen kann.

Bei einem Typfehler der SHOP3-Baumaufbereitung prüft der Runner den
Release-Review erneut ohne Baumausgabe. Er übernimmt dieses Ergebnis nur
dann, wenn SHOP3 genau einen leeren Plan liefert.

## Trägerseite

Die vorgesehene Federated-Wiki-Trägerseite heißt **Den v2 Delivery Outlook**.
Ihr Slug `den-v2-delivery-outlook` entspricht dem ASDF-System. Das zugehörige
Assets-Item verwendet `pages/den-v2-delivery-outlook` und das Asset heißt
`den-v2-delivery-outlook.zip`. Der Lieferentwurf bleibt als Beleg referenziert.

Quelle: [den-delivery-plan.md](https://gist.github.com/sini/cbaeb289453aa89e5a9bf285fe50f94a/c83c4a86460175413b2a4cff2bfb58191dd96b84).
