process trimming {
    label "plasmid"
    input:
        path("fastq") from basecalled_out
    output:
        path("*.trimmed_fastq") into trimmed_out
    script:
    """
    porechop -i ${fastq} \
        --format fastq.gz \
        --end_threshold  50 --extra_end_trim 50 \
        --discard_middle --middle_threshold 80 \
        > ${fastq}.trimmed.fastq.gz
    """
}
