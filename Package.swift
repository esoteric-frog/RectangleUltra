// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "RectangleUltra",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "RectangleUltra", targets: ["Rectangle"]),
    ],
    dependencies: [
        // rxhanson/MASShortcut @ 2f9fbb3f, vendored: MASLocalization.m finds its bundle in Contents/Resources.
        .package(path: "Vendor/MASShortcut"),
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
                "Assets.xcassets",
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
