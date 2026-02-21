enum YamlConfigurationError: Error, Sendable, Equatable, CustomStringConvertible {

    case fileNotReadable(String)
    case invalidYaml(String)

    var description: String {
        switch self {
        case .fileNotReadable(let path):
            "cannot read configuration file '\(path)'"

        case .invalidYaml(let path):
            "invalid YAML in configuration file '\(path)'"
        }
    }
}
