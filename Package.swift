// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TWS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TWS",
            targets: ["TWS", "TWSNotifications", "TWSCookieManager"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            from: .init(1, 17, 1)
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-url-routing",
            from: .init(0, 6, 2)
        ),
        .package(
            url: "https://github.com/groue/GRMustache.swift",
            from: .init(6, 0, 0)
        ),
        .package(
            url: "https://github.com/Kitura/Swift-JWT.git",
            from: .init(4, 0, 0)
        )
    ],
    targets: [
        .target(
            name: "TWS",
            dependencies: [
                .product(name: "Mustache", package: "GRMustache.swift"),
                .target(name: "TWSCore"),
                .target(name: "TWSModels"),
                .target(name: "TWSLogger"),
                .target(name: "TWSLocal")
            ],
            path: "Sources/TWS",
            resources: [
                .copy("Resources/JavaScriptLocationInjection.js")
            ]
        ),
        .target(
            name: "TWSCore",
            dependencies: [
                .target(name: "TWSCommon"),
                .target(name: "TWSSnippets"),
                .target(name: "TWSSettings"),
                .target(name: "TWSLogger"),
                .target(name: "TWSFormatters")
            ],
            path: "Sources/TWSCore"
        ),
        .target(
            name: "TWSLocal",
            dependencies: [
                .target(name: "TWSModels"),
                .target(name: "TWSSnippet")
            ],
            path: "Sources/TWSLocal",
            swiftSettings: [
                .define("TESTING", .when(configuration: .debug))
            ]),
        .target(
            name: "TWSSnippets",
            dependencies: [
                .target(name: "TWSCommon"),
                .target(name: "TWSModels"),
                .target(name: "TWSSnippet"),
                .target(name: "TWSLogger"),
                .target(name: "TWSTriggers")
            ],
            path: "Sources/TWSSnippets",
            swiftSettings: [
                .define("TESTING", .when(configuration: .debug))
            ]
        ),
        .target(
            name: "TWSFormatters",
            path: "Sources/TWSFormatters"
        ),
        .target(
            name: "TWSSnippet",
            dependencies: [
                .target(name: "TWSCommon"),
                .target(name: "TWSModels"),
                .target(name: "TWSLogger"),
                .target(name: "TWSAPI")
            ],
            path: "Sources/TWSSnippet"
        ),
        .target(
            name: "TWSSettings",
            dependencies: [
                .target(name: "TWSCommon"),
                .target(name: "TWSModels"),
                .target(name: "TWSLogger")
            ],
            path: "Sources/TWSSettings"
        ),
        .target(
            name: "TWSModels",
            path: "Sources/TWSModels"
        ),
        .target(
            name: "TWSAPI",
            dependencies: [
                .product(name: "SwiftJWT", package: "Swift-JWT"),
                .target(name: "TWSModels"),
                .target(name: "TWSLogger"),
                .target(name: "TWSFormatters")
            ],
            path: "Sources/TWSAPI"
        ),
        .target(
            name: "TWSCommon",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "URLRouting", package: "swift-url-routing"),
                .target(name: "TWSAPI"),
                .target(name: "TWSLogger")
            ],
            path: "Sources/TWSCommon"
        ),
        .target(
            name: "TWSLogger",
            dependencies: [
                .target(name: "TWSModels")
            ],
            path: "Sources/TWSLogger"
        ),
        .target(
            name: "TWSNotifications",
            dependencies: [
                .target(name: "TWS")
            ],
            path: "Sources/TWSNotifications"
        ),
        .target(
            name: "TWSTriggers",
            dependencies: [
                .target(name: "TWSCommon")
            ],
            path: "Sources/TWSTriggers"
        ),
        .target(name: "TWSCookieManager",
            dependencies: [
                .target(name: "TWSLogger")
            ],
            path: "Sources/TWSCookieManager"),
        // Tests
        .testTarget(
            name: "TWSSnippetsTests",
            dependencies: [
                .target(name: "TWSSnippets"),
                .target(name: "TWSLocal"),
                .target(name: "TWSTriggers"),
                .target(name: "TWSCookieManager")
            ],
            path: "Tests/TWSSnippetsTests"
        ),
        .testTarget(
            name: "TWSModelsTests",
            dependencies: [
                .target(name: "TWSModels")
            ],
            path: "Tests/TWSModelsTests"
        ),
        .testTarget(
            name: "TWSLoggerTests",
            dependencies: [
                .target(name: "TWSLogger")
            ],
            path: "Tests/TWSLoggerTests"
        ),
        .testTarget(
            name: "RouterTests",
            dependencies: [
                .target(name: "TWSAPI"),
                .target(name: "TWSCookieManager")
            ],
            path: "Tests/RouterTests"
        ),
        .testTarget(
            name: "InjectionTests",
            dependencies: [
                .target(name: "TWSCommon"),
                .target(name: "TWSCookieManager")
            ],
            path: "Tests/InjectionTests"
        ),
        .testTarget(
            name: "TWSNotificationsTests",
            dependencies: [
                .target(name: "TWSNotifications"),
                .target(name: "TWSCookieManager")
            ],
            path: "Tests/TWSNotificationsTests"
        ),
        .testTarget(
            name: "TWSCookieManagerTests",
            dependencies: [
                .target(name: "TWSCookieManager"),
                .target(name: "TWSLogger")
            ],
            path: "Tests/TWSCookieManagerTests"
        )
    ]
)
