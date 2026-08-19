# AMR / WGS Genomic Analysis Pipeline

This folder runs a full bacterial whole-genome-sequencing (WGS) AMR analysis
pipeline, start to finish, with one command. It was built from a set of
one-off terminal commands and turned into scripts anyone — including
someone with **no prior bioinformatics or coding experience** — can read
and run.

You don't need to understand or edit any script except `config.sh`.

---

## What's in this folder

```
config.sh                        <- the ONLY file you edit
run_all.sh                       <- runs the whole pipeline in one go
scripts/
  00_make_isolate_lists.sh       <- lists your isolates from your FASTA files
  01_qc.sh                       <- confirms species identity
  02_typing.sh                   <- MLST, Kleborate, FimTyper
  03_amr.sh                      <- AMRFinderPlus, ResFinder
  04_virulence.sh                <- VirulenceFinder
  05_plasmid.sh                  <- PlasmidFinder
  06_phylo.sh                    <- Prokka -> Roary -> FastTree (tree building)
  07_postprocess.sh              <- combines/cleans up all the results
  rename_amrfinder_columns.R     <- helper R script (called automatically)
  run_pathotyper.R               <- helper R script (called automatically)
isolates/                        <- auto-generated isolate lists go here
results/                         <- every stage's output goes here
logs/                            <- error logs go here if something fails
```

---

## Before you start: things that must already be installed

This pipeline *runs* your analysis tools — it doesn't install them. Make
sure these are already installed and working on your computer:

- Docker (for ResFinder and PlasmidFinder)
- AMRFinderPlus, MLST, Kleborate, FimTyper, Prokka, Roary, FastTree, bactinspector
- VirulenceFinder (Python) — with its own virtual environment
- R, with the `dplyr` and `pathotypeR` packages installed

If you're not sure whether something is installed, open a terminal and type
its name (e.g. `prokka --version`). If you see `command not found`, it
isn't installed yet — install it (or ask whoever set up your project
environment) before running that stage.

---

## One-time setup

1. **Open a terminal** and navigate into this folder:
   ```bash
   cd path/to/pipeline-scripts
   ```

2. **Make the scripts runnable** (only needs to be done once):
   ```bash
   chmod +x run_all.sh scripts/*.sh
   ```

3. **Edit `config.sh`** — open it in any text editor:
   ```bash
   nano config.sh
   ```
   Change `PROJECT_ROOT` and the other paths near the top to match where
   your files actually live on your computer. Save and close
   (`nano`: press `Ctrl+O` then `Enter` to save, `Ctrl+X` to exit).

---

## Running the pipeline

**To run everything, start to finish:**
```bash
bash run_all.sh
```

**To run just one stage** (useful if a later stage failed and you don't
want to redo everything before it):
```bash
bash scripts/03_amr.sh
```

While it runs, you'll see a line printed for each isolate as it's
processed, e.g. `Scanning G18653095 ...`, so you can see it's making
progress rather than looking stuck.

---

## What each stage actually runs

You never need to type any of this yourself — every command below already
runs automatically when you call the matching script (`bash
scripts/02_typing.sh`, etc.). It's here so you can see, and if you want
copy-paste and run by hand, exactly what happens at each stage — useful
for a thesis methods section, or for troubleshooting.

**Stage 00 — Build isolate lists** (`scripts/00_make_isolate_lists.sh`)
```bash
ls "$ECOLI_FASTA_DIR"/*.fasta | xargs -n 1 basename | sed 's/\.fasta$//' > "$ECOLI_LIST"
ls "$KLEB_FASTA_DIR"/*.fasta  | xargs -n 1 basename | sed 's/\.fasta$//' > "$KLEB_LIST"
```

**Stage 01 — Species QC** (`scripts/01_qc.sh`) — run once per species, not per isolate
```bash
bactinspector closest_match -i "$ECOLI_FASTQ_DIR" -fq "*.fastq.gz"

# Download and unzip the closest-matching reference genome
ftp_path=$(sed -n '2p' closest_matches_*.tsv | grep -o 'ftp://.*\.gz')
wget "$ftp_path"
gunzip ./*.gz
mv *.fna Ecoli_reference_genome.fna
```

**Stage 02 — Sequence typing** (`scripts/02_typing.sh`)
```bash
# MLST + Kleborate, for every Klebsiella isolate
while read -r x; do
    mlst -scheme klebsiella "${KLEB_FASTA_DIR}/${x}.fasta" >> "results/02_typing/mlst/${x}.tsv"
    kleborate -a "${KLEB_FASTA_DIR}/${x}.fasta" -o "results/02_typing/kleborate/${x}.tsv" -p kpsc --trim_headers
done < "$KLEB_LIST"

# FimTyper, for every E. coli isolate
while read -r x; do
    perl "$FIMTYPER_SCRIPT" -d "$FIMTYPER_DB" -b "$FIMTYPER_BLAST" \
         -i "${ECOLI_FASTA_DIR}/${x}.fasta" -o "results/02_typing/fimtyper/${x}" -k 95.00 -l 0.60
done < "$ECOLI_LIST"
```

**Stage 03 — AMR gene detection** (`scripts/03_amr.sh`)
```bash
# AMRFinderPlus, for every E. coli isolate
while read -r x; do
    amrfinder -n "${ECOLI_FASTA_DIR}/${x}.fasta" --plus -O Escherichia -o "results/03_amr/amrfinder/${x}.tsv"
done < "$ECOLI_LIST"

# ResFinder, for every Klebsiella isolate — acquired resistance genes + point mutations
while read -r x; do
    docker run --rm -v "${PROJECT_ROOT}:/app" genomicepidemiology/resfinder \
        -ifa "/app/species_fastas/klebsiella_pneumoniae/${x}.fasta" \
        -o "/app/results/03_amr/resfinder/${x}" -s klebsiella --acquired --point
done < "$KLEB_LIST"
```

**Stage 04 — Virulence gene detection** (`scripts/04_virulence.sh`)
```bash
while read -r x; do
    python3 "$VIRULENCEFINDER_SCRIPT" \
        -i "${ECOLI_FASTA_DIR}/${x}.fasta" -o "results/04_virulence/${x}.tsv" -d "$VIRULENCEFINDER_DB"
done < "$ECOLI_LIST"
```

**Stage 05 — Plasmid detection** (`scripts/05_plasmid.sh`)
```bash
while read -r x; do
    docker run --rm -v "$PLASMID_DB:/database" -v "${PROJECT_ROOT}:/workdir" plasmidfinder \
        -i "/workdir/species_fastas/escherichia_coli/${x}.fasta" -o "/workdir/results/05_plasmid/${x}"
done < "$ECOLI_LIST"
```

**Stage 06 — Annotation, pan-genome, tree** (`scripts/06_phylo.sh`) — three steps in order
```bash
# 1. Annotate every genome (Prokka) and collect the .gff files it produces
while read -r x; do
    prokka --outdir "results/06_phylo/prokka/${x}" --prefix "$x" --cpus "$THREADS" \
           --genus Escherichia --usegenus "${ECOLI_FASTA_DIR}/${x}.fasta"
    cp "results/06_phylo/prokka/${x}/${x}.gff" "results/06_phylo/gff/"
done < "$ECOLI_LIST"

# 2. Build the pan-genome alignment across all isolates (Roary)
roary -e -n -v -p "$THREADS" -f "results/06_phylo/roary_output" results/06_phylo/gff/*.gff

# 3. Build the phylogenetic tree from that alignment (FastTree)
FastTree -nt "results/06_phylo/roary_output/core_gene_alignment.aln" > "results/06_phylo/core_genome_tree.newick"
```

**Stage 07 — Post-processing** (`scripts/07_postprocess.sh`) — five steps in order
```bash
# 1. Standardize AMRFinder column names so files can be safely combined
Rscript scripts/rename_amrfinder_columns.R "results/03_amr/amrfinder"

# 2. Combine every isolate's AMRFinder result into one file
awk 'FNR==1 && NR!=1 {next} {print}' results/03_amr/amrfinder/*.tsv > "results/07_postprocess/combined_amr_results.tsv"

# 3. Convert that combined file to CSV
sed 's/\t/,/g' "results/07_postprocess/combined_amr_results.tsv" > "results/07_postprocess/combined_amr_results.csv"

# 4. Collect every Kleborate summary file into one folder
find "results/02_typing/kleborate" -type f -name "*.tsv" -exec cp {} "results/07_postprocess/kleborate_summaries/" \;

# 5. Predict E. coli pathotypes
Rscript scripts/run_pathotyper.R "$ECOLI_FASTA_DIR" "results/07_postprocess"
```

---

## Where to find your results

Everything lands in `results/`, organized by stage:
```
results/02_typing/kleborate/G18653095.tsv
results/03_amr/amrfinder/G18653095.tsv
results/06_phylo/core_genome_tree.newick
results/07_postprocess/combined_amr_results.csv
```

The final combined AMR table and the phylogenetic tree file are the two
outputs you'll likely use most in your write-up.

To view the tree, upload `core_genome_tree.newick` to
[itol.embl.de](https://itol.embl.de) — no software install needed.

---

## If something goes wrong

Every stage writes error details to `logs/`, and the script will tell you
which file to check, e.g.:
```
!! Failed on G18653095 — see logs/03_amr/G18653095_amrfinder.err
```
Open that file in a text editor to see the actual error message from the
tool. Common causes:

- **"command not found"** — the tool isn't installed, or isn't on your PATH
- **"No such file or directory"** — a path in `config.sh` is wrong, or you
  haven't run `00_make_isolate_lists.sh` yet
- **"Permission denied"** — run `chmod +x scripts/*.sh` again
- **Docker steps failing** — make sure Docker Desktop (or the Docker
  service) is actually running before you start

---

## Putting this under version control (Git)

Doing this once at the start means every change you make from here on is
tracked — useful for a thesis methods section, and for undoing mistakes.

```bash
git init
git add .
git commit -m "Initial pipeline scripts"
```

The included `.gitignore` already excludes `results/`, `logs/`, and raw
genome files (`.fasta`, `.fastq.gz`, `.fna`) so you never accidentally
commit large files or clinical isolate data to GitHub.

---

## Optional next step: Snakemake

Once you're comfortable with this version, the natural next step is a
workflow manager like **Snakemake**. It would let the pipeline
automatically figure out which stages need re-running when you add a new
isolate, run independent stages in parallel, and produce a diagram of the
whole workflow — but it has its own learning curve, so it's worth doing
only once `run_all.sh` feels comfortable and familiar.
