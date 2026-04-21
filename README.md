# ePuSta_tools

Collection of shell scripts for **mass / batch processing** in the ePuSta
ecosystem. Used to automate the end-to-end pipeline (Apache access logs →
epustalogfile → Solr import) in MIR / reposis environments.

Related projects:

- [ePuSta-logfileparser](https://github.com/gbv/ePuSta-logfileparser/) –
  PHP library and CLI for processing a **single** log file (parse, filter,
  enrich, anonymize).
- [ePuSta-Server](https://github.com/gbv/ePuSta-Server/) – Solr-based index
  and HTTP APIs; CLI tools for operating on a **single** import file.

## Division of responsibilities

| Concern | Home project |
|---|---|
| Processing of a **single** access-log / epustalog file | `ePuSta-logfileparser` |
| Processing of a **single** Solr import file / operations on one source | `ePuSta-Server` |
| **Mass processing** across many files or whole directories | `ePuSta_tools` (this project) |
| Orchestration across repositories, cron integration | `ePuSta_tools` |

### Planned: consolidation of batch scripts

The `*-all.sh` and `*_allMissed.*` scripts that currently live in
`ePuSta-Server/bin/` (e.g. `createSolrImport_all.sh`, `import_all.sh`,
`import_allMissed.php`) are mass-processing helpers and will be **moved into
this project**. After the move, `ePuSta-Server/bin/` will only contain
scripts that operate on a single file or on the Solr core itself.

Until the move is done, these scripts can still be found in the server
project.

## Scripts (current)

| Script | Purpose |
|---|---|
| `parse.sh` | Main entry point: parses all access logs in `$ACCESSLOGDIR` into epustalogfiles in `$EPUSTALOGDIR` using the configured `PIPELINE`. Supports `--use-modified-time` to only (re-)process files whose source is newer than the target. |
| `parse_all_missed.sh` | Older helper that only parses missing epustalogfiles (hardcoded pipeline, no `.gz` output). Superseded by `parse.sh`. |
| `zipAccessLogs.sh` | Compresses all `.log` files in `$ACCESSLOGDIR`. |
| `zipEpustaLogs.sh` | Compresses all `.log` files in `$EPUSTALOGDIR`. |
| `remove_loglines.sh` | Removes `MCRLoginServlet` lines from a single log file. |
| `remove_all_loglines.sh` | Same as above, applied to all files. |
| `renameLogfiles.php` | Renames log files to the ePuSta naming scheme. |

## File naming scheme

- Access logs: `<name>.log` or `<name>.log.gz` (in `$ACCESSLOGDIR`)
- ePuSta logs: `<name>.epusta.log` or `<name>.epusta.log.gz` (in
  `$EPUSTALOGDIR`)

## Configuration

- Copy `config.template` to `config` and adjust the values.
- `config` is **not committed** (listed in `.gitignore`).

Relevant variables:

| Variable | Purpose |
|---|---|
| `ACCESSLOGDIR` | Directory Apache writes access logs to |
| `EPUSTALOGDIR` | Directory where parsed epustalogfiles are stored |
| `LOGFILEPREFIX` | Prefix used for log file names |
| `PIPELINE` | Pipeline expression (see below) |

### Pipeline

The `PIPELINE` variable defines the sequence of CLI tools from
`ePuSta-logfileparser` that is applied to each raw log line. Typical setup:

```
PIPELINE="log2epusta.php | addIdentifierMIR.php | filter.php"
```

Because these PHP scripts live in `ePuSta-logfileparser`, their location
must be in `$PATH` (usually via `~/.profile`, see below).

## Typical server environment

Each repository has its own Linux user. Its home directory contains:

```
~/accesslogs/           ← Apache writes access logs here ($ACCESSLOGDIR)
~/bin/                  ← git clone of ePuSta_tools (scripts run from here)
~/epusta-logfileparser/ ← git clone of ePuSta-logfileparser (PHP CLI tools)
~/epustalogs/           ← parsed epustalogfiles ($EPUSTALOGDIR)
```

Run manually or via cron. Typical cron entry (daily at 6 AM):

```
00 6 * * * . /home/<user>/.profile; parse.sh --use-modified-time && zipAccessLogs.sh && zipEpustaLogs.sh
```

Sourcing `~/.profile` ensures `PATH` includes `~/epusta-logfileparser/`.

## Dependencies

The PHP scripts referenced in `PIPELINE` must be in `PATH`:

- `log2epusta.php`
- `addIdentifierMIR.php` / `addIdentifierOpus4.php`
- `filter.php`
- `anonymize.php`

They come from [ePuSta-logfileparser](https://github.com/gbv/ePuSta-logfileparser/).

## Workflow

- Every change in its own feature branch.
- Open a PR on GitHub and merge after approval.
- Locally: delete the branch after merge and switch back to `main`.
