# ============================================================
# run_pathotyper.R
# ------------------------------------------------------------
# WHAT THIS DOES:
#   Runs pathotypeR on a folder of E. coli genome files to
#   predict pathotype, and saves the result as both .csv and
#   .tsv.
#
# NOTE:
#   For retrospective/older E. coli sequences, pathotypeR may
#   report phylogroups instead of pathotypes — that's expected
#   behavior of the tool, not an error in this script.
#
# HOW THIS IS RUN:
#   Called automatically by 07_postprocess.sh. To run by hand:
#     Rscript run_pathotyper.R <input_folder> <output_folder>
# ============================================================
suppressMessages(library(pathotypeR))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
    stop("Usage: Rscript run_pathotyper.R <input_folder> <output_folder>")
}
indir  <- args[1]
outdir <- args[2]

results <- pathotypeR(indir, output = "patho_pred")

write.csv(results, file.path(outdir, "pathotype_results.csv"), row.names = FALSE)
write.table(results, file.path(outdir, "pathotype_results.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)

message("pathotypeR results saved to ", outdir)
