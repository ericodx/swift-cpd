import Foundation

@testable import swift_cpd

func loadOrderedEntries(
    from filePath: String
) throws -> [BaselineEntry] {
    let data = try Data(
        contentsOf: URL(fileURLWithPath: filePath)
    )
    return try JSONDecoder().decode(
        [BaselineEntry].self,
        from: data
    )
}
