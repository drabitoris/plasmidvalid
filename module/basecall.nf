process test1 {
    queue "${params.gpu_partition}"
    clusterOptions "--gres=gpu:${params.gpu_config} --mem=${params.gpu_mem} --time=0-03:00 --cpus-per-task 5"
    input:
        file("workpath_full")
        file("projectpath_full")
    output:
        path("projectpath_full")
    script:
    """
    module load dorado
    for bc in barcode{01..96} unclassified mixed
    do
        mkdir -p ${projectpath_full}/basecalls/\$bc
        dorado basecaller --emit-fastq ${params.basecall_model} ${workpath_full}/\$bc | gzip > ${projectpath_full}/basecalls/\$bc/\$bc.fastq.gz
    done
    """
}
process backUp {
    input:
        path("projectpath_full")
    output:
        path("projectpath_full")
    script:
    """
    tar -cvf ${params.project}_sup_basecalls.tar ${projectpath_full}/basecalls/
    rsync -av ${params.project}_sup_basecalls.tar ${params.backup_dir}
    """
}
