// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription
    import ProjectDescriptionHelpers

    let packageSettings = PackageSettings(
        productTypes: [
            "ComposableArchitecture": .framework,
            "Dependencies": .framework,
            "Clocks": .framework,
            "ConcurrencyExtras": .framework,
            "CombineSchedulers": .framework,
            "IdentifiedCollections": .framework,
            "OrderedCollections": .framework,
            "_CollectionsUtilities": .framework,
            "DependenciesMacros": .framework,
            "SwiftUINavigationCore": .framework,
            "Perception": .framework,
            "CasePaths": .framework,
            "CustomDump": .framework,
            "XCTestDynamicOverlay": .framework
        ],
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
            exact: .init(10, 28, 0)
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            exact: .init(1, 11, 1)
        )
    ]
)
