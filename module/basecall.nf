process basecall {
    queue "${params.gpu_partition}"
    clusterOptions "--gres=gpu:${params.gpu_config} --mem=${params.gpu_mem} --time=0-03:00 --cpus-per-task 5"
    input:
        path("workpath_full")
        path("projectpath_full")
    output:
        path("${projectpath_full}/basecalls/foo/foo.fastq.gz")
    script:
    """
    module load dorado/0.3.0
    mkdir -p ${projectpath_full}/basecalls/foo
    dorado basecaller --emit-fastq \$DORADO_MODELS/${params.basecall_model} ${workpath_full}/foo | gzip > ${projectpath_full}/basecalls/foo/foo.fastq.gz
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
