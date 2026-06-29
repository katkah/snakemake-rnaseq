rule fastp_pe:
    input:
        r1=f"{config['output_dir']}/sortmerna/{{sample}}_{{chunk}}_non_rRNA_fwd.fq.gz",
        r2=f"{config['output_dir']}/sortmerna/{{sample}}_{{chunk}}_non_rRNA_rev.fq.gz",
    output:
        trimmed_r1=f"{config['output_dir']}/fastp/{{sample}}_{{chunk}}_trimmed_R1.fastq.gz",
        trimmed_r2=f"{config['output_dir']}/fastp/{{sample}}_{{chunk}}_trimmed_R2.fastq.gz",
        html=f"{config['output_dir']}/fastp/{{sample}}_{{chunk}}_fastp.html",
        json=f"{config['output_dir']}/fastp/{{sample}}_{{chunk}}_fastp.json",
    log:
        f"{config['logs_dir']}/fastp/{{sample}}_{{chunk}}.log",
    shadow:
        "minimal"
    threads: config["fastp"]["threads"]
    resources:
        mem_gb=config["fastp"]["mem_gb"],
    params:
        outdir=f"{config['output_dir']}/fastp",
        extra=f"{config['fastp']['base_params']} {config['fastp']['paired_params']}",
    conda:
        "../envs/fastp.yaml"
    shell:
        """
        mkdir -p {params.outdir}
        fastp \
            -i {input.r1} \
            -I {input.r2} \
            -o {output.trimmed_r1} \
            -O {output.trimmed_r2} \
            -h {output.html} \
            -j {output.json} \
            -w {threads} \
            {params.extra} 2> {log}
        """


rule fastp_se:
    input:
        f"{config['output_dir']}/sortmerna/{{sample}}_{{chunk}}_non_rRNA.fq.gz",
    output:
        trimmed=f"{config['output_dir']}/fastp/{{sample}}_{{chunk}}_trimmed.fastq.gz",
        html=f"{config['output_dir']}/fastp/{{sample}}_{{chunk}}_fastp.html",
        json=f"{config['output_dir']}/fastp/{{sample}}_{{chunk}}_fastp.json",
    log:
        f"{config['logs_dir']}/fastp/{{sample}}_{{chunk}}.log",
    shadow:
        "minimal"
    threads: config["fastp"]["threads"]
    resources:
        mem_gb=config["fastp"]["mem_gb"],
    params:
        outdir=f"{config['output_dir']}/fastp",
        extra=f"{config['fastp']['base_params']} {config['fastp']['single_params']}",
    conda:
        "../envs/fastp.yaml"
    shell:
        """
        mkdir -p {params.outdir}
        fastp \
            -i {input} \
            -o {output.trimmed} \
            -h {output.html} \
            -j {output.json} \
            -w {threads} \
            {params.extra} 2> {log}
        """
