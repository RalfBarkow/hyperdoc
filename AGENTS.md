## Kuratierte FAQ

Der [FAQ-Index](assets/faq/index.json) führt zum DITA-Topic und zum archivierten Prüfprotokoll. Vor einer Änderung den Geltungsbereich des Eintrags und den geprüften Commit lesen.

Den ASDF-Prüflauf im gepinnten Dev-Shell als normaler Benutzer ausführen. Bei den vier Zielpfaden für die Nix-Quelle berechnet die Probe ausschließlich Namen. Zum Aktualisieren des veröffentlichten Befunds im Checkout:

```sh
nix develop --no-update-lock-file -c bash scripts/check-asdf-fasl-nix-store.sh > /tmp/faq-check.txt &&
  python3 scripts/faq-evidence.py --record /tmp/faq-check.txt
bash scripts/render-faq.sh
python3 scripts/faq-evidence.py --check
```

Der Index nennt das Datum des letzten **archivierten** erfolgreichen Laufs. Die CI prüft den zugehörigen SHA-256 und wiederholt die Fälle in frischen Prozessen. Fleet liefert die Dateien aus `assets/faq/` auf dem Staging-Host aus.
