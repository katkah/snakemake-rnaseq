rule join_reads_pe:
    input:
        r1=expand(
            f"{config['output_dir']}/fastp/{{{{sample}}}}_{{chunk}}_trimmed_R1.fastq.gz",
            chunk=CHUNKS,
        ),
        r2=expand(
            f"{config['output_dir']}/fastp/{{{{sample}}}}_{{chunk}}_trimmed_R2.fastq.gz",
            chunk=CHUNKS,
        ),
    output:
        r1=f"{config['output_dir']}/joined/{{sample}}_trimmed_R1.fastq.gz",
        r2=f"{config['output_dir']}/joined/{{sample}}_trimmed_R2.fastq.gz",
    log:
        f"{config['logs_dir']}/joined/{{sample}}.log",
    threads: 1
    shell:
        """
        mkdir -p {config[output_dir]}/joined
        mkdir -p {config[logs_dir]}/joined
        echo "joining R1 chunks for {wildcards.sample}" > {log}
        cat {input.r1} > {output.r1} 2>> {log}
        echo "joining R2 chunks for {wildcards.sample}" >> {log}
        cat {input.r2} > {output.r2} 2>> {log}
        """


rule join_reads_se:
    input:
        expand(
            f"{config['output_dir']}/fastp/{{{{sample}}}}_{{chunk}}_trimmed.fastq.gz",
            chunk=CHUNKS,
        ),
    output:
        f"{config['output_dir']}/joined/{{sample}}_trimmed.fastq.gz",
    log:
        f"{config['logs_dir']}/joined/{{sample}}.log",
    threads: 1
    shell:
        """
        mkdir -p {config[output_dir]}/joined
        mkdir -p {config[logs_dir]}/joined
        echo "joining chunks for {wildcards.sample}" > {log}
        cat {input} > {output} 2>> {log}
        """
