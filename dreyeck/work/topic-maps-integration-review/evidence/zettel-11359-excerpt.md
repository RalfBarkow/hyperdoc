Excerpt of Zettel 11359 "From reviewed Topic Maps commit to HyperDoc integration candidate" (2026-10-28 07:09), a note by the project owner, kept outside this repository at /Users/rgb/workspace/z11359.md
SHA-256 of the whole note: cd1ed4fd163d7269b783bda5b2f5d8be5ad36e20ac8ecf8ac7c95024b86ca755
Sections 1, 3 and 5, verbatim, as the proposed structure this reading is built toward. It is a statement of intent: it declares nothing in any Work page, WBS dictionary or the project CTM.

#### 1. Zuständigkeiten und Integrationsweg

\
\| Schritt \| Verantwortlich \| Ergebnis \|\
\| - \| ~~- \|~~ \-\-\-- \|\
\| A. Topic Maps integrieren \| Claude Code \| `6162ed68` in den
maßgeblichen Entwicklungsbranch übernehmen \|\
\| B. Integration prüfen \| Codex \| Merge, Regressionen und
Quellidentität unabhängig verifizieren \|\
\| C. HyperDoc integrieren \| Claude Code \| Project Workspace und
Nix-Paket auf die geprüfte Revision umstellen \|\
\| D. HyperDoc-Review \| Sie, unterstützt durch ChatGPT \| Modell, Code,
Tests und Evidenz im HyperDoc lesen \|\
\| E. Staging deployen \| Claude Code bereitet vor; Sie geben frei \|
Neue Revision auf Port 18780 \|\
\| F. Produktion freigeben \| Sie, nach Sicherheitsprüfung durch Codex
\| Topic Maps wird Bestandteil des regulären Catalogs auf Port 8080 \|\
\
Wichtig: Die Integration von 1C muss nicht zwingend auf Slice 1E warten.
1C erfüllt bereits die operative 90-Sekunden-Grenze. Die spätere
Association-Optimierung kann getrennt entwickelt werden.\
\
Der bisherige No-go für den unveränderten Stand `b2eecffa` gilt aber
nicht automatisch als aufgehoben. Das muss für die integrierte Revision
nachgewiesen werden.\
\


#### 3. Die Integration soll im HyperDoc selbst nachvollziehbar werden

\
Das ist für mich der entscheidende fachliche Anspruch an diese nächste
Arbeitsphase.\
\
Beispiel: Navigation vom Work Item zur Implementierung\
\
Work Item: Topic Maps in HyperDoc integrieren\
\
Vorgeschlagenes Projektobjekt\
\
Source Change\
\
Commit `6162ed68`\
\
Evidence\
\
Independent Review 1C\
\
Project Workspace\
\
CTM → TMDM → CXTM → Inspector\
\
Deployment Evidence\
\
Nix-Snapshot, systemd, Browser- und Runtime-Tests\
\
Das ist eine gewünschte Navigationsstruktur, nicht die Behauptung, dass
alle diese Beziehungen schon als deklarierte Topic-Map-Associations
existieren.\
\
Sie sollten beim Lesen eines Work Package nicht erst externe Berichte
und Git-Hashes zusammensuchen müssen. Die betreffenden Objekte und
Quellen sollten über ihre Beziehungen erreichbar sein.\
\


#### 5. Wer entscheidet über den Abschluss?

\
Ich würde drei ausdrücklich getrennte Entscheidungen festhalten:\
\
- Integration in `topic-maps`: nach positivem Test- und Quellenabgleich
lokal abschließen.\
- Integration in HyperDoc-Staging: nach Kompatibilitätsprüfung und
reproduzierbarem Nix-Build freigeben.\
- Integration in den produktiven HyperDoc-Catalog: erst nach
Browser-Review, Sicherheitsprüfung und Betriebsnachweis freigeben.\
\
Der lokale Commit `6162ed68` ist damit ein abgeschlossener
Implementierungsstand, noch keine HyperDoc- oder Produktionsabnahme.\
\
Mein Vorschlag: Geben Sie Claude Code jetzt den Auftrag oben. Nach Phase
A sollte Codex den integrierten Topic-Maps-Stand unabhängig prüfen;
anschließend kann Claude die HyperDoc-Integration weiterführen. Slice 1E
bleibt ein separater Optimierungspfad und blockiert die Arbeit mit dem
bereits geprüften 1C nicht.\
\
\
