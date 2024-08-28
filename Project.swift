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
            entitlements: getEntitlements(),
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
            resources: ["TWSKit/Resources/**"],
            dependencies: [
                .target(name: "TWSCore"),
                .target(name: "TWSModels"),
                .target(name: "TWSLogger")
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
                .target(name: "TWSSettings"),
                .target(name: "TWSUniversalLinks"),
                .target(name: "TWSLogger")
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
                .target(name: "TWSSnippet"),
                .target(name: "TWSLogger")
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
                .target(name: "TWSModels"),
                .target(name: "TWSLogger")
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
                .target(name: "TWSModels"),
                .target(name: "TWSLogger")
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
            product: .staticFramework,
            bundleId: "com.inova.twsapi",
            deploymentTargets: .iOS(deploymentTarget()),
            sources: ["TWSAPI/Sources/**"],
            dependencies: [
                .target(name: "TWSModels"),
                .target(name: "TWSLogger")
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
                .external(name: "URLRouting"),
                .target(name: "TWSAPI"),
                .target(name: "TWSLogger")
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
            name: "TWSLogger",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.inova.twslogger",
            deploymentTargets: .iOS(deploymentTarget()),
            infoPlist: .extendingDefault(with: loggerInfoPlist()),
            sources: ["TWSLogger/Sources/**"],
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
            name: "TWSLoggerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.inova.twsLoggerTests",
            deploymentTargets: .iOS(deploymentTarget()),
            infoPlist: .default,
            sources: ["TWSLoggerTests/Sources/**"],
            dependencies: [
                .target(name: "TWSLogger")
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
            name: "TWSUniversalLinks",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.inova.twsuniversallinks",
            deploymentTargets: .iOS(deploymentTarget()),
            sources: ["TWSUniversalLinks/Sources/**"],
            dependencies: [
                .target(name: "TWSModels"),
                .target(name: "TWSCommon"),
                .target(name: "TWSLogger")
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
            testAction: .targets(["TWSDemoTests", "TWSSnippetsTests", "TWSLoggerTests"]),
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

func getEntitlements() -> Entitlements {
    return Entitlements.dictionary([
        "com.apple.developer.associated-domains":
            [
                "applinks:thewebsnippet.com",
                "applinks:thewebsnippet.dev",
                "applinks:spotlight.inova.si"
            ]
    ])
}

func infoPlist() -> [String: Plist.Value] {
    [
        "UILaunchScreen": [:],
        "CFBundleDisplayName": "The Web Snippet",
        "CFBundleShortVersionString": "$(MARKETING_VERSION)",
        "CFBundleVersion": "${CURRENT_PROJECT_VERSION}",
        "NSLocationWhenInUseUsageDescription": "This app requires access to your location to enhance your experience by providing location-based features while you are using the app."
    ]
}

func loggerInfoPlist() -> [String: Plist.Value] {
    [
        "OSLogPreferences": [
            "$(PRODUCT_BUNDLE_IDENTIFIER)": [
                "TWSKit": [
                    "Level": [
                        "Enable": "Debug",
                        "Persist": "Debug"
                    ]
                ],
                "TWSSnippets": [
                    "Level": [
                        "Enable": "Debug",
                        "Persist": "Debug"
                    ]
                ],
                "TWSCore": [
                    "Level": [
                        "Enable": "Debug",
                        "Persist": "Debug"
                    ]
                ],
                "TWSSnippet": [
                    "Level": [
                        "Enable": "Debug",
                        "Persist": "Debug"
                    ]
                ],
                "TWSCommon": [
                    "Level": [
                        "Enable": "Debug",
                        "Persist": "Debug"
                    ]
                ],
                "TWSSettings": [
                    "Level": [
                        "Enable": "Debug",
                        "Persist": "Debug"
                    ]
                ],
                "TWSApi": [
                    "Level": [
                        "Enable": "Debug",
                        "Persist": "Debug"
                    ]
                ],
                "TWSUniversalLinks": [
                    "Level": [
                        "Enable": "Debug",
                        "Persist": "Debug"
                    ]
                ]
            ]
        ],
        "Enable-Private-Data": true
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
                $HOME/.local/bin/mise x -- swiftlint
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
