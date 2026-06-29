rule star_prepare_index:
    input:
        genome_fasta=config["reference"].get("genome_fasta", ""),
        gtf=config["reference"]["gtf"],
    output:
        f"{STAR_IDX}/genomeParameters.txt",
    log:
        f"{config['logs_dir']}/star/prepare_index.log",
    shadow:
        "minimal"
    threads: config["star"]["threads"]
    resources:
        mem_gb=config["star"]["mem_gb"],
    params:
        outdir=STAR_IDX,
    conda:
        "../envs/star.yaml"
    shell:
        """
        mkdir -p {params.outdir}

        if [[ {input.genome_fasta} == *.gz ]]; then
            gunzip -c {input.genome_fasta} > genome.fa
            GENOME_FILE=genome.fa
        else
            GENOME_FILE={input.genome_fasta}
        fi

        STAR --runMode genomeGenerate \
             --genomeDir {params.outdir} \
             --genomeFastaFiles $GENOME_FILE \
             --sjdbGTFfile {input.gtf} \
             --runThreadN {threads} \
             2> {log}
        """


rule star_align_pe:
    input:
        fastq1=f"{config['output_dir']}/joined/{{sample}}_trimmed_R1.fastq.gz",
        fastq2=f"{config['output_dir']}/joined/{{sample}}_trimmed_R2.fastq.gz",
        genome_params=f"{STAR_IDX}/genomeParameters.txt",
        gtf=config["reference"]["gtf"],
    output:
        bam=f"{config['output_dir']}/star/{{sample}}/{{sample}}Aligned.sortedByCoord.out.bam",
        transcriptome_bam=f"{config['output_dir']}/star/{{sample}}/{{sample}}Aligned.toTranscriptome.out.bam",
        counts=f"{config['output_dir']}/star/{{sample}}/{{sample}}ReadsPerGene.out.tab",
        sj=f"{config['output_dir']}/star/{{sample}}/{{sample}}SJ.out.tab",
        log=f"{config['output_dir']}/star/{{sample}}/{{sample}}Log.final.out",
    log:
        f"{config['logs_dir']}/star/{{sample}}.log",
    shadow:
        "minimal"
    threads: config["star"]["threads"]
    resources:
        mem_gb=config["star"]["mem_gb"],
    params:
        outdir=f"{config['output_dir']}/star/{{sample}}",
        genome_dir=STAR_IDX,
        extra=config["star"]["extra_params"],
    conda:
        "../envs/star.yaml"
    shell:
        """
        mkdir -p genome_index
        cp -r {params.genome_dir}/* genome_index/
        cp {input.gtf} .

        mkdir -p {params.outdir}

        STAR --runThreadN {threads} \
            --genomeDir genome_index \
            --readFilesIn {input.fastq1} {input.fastq2} \
            --sjdbGTFfile $(basename {input.gtf}) \
            --outFileNamePrefix {params.outdir}/{wildcards.sample} \
            {params.extra} \
            2> {log}
        """


rule star_align_se:
    input:
        fastq=f"{config['output_dir']}/joined/{{sample}}_trimmed.fastq.gz",
        genome_params=f"{STAR_IDX}/genomeParameters.txt",
        gtf=config["reference"]["gtf"],
    output:
        bam=f"{config['output_dir']}/star/{{sample}}/{{sample}}Aligned.sortedByCoord.out.bam",
        transcriptome_bam=f"{config['output_dir']}/star/{{sample}}/{{sample}}Aligned.toTranscriptome.out.bam",
        counts=f"{config['output_dir']}/star/{{sample}}/{{sample}}ReadsPerGene.out.tab",
        sj=f"{config['output_dir']}/star/{{sample}}/{{sample}}SJ.out.tab",
        log=f"{config['output_dir']}/star/{{sample}}/{{sample}}Log.final.out",
    log:
        f"{config['logs_dir']}/star/{{sample}}.log",
    shadow:
        "minimal"
    threads: config["star"]["threads"]
    resources:
        mem_gb=config["star"]["mem_gb"],
    params:
        outdir=f"{config['output_dir']}/star/{{sample}}",
        genome_dir=STAR_IDX,
        extra=config["star"]["extra_params"],
    conda:
        "../envs/star.yaml"
    shell:
        """
        mkdir -p genome_index
        cp -r {params.genome_dir}/* genome_index/
        cp {input.gtf} .

        mkdir -p {params.outdir}

        STAR --runThreadN {threads} \
            --genomeDir genome_index \
            --readFilesIn {input.fastq} \
            --sjdbGTFfile $(basename {input.gtf}) \
            --outFileNamePrefix {params.outdir}/{wildcards.sample} \
            {params.extra} \
            2> {log}
        """
