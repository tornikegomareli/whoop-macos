// swift-tools-version: 6.2

import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "GRDB": .staticFramework,
    ]
)
#endif

let package = Package(
    name: "WhoopScopeDependencies",
    dependencies: [
        .package(
            url: "https://github.com/groue/GRDB.swift.git",
            exact: "7.11.1"
        ),
    ]
)

