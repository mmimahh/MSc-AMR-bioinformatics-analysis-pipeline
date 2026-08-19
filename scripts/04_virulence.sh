#!/usr/bin/env bash
# ============================================================
# 04_virulence.sh
# ------------------------------------------------------------
# WHAT THIS DOES:
#   Runs VirulenceFinder on every E. coli isolate to detect
#   virulence genes.
#
# BEFORE RUNNING — IMPORTANT:
#   VirulenceFinder needs its Python environment active first.
#   In your terminal, run this once before running this script:
#     source /path/to/virulencefinder_env/bin/activate
#   (this script doesn't do it for you, since the exact location
#   depends on how you installed it)
#
# HOW TO RUN:
#   bash scripts/04_virulence.sh
# ============================================================
set -euo pipefail
source "$(dirname "$0")/../config.sh"

OUT="${OUTPUT_DIR}/04_virulence"
LOGS="${LOG_DIR}/04_virulence"
mkdir -p "$OUT" "$LOGS"

while read -r x; do
    echo "  Scanning $x ..."
    if python3 "$VIRULENCEFINDER_SCRIPT" \
        -i "${ECOLI_FASTA_DIR}/${x}.fasta" \
        -o "$OUT/${x}.tsv" \
        -d "$VIRULENCEFINDER_DB" \
        2>> "$LOGS/${x}.err"; then
        echo "    done"
    else
        echo "    !! Failed on $x — see $LOGS/${x}.err"
        echo "    (most common cause: forgot to activate the virulencefinder_env first)"
    fi
done < "$ECOLI_LIST"

echo "Virulence gene detection complete. Results in $OUT"
