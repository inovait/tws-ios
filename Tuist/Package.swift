// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription
    import ProjectDescriptionHelpers

    let packageSettings = PackageSettings(
        productTypes: [:
//            "Firebase": .default, // default is .staticFramework
        ],
        baseSettings: .settings(configurations: [
            .debug(name: "Debug"),
            .release(name: "Staging"),
            .release(name: "Release")
        ])
    )

#endif

let package = Package(
    name: "Dependencies",
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "10.26.0"
        )
    ]
)
