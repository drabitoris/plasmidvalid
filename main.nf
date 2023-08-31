#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process baseCall {
    executor 'slurm'
    queue 'gpuq_interactive' // Slurm partition name
    memory '${params.gpu_mem}' // Memory requirement
    // Other Slurm-specific options
    clusterOptions "--gres=gpu:${params.gpu_config}"
    input:
        file("workpath_full") from workpath_ch
    output:
        file(*basecalls/$bc/.fastq.gz), emit: basecall
        val("${task.exitStatus}"), emit: status
    script:
        def MODEL = ${params.basecall_model}
    """
    STATUS="Basecalling by dorado FAILED"
    module load dorado
    for bc in barcode{01..96} unclassified mixed; do
        mkdir -p ${workpath_full}/basecalls/$bc
        dorado basecaller --emit-fastq $MODEL ${workpath_full}/pod5_pass/$bc | gzip > ${workpath_full}/basecalls/$bc/$bc.fastq.gz
    done
    STATUS="Basecalling by dorado completed Successfully"
    """
}
process baseCall_backup {
    input:
        file("workpath_full") from workpath_ch
        file("basecall") from baseCall.basecall
    output:
        val("${task.exitStatus}"), emit: status
    script:
    """
    STATUS="Backup basecalled results FAILED"
    tar -cvf ${params.project}_sup_basecalls.tar ${params.sample}/${params.run}/basecalls
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
    workpath_ch = Channel.fromPath(params.work_dir + "/" + params.project, checkIfExists: true)
    baseCall(
        workpath_full,
        params.basecall_model
    )
    baseCall_backup(
        baseCall.basecall,
        params.run,
        params.project,
        params.sample,
        params.backup_dir
    )
}