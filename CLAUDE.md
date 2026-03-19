# CLAUDE.md — ePuSta_tools

Collection of shell scripts for automated processing of Apache access logs
using the [ePuSta-logfileparser](https://github.com/gbv/ePuSta-logfileparser/)
in a MIR/reposis environment.

## File naming scheme

- Access logs: `<name>.log` or `<name>.log.gz` (in `ACCESSLOGDIR`)
- ePuSta logs: `<name>.epusta.log` or `<name>.epusta.log.gz` (in `EPUSTALOGDIR`)

## Configuration

- Copy `config.template` to `config` and set the variables
- `config` is **never committed** (listed in .gitignore)
- Relevant variables: `ACCESSLOGDIR`, `EPUSTALOGDIR`, `LOGFILEPREFIX`, `PIPELINE`

## Scripts

| Script | Purpose |
|---|---|
| `parse.sh` | Main script: parses access logs to ePuSta logs (preferred) |
| `parse_all_missed.sh` | Older script: only parses missing ePuSta logs (hardcoded pipeline) |
| `zipAccessLogs.sh` | Compresses all `.log` files in `ACCESSLOGDIR` |
| `zipEpustaLogs.sh` | Compresses all `.log` files in `EPUSTALOGDIR` |
| `remove_loglines.sh` | Removes MCRLoginServlet lines from a single log file |
| `remove_all_loglines.sh` | Same as above, for all files |
| `renameLogfiles.php` | Renames log files |

`parse.sh` is the current main script — `parse_all_missed.sh` is outdated
(hardcoded pipeline, no `.gz` support for output).

## Typical server environment

Each repository has a dedicated Linux user. Their home directory contains
the following subdirectories by default:

```
~/accesslogs/           ← Apache writes access logs here ($ACCESSLOGDIR)
~/bin/                  ← git clone of ePuSta_tools (scripts run from here)
~/epusta-logfileparser/ ← git clone of ePuSta-logfileparser (PHP scripts)
~/epustalogs/           ← parsed ePuSta logs ($EPUSTALOGDIR)
```

Scripts are started manually or run daily via cron.
Typical cron entry (daily at 6 AM):

```
00 6 * * * . /home/<user>/.profile; parse.sh --use-modified-time && zipAccessLogs.sh && zipEpustaLogs.sh
```

`source ~/.profile` in the scripts and the cron entry ensures that the
PATH (including `~/epusta-logfileparser/`) is set correctly.

## Dependencies

The PHP scripts of the pipeline must be in `PATH` (via `~/.profile`):
- `log2epusta.php`
- `addIdentifierMIR.php`
- `filter.php`

These come from the [ePuSta-logfileparser](https://github.com/gbv/ePuSta-logfileparser/).

## Workflow

- Every change in its own branch (`feat/...`)
- Create PR on GitHub, merge after approval
- Locally: delete branch after merge, switch back to `main`
