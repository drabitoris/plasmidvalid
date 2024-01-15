#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { basecall } from "./module/basecall"
include { trimming } from "./module/assembleCore"
include { downSampling } from "./module/assembleCore"
include { assembling } from "./module/assembleCore"
include { medakaPolish } from "./module/assembleCore"
include { correcting } from "./module/assembleCore"
def processCsvRow(row) {
    Channel.of(row)
}

workflow {
    database = file("$projectDir/data/OPTIONAL_FILE")
    if (params.db_directory != null){
         database = file(params.db_directory, type: "dir")
    }
    Channel.
        fromPath("${params.sample_sheet}")
        .splitCsv(header: true, sep: ',', strip: true)
        .set { csvrow }
    bout = basecall(csvrow) 
    tout = trimming(bout)
    dout = downSampling(tout)
    aout = assembling(dout)
    mout = medakaPolish(bout, aout)
    dcout = correcting(mout)
    
    report = report(
        downsampled_stats.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        final_status,
        sample_fastqs.stats.collect(),
        filtered_stats,
        software_versions.collect(),
        workflow_params,
        annotation.report,
        insert.json,
        annotation.json,
        qc_insert.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        assembly_quality.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        mafs.map{ meta, maf -> maf}.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE"))
        )
}
