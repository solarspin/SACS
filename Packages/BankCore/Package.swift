// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "BankCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BankCore", targets: ["BankCore"])
    ],
    dependencies: [

    ],
    targets: [
        .target(name: "BankCore", dependencies: []),
        .testTarget(name: "BankCoreTests", dependencies: ["BankCore"])
    ]
)
