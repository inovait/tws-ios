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
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            exact: .init(11, 2, 0)
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            exact: .init(1, 15, 0)
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-url-routing",
            exact: .init(0, 6, 2)
        ),
        .package(
            url: "https://github.com/ProxymanApp/atlantis",
            exact: .init(1, 25, 1)
        )
    ]
)
