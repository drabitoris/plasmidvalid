#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { basecall } from "./module/basecall"
include { trimming } from "./module/assembleCore"
include { downSampling } from "./module/assembleCore"
include { assembling } from "./module/assembleCore"
include { medakaPolish } from "./module/assembleCore"
include { dupscoopCorrection } from "./module/assembleCore"
def processCsvRow(row) {
    Channel.of(row)
}

workflow {
    Channel.
        fromPath("${params.sample_sheet}")
        .splitCsv(header: true, sep: ',', strip: true)
        .set { csvrow }
    bout = basecall(csvrow) 
    tout = trimming(bout)
    dout = downSampling(tout)
    aout = assembling(dout)
    mout = medakaPolish(bout, aout)
    dcout = dupscoopCorrection(mout)
}
