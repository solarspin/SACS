// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "BankTransfers",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BankTransfers", targets: ["BankTransfers"])
    ],
    dependencies: [
        .package(path: "../BankCore"),
        .package(path: "../BankNetworking"),
        .package(path: "../BankDesign")
    ],
    targets: [
        .target(name: "BankTransfers", dependencies: ["BankCore", "BankNetworking", "BankDesign"]),
        .testTarget(name: "BankTransfersTests", dependencies: ["BankTransfers"])
    ]
)
