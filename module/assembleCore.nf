process trimming {
    label "plasmid"
    input:
        val samplesheet
    output:
        tuple val (${samplesheet.barcode}), path '${samplesheet.barcode}.trimmed.fastq.gz', emit: trimmed
    script:
    """
    porechop -i ${samplesheet.barcode}.fastq.gz \
        --format fastq.gz \
        --end_threshold  50 --extra_end_trim 50 \
        --discard_middle --middle_threshold 80 \
        > ${samplesheet.barcode}.trimmed.fastq.gz
    """
}
process downSampling {
    label "plasmid"
    input:
        path trimmed_fastq
    output:
        path 'boo.downsampled.fastq.gz', emit: downsampled
    script:
    """
    rasusa \
        --coverage 180 \
        --genome-size ${params.approx_size} \
        -O g \
        --input boo.trimmed.fastq.gz > boo.downsampled.fastq.gz
    """
}
process assembling {
    label "plasmid"
    input:
        path downsampled_fastq
    output:
        path 'assm_\$downsampled_fastq', emit: assembled
    script:
    """
    flye \
        --${params.flye_quality} boo.downsampled.fastq.gz \
        --deterministic \
        --threads 8 \
        --genome-size ${params.approx_size} \
        --out-dir "assm_${downsampled_fastq}" \
        --meta
    """
}
