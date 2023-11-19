process trimming {
    label "plasmid"
    input:
        path("fastq")
    output:
        path("*.trimmed_fastq"), emit: trimmed
    script:
    """
    porechop -i ${fastq} \
        --format fastq.gz \
        --end_threshold  50 --extra_end_trim 50 \
        --discard_middle --middle_threshold 80 \
        > ${fastq}.trimmed.fastq.gz
    """
}
process downSampling {
    label "plasmid"
    input:
        path("trimmed_fastq")
    output:
        path("*.downsampled.fastq.gz"), emit: downsampled
    when:
        param.coverage > 50
    script:
    """
    rasusa \
        --coverage 180 \
        --genome-size $approx_size \
        --input ${trimmed_fastq}.trimmed.fastq.gz > ${trimmed_fastq}.downsampled.fastq.gz
    """
}
process assembling {
    label "plasmid"
    input:
        path ("downsampled_fastq")
    output:
        path("assmed_fastq"), emit: assembled
    script:
    """
    flye \
        --${params.flye_quality} \
        --deterministic \
        --threads 8 \
        --genome-size ${param.approx_size} \
        --out-dir "assm_\${downsampled_fastq}" \
        --meta
    """
}
