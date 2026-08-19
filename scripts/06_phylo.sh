#!/usr/bin/env bash
# ============================================================
# 06_phylo.sh
# ------------------------------------------------------------
# WHAT THIS DOES (three steps, in order):
#   1. Annotates every genome with Prokka — this produces the
#      .gff files that Roary needs in step 2.
#   2. Builds a pan-genome alignment across all isolates (Roary).
#   3. Builds a phylogenetic tree from that alignment (FastTree).
#
# THE FINAL OUTPUT:
#   results/06_phylo/core_genome_tree.newick
#   Upload this .newick file to https://itol.embl.de to view
#   and style the tree in your browser — no software install
#   needed for that step.
#
# HOW TO RUN:
#   bash scripts/06_phylo.sh
#
# NOTE:
#   This step can take a while (Prokka + Roary on many genomes
#   is the slowest part of the whole pipeline) — that's normal.
# ============================================================
set -euo pipefail
source "$(dirname "$0")/../config.sh"

OUT="${OUTPUT_DIR}/06_phylo"
LOGS="${LOG_DIR}/06_phylo"
GFF_DIR="${OUT}/gff"
mkdir -p "$GFF_DIR" "$LOGS"

echo "== Step 1: Annotating genomes with Prokka =="
while read -r x; do
    echo "  Annotating $x ..."
    if prokka --outdir "${OUT}/prokka/${x}" \
           --prefix "$x" \
           --cpus "$THREADS" \
           --genus Escherichia \
           --usegenus \
           "${ECOLI_FASTA_DIR}/${x}.fasta" \
           2>> "$LOGS/${x}_prokka.err"; then
        cp "${OUT}/prokka/${x}/${x}.gff" "$GFF_DIR/"
    else
        echo "    !! Failed on $x — see $LOGS/${x}_prokka.err"
    fi
done < "$ECOLI_LIST"

echo "== Step 2: Building pan-genome alignment with Roary =="
roary -e -n -v -p "$THREADS" -f "${OUT}/roary_output" "$GFF_DIR"/*.gff \
    2>> "$LOGS/roary.err"

echo "== Step 3: Building phylogenetic tree with FastTree =="
FastTree -nt "${OUT}/roary_output/core_gene_alignment.aln" > "${OUT}/core_genome_tree.newick" \
    2>> "$LOGS/fasttree.err"

echo "Done. Tree file: ${OUT}/core_genome_tree.newick"
echo "Upload it to https://itol.embl.de to view it."
