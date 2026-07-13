# snakemake-rnaseq

[![Pipeline dry-run CI](https://github.com/katkah/snakemake-rnaseq/actions/workflows/test.yml/badge.svg)](https://github.com/katkah/snakemake-rnaseq/actions/workflows/test.yml)

A Snakemake pipeline for RNA-seq read processing and expression quantification. Supports both paired-end and single-end data, with rRNA depletion, quality trimming, STAR alignment, and dual quantification via RSEM and Salmon.

## Features

- **Paired-end and single-end support** — auto-detected from the sample sheet
- **rRNA depletion** — SortMeRNA with parallelised chunked processing
- **Quality trimming** — fastp with configurable parameters
- **Alignment** — STAR with transcriptome BAM for downstream quantification
- **Quantification** — RSEM (gene and isoform counts, TPM) + Salmon (bootstrap uncertainty estimates)
- **QC** — FastQC on raw and trimmed reads, MultiQC summary report
- **Index building** — optional STAR and RSEM index construction from genome FASTA and GTF
- **CI dry-run** — GitHub Actions tests the full DAG on every push

## Requirements

### Conda (one-time setup)

**[Miniforge](https://github.com/conda-forge/miniforge) is strongly recommended** over Miniconda or Anaconda.

```bash
# Install Miniforge (Linux x86-64)
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh
```

If you already have Miniconda/Anaconda:

```bash
conda install -n base conda-libmamba-solver
conda config --set solver libmamba
conda config --set channel_priority flexible
```

### Snakemake

```bash
conda create -n snakemake -c bioconda -c conda-forge "snakemake>=9" pandas
conda activate snakemake
```

All tool dependencies (STAR, RSEM, Salmon, fastp, SortMeRNA, FastQC, MultiQC, seqkit) are installed **automatically** by Snakemake into isolated conda environments on first run.

## Quick start

```bash
# 1. Clone the repository
git clone https://github.com/katkah/snakemake-rnaseq.git
cd snakemake-rnaseq

# 2. Create your config files from the templates
cp config/config.yaml.template config/config.yaml
cp config/samples.tsv.example  config/samples.tsv

# 3. Edit config/config.yaml — set your paths and parameters
# Edit config/samples.tsv    — add your sample names and FASTQ paths

# 4. Download the SortMeRNA rRNA database (one-time, see below)

# 5. Run
snakemake --snakefile workflow/Snakefile \
          --use-conda \
          --cores 32
```

## Reference data

### SortMeRNA rRNA database

The SortMeRNA database is not bundled with the conda package and must be downloaded once:

```bash
mkdir -p ~/rnaseq_data/sortmerna
cd ~/rnaseq_data/sortmerna
wget https://github.com/biocore/sortmerna/releases/download/v4.3.4/database.tar.gz
tar -xzf database.tar.gz
```

Set the path in `config/config.yaml`:

```yaml
sortmerna:
  database: "/home/user/rnaseq_data/sortmerna/smr_v4.3_default_db.fasta"
```

### Genome indices (STAR and RSEM)

The pipeline can either **build indices from scratch** or **reuse existing ones**:

- **Build from scratch**: point `star_index` and `rsem_index` to new empty directories. The pipeline will create them and build the indices automatically using `genome_fasta` and `gtf`.
- **Reuse existing**: point to directories that already contain the index files. The pipeline checks for marker files (`genomeParameters.txt` for STAR, `{rsem_index_name}.seq` for RSEM) and skips building if they are present.

```yaml
reference:
  genome_fasta: "/path/to/genome.fa.gz"   # only needed when building indices
  gtf: "/path/to/annotation.gtf"
  star_index: "/path/to/star_index/"      # new dir = build; existing dir = reuse
  rsem_index: "/path/to/rsem_index/"
  rsem_index_name: "species_name"
```

## Configuration

### `config/config.yaml`

| Key | Description |
|---|---|
| `samples` | Path to sample sheet |
| `chunks` | Number of chunks to split reads into for parallel rRNA depletion |
| `reference.genome_fasta` | Genome FASTA (gzipped supported); required only when building indices |
| `reference.gtf` | GTF annotation file |
| `reference.star_index` | STAR index directory |
| `reference.rsem_index` | RSEM index directory |
| `reference.rsem_index_name` | Base name of RSEM index files (without extension) |
| `sortmerna.database` | Path to `smr_v4.3_default_db.fasta` |
| `rsem.strandedness` | Library strandedness: `none`, `forward`, or `reverse` |
| `salmon.lib_type` | Salmon library type; `A` = auto-detect from BAM (recommended) |
| `salmon.bootstraps` | Number of bootstrap replicates for uncertainty estimation |

See `config/config.yaml.template` for all options including per-tool thread and memory settings.

### `config/samples.tsv`

Tab-separated. Use `fq2` for paired-end; omit or leave empty for single-end. All samples in one file must be the same type.

```
sample    fq1                          fq2
sample1   /data/raw/sample1_R1.fastq.gz   /data/raw/sample1_R2.fastq.gz
sample2   /data/raw/sample2_R1.fastq.gz   /data/raw/sample2_R2.fastq.gz
```

## Outputs

```
results/
├── fastqc/                          # FastQC reports on raw reads
├── fastqc_trimmed/                  # FastQC reports on trimmed reads
├── multiqc/multiqc_report.html      # aggregated QC report
├── star/{sample}/
│   ├── {sample}Aligned.sortedByCoord.out.bam      # genome BAM
│   ├── {sample}Aligned.toTranscriptome.out.bam    # transcriptome BAM
│   └── {sample}ReadsPerGene.out.tab               # raw gene counts
├── rsem/
│   ├── {sample}.genes.results       # gene-level TPM and counts
│   └── {sample}.isoforms.results    # isoform-level TPM and counts
└── salmon/{sample}/
    ├── quant.sf                     # transcript-level quantification
    └── quant.genes.sf               # gene-level quantification
```

### Downstream analysis

The pipeline ends at quantification — differential expression is out of scope and left to you. These outputs are ready-made inputs for the usual tools: STAR gene counts (`ReadsPerGene.out.tab`) load directly into DESeq2 or edgeR, and Salmon's bootstrap replicates support uncertainty-aware DE via `tximport` + `fishpond`. No downstream scripts are bundled.

## Known limitations

**RSEM `--calc-ci`** is disabled. RSEM 1.3.3 has a known bug with confidence interval computation (GitHub issue [#134](https://github.com/deweylab/RSEM/issues/134), open since 2020). Salmon bootstraps provide an alternative uncertainty estimate.

## Running on HPC (PBS/Torque)

A ready-to-use PBS batch script is provided as `run_metacentrum.sh.template`. Copy it, fill in your paths, and submit:

```bash
cp run_metacentrum.sh.template run_metacentrum.sh
# Edit run_metacentrum.sh — set your storage paths
qsub run_metacentrum.sh
```

### One-time environment setup (MetaCentrum)

Run inside an interactive job — do not install on the frontend:

```bash
qsub -I -l select=1:ncpus=2:mem=8gb -l walltime=2:00:00

STORAGE="/storage/SITE/home/$USER"
export CONDA_PKGS_DIRS="$STORAGE/tools/.conda/pkgs"
mkdir -p "$CONDA_PKGS_DIRS"

module add mambaforge

mamba create --prefix "$STORAGE/my_envs/snakemake" \
    -c bioconda -c conda-forge \
    "snakemake-minimal>=9" pandas conda mamba

chmod -R u+rwX "$STORAGE/my_envs/snakemake"
"$STORAGE/my_envs/snakemake/bin/conda" config --set channel_priority flexible
```

## License

Released under the [MIT License](LICENSE).
