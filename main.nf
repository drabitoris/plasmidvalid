#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { baseCall } from "./modules/basecall"
include { baseCall_backup } from "./modules/basecall"
workpath_ch = Channel.fromPath("${params.work_dir}/${params.project}/${params.sample}/${params.run}", checkIfExists: true)
projectpath_ch = Channel.fromPath("${params.work_dir}/${params.project}", checkIfExists: true)

def helpMessage() {
    log.info"""
    Usage:

    nextflow run main.nf <ARGUMENTS>

    Required arguments:

    foo
    """.stripIndent()
}

workflow {
    if (params.project == null || params.run == null || params.sample == null) {
        helpMessage()
        exit 1
    }
    baseCall(workpath_ch, projectpath_ch)
    baseCall_backup(projectpath_ch)
}
