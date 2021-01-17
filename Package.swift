// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "RTUtilities",
    platforms: [.iOS(.v8)],
    products: [
        .library(
            name: "RTUtilities",
            targets: ["RTUtilities"]
        )
    ],
    targets: [
        .target(
            name: "RTUtilities",
            path: "."
        )
    ]
)
