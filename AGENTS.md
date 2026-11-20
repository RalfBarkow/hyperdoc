# HyperDoc operator authority

- Repository automation and coding agents must not open SSH sessions or invoke SSH, SCP or SFTP, including through Git transports, wrappers or other tools.
- Model host and service actions on the relevant Lisp Topics. State the target, operation and effects before the operator can authorize an action. A Play control that prepares an observation must not carry it out.
- A manual observation can show the bounded command for an already authorized operator session and accept the resulting evidence. A request, an approved effect and an observed result are separate records.
- Keep Git publication and server activation under the operator's explicit control. Use local files or HTTP(S) for Git tooling.

## Kuratierte FAQ

Bei Fragen zur Umgebung zuerst den [FAQ-Index](assets/faq/index.json) lesen, sobald er im Checkout vorhanden ist. In der Antwort die ID des herangezogenen Eintrags nennen. Vor einer Änderung den Geltungsbereich des Eintrags und den geprüften Commit lesen.

Den ASDF-Prüflauf im gepinnten Dev-Shell als normaler Benutzer ausführen. Bei den vier Zielpfaden für die Nix-Quelle berechnet die Probe ausschließlich Namen. Zum Aktualisieren des veröffentlichten Befunds im Checkout:

```sh
nix develop --no-update-lock-file -c bash scripts/check-asdf-fasl-nix-store.sh > /tmp/faq-check.txt &&
  python3 scripts/faq-evidence.py --record /tmp/faq-check.txt
bash scripts/render-faq.sh
python3 scripts/faq-evidence.py --check
```

Der Index nennt das Datum des letzten **archivierten** erfolgreichen Laufs. Die CI prüft den zugehörigen SHA-256 und wiederholt die Fälle in frischen Prozessen. Die Auslieferung der Dateien aus `assets/faq/` auf dem Staging-Host ist über Fleet vorgesehen.
