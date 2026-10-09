// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "Wayfinder",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Wayfinder", targets: ["Wayfinder"])],
    dependencies: [.package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")],
    targets: [
        .target(name: "WayfinderCore"),
        .executableTarget(name: "Wayfinder", dependencies: ["WayfinderCore", .product(name: "Sparkle", package: "Sparkle")],
                          linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]),
        .testTarget(name: "WayfinderCoreTests", dependencies: ["WayfinderCore"], exclude: ["StandaloneRunner.swift", "TestSupport.swift"])
    ]
)
