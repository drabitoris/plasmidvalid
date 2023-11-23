/**
 * Create a map that contains at least these keys: `[alias, barcode, type]`.
 * `alias` is required, `barcode` and `type` are filled with default values if
 * missing. Additional entries are allowed.
 *
 * @param arguments: map with input parameters; must contain `alias`
 * @return: map(alias, barcode, type, ...)
 */

Map create_metamap(Map arguments) {
    ArgumentParser parser = new ArgumentParser(
        args: ["alias"],
        kwargs: [
            "barcode": null,
            "type": "test_sample",
            "run_ids": [],
        ],
        name: "create_metamap",
    )
    def metamap = parser.parse_known_args(arguments)
    metamap['alias'] = metamap['alias'].replaceAll(" ","_")
    return metamap
}

/**
 * Check the sample sheet and return a channel with its rows if it is valid.
 *
 * @param sample_sheet: path to the sample sheet CSV
 * @return: channel of maps (with values in sample sheet header as keys)
 */
def get_sample_sheet(Path sample_sheet, ArrayList required_sample_types) {
    // If `validate_sample_sheet` does not return an error message, we can assume that
    // the sample sheet is valid and parse it. However, because of Nextflow's
    // asynchronous magic, we might emit values from `.splitCSV()` before the
    // error-checking closure finishes. This is no big deal, but undesired nonetheless
    // as the error message might be overwritten by the traces of new nextflow processes
    // in STDOUT. Thus, we use the somewhat clunky construct with `concat` and `last`
    // below. This lets the CSV channel only start to emit once the error checking is
    // done.
    ch_err = validate_sample_sheet(sample_sheet, required_sample_types).map {
        // check if there was an error message
        if (it) error "Invalid sample sheet: ${it}."
        it
    }
    // concat the channel holding the path to the sample sheet to `ch_err` and call
    // `.last()` to make sure that the error-checking closure above executes before
    // emitting values from the CSV
    return ch_err.concat(Channel.fromPath(sample_sheet)).last().splitCsv(
        header: true, quote: '"'
    )
}
