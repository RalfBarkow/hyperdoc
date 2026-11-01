# Lokaler Testnachweis

`verification.txt` enthält die beobachteten Abschlussmeldungen, Exitcodes,
den getrennt reproduzierten Authority-Drift und SHA-256 der geprüften neuen
Lisp-/ASDF-/Fixture-Dateien. `approved.html` ist die tatsächliche Ausgabe des
Code-Story-Item-Renderers aus dem positiven Test, kein Screenshot und kein
Browser-End-to-End-Nachweis.

Die Testprozesse nutzten die bereits vorhandene lokale Runtime-Hülle
`/workspace/scratch/tmdm-mcp-portable/run.py` mit SBCL 2.4.10 und der vorhandenen
ASDF-Source-Registry. Kein neuer Dienst und keine laufende Nutzer-Image wurden
benutzt. Vollständige Arbeitslogs verbleiben unter `/tmp/trusted-examples-focused.log`
und `/tmp/trusted-examples-authority-baseline.log` in dieser Umgebung.

Der erfolgreiche Prozess führte nach `(require :asdf)` aus:

```lisp
(asdf:test-system "dreyeck/verified-example")
(asdf:load-system "dreyeck/local-fedwiki-page/tests")
```

Danach, als getrennt gelesenes Formular:

```lisp
(assert (dreyeck/local-fedwiki-page/tests:run-local-fedwiki-page-tests))
```

Die vorhandene Local-Page-Suite wurde direkt nach beendetem LOAD-OP aufgerufen,
nicht über ihren alten Prozesslauncher: dessen `*runtime-pathname*` kann in der
vorliegenden portablen Umgebung auf den dynamischen Loader zeigen. Der neue
ASDF-Testtreiber verwendet deshalb das konfigurierte `sbcl` auf PATH.

Für die HTML-Probe war `HYPERDOC_VERIFIED_EXAMPLE_HTML=/tmp/trusted-example-approved.html`
gesetzt; ausschliesslich der Testtreiber liest diese Ausgabeoption.

Der getrennte Authority-Baselineprozess führte aus:

```lisp
(require :asdf)
(assert (not (find-package "DREYECK/VERIFIED-EXAMPLE")))
(asdf:test-system "dreyeck/authority-policy")
```

Dabei war `HYPERDOC_FEDWIKI_SITE_ROOT` auf
`/workspace/hyperdoc/dreyeck/tests/fixtures/local-fedwiki-view-site/` gesetzt.
Exit 1 reproduziert den vorhandenen Drift-Befund; diese Suite ist nicht bestanden.
