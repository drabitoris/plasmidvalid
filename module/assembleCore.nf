process trimming {
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
process downSampling {
    input:
        path("trimmed_fastq") from trimmed_out
    output:
        path("*.downsampled.fastq.gz") into downsampled_out
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
        path path ("downsampled_fastq") from (params.coverage > 50 ? trimmed_out : downsampled_out)
    output:
        path("assmed_fastq")
    script:
        name = sample_id
    """
    flye \
        --${params.flye_quality} \
        --deterministic \
        --threads $task.cpus \
        --genome-size $approx_size \
        --out-dir "assm_\${BOO_NAME}" \
        --meta
    """
}
process medakaPolishAssembly {
    label "medaka"
    cpus params.threads
    input:
        path("assmed_fastq")
    output:
        path("${sample_id}.final.fastq")
    script:
        def model = medaka_model
    
    """
    medaka_consensus -i "${fastq}" -d "${draft}" -m "${model}" -o . -t $task.cpus -f -q
    """
}
process MedakaPolish {
    label (params.GPU == "ON" ? 'with_gpus': 'with_cpus')
    errorStrategy 'finish'
    publishDir "$results_path/medaka_consensus3"
    beforeScript 'chmod o+rw .'

    input:
    set str_name, path(reads), path(rotated) from read_phased_medaka3.filter{ it.get(2).countFasta()>=1} 
    
    output:
    set str_name, file("${str_name}_racon_medaka/consensus.fasta") into medaka_consensus
    
    script:
    """
    chmod -R a+rw ./
    medaka_consensus -i ${reads} -d ${rotated} -o ${str_name}_racon_medaka -m $params.medaka_model
    chmod -R a+rw ./
    """
}
