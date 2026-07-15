// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "BankAuth",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BankAuth", targets: ["BankAuth"])
    ],
    dependencies: [
        .package(path: "../BankCore"),
        .package(path: "../BankNetworking"),
        .package(path: "../BankDesign")
    ],
    targets: [
        .target(name: "BankAuth", dependencies: ["BankCore", "BankNetworking", "BankDesign"]),
        .testTarget(name: "BankAuthTests", dependencies: ["BankAuth"])
    ]
)
