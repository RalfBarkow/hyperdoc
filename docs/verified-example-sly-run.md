# SLY-Nachweis in der separat gestarteten Entwicklungsimage

Diese Formen werden vom Nutzer einzeln ausgewertet. Codex hat keine davon in
der Nutzer-Image ausgeführt. Keine Start-, Neustart- oder Deployment-Form ist
enthalten. Runtime und Port werden beim manuellen Start festgelegt; die Image
auf Port 8081 bleibt unberührt.

Voraussetzung: Die ASDF-Source-Registry der neuen SBCL-Entwicklungsimage sieht
den Checkout **mit den uncommitted Slice-Dateien**. GitHub-HEAD `573fe376` allein
enthält sie nicht. `/workspace/hyperdoc` bezeichnet den Cloud-Worktree und ist
kein behaupteter Pfad auf dem Rechner des Nutzers. Bei fehlendem System oder
anderem Quellpfad zunächst die Diagnose aus der Handoff-Review zurückgeben.

Alle Blöcke einzeln lesen und auswerten, damit neu geladene Packages beim Lesen
des nächsten Blocks vorhanden sind. `inspect` startet keinen Webserver; die
Lisp-Inspektion jeweils beenden, bevor die nächste Form ausgewertet wird.

1. Das kleinste benötigte Subsystem laden.

```lisp
(require :asdf)
```

```lisp
(asdf:load-system "dreyeck/verified-example/fixture")
(asdf:system-source-file
 (asdf:registered-system "dreyeck/verified-example/fixture"))
```

Erwartung: der tatsächliche `dreyeck.asd`-Pfad des gewählten Checkouts. Diese
Ausgabe zuerst prüfen. Die Beispiel-Fixture selbst wird hier noch nicht geladen.

2. Die bekannte Fixture bewusst vorbereiten; dann Page und Record erzeugen.

```lisp
(dreyeck/verified-example/fixture:prepare-fixture)
(defparameter *verified-site*
  (dreyeck/verified-example/fixture:fixture-site-root))
```

`prepare-fixture` ist ausdrücklich aktiv: registriert die bekannte Fixture-ASD
und lädt sie mit `:force t`. Keine Wiki-Seite bestimmt, welche ASD geladen wird.

```lisp
(defparameter *verified-page*
  (dreyeck/local-fedwiki-page:make-local-fedwiki-page
   *verified-site*
   (dreyeck/local-fedwiki-page:make-local-fedwiki
    *verified-site* "verified-example-local")
   "verified-fixture-value"))
(defparameter *verified-item*
  (aref (hyperbook/fedwiki::story-of *verified-page*) 0))
(defparameter *verified-record*
  (dreyeck/verified-example/fixture:capture-fixture
   *verified-site* "fixture-value"))
```

```lisp
(list (dreyeck/evaluation-record:evaluation-status-of *verified-record*)
      (dreyeck/evaluation-record:evaluation-result-of *verified-record*)
      (dreyeck/evaluation-record:evaluation-failure-of *verified-record*))
(inspect *verified-record*)
```

Erwartung: `(:PASSED ":FIXTURE" NIL)`. Das ist das Ergebnis der festen
Beispieloperation mit ihrem Oracle; es ist noch kein Darstellungsrecht.

3. Die Ablehnung vor der Freigabe beobachten, dann bewusst Darstellung erlauben.

```lisp
(assert
 (null (dreyeck/authority-policy:find-operation-contract "local/fixture-value"))
 () "Identität bereits belegt; bestehenden Contract nicht überschreiben.")
(multiple-value-list
 (dreyeck/verified-example:display-decision
  "local/fixture-value" *verified-page* *verified-item*))
```

Erwartung: `(NIL :NOT-APPROVED NIL NIL)`.

```lisp
(defparameter *verified-display-grant*
  (dreyeck/verified-example:approve-display
   "local/fixture-value" *verified-record* "separate SLY development image"))
(defparameter *verified-view*
  (dreyeck/verified-example:example-view
   "local/fixture-value" *verified-page* *verified-item*))
```

```lisp
(list
 :digest-matches
 (equal (dreyeck/verified-example:example-digest *verified-record*)
        (dreyeck/authority-policy:contract-audit-provenance *verified-display-grant*))
 :decision
 (multiple-value-list
  (dreyeck/verified-example:display-decision
   "local/fixture-value" *verified-page* *verified-item*))
 :play (dreyeck/verified-example:request-play "local/fixture-value"))
(html-inspector-views:view-html *verified-view*)
(inspect *verified-view*)
```

Erwartung: Digest-Vergleich `T`, Entscheidung `(T :DISPLAY-ONLY <record> <contract>)`,
Play `(:STATUS :REFUSED :REASON :EXECUTION-UNAVAILABLE :EXECUTED-P NIL)`.
Das HTML enthält Quelltext und `:FIXTURE`, keinen Play-Button.

4. Änderung an einer Item-Kopie simulieren.

```lisp
(defparameter *verified-changed-item*
  (let* ((source (dreyeck/verified-example:example-page-source *verified-record*))
         (item (dreyeck/local-fedwiki-page:find-story-item source "fixture-value"))
         (json (dreyeck/local-fedwiki-page:story-item-json item)))
    (setf (gethash "text" json)
          "(page-attached-hyperdoc-fixture:fixture-value) ; changed")
    (hyperbook/fedwiki::make-story-item json)))
```

```lisp
(multiple-value-list
 (dreyeck/verified-example:display-decision
  "local/fixture-value" *verified-page* *verified-changed-item*))
(defparameter *verified-changed-view*
  (dreyeck/verified-example:example-view
   "local/fixture-value" *verified-page* *verified-changed-item*))
(html-inspector-views:view-html *verified-changed-view*)
(inspect *verified-changed-view*)
```

Erwartung: `(NIL :PAGE-OR-ITEM-CHANGED NIL NIL)`; neues HTML ohne gespeicherten
Code und ohne Ergebnis. Die Originalobjekte und die Dateien bleiben unverändert.
Diese Gegenprobe belegt die Item-Inhaltsbindung, nicht eine live ausgeführte
Dateiänderung. Als Kontrolle liefert das unveränderte `*verified-item*` weiterhin
`:DISPLAY-ONLY`, solange die Dateien aktuell geblieben sind.

5. Widerrufen und dieselbe ursprüngliche Darstellung erneut anfordern.

```lisp
(dreyeck/verified-example:revoke-display
 "local/fixture-value" "separate SLY review ended")
(multiple-value-list
 (dreyeck/verified-example:display-decision
  "local/fixture-value" *verified-page* *verified-item*))
(defparameter *verified-revoked-view*
  (dreyeck/verified-example:example-view
   "local/fixture-value" *verified-page* *verified-item*))
(html-inspector-views:view-html *verified-revoked-view*)
(inspect *verified-revoked-view*)
```

Erwartung: `(NIL :REVOKED NIL NIL)`; kein Code und kein Ergebnis im neuen View.
Der alte `*verified-display-grant*` bleibt als Objekt bestehen, ist aber nicht
mehr der aktuelle Registry-Eintrag. Bereits ausgegebenes HTML wird nicht gelöscht.

6. Beziehungen als unterscheidbare Objekte inspizieren.

```lisp
(defparameter *verified-relations*
  (list :page *verified-page*
        :page-source (dreyeck/verified-example:example-page-source *verified-record*)
        :system (asdf:registered-system "page-attached-hyperdoc-fixture")
        :record *verified-record*
        :old-contract *verified-display-grant*
        :current-contract
        (dreyeck/authority-policy:find-operation-contract "local/fixture-value")
        :approved-snapshot *verified-view*
        :changed-view *verified-changed-view*
        :revoked-view *verified-revoked-view*))
(inspect *verified-relations*)
```

Der alte View ist ein gespeicherter Darstellungsstand, kein nach Widerruf erneut
autorisierter Abruf. Der aktuelle Contract hat Status `:UNSAFE`.

## CLOG-Nachweis ohne impliziten Serverstart

Die obigen Prüfungen benötigen keinen HTTP-Port. Für die tatsächliche
CLOG-Darstellung muss der Nutzer in **derselben separaten Entwicklungsimage**
bereits einen CLOG-Listener auf seinem bewusst gewählten Port und einen leeren
Browser-Body bereitgestellt haben. Dafür wird hier kein Startbefehl gegeben.

`clog-inspect` ist hier absichtlich ausgeschlossen: sein Implementierungsrumpf
startet CLOG bei Bedarf. Der bereits vorhandene öffentliche Einstieg
`on-new-inspector` erstellt dagegen nur im übergebenen Body einen Inspector.
Er ist in der untersuchten Version mit den unten verwendeten Keywords definiert.

Der folgende Block setzt geladene Packages `CLOG`, `CLOG-USER` und
`CLOG-MOLDABLE-INSPECTOR` voraus. Er startet nichts; bei fehlendem Body oder
ungeeignetem Port muss die Auswertung abbrechen. Eine andere SLY-Verbindung
darf dafür nicht benutzt werden.

```lisp
(assert (clog:is-running-p) () "CLOG muss bereits manuell bereitgestellt sein.")
(assert (and (integerp clog:*clog-port*) (/= 8081 clog:*clog-port*))
        () "Nicht den Listener auf Port 8081 verwenden.")
(defparameter *verified-inspector-body* clog-user:*body*)
(assert (and *verified-inspector-body* (clog:validp *verified-inspector-body*))
        () "In dieser Entwicklungsimage fehlt ein verbundener Browser-Body.")
(clog-moldable-inspector:on-new-inspector
 *verified-inspector-body* :object *verified-relations*
 :pane-width "600px" :playground? nil)
```

`clog-user:*body*` kann in einer manuellen Installation NIL sein. Das ist kein
Anlass, automatisch einen Listener oder Browser zu öffnen: dann die tatsächlich
vorhandene Body-Bindung der gewählten Entwicklungsimage als Beobachtung
zurückgeben. Der bereitgestellte Body wird für die Inspector-Darstellung verwendet.

Zurückzugeben sind: ASDF-Quellpfad; `(:PASSED ":FIXTURE" NIL)`; die vier
Entscheidungen `:NOT-APPROVED`, `:DISPLAY-ONLY`, `:PAGE-OR-ITEM-CHANGED`, `:REVOKED`;
Play-Ablehnung; und getrennt davon die tatsächliche CLOG-Beobachtung oder der
konkrete fehlende Body/Package-Zustand. Bis dahin bleiben die Formen ein
quellgeprüfter Handoff und kein behaupteter Live-Nachweis.
