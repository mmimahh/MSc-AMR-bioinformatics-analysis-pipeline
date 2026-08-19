#!/usr/bin/env bash
# ============================================================
# 07_postprocess.sh
# ------------------------------------------------------------
# WHAT THIS DOES:
#   Cleans up and combines results from earlier stages:
#     1. Standardizes AMRFinder column names (calls an R script)
#     2. Combines all AMRFinder .tsv files into one file
#     3. Converts that combined file to .csv
#     4. Collects Kleborate summary files into one folder
#     5. Runs pathotypeR to predict E. coli pathotypes
#
# HOW TO RUN:
#   bash scripts/07_postprocess.sh
#
# REQUIRES: R installed, with the "dplyr" and "pathotypeR"
# packages available.
# ============================================================
set -euo pipefail
source "$(dirname "$0")/../config.sh"

AMR_DIR="${OUTPUT_DIR}/03_amr/amrfinder"
OUT="${OUTPUT_DIR}/07_postprocess"
LOGS="${LOG_DIR}/07_postprocess"
mkdir -p "$OUT" "$LOGS"

echo "== Step 1: Standardizing AMRFinder column names =="
Rscript "$(dirname "$0")/rename_amrfinder_columns.R" "$AMR_DIR" 2>> "$LOGS/rename_columns.err" \
    && echo "  done" \
    || echo "  !! Failed — see $LOGS/rename_columns.err"

echo "== Step 2: Combining all AMRFinder results into one file =="
awk 'FNR==1 && NR!=1 {next} {print}' "$AMR_DIR"/*.tsv > "$OUT/combined_amr_results.tsv"
echo "  -> $OUT/combined_amr_results.tsv"

echo "== Step 3: Converting the combined file to CSV =="
sed 's/\t/,/g' "$OUT/combined_amr_results.tsv" > "$OUT/combined_amr_results.csv"
echo "  -> $OUT/combined_amr_results.csv"

echo "== Step 4: Collecting Kleborate summary files into one folder =="
mkdir -p "$OUT/kleborate_summaries"
find "${OUTPUT_DIR}/02_typing/kleborate" -type f -name "*.tsv" -exec cp {} "$OUT/kleborate_summaries/" \;
echo "  -> $OUT/kleborate_summaries/"

echo "== Step 5: Running pathotypeR on E. coli isolates =="
Rscript "$(dirname "$0")/run_pathotyper.R" "$ECOLI_FASTA_DIR" "$OUT" 2>> "$LOGS/pathotyper.err" \
    && echo "  done" \
    || echo "  !! Failed — see $LOGS/pathotyper.err"

echo "Post-processing complete. Everything is in $OUT"
