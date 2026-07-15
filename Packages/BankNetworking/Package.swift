// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "BankNetworking",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BankNetworking", targets: ["BankNetworking"])
    ],
    dependencies: [
        .package(path: "../BankCore")
    ],
    targets: [
        .target(name: "BankNetworking", dependencies: ["BankCore"]),
        .testTarget(name: "BankNetworkingTests", dependencies: ["BankNetworking"])
    ]
)
