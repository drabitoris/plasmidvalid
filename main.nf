#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { basecall } from "./module/basecall"
include { backUp } from "./module/basecall"
include { trimming } from "./module/assembleCore"
include { downSampling } from "./module/assembleCore"
include { assembling } from "./module/assembleCore"
workflow {
    workpath_ch = Channel.fromPath("${params.work_dir}/${params.project}/${params.sample}/${params.run}/pod5_pass/barcode09", checkIfExists: true)
    projectpath_ch = Channel.fromPath("${params.work_dir}/${params.project}", checkIfExists: true)
    main:
        bout =basecall(workpath_ch, projectpath_ch).basecalled
        tout = trimming(bout).trimmed
        dout = downSampling(tout).downsampled
        result = assembling(dout).assembled
        result.view { "Result: ${it}" }
}
