process trimming {
    input:
        path("fastq")
    output:
        path("*.trimmed_fastq"), emit: trimmed
    script:
    """
    cat ${fastq} > ${fastq}.trimmed.fastq.gz
    """
}
