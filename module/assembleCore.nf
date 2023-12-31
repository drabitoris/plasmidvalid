process trimming {
    debug true
    label "plasmid"
    input:
        tuple val(meta), path('basecalled.fastq')
    output:
        tuple val(meta), path('trimmed.fastq.gz')

    script:
    """
    porechop -i basecalled.fastq \
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
        path('assembly.fasta')

    script:
    """
    flye \
        --${params.flye_quality} downsampled.fastq.gz \
        --deterministic \
        --threads 8 \
        --genome-size ${meta.approx_size} \
        --out-dir . \
        --meta > assembly.fasta
    """
}

process medakaPolish {
    label "medaka"
    cpus 4
    input:
        tuple val(meta), path('basecallfastq.fastq')
        path('flyedraft.fasta')
    output:
        tuple val(meta), path('*.final.fasta')
    script:
    
    """
    medaka_consensus -i basecallfastq.fastq -d flyedraft.fasta -m ${params.medaka_model} -o . -t 8 -f -q
    echo ">${meta.barcode}" >> ${meta.barcode}.final.fasta
    sed "2q;d" consensus.fasta >> ${meta.barcode}.final.fasta
    mv consensus.fasta ${meta.barcode}.final.fastq
    """
}

process correcting {
    label "plasmid"
    input:
        tuple val(meta), path('reference.fasta')
    output:
        tuple val(meta), path('*.corrected.fasta')
    script:

    """
    dupscoop --ref reference.fasta --min 500 -s 0.7 -o ${meta.barcode}.corrected.fasta -d 20
    """
}

process annotating {
    label "plasmid"
    input:
        tuple val(meta), path('reference.fasta')
    output:
        tuple val(meta), path('*.corrected.fasta')
    script:

    """
    dupscoop --ref reference.fasta --min 500 -s 0.7 -o ${meta.barcode}.corrected.fasta -d 20
    """
}
