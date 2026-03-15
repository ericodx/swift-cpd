import Testing

@testable import swift_cpd

@Suite("HelpText")
struct HelpTextTests {

    @Test("Given help text, when accessed, then contains usage information")
    func containsUsageInformation() {
        let usage = HelpText.usage

        #expect(usage.contains("USAGE:"))
        #expect(usage.contains("swift-cpd"))
        #expect(usage.contains("--min-tokens"))
        #expect(usage.contains("--format"))
        #expect(usage.contains("--help"))
    }
}
