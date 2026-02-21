// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftCPD",
    platforms: [
        .macOS(.v15),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        .plugin(name: "SwiftCPDPlugin", targets: ["SwiftCPDPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0")
    ],
    targets: [
        .executableTarget(
            name: "swift-cpd",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SwiftCPDTests",
            dependencies: ["swift-cpd"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .plugin(
            name: "SwiftCPDPlugin",
            capability: .buildTool(),
            dependencies: ["swift-cpd"]
        ),
    ]
)
