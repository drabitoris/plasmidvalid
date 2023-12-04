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
        tuple val(meta), path('assembled.fasta')

    script:
    """
    flye \
        --${params.flye_quality} downsampled.fastq.gz \
        --deterministic \
        --threads 8 \
        --genome-size ${meta.approx_size} \
        --out-dir . \
        --meta > assembled.fasta
    """
}

process medakaPolish {
    label "medaka"
    cpus 4
    input:
        tuple val(meta), path(flyedraft)
        path(basecallfastq)
    output:
        tuple val(meta), path("*.final.fasta"), emit: polished
    script:
    
    """
    medaka_consensus -i "${basecallfastq}" -d "${flyedraft}" -m "${params.model}" -o . -t $task.cpus -f -q
    echo ">${meta.barcode}" >> "${meta.barcode}.final.fasta"
    sed "2q;d" consensus.fasta >> "${meta.barcode}.final.fasta"
    mv consensus.fasta "${meta.barcode}.final.fastq"
    """
}
