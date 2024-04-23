// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

enum AppMetricaTarget: String {
    case core = "AppMetricaCore"
    case crashes = "AppMetricaCrashes"
    case coreExtension = "AppMetricaCoreExtension"
    case adSupport = "AppMetricaAdSupport"
    case webKit = "AppMetricaWebKit"
    case log = "AppMetricaLog"
    case coreUtils = "AppMetricaCoreUtils"
    case testUtils = "AppMetricaTestUtils"
    case network = "AppMetricaNetwork"
    case hostState = "AppMetricaHostState"
    case platform = "AppMetricaPlatform"
    case protobufUtils = "AppMetricaProtobufUtils"
    case storageUtils = "AppMetricaStorageUtils"
    case encodingUtils = "AppMetricaEncodingUtils"
    
    case protobuf = "AppMetrica_Protobuf"
    case fmdb = "AppMetrica_FMDB"
    
    var name: String { rawValue }
    var testsName: String { rawValue + "Tests" }
    var path: String { "\(rawValue)/Sources" }
    var testsPath: String { "\(rawValue)/Tests" }
    var dependency: Target.Dependency { .target(name: rawValue) }
}

enum AppMetricaProduct: String, CaseIterable {
    case core = "AppMetricaCore"
    case crashes = "AppMetricaCrashes"
    case adSupport = "AppMetricaAdSupport"
    case webKit = "AppMetricaWebKit"
    
    static var allProducts: [Product] { allCases.map { $0.product } }
    
    var targets: [AppMetricaTarget] {
        switch self {
        case .core: return [.core, .coreExtension]
        case .crashes: return [.crashes]
        case .adSupport: return [.adSupport]
        case .webKit: return [.webKit]
        }
    }
    
    var product: Product { .library(name: rawValue, targets: targets.map { $0.name }) }
}

enum ExternalDependency: String, CaseIterable {
    case kiwi = "Kiwi"
    case ksCrash = "KSCrash"

    static var allDependecies: [Package.Dependency] { allCases.map { $0.package } }
    
    var dependency: Target.Dependency { .byName(name: rawValue) }
    
    var package: Package.Dependency {
        switch self {
        case .ksCrash: return .package(url: "https://github.com/kstenerud/KSCrash", "1.17.0"..<"1.18.0")
        case .kiwi: return .package(url: "https://github.com/appmetrica/Kiwi", exact: "3.0.1-spm")
        }
    }
}

let package = Package(
    name: "AppMetrica",
    platforms: [
        .iOS(.v11),
        .tvOS(.v11),
    ],
    products: AppMetricaProduct.allProducts,
    dependencies: ExternalDependency.allDependecies,
    targets: [
        //MARK: - AppMetrica SDK -
        .target(
            target: .core,
            dependencies: [
                .network, .log, .coreUtils, .hostState, .protobufUtils, .platform, .storageUtils, .encodingUtils, .protobuf, .fmdb
            ],
            searchPaths: [
                "../../AppMetricaCoreExtension/Sources/include/AppMetricaCoreExtension"
            ]
        ),
        .testTarget(
            target: .core,
            dependencies: [
                .core, .coreExtension, .webKit, .testUtils, .hostState, .protobufUtils, .platform
            ],
            externalDependencies: [.kiwi],
            searchPaths: [
                "../../AppMetricaCoreExtension/Sources/include/AppMetricaCoreExtension"
            ],
            resources: [.process("Resources")]
        ),
        
        //MARK: - AppMetrica Crashes
        .target(
            target: .crashes,
            dependencies: [
                .core, .log, .coreExtension, .hostState, .protobufUtils, .platform, .storageUtils, .encodingUtils, .protobuf
            ],
            externalDependencies: [.ksCrash]
        ),
        .testTarget(
            target: .crashes,
            dependencies: [.crashes, .testUtils],
            externalDependencies: [.kiwi],
            resources: [.process("Resources")]
        ),
        
        //MARK: - AppMetrica CoreExtension
        .target(
            target: .coreExtension,
            dependencies: [.core, .storageUtils]
        ),
        
        //MARK: - AppMetrica Log
        .target(target: .log),
        .testTarget(
            target: .log,
            dependencies: [.log]
        ),
        
        //MARK: - AppMetrica Protobuf
        .target(target: .protobuf),
        
        //MARK: - AppMetrica ProtobufUtils
        .target(target: .protobufUtils, dependencies: [.protobuf]),
        .testTarget(
            target: .protobufUtils,
            dependencies: [.protobufUtils]
        ),
        
        //MARK: - AppMetrica CoreUtils
        .target(
            target: .coreUtils,
            dependencies: [.log]
        ),
        .testTarget(
            target: .coreUtils,
            dependencies: [.coreUtils, .testUtils],
            externalDependencies: [.kiwi],
            searchPaths: ["../Sources/include/AppMetricaCoreUtils"]
        ),
        
        //MARK: - AppMetrica TestUtils
        .target(
            target: .testUtils,
            dependencies: [.coreUtils, .network, .storageUtils, .hostState],
            externalDependencies: [.kiwi],
            includePrivacyManifest: false
        ),
        
        //MARK: - AppMetrica Network
        .target(
            target: .network,
            dependencies: [.log, .coreUtils, .platform]
        ),
        .testTarget(
            target: .network,
            dependencies: [.network, .platform, .coreExtension, .testUtils],
            externalDependencies: [.kiwi],
            searchPaths: ["../Sources/include/AppMetricaNetwork"]
        ),
        
        //MARK: - AppMetrica AdSupport
        .target(target: .adSupport, dependencies: [.core, .coreExtension]),
        .testTarget(
            target: .adSupport,
            dependencies: [.adSupport, .testUtils],
            externalDependencies: [.kiwi]
        ),
        
        //MARK: - AppMetrica WebKit
        .target(target: .webKit, dependencies: [.core, .log, .coreUtils]),
        .testTarget(
            target: .webKit,
            dependencies: [.webKit, .testUtils],
            externalDependencies: [.kiwi]
        ),
        
        //MARK: - AppMetrica HostState
        .target(target: .hostState, dependencies: [.coreUtils, .log]),
        .testTarget(
            target: .hostState,
            dependencies: [.hostState, .testUtils],
            externalDependencies: [.kiwi]
        ),
        
        //MARK: - AppMetrica Platform
        .target(target: .platform, dependencies: [.log, .coreUtils]),
        .testTarget(
            target: .platform,
            dependencies: [.platform, .testUtils],
            externalDependencies: [.kiwi]
        ),
        
        //MARK: - AppMetrica StorageUtils
        .target(target: .storageUtils, dependencies: [.log, .coreUtils]),
        .testTarget(
            target: .storageUtils,
            dependencies: [.storageUtils, .testUtils],
            externalDependencies: [.kiwi]
        ),
        
        //MARK: - AppMetrica EncodingUtils
        .target(target: .encodingUtils, dependencies: [.log, .platform, .coreUtils]),
        .testTarget(
            target: .encodingUtils,
            dependencies: [.encodingUtils, .testUtils],
            externalDependencies: [.kiwi]
        ),
        
        //MARK: - AppMetrica FMDB
        .target(target: .fmdb),
    ]
)

//MARK: - Helpers

extension Target {
    static func target(target: AppMetricaTarget,
                       dependencies: [AppMetricaTarget] = [],
                       externalDependencies: [ExternalDependency] = [],
                       searchPaths: [String] = [],
                       includePrivacyManifest: Bool = true) -> Target {
        var resources: [Resource] = []
        if includePrivacyManifest {
            resources.append(.copy("Resources/PrivacyInfo.xcprivacy"))
        }
        
        let resultSearchPath: Set<String> = target.headerPaths.union(searchPaths)

        return .target(
            name: target.name,
            dependencies: dependencies.map { $0.dependency } + externalDependencies.map { $0.dependency },
            path: target.path,
            resources: resources,
            cSettings: resultSearchPath.sorted().map { .headerSearchPath($0) }
        )
    }
    
    static func testTarget(target: AppMetricaTarget,
                           dependencies: [AppMetricaTarget] = [],
                           testUtils: [AppMetricaTarget] = [],
                           externalDependencies: [ExternalDependency] = [],
                           searchPaths: [String] = [],
                           resources: [Resource]? = nil) -> Target {
        
        let resultSearchPath: Set<String> = target.testsHeaderPaths.union(searchPaths)
        
        return .testTarget(
            name: target.testsName,
            dependencies: dependencies.map { $0.dependency } + externalDependencies.map { $0.dependency },
            path: target.testsPath,
            resources: resources,
            cSettings: resultSearchPath.sorted().map { .headerSearchPath($0) }
        )
    }
    
}

//MARK: - Header paths

extension AppMetricaTarget {
    
    var headerPaths: Set<String> {
        let commonPaths: Set<String> = [
            ".",
            "include",
            "include/\(name)"
        ]
        
        return commonPaths.union(additionalHeaderPaths)
    }
    
    var testsHeaderPaths: Set<String> {
        let commonPaths: Set<String> = [
            "."
        ]
        
        let moduleHeaderPaths = headerPaths.map { "../Sources/\($0)" }
        
        return commonPaths.union(testAdditionalHeaderPaths).union(moduleHeaderPaths)
    }
    
}

extension AppMetricaTarget {
    
    var additionalHeaderPaths: [String] {
        switch self {
        case .core:
            return [
                ".",
                "./AdRevenue",
                "./AdRevenue/Formatting",
                "./AdRevenue/Model",
                "./AdRevenue/Serialization",
                "./AdRevenue/Validation",
                "./Attribution",
                "./Configuration",
                "./Core",
                "./Database",
                "./Database/IntegrityManager",
                "./Database/KeyValueStorage",
                "./Database/KeyValueStorage/Converters",
                "./Database/KeyValueStorage/DataProviders",
                "./Database/Migration",
                "./Database/Migration/ApiKey",
                "./Database/Migration/Library",
                "./Database/Migration/Scheme",
                "./Database/Migration/Utilities",
                "./Database/Scheme",
                "./Database/Trimming",
                "./DeepLink",
                "./Dispatcher",
                "./ECommerce",
                "./ExtensionsReport",
                "./ExternalAttribution",
                "./Generated",
                "./Limiters",
                "./Location",
                "./Logging",
                "./Model",
                "./Model/Event",
                "./Model/Event/Value",
                "./Model/Reporter",
                "./Model/Reporter/Serialization",
                "./Model/Session",
                "./Model/Truncation",
                "./Network",
                "./Network/File",
                "./Network/Report",
                "./Network/Startup",
                "./Permissions",
                "./Profiles",
                "./Profiles/Attributes",
                "./Profiles/Attributes/Complex",
                "./Profiles/Models",
                "./Profiles/Truncation",
                "./Profiles/Updates",
                "./Profiles/Updates/Factory",
                "./Profiles/Validation",
                "./Reporter",
                "./Reporter/FirstOccurrence",
                "./Revenue",
                "./Revenue/AutoIAP",
                "./Revenue/AutoIAP/Models",
                "./SearchAds",
                "./SearchAds/AdServices",
                "./StartupPermissions",
                "./Strategies",
                "./include",
                "./include/AppMetricaCore",
                "./Privacy",
                "./Resources",
            ]
        case .coreUtils:
            return [
                ".",
                "./Execution",
                "./Truncation",
                "./Utilities",
                "./include",
                "./include/AppMetricaCoreUtils",
                "./Resources",
            ]
        case .crashes:
            return [
                ".",
                "./CrashModels",
                "./CrashModels/Crash",
                "./CrashModels/Crash/Error",
                "./CrashModels/Crash/Thread",
                "./CrashModels/System",
                "./Error",
                "./Generated",
                "./LibraryCrashes",
                "./include",
                "./include/AppMetricaCrashes",
                "./Plugins",
                "./Resources",
            ]
        case .adSupport, .coreExtension, .encodingUtils, .fmdb, .hostState, .log, .network, .platform, .protobuf, .protobufUtils, .storageUtils, .webKit, .testUtils:
            return []
        }
    }
    
    var testAdditionalHeaderPaths: [String] {
        switch self {
        case .core:
            return [
                "Mocks",
                "Resources",
                "Utilities",
            ]
        case .coreUtils, .encodingUtils, .network:
            return [
                "Utilities",
            ]
        case .platform, .protobufUtils, .log:
            return [
                "Mocks",
            ]
        case .crashes, .coreExtension, .adSupport, .webKit, .testUtils, .hostState, .storageUtils, .protobuf, .fmdb:
            return []
        }
    }
    
}
