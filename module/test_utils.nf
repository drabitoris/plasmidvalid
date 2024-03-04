import org.junit.Test

class AssemblyStatTest {
    @Test
    void testAssemblyStatProcess() {
        def meta = [alias: "sample"]
        def assemblyFastqPath = "/path/to/assembly.fastq"
        def expectedOutputPath = "/path/to/sample.assembly_stats.tsv"

        def process = assemblyStat
        process.meta = meta
        process."assembly.fastq" = assemblyFastqPath

        process.run()

        assert process."${meta.alias}.assembly_stats.tsv" == expectedOutputPath
    }
}