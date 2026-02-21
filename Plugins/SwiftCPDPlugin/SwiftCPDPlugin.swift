import PackagePlugin

@main
struct SwiftCPDPlugin: BuildToolPlugin {

    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        guard
            let sourceTarget = target as? SourceModuleTarget
        else {
            return []
        }

        let tool = try context.tool(named: "swift-cpd")
        let outputPath = context.pluginWorkDirectoryURL.appending(path: "swift-cpd.marker")
        let cacheDir = context.pluginWorkDirectoryURL.appending(path: "cache").path()
        let profrawPath = context.pluginWorkDirectoryURL.appending(path: "default.profraw").path()

        return [
            .buildCommand(
                displayName: "SwiftCPD: Detecting clones in \(sourceTarget.name)",
                executable: tool.url,
                arguments: [
                    "--format", "xcode",
                    "--cache-dir", cacheDir,
                    "--output", outputPath.path(),
                    sourceTarget.directoryURL.path(),
                ],
                environment: [
                    "LLVM_PROFILE_FILE": profrawPath
                ],
                outputFiles: [outputPath]
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension SwiftCPDPlugin: XcodeBuildToolPlugin {
        func createBuildCommands(
            context: XcodePluginContext,
            target: XcodeTarget
        ) throws -> [Command] {
            let tool = try context.tool(named: "swift-cpd")
            let outputPath = context.pluginWorkDirectoryURL.appending(path: "swift-cpd.marker")
            let cacheDir = context.pluginWorkDirectoryURL.appending(path: "cache").path()
            let profrawPath = context.pluginWorkDirectoryURL.appending(path: "default.profraw").path()

            return [
                .buildCommand(
                    displayName: "SwiftCPD: Detecting clones",
                    executable: tool.url,
                    arguments: [
                        "--format", "xcode",
                        "--cache-dir", cacheDir,
                        "--output", outputPath.path(),
                        context.xcodeProject.directoryURL.path(),
                    ],
                    environment: [
                        "LLVM_PROFILE_FILE": profrawPath
                    ],
                    outputFiles: [outputPath]
                )
            ]
        }
    }
#endif
