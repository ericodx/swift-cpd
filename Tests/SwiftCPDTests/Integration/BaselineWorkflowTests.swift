import Foundation
import Testing

@testable import swift_cpd

@Suite("BaselineWorkflow")
struct BaselineWorkflowTests {

    let store = BaselineStore()

    @Test(
        "Given analysis with clones, when generating baseline, then file contains all entries"
    )
    func generateBaseline() async throws {
        let tempDir = createTempDirectory(prefix: "BaselineWorkflow")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)
        let result = try await analyzeDirectory(tempDir)

        let baselinePath = tempDir + "/baseline.json"
        let entries = store.entriesFromCloneGroups(result.cloneGroups)
        try store.save(entries, to: baselinePath)

        let loaded = try store.load(from: baselinePath)
        #expect(loaded.count == entries.count)
        #expect(loaded == entries)
    }

    @Test(
        "Given baseline file, when comparing same analysis, then no new clones reported"
    )
    func compareWithSameClones() async throws {
        let tempDir = createTempDirectory(prefix: "BaselineWorkflow")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)
        let result = try await analyzeDirectory(tempDir)

        let baselinePath = tempDir + "/baseline.json"
        let entries = store.entriesFromCloneGroups(result.cloneGroups)
        try store.save(entries, to: baselinePath)

        let baseline = try store.load(from: baselinePath)
        let newClones = store.filterNewClones(
            result.cloneGroups,
            baseline: baseline
        )

        #expect(newClones.isEmpty)
    }

    @Test(
        "Given baseline file, when new clone appears, then only new clone is reported"
    )
    func detectNewClone() async throws {
        let tempDir = createTempDirectory(prefix: "BaselineWorkflow")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)
        let initialResult = try await analyzeDirectory(tempDir, cacheLabel: "initial")

        let baselinePath = tempDir + "/baseline.json"
        let entries = store.entriesFromCloneGroups(initialResult.cloneGroups)
        try store.save(entries, to: baselinePath)

        try additionalDuplicateSource.write(
            toFile: tempDir + "/C.swift",
            atomically: true,
            encoding: .utf8
        )

        let updatedResult = try await analyzeDirectory(tempDir, cacheLabel: "updated")
        let baseline = try store.load(from: baselinePath)
        let newClones = store.filterNewClones(
            updatedResult.cloneGroups,
            baseline: baseline
        )

        #expect(updatedResult.cloneGroups.count > initialResult.cloneGroups.count)
        #expect(!newClones.isEmpty)
        #expect(newClones.count < updatedResult.cloneGroups.count)
    }

    @Test(
        "Given baseline file, when updating with new clones, then baseline reflects current state"
    )
    func updateBaseline() async throws {
        let tempDir = createTempDirectory(prefix: "BaselineWorkflow")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)
        let initialResult = try await analyzeDirectory(tempDir, cacheLabel: "initial")

        let baselinePath = tempDir + "/baseline.json"
        let initialEntries = store.entriesFromCloneGroups(
            initialResult.cloneGroups
        )
        try store.save(initialEntries, to: baselinePath)

        try additionalDuplicateSource.write(
            toFile: tempDir + "/C.swift",
            atomically: true,
            encoding: .utf8
        )

        let updatedResult = try await analyzeDirectory(tempDir, cacheLabel: "updated")
        let updatedEntries = store.entriesFromCloneGroups(
            updatedResult.cloneGroups
        )
        try store.save(updatedEntries, to: baselinePath)

        let reloaded = try store.load(from: baselinePath)
        let finalNewClones = store.filterNewClones(
            updatedResult.cloneGroups,
            baseline: reloaded
        )

        #expect(finalNewClones.isEmpty)
        #expect(reloaded.count == updatedEntries.count)
    }

    @Test(
        "Given non-existent baseline path, when comparing, then all clones treated as new"
    )
    func nonExistentBaselineTreatsAllAsNew() async throws {
        let tempDir = createTempDirectory(prefix: "BaselineWorkflow")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)
        let result = try await analyzeDirectory(tempDir)

        let baseline = try store.load(from: tempDir + "/missing.json")
        let newClones = store.filterNewClones(
            result.cloneGroups,
            baseline: baseline
        )

        #expect(newClones.count == result.cloneGroups.count)
    }
}
