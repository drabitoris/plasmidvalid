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
    primer_file = file("$projectDir/data/OPTIONAL_FILE")
    if (params.primers != null){
        primer_file = file(params.primers, type: "file")
    }
    align_ref = file("$projectDir/data/OPTIONAL_FILE")
    if (params.insert_reference != null){
        align_ref = file(params.insert_reference, type: "file")
    }
    database = file("$projectDir/data/OPTIONAL_FILE")
    if (params.db_directory != null){
         database = file(params.db_directory, type: "dir")
    }
    Channel.
        fromPath("${params.sample_sheet}")
        .splitCsv(header: true, sep: ',', strip: true)
        .set { csvrow }
    meta = basecall(csvrow).meta
    bout = basecall(csvrow) 
    tout = trimming(bout)
    dout = downSampling(tout)
    aout = assembling(dout)
    mout = medakaPolish(bout, aout)
    dcout = correcting(mout)

    report = report(
        downsampled_stats.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        final_status,
        sample_fastqs.stats.collect(),x
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
