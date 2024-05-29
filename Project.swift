import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "TheWebSnippet",
    organizationName: "Inova IT, d.o.o.",
    settings: .settings(
        configurations: [
            .debug( name: "Debug", xcconfig: .relativeToRoot("config/TWS.xcconfig")),
            .release(name: "Staging", xcconfig: .relativeToRoot("config/TWS.xcconfig")),
            .release(name: "Release", xcconfig: .relativeToRoot("config/TWS.xcconfig"))
        ]
    ),
    targets: [
        .target(
            name: "TWSDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.inova.tws",
            deploymentTargets: .iOS(deploymentTarget()),
            infoPlist: .extendingDefault(with: infoPlist()),
            sources: ["TWSDemo/Sources/**"],
            resources: ["TWSDemo/Resources/**"],
            scripts: targetScripts(),
            dependencies: [
                .external(name: "FirebaseAnalytics"),
                .external(name: "FirebaseCrashlytics"),
                .target(name: "TWSKit")
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug", xcconfig: .relativeToRoot("config/TWSDemo_dev.xcconfig")),
                    .release(name: "Staging", xcconfig: .relativeToRoot("config/TWSDemo_staging.xcconfig")),
                    .release(name: "Release", xcconfig: .relativeToRoot("config/TWSDemo_release.xcconfig"))
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
            deploymentTargets: .iOS(deploymentTarget()),
            infoPlist: .default,
            sources: ["TWSDemoTests/Sources/**"],
            dependencies: [
                .target(name: "TWSDemo")
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: .relativeToRoot("config/TWSDemo_tests.xcconfig")
                    )
                ]
            )
        ),
        .target(
            name: "TWSKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.inova.twskit",
            deploymentTargets: .iOS(deploymentTarget()),
            sources: ["TWSKit/Sources/**"],
            dependencies: [
                .target(name: "TWSCore"),
                .target(name: "TWSModels")
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug", xcconfig: .relativeToRoot("config/TWSDist.xcconfig")),
                    .release(name: "Staging", xcconfig: .relativeToRoot("config/TWSDist.xcconfig")),
                    .release(name: "Release", xcconfig: .relativeToRoot("config/TWSDist.xcconfig"))
                ]
            )
        ),
        .target(
            name: "TWSCore",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.inova.twscore",
            deploymentTargets: .iOS(deploymentTarget()),
            sources: ["TWSCore/Sources/**"],
            dependencies: [
                .target(name: "TWSCommon"),
                .target(name: "TWSSnippets"),
                .target(name: "TWSSettings")
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Staging"),
                    .release(name: "Release")
                ]
            )
        ),
        .target(
            name: "TWSSnippets",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.inova.twssnippets",
            deploymentTargets: .iOS(deploymentTarget()),
            sources: ["TWSSnippets/Sources/**"],
            dependencies: [
                .target(name: "TWSCommon"),
                .target(name: "TWSModels"),
                .target(name: "TWSSnippet")
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Staging"),
                    .release(name: "Release")
                ]
            )
        ),
        .target(
            name: "TWSSnippetsTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.inova.twssnippetsTests",
            deploymentTargets: .iOS(deploymentTarget()),
            infoPlist: .default,
            sources: ["TWSSnippetsTests/Sources/**"],
            dependencies: [
                .target(name: "TWSSnippets")
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: .relativeToRoot("config/TWSDemo_tests.xcconfig")
                    )
                ]
            )
        ),
        .target(
            name: "TWSSnippet",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.inova.twssnippet",
            deploymentTargets: .iOS(deploymentTarget()),
            sources: ["TWSSnippet/Sources/**"],
            dependencies: [
                .target(name: "TWSCommon"),
                .target(name: "TWSModels")
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Staging"),
                    .release(name: "Release")
                ]
            )
        ),
        .target(
            name: "TWSSettings",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.inova.twssettings",
            deploymentTargets: .iOS(deploymentTarget()),
            sources: ["TWSSettings/Sources/**"],
            dependencies: [
                .target(name: "TWSCommon"),
                .target(name: "TWSModels")
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Staging"),
                    .release(name: "Release")
                ]
            )
        ),
        .target(
            name: "TWSModels",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.inova.twsmodels",
            deploymentTargets: .iOS(deploymentTarget()),
            sources: ["TWSModels/Sources/**"],
            dependencies: [
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug", xcconfig: .relativeToRoot("config/TWSDist.xcconfig")),
                    .release(name: "Staging", xcconfig: .relativeToRoot("config/TWSDist.xcconfig")),
                    .release(name: "Release", xcconfig: .relativeToRoot("config/TWSDist.xcconfig"))
                ]
            )
        ),
        .target(
            name: "TWSAPI",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.inova.twsapi",
            deploymentTargets: .iOS(deploymentTarget()),
            sources: ["TWSAPI/Sources/**"],
            dependencies: [
                .target(name: "TWSModels")
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Staging"),
                    .release(name: "Release")
                ]
            )
        ),
        .target(
            name: "TWSCommon",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.inova.twscommon",
            deploymentTargets: .iOS(deploymentTarget()),
            sources: ["TWSCommon/Sources/**"],
            dependencies: [
                .external(name: "ComposableArchitecture"),
                .target(name: "TWSAPI")
            ],
            settings: .settings(
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Staging"),
                    .release(name: "Release")
                ]
            )
        )
    ],
    schemes: [
        .scheme(
            name: "TWSDemo",
            buildAction: .buildAction(targets: ["TWSDemo"]),
            testAction: .targets(["TWSDemoTests", "TWSSnippetsTests"]),
            runAction: .runAction(),
            archiveAction: .archiveAction(configuration: "TWSDemo"),
            profileAction: .profileAction(),
            analyzeAction: .analyzeAction(configuration: "TWSDemo")
        )
    ]
)

func deploymentTarget() -> String {
    "17.0"
}

func infoPlist() -> [String: Plist.Value] {
    [
        "UILaunchScreen": [:],
        "CFBundleDisplayName": "The Web Snippet",
        "CFBundleShortVersionString": "$(MARKETING_VERSION)",
        "CFBundleVersion": "${CURRENT_PROJECT_VERSION}"
    ]
}

func targetScripts() -> [TargetScript] {
    [
        .pre(
            script: #"""
            if [[ "$(uname -m)" == arm64 ]]; then
                export PATH="/opt/homebrew/bin:$PATH"
            fi

            if which swiftlint > /dev/null; then
                swiftlint
            else
                echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
            fi
            """#,
            name: "SwiftLint",
            basedOnDependencyAnalysis: false
        ),
        .post(
            script: #"""
            "${SRCROOT}/Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run"
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
        )
    ]
}
