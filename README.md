# OpenShift Toolbox

Command-line tools for checking OpenShift releases, operators and vulnerabilities, using Red Hat's public APIs and operator index images.

| I want to… | Tool | Documentation |
|---|---|---|
| List the CVEs affecting an OpenShift version, with CVSS score, publication date, the release that fixes each one and its RHSA link (RHSB when not fixed) | `get_vulnerabilities.py` / `.sh` | [Vulnerability Scanner](VULNERABILITIES_README.md) |
| Get the CVSS score, publication date, fixing release and RHSA link (RHSB when not fixed) for a list of CVEs in a file (e.g. for 4.22 or 4.22.18) | `get_vulnerabilities.py` / `.sh` `--cve-file` | [Vulnerability Scanner](VULNERABILITIES_README.md#fix-release--advisory-for-a-list-of-cves---cve-file) |
| List the operators available for an OpenShift version, with the latest version per channel | `list_operators.py` | [Operator Versions](OPERATORS_README.md) |
| See an operator's upgrade graph and the path OLM follows from the installed version | `operator_upgrade_path.py` | [Operator Upgrade Path](OPERATOR_UPGRADE_PATH_README.md) |
| Follow a release's CVEs day by day in a git-tracked Markdown page | `.github/workflows/cve-report.yml` | [Scheduled report](VULNERABILITIES_README.md#scheduled-report-in-git-github-actions) · [reports/](reports/) |
| List the OpenShift releases in a stream and their update channels | `list_versions.py` | `./list_versions.py --help` |
| Follow a stream's releases (new releases, channel changes) day by day in a git-tracked Markdown page | `.github/workflows/versions-report.yml` | [Scheduled reports](#scheduled-reports-github-actions) · [reports/](reports/) |

## Documentation

### Vulnerabilities

- **[VULNERABILITIES_README.md](VULNERABILITIES_README.md)**: full guide to the vulnerability scanner: installation, CVE details and fix status, checking a specific release (e.g. `4.21.17`), filters and output formats.
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)**: cheat sheet of common commands for the three scanner scripts.
- **[SUMMARY.md](SUMMARY.md)**: overview of the scanner files, data source, usage examples and which script to pick.

### Operators

- **[OPERATORS_README.md](OPERATORS_README.md)**: lists operators per catalog and channel, compares two OpenShift versions, and exports to table, CSV or JSON. Data comes from the Red Hat Ecosystem Catalog (Pyxis).
- **[OPERATOR_UPGRADE_PATH_README.md](OPERATOR_UPGRADE_PATH_README.md)**: builds the OLM upgrade graph from the operator index image, shows the upgrade path from an installed version, and can output a Mermaid diagram. Covers disconnected clusters too.

## Scripts

| Script | Purpose | Data source |
|---|---|---|
| [get_vulnerabilities.py](get_vulnerabilities.py) | Vulnerability scanner (holds all the logic) | Red Hat Security Data API |
| [get_vulnerabilities.sh](get_vulnerabilities.sh) | Bash wrapper around the Python scanner: same options, plus positional `<version> [format] [severity]` shortcuts | Red Hat Security Data API |
| [get_vulnerabilities_advanced.sh](get_vulnerabilities_advanced.sh) | jq-based scanner, for speed | Red Hat Security Data API |
| [list_operators.py](list_operators.py) | Operators and channel heads per OpenShift version | Red Hat Ecosystem Catalog (Pyxis) |
| [operator_upgrade_path.py](operator_upgrade_path.py) | OLM upgrade graph and upgrade path | Operator index image (`oc image extract`) |
| [list_versions.py](list_versions.py) | Releases per stream, update channels and release dates | OpenShift update graph (Cincinnati) |
| [.github/workflows/cve-report.yml](.github/workflows/cve-report.yml) | Daily run of `get_vulnerabilities.py`, commits [reports/](reports/)`cve-<release>.md` when it changes | GitHub Actions |
| [.github/workflows/versions-report.yml](.github/workflows/versions-report.yml) | Daily run of `list_versions.py`, commits [reports/](reports/)`versions-<stream>.md` when it changes | GitHub Actions |

## Scheduled reports (GitHub Actions)

Two workflows regenerate Markdown pages in [reports/](reports/) and commit them when the data changes, so each
page's git history shows what changed and when:

| Workflow | Page | Content | Settings in the workflow file |
|---|---|---|---|
| [CVE report](.github/workflows/cve-report.yml) | `reports/cve-<release>.md` | CVEs fixed in a later release and CVEs with no fix yet ([details](VULNERABILITIES_README.md#scheduled-report-in-git-github-actions)) | `RELEASES`, `MIN_SEVERITY` |
| [Versions report](.github/workflows/versions-report.yml) | `reports/versions-<stream>.md` | Every release of the stream, newest first: release date, update channels, errata link | `STREAMS` |

- **When:** the `cron:` lines, in UTC (Belgian time minus 1 hour in winter, minus 2 in summer); edit them freely.
  To run one now: Actions tab → pick the workflow → *Run workflow* (you can also type other releases or streams there).
- **No noise:** a new "Generated on" date alone does not make a commit.
- **Requirements:** Settings → Actions → General → Workflow permissions: *Read and write*. GitHub pauses scheduled
  workflows after 60 days without activity in the repository.

The pages can also be made by hand:

```bash
./list_versions.py 4.22 --format markdown --output reports/versions-4.22.md
./get_vulnerabilities.py 4.22.18 --min-severity important --format markdown --output reports/cve-4.22.18.md
```

## Requirements

- Python 3.9+ (standard library only)
- `curl`, and `jq` for `get_vulnerabilities_advanced.sh`
- The `oc` CLI and access to `registry.redhat.io` for `operator_upgrade_path.py`
- Internet access to the Red Hat APIs

## Quick start

```bash
# CVEs affecting OpenShift 4.21
./get_vulnerabilities.py 4.21

# Fixing release and RHSA link for each CVE in a file
./get_vulnerabilities.sh --cve-file cves.txt 4.21

# Operators available for OpenShift 4.21
./list_operators.py 4.21

# Upgrade path of an operator from its installed version
./operator_upgrade_path.py 4.21 cluster-logging --from 6.4.2

# Releases in the 4.21 stream
./list_versions.py 4.21

# Same, as a Markdown page
./list_versions.py 4.21 --format markdown --output versions-4.21.md
```

See each guide for the full set of options.
