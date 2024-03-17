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
include { assemblyMafs } from "./module/utils"
include { exampleinserts } from "./module/utils"
include { output } from "./module/utils"

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
    dcout = correcting(mout.fasta)
    annotation = annotating(dcout.corrected.map { it -> it[1] }.collect(), database)

    database = file("$projectDir/data/OPTIONAL_FILE")
    if (params.db_directory != null){
            database = file(params.db_directory, type: "dir")
    }
    samplestat = sampleStat(bout)
    filteredstat = Channel.empty()
    downsampledstat = downsampledStats(dout)
    assemblystat = assemblyStat(mout.fastq)
    final_status = dcout.status.groupTuple().map { it -> it[0].toString() + ',' + it[1][-1].toString() }
    final_status = final_status.collectFile(name: 'final_status.csv', newLine: true)
    medaka_version = medakaVersion()
    software_versions = getVersions(medaka_version)
    workflow_params = getParams()
    insert = exampleinserts()
    qc_insert = Channel.empty()
    mafs = assemblyMafs(aout)

    report = report(
        downsampledstat.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        final_status,
        samplestat.collect(),
        filteredstat.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        software_versions.collect(),
        workflow_params,
        annotation.report,
        insert.json,
        annotation.json,
        qc_insert.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        assemblystat.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE")),
        mafs.map{ meta, maf -> maf}.collect().ifEmpty(file("$projectDir/data/OPTIONAL_FILE"))
        )
    output(report.html)
}