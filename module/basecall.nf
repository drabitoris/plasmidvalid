process basecall {
    queue "${params.gpu_partition}"
    clusterOptions "--gres=gpu:${params.gpu_config} --mem=${params.gpu_mem} --time=0-03:00 --cpus-per-task 1"
    input:
        val(meta)
    output:
        tuple val(meta), path('basecalled.fastq.gz')
    script:
    bar = meta.barcode
    """ 
    module load dorado
    dorado basecaller --emit-fastq \$DORADO_MODELS/${params.model} \
        ${params.work_dir}/${params.project}/_transfer/${params.sample}/${params.run}/pod5_pass/${bar} \
        | gzip >> basecalled.fastq.gz
    """
}
