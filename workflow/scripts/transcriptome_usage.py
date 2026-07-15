"""Report what fraction of the input reads actually reached transcriptome quantification.

Neither Salmon nor RSEM can answer this on their own: both run in alignment mode on
STAR's transcriptome BAM, so they only ever see reads STAR already projected onto
transcripts — their own "mapped %" is ~100% by construction. The honest number is
the count of quantified fragments divided by the total reads that entered STAR.

Numerator:   RSEM .stat/.cnt, line 1 is "N0 N1 N2 N_tot" (N_tot = fragments RSEM read
             from the transcriptome BAM).
Denominator: STAR Log.final.out, "Number of input reads".

Emits a MultiQC custom-content table (the *_mqc.tsv suffix is what MultiQC scans for).
"""

samples = snakemake.params.samples
star_logs = snakemake.input.star
cnt_files = snakemake.input.cnt

rows = []
for sample, star_log, cnt_file in zip(samples, star_logs, cnt_files):
    total = None
    with open(star_log) as fh:
        for line in fh:
            if "Number of input reads" in line:
                total = int(line.split("|")[1].strip())
                break
    if total is None:
        raise ValueError(f"'Number of input reads' not found in {star_log}")

    with open(cnt_file) as fh:
        fields = fh.readline().split()
    if len(fields) < 4:
        raise ValueError(f"Unexpected RSEM .cnt first line in {cnt_file}: {fields}")
    quantified = int(fields[3])

    pct = round(100.0 * quantified / total, 2) if total else 0.0
    rows.append((sample, total, quantified, pct))

with open(snakemake.output[0], "w") as out:
    out.write("# id: 'transcriptome_usage'\n")
    out.write("# section_name: 'Transcriptome usage'\n")
    out.write(
        "# description: 'Fraction of input reads that reached transcriptome "
        "quantification. Reads mapping to introns, intergenic regions or "
        "unannotated genes align to the genome but never enter the transcriptome "
        "BAM, so this is well below the STAR genome mapping rate. NOTE: the "
        "mapped/aligned % reported by Salmon and RSEM is ~100% by construction "
        "(they only see reads STAR already projected onto transcripts) and is NOT "
        "comparable to STAR genome mapping — this metric is.'\n"
    )
    out.write("# plot_type: 'table'\n")
    out.write("# pconfig:\n")
    out.write("#     id: 'transcriptome_usage_table'\n")
    out.write("Sample\tInput reads\tQuantified fragments\tTranscriptome usage %\n")
    for row in rows:
        out.write("\t".join(str(value) for value in row) + "\n")
