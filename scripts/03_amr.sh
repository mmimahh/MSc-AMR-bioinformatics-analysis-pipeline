#!/usr/bin/env bash
# ============================================================
# 03_amr.sh
# ------------------------------------------------------------
# WHAT THIS DOES:
#   Detects antimicrobial resistance (AMR) genes:
#     - AMRFinderPlus for E. coli
#     - ResFinder (acquired genes + point mutations) for Klebsiella
#   Every isolate's result lands in
#   results/03_amr/<tool>/<isolate>.tsv — this consistent
#   naming is what lets 07_postprocess.sh combine everything
#   later without modification.
#
# HOW TO RUN:
#   bash scripts/03_amr.sh
# ============================================================
set -euo pipefail
source "$(dirname "$0")/../config.sh"

OUT="${OUTPUT_DIR}/03_amr"
LOGS="${LOG_DIR}/03_amr"
mkdir -p "$OUT/amrfinder" "$OUT/resfinder" "$LOGS"

echo "== AMRFinderPlus (E. coli) =="
while read -r x; do
    echo "  Scanning $x ..."
    if amrfinder -n "${ECOLI_FASTA_DIR}/${x}.fasta" --plus -O Escherichia \
        -o "$OUT/amrfinder/${x}.tsv" 2>> "$LOGS/${x}_amrfinder.err"; then
        echo "    done"
    else
        echo "    !! Failed on $x — see $LOGS/${x}_amrfinder.err"
    fi
done < "$ECOLI_LIST"

echo "== ResFinder (Klebsiella, acquired + point mutations) =="
while read -r x; do
    echo "  Scanning $x ..."
    if docker run --rm \
        -v "${PROJECT_ROOT}:/app" \
        genomicepidemiology/resfinder \
        -ifa "/app/species_fastas/klebsiella_pneumoniae/${x}.fasta" \
        -o "/app/results/03_amr/resfinder/${x}" \
        -s klebsiella --acquired --point \
        2>> "$LOGS/${x}_resfinder.err"; then
        echo "    done"
    else
        echo "    !! Failed on $x — see $LOGS/${x}_resfinder.err"
    fi
done < "$KLEB_LIST"

echo "AMR detection complete. Results in $OUT"
