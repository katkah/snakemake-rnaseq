rule fastqc_pe:
    input:
        get_copy_inputs,
    output:
        html=f"{config['output_dir']}/fastqc/{{sample}}_1_fastqc.html",
        zip=f"{config['output_dir']}/fastqc/{{sample}}_1_fastqc.zip",
        html2=f"{config['output_dir']}/fastqc/{{sample}}_2_fastqc.html",
        zip2=f"{config['output_dir']}/fastqc/{{sample}}_2_fastqc.zip",
    log:
        f"{config['logs_dir']}/fastqc/{{sample}}.log",
    threads: config["fastqc"]["threads"]
    resources:
        mem_gb=config["fastqc"]["mem_gb"],
    params:
        outdir=f"{config['output_dir']}/fastqc",
    conda:
        "../envs/fastqc.yaml"
    shell:
        """
        mkdir -p {params.outdir}
        fastqc -t {threads} -o {params.outdir} {input} 2> {log}
        stem1=$(basename {input[0]} .fastq.gz)
        stem2=$(basename {input[1]} .fastq.gz)
        if [ "{params.outdir}/${{stem1}}_fastqc.html" != "{output.html}" ]; then mv {params.outdir}/${{stem1}}_fastqc.html {output.html}; fi
        if [ "{params.outdir}/${{stem1}}_fastqc.zip" != "{output.zip}" ]; then mv {params.outdir}/${{stem1}}_fastqc.zip {output.zip}; fi
        if [ "{params.outdir}/${{stem2}}_fastqc.html" != "{output.html2}" ]; then mv {params.outdir}/${{stem2}}_fastqc.html {output.html2}; fi
        if [ "{params.outdir}/${{stem2}}_fastqc.zip" != "{output.zip2}" ]; then mv {params.outdir}/${{stem2}}_fastqc.zip {output.zip2}; fi
        """


rule fastqc_se:
    input:
        get_copy_inputs,
    output:
        html=f"{config['output_dir']}/fastqc/{{sample}}_fastqc.html",
        zip=f"{config['output_dir']}/fastqc/{{sample}}_fastqc.zip",
    log:
        f"{config['logs_dir']}/fastqc/{{sample}}.log",
    threads: config["fastqc"]["threads"]
    resources:
        mem_gb=config["fastqc"]["mem_gb"],
    params:
        outdir=f"{config['output_dir']}/fastqc",
    conda:
        "../envs/fastqc.yaml"
    shell:
        """
        mkdir -p {params.outdir}
        fastqc -t {threads} -o {params.outdir} {input} 2> {log}
        stem=$(basename {input[0]} .fastq.gz)
        if [ "{params.outdir}/${{stem}}_fastqc.html" != "{output.html}" ]; then mv {params.outdir}/${{stem}}_fastqc.html {output.html}; fi
        if [ "{params.outdir}/${{stem}}_fastqc.zip" != "{output.zip}" ]; then mv {params.outdir}/${{stem}}_fastqc.zip {output.zip}; fi
        """


rule fastqc_trimmed_pe:
    input:
        r1=f"{config['output_dir']}/joined/{{sample}}_trimmed_R1.fastq.gz",
        r2=f"{config['output_dir']}/joined/{{sample}}_trimmed_R2.fastq.gz",
    output:
        html=f"{config['output_dir']}/fastqc_trimmed/{{sample}}_trimmed_R1_fastqc.html",
        zip=f"{config['output_dir']}/fastqc_trimmed/{{sample}}_trimmed_R1_fastqc.zip",
        html2=f"{config['output_dir']}/fastqc_trimmed/{{sample}}_trimmed_R2_fastqc.html",
        zip2=f"{config['output_dir']}/fastqc_trimmed/{{sample}}_trimmed_R2_fastqc.zip",
    log:
        f"{config['logs_dir']}/fastqc_trimmed/{{sample}}.log",
    threads: config["fastqc"]["threads"]
    resources:
        mem_gb=config["fastqc"]["mem_gb"],
    params:
        outdir=f"{config['output_dir']}/fastqc_trimmed",
    conda:
        "../envs/fastqc.yaml"
    shell:
        """
        mkdir -p {params.outdir}
        fastqc -t {threads} -o {params.outdir} {input.r1} {input.r2} 2> {log}
        """


rule fastqc_trimmed_se:
    input:
        f"{config['output_dir']}/joined/{{sample}}_trimmed.fastq.gz",
    output:
        html=f"{config['output_dir']}/fastqc_trimmed/{{sample}}_trimmed_fastqc.html",
        zip=f"{config['output_dir']}/fastqc_trimmed/{{sample}}_trimmed_fastqc.zip",
    log:
        f"{config['logs_dir']}/fastqc_trimmed/{{sample}}.log",
    threads: config["fastqc"]["threads"]
    resources:
        mem_gb=config["fastqc"]["mem_gb"],
    params:
        outdir=f"{config['output_dir']}/fastqc_trimmed",
    conda:
        "../envs/fastqc.yaml"
    shell:
        """
        mkdir -p {params.outdir}
        fastqc -t {threads} -o {params.outdir} {input} 2> {log}
        """


rule multiqc:
    input:
        raw_fastqc=get_fastqc_zip_outputs,
        trimmed_fastqc=get_fastqc_trimmed_zip_outputs,
        fastp=expand(
            f"{config['output_dir']}/fastp/{{sample}}_{{chunk}}_fastp.json",
            sample=SAMPLES,
            chunk=CHUNKS,
        ),
        sortmerna=expand(
            f"{config['output_dir']}/sortmerna/{{sample}}_{{chunk}}_rRNA.log",
            sample=SAMPLES,
            chunk=CHUNKS,
        ),
        star=expand(
            f"{config['output_dir']}/star/{{sample}}/{{sample}}Log.final.out",
            sample=SAMPLES,
        ),
        rsem=expand(
            f"{config['output_dir']}/rsem/{{sample}}.genes.results",
            sample=SAMPLES,
        ),
        salmon=expand(
            f"{config['output_dir']}/salmon/{{sample}}/quant.sf",
            sample=SAMPLES,
        ),
    output:
        f"{config['output_dir']}/multiqc/multiqc_report.html",
    log:
        f"{config['logs_dir']}/multiqc/multiqc.log",
    resources:
        mem_gb=config["multiqc"]["mem_gb"],
    params:
        scan_dir=config["output_dir"],
        outdir=f"{config['output_dir']}/multiqc",
    conda:
        "../envs/multiqc.yaml"
    shell:
        """
        multiqc --force {params.scan_dir} -o {params.outdir} 2> {log}
        """
