# CLAUDE.md — ePuSta_tools

Shell scripts for **mass / batch processing** in the ePuSta ecosystem.
Automates the Apache access log → epustalogfile → Solr pipeline in
MIR / reposis environments, using
[ePuSta-logfileparser](https://github.com/gbv/ePuSta-logfileparser/) and
[ePuSta-Server](https://github.com/gbv/ePuSta-Server/) as building blocks.

## Division of responsibilities (ePuSta ecosystem)

- **Single-file processing** lives in:
  - `ePuSta-logfileparser` (parse / enrich / filter a single access log)
  - `ePuSta-Server` (single Solr import JSON / operations on one source)
- **Mass processing & orchestration** lives in **this project**:
  - iterate over whole directories of logs
  - cron integration, gzip handling, pipeline composition

### Planned move

The `*-all.sh` / `*_allMissed.*` scripts in `ePuSta-Server/bin/`
(currently: `createSolrImport_all.sh`, `import_all.sh`,
`import_allMissed.php`) are mass-processing helpers and will be moved here.
Until the move happens, keep them in mind when looking for "batch Solr
import" — they are still in the server repo.

## File naming scheme

- Access logs: `<name>.log` or `<name>.log.gz` (in `ACCESSLOGDIR`)
- ePuSta logs: `<name>.epusta.log` or `<name>.epusta.log.gz` (in `EPUSTALOGDIR`)

## Configuration

- Copy `config.template` to `config` and set the variables
- `config` is **never committed** (listed in `.gitignore`)
- Relevant variables: `ACCESSLOGDIR`, `EPUSTALOGDIR`, `LOGFILEPREFIX`, `PIPELINE`

## Scripts

| Script | Purpose |
|---|---|
| `parse.sh` | Main script: parses access logs to ePuSta logs (preferred). Supports `--use-modified-time` for incremental runs. |
| `parse_all_missed.sh` | Older script: only parses missing ePuSta logs (hardcoded pipeline, no `.gz` output). Outdated. |
| `zipAccessLogs.sh` | Compresses all `.log` files in `ACCESSLOGDIR`. |
| `zipEpustaLogs.sh` | Compresses all `.log` files in `EPUSTALOGDIR`. |
| `remove_loglines.sh` | Removes MCRLoginServlet lines from a single log file. |
| `remove_all_loglines.sh` | Same as above, for all files. |
| `renameLogfiles.php` | Renames log files. |

`parse.sh` is the current main script — `parse_all_missed.sh` is outdated.

## Typical server environment

Each repository has a dedicated Linux user. Their home directory contains:

```
~/accesslogs/           ← Apache writes access logs here ($ACCESSLOGDIR)
~/bin/                  ← git clone of ePuSta_tools (scripts run from here)
~/epusta-logfileparser/ ← git clone of ePuSta-logfileparser (PHP scripts)
~/epustalogs/           ← parsed ePuSta logs ($EPUSTALOGDIR)
```

Scripts run manually or daily via cron. Typical entry (6 AM daily):

```
00 6 * * * . /home/<user>/.profile; parse.sh --use-modified-time && zipAccessLogs.sh && zipEpustaLogs.sh
```

Sourcing `~/.profile` in the cron line ensures that `PATH` contains
`~/epusta-logfileparser/`.

## Dependencies

The PHP scripts of the pipeline must be in `PATH` (via `~/.profile`):

- `log2epusta.php`
- `addIdentifierMIR.php`
- `filter.php`

These come from [ePuSta-logfileparser](https://github.com/gbv/ePuSta-logfileparser/).

## Workflow

- Every change in its own branch (`feat/...`)
- Create PR on GitHub, merge after approval
- Locally: delete branch after merge, switch back to `main`
