// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "Wayfinder",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Wayfinder", targets: ["Wayfinder"])],
    targets: [
        .target(name: "WayfinderCore"),
        .executableTarget(name: "Wayfinder", dependencies: ["WayfinderCore"]),
        .testTarget(name: "WayfinderCoreTests", dependencies: ["WayfinderCore"], exclude: ["StandaloneRunner.swift", "TestSupport.swift"])
    ]
)
