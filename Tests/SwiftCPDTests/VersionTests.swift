import Testing

@testable import swift_cpd

@Suite("Version")
struct VersionTests {

    @Test("Given Version, when accessing current, then returns non-empty string")
    func versionIsNotEmpty() {
        #expect(!Version.current.isEmpty)
    }
}
