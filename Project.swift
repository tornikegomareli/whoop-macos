import ProjectDescription

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
            destinations: [.mac],
            product: .framework,
            bundleId: "com.whoopscope.domain",
            deploymentTargets: .macOS("26.0"),
            sources: ["Modules/Domain/Sources/**"],
            dependencies: []
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
            name: "WhoopScopeSettings",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.whoopscope.settings",
            deploymentTargets: .macOS("26.0"),
            sources: ["Features/Settings/Sources/**"],
            dependencies: [
                .target(name: "WhoopScopeDomain"),
                .target(name: "WhoopScopeDesignSystem"),
            ]
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
            dependencies: [
                .target(name: "WhoopScopeDashboard"),
                .target(name: "WhoopScopeAuthentication"),
                .target(name: "WhoopScopeData"),
                .target(name: "WhoopScopeDesignSystem"),
                .target(name: "WhoopScopeDomain"),
                .target(name: "WhoopScopePersistence"),
                .target(name: "WhoopScopeSettings"),
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                    "FRAMEWORK_SEARCH_PATHS": .array([
                        "$(inherited)",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeDashboard",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeAuthentication",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeData",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeDesignSystem",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeDomain",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopePersistence",
                        "$(CONFIGURATION_BUILD_DIR)$(TARGET_BUILD_SUBPATH)/WhoopScopeSettings",
                    ]),
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
                ],
                configuration: .debug
            ),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
