import Foundation

struct SourceFileDiscovery: Sendable {

    init(crossLanguageEnabled: Bool, excludePatterns: [String] = []) {
        self.crossLanguageEnabled = crossLanguageEnabled
        self.globMatcher = GlobMatcher(patterns: excludePatterns)
    }

    let crossLanguageEnabled: Bool
    private let globMatcher: GlobMatcher

    private let excludedDirectoryNames: Set<String> = [
        ".build",
        ".git",
        "DerivedData",
        "Pods",
        "Carthage",
        "SourcePackages",
    ]

    private let swiftExtensions: Set<String> = ["swift"]

    private let cFamilyExtensions: Set<String> = ["m", "mm", "h", "c", "cpp"]

    func findSourceFiles(in paths: [String]) throws -> [String] {
        var results: [String] = []

        for path in paths {
            let resolvedPath = resolvePath(path)
            var isDirectory: ObjCBool = false

            guard
                FileManager.default.fileExists(atPath: resolvedPath, isDirectory: &isDirectory)
            else {
                throw FileDiscoveryError.pathDoesNotExist(path)
            }

            if isDirectory.boolValue {
                let files = try findSourceFilesInDirectory(resolvedPath)
                results.append(contentsOf: files)
            } else if isValidSourceFile(resolvedPath) {
                results.append(resolvedPath)
            }
        }

        return results.sorted()
    }
}

extension SourceFileDiscovery {

    private func resolvePath(_ path: String) -> String {
        if path.hasPrefix("/") {
            return path
        }

        return FileManager.default.currentDirectoryPath + "/" + path
    }

    private func findSourceFilesInDirectory(_ directory: String) throws -> [String] {
        let url = URL(fileURLWithPath: directory)

        let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )!

        var files: [String] = []

        for case let fileURL as URL in enumerator {
            let resourceValues = try? fileURL.resourceValues(forKeys: [.isSymbolicLinkKey])

            if resourceValues?.isSymbolicLink == true {
                continue
            }

            if shouldExclude(fileURL) {
                enumerator.skipDescendants()
                continue
            }

            if isValidExtension(fileURL.pathExtension) {
                files.append(fileURL.path)
            }
        }

        return files
    }

    private func shouldExclude(_ url: URL) -> Bool {
        let lastComponent = url.lastPathComponent

        if excludedDirectoryNames.contains(lastComponent) {
            return true
        }

        return globMatcher.matches(url.path)
    }

    private func isValidSourceFile(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension
        return isValidExtension(ext)
    }

    private func isValidExtension(_ ext: String) -> Bool {
        if swiftExtensions.contains(ext) {
            return true
        }

        if crossLanguageEnabled, cFamilyExtensions.contains(ext) {
            return true
        }

        return false
    }
}
