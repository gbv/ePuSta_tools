# CLAUDE.md — ePuSta_tools

Shell-Skript-Sammlung zur automatisierten Verarbeitung von Apache-Access-Logs
mit dem [ePuSta-Logfileparser](https://github.com/gbv/ePuSta-logfileparser/)
in einer MIR/reposis-Umgebung.

## Dateischema

- Access-Logs: `<name>.log` oder `<name>.log.gz` (in `ACCESSLOGDIR`)
- ePuSta-Logs: `<name>.epusta.log` oder `<name>.epusta.log.gz` (in `EPUSTALOGDIR`)

## Konfiguration

- `config.template` → nach `config` kopieren und Variablen setzen
- `config` wird **nie committed** (steht in .gitignore)
- Relevante Variablen: `ACCESSLOGDIR`, `EPUSTALOGDIR`, `LOGFILEPREFIX`, `PIPELINE`

## Skripte

| Skript | Zweck |
|---|---|
| `parse.sh` | Hauptskript: parst Access-Logs zu ePuSta-Logs (bevorzugen) |
| `parse_all_missed.sh` | Älteres Skript: parst nur noch fehlende ePuSta-Logs (hardcodete Pipeline) |
| `zipAccessLogs.sh` | Komprimiert alle `.log` in `ACCESSLOGDIR` |
| `zipEpustaLogs.sh` | Komprimiert alle `.log` in `EPUSTALOGDIR` |
| `remove_loglines.sh` | Entfernt MCRLoginServlet-Zeilen aus einer einzelnen Logdatei |
| `remove_all_loglines.sh` | Wie oben, für alle Dateien |
| `renameLogfiles.php` | Benennt Logdateien um |

`parse.sh` ist das aktuelle Hauptskript — `parse_all_missed.sh` ist veraltet
(hardcodete Pipeline, kein `.gz`-Support für Ausgabe).

## Typische Serverumgebung

Pro Repository gibt es einen dedizierten Linux-Nutzer. Dessen Home-Verzeichnis
enthält standardmäßig folgende Unterverzeichnisse:

```
~/accesslogs/           ← Apache schreibt hier die Access-Logs rein ($ACCESSLOGDIR)
~/bin/                  ← git clone von ePuSta_tools (Skripte laufen von hier)
~/epusta-logfileparser/ ← git clone von ePuSta-logfileparser (PHP-Skripte)
~/epustalogs/           ← geparste ePuSta-Logs ($EPUSTALOGDIR)
```

Die Skripte werden manuell gestartet oder täglich per Cron ausgeführt.
Typischer Cron-Eintrag (täglich 6 Uhr):

```
00 6 * * * . /home/<user>/.profile; parse.sh --use-modified-time && zipAccessLogs.sh && zipEpustaLogs.sh
```

`source ~/.profile` in den Skripten und der Cron-Zeile stellt sicher, dass der
PATH (inkl. `~/epusta-logfileparser/`) korrekt gesetzt ist.

## Abhängigkeiten

Die PHP-Skripte der Pipeline müssen im `PATH` liegen (via `~/.profile`):
- `log2epusta.php`
- `addIdentifierMIR.php`
- `filter.php`

Diese kommen aus dem [ePuSta-logfileparser](https://github.com/gbv/ePuSta-logfileparser/).

## Workflow

- Jede Änderung in einem eigenen Branch (`feat/...`)
- PR auf GitHub erstellen, nach Approval mergen
- Lokal: Branch nach dem Merge löschen, auf `main` zurückwechseln
