process test1 {
    queue 'gpuq_interactive' // Slurm partition name
    memory params.gpu_mem.toGiga() // Memory requirement
    // Other Slurm-specific options
    clusterOptions "--gres=gpu:${params.gpu_config}"
    input:
        path("workpath_full"),
        path("projectpath_full")
    output:
        val("${task.exitStatus}")
    script:
    """
    module load dorado
    for bc in barcode{01..96} unclassified mixed
    do
        mkdir -p ${projectpath_full}/basecalls/\$bc
        dorado basecaller --emit-fastq ${params.basecall_model} ${workpath_full}/pod5_pass/\$bc | gzip > ${projectpath_full}/basecalls/\$bc/\$bc.fastq.gz
    done
    """
}
process backUp {
    input:
        path("projectpath_full")
    output:
        val("${task.exitStatus}")
    script:
    """
    tar -cvf ${params.project}_sup_basecalls.tar ${projectpath_full}/basecalls/
    rsync -av ${params.project}_sup_basecalls.tar ${params.backup_dir}
    """
}
