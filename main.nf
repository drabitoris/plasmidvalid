#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { test1 } from "./module/basecall"
include { backUp } from "./module/basecall"

workflow {
    workpath_ch = Channel.fromPath("${params.work_dir}/${params.project}/${params.sample}/${params.run}", checkIfExists: true)
    projectpath_ch = Channel.fromPath("${params.work_dir}/${params.project}", checkIfExists: true)
    main:
        test1(workpath_ch, projectpath_ch)
}
