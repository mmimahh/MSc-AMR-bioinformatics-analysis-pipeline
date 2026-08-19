#!/usr/bin/env bash
# ============================================================
# 01_qc.sh
# ------------------------------------------------------------
# WHAT THIS DOES:
#   Confirms species identity by comparing your sequencing
#   reads against a reference database (bactinspector), then
#   downloads the best-matching reference genome so later
#   steps (like Prokka annotation in 06_phylo.sh) have a
#   reference to work against.
#
#   This is usually run ONCE PER SPECIES, not once per isolate
#   — it answers "am I really looking at E. coli?", not "which
#   E. coli isolate is this?".
#
# HOW TO RUN:
#   bash scripts/01_qc.sh
# ============================================================
set -euo pipefail
source "$(dirname "$0")/../config.sh"

QC_OUT="${OUTPUT_DIR}/01_qc"
mkdir -p "$QC_OUT"
cd "$QC_OUT"

echo "Running species check against E. coli reads..."
bactinspector closest_match -i "$ECOLI_FASTQ_DIR" -fq "*.fastq.gz" \
    2>> "${LOG_DIR}/01_qc.err"

echo "Downloading the closest-matching reference genome..."
ftp_path=$(sed -n '2p' closest_matches_*.tsv | grep -o 'ftp://.*\.gz')
if [ -z "$ftp_path" ]; then
    echo "  !! Couldn't find a download link in the closest_matches file — check ${QC_OUT}"
    exit 1
fi
wget "$ftp_path"
gunzip ./*.gz

# Rename whatever file was downloaded to a predictable, easy-to-find name,
# so every later script can refer to it without knowing the NCBI accession.
downloaded_file=$(ls ./*.fna | head -n 1)
mv "$downloaded_file" "${QC_OUT}/Ecoli_reference_genome.fna"

echo "Done. Reference genome saved to: ${QC_OUT}/Ecoli_reference_genome.fna"
