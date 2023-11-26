process basecall {
    queue "${params.gpu_partition}"
    clusterOptions "--gres=gpu:${params.gpu_config} --mem=${params.gpu_mem} --time=0-03:00 --cpus-per-task 5"
    input:
        val samplesheet 
    output:
        path("${samplesheet.barcode}.fastq.gz"), emit: basecalled
    script:
    """
    module load dorado
    dorado basecaller --emit-fastq \$DORADO_MODELS/${params.basecall_model} \
        ${params.work_dir}/${params.project}/_transfer/${params.sample}/${params.run}/pod5_pass/${samplesheet.barcode} \
        | gzip >> ${samplesheet.barcode}.fastq.gz
    """
}
