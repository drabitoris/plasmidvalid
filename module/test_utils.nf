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
}@Test
void testAssemblyStatProcessWithValidInput() {
    def meta = [alias: "sample"]
    def assemblyFastqPath = "/path/to/assembly.fastq"
    def expectedOutputPath = "/path/to/sample.assembly_stats.tsv"

    def process = assemblyStat
    process.meta = meta
    process."assembly.fastq" = assemblyFastqPath

    process.run()

    assert process."${meta.alias}.assembly_stats.tsv" == expectedOutputPath
}

@Test
void testAssemblyStatProcessWithInvalidInput() {
    def meta = [alias: "sample"]
    def assemblyFastqPath = "/path/to/nonexistent.fastq"

    def process = assemblyStat
    process.meta = meta
    process."assembly.fastq" = assemblyFastqPath

    def exception = shouldFail(IllegalArgumentException) {
        process.run()
    }

    assert exception.message == "Input file not found: ${assemblyFastqPath}"
}import org.junit.Test

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

    @Test
    void testAssemblyStatProcessWithDifferentAlias() {
        def meta = [alias: "another_sample"]
        def assemblyFastqPath = "/path/to/another_assembly.fastq"
        def expectedOutputPath = "/path/to/another_sample.assembly_stats.tsv"

        def process = assemblyStat
        process.meta = meta
        process."assembly.fastq" = assemblyFastqPath

        process.run()

        assert process."${meta.alias}.assembly_stats.tsv" == expectedOutputPath
    }
}