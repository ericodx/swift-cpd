import Foundation
import Yams

struct YamlConfigurationLoader: Sendable {

    func load(from filePath: String) throws -> YamlConfiguration {
        let content: String
        do {
            content = try String(contentsOfFile: filePath, encoding: .utf8)
        } catch {
            throw YamlConfigurationError.fileNotReadable(filePath)
        }

        guard
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return YamlConfiguration(
                minimumTokenCount: nil,
                minimumLineCount: nil,
                outputFormat: nil,
                paths: nil,
                maxDuplication: nil,
                type3Similarity: nil,
                type3TileSize: nil,
                type3CandidateThreshold: nil,
                type4Similarity: nil,
                crossLanguageEnabled: nil,
                exclude: nil,
                inlineSuppressionTag: nil,
                enabledCloneTypes: nil,
                ignoreSameFile: nil,
                ignoreStructural: nil
            )
        }

        do {
            let decoder = YAMLDecoder()
            return try decoder.decode(YamlConfiguration.self, from: content)
        } catch {
            throw YamlConfigurationError.invalidYaml(filePath)
        }
    }

    func loadIfExists(from filePath: String) throws -> YamlConfiguration? {
        guard
            FileManager.default.fileExists(atPath: filePath)
        else {
            return nil
        }

        return try load(from: filePath)
    }
}
