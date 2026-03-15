enum ArgumentParsingError: Error, Sendable, Equatable {

    case unknownFlag(String)
    case missingValue(String)
    case invalidIntegerValue(String, String)
    case invalidFormatValue(String)
    case invalidDuplicationValue(String)
    case invalidTypesValue(String)
}

extension ArgumentParsingError: CustomStringConvertible {

    var description: String {
        switch self {
        case .unknownFlag(let flag):
            "unknown flag '\(flag)'"

        case .missingValue(let flag):
            "missing value for '\(flag)'"

        case .invalidIntegerValue(let value, let flag):
            "invalid integer value '\(value)' for '\(flag)'"

        case .invalidFormatValue(let value):
            "invalid format '\(value)', expected: text, json, html, xcode"

        case .invalidDuplicationValue(let value):
            "invalid duplication value '\(value)', expected a number between 0 and 100"

        case .invalidTypesValue(let value):
            "invalid types value '\(value)', expected comma-separated list of: 1, 2, 3, 4"
        }
    }
}
