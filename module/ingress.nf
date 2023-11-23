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
