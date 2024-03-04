process getParams {
    label "wfplasmid"
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

process downsampledStats {
    label "plasmid"
    cpus 1
    memory "2GB"
    input:
        tuple val(meta), path('downsampled.fastq.gz')
    output:
        path "*.stats", optional: true
    """
    fastcat -s ${meta.} -r ${sample_id}.downsampled $sample > /dev/null
    if [[ "\$(wc -l <"${sample_id}.downsampled")" -ge "2" ]];  then
        mv ${sample_id}.downsampled ${sample_id}.stats
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
        path "${meta.alias}.assembly_stats.tsv"
    script:
    """
    fastcat -s "${meta.alias}" -r "${meta.alias}.assembly_stats.tsv" assembly.fastq
    """
}
process fastcat {
    label "wf_common"
    cpus 3
    memory "2 GB"
    input:
        tuple val(meta), path("input")
    output:
        tuple val(meta), path("seqs.fastq.gz"), path("fastcat_stats")
    script:
        String out = "seqs.fastq.gz"
        String fastcat_stats_outdir = "fastcat_stats"
        """
        mkdir $fastcat_stats_outdir
        fastcat \
            -s ${meta.alias} \
            -r >(bgzip -c > per-read-stats.tsv.gz) \
            -f per-file-stats.tsv \
            input \
            | bgzip > $out

        # extract the run IDs from the per-read stats
        csvtk cut -tf runid per-read-stats.tsv.gz \
        | csvtk del-header | sort | uniq > run_ids
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
