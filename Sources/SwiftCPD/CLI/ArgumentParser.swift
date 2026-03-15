struct ArgumentParser: Sendable {

    private let booleanFlags: Set<String> = [
        "--version",
        "--help",
        "--baseline-generate",
        "--baseline-update",
        "--cross-language",
        "--ignore-same-file",
        "--ignore-structural",
    ]

    func parse(_ arguments: [String]) throws -> ParsedArguments {
        var result = ParsedArguments()
        let args = Array(arguments.dropFirst())
        var index = 0

        while index < args.count {
            let arg = args[index]

            guard
                arg.hasPrefix("--")
            else {
                if arg == "init" {
                    result.showInit = true
                } else {
                    result.paths.append(arg)
                }

                index += 1
                continue
            }

            try applyFlag(arg, to: &result, at: &index, in: args)
            index += 1
        }

        return result
    }
}

extension ArgumentParser {

    private func applyFlag(
        _ flag: String,
        to result: inout ParsedArguments,
        at index: inout Int,
        in args: [String]
    ) throws {
        if booleanFlags.contains(flag) {
            applyBooleanFlag(flag, to: &result)
            return
        }

        try applyValueFlag(flag, to: &result, at: &index, in: args)
    }

    private func applyBooleanFlag(_ flag: String, to result: inout ParsedArguments) {
        if flag == "--version" {
            result.showVersion = true
        } else if flag == "--help" {
            result.showHelp = true
        } else if flag == "--baseline-generate" {
            result.baselineGenerate = true
        } else if flag == "--baseline-update" {
            result.baselineUpdate = true
        } else if flag == "--cross-language" {
            result.crossLanguageEnabled = true
        } else if flag == "--ignore-same-file" {
            result.ignoreSameFile = true
        } else if flag == "--ignore-structural" {
            result.ignoreStructural = true
        }
    }

    private func applyValueFlag(
        _ flag: String,
        to result: inout ParsedArguments,
        at index: inout Int,
        in args: [String]
    ) throws {
        if flag.hasPrefix("--type3-") {
            try applyType3Flag(flag, to: &result, at: &index, in: args)
            return
        }

        if flag.hasPrefix("--type4-") {
            try applyType4Flag(flag, to: &result, at: &index, in: args)
            return
        }

        try applyGeneralFlag(flag, to: &result, at: &index, in: args)
    }

    private func applyGeneralFlag(
        _ flag: String,
        to result: inout ParsedArguments,
        at index: inout Int,
        in args: [String]
    ) throws {
        switch flag {
        case "--min-tokens":
            result.minimumTokenCount = try requireInteger(for: flag, at: &index, in: args)

        case "--min-lines":
            result.minimumLineCount = try requireInteger(for: flag, at: &index, in: args)

        case "--format":
            result.format = try requireFormat(for: flag, at: &index, in: args)

        case "--output":
            result.outputFilePath = try requireValue(for: flag, at: &index, in: args)

        case "--baseline":
            result.baselineFilePath = try requireValue(for: flag, at: &index, in: args)

        case "--config":
            result.configFilePath = try requireValue(for: flag, at: &index, in: args)

        case "--cache-dir":
            result.cacheDirectory = try requireValue(for: flag, at: &index, in: args)

        case "--max-duplication":
            result.maxDuplication = try requireDouble(for: flag, at: &index, in: args)

        case "--exclude":
            let pattern = try requireValue(for: flag, at: &index, in: args)
            result.excludePatterns.append(pattern)

        case "--suppression-tag":
            result.inlineSuppressionTag = try requireValue(for: flag, at: &index, in: args)

        case "--types":
            result.enabledCloneTypes = try requireCloneTypes(for: flag, at: &index, in: args)

        default:
            throw ArgumentParsingError.unknownFlag(flag)
        }
    }

    private func applyType3Flag(
        _ flag: String,
        to result: inout ParsedArguments,
        at index: inout Int,
        in args: [String]
    ) throws {
        if flag == "--type3-similarity" {
            result.type3Similarity = try requireInteger(for: flag, at: &index, in: args)
        } else if flag == "--type3-tile-size" {
            result.type3TileSize = try requireInteger(for: flag, at: &index, in: args)
        } else if flag == "--type3-candidate-threshold" {
            result.type3CandidateThreshold = try requireInteger(for: flag, at: &index, in: args)
        } else {
            throw ArgumentParsingError.unknownFlag(flag)
        }
    }

    private func applyType4Flag(
        _ flag: String,
        to result: inout ParsedArguments,
        at index: inout Int,
        in args: [String]
    ) throws {
        if flag == "--type4-similarity" {
            result.type4Similarity = try requireInteger(for: flag, at: &index, in: args)
        } else {
            throw ArgumentParsingError.unknownFlag(flag)
        }
    }

    private func requireValue(for flag: String, at index: inout Int, in args: [String]) throws -> String {
        index += 1

        guard
            index < args.count
        else {
            throw ArgumentParsingError.missingValue(flag)
        }

        return args[index]
    }

    private func requireInteger(for flag: String, at index: inout Int, in args: [String]) throws -> Int {
        let value = try requireValue(for: flag, at: &index, in: args)

        guard
            let intValue = Int(value)
        else {
            throw ArgumentParsingError.invalidIntegerValue(value, flag)
        }

        return intValue
    }

    private func requireDouble(for flag: String, at index: inout Int, in args: [String]) throws -> Double {
        let value = try requireValue(for: flag, at: &index, in: args)

        guard
            let doubleValue = Double(value),
            doubleValue >= 0,
            doubleValue <= 100
        else {
            throw ArgumentParsingError.invalidDuplicationValue(value)
        }

        return doubleValue
    }

    private func requireCloneTypes(
        for flag: String,
        at index: inout Int,
        in args: [String]
    ) throws -> Set<CloneType> {
        let value = try requireValue(for: flag, at: &index, in: args)

        if value == "all" {
            return Set(CloneType.allCases)
        }

        let parts = value.split(separator: ",")
        var types = Set<CloneType>()

        for part in parts {
            guard
                let rawValue = Int(part.trimmingCharacters(in: .whitespaces)),
                let cloneType = CloneType(rawValue: rawValue)
            else {
                throw ArgumentParsingError.invalidTypesValue(value)
            }

            types.insert(cloneType)
        }

        guard
            !types.isEmpty
        else {
            throw ArgumentParsingError.invalidTypesValue(value)
        }

        return types
    }

    private func requireFormat(for flag: String, at index: inout Int, in args: [String]) throws -> OutputFormat {
        let value = try requireValue(for: flag, at: &index, in: args)

        guard
            let format = OutputFormat(rawValue: value)
        else {
            throw ArgumentParsingError.invalidFormatValue(value)
        }

        return format
    }
}
