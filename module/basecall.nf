process basecall {
    queue "${params.gpu_partition}"
    clusterOptions "--gres=gpu:${params.gpu_config} --mem=${params.gpu_mem} --time=0-03:00 --cpus-per-task 1"
    input:
        val row 
    output:
        val (bar), path ('${row.barcode}.fastq.gz'), emit: basecalled
    script:
    """
    echo ${row.barcode} > bar 
    module load dorado
    dorado basecaller --emit-fastq \$DORADO_MODELS/${params.basecall_model} \
        ${params.work_dir}/${params.project}/_transfer/${params.sample}/${params.run}/pod5_pass/$bar \
        | gzip >> ${row.barcode}.fastq.gz
    """
}
