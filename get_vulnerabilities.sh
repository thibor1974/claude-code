#!/bin/bash

###############################################################################
# Script: get_vulnerabilities.sh
# Purpose: List vulnerabilities affecting a specific OpenShift version, with the
#          OpenShift release that fixes each one (or its fix status)
# Usage: ./get_vulnerabilities.sh [options] <version> [format] [severity]
#        ./get_vulnerabilities.sh --cve CVE-XXXX-XXXX
#        ./get_vulnerabilities.sh --cve-file FILE <version> [format] [severity]
#
# Thin wrapper around get_vulnerabilities.py (which holds all the logic): same
# features and options, plus the positional [format] [severity] shortcuts.
#
# Report layout: CVEs are ordered by severity (critical, important, moderate,
# low), then by status in the release when a full release is given, then by
# CVSS score. The table and markdown reports start with the number of CVEs per
# severity (json: "by_severity"; stats: "By Severity"). With --priority or
# --priority-file, the listed CVEs come first, in their own section.
#
# Arguments:
#   version   - OpenShift stream (e.g., 4.21) or full release (e.g., 4.21.17) - REQUIRED
#               (except with --cve). With a full release, only the CVEs it is still
#               exposed to are listed: fixed in a later release, or not fixed yet
#               (see --show-fixed, --skip-unfixed)
#   format    - Output format: table, csv, json, stats, markdown (default: table)
#   severity  - Filter by severity: critical, important, moderate, low (optional)
#
# Options:
#   --cve CVE-ID              Fix status of one CVE for every OpenShift version
#   --cve-file FILE           Only the CVEs listed in FILE ('-' for stdin): CVSS score, publication
#                             date, release fixing each one and advisory (RHSA) link, or security
#                             bulletin (RHSB) link when not fixed. With a full release (4.22.18),
#                             also whether that release is still vulnerable
#   --priority CVES           CVE IDs to list first, comma-separated (e.g. CVE-2026-1234,CVE-2026-5678);
#                             can be repeated. Always listed, even when already fixed in the release
#   --priority-file FILE      Same, CVE IDs read from FILE ('-' for stdin). A tag (P1, P2, ...) can be
#                             given per CVE: CSV 'cve,priority' (CVE-2026-1234,P1), or a line 'P1'
#                             before its CVEs. P1 comes before P2; markdown shows the tag.
#                             Priority CVEs not in the report are listed with why, e.g.
#                             "not affecting OpenShift"
#   -f, --format FORMAT       Same as the format argument
#   -s, --severity LEVEL      Same as the severity argument
#   --min-severity LEVEL      Keep LEVEL and the more severe ones (e.g. important = critical + important)
#   -o, --output FILE         Write the report to FILE (default: stdout)
#   --advisory-prefix LIST    Only CVEs with advisories starting with LIST (e.g. RHSA,RHBA)
#   --include-unfixed         Also list CVEs not fixed in this version (slow: a few minutes);
#                             default with a full release
#   --skip-unfixed            With a full release: skip the CVEs not fixed yet (fast)
#   --fixed-in [RELEASE]      Only the CVEs fixed in this exact release (like 4.21.17); the
#                             release can follow the option or be the version argument
#   --no-fix                  Skip the fix lookups (faster)
#   --show-fixed              With a full release: also list the CVEs already fixed in it or earlier
#                             (by default they are only counted)
#
# Examples:
#   ./get_vulnerabilities.sh 4.21
#   ./get_vulnerabilities.sh 4.21.17 table important
#   ./get_vulnerabilities.sh 4.21.17 --show-fixed
#   ./get_vulnerabilities.sh --fixed-in 4.21.17 csv
#   ./get_vulnerabilities.sh 4.12 csv
#   ./get_vulnerabilities.sh 4.12 stats
#   ./get_vulnerabilities.sh 4.12 table critical
#   ./get_vulnerabilities.sh 4.22.18 --min-severity important
#   ./get_vulnerabilities.sh --include-unfixed 4.12 csv important
#   ./get_vulnerabilities.sh 4.22.18 markdown -o reports/cve-4.22.18.md
#   ./get_vulnerabilities.sh --cve CVE-2026-46300
#   ./get_vulnerabilities.sh --cve-file cves.txt 4.22
#   ./get_vulnerabilities.sh --cve-file cves.txt 4.22.18 csv
#   ./get_vulnerabilities.sh 4.22.18 --priority CVE-2026-98432,CVE-2026-19630
#   ./get_vulnerabilities.sh 4.22.18 markdown --priority-file reports/watched.csv
###############################################################################

set -euo pipefail

RED='\033[0;31m'
NC='\033[0m'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY_SCRIPT="${SCRIPT_DIR}/get_vulnerabilities.py"

usage() {
    echo "Usage: $0 [options] <version> [format] [severity]"
    echo "   or: $0 --cve CVE-ID [-o FILE]"
    echo "   or: $0 --cve-file FILE <version> [format] [severity]"
    echo ""
    echo "Arguments:"
    echo "  version   - OpenShift stream (e.g., 4.21) or full release (e.g., 4.21.17)"
    echo "  format    - Output format: table, csv, json, stats, markdown (default: table)"
    echo "  severity  - Filter by severity: critical, important, moderate, low"
    echo ""
    echo "Reports list CVEs by severity (most severe first) and start with the number of CVEs per severity."
    echo "With --priority / --priority-file, the listed CVEs come first, in their own section."
    echo ""
    echo "Options:"
    echo "  --cve CVE-ID              Fix status of one CVE for every OpenShift version"
    echo "  --cve-file FILE           Only the CVEs listed in FILE ('-' for stdin): CVSS score, publication"
    echo "                            date, release fixing each one and RHSA link (RHSB when not fixed)"
    echo "                            version: 4.22, or 4.22.18 to also check that release"
    echo "  --priority CVES           CVE IDs to list first, comma-separated; can be repeated"
    echo "                            (always listed, even when already fixed in the release)"
    echo "  --priority-file FILE      Same, CVE IDs read from FILE ('-' for stdin), with an optional"
    echo "                            P1/P2 tag per CVE: CSV 'cve,priority' or a 'P1' line before its CVEs"
    echo "                            (P1 listed before P2, tag shown in the markdown report)."
    echo "                            Priority CVEs not in the report get a comment, e.g. 'not affecting OpenShift'"
    echo "  -f, --format FORMAT       Same as the format argument"
    echo "  -s, --severity LEVEL      Same as the severity argument"
    echo "  --min-severity LEVEL      Keep LEVEL and the more severe ones (important = critical + important)"
    echo "  -o, --output FILE         Write the report to FILE (default: stdout)"
    echo "  --advisory-prefix LIST    Only CVEs with advisories starting with LIST (e.g. RHSA,RHBA)"
    echo "  --include-unfixed         Also list CVEs not fixed in this version (slow: a few minutes);"
    echo "                            default with a full release"
    echo "  --skip-unfixed            With a full release: skip the CVEs not fixed yet (fast)"
    echo "  --fixed-in [RELEASE]      Only the CVEs fixed in this exact release (like 4.21.17)"
    echo "  --no-fix                  Skip the fix lookups (faster)"
    echo "  --show-fixed              With a full release: also list the CVEs already fixed in it or earlier"
    echo ""
    echo "Examples:"
    echo "  $0 4.21"
    echo "  $0 4.21.17 table important"
    echo "  $0 4.21.17 --show-fixed"
    echo "  $0 --fixed-in 4.21.17 csv"
    echo "  $0 4.12 csv"
    echo "  $0 4.12 stats"
    echo "  $0 4.12 table critical"
    echo "  $0 4.22.18 --min-severity important"
    echo "  $0 --include-unfixed 4.12 csv important"
    echo "  $0 4.22.18 markdown -o reports/cve-4.22.18.md"
    echo "  $0 --cve CVE-2026-46300"
    echo "  $0 --cve-file cves.txt 4.22"
    echo "  $0 --cve-file cves.txt 4.22.18 csv"
    echo "  $0 4.22.18 --priority CVE-2026-98432,CVE-2026-19630"
    echo "  $0 4.22.18 markdown --priority-file reports/watched.csv"
    exit 1
}

error() {
    echo -e "${RED}Error: $*${NC}" >&2
    exit 1
}

# Value of an option that takes one, e.g. need_value --format "$@"
need_value() {
    [ "$#" -ge 2 ] || error "$1 requires a value"
}

OPTS=()
POSITIONAL=()
FIXED_IN=false
CVE_ID=
CVE_FILE=
output_format=
severity_filter=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --cve)
            need_value "$@"
            [[ $2 =~ ^CVE-[0-9]{4}-[0-9]+$ ]] || error "Invalid CVE ID '$2'. Use format like CVE-2026-46300"
            CVE_ID="$2"
            shift 2
            ;;
        --cve-file)
            need_value "$@"
            [ "$2" = "-" ] || [ -r "$2" ] || error "Cannot read CVE file '$2'"
            CVE_FILE="$2"
            shift 2
            ;;
        -f|--format)
            need_value "$@"
            output_format="$2"
            shift 2
            ;;
        -s|--severity)
            need_value "$@"
            severity_filter="$2"
            shift 2
            ;;
        --min-severity)
            need_value "$@"
            case "$2" in
                critical|important|moderate|low) OPTS+=(--min-severity "$2") ;;
                *) error "Invalid severity '$2'. Use critical, important, moderate or low" ;;
            esac
            shift 2
            ;;
        -o|--output)
            need_value "$@"
            OPTS+=(--output "$2")
            shift 2
            ;;
        --advisory-prefix)
            need_value "$@"
            OPTS+=(--advisory-prefix "$2")
            shift 2
            ;;
        --priority)
            need_value "$@"
            OPTS+=(--priority "$2")
            shift 2
            ;;
        --priority-file)
            need_value "$@"
            [ "$2" = "-" ] || [ -r "$2" ] || error "Cannot read priority file '$2'"
            OPTS+=(--priority-file "$2")
            shift 2
            ;;
        --fixed-in)
            FIXED_IN=true
            shift
            ;;
        --include-unfixed|--skip-unfixed|--no-fix|--show-fixed)
            OPTS+=("$1")
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            error "Unknown option '$1'"
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

# --cve: one CVE across all OpenShift versions, no version argument
if [ -n "$CVE_ID" ]; then
    [ "${#POSITIONAL[@]}" -eq 0 ] || error "--cve takes no version, format or severity argument"
    exec python3 "$PY_SCRIPT" --cve "$CVE_ID" ${OPTS[@]+"${OPTS[@]}"}
fi

[ "${#POSITIONAL[@]}" -ge 1 ] || usage
[ "${#POSITIONAL[@]}" -le 3 ] || error "Too many arguments: ${POSITIONAL[*]}"
version="${POSITIONAL[0]}"
# Positional format / severity, unless already given as options
if [ "${#POSITIONAL[@]}" -ge 2 ]; then
    [ -z "$output_format" ] || error "Format given twice ('${output_format}' and '${POSITIONAL[1]}')"
    output_format="${POSITIONAL[1]}"
fi
if [ "${#POSITIONAL[@]}" -ge 3 ]; then
    [ -z "$severity_filter" ] || error "Severity given twice ('${severity_filter}' and '${POSITIONAL[2]}')"
    severity_filter="${POSITIONAL[2]}"
fi
output_format="${output_format:-table}"

[[ $version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || error "Invalid version format. Use format like 4.21 or 4.21.17"
case "$output_format" in
    table|csv|json|stats|markdown) ;;
    *) error "Invalid format '${output_format}'. Use table, csv, json, stats or markdown" ;;
esac
case "$severity_filter" in
    '') ;;
    critical|important|moderate|low) OPTS+=(--severity "$severity_filter") ;;
    *) error "Invalid severity '${severity_filter}'. Use critical, important, moderate or low" ;;
esac

if $FIXED_IN; then
    [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || error "--fixed-in needs a full release like 4.21.17"
    OPTS+=(--fixed-in "$version")
fi

if [ -n "$CVE_FILE" ]; then
    $FIXED_IN && error "--cve-file cannot be combined with --fixed-in"
    OPTS+=(--cve-file "$CVE_FILE")
fi

# ${OPTS[@]+...} keeps bash 3.2 (macOS) happy with an empty array under set -u
exec python3 "$PY_SCRIPT" "$version" --format "$output_format" ${OPTS[@]+"${OPTS[@]}"}
