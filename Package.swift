// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftCPD",
    platforms: [
        .macOS(.v15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1),
    ],
    products: [
        .executable(name: "swift-cpd", targets: ["swift-cpd"]),
        .plugin(name: "SwiftCPDPlugin", targets: ["SwiftCPDPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "swift-cpd",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux])),
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
