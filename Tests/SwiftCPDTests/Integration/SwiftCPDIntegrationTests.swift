import Foundation
import Testing

@Suite("SwiftCPDIntegration")
struct SwiftCPDIntegrationTests {

    private let minArgs = ["--min-tokens", "10", "--min-lines", "2"]

    @Test("Given --version flag, when running, then prints version and exits 0")
    func versionFlag() throws {
        let result = try runSwiftCPD(["--version"])

        #expect(result.exitCode == 0)
        #expect(!result.stdout.isEmpty)
    }

    @Test("Given --help flag, when running, then prints usage and exits 0")
    func helpFlag() throws {
        let result = try runSwiftCPD(["--help"])

        #expect(result.exitCode == 0)
        #expect(result.stdout.contains("USAGE:"))
    }

    @Test("Given duplicate files, when analyzing, then exits with clones detected code")
    func duplicateFilesDetected() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let result = try runSwiftCPD(minArgs + [tempDir])

        #expect(result.exitCode == 1)
    }

    @Test("Given --format json, when analyzing, then produces valid JSON output")
    func jsonFormat() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let result = try runSwiftCPD(["--format", "json"] + minArgs + [tempDir])

        #expect(result.stdout.contains("\"clones\""))
        #expect(result.stdout.contains("\"summary\""))
    }

    @Test("Given --format html with --output, when analyzing, then writes file")
    func htmlOutputToFile() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let outputPath = tempDir + "/report.html"
        let result = try runSwiftCPD(["--format", "html", "--output", outputPath] + minArgs + [tempDir])

        #expect(result.exitCode == 1)
        #expect(FileManager.default.fileExists(atPath: outputPath))
    }

    @Test("Given --baseline-generate, when analyzing, then creates baseline file")
    func baselineGenerate() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let baselinePath = tempDir + "/baseline.json"
        let result = try runSwiftCPD(["--baseline-generate", "--baseline", baselinePath] + minArgs + [tempDir])

        #expect(result.exitCode == 0)
        #expect(FileManager.default.fileExists(atPath: baselinePath))
        #expect(result.stdout.contains("Baseline generated"))
    }

    @Test("Given --baseline with existing baseline, when analyzing same files, then no new clones")
    func baselineCompare() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let baselinePath = tempDir + "/baseline.json"
        _ = try runSwiftCPD(["--baseline-generate", "--baseline", baselinePath] + minArgs + [tempDir])

        let result = try runSwiftCPD(["--baseline", baselinePath] + minArgs + [tempDir])

        #expect(result.exitCode == 0)
    }

    @Test("Given --baseline-update, when analyzing, then updates baseline file")
    func baselineUpdate() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let baselinePath = tempDir + "/baseline.json"
        _ = try runSwiftCPD(["--baseline-generate", "--baseline", baselinePath] + minArgs + [tempDir])

        let result = try runSwiftCPD(["--baseline-update", "--baseline", baselinePath] + minArgs + [tempDir])

        #expect(result.exitCode == 0)
        #expect(result.stdout.contains("Baseline updated"))
    }

    @Test("Given --max-duplication with low threshold, when analyzing duplicates, then exits with clones detected")
    func maxDuplicationThreshold() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let result = try runSwiftCPD(["--max-duplication", "1"] + minArgs + [tempDir])

        #expect(result.exitCode == 1)
    }

    @Test("Given unknown flag, when running, then exits with error")
    func unknownFlag() throws {
        let result = try runSwiftCPD(["--nonexistent-flag"])

        #expect(result.exitCode == 2)
        #expect(result.stderr.contains("error"))
    }

    @Test("Given no paths, when running, then exits with error")
    func noPaths() throws {
        let result = try runSwiftCPD([])

        #expect(result.exitCode == 2)
    }

    @Test("Given nonexistent path, when running, then exits with error")
    func nonexistentPath() throws {
        let result = try runSwiftCPD(["/nonexistent/path/to/nowhere"])

        #expect(result.exitCode == 3)
        #expect(result.stderr.contains("error"))
    }

    @Test("Given --format xcode, when analyzing duplicates, then output has warning format")
    func xcodeFormat() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let result = try runSwiftCPD(["--format", "xcode"] + minArgs + [tempDir])

        #expect(result.exitCode == 0)
        #expect(result.stdout.contains("warning:"))
    }

    @Test("Given empty directory, when analyzing, then reports no files found")
    func emptyDirectory() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        let result = try runSwiftCPD([tempDir])

        #expect(result.exitCode == 2)
        #expect(result.stderr.contains("error"))
    }

    @Test("Given invalid YAML config file, when running, then exits with config error")
    func invalidYamlConfig() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let configPath = tempDir + "/config.yml"
        try? "invalid: [yaml: {broken".write(toFile: configPath, atomically: true, encoding: .utf8)

        let result = try runSwiftCPD(["--config", configPath] + minArgs + [tempDir])

        #expect(result.exitCode == 2)
    }

    @Test("Given --baseline with --max-duplication, when new clones exceed threshold, then exits with clones detected")
    func baselineCompareWithMaxDuplication() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let baselinePath = tempDir + "/baseline.json"
        try? "[]".write(toFile: baselinePath, atomically: true, encoding: .utf8)

        let result = try runSwiftCPD(["--baseline", baselinePath, "--max-duplication", "1"] + minArgs + [tempDir])

        #expect(result.exitCode == 1)
    }

    @Test("Given init command, when no config exists, then creates .swift-cpd.yml and exits 0")
    func initCreatesConfig() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDInit")
        defer { removeTempDirectory(tempDir) }

        let result = try runSwiftCPD(["init"], workingDirectory: tempDir)

        #expect(result.exitCode == 0)
        #expect(result.stdout.contains("Created .swift-cpd.yml"))

        let configPath = tempDir + "/.swift-cpd.yml"
        #expect(FileManager.default.fileExists(atPath: configPath))

        let content = try String(contentsOfFile: configPath, encoding: .utf8)
        #expect(content.contains("minimumTokenCount: 50"))
        #expect(content.contains("paths:"))
    }

    @Test("Given init command, when directory is read-only, then exits with analysis error")
    func initReadOnlyDirectoryReturnsError() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDInitReadOnly")
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: tempDir
            )
            removeTempDirectory(tempDir)
        }

        try FileManager.default.setAttributes(
            [.posixPermissions: 0o555],
            ofItemAtPath: tempDir
        )

        let result = try runSwiftCPD(["init"], workingDirectory: tempDir)

        #expect(result.exitCode == 3)
        #expect(result.stderr.contains("error"))
    }

    @Test("Given init command, when config already exists, then exits with error")
    func initWhenConfigExistsReturnsError() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDInit")
        defer { removeTempDirectory(tempDir) }

        let configPath = tempDir + "/.swift-cpd.yml"
        try "existing: true".write(toFile: configPath, atomically: true, encoding: .utf8)

        let result = try runSwiftCPD(["init"], workingDirectory: tempDir)

        #expect(result.exitCode == 2)
        #expect(result.stderr.contains("already exists"))
    }

    @Test("Given valid YAML config file, when running, then uses config values")
    func validYamlConfig() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let configContent = """
            min_tokens: 10
            min_lines: 2
            """
        let configPath = tempDir + "/swiftcpd.yml"
        try? configContent.write(toFile: configPath, atomically: true, encoding: .utf8)

        let result = try runSwiftCPD(["--config", configPath, tempDir])

        #expect(result.exitCode == 1)
    }

    @Test("Given --ignore-same-file, when analyzing cross-file duplicates, then still detects them")
    func ignoreSameFileWithCrossFileDuplicates() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let result = try runSwiftCPD(["--ignore-same-file"] + minArgs + [tempDir])

        #expect(result.exitCode == 1)
    }

    @Test("Given --ignore-same-file, when analyzing same-file duplicates only, then reports no clones")
    func ignoreSameFileWithSameFileDuplicates() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        let source = """
            func duplicateA() -> Int {
                let value = 42
                let result = value * 2
                let adjusted = result + 10
                let final_value = adjusted - 5
                return final_value
            }

            func duplicateB() -> Int {
                let value = 42
                let result = value * 2
                let adjusted = result + 10
                let final_value = adjusted - 5
                return final_value
            }
            """
        try source.write(toFile: tempDir + "/Single.swift", atomically: true, encoding: .utf8)

        let result = try runSwiftCPD(["--ignore-same-file", "--types", "1,2"] + minArgs + [tempDir])

        #expect(result.exitCode == 0)
    }

    @Test("Given --max-duplication with high threshold, when analyzing unique files, then exits with success")
    func maxDuplicationHighThresholdPasses() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        try uniqueSourceA.write(toFile: tempDir + "/A.swift", atomically: true, encoding: .utf8)
        try uniqueSourceB.write(toFile: tempDir + "/B.swift", atomically: true, encoding: .utf8)

        let result = try runSwiftCPD(["--max-duplication", "50", "--types", "1,2", tempDir])

        #expect(result.exitCode == 0)
    }

    @Test("Given --baseline with new clones and no max-duplication, when comparing, then exits with clones detected")
    func baselineCompareWithNewClones() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        let baselinePath = tempDir + "/baseline.json"
        try "[]".write(toFile: baselinePath, atomically: true, encoding: .utf8)

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let result = try runSwiftCPD(["--baseline", baselinePath] + minArgs + [tempDir])

        #expect(result.exitCode == 1)
    }

    @Test(
        "Given --baseline with --max-duplication high threshold, when comparing unique files, then exits with success")
    func baselineCompareWithMaxDuplicationHighThreshold() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        let baselinePath = tempDir + "/baseline.json"
        try "[]".write(toFile: baselinePath, atomically: true, encoding: .utf8)

        try uniqueSourceA.write(toFile: tempDir + "/A.swift", atomically: true, encoding: .utf8)
        try uniqueSourceB.write(toFile: tempDir + "/B.swift", atomically: true, encoding: .utf8)

        let result = try runSwiftCPD(["--baseline", baselinePath, "--max-duplication", "50", "--types", "1,2", tempDir])

        #expect(result.exitCode == 0)
    }

    @Test("Given --format xcode and --output, when analyzing duplicates, then prints warnings and creates marker file")
    func xcodeFormatWithOutputCreatesMarker() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let markerPath = tempDir + "/marker.txt"
        let result = try runSwiftCPD(["--format", "xcode", "--output", markerPath] + minArgs + [tempDir])

        #expect(result.exitCode == 0)
        #expect(result.stdout.contains("warning:"))
        #expect(FileManager.default.fileExists(atPath: markerPath))

        let markerData = try Data(contentsOf: URL(fileURLWithPath: markerPath))
        #expect(markerData.isEmpty)
    }

    @Test("Given --format xcode with no clones, when analyzing, then exits 0 with empty output")
    func xcodeFormatNoClones() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        try uniqueSourceA.write(toFile: tempDir + "/A.swift", atomically: true, encoding: .utf8)
        try uniqueSourceB.write(toFile: tempDir + "/B.swift", atomically: true, encoding: .utf8)

        let result = try runSwiftCPD(["--format", "xcode"] + minArgs + [tempDir])

        #expect(result.exitCode == 0)
    }

    @Test("Given --cache-dir, when analyzing, then writes cache to specified directory")
    func cacheDirWritesToSpecifiedDirectory() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let cacheDir = tempDir + "/custom-cache"
        let result = try runSwiftCPD(["--cache-dir", cacheDir] + minArgs + [tempDir])

        #expect(result.exitCode == 1)
        #expect(FileManager.default.fileExists(atPath: cacheDir + "/cache.json"))
    }

    @Test("Given --ignore-structural, when analyzing, then filters Type-3 and Type-4 clones")
    func ignoreStructuralFiltersAdvancedClones() throws {
        let tempDir = createTempDirectory(prefix: "SwiftCPDIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir, source: integrationDuplicateSource)

        let resultAll = try runSwiftCPD(["--format", "json"] + minArgs + [tempDir])
        let resultFiltered = try runSwiftCPD(["--ignore-structural", "--format", "json"] + minArgs + [tempDir])

        #expect(resultAll.stdout.count >= resultFiltered.stdout.count)
    }
}
