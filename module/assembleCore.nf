process trimming {
    label "plasmid"
    input:
        tuple val(meta), path('basecalled')
    output:
        tuple var(meta), path('trimmed.fastq.gz')
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
        tuple var(meta), path('trimmed')
    output:
        tuple var(meta), path('downsampled.fastq.gz')
    script:
    """
    rasusa \
        --coverage 180 \
        --genome-size ${meta.approx_size} \
        -O g \
        --input $trimmed > downsampled.fastq.gz
    """
}
process assembling {
    label "plasmid"
    input:
        tuple var(meta), path('downsampled')
    output:
        tuple var(meta), path('assembled.fastq.gz')
    script:
    """
    flye \
        --${params.flye_quality} $downsampled \
        --deterministic \
        --threads 8 \
        --genome-size ${meta.approx_size} \
        --out-dir . \
        --meta
    """
}
