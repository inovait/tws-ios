// swift-tools-version: 6.0
@preconcurrency import PackageDescription

#if TUIST
    import ProjectDescription
    import ProjectDescriptionHelpers

    let packageSettings = PackageSettings(
        productTypes: [:],
        baseSettings: .settings(
            configurations: [
                .debug(name: "Debug"),
                .debug(name: "Testing"),
                .release(name: "Staging"),
                .release(name: "Release")
            ]
        )
    )

#endif

let package = Package(
    name: "Dependencies",
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            exact: .init(1, 16, 1)
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-url-routing",
            exact: .init(0, 6, 2)
        ),
        .package(
            url: "https://github.com/groue/GRMustache.swift",
            exact: .init(6, 0, 0)
        ),
        .package(
            url: "https://github.com/Kitura/Swift-JWT.git",
            exact: .init(4, 0, 0)
        )
    ]
)
