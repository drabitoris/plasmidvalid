#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { basecall } from "./module/basecall"
include { trimming } from "./module/assembleCore"
include { downSampling } from "./module/assembleCore"
include { assembling } from "./module/assembleCore"

def processCsvRow(row) {
    Channel.of(row)
}

workflow {
    Channel.
        fromPath("${params.sample_sheet}")
        .splitCsv(header: true, sep: ',', strip: true)
        .set { csv_rows }
    main:
        bout = basecall(csv_rows).basecalled 
        tout = trimming(csv_rows, bout).trimmed 
        dout = downSampling(csv_rows, tout).downSampled 
        aout = assembling(csv_rows, dout)
}
