# ============================================================
# rename_amrfinder_columns.R
# ------------------------------------------------------------
# WHAT THIS DOES:
#   Standardizes column names across AMRFinder .tsv files so
#   they can all be safely combined into one file later:
#     "Type"         -> "Element type"
#     "Gene.symbol"  -> "Gene symbol"
#     "Element.type" -> "Element type"
#
# HOW THIS IS RUN:
#   Called automatically by 07_postprocess.sh — you don't need
#   to run this by hand. If you ever want to run it yourself:
#     Rscript rename_amrfinder_columns.R /path/to/amrfinder_results
# ============================================================
suppressMessages(library(dplyr))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
    stop("Usage: Rscript rename_amrfinder_columns.R <folder_of_tsv_files>")
}
indir <- args[1]

files <- list.files(indir, pattern = "\\.tsv$", full.names = TRUE)
if (length(files) == 0) {
    stop(paste("No .tsv files found in", indir))
}

process_file <- function(file) {
    data <- read.delim(file, stringsAsFactors = FALSE)

    if ("Type" %in% colnames(data)) {
        data <- data %>% rename(`Element type` = `Type`)
    }
    if ("Gene.symbol" %in% colnames(data)) {
        data <- data %>% rename(`Gene symbol` = `Gene.symbol`)
    }
    if ("Element.type" %in% colnames(data)) {
        data <- data %>% rename(`Element type` = `Element.type`)
    }

    write.table(data, file, sep = "\t", row.names = FALSE, quote = FALSE)
    message(paste("Processed:", basename(file)))
}

invisible(lapply(files, process_file))
message("All files standardized.")
