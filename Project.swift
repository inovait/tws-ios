import ProjectDescription
import ProjectDescriptionHelpers

let deploymentTarget = "17.0"

// Project settings

let debugConfiguration: Configuration = .debug(
    name: "Debug",
    xcconfig: .relativeToRoot("config/TWS.xcconfig")
)

let stagingConfiguration: Configuration = .release(
    name: "Staging",
    xcconfig: .relativeToRoot("config/TWS.xcconfig")
)

let releaseConfiguration: Configuration = .release(
    name: "Release",
    xcconfig: .relativeToRoot("config/TWS.xcconfig")
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

//

let demoTestsConfiguration: Configuration = .debug(
    name: "Debug",
    xcconfig: .relativeToRoot("config/TWSDemo_tests.xcconfig")
)


// Plist

let infoPlist: [String: Plist.Value] = [
    "UILaunchScreen": [:],
    "CFBundleDisplayName": "The Web Snippet",
    "CFBundleShortVersionString": "$(MARKETING_VERSION)",
    "CFBundleVersion": "${CURRENT_PROJECT_VERSION}"
]

//

let targetScripts: [TargetScript] = [
    .post(
        script: #"""
        "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
        """#,
        name: "Firebase Crashlystics",
        inputPaths: [
            "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}",
            "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}",
            "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist",
            "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
            "$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)"
        ],
        basedOnDependencyAnalysis: false
    ),
]

// Project

let project = Project(
    name: "TheWebSnippet",
    organizationName: "Inova IT, d.o.o.",
    settings: .settings(
        configurations: [
            debugConfiguration,
            stagingConfiguration,
            releaseConfiguration
        ]
    ),
    targets: [
        .target(
            name: "TWSDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.inova.tws",
            deploymentTargets: .iOS(deploymentTarget),
            infoPlist: .extendingDefault(with: infoPlist),
            sources: ["TWSDemo/Sources/**"],
            resources: ["TWSDemo/Resources/**"],
            scripts: targetScripts,
            dependencies: [
                .external(name: "FirebaseAnalytics"),
                .external(name: "FirebaseCrashlytics")
            ],
            settings: .settings(
                configurations: [
                    demoDebugConfiguration,
                    demoStagingConfiguration,
                    demoReleaseConfiguration
                ],
                defaultSettings: .recommended(excluding: [
                    "CODE_SIGN_IDENTITY",
                    "DEVELOPMENT_TEAM"
                ])
            )
        ),
        .target(
            name: "TWSDemoTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.inova.twsTests",
            deploymentTargets: .iOS(deploymentTarget),
            infoPlist: .default,
            sources: ["TWSDemoTests/Sources/**"],
            dependencies: [
                .target(name: "TWSDemo")
            ],
            settings: .settings(
                configurations: [
                    demoTestsConfiguration
                ]
            )
        )
    ]
)
