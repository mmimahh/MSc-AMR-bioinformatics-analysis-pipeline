#!/usr/bin/env bash
# ============================================================
# 00_make_isolate_lists.sh
# ------------------------------------------------------------
# WHAT THIS DOES:
#   Looks inside your FASTA folders (set in config.sh) and
#   writes one isolate name per line into a .txt file. Every
#   later script reads isolate names from these .txt files, so
#   this must be run first — and again any time you add new
#   genome files.
#
# HOW TO RUN:
#   bash scripts/00_make_isolate_lists.sh
#
# WHAT "SUCCESS" LOOKS LIKE:
#   Two lines like "wrote 42 isolate names to ..." — if you see
#   "wrote 0 isolate names", double-check the folder paths in
#   config.sh actually contain .fasta files.
# ============================================================
set -euo pipefail                     # stop immediately if anything fails
source "$(dirname "$0")/../config.sh" # load your paths from config.sh

echo "Building E. coli isolate list from: $ECOLI_FASTA_DIR"
if ! ls "$ECOLI_FASTA_DIR"/*.fasta >/dev/null 2>&1; then
    echo "  !! No .fasta files found in $ECOLI_FASTA_DIR"
    echo "  !! Check ECOLI_FASTA_DIR in config.sh"
else
    ls "$ECOLI_FASTA_DIR"/*.fasta | xargs -n 1 basename | sed 's/\.fasta$//' > "$ECOLI_LIST"
    echo "  -> wrote $(wc -l < "$ECOLI_LIST") isolate names to $ECOLI_LIST"
fi

echo "Building Klebsiella isolate list from: $KLEB_FASTA_DIR"
if ! ls "$KLEB_FASTA_DIR"/*.fasta >/dev/null 2>&1; then
    echo "  !! No .fasta files found in $KLEB_FASTA_DIR"
    echo "  !! Check KLEB_FASTA_DIR in config.sh"
else
    ls "$KLEB_FASTA_DIR"/*.fasta | xargs -n 1 basename | sed 's/\.fasta$//' > "$KLEB_LIST"
    echo "  -> wrote $(wc -l < "$KLEB_LIST") isolate names to $KLEB_LIST"
fi

echo "Done. Open the .txt files in isolates/ with any text editor to double-check them."
