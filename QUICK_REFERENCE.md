# Quick Reference - OpenShift Vulnerability Scanner

## Available Scripts

You have **three** vulnerability scanning scripts:

1. **get_vulnerabilities.sh** - Bash wrapper around the Python script (positional args)
2. **get_vulnerabilities_advanced.sh** - Quick jq-based CVE list with CVSS and publication date (no fix info / links)
3. **get_vulnerabilities.py** - Python script holding all the logic (fixed release, fix status, stats)

---

## Quick Start

### Using the Bash Script

```bash
# Basic usage (fetches real vulnerabilities from Red Hat API)
./get_vulnerabilities.sh 4.21

# Show in different formats
./get_vulnerabilities.sh 4.21 csv > report.csv
./get_vulnerabilities.sh 4.21 json > report.json

# Filter by severity
./get_vulnerabilities.sh 4.21 table important
./get_vulnerabilities.sh 4.21 csv moderate

# Lookup specific CVE details (NEW!)
./get_vulnerabilities.sh --cve CVE-2026-46300

# Fixing release and RHSA link for each CVE listed in a file
./get_vulnerabilities.sh --cve-file cves.txt 4.21
```

### Using the Python Script

```bash
# Basic usage
./get_vulnerabilities.py 4.21

# Show in different formats
./get_vulnerabilities.py 4.21 --format csv > report.csv
./get_vulnerabilities.py 4.21 --format json > report.json
./get_vulnerabilities.py 4.21 --format stats

# Filter by severity
./get_vulnerabilities.py 4.21 --severity important
./get_vulnerabilities.py 4.21 -s moderate -f csv

# Lookup specific CVE details (NEW!)
./get_vulnerabilities.py --cve CVE-2026-46300

# Fixing release and RHSA link for each CVE listed in a file
./get_vulnerabilities.py 4.21 --cve-file cves.txt
```

Filter by advisory prefixes (RHSA/RHBA):
```bash
./get_vulnerabilities.py 4.21 --format json --advisory-prefix RHSA,RHBA | jq '.vulnerabilities[]'
```

### Using the Advanced Bash Script

```bash
# Fastest execution (uses jq, falls back to Python if needed)
./get_vulnerabilities_advanced.sh 4.21

# With format options
./get_vulnerabilities_advanced.sh 4.21 csv
```

---

## CVE Details & Fix Status (NEW!)

Check if a specific CVE is fixed in your OpenShift versions:

```bash
# Get detailed information about a CVE
./get_vulnerabilities.py --cve CVE-2026-46300

# Or using bash
./get_vulnerabilities.sh --cve CVE-2026-46300
```

Output shows:
- CVE severity, CVSS score and publication date
- The release that fixes it in each OpenShift version, with the advisory and its link
- The Red Hat Security Bulletin (RHSB) link when Red Hat published one, and the Red Hat CVE page link
- Other OpenShift products and per-package fix states
- Full description

```
Fixed in OpenShift Container Platform:
--------------------------------------------------------------------------------
  Stream   Fixed In     Advisory         Link
  4.12     4.12.91      RHSA-2026:21695  https://access.redhat.com/errata/RHSA-2026:21695
  4.13     4.13.67      RHSA-2026:21690  https://access.redhat.com/errata/RHSA-2026:21690
  ...
  4.20     4.20.24      RHSA-2026:21702  https://access.redhat.com/errata/RHSA-2026:21702
  4.21     4.21.17      RHBA-2026:20032  https://access.redhat.com/errata/RHBA-2026:20032
```

### Fixed release & fix status per CVE

```bash
# Every CVE fixed in 4.12, with the 4.12.z release that fixes it
./get_vulnerabilities.sh 4.12 csv > fixed_4.12.csv

# Also include CVEs NOT fixed in 4.12 (Affected, Fix deferred, Will not fix...) - takes 2-3 minutes
./get_vulnerabilities.py 4.12 --include-unfixed --format csv > status_4.12.csv
./get_vulnerabilities.sh --include-unfixed 4.12 table important

# Summary by fix status
./get_vulnerabilities.py 4.12 --include-unfixed --format stats

# Skip the fix lookups when you only need the CVE list (faster)
./get_vulnerabilities.py 4.12 --format csv --no-fix
```

### Check a specific release (e.g. 4.21.17)

Give the full release instead of the stream to see which CVEs your cluster is still exposed to:

```bash
./get_vulnerabilities.sh 4.21.17                      # table, most urgent first
./get_vulnerabilities.sh 4.21.17 csv important > exposure_4.21.17.csv
./get_vulnerabilities.py 4.21.17 --format stats       # counts + minimum upgrade
./get_vulnerabilities.py 4.21.17 --include-unfixed    # also CVEs with no fix yet (slow)
```

```
CVE ID           Severity   CVSS  Published   In 4.21.17           Fixed In / Status    Advisory         Link                                                               Description
CVE-2026-114406  CRITICAL   6.8   2026-10-20  VULNERABLE           4.21.40              RHSA-2026:89232  https://access.redhat.com/errata/RHSA-2026:89232                   ca-certificates: Distrust eMudhra intermediate CA certificat
CVE-2026-16242   CRITICAL   9.4   2026-07-17  VULNERABLE           4.21.27              RHSA-2026:48670  https://access.redhat.com/errata/RHSA-2026:48670                   hypershift: Konnectivity proxy-server accepts agent connecti
CVE-2026-46300   IMPORTANT  7.8   2026-05-13  Not vulnerable       4.21.17              RHBA-2026:20032  https://access.redhat.com/errata/RHBA-2026:20032                   kernel: "Fragnesia" is a variant of Dirty Frag vulnerability
...
In 4.21.17: VULNERABLE: 163, Not vulnerable: 26
Upgrade to 4.21.40 or later to get all available fixes
```

The **In 4.21.17** column (`version_status` in CSV/JSON):

| Value | Meaning |
|-------|---------|
| `VULNERABLE` | Fixed in a later release; **Fixed In** is the release to upgrade to |
| `Not vulnerable` | The fix shipped in this release or an earlier one |
| `Vulnerable (no fix)` | No fix in this stream yet (Affected / Fix deferred / Will not fix; with `--include-unfixed`) |
| `Unknown` | The fixing release could not be determined (e.g. `Fixed (see adv.)`), or under investigation |

The data is still fetched for the whole stream (4.21). "VULNERABLE" means the fix came after your release;
Red Hat does not publish whether an individual earlier release actually shipped the vulnerable code.

### CVEs fixed in a specific release (`--fixed-in`)

List only the CVEs whose fix shipped in exactly that release (release notes style):

```bash
./get_vulnerabilities.sh --fixed-in 4.21.17               # table
./get_vulnerabilities.sh --fixed-in 4.21.17 csv important
./get_vulnerabilities.py --fixed-in 4.21.17 --format json
```

```
════════════════════════════════════════════════════════════════════════════════════════════════════
OpenShift 4.21.17 - CVEs fixed in this release
════════════════════════════════════════════════════════════════════════════════════════════════════

CVE ID           Severity   CVSS  Published   First Fixed  Fixed In / Status    Advisory         Link                                                               Description
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CVE-2026-46300   IMPORTANT  7.8   2026-05-13  4.21.17      4.21.17              RHBA-2026:20032  https://access.redhat.com/errata/RHBA-2026:20032                   kernel: "Fragnesia" is a variant of Dirty Frag vulnerability
CVE-2026-41674   IMPORTANT  7.5   2026-05-07  4.21.17      4.21.17              RHSA-2026:20034  https://access.redhat.com/errata/RHSA-2026:20034                   xmldom: xmldom: Arbitrary XML markup injection
CVE-2026-35469   IMPORTANT  6.5   2026-04-13  4.21.16      4.21.17              RHSA-2026:20034  https://access.redhat.com/errata/RHSA-2026:20034                   Kubelet: CRI-O: kube-apiserver: Kubelet, CRI-O, kube-apiserv
CVE-2026-33186   IMPORTANT  9.1   2026-03-20  4.21.10      4.21.17              RHSA-2026:20034  https://access.redhat.com/errata/RHSA-2026:20034                   google.golang.org/grpc/grpc-go: google.golang.org/grpc/authz
...
Total: 7 vulnerabilities found
Fix status: Fixed: 7
First fixed in 4.21.17: 3, fixed earlier with more components fixed in 4.21.17: 4
```

Red Hat often fixes a CVE component by component over several releases, so a CVE is listed if **any** of its
fixes shipped in that release. **First Fixed** shows when the stream first got a fix (`first_fixed_in` in CSV/JSON,
empty when it is this release); JSON also has `fix_releases`, the full list of releases/advisories.
Advisories whose release cannot be determined (a few old ones) cannot be matched; a note on stderr gives the count.

### Fix release & advisory for a list of CVEs (`--cve-file`)

Give a text file of CVE IDs and an OpenShift version, either a stream (`4.22`) or a full release (`4.22.18`).
For each CVE: its severity, CVSS v3 score, publication date, the release of that stream that fixes it
and a link: the advisory (RHSA) that ships the fix, or the security bulletin (RHSB) when the CVE is not fixed.

```bash
cat cves.txt
# CVEs reported by the scanner
CVE-2026-114406
CVE-2026-16242, CVE-2026-43037
CVE-2026-46300
CVE-2021-44228
CVE-2024-3094

./get_vulnerabilities.sh --cve-file cves.txt 4.22             # stream: fixing release in 4.22
./get_vulnerabilities.sh --cve-file cves.txt 4.22.18          # release: also, is each CVE fixed in 4.22.18?
./get_vulnerabilities.sh --cve-file cves.txt 4.22.18 csv      # CSV export
./get_vulnerabilities.py 4.22 --cve-file cves.txt --format json
grep -o 'CVE-[0-9-]*' scan.log | ./get_vulnerabilities.py 4.22 --cve-file -   # read from stdin
```

```
════════════════════════════════════════════════════════════════════════════════════════════════════
OpenShift 4.22.18 - Fix status of the CVEs in cves.txt
════════════════════════════════════════════════════════════════════════════════════════════════════

CVE ID           Severity   CVSS  Published   In 4.22.18           Fixed In / Status    Advisory         Link
--------------------------------------------------------------------------------------------------------------------------------------------------
CVE-2026-114406  CRITICAL   6.8   2026-10-20  VULNERABLE           4.22.20              RHSA-2026:89197  https://access.redhat.com/errata/RHSA-2026:89197
CVE-2026-16242   CRITICAL   9.4   2026-07-17  Not vulnerable       4.22.8               RHSA-2026:48693  https://access.redhat.com/errata/RHSA-2026:48693
CVE-2026-43037   CRITICAL   8.8   2026-05-01  Not vulnerable       4.22.7               RHSA-2026:44232  https://access.redhat.com/errata/RHSA-2026:44232
CVE-2026-46300   IMPORTANT  7.8   2026-05-13  Unknown              No fix listed        RHSB-2026-003    https://access.redhat.com/security/vulnerabilities/RHSB-2026-003
CVE-2021-44228   CRITICAL   9.8   2021-12-10  Unknown              No fix listed        RHSB-2021-009    https://access.redhat.com/security/vulnerabilities/RHSB-2021-009
CVE-2024-3094    CRITICAL   10.0  2024-03-29  Unknown              No fix listed                         https://access.redhat.com/security/cve/CVE-2024-3094

Total: 6 CVEs
Fix status: Fixed: 3, No fix listed: 3
In 4.22.18: VULNERABLE: 1, Unknown: 3, Not vulnerable: 2
Upgrade to 4.22.20 or later to get all available fixes
```

- The file can use any layout (one per line, comma-separated, comments, a scanner report): every `CVE-YYYY-NNNN`
  is picked up, case-insensitively, and duplicates are dropped. CVEs are listed in file order.
- **Fixed In** is the earliest release of the stream with a fix; for CVEs not fixed in the stream it shows
  Red Hat's status instead (Affected, Will not fix, ...) or `No fix listed` when the stream is not concerned.
  Unknown CVE IDs show `Lookup failed` and are named on stderr.
- **Link** depends on whether the CVE is fixed in the stream (`link` in CSV/JSON):
  - **Fixed**: the errata page of the advisory that ships the fix (also in `fix_advisory_url`). Some fixes
    ship in a bug fix advisory (RHBA) rather than an RHSA.
  - **Not fixed**: the Red Hat Security Bulletin (RHSB) when Red Hat published one, with its ID in the
    **Advisory** column (`security_bulletin` in CSV/JSON). Bulletins exist only for high-profile CVEs
    (e.g. Log4Shell, RHSB-2021-009); for the others the link is the Red Hat CVE page, which gives the
    status per product.
- **CVSS** is Red Hat's CVSS v3 base score (`cvss3_score` in CSV/JSON; JSON also has `cvss3_scoring_vector`),
  **Published** the date the CVE was made public (`public_date`). `N/A` when Red Hat gives none.
- With a full release (e.g. 4.22.18), the **In 4.22.18** column says whether that release already has the fix:
  `VULNERABLE` (fixed in a later release: upgrade to **Fixed In**), `Not vulnerable`, or `Unknown`.
- Works with `--severity` and every output format; not with `--fixed-in`, `--include-unfixed`, `--no-fix`
  or `--advisory-prefix`.

## Complete Usage Examples

### Example 2: Export important vulnerabilities as CSV
```bash
./get_vulnerabilities.sh 4.21 csv important > important_vulns.csv
```

### Example 3: Get JSON data for programmatic processing
```bash
./get_vulnerabilities.py 4.21 --format json | jq '.vulnerabilities[] | select(.severity=="important")'
```

### Example 4: Generate vulnerability statistics
```bash
./get_vulnerabilities.py 4.21 --format stats
```

### Example 5: Check if a CVE is fixed in your version
```bash
# Get full details including which versions have fixes
./get_vulnerabilities.py --cve CVE-2026-46300

# Or extract just the fix information
./get_vulnerabilities.sh --cve CVE-2026-46300 | grep -A20 "Fixed in OpenShift Container Platform"
```

This shows:
- Severity and publication date
- Which OpenShift versions have the fix (with advisory IDs)
- Which versions are still affected
- Detailed description

### Example 6: Check only important vulnerabilities
```bash
./get_vulnerabilities.sh 4.21 table important
```

### Example 7: Batch check multiple versions
```bash
for version in 4.19 4.20 4.21; do
    echo "=== Checking OpenShift $version ==="
    ./get_vulnerabilities.py $version --format stats
done
```

### Example 8: Create a vulnerability report with timestamp
```bash
VERSION="4.21"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
./get_vulnerabilities.sh $VERSION csv > "vulns_${VERSION}_${TIMESTAMP}.csv"
```

---

## Choosing Which Script

| Script | Best For | Language | Speed | Features |
|--------|----------|----------|-------|----------|
| **get_vulnerabilities.sh** | General use | Bash → Python | ~15s | Same data as .py, positional args |
| **get_vulnerabilities_advanced.sh** | Quick CVE list | Bash + jq | ~1s | CVSS + date only: no fixed release / status / links |
| **get_vulnerabilities.py** | Everything | Python | ~15s | Fixed release, fix status, stats, `--include-unfixed` |

---

## Output Format Reference

### Table Format (Default - with fixed release / fix status)
```
════════════════════════════════════════════════════════════════════════════════════════════════════
OpenShift 4.12 - Vulnerabilities Report
════════════════════════════════════════════════════════════════════════════════════════════════════

CVE ID           Severity   CVSS  Published   Fixed In / Status    Advisory         Link                                                               Description
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CVE-2026-43037   CRITICAL   8.8   2026-05-01  4.12.92              RHSA-2026:26528  https://access.redhat.com/errata/RHSA-2026:26528                   kernel: ip6_tunnel: clear skb2->cb[] in ip4ip6_err()
CVE-2023-49569   CRITICAL   8.1   2024-01-09  4.12.50              RHSA-2024:0832   https://access.redhat.com/errata/RHSA-2024:0832                    go-git: Maliciously crafted Git server replies can lead to p
CVE-2021-4235    MODERATE   5.5   2022-12-27  4.12.0               RHSA-2022:7398   https://access.redhat.com/errata/RHSA-2022:7398                    go-yaml: Denial of Service in go-yaml
CVE-2023-0229    MODERATE   6.3   2023-01-12  Fixed (see adv.)     RHBA-2023:1037   https://access.redhat.com/errata/RHBA-2023:1037                    openshift/apiserver-library-go: Bypass of SCC seccomp profil
CVE-2026-46333   IMPORTANT  7.8   2026-05-15  Fix deferred         RHSB-2026-004    https://access.redhat.com/security/vulnerabilities/RHSB-2026-004   kernel: Read root-owned files as an unprivileged user
CVE-2026-97631   CRITICAL   8.8   2026-10-22  Affected                              https://access.redhat.com/security/cve/CVE-2026-97631              edk2: Pre-boot RCE in EDK II PXE driver

Total: 3992 vulnerabilities found
Fix status: Fix deferred: 2400, Affected: 918, Will not fix: 312, Fixed: 293, Out of support scope: 37, Under investigation: 32
```
(excerpt of `./get_vulnerabilities.py 4.12 --include-unfixed`; without it only the 293 fixed CVEs are listed)

**CVSS** is Red Hat's CVSS v3 base score (`cvss3_score` in CSV/JSON), **Published** the date the CVE was made
public (`public_date`). **Link** (`link` in CSV/JSON) is where to read about the fix:

| CVE | Advisory column | Link |
|-----|-----------------|------|
| Fixed | The advisory that ships the fix (RHSA, sometimes RHBA) | Its errata page, e.g. `https://access.redhat.com/errata/RHSA-2026:26528` |
| Not fixed, with a Red Hat Security Bulletin | The bulletin (`security_bulletin` in CSV/JSON), e.g. `RHSB-2026-004` | The bulletin page |
| Not fixed, no bulletin (most CVEs) | empty | The Red Hat CVE page, which gives the status per product |

Bulletins exist only for high-profile CVEs; the script finds them on the CVE page of the unfixed CVEs Red Hat flags
as having one (a few extra requests). With `--no-fix` there is no fix information, so no link either.

**Fixed In / Status**, per CVE, for the requested version:

| Value | Meaning |
|-------|---------|
| `4.12.92` | Earliest 4.12 release containing the fix; **Advisory** is the errata that shipped it |
| `Fixed (see adv.)` | Fixed, but the release could not be derived from the advisory (a few old/non-release errata) |
| `Affected`, `Fix deferred`, `Under investigation`, `Will not fix`, `Out of support scope` | Not fixed in this version: Red Hat's status (only with `--include-unfixed`) |
| `No fix listed` / `Lookup failed` | No fix or status published / the per-CVE API call failed |

How it is computed: the CVE's `affected_release` entries for this stream give the advisory, and the
advisory's CSAF document (or errata page) gives the release, e.g. `RHSA-2026:54206` → `4.12.96`.

> **Important:** the product query for a version (e.g. 4.12) only returns CVEs Red Hat has **already fixed** in it.
> To also see CVEs that are **not fixed**, add `--include-unfixed`: it checks the ~4000 CVEs filed against the generic
> "OpenShift Container Platform 4" product (takes 2-3 minutes). Red Hat publishes that status for "OCP 4" as a whole,
> not per minor version, so some of those rows concern components the version you asked for may not ship.

### CSV Format
```csv
CVE,severity,cvss3_score,public_date,version_status,fix_status,fixed_in,fix_advisory,fix_advisory_url,security_bulletin,link,first_fixed_in,bugzilla,description,advisories
CVE-2026-114406,critical,6.8,2026-10-20T13:00:00Z,,Fixed,4.12.102,RHSA-2026:90272,https://access.redhat.com/errata/RHSA-2026:90272,,https://access.redhat.com/errata/RHSA-2026:90272,,2556046,ca-certificates: Distrust eMudhra intermediate CA certificates...,RHSA-2026:90969;...
```

### JSON Format
```json
{
  "version": "4.21",
  "count": 27,
  "vulnerabilities": [
    {
      "CVE": "CVE-2026-46300",
      "severity": "important",
      "public_date": "2026-05-13T12:00:00Z",
      "cvss3_score": "7.8",
      "advisories": ["RHSA-2026:21695", "..."],
      "bugzilla": "2477015",
      "bugzilla_description": "kernel: ...",
      "resource_url": "https://access.redhat.com/hydra/rest/securitydata/cve/CVE-2026-46300.json",
      "fix_status": "Fixed",
      "fixed_in": "4.21.17",
      "fix_advisory": "RHBA-2026:20032",
      "security_bulletin": "",
      "link": "https://access.redhat.com/errata/RHBA-2026:20032"
    }
  ],
  "source": "Red Hat Security Advisory API"
}
```

---

## Common Tasks

### Task: Create a weekly vulnerability report
```bash
#!/bin/bash
REPORT_DIR="./reports"
mkdir -p "$REPORT_DIR"

for version in 4.19 4.20 4.21; do
    echo "Generating report for OpenShift $version..."
    ./get_vulnerabilities.py "$version" --format csv \
        --output "$REPORT_DIR/vulns_${version}_$(date +%Y%m%d).csv"
done

echo "Reports generated in $REPORT_DIR"
```

### Task: Get only important issues
```bash
./get_vulnerabilities.py 4.21 --severity important --format table
```

### Task: Export for external tools
```bash
# Export as JSON for Splunk/ELK/other tools
./get_vulnerabilities.py 4.21 --format json > /var/log/ocp-vulns.json

# Export as CSV for Excel
./get_vulnerabilities.sh 4.21 csv > vulnerability_report.csv
```

### Task: Monitor specific severity levels
```bash
#!/bin/bash
VERSION=$1
SEVERITY=${2:-critical}

CRITICAL_COUNT=$(./get_vulnerabilities.py "$VERSION" --severity "$SEVERITY" --format json | jq '.count')

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "WARNING: Found $CRITICAL_COUNT $SEVERITY vulnerabilities in OpenShift $VERSION"
    # Send alert, create ticket, etc.
fi
```

---

## Troubleshooting

### "Command not found"
```bash
# Make sure scripts are executable
chmod +x get_vulnerabilities.sh
chmod +x get_vulnerabilities.py
```

### "Python3 not found"
```bash
# For Python script, ensure Python 3.6+ is installed
python3 --version

# Or use the bash version instead
./get_vulnerabilities.sh 4.12
```

### Network issues when fetching data
```bash
# All scripts retry failed requests, then exit with code 1 and an error on stderr.
# A network/API failure never produces an empty report.
curl -sSf 'https://access.redhat.com/hydra/rest/securitydata/cve.json?per_page=1' >/dev/null && echo "API reachable"
```

---

## Integration Examples

### With Jenkins
```groovy
pipeline {
    stages {
        stage('Scan Vulnerabilities') {
            steps {
                script {
                    sh './get_vulnerabilities.py ${OCP_VERSION} --format json > vulns.json'
                    def vulns = readJSON file: 'vulns.json'
                    if (vulns.count > 0) {
                        unstable("Found ${vulns.count} vulnerabilities")
                    }
                }
            }
        }
    }
}
```

### With Kubernetes CronJob
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ocp-vuln-scanner
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: scanner
            image: quay.io/my-org/ocp-scanner:latest
            command:
            - /bin/bash
            - -c
            - |
              ./get_vulnerabilities.sh 4.12 csv > /reports/vulns_$(date +%Y%m%d).csv
            volumeMounts:
            - name: reports
              mountPath: /reports
          volumes:
          - name: reports
            persistentVolumeClaim:
              claimName: scanner-reports
          restartPolicy: OnFailure
```

---

## Support & Documentation

- Full documentation: See `VULNERABILITIES_README.md`
- Red Hat Security: https://access.redhat.com/security/
- OpenShift Docs: https://docs.openshift.com/
- CVE Database: https://cve.mitre.org/
