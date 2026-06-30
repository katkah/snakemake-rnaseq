rule salmon_quantify:
    input:
        bam=f"{config['output_dir']}/star/{{sample}}/{{sample}}Aligned.toTranscriptome.out.bam",
        transcriptome=f"{RSEM_IDX}.transcripts.fa",
        gtf=config["reference"]["gtf"],
    output:
        quant=f"{config['output_dir']}/salmon/{{sample}}/quant.sf",
        quant_genes=f"{config['output_dir']}/salmon/{{sample}}/quant.genes.sf",
    log:
        f"{config['logs_dir']}/salmon/{{sample}}.log",
    threads: config["salmon"]["threads"]
    resources:
        mem_gb=config["salmon"]["mem_gb"],
    params:
        outdir=f"{config['output_dir']}/salmon/{{sample}}",
        lib_type=config["salmon"]["lib_type"],
        bootstraps=config["salmon"]["bootstraps"],
        extra=config["salmon"]["extra_params"],
    conda:
        "../envs/salmon.yaml"
    shell:
        """
        mkdir -p {params.outdir}

        salmon quant \
            -a {input.bam} \
            -t {input.transcriptome} \
            -g {input.gtf} \
            -l {params.lib_type} \
            --numBootstraps {params.bootstraps} \
            -p {threads} \
            {params.extra} \
            -o {params.outdir} \
            2> {log}
        """
