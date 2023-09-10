#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { baseCall } from "./module/basecall"
include { backUp } from "./module/basecall"

workflow {
    workpath_ch = Channel.fromPath("${params.work_dir}/${params.project}/${params.sample}/${params.run}/pod5_pass/", checkIfExists: true)
    projectpath_ch = Channel.fromPath("${params.work_dir}/${params.project}", checkIfExists: true)
    main:
        baseCall(workpath_ch,projectpath_ch)
}
