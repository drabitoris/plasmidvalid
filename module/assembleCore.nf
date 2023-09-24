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
        path("*.downsampled.fastq.gz")
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
process assembling {
    input:
        path("trimmed_fastq")
    output:
        path("trimmed_fastq")
    script:
        name = sample_id
    """
    flye \
        --${params.flye_quality} \${SUBSET} \
        --deterministic \
        --threads $task.cpus \
        --genome-size $approx_size \
        --out-dir "assm_\${SUBSET_NAME}" \
        --meta
    """
}
process medakaPolishAssembly {
    label "medaka"
    cpus params.threads
    input:
        tuple val(sample_id), path(draft), path(fastq), val(medaka_model)
    output:
        tuple val(sample_id), path("*.final.fasta"), emit: polished
        tuple val(sample_id), env(STATUS), emit: status
        tuple val(sample_id), path("${sample_id}.final.fastq"), emit: assembly_qc
    script:
        def model = medaka_model
    
    """
    STATUS="Failed to polish assembly with Medaka"
    medaka_consensus -i "${fastq}" -d "${draft}" -m "${model}" -o . -t $task.cpus -f -q
    echo ">${sample_id}" >> "${sample_id}.final.fasta"
    sed "2q;d" consensus.fasta >> "${sample_id}.final.fasta"
    mv consensus.fasta "${sample_id}.final.fastq"
    STATUS="Completed successfully"
    """
}
