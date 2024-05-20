import ProjectDescription

// Project settings

let debugConfiguration: Configuration = .debug(
    name: "Debug"
)

let stagingConfiguration: Configuration = .release(
    name: "Staging"
)

let releaseConfiguration: Configuration = .release(
    name: "Release"
)

// Demo app settings

let demoDebugConfiguration: Configuration = .debug(
    name: "Debug",
    xcconfig: .relativeToRoot("config/TWSDemo_dev.xcconfig")
)

let demoStagingConfiguration: Configuration = .release(
    name: "Staging",
    xcconfig: .relativeToRoot("config/TWSDemo_staging.xcconfig")
)

let demoReleaseConfiguration: Configuration = .release(
    name: "Release",
    xcconfig: .relativeToRoot("config/TWSDemo_release.xcconfig")
)

// Plist

let infoPlist: [String: Plist.Value] = [
    "UILaunchScreen": [:]
]

// Project

let project = Project(
    name: "TheWebSnippet",
    organizationName: "Inova IT, d.o.o.",
    settings: .settings(configurations: [
        debugConfiguration,
        stagingConfiguration,
        releaseConfiguration
    ]),
    targets: [
        .target(
            name: "TWSDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.inova.tws",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: infoPlist),
            sources: ["TWSDemo/Source/**"],
            dependencies: [],
            settings: .settings(configurations: [
                demoDebugConfiguration,
                demoStagingConfiguration,
                demoReleaseConfiguration
            ])
        )
    ]
)
