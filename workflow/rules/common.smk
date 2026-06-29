import pandas as pd


samples_df = pd.read_csv(config["samples"], sep="\t")
SAMPLES = samples_df["sample"].tolist()
CHUNKS = config["chunks"]


def detect_data_type(df):
    has_fq2_column = "fq2" in df.columns
    has_fq2_values = has_fq2_column and not df["fq2"].isna().all()
    return has_fq2_values


def validate_consistent_data_type(df):
    if "fq2" not in df.columns:
        return True

    all_paired = df["fq2"].notna().all()
    all_single = df["fq2"].isna().all()

    if not (all_paired or all_single):
        paired_samples = df[df["fq2"].notna()]["sample"].tolist()
        single_samples = df[df["fq2"].isna()]["sample"].tolist()
        raise ValueError(
            f"Mixed datasets not supported. All samples must be the same type.\n"
            f"Paired-end samples: {paired_samples}\n"
            f"Single-end samples: {single_samples}\n"
            f"Please create separate sample files for each data type."
        )

    return True


IS_PAIRED = detect_data_type(samples_df)
validate_consistent_data_type(samples_df)
print(
    f"Detected data type: {'Paired-end' if IS_PAIRED else 'Single-end'} ({len(SAMPLES)} samples)"
)


# Constrain {sample} to known sample names to prevent the SE split pattern
# (split/{sample}.part_{chunk}.fastq.gz) from matching PE filenames like
# SRR001_1.part_001.fastq.gz with sample=SRR001_1.
wildcard_constraints:
    sample="|".join(SAMPLES),


# star_align_pe and star_align_se produce identical output paths — ruleorder
# tells Snakemake which rule to prefer based on data type.
if IS_PAIRED:
    ruleorder: star_align_pe > star_align_se
else:
    ruleorder: star_align_se > star_align_pe


def get_copy_inputs(wildcards):
    sample_data = samples_df[samples_df["sample"] == wildcards.sample].iloc[0]
    inputs = [sample_data["fq1"]]
    if IS_PAIRED:
        inputs.append(sample_data["fq2"])
    return inputs


def get_fastqc_outputs(wildcards):
    if IS_PAIRED:
        return expand(
            f"{config['output_dir']}/fastqc/{{sample}}_{{read}}_fastqc.html",
            sample=SAMPLES,
            read=[1, 2],
        )
    return expand(
        f"{config['output_dir']}/fastqc/{{sample}}_fastqc.html", sample=SAMPLES
    )


def get_fastqc_zip_outputs(wildcards):
    if IS_PAIRED:
        return expand(
            f"{config['output_dir']}/fastqc/{{sample}}_{{read}}_fastqc.zip",
            sample=SAMPLES,
            read=[1, 2],
        )
    return expand(
        f"{config['output_dir']}/fastqc/{{sample}}_fastqc.zip", sample=SAMPLES
    )


def get_fastqc_trimmed_outputs(wildcards):
    if IS_PAIRED:
        return expand(
            f"{config['output_dir']}/fastqc_trimmed/{{sample}}_trimmed_R{{read}}_fastqc.html",
            sample=SAMPLES,
            read=[1, 2],
        )
    return expand(
        f"{config['output_dir']}/fastqc_trimmed/{{sample}}_trimmed_fastqc.html",
        sample=SAMPLES,
    )


def get_fastqc_trimmed_zip_outputs(wildcards):
    if IS_PAIRED:
        return expand(
            f"{config['output_dir']}/fastqc_trimmed/{{sample}}_trimmed_R{{read}}_fastqc.zip",
            sample=SAMPLES,
            read=[1, 2],
        )
    return expand(
        f"{config['output_dir']}/fastqc_trimmed/{{sample}}_trimmed_fastqc.zip",
        sample=SAMPLES,
    )
