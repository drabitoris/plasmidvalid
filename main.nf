#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
import groovy.json.JsonBuilder
include { basecall } from "./module/basecall"
include { trimming } from "./module/assembleCore"
include { downSampling } from "./module/assembleCore"
include { assembling } from "./module/assembleCore"
include { medakaPolish } from "./module/assembleCore"
include { correcting } from "./module/assembleCore"
include { annotating } from "./module/assembleCore"
include { medakaVersion } from "./module/utils"
include { getVersions } from "./module/utils"
include { getParams } from "./module/utils"
include { sampleStat } from "./module/utils"
include { downsampledStats } from "./module/utils"
include { assemblyStat } from "./module/utils"
include { exampleStatus } from "./module/utils"
include { report } from "./module/assembleCore"

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
    bout = basecall(csvrow) 
    tout = trimming(bout)
    dout = downSampling(tout)
    aout = assembling(dout)
    mout = medakaPolish(bout, aout)
    dcout = correcting(mout)
    annotation = annotating(dcout, database)

    database = file("$projectDir/data/OPTIONAL_FILE")
    if (params.db_directory != null){
            database = file(params.db_directory, type: "dir")
    }
    samplestat = sampleStat(bout)
    filteredstat = samplestat
    downsampledstat = downsampledStats(dout)
    assemblystat = assemblyStat(aout)
    status = exampleStatus()
    medaka_version = medakaVersion()
    software_versions = getVersions(medaka_version)
    workflow_params = getParams()
    insert = Channel.empty()
    qc_insert = Channel.empty()
    maf = Channel.empty()

    report = report(
        downsampledstat.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        status,
        samplestat.collect(),
        filteredstat.collect(),
        software_versions.collect(),
        workflow_params,
        annotation.report,
        insert.json.ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        annotation.json,
        qc_insert.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        assemblystat.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        mafs.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE"))
        )
}
