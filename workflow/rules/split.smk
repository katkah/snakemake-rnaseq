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
        """
