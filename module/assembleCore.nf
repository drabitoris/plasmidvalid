process trimming {
    label "plasmid"
    input:
        tuple var(row), path('basecalled')
    output:
        tuple var(row), path('trimmed.fastq.gz')
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
        tuple var(row), path('trimmed')
    output:
        tuple var(row), path('downsampled.fastq.gz')
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
        tuple var(row), path('downsampled')
    output:
        tuple var(row), path('assembled.fastq.gz')
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
