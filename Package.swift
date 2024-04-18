// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HXPhotoPicker",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "HXPhotoPicker",
            targets: ["HXPhotoPicker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "HXPhotoPicker",
            dependencies: ["Kingfisher"],
            resources: [
                .process("Resources/HXPhotoPicker.bundle"),
                .copy("Resources/PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .define("HXPICKER_ENABLE_SPM"),
                .define("HXPICKER_ENABLE_PICKER"),
                .define("HXPICKER_ENABLE_EDITOR"),
                .define("HXPICKER_ENABLE_CAMERA")
            ]),
    ]
)
