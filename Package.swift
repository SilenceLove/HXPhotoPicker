// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HXPhotoPicker",
    platforms: [.iOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "HXPhotoPicker",
            targets: ["HXPhotoPicker"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "HXPhotoPicker",
            dependencies: ["Kingfisher"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .define("HXPICKER_ENABLE_SPM"),
                .define("HXPICKER_ENABLE_PICKER"),
                .define("HXPICKER_ENABLE_EDITOR"),
                .define("HXPICKER_ENABLE_CAMERA")
            ]),
    ]
)
