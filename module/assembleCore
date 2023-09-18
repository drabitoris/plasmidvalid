process trimming {
    input:
        path("fastq")
    output:
        path("trimmed_fastq")
    script:
    """
    porechop -i ${fastq} -o trimmed_fastq --end_size $param.trim_length
    """
}
