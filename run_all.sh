#!/usr/bin/env bash
# ============================================================
# run_all.sh
# ------------------------------------------------------------
# WHAT THIS DOES:
#   Runs the entire pipeline, start to finish, in the correct
#   order. This is the ONLY command you need once config.sh is
#   filled in correctly.
#
# HOW TO RUN:
#   bash run_all.sh
#
# WHAT IF SOMETHING FAILS PARTWAY THROUGH?
#   Every stage script can also be run on its own, e.g.:
#     bash scripts/03_amr.sh
#   so you don't have to restart from the very beginning —
#   just run the remaining stage scripts individually, in order.
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

echo "############################################"
echo "# STARTING FULL PIPELINE"
echo "############################################"

bash scripts/00_make_isolate_lists.sh
bash scripts/01_qc.sh
bash scripts/02_typing.sh
bash scripts/03_amr.sh
bash scripts/04_virulence.sh
bash scripts/05_plasmid.sh
bash scripts/06_phylo.sh
bash scripts/07_postprocess.sh

echo "############################################"
echo "# PIPELINE COMPLETE"
echo "# Results are in: results/"
echo "# Logs are in:    logs/   (check here if any step said 'Failed')"
echo "############################################"
