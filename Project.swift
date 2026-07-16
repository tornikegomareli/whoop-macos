import ProjectDescription

private func frameworkSearchSettings(_ targetNames: [String]) -> Settings {
    .settings(
        base: [
            "FRAMEWORK_SEARCH_PATHS": .array(
                ["$(inherited)"] + targetNames.map {
                    "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/\($0)"
                }
            ),
        ]
    )
}

let project = Project(
    name: "WhoopScope",
    organizationName: "WhoopScope",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        ]
    ),
    targets: [
        .target(
            name: "WhoopScopeDomain",
            destinations: [.mac, .iPhone],
            product: .framework,
            bundleId: "com.whoopscope.domain",
            deploymentTargets: .multiplatform(iOS: "26.0", macOS: "26.0"),
            sources: ["Modules/Domain/Sources/**"],
            dependencies: []
        ),
        .target(
            name: "WhoopScopeHealthBridge",
            destinations: [.mac, .iPhone],
            product: .framework,
            bundleId: "com.whoopscope.health-bridge",
            deploymentTargets: .multiplatform(iOS: "26.0", macOS: "26.0"),
            sources: ["Modules/HealthBridge/Sources/**"],
            dependencies: [
                .target(name: "WhoopScopeDomain"),
            ]
        ),
        .target(
            name: "WhoopScopePersistence",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.whoopscope.persistence",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/Persistence/Sources/**"],
            dependencies: [
                .target(name: "WhoopScopeDomain"),
                .external(name: "GRDB"),
            ],
            settings: .settings(
                base: [
                    "FRAMEWORK_SEARCH_PATHS": .array([
                        "$(inherited)",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/GRDB",
                    ]),
                ]
            )
        ),
        .target(
            name: "WhoopScopeAuthentication",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.whoopscope.authentication",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/Authentication/Sources/**"],
            dependencies: [
                .target(name: "WhoopScopeDomain"),
            ]
        ),
        .target(
            name: "WhoopScopeData",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.whoopscope.data",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/Data/Sources/**"],
            dependencies: [
                .target(name: "WhoopScopeDomain"),
                .target(name: "WhoopScopePersistence"),
            ]
        ),
        .target(
            name: "WhoopScopeDesignSystem",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.whoopscope.design-system",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/DesignSystem/Sources/**"],
            dependencies: []
        ),
        .target(
            name: "WhoopScopeWidgetSupport",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.whoopscope.widget-support",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/WidgetSupport/Sources/**"],
            dependencies: [],
            settings: .settings(
                base: [
                    "APPLICATION_EXTENSION_API_ONLY": "YES",
                ]
            )
        ),
        .target(
            name: "WhoopScopePreviewData",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.whoopscope.preview-data",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/PreviewData/Sources/**"],
            dependencies: [
                .target(name: "WhoopScopeDomain"),
            ]
        ),
        .target(
            name: "WhoopScopeDashboard",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.whoopscope.dashboard",
            deploymentTargets: .macOS("26.0"),
            sources: ["Features/Dashboard/Sources/**"],
            dependencies: [
                .target(name: "WhoopScopeDomain"),
                .target(name: "WhoopScopeDesignSystem"),
            ]
        ),
        .target(
            name: "WhoopScopeTrends",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.whoopscope.trends",
            deploymentTargets: .macOS("26.0"),
            sources: ["Features/Trends/Sources/**"],
            dependencies: [
                .target(name: "WhoopScopeDomain"),
                .target(name: "WhoopScopeDesignSystem"),
            ]
        ),
        .target(
            name: "WhoopScopeSettings",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.whoopscope.settings",
            deploymentTargets: .macOS("26.0"),
            sources: ["Features/Settings/Sources/**"],
            dependencies: [
                .target(name: "WhoopScopeDomain"),
                .target(name: "WhoopScopeDesignSystem"),
                .target(name: "WhoopScopeHealthBridge"),
            ]
        ),
        .target(
            name: "WhoopScopeWidgetExtension",
            destinations: [.mac],
            product: .appExtension,
            productName: "WhoopScopeWidget",
            bundleId: "com.whoopscope.mac.widget",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .dictionary(
                [
                    "CFBundleDisplayName": "WhoopScope",
                    "CFBundleExecutable": "$(EXECUTABLE_NAME)",
                    "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                    "CFBundleName": "WhoopScope",
                    "CFBundlePackageType": "$(PRODUCT_BUNDLE_PACKAGE_TYPE)",
                    "CFBundleShortVersionString": "0.1.0",
                    "CFBundleVersion": "1",
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                    ],
                ]
            ),
            sources: ["Apps/Widget/Sources/**"],
            resources: ["Apps/Widget/Resources/**"],
            entitlements: .dictionary(
                [
                    "com.apple.security.app-sandbox": true,
                    "com.apple.security.application-groups": [
                        "6SR4JWJD54.com.whoopscope.shared",
                    ],
                ]
            ),
            dependencies: [
                .target(name: "WhoopScopeWidgetSupport"),
            ],
            settings: .settings(
                base: [
                    "APPLICATION_EXTENSION_API_ONLY": "YES",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "6SR4JWJD54",
                    "FRAMEWORK_SEARCH_PATHS": .array([
                        "$(inherited)",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeWidgetSupport",
                    ]),
                    "SKIP_INSTALL": "YES",
                ]
            )
        ),
        .target(
            name: "WhoopScopeMac",
            destinations: [.mac],
            product: .app,
            bundleId: "com.whoopscope.mac",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .dictionary(
                [
                    "CFBundleDisplayName": "WhoopScope",
                    "CFBundleExecutable": "$(EXECUTABLE_NAME)",
                    "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                    "CFBundleName": "WhoopScope",
                    "CFBundlePackageType": "$(PRODUCT_BUNDLE_PACKAGE_TYPE)",
                    "CFBundleShortVersionString": "0.1.0",
                    "CFBundleVersion": "1",
                    "LSApplicationCategoryType": "public.app-category.healthcare-fitness",
                    "NSPrincipalClass": "NSApplication",
                    "WHOOPSCOPE_BROKER_URL": "https://whoopscope-auth.whoopscope.workers.dev",
                    "CFBundleURLTypes": [
                        [
                            "CFBundleURLName": "com.whoopscope.oauth",
                            "CFBundleURLSchemes": ["whoopscope"],
                        ],
                    ],
                ]
            ),
            sources: ["Apps/Mac/Sources/**"],
            resources: ["Apps/Mac/Resources/**"],
            entitlements: .dictionary(
                [
                    "com.apple.security.application-groups": [
                        "6SR4JWJD54.com.whoopscope.shared",
                    ],
                ]
            ),
            dependencies: [
                .target(name: "WhoopScopeDashboard"),
                .target(name: "WhoopScopeAuthentication"),
                .target(name: "WhoopScopeData"),
                .target(name: "WhoopScopeDesignSystem"),
                .target(name: "WhoopScopeDomain"),
                .target(name: "WhoopScopeHealthBridge"),
                .target(name: "WhoopScopePersistence"),
                .target(name: "WhoopScopeSettings"),
                .target(name: "WhoopScopeTrends"),
                .target(name: "WhoopScopeWidgetSupport"),
                .target(name: "WhoopScopeWidgetExtension"),
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "6SR4JWJD54",
                    "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                    "FRAMEWORK_SEARCH_PATHS": .array([
                        "$(inherited)",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeDashboard",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeAuthentication",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeData",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeDesignSystem",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeDomain",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeHealthBridge",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopePersistence",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeSettings",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeTrends",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeWidgetSupport",
                    ]),
                ]
            )
        ),
        .target(
            name: "WhoopScopeCompanion",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.whoopscope.companion",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "WhoopScope",
                    "CFBundleShortVersionString": "0.1.0",
                    "CFBundleVersion": "1",
                    "LSApplicationCategoryType": "public.app-category.healthcare-fitness",
                    "NSHealthShareUsageDescription": "WhoopScope reads selected activity, mobility, mindfulness, hydration, and body-composition data to enrich your private WHOOP history. It never requests sleep data.",
                    "NSLocalNetworkUsageDescription": "WhoopScope uses your local network to send selected Apple Health summaries directly to your Mac.",
                    "NSBonjourServices": ["_whoopscope._tcp"],
                    "UILaunchScreen": [:],
                ]
            ),
            sources: ["Apps/iPhone/Sources/**"],
            resources: ["Apps/Mac/Resources/Assets.xcassets"],
            entitlements: .dictionary(
                [
                    "com.apple.developer.healthkit": true,
                ]
            ),
            dependencies: [
                .target(name: "WhoopScopeDomain"),
                .target(name: "WhoopScopeHealthBridge"),
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "6SR4JWJD54",
                    "FRAMEWORK_SEARCH_PATHS": .array([
                        "$(inherited)",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeDomain",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeHealthBridge",
                    ]),
                    "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                    "TARGETED_DEVICE_FAMILY": "1",
                ]
            )
        ),
        .target(
            name: "WhoopScopeDomainTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.whoopscope.domain-tests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/Domain/Tests/**"],
            dependencies: [
                .target(name: "WhoopScopeDomain"),
            ],
            settings: frameworkSearchSettings(["WhoopScopeDomain"])
        ),
        .target(
            name: "WhoopScopeDashboardTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.whoopscope.dashboard-tests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Features/Dashboard/Tests/**"],
            dependencies: [
                .target(name: "WhoopScopeDashboard"),
                .target(name: "WhoopScopeDomain"),
                .target(name: "WhoopScopePreviewData"),
            ],
            settings: frameworkSearchSettings([
                "WhoopScopeDashboard",
                "WhoopScopeDesignSystem",
                "WhoopScopeDomain",
                "WhoopScopePreviewData",
            ])
        ),
        .target(
            name: "WhoopScopePersistenceTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.whoopscope.persistence-tests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/Persistence/Tests/**"],
            dependencies: [
                .target(name: "WhoopScopePersistence"),
                .target(name: "WhoopScopeDomain"),
            ],
            settings: frameworkSearchSettings([
                "GRDB",
                "GRDBSQLite",
                "GRDB_GRDB",
                "WhoopScopePersistence",
                "WhoopScopeDomain",
            ])
        ),
        .target(
            name: "WhoopScopeDataTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.whoopscope.data-tests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/Data/Tests/**"],
            dependencies: [
                .target(name: "WhoopScopeData"),
                .target(name: "WhoopScopeDomain"),
            ],
            settings: frameworkSearchSettings([
                "GRDB",
                "GRDBSQLite",
                "GRDB_GRDB",
                "WhoopScopeData",
                "WhoopScopeDomain",
                "WhoopScopePersistence",
            ])
        ),
        .target(
            name: "WhoopScopeAuthenticationTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.whoopscope.authentication-tests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/Authentication/Tests/**"],
            dependencies: [
                .target(name: "WhoopScopeAuthentication"),
                .target(name: "WhoopScopeDomain"),
            ],
            settings: frameworkSearchSettings([
                "WhoopScopeAuthentication",
                "WhoopScopeDomain",
            ])
        ),
        .target(
            name: "WhoopScopeSettingsTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.whoopscope.settings-tests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Features/Settings/Tests/**"],
            dependencies: [
                .target(name: "WhoopScopeSettings"),
                .target(name: "WhoopScopeDomain"),
            ],
            settings: frameworkSearchSettings([
                "WhoopScopeDesignSystem",
                "WhoopScopeHealthBridge",
                "WhoopScopeSettings",
                "WhoopScopeDomain",
            ])
        ),
        .target(
            name: "WhoopScopeTrendsTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.whoopscope.trends-tests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Features/Trends/Tests/**"],
            dependencies: [
                .target(name: "WhoopScopeTrends"),
                .target(name: "WhoopScopeDomain"),
            ],
            settings: frameworkSearchSettings([
                "WhoopScopeDesignSystem",
                "WhoopScopeTrends",
                "WhoopScopeDomain",
            ])
        ),
        .target(
            name: "WhoopScopeWidgetSupportTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.whoopscope.widget-support-tests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/WidgetSupport/Tests/**"],
            dependencies: [
                .target(name: "WhoopScopeWidgetSupport"),
            ],
            settings: frameworkSearchSettings(["WhoopScopeWidgetSupport"])
        ),
        .target(
            name: "WhoopScopeHealthBridgeTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.whoopscope.health-bridge-tests",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/HealthBridge/Tests/**"],
            dependencies: [
                .target(name: "WhoopScopeHealthBridge"),
                .target(name: "WhoopScopeDomain"),
            ],
            settings: frameworkSearchSettings([
                "WhoopScopeHealthBridge",
                "WhoopScopeDomain",
            ])
        ),
    ],
    schemes: [
        .scheme(
            name: "WhoopScope",
            shared: true,
            buildAction: .buildAction(targets: ["WhoopScopeMac"]),
            testAction: .targets(
                [
                    "WhoopScopeDomainTests",
                    "WhoopScopeDashboardTests",
                    "WhoopScopeAuthenticationTests",
                    "WhoopScopeDataTests",
                    "WhoopScopePersistenceTests",
                    "WhoopScopeSettingsTests",
                    "WhoopScopeTrendsTests",
                    "WhoopScopeWidgetSupportTests",
                    "WhoopScopeHealthBridgeTests",
                ],
                configuration: .debug
            ),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "WhoopScopeCompanion",
            shared: true,
            buildAction: .buildAction(targets: ["WhoopScopeCompanion"]),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
