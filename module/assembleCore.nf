process trimming {
    input:
        path("fastq")
    output:
        path("trimmed_fastq")
    script:
    """
    porechop -i ${fastq} > ${fastq}.trimmed.fastq.gz
    """
}
process downSampling {
    input:
        path("trimmed_fastq")
    output:
        path("trimmed_fastq")
    when:
        param.coverage > 50
    script:
        name = sample_id
    """
    rasusa \
        --coverage $target \
        --genome-size $approx_size \
        --input ${name}.trimmed.fastq.gz > ${name}.downsampled.fastq.gz
    """
}
