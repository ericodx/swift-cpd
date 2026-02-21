import Foundation

@main
struct SwiftCPD {

    static func main() async {
        let parser = ArgumentParser()

        let parsed: ParsedArguments
        do {
            parsed = try parser.parse(CommandLine.arguments)
        } catch {
            printError(error)
            exit(ExitCode.configurationError.rawValue)
        }

        if parsed.showVersion {
            print(Version.current)
            exit(ExitCode.success.rawValue)
        }

        if parsed.showHelp {
            print(HelpText.usage)
            exit(ExitCode.success.rawValue)
        }

        if parsed.showInit {
            let exitCode = handleInit()
            exit(exitCode.rawValue)
        }

        let yamlConfig: YamlConfiguration?
        do {
            yamlConfig = try loadYamlConfiguration(parsed)
        } catch {
            printError(error)
            exit(ExitCode.configurationError.rawValue)
        }

        let configuration: Configuration
        do {
            configuration = try Configuration(from: parsed, yaml: yamlConfig)
        } catch {
            printError(error)
            print(HelpText.usage)
            exit(ExitCode.configurationError.rawValue)
        }

        do {
            let exitCode = try await runAnalysis(configuration)
            exit(exitCode.rawValue)
        } catch {
            printError(error)
            exit(ExitCode.analysisError.rawValue)
        }
    }
}

extension SwiftCPD {

    private static func runAnalysis(_ configuration: Configuration) async throws -> ExitCode {
        let discovery = SourceFileDiscovery(
            crossLanguageEnabled: configuration.crossLanguageEnabled,
            excludePatterns: configuration.excludePatterns
        )
        let files = try discovery.findSourceFiles(in: configuration.paths)

        guard
            !files.isEmpty
        else {
            printError("No source files found in the specified paths.")
            return .configurationError
        }

        let pipeline = buildPipeline(from: configuration)

        let progressReporter = ProgressReporter(totalFiles: files.count)

        if configuration.outputFormat == .text {
            progressReporter.start()
        }

        let startTime = Date()
        let pipelineResult = try await pipeline.analyze(files: files)
        let executionTime = Date().timeIntervalSince(startTime)

        await progressReporter.stop()

        let cloneGroups = filterCloneGroups(pipelineResult.cloneGroups, configuration: configuration)

        let result = AnalysisResult(
            cloneGroups: cloneGroups,
            filesAnalyzed: files.count,
            executionTime: executionTime,
            totalTokens: pipelineResult.totalTokens,
            minimumTokenCount: configuration.minimumTokenCount,
            minimumLineCount: configuration.minimumLineCount
        )

        switch configuration.baselineMode {
        case .generate:
            return try handleBaselineSave(result, configuration, action: "generated")

        case .update:
            return try handleBaselineSave(result, configuration, action: "updated")

        case .compare:
            return try handleBaselineCompare(result, configuration)

        case .none:
            return handleReport(result, configuration)
        }
    }

    private static func handleReport(
        _ result: AnalysisResult,
        _ configuration: Configuration
    ) -> ExitCode {
        let reporter = makeReporter(configuration.outputFormat)
        let output = reporter.report(result)

        if configuration.outputFormat == .xcode {
            print(output)
            writeMarkerFile(to: configuration.outputFilePath)
            return .success
        }

        writeOutput(output, to: configuration.outputFilePath)

        if let threshold = configuration.maxDuplication {
            let duplicatedTokens = result.cloneGroups.reduce(0) { $0 + $1.tokenCount }
            let percentage = DuplicationCalculator.percentage(
                duplicatedTokens: duplicatedTokens,
                totalTokens: result.totalTokens
            )
            return percentage > threshold ? .clonesDetected : .success
        }

        return result.cloneGroups.isEmpty ? .success : .clonesDetected
    }

    private static func handleBaselineSave(
        _ result: AnalysisResult,
        _ configuration: Configuration,
        action: String
    ) throws -> ExitCode {
        let store = BaselineStore()
        let entries = store.entriesFromCloneGroups(result.cloneGroups)
        try store.save(entries, to: configuration.baselineFilePath)
        print("Baseline \(action) with \(entries.count) clone(s) at \(configuration.baselineFilePath)")
        return .success
    }

    private static func handleBaselineCompare(
        _ result: AnalysisResult,
        _ configuration: Configuration
    ) throws -> ExitCode {
        let store = BaselineStore()
        let baseline = try store.load(from: configuration.baselineFilePath)
        let newClones = store.filterNewClones(result.cloneGroups, baseline: baseline)

        let filteredResult = AnalysisResult(
            cloneGroups: newClones,
            filesAnalyzed: result.filesAnalyzed,
            executionTime: result.executionTime,
            totalTokens: result.totalTokens,
            minimumTokenCount: result.minimumTokenCount,
            minimumLineCount: result.minimumLineCount
        )

        let reporter = makeReporter(configuration.outputFormat)
        let output = reporter.report(filteredResult)
        writeOutput(output, to: configuration.outputFilePath)

        if let threshold = configuration.maxDuplication {
            let duplicatedTokens = newClones.reduce(0) { $0 + $1.tokenCount }
            let percentage = DuplicationCalculator.percentage(
                duplicatedTokens: duplicatedTokens,
                totalTokens: result.totalTokens
            )
            return percentage > threshold ? .clonesDetected : .success
        }

        return newClones.isEmpty ? .success : .clonesDetected
    }
}

extension SwiftCPD {

    private static func buildPipeline(from configuration: Configuration) -> AnalysisPipeline {
        AnalysisPipeline(
            minimumTokenCount: configuration.minimumTokenCount,
            minimumLineCount: configuration.minimumLineCount,
            cacheDirectory: configuration.cacheDirectory,
            crossLanguageEnabled: configuration.crossLanguageEnabled,
            thresholds: DetectionThresholds(
                type3Similarity: configuration.type3Similarity,
                type3TileSize: configuration.type3TileSize,
                type3CandidateThreshold: configuration.type3CandidateThreshold,
                type4Similarity: configuration.type4Similarity
            ),
            inlineSuppressionTag: configuration.inlineSuppressionTag,
            enabledCloneTypes: configuration.enabledCloneTypes
        )
    }

    private static func filterCloneGroups(
        _ cloneGroups: [CloneGroup],
        configuration: Configuration
    ) -> [CloneGroup] {
        var filtered = cloneGroups

        if configuration.ignoreSameFile {
            filtered = filtered.filter { !$0.isSameFile }
        }

        if configuration.ignoreStructural {
            filtered = filtered.filter { !$0.isStructural }
        }

        return filtered
    }

    private static func handleInit() -> ExitCode {
        let filePath = ".swift-cpd.yml"

        guard
            !FileManager.default.fileExists(atPath: filePath)
        else {
            printError("\(filePath) already exists.")
            return .configurationError
        }

        let content = """
            paths:
              - Sources/
            minimumTokenCount: 50
            minimumLineCount: 5
            outputFormat: text
            type3Similarity: 70
            type4Similarity: 80
            exclude: []
            ignoreSameFile: true
            ignoreStructural: true
            enabledCloneTypes:
              - 1
              - 2
              - 3
              - 4
            """

        do {
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
            print("Created \(filePath)")
            return .success
        } catch {
            printError(error)
            return .analysisError
        }
    }

    private static func makeReporter(_ format: OutputFormat) -> any Reporter {
        switch format {
        case .text:
            TextReporter()

        case .json:
            JsonReporter()

        case .html:
            HtmlReporter()

        case .xcode:
            XcodeReporter()
        }
    }

    private static func writeOutput(_ output: String, to filePath: String?) {
        if let filePath {
            try? output.write(toFile: filePath, atomically: true, encoding: .utf8)
        } else {
            print(output)
        }
    }

    private static func writeMarkerFile(to filePath: String?) {
        guard
            let filePath
        else {
            return
        }

        let url = URL(fileURLWithPath: filePath)
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? Data().write(to: url)
    }

    private static func printError(_ error: any Error) {
        fputs("error: \(error)\n", stderr)
    }

    private static func printError(_ message: String) {
        fputs("error: \(message)\n", stderr)
    }

    private static func loadYamlConfiguration(
        _ parsed: ParsedArguments
    ) throws -> YamlConfiguration? {
        let loader = YamlConfigurationLoader()

        if let explicitPath = parsed.configFilePath {
            return try loader.load(from: explicitPath)
        }

        return try loader.loadIfExists(from: ".swift-cpd.yml")
    }
}
