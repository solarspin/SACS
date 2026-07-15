// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "BankTreasury",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BankTreasury", targets: ["BankTreasury"])
    ],
    dependencies: [
        .package(path: "../BankCore"),
        .package(path: "../BankNetworking"),
        .package(path: "../BankDesign")
    ],
    targets: [
        .target(name: "BankTreasury", dependencies: ["BankCore", "BankNetworking", "BankDesign"]),
        .testTarget(name: "BankTreasuryTests", dependencies: ["BankTreasury"])
    ]
)
