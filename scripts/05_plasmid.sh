#!/usr/bin/env bash
# ============================================================
# 05_plasmid.sh
# ------------------------------------------------------------
# WHAT THIS DOES:
#   Detects plasmids in every E. coli isolate using
#   PlasmidFinder (run through Docker).
#
# BEFORE RUNNING:
#   Make sure Docker Desktop (or the Docker service) is running,
#   otherwise every isolate will fail with a "Cannot connect to
#   the Docker daemon" error.
#
# HOW TO RUN:
#   bash scripts/05_plasmid.sh
# ============================================================
set -euo pipefail
source "$(dirname "$0")/../config.sh"

OUT="${OUTPUT_DIR}/05_plasmid"
LOGS="${LOG_DIR}/05_plasmid"
mkdir -p "$OUT" "$LOGS"

while read -r x; do
    echo "  Scanning $x ..."
    if docker run --rm \
        -v "$PLASMID_DB:/database" \
        -v "${PROJECT_ROOT}:/workdir" \
        plasmidfinder -i "/workdir/species_fastas/escherichia_coli/${x}.fasta" \
                       -o "/workdir/results/05_plasmid/${x}" \
        2>> "$LOGS/${x}.err"; then
        echo "    done"
    else
        echo "    !! Failed on $x — see $LOGS/${x}.err"
    fi
done < "$ECOLI_LIST"

echo "Plasmid detection complete. Results in $OUT"
echo "(PlaScope is a separate tool and isn't wired into this script yet —"
echo " run it by hand for now if you need it.)"
