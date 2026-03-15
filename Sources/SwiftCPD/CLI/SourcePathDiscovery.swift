import Foundation

struct SourcePathDiscovery {

    private static let excluded: Set<String> = [
        ".build", ".git", ".swiftpm", ".Trash",
        "build", "Build", "DerivedData",
        "Pods", "Carthage", "vendor", "Packages",
    ]

    func discover(in rootPath: String = ".") -> [String] {
        let fileManager = FileManager.default

        let sourcesPath = "\(rootPath)/Sources"
        if fileManager.fileExists(atPath: sourcesPath) {
            return ["Sources/"]
        }

        guard
            let contents = try? fileManager.contentsOfDirectory(atPath: rootPath)
        else {
            return ["Sources/"]
        }

        var paths: [String] = []

        for name in contents.sorted() {
            guard !name.hasPrefix("."), !Self.excluded.contains(name) else { continue }

            let fullPath = "\(rootPath)/\(name)"
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue else { continue }

            if directoryContainsSwiftFiles(fullPath) {
                paths.append("\(name)/")
            }
        }

        return paths.isEmpty ? ["Sources/"] : paths
    }

    private func directoryContainsSwiftFiles(_ path: String) -> Bool {
        let enumerator = FileManager.default.enumerator(atPath: path)

        while let entry = enumerator?.nextObject() as? String {
            if entry.hasSuffix(".swift") {
                return true
            }
        }

        return false
    }
}
