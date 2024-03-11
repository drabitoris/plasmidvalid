import groovy.json.JsonBuilder

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
    fastcat -s ${meta.alias} -r ${meta.alias}.downsampled downsampled.fastq.gz > /dev/null
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
        tuple val(meta), path("polished.fasta")
    output:
        path "*.stats.tsv", optional: true
    script:
    """
    fastcat -s "${meta.alias}" -r "${meta.alias}.stats.tsv" polished.fasta
    """
}

process exampleStatus {
    label "plasmid"
    output:
        env(STATUS), emit: status
    script:
    """
    STATUS="boo_STATUS"
    """
}

process assemblyMafs {
    label "plasmid"
    cpus 1
    memory "2GB"
    input:
        tuple val(meta), path("assembly.fasta")
    output:
        tuple val(meta), path("${meta.alias}.assembly.maf")
    // set -m(multiplicity) to 10000 to increase sensitivity from default of 10
    // for assemblies this small computational cost is low
    // reduce offset distance for suppressing repeats inside exact matches -w 
    // from default of 1000 to 10.
    """
    lastdb db.lastdb "assembly.fasta"
    lastal -m 10000 -w 10 db.lastdb "assembly.fasta" > "${meta.alias}.assembly.maf"
    """
}