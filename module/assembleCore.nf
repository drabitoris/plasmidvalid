process trimming {
    debug true
    label "plasmid"
    input:
        tuple val(meta), path('basecalled')
    output:
        tuple val(meta), path('trimmed.fastq.gz')

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
        tuple val(meta), path('trimmed')
    output:
        tuple val(meta), path('downsampled.fastq.gz')

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
        tuple val(meta), path('downsampled.fastq.gz')
    output:
        tuple val(meta), path('assembled.fastq.gz')

    script:
    """
    flye \
        --${params.flye_quality} downsampled.fastq.gz \
        --deterministic \
        --threads 8 \
        --genome-size ${meta.approx_size} \
        --out-dir . \
        --meta > assembled.fastq.gz
    """
}
