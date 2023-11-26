#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { basecall } from "./module/basecall"
include { trimming } from "./module/assembleCore"

def processCsvRow(row) {
    Channel.of(row)
}

workflow {
    Channel
        .fromPath('${params.sample_sheet}')
        .splitCsv(header: true, sep: ',', strip: true)
        .map { row -> processCsvRow(row) }
        .set { csv_rows }
    workpath_ch = Channel.fromPath("${params.work_dir}/${params.project}/${params.sample}/${params.run}/pod5_pass/barcode09", checkIfExists: true)
    projectpath_ch = Channel.fromPath("${params.work_dir}/${params.project}", checkIfExists: true)

    main:
        bout = basecall(csv_rows).basecalled
        result = trimming(csv_rows).trimmed
        result.view { "Result: ${it}" }
}
