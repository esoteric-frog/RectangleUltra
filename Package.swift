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
                "Base.lproj", "mul.lproj",
                "Logging/LogViewer.storyboard", "Popover/MessageView.xib",
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
