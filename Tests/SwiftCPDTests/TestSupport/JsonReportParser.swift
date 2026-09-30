import Foundation

func jsonClones(in stdout: String) throws -> [[String: Any]] {
    let report = try JSONSerialization.jsonObject(with: Data(stdout.utf8)) as? [String: Any]
    return report?["clones"] as? [[String: Any]] ?? []
}
