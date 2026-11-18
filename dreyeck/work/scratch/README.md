# Scratch · Federated Wiki Matrix Room

Die HyperDoc-Seite unter `pages/Topics aus dem Federated Wiki Matrix Room.html`
führt von 19 vorläufigen Topics zu ihren Matrix-Fundstellen, zum Bild und zu
verlinkten Quellen. `scratch.ctm` enthält dieselbe Zuordnung als Topic Map.
Die Tag-IRIs in der Map bezeichnen vorläufige Topics unabhängig von Dateinamen,
späteren FedWiki-Seiten und ASDF-Systemen.

In `src/topic-index.lisp` stehen die Topics, Beiträge und Beziehungen als
Common-Lisp-Daten. `hyperdoc-scratch:find-topic` nimmt eine lokale ID wie
`:typed-nodes`. `hyperdoc-scratch:sources-for-topic` löst die Fundstellen dazu
auf. Die Feldwerte `:explizit`, `:zugeschriebene-these` und `:abgeleitet`
geben die Herkunft der Topic-Zuordnung an.

## Build auf dreyeck.ch

Vom Wurzelverzeichnis des HyperDoc-Checkouts aus baut Python 3 das ZIP aus den versionierten Dateien. Der Build benötigt weder eine laufende Wiki noch eine temporäre SLY-Sitzung.

```sh
python3 scripts/build-scratch-zip.py /tmp/scratch.zip
```

`fedwiki/scratch.json` enthält die lokale Trägerseite mit dem Assets-Item `6efc97a9d8dc7bf4` und vier Journalaktionen. `fedwiki/matrix-index.json` erhält die zusätzliche Seitenvorlage des ursprünglichen ZIP mit ihren eigenen IDs. Das Wiki bietet den Download unter `assets/pages/scratch/scratch.zip` an.

## Abnahme in einem frischen Site-Root

Die folgenden Shell-Befehle verwenden ausschliesslich den zuvor gebauten Anhang. Die letzte Zeile gibt den Site-Root für die mREPL aus.

```sh
site=$(mktemp -d)
mkdir -p "$site/assets/pages" "$site/pages"
unzip -q /tmp/scratch.zip -d "$site/assets/pages"
cp "$site/assets/pages/scratch/fedwiki/scratch.json" "$site/pages/scratch"
cp /tmp/scratch.zip "$site/assets/pages/scratch/scratch.zip"
echo "$site/"
```

In einem HyperDoc-Entwicklungsimage die Formen einzeln auswerten. In der zweiten Form den ausgegebenen Pfad einsetzen.

```lisp
(asdf:load-system "dreyeck/fedwiki-hyperdoc")
(defparameter *scratch-site* #P"/pfad/zum/site-root/")
(defparameter *scratch-run*
  (dreyeck/fedwiki-hyperdoc:activate-local-fedwiki-page-hyperdoc *scratch-site* "scratch"))
(getf *scratch-run* :selected-presentation-system) ; "scratch"
(mapcar (lambda (s) (getf s :id)) (hyperdoc-scratch:sources-for-topic :typed-nodes))
; (:M01 :IMAGE :SOLO)
(clog-moldable-inspector:clog-inspect :object (getf *scratch-run* :runtime-hyperdoc))
```

Das Archiv enthält das vollständige Bild und die eigenständig importierbare `scratch.ctm`. Die Hauptseite verweist auf beides. Im Inspector bleiben die Verweise auf Matrix-Fundstellen im Lesefenster und der CTM-Download liefert die mitgelieferten Dateibytes.

Die Matrix-Zeitangaben sind die Anzeigezeiten aus dem übergebenen Auszug.
Die Abbildung im Archiv ist der mitgegebene Graphviz-Screenshot. Der im
Beitrag um 22:10 erwähnte zweite Screenshot steht als Quellenhinweis im
Index. Die Videos sind per Zeit- bzw. Quellverweis erschlossen.
