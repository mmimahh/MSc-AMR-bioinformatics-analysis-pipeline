#!/usr/bin/env bash
# ============================================================
# 02_typing.sh
# ------------------------------------------------------------
# WHAT THIS DOES:
#   Runs sequence typing on every isolate:
#     - MLST + Kleborate for Klebsiella
#     - FimTyper for E. coli
#   Every result goes to results/02_typing/<tool>/<isolate>.tsv
#   and every failure is logged to logs/02_typing/ instead of
#   just silently vanishing.
#
# HOW TO RUN:
#   bash scripts/02_typing.sh
#
# WHAT "SUCCESS" LOOKS LIKE:
#   A final line like "Typing complete: 40 succeeded, 0 failed".
#   If anything failed, it names the log file to open and read.
# ============================================================
set -euo pipefail
source "$(dirname "$0")/../config.sh"

OUT="${OUTPUT_DIR}/02_typing"
LOGS="${LOG_DIR}/02_typing"
mkdir -p "$OUT/mlst" "$OUT/kleborate" "$OUT/fimtyper" "$LOGS"

success=0
failed=0

echo "== MLST + Kleborate (Klebsiella) =="
while read -r x; do
    echo "  Typing $x ..."
    if mlst -scheme klebsiella "${KLEB_FASTA_DIR}/${x}.fasta" >> "$OUT/mlst/${x}.tsv" 2>> "$LOGS/${x}_mlst.err" \
       && kleborate -a "${KLEB_FASTA_DIR}/${x}.fasta" -o "$OUT/kleborate/${x}.tsv" -p kpsc --trim_headers 2>> "$LOGS/${x}_kleborate.err"; then
        success=$((success+1))
    else
        echo "    !! Failed on $x — see $LOGS/${x}_mlst.err or ${x}_kleborate.err"
        failed=$((failed+1))
    fi
done < "$KLEB_LIST"

echo "== FimTyper (E. coli) =="
while read -r x; do
    echo "  Typing $x ..."
    if perl "$FIMTYPER_SCRIPT" \
         -d "$FIMTYPER_DB" -b "$FIMTYPER_BLAST" \
         -i "${ECOLI_FASTA_DIR}/${x}.fasta" \
         -o "$OUT/fimtyper/${x}" -k 95.00 -l 0.60 2>> "$LOGS/${x}_fimtyper.err"; then
        success=$((success+1))
    else
        echo "    !! Failed on $x — see $LOGS/${x}_fimtyper.err"
        failed=$((failed+1))
    fi
done < "$ECOLI_LIST"

echo "Typing complete: $success succeeded, $failed failed."
echo "If anything failed, open the matching file in $LOGS to see why."
