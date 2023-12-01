process trimming {
    label "plasmid"
    input:
        path basecalled
    output:
        path('trimmed.fastq.gz'), emit: trimmed
    script:
    """
    porechop -i $basecalled \
        --format fastq.gz \
        --end_threshold  50 --extra_end_trim 50 \
        --discard_middle --middle_threshold 80 \
        > trimmed.fastq.gz
    """
}
process downSampling {
    label "plasmid"
    input:
    var row
    path trimmed
    output:
        path('downsampled.fastq.gz'), emit: downSampled
    script:
    """
    rasusa \
        --coverage 180 \
        --genome-size ${row.approx_size} \
        -O g \
        --input $trimmed > downsampled.fastq.gz
    """
}
process assembling {
    label "plasmid"
    input:
    var row
    path downsampled
    output:
        path('assembled.fastq.gz'), emit: assembled
    script:
    """
    flye \
        --${params.flye_quality} $downsampled \
        --deterministic \
        --threads 8 \
        --genome-size ${row.approx_size} \
        --out-dir . \
        --meta
    """
}
