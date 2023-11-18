process trimming {
    input:
        path("fastq") from basecalled
    output:
        path("*.trimmed_fastq"), emit: trimmed
    script:
    """
    cat ${fastq} > ${fastq}.trimmed.fastq.gz
    """
}
