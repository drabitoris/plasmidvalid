#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { baseCall } from "./module/basecall"
include { baseCall_backup } from "./module/basecall"
workpath_ch = Channel.fromPath("${params.work_dir}/${params.project}/${params.sample}/${params.run}", checkIfExists: true)
projectpath_ch = Channel.fromPath("${params.work_dir}/${params.project}", checkIfExists: true)

workflow {
    baseCall(workpath_ch, projectpath_ch)
    baseCall_backup(projectpath_ch)
}
