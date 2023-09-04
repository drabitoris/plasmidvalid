#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { test2 } from "./module/basecall"
include { backUp } from "./module/basecall"
workpath_ch = Channel.fromPath("${params.work_dir}/${params.project}/${params.sample}/${params.run}", checkIfExists: true)
projectpath_ch = Channel.fromPath("${params.work_dir}/${params.project}", checkIfExists: true)

workflow {
    main:
        test2(workpath_ch, projectpath_ch)
        backUp(projectpath_ch)
}
