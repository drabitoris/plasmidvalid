#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
workpath_ch = Channel.fromPath("${params.work_dir}/${params.project}/${params.sample}/${params.run}", checkIfExists: true)
projectpath_ch = Channel.fromPath("${params.work_dir}/${params.project}", checkIfExists: true)
process baseCall {
    queue 'gpuq_interactive' // Slurm partition name
    memory '${params.gpu_mem}' // Memory requirement
    // Other Slurm-specific options
    clusterOptions "--gres=gpu:${params.gpu_config}"
    input:
        file("workpath_full")
        file("projectpath_full")
    output:
        file("basecalls/*"), emit: basecall
        val("${task.exitStatus}"), emit: status
    script:
        def MODEL = "${params.basecall_model}"
    """
    STATUS="Basecalling by dorado FAILED"
    module load dorado
    for bc in barcode{01..96} unclassified mixed; do
        mkdir -p ${workpath_full}/basecalls/${bc}
        dorado basecaller --emit-fastq ${MODEL} ${workpath_full}/pod5_pass/$bc | gzip > ${projectpath_full}/basecalls/${bc}/${bc}.fastq.gz
    done
    STATUS="Basecalling by dorado completed Successfully"
    """
}
process baseCall_backup {
    input:
        file("projectpath_full")
        file("basecall")
    output:
        val("${task.exitStatus}"), emit: status
    script:
    """
    STATUS="Backup basecalled results FAILED"
    tar -cvf ${params.project}_sup_basecalls.tar ${basecall}
    rsync -av ${params.project}_sup_basecalls.tar ${params.backup_dir}
    STATUS="Backup basecalled results completed Successfully"
    """
}

def helpMessage() {
    log.info"""
    Usage:

    nextflow run main.nf <ARGUMENTS>

    Required arguments:

    foo
    """.stripIndent()
}
workflow {
    if (params.help || params.project == null || params.run == null || params.sample == null) {
        helpMessage()
        exit 1
    }

    baseCall(workpath_ch, projectpath_ch)
    baseCall_backup(projectpath_ch)
}
