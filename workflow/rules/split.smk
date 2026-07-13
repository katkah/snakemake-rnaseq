rule split_reads_pe:
    input:
        get_copy_inputs,
    output:
        temp(expand(f"{config['output_dir']}/split/{{{{sample}}}}_1.part_{{c}}.fastq.gz", c=CHUNKS)),
        temp(expand(f"{config['output_dir']}/split/{{{{sample}}}}_2.part_{{c}}.fastq.gz", c=CHUNKS)),
    threads: 1
    params:
        n_chunks=config["chunks"],
        splitdir=f"{config['output_dir']}/split",
    conda:
        "../envs/seqkit.yaml"
    shell:
        """
        mkdir -p {params.splitdir}
        seqkit split2 -p {params.n_chunks} -O {params.splitdir} -1 {input[0]} -2 {input[1]}
        stem1=$(basename {input[0]} .fastq.gz)
        stem2=$(basename {input[1]} .fastq.gz)
        for f in {params.splitdir}/${{stem1}}.part_*.fastq.gz; do
            suffix=${{f#{params.splitdir}/${{stem1}}.}}
            target="{params.splitdir}/{wildcards.sample}_1.${{suffix}}"
            if [ "$f" != "$target" ]; then mv "$f" "$target"; fi
        done
        for f in {params.splitdir}/${{stem2}}.part_*.fastq.gz; do
            suffix=${{f#{params.splitdir}/${{stem2}}.}}
            target="{params.splitdir}/{wildcards.sample}_2.${{suffix}}"
            if [ "$f" != "$target" ]; then mv "$f" "$target"; fi
        done
        """


rule split_reads_se:
    input:
        get_copy_inputs,
    output:
        temp(expand(f"{config['output_dir']}/split/{{{{sample}}}}.part_{{c}}.fastq.gz", c=CHUNKS)),
    threads: 1
    params:
        n_chunks=config["chunks"],
        splitdir=f"{config['output_dir']}/split",
    conda:
        "../envs/seqkit.yaml"
    shell:
        """
        mkdir -p {params.splitdir}
        seqkit split2 -p {params.n_chunks} -O {params.splitdir} {input[0]}
        stem=$(basename {input[0]} .fastq.gz)
        for f in {params.splitdir}/${{stem}}.part_*.fastq.gz; do
            suffix=${{f#{params.splitdir}/${{stem}}.}}
            target="{params.splitdir}/{wildcards.sample}.${{suffix}}"
            if [ "$f" != "$target" ]; then mv "$f" "$target"; fi
        done
        """
