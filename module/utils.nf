process getParams {
    label "plasmid"
    cpus 1
    memory "2GB"
    output:
        path "params.json"
    script:
        def paramsJSON = new JsonBuilder(params).toPrettyString()
    """
    # Output nextflow params object to JSON
    echo '$paramsJSON' > params.json
    """
}

process medakaVersion {
    label "medaka"
    cpus 1 
    memory "2GB"
    output:
        path "medaka_version.txt"
    """
    medaka --version | sed 's/ /,/' >> "medaka_version.txt"
    """
}

process getVersions {
    label "plasmid"
    cpus 1
    memory "2GB"
    input:
        path "input_versions.txt"
    output:
        path "versions.txt"
    script:
    """
    cat "input_versions.txt" >> "versions.txt"
    minimap2 --version | sed 's/^/minimap2,/' >> versions.txt
    samtools --version | head -n 1 | sed 's/ /,/' >> versions.txt
    dupscoop --version | sed 's/ /,/' >> versions.txt
    bedtools --version | sed 's/ /,/' >> versions.txt
    flye --version |  sed 's/^/flye,/' >> versions.txt
    fastcat --version | sed 's/^/fastcat,/' >> versions.txt
    rasusa --version | sed 's/ /,/' >> versions.txt
    python -c "import spoa; print(spoa.__version__)" | sed 's/^/spoa,/'  >> versions.txt
    python -c "import pandas; print(pandas.__version__)" | sed 's/^/pandas,/'  >> versions.txt
    python -c "import plannotate; print(plannotate.__version__)" | sed 's/^/plannotate,/'  >> versions.txt
    python -c "import bokeh; print(bokeh.__version__)" | sed 's/^/bokeh,/'  >> versions.txt
    """
}

process sampleStat {
    label "plasmid"
    cpus 3
    memory "2 GB"
    input:
        tuple val(meta), path('basecalled.fastq')
    output:
        path("*.stats.tsv"), optional: true
    script:
    """
    fastcat -s "${meta.alias}" -r "${meta.alias}.stats.tsv" basecalled.fastq
    """
}

process downsampledStats {
    label "plasmid"
    cpus 1
    memory "2GB"
    input:
        tuple val(meta), path('downsampled.fastq.gz')
    output:
        path "*.stats", optional: true
    """
    fastcat -s ${meta.alias} -r ${meta.alias}.downsampled $sample > /dev/null
    if [[ "\$(wc -l <"${meta.alias}.downsampled")" -ge "2" ]];  then
        mv ${meta.alias}.downsampled ${meta.alias}.stats
    fi
    """
}

process assemblyStat {
    label "plasmid"
    cpus 1
    memory "2GB"
    input:
        tuple val(meta), path("assembly.fastq")
    output:
        path "*.stats.tsv", optional: true
    script:
    """
    fastcat -s "${meta.alias}" -r "${meta.alias}.stats.tsv" assembly.fastq
    """
}

process perReadstats {
    label "plasmid"
    cpus params.threads
    memory "2GB"
    input:
        tuple val(meta),
            path("basecalled.fastq"),
            path("per-read-stats.tsv.gz"),
            val(approx_size)
        val extra_args
    output:
        tuple val(meta.alias), path("${meta.alias}.fastq.gz"), val(approx_size),
            optional: true, emit: sample
        path "${meta.alias}.stats.gz", emit: stats
        tuple val(meta.alias), env(STATUS), emit: status
    script:
        def expected_depth = "$params.assm_coverage"
        // a little heuristic to decide if we have enough data
        int value = (expected_depth.toInteger()) * 0.8
        int bgzip_threads = task.cpus == 1 ? 1 : task.cpus - 1
    """
    fastcat -s ${meta.alias} -r ${meta.alias}.interim input.fastq.gz \
    | bgzip -@ $bgzip_threads > interim.fastq.gz
    if [[ "\$(wc -l < "${meta.alias}.interim")" -ge "$value" ]]; then
        mv interim.fastq.gz ${meta.alias}.fastq.gz
        STATUS="Completed successfully"
    fi
    """
}
