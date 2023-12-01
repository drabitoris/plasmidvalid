process trimming {
    label "plasmid"
    input:
        tuple var(row), path('basecalled')
    output:
        tuple var(row), path('trimmed.fastq.gz'), emit: trimmed
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
        tuple var(row), path('trimmed')
    output:
        tuple var(row), path('downsampled.fastq.gz'), emit: downSampled
    script:
    """
    rasusa \
        --coverage 180 \
        --genome-size ${row.approx_size} \
        -O g \
        --input $trimmed > downsampled.fastq.gz
    """
}
process assembling {
    label "plasmid"
    input:
        tuple var(row), path('downsampled')
    output:
        tuple var(row), path('assembled.fastq.gz'), emit: assembled
    script:
    """
    flye \
        --${params.flye_quality} $downsampled \
        --deterministic \
        --threads 8 \
        --genome-size ${row.approx_size} \
        --out-dir . \
        --meta
    """
}
process medakaPolishAssembly {
    label "medaka"
    cpus 4
    input:
        tuple val(sample_id), path(draft), path(fastq), val(medaka_model)
    output:
        tuple val(sample_id), path("*.final.fasta"), emit: polished
        tuple val(sample_id), path("${sample_id}.final.fastq"), emit: assembly_qc
    script:
        def model = medaka_model
    
    """
    medaka_consensus -i "${fastq}" -d "${draft}" -m "${model}" -o . -t 4 -f -q
    echo ">${sample_id}" >> "${sample_id}.final.fasta"
    sed "2q;d" consensus.fasta >> "${sample_id}.final.fasta"
    mv consensus.fasta "${sample_id}.final.fastq"
    """
}
