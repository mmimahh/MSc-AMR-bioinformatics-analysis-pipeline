#!/usr/bin/env bash
# ============================================================
# config.sh
# ------------------------------------------------------------
# This is the ONLY file you should need to edit before running
# the pipeline. It tells every other script:
#   - where your project lives on this computer
#   - where your genome files (.fasta) are
#   - where each tool's reference database is
#   - where results and logs should be written
#
# HOW TO USE THIS FILE:
#   1. Open it in a text editor (e.g. run: nano config.sh)
#   2. Replace every path below with the correct path for YOUR
#      computer. Copy-paste is safer than retyping.
#   3. Save and close.
#   4. Every script in scripts/ reads these values automatically
#      when you run it — you never edit those scripts directly.
#
# WHAT IS A "PATH"?
#   It's just the address of a folder on your computer, e.g.
#   /home/joy/Project/Ayomide  — like a street address, but for
#   files. You can find a folder's path by opening a terminal,
#   navigating to it with `cd`, then typing `pwd`.
# ============================================================

# ---- 1. Project root -------------------------------------------------------
# The main folder that contains everything for this project.
PROJECT_ROOT="/home/joy/Project/Ayomide"

# ---- 2. Where your genome files (FASTA) live, per species ------------------
ECOLI_FASTA_DIR="${PROJECT_ROOT}/species_fastas/escherichia_coli"
KLEB_FASTA_DIR="${PROJECT_ROOT}/species_fastas/klebsiella_pneumoniae"
ECOLI_FASTQ_DIR="${PROJECT_ROOT}/species_fastqs/escherichia_coli"

# ---- 3. Isolate lists (plain text files, one isolate name per line) --------
# These are created automatically by scripts/00_make_isolate_lists.sh —
# you don't need to create them by hand.
ISOLATE_DIR="${PROJECT_ROOT}/isolates"
ECOLI_LIST="${ISOLATE_DIR}/ecoli_isolates.txt"
KLEB_LIST="${ISOLATE_DIR}/kleb_isolates.txt"

# ---- 4. Tool databases ------------------------------------------------------
PLASMID_DB="${PROJECT_ROOT}/plasmidfinder_db"
VIRULENCEFINDER_DB="${PROJECT_ROOT}/virulencefinder/virulencefinder_db"
FIMTYPER_DB="${PROJECT_ROOT}/fimtyper/fimtyper_db"
FIMTYPER_BLAST="${PROJECT_ROOT}/fimtyper/ncbi-blast-2.12.0+"
VIRULENCEFINDER_SCRIPT="${PROJECT_ROOT}/virulencefinder/virulencefinder.py"
FIMTYPER_SCRIPT="${PROJECT_ROOT}/fimtyper/fimtyper.pl"

# ResFinder databases — ResFinder itself reads these as environment variables.
export CGE_RESFINDER_RESGENE_DB="${PROJECT_ROOT}/Resfinder/resfinder/resfinder_db"
export CGE_RESFINDER_RESPOINT_DB="${PROJECT_ROOT}/Resfinder/resfinder/pointfinder_db"
export CGE_DISINFINDER_DB="${PROJECT_ROOT}/Resfinder/resfinder/disinfinder_db"

# ---- 5. Where results and logs get written ----------------------------------
# Every stage writes to its own subfolder of OUTPUT_DIR, and every result
# file is always named "<isolate>.tsv" — this consistent naming is what lets
# the post-processing scripts (07) work no matter which tool produced the
# file, without you needing to edit anything.
OUTPUT_DIR="${PROJECT_ROOT}/results"
LOG_DIR="${PROJECT_ROOT}/logs"

# ---- 6. How many CPU cores tools are allowed to use --------------------------
THREADS=4

# ---- 7. Do not edit below this line ------------------------------------------
# Creates the results/logs/isolates folders automatically if missing.
mkdir -p "$OUTPUT_DIR" "$LOG_DIR" "$ISOLATE_DIR"
