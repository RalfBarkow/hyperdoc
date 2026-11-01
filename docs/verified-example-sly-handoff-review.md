# Prüfung des SLY-Handoffs

Geprüfter Ausgangspunkt: Branch `work`, HEAD
`573fe37611a61d984260ebf43c797f7534211bdd`. Der Slice liegt lokal und uncommitted
vor: `dreyeck.asd` ist geändert, die neuen Implementierungs-, Test- und
Berichtsdateien sind untracked. Die fünf im Testnachweis gespeicherten
Datei-Digests stimmen weiterhin. Es wurde nichts veröffentlicht.

Vor dieser Untersuchung wurden die neun Slice-Dateien unverändert gesichert:
`/workspace/scratch/verified-example-handoff-yi9hzc9m/slice.tar.gz`, daneben
`manifest.json` und `tracked.patch`. Die Archivbytes wurden gegen das Manifest
geprüft. Nach der anschliessenden Auswahl einer separaten Entwicklungsimage
wurde zusätzlich der startfreie [SLY-Ablauf](verified-example-sly-run.md)
vorbereitet und der Inspector-Helper im ursprünglichen Bericht korrigiert.
Implementierung und Tests blieben unverändert.

## Was der bisherige Handoff tatsächlich macht

- `asdf:load-system "dreyeck/verified-example/fixture"` lädt die lokale Erweiterung
  und ihre Abhängigkeiten. Darunter sind Inspector-Containment-Methoden. Auch
  dieser Schritt ist keine rein lesende Beobachtung einer beliebigen Image.
- `prepare-fixture` registriert die bekannte ASD-Datei und lädt ihr System mit
  `:force t`. Erst nach Auswahl einer Entwicklungsimage ausführen.
- `capture-fixture` führt genau `fixture-value` und dessen Oracle aus. Der Record
  belegt diese Auswertung, nicht die Ausführung der vollständigen ASDF-Testsuite.
- `approve-display` verändert die lokale Contract-Registry. Der Name
  `local/fixture-value` muss für diesen Versuch frei sein; eine bestehende
  Freigabe darf nicht still überschrieben werden.
- `example-view` prüft die Freigabe und rendert gespeicherte Daten. Der bestehende
  Handoff zeigt Erfolg und Widerruf, bislang aber keine Item-Änderungsgegenprobe.

Gewählt wurde eine separate, bewusst manuell gestartete Entwicklungsimage.
Port und Runtime bestimmt der Nutzer beim Start; die Image auf Port 8081 bleibt
unberührt. Noch nicht belegt ist, ob das Dateisystem der neuen Image den
Cloud-Worktree unter `/workspace/hyperdoc` sehen kann.
Den Pfad daher nicht in eine lokale SLY-Image übernehmen, bevor er beobachtet wurde.

## Erster Schritt: ausschliesslich Image und registrierte Quelle beobachten

Keine Loads, Registry-Suche mit Autoload, Fixture-Auswertung oder Serveroperation.
Die Form verwendet nur bereits vorhandene Packages und ASDF-Registrierungen;
fehlende Registrierung bedeutet nicht, dass die Datei auf Disk fehlt.

```lisp
(defparameter *verified-image-observation*
  (list
   :lisp (list (lisp-implementation-type) (lisp-implementation-version))
   :directory *default-pathname-defaults*
   :dreyeck-asd
   (let* ((package (find-package "ASDF"))
          (lookup (and package (find-symbol "REGISTERED-SYSTEM" package)))
          (source (and package (find-symbol "SYSTEM-SOURCE-FILE" package)))
          (system (and lookup (fboundp lookup) (funcall lookup "dreyeck"))))
     (and system source (fboundp source) (funcall source system)))
   :server-parameters
   (let* ((package (find-package "HYPERBOOK/SERVER"))
          (symbol (and package (find-symbol "*SERVER-PARAMETERS*" package))))
     (and symbol (boundp symbol) (symbol-value symbol)))
   :slice-package-present
   (not (null (find-package "DREYECK/VERIFIED-EXAMPLE")))))
(inspect *verified-image-observation*)
```

Zurückzugeben ist die Plist aus der separat gestarteten Entwicklungsimage.
`NIL` bei `:server-parameters` allein beweist nicht, dass eine Image unproduktiv
ist. Ein vorhandenes Slice-Package beweist nicht, dass es den aktuellen Diskstand
enthält. Erst aus dieser Beobachtung ergibt sich die passende kleine Ladeform.

### Korrigierte Inspector-Annahme

Die bisherige Annahme „Package vorhanden → Inspector-Aufruf ohne Serverstart“
war falsch. In der installierten `clog-moldable-inspector`-Quelle ruft
`clog-inspect` bei `(not (clog:is-running-p))` selbst `clog:initialize` auf
(`inspector.lisp:719–744`). Das Package allein belegt weder einen laufenden
Inspector noch einen bewusst gewählten Port. Der vorhandene Einstieg
`on-new-inspector` (`inspector.lisp:707`) erstellt dagegen einen Inspector in
einem übergebenen Browser-Body und startet keinen Listener. Der aktualisierte
Handoff verwendet für die Kernprüfung `inspect` und für CLOG ausschliesslich
diesen bestehenden Body-Einstieg. Präventionsregel: Objektinspektion und
Runtime-/Listener-Initialisierung anhand der tatsächlichen Aufrufkette trennen.

## Nach Vorbereitung in der gewählten Entwicklungsimage

Die folgenden Ergänzungen setzen die im ursprünglichen
[SLY-Handoff](trusted-executable-examples.md#e-inspector-handoff-für-die-eigene-sly-image)
angelegten Objekte und `inspect-verified-example` voraus. Sie sind vorbereitet,
hier aber nicht in der Nutzer-Image ausgewertet worden.

Vor dem dortigen `approve-display` einmal prüfen:

```lisp
(assert
 (null (dreyeck/authority-policy:find-operation-contract "local/fixture-value"))
 () "Diese Identität hat bereits einen Contract; nicht überschreiben.")
```

Nach ausdrücklicher Freigabe die konkrete Bindung untersuchen:

```lisp
(defparameter *verified-authorization-observation*
  (list
   :page-source
   (dreyeck/verified-example:example-page-source *verified-record*)
   :record *verified-record*
   :current-contract
   (dreyeck/authority-policy:find-operation-contract "local/fixture-value")
   :digest-matches
   (equal
    (dreyeck/verified-example:example-digest *verified-record*)
    (dreyeck/authority-policy:contract-audit-provenance *verified-display-grant*))
   :decision
   (multiple-value-list
    (dreyeck/verified-example:display-decision
     "local/fixture-value" *verified-page* *verified-item*))))
(inspect-verified-example *verified-authorization-observation*)
```

Erwartung: Digest-Vergleich `T`; Entscheidung `(T :DISPLAY-ONLY <record> <contract>)`.
Die vier zurückgegebenen Werte bleiben erhalten. Die Gleichheit des Digests
allein reicht nicht zur Freigabe: `display-decision` prüft zusätzlich die aktuelle
Registry, Seitenkoordinate, Item-Inhalt und Dateien.

Änderungsgegenprobe an einer Kopie des Story-Items:

```lisp
(defparameter *verified-changed-item*
  (let* ((source (dreyeck/verified-example:example-page-source *verified-record*))
         (item (dreyeck/local-fedwiki-page:find-story-item source "fixture-value"))
         (json (dreyeck/local-fedwiki-page:story-item-json item)))
    (setf (gethash "text" json)
          "(page-attached-hyperdoc-fixture:fixture-value) ; changed")
    (hyperbook/fedwiki::make-story-item json)))
(multiple-value-list
 (dreyeck/verified-example:display-decision
  "local/fixture-value" *verified-page* *verified-changed-item*))
(defparameter *verified-changed-view*
  (dreyeck/verified-example:example-view
   "local/fixture-value" *verified-page* *verified-changed-item*))
(inspect-verified-example *verified-changed-view*)
```

Erwartung: `(NIL :PAGE-OR-ITEM-CHANGED NIL NIL)`, kein gespeicherter Quelltext und
kein Ergebnis im neuen View. `story-item-json` liefert eine Kopie; die Originalseite,
das freigegebene Item und die Dateien bleiben unverändert. Dies belegt die
Inhaltsbindung des Items. Eine Dateirevisionsänderung ist eine andere Gegenprobe,
bereits in den Repository-Tests enthalten; sie wird hier nicht als live beobachtet
ausgegeben. Das unveränderte `*verified-item*` sollte weiterhin `:DISPLAY-ONLY` liefern.

Danach der vorhandene Widerruf, mit expliziter Beobachtung des aktuellen Contracts:

```lisp
(dreyeck/verified-example:revoke-display "local/fixture-value" "SLY review ended")
(multiple-value-list
 (dreyeck/verified-example:display-decision
  "local/fixture-value" *verified-page* *verified-item*))
(defparameter *verified-revocation-observation*
  (list :old-contract *verified-display-grant*
        :current-contract
        (dreyeck/authority-policy:find-operation-contract "local/fixture-value")
        :new-view
        (dreyeck/verified-example:example-view
         "local/fixture-value" *verified-page* *verified-item*)))
(inspect-verified-example *verified-revocation-observation*)
```

Erwartung: `(NIL :REVOKED NIL NIL)`. Der alte Contract ist weiterhin als historisches
Objekt vorhanden; die aktuelle Registry enthält den ersetzenden `:UNSAFE`-Contract.
Ein neu erzeugter View zeigt die Ablehnung. Alte bereits dargestellte Views sind
keine erneute Autorisierungsentscheidung und werden nicht rückwirkend gelöscht.

## Authority-Drift und Reichweite

Der fehlgeschlagene Test ist `check-adapters-as-reviewed` in
`dreyeck/tests/authority-policy.lisp:375`. Erwartet wird
`(null (containment-adapter-drift))`. Beobachtet wurde:

```lisp
((:point
  "new title-bar actions on DREYECK/WORK/TRAILS-RENDERED-READING::CONTEXT-FEDWIKI-PAGE"))
```

`containment-adapter-drift` prüft unter anderem die Menge der Klassen mit primären
Title-Bar-Methoden gegen `+known-title-bar-classes+`; es analysiert deren Wirkung
nicht. Die gemeldete Methode in
`dreyeck/work/trails-rendered-federated-context.lisp:1054` liefert `nil` und
unterdrückt dadurch Aktionen. Derselbe Fehler trat im separaten Testprozess ohne
Laden des neuen Slices auf; siehe den vorhandenen Testnachweis.

Der ausgewählte neue View rendert nur gespeicherte Strings und erzeugt keine
Inspector-Referenzen, Thunks oder Assets. Seine Entscheidung ruft
`invocation-decision` auf, nicht die driftende Title-Bar-Methode. Für diesen
konkreten Pfad ist damit kein kausaler Einfluss des gemeldeten Methodenrumpfs
gefunden. Das macht die allgemeine Authority-Suite nicht grün: Wer vom lokalen
Betreiber-Inspector zu einer öffentlichen allgemeinen Page-/ASDF-Inspektion
übergeht, muss die gesamte Containment-Grenze erneut prüfen. Eine Allowlist-
Anpassung wurde hier bewusst nicht vorgenommen.
