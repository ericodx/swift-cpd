import Testing

@testable import swift_cpd

@Suite("CloneType")
struct CloneTypeTests {

    @Test("Given CloneType cases, when accessing rawValue, then returns expected integers")
    func rawValues() {
        #expect(CloneType.type1.rawValue == 1)
        #expect(CloneType.type2.rawValue == 2)
        #expect(CloneType.type3.rawValue == 3)
        #expect(CloneType.type4.rawValue == 4)
    }

    @Test("Given CloneType, when listing all cases, then returns all four types")
    func allCases() {
        #expect(CloneType.allCases.count == 4)
        #expect(CloneType.allCases == [.type1, .type2, .type3, .type4])
    }

    @Test("Given valid raw value, when initializing CloneType, then returns correct case")
    func initFromRawValue() {
        #expect(CloneType(rawValue: 1) == .type1)
        #expect(CloneType(rawValue: 2) == .type2)
        #expect(CloneType(rawValue: 3) == .type3)
        #expect(CloneType(rawValue: 4) == .type4)
    }

    @Test("Given invalid raw value, when initializing CloneType, then returns nil")
    func initFromInvalidRawValue() {
        #expect(CloneType(rawValue: 0) == nil)
        #expect(CloneType(rawValue: 5) == nil)
    }
}
