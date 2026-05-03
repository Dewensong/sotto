// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Sotto",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "SottoCore", targets: ["SottoCore"]),
        .executable(name: "Sotto", targets: ["Sotto"])
    ],
    targets: [
        .target(name: "SottoCore"),
        .executableTarget(
            name: "Sotto",
            dependencies: ["SottoCore"]
        ),
        .testTarget(
            name: "SottoTests",
            dependencies: ["SottoCore"]
        )
    ]
)
