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
        tuple val(meta), path('*.polished.fasta')
    script:
    
    """
    medaka_consensus -i basecallfastq.fastq -d flyedraft.fasta -m ${params.medaka_model} -o . -t 8 -f -q
    echo ">${meta.barcode}" >> ${meta.barcode}.polished.fasta
    sed "2q;d" consensus.fasta >> ${meta.barcode}.polished.fasta
    mv consensus.fasta ${meta.barcode}.polished.fastq
    """
}

process correcting {
    label "plasmid"
    input:
        tuple val(meta), path('polished.fasta')
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
        tuple val(meta), path('corrected.fasta')
        path annotation_database
    output:
        path "feature_table.txt", emit: feature_table
        path "plannotate.json", emit: json
        path "*annotations.bed", optional: true, emit: annotations
        path "plannotate_report.json", emit: report
        path "*annotations.gbk", optional: true, emit: gbk
    script:
        def database =  annotation_database.name.startsWith('OPTIONAL_FILE') ? "Default" : "${annotation_database}"
    """
    workflow-glue run_plannotate --sequences corrected.fasta --database $database
    """
}

process report {
    label "plasmid"
    cpus 1
    memory "2GB"
    input:
        path "downsampled_stats/*"
        path final_status
        path "per_barcode_stats/*"
        path "host_filter_stats/*"
        path "versions/*"
        path "params.json"
        path plannotate_json
        path inserts_json
        path lengths
        path "qc_inserts/*"
        path "assembly_quality/*"
        path "mafs/*"
    output:
        path "wf-clone-validation-*.html", emit: html
        path "sample_status.txt", emit: sample_stat
        path "inserts/*", optional: true, emit: inserts
    script:
        report_name = "wf-clone-validation-report.html"
    """
    workflow-glue report \
     $report_name \
    --downsampled_stats downsampled_stats/* \
    --revision $workflow.revision \
    --commit $workflow.commitId \
    --status $final_status \
    --per_barcode_stats per_barcode_stats/* \
    --host_filter_stats host_filter_stats/* \
    --params params.json \
    --versions versions \
    --plannotate_json $plannotate_json \
    --lengths $lengths \
    --inserts_json $inserts_json \
    --qc_inserts qc_inserts \
    --assembly_quality assembly_quality/* \
    --mafs mafs
    """
}