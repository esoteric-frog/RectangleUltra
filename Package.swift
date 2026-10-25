// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "RectangleUltra",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "RectangleUltra", targets: ["Rectangle"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rxhanson/MASShortcut",
                 revision: "2f9fbb3f959b7a683c6faaf9638d22afad37a235"),
    ],
    targets: [
        .target(name: "CAXPrivate", path: "Sources/CAXPrivate"),
        .executableTarget(
            name: "Rectangle",
            dependencies: ["CAXPrivate", .product(name: "MASShortcut", package: "MASShortcut")],
            path: "Rectangle",
            exclude: [
                "Info.plist", "InternetAccessPolicy.plist",
                "Rectangle.entitlements", "RectangleRelease.entitlements",
                "Assets.xcassets", "AppIcon.icon", "Localizable.xcstrings",
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(name: "XCTestShim", path: "Tests/XCTestShim",
                swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "RectangleTests", dependencies: ["Rectangle", "XCTestShim"],
                    path: "RectangleTests", exclude: ["Info.plist"],
                    swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
