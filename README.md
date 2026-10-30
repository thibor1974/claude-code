# OpenShift Toolbox

Command-line tools for checking OpenShift releases, operators and vulnerabilities, using Red Hat's public APIs and operator index images.

| I want to… | Tool | Documentation |
|---|---|---|
| List the CVEs affecting an OpenShift version, with CVSS score, publication date, the release that fixes each one and its RHSA link (RHSB when not fixed) | `get_vulnerabilities.py` / `.sh` | [Vulnerability Scanner](VULNERABILITIES_README.md) |
| Get the CVSS score, publication date, fixing release and RHSA link (RHSB when not fixed) for a list of CVEs in a file (e.g. for 4.22 or 4.22.18) | `get_vulnerabilities.py` / `.sh` `--cve-file` | [Vulnerability Scanner](VULNERABILITIES_README.md#fix-release--advisory-for-a-list-of-cves---cve-file) |
| List the operators available for an OpenShift version, with the latest version per channel | `list_operators.py` | [Operator Versions](OPERATORS_README.md) |
| See an operator's upgrade graph and the path OLM follows from the installed version | `operator_upgrade_path.py` | [Operator Upgrade Path](OPERATOR_UPGRADE_PATH_README.md) |
| List the OpenShift releases in a stream and their update channels | `list_versions.py` | `./list_versions.py --help` |

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
| [get_vulnerabilities.sh](get_vulnerabilities.sh) | Bash wrapper around the Python scanner, with positional arguments | Red Hat Security Data API |
| [get_vulnerabilities_advanced.sh](get_vulnerabilities_advanced.sh) | jq-based scanner, for speed | Red Hat Security Data API |
| [list_operators.py](list_operators.py) | Operators and channel heads per OpenShift version | Red Hat Ecosystem Catalog (Pyxis) |
| [operator_upgrade_path.py](operator_upgrade_path.py) | OLM upgrade graph and upgrade path | Operator index image (`oc image extract`) |
| [list_versions.py](list_versions.py) | Releases per stream, update channels and release dates | OpenShift update graph (Cincinnati) |

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
```

See each guide for the full set of options.
