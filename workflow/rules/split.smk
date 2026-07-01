rule split_reads_pe:
    input:
        get_copy_inputs,
    output:
        expand("split/{{sample}}_1.part_{c}.fastq.gz", c=CHUNKS),
        expand("split/{{sample}}_2.part_{c}.fastq.gz", c=CHUNKS),
    threads: 1
    params:
        n_chunks=config["chunks"],
    conda:
        "../envs/seqkit.yaml"
    shell:
        """
        mkdir -p split
        seqkit split2 -p {params.n_chunks} -O split -1 {input[0]} -2 {input[1]}
        stem1=$(basename {input[0]} .fastq.gz)
        stem2=$(basename {input[1]} .fastq.gz)
        for f in split/${{stem1}}.part_*.fastq.gz; do
            suffix=${{f#split/${{stem1}}.}}
            mv "$f" "split/{wildcards.sample}_1.${{suffix}}"
        done
        for f in split/${{stem2}}.part_*.fastq.gz; do
            suffix=${{f#split/${{stem2}}.}}
            mv "$f" "split/{wildcards.sample}_2.${{suffix}}"
        done
        """


rule split_reads_se:
    input:
        get_copy_inputs,
    output:
        expand("split/{{sample}}.part_{c}.fastq.gz", c=CHUNKS),
    threads: 1
    params:
        n_chunks=config["chunks"],
    conda:
        "../envs/seqkit.yaml"
    shell:
        """
        mkdir -p split
        seqkit split2 -p {params.n_chunks} -O split {input[0]}
        stem=$(basename {input[0]} .fastq.gz)
        for f in split/${{stem}}.part_*.fastq.gz; do
            suffix=${{f#split/${{stem}}.}}
            mv "$f" "split/{wildcards.sample}.${{suffix}}"
        done
        """
