rule rsem_prepare_reference:
    input:
        genome_fasta=config["reference"]["genome_fasta"],
        gtf=config["reference"]["gtf"],
    output:
        seq=f"{config['reference']['rsem_index']}/{config['reference']['rsem_index_name']}.seq",
        grp=f"{config['reference']['rsem_index']}/{config['reference']['rsem_index_name']}.grp",
        ti=f"{config['reference']['rsem_index']}/{config['reference']['rsem_index_name']}.ti",
        idx_fa=f"{config['reference']['rsem_index']}/{config['reference']['rsem_index_name']}.idx.fa",
        transcripts_fa=f"{config['reference']['rsem_index']}/{config['reference']['rsem_index_name']}.transcripts.fa",
        chrlist=f"{config['reference']['rsem_index']}/{config['reference']['rsem_index_name']}.chrlist",
        n2g_idx_fa=f"{config['reference']['rsem_index']}/{config['reference']['rsem_index_name']}.n2g.idx.fa",
    log:
        f"{config['logs_dir']}/rsem/prepare_reference.log",
    shadow:
        "minimal"
    threads: config["rsem"]["threads"]
    resources:
        mem_gb=config["rsem"]["mem_gb"],
    params:
        index_dir=config["reference"]["rsem_index"],
        index_prefix=f"{config['reference']['rsem_index']}/{config['reference']['rsem_index_name']}",
    conda:
        "../envs/rsem.yaml"
    shell:
        """
        mkdir -p {params.index_dir}

        cp {input.genome_fasta} ./
        cp {input.gtf} ./

        if [[ {input.genome_fasta} == *.gz ]]; then
            gunzip $(basename {input.genome_fasta})
            GENOME_FILE=$(basename {input.genome_fasta} .gz)
        else
            GENOME_FILE=$(basename {input.genome_fasta})
        fi

        rsem-prepare-reference \
            --gtf $(basename {input.gtf}) \
            --num-threads {threads} \
            $GENOME_FILE \
            {params.index_prefix} 2> {log}
        """


rule rsem_quantify:
    input:
        bam=f"{config['output_dir']}/star/{{sample}}/{{sample}}Aligned.toTranscriptome.out.bam",
        index_seq=f"{config['reference']['rsem_index']}/{config['reference']['rsem_index_name']}.seq",
        index_grp=f"{config['reference']['rsem_index']}/{config['reference']['rsem_index_name']}.grp",
    output:
        genes=f"{config['output_dir']}/rsem/{{sample}}.genes.results",
        isoforms=f"{config['output_dir']}/rsem/{{sample}}.isoforms.results",
    log:
        f"{config['logs_dir']}/rsem/{{sample}}.log",
    shadow:
        "minimal"
    threads: config["rsem"]["threads"]
    resources:
        mem_gb=config["rsem"]["mem_gb"],
    params:
        outdir=f"{config['output_dir']}/rsem",
        index_dir=config["reference"]["rsem_index"],
        index_name=config["reference"]["rsem_index_name"],
        strandedness=config["rsem"]["strandedness"],
        extra=config["rsem"]["extra_params"],
        seed="12345",
        paired="--paired-end" if IS_PAIRED else "",
    conda:
        "../envs/rsem.yaml"
    shell:
        """
        mkdir -p rsem_index
        cp {params.index_dir}/* rsem_index/

        mkdir -p {params.outdir}

        rsem-calculate-expression -p {threads} \
            {params.paired} \
            --seed {params.seed} \
            --strandedness {params.strandedness} \
            {params.extra} \
            {input.bam} rsem_index/{params.index_name} {params.outdir}/{wildcards.sample} 2> {log}
        """
