// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "BankDesign",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BankDesign", targets: ["BankDesign"])
    ],
    dependencies: [
        .package(path: "../BankCore")
    ],
    targets: [
        .target(name: "BankDesign", dependencies: ["BankCore"]),
        .testTarget(name: "BankDesignTests", dependencies: ["BankDesign"])
    ]
)
