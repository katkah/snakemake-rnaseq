rule sortmerna_pe:
    input:
        r1=f"{config['output_dir']}/split/{{sample}}_1.part_{{chunk}}.fastq.gz",
        r2=f"{config['output_dir']}/split/{{sample}}_2.part_{{chunk}}.fastq.gz",
    output:
        temp(f"{config['output_dir']}/sortmerna/{{sample}}_{{chunk}}_non_rRNA_fwd.fq.gz"),
        temp(f"{config['output_dir']}/sortmerna/{{sample}}_{{chunk}}_non_rRNA_rev.fq.gz"),
        stats=f"{config['output_dir']}/sortmerna/{{sample}}_{{chunk}}_rRNA.log",
    log:
        f"{config['logs_dir']}/sortmerna/{{sample}}_{{chunk}}.log",
    shadow:
        "minimal"
    threads: config["sortmerna"]["threads"]
    resources:
        mem_gb=config["sortmerna"]["mem_gb"],
    params:
        database=config["sortmerna"]["database"],
        prefix="{sample}_{chunk}",
        extra=config["sortmerna"]["extra_params"],
    conda:
        "../envs/sortmerna.yaml"
    shell:
        """
        mkdir -p {config[output_dir]}/sortmerna
        cp {params.database} .
        database_name=$(basename {params.database})

        sortmerna --ref $database_name \
                  --reads {input.r1} \
                  --reads {input.r2} \
                  --workdir . \
                  --fastx --paired_out --out2 \
                  --aligned rRNA-reads \
                  --other {params.prefix}_non_rRNA \
                  --threads {threads} \
                  {params.extra} \
                  2> {log}

        mv {params.prefix}_non_rRNA_fwd.fq.gz {config[output_dir]}/sortmerna/
        mv {params.prefix}_non_rRNA_rev.fq.gz {config[output_dir]}/sortmerna/
        mv rRNA-reads.log {output.stats}
        """


rule sortmerna_se:
    input:
        f"{config['output_dir']}/split/{{sample}}.part_{{chunk}}.fastq.gz",
    output:
        temp(f"{config['output_dir']}/sortmerna/{{sample}}_{{chunk}}_non_rRNA.fq.gz"),
        stats=f"{config['output_dir']}/sortmerna/{{sample}}_{{chunk}}_rRNA.log",
    log:
        f"{config['logs_dir']}/sortmerna/{{sample}}_{{chunk}}.log",
    shadow:
        "minimal"
    threads: config["sortmerna"]["threads"]
    resources:
        mem_gb=config["sortmerna"]["mem_gb"],
    params:
        database=config["sortmerna"]["database"],
        prefix="{sample}_{chunk}",
        extra=config["sortmerna"]["extra_params"],
    conda:
        "../envs/sortmerna.yaml"
    shell:
        """
        mkdir -p {config[output_dir]}/sortmerna
        cp {params.database} .
        database_name=$(basename {params.database})

        sortmerna --ref $database_name \
                  --reads {input} \
                  --workdir . \
                  --fastx \
                  --aligned rRNA-reads \
                  --other {params.prefix}_non_rRNA \
                  --threads {threads} \
                  {params.extra} \
                  2> {log}

        mv {params.prefix}_non_rRNA.fq.gz {config[output_dir]}/sortmerna/
        mv rRNA-reads.log {output.stats}
        """
