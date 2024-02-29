// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

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
        case .core: [.core, .coreExtension]
        case .crashes: [.crashes]
        case .adSupport: [.adSupport]
        case .webKit: [.webKit]
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
        case .ksCrash: .package(url: "https://github.com/kstenerud/KSCrash", .upToNextMinor(from: "1.16.1"))
        case .kiwi: .package(url: "https://github.com/appmetrica/Kiwi", .upToNextMinor(from: "3.0.1-spm"))
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
                "../../AppMetricaCoreExtension/Sources/include/AppMetricaCoreExtension", "./**"
            ]
        ),
        .testTarget(
            target: .core,
            dependencies: [
                .core, .coreExtension, .webKit, .testUtils, .hostState, .protobufUtils, .platform
            ],
            externalDependencies: [.kiwi],
            searchPaths: [
                "../../AppMetricaCoreExtension/Sources/include/AppMetricaCoreExtension", "./**", "../Sources/**"
            ],
            resources: [.process("Resources")]
        ),
        
        //MARK: - AppMetrica Crashes
        .target(
            target: .crashes,
            dependencies: [
                .core, .log, .coreExtension, .hostState, .protobufUtils, .platform, .storageUtils, .encodingUtils, .protobuf
            ],
            externalDependencies: [.ksCrash],
            searchPaths: ["./**"]
        ),
        .testTarget(
            target: .crashes,
            dependencies: [.crashes, .testUtils],
            externalDependencies: [.kiwi],
            searchPaths: ["../Sources/**", "./Helpers"],
            resources: [.process("Resources")]
        ),
        
        //MARK: - AppMetrica CoreExtension
        .target(
            target: .coreExtension,
            dependencies: [.core, .storageUtils],
            searchPaths: ["./**"]
        ),
        
        //MARK: - AppMetrica Log
        .target(target: .log),
        .testTarget(
            target: .log,
            dependencies: [.log],
            searchPaths: ["../Sources"]
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
            dependencies: [.log],
            searchPaths: ["./**"]
        ),
        .testTarget(
            target: .coreUtils,
            dependencies: [.coreUtils, .testUtils],
            externalDependencies: [.kiwi],
            searchPaths: ["Utilities", "../Sources/include/AppMetricaCoreUtils"]
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
            searchPaths: ["Utilities", "../Sources/include/AppMetricaNetwork"]
        ),
        
        //MARK: - AppMetrica AdSupport
        .target(target: .adSupport, dependencies: [.core, .coreExtension]),
        .testTarget(
            target: .adSupport,
            dependencies: [.adSupport, .testUtils],
            externalDependencies: [.kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica WebKit
        .target(target: .webKit, dependencies: [.core, .log, .coreUtils]),
        .testTarget(
            target: .webKit,
            dependencies: [.webKit, .testUtils],
            externalDependencies: [.kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica HostState
        .target(target: .hostState, dependencies: [.coreUtils, .log]),
        .testTarget(
            target: .hostState,
            dependencies: [.hostState, .testUtils],
            externalDependencies: [.kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica Platform
        .target(target: .platform, dependencies: [.log, .coreUtils]),
        .testTarget(
            target: .platform,
            dependencies: [.platform, .testUtils],
            externalDependencies: [.kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica StorageUtils
        .target(target: .storageUtils, dependencies: [.log, .coreUtils]),
        .testTarget(
            target: .storageUtils,
            dependencies: [.storageUtils, .testUtils],
            externalDependencies: [.kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica EncodingUtils
        .target(target: .encodingUtils, dependencies: [.log, .platform, .coreUtils]),
        .testTarget(
            target: .encodingUtils,
            dependencies: [.encodingUtils, .testUtils],
            externalDependencies: [.kiwi],
            searchPaths: ["../Sources/**"]
        ),
        
        //MARK: - AppMetrica FMDB
        .target(target: .fmdb),
    ]
)

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

        return .target(
            name: target.name,
            dependencies: dependencies.map { $0.dependency } + externalDependencies.map { $0.dependency },
            path: target.path,
            resources: resources,
            cSettings: combinedSettings(from: searchPaths, path: target.path)
        )
    }
    
    static func testTarget(target: AppMetricaTarget,
                           dependencies: [AppMetricaTarget] = [],
                           testUtils: [AppMetricaTarget] = [],
                           externalDependencies: [ExternalDependency] = [],
                           searchPaths: [String] = [],
                           resources: [Resource]? = nil) -> Target {
        
        return .testTarget(
            name: target.testsName,
            dependencies: dependencies.map { $0.dependency } + externalDependencies.map { $0.dependency },
            path: target.testsPath,
            resources: resources,
            cSettings: combinedSettings(from: searchPaths, path: target.testsPath)
        )
    }
    
    private static func combinedSettings(from searchPaths: [String], path: String) -> [CSetting] {
        return searchPaths.flatMap { searchPath -> [CSetting] in
            if searchPath.hasSuffix("**") {
                return headerSearchPaths(path, relativeSearchPath: String(searchPath.dropLast(2)))
            } else {
                return [.headerSearchPath(searchPath)]
            }
        }
    }

    private static func headerSearchPaths(_ targetPath: String, relativeSearchPath: String = ".") -> [CSetting] {
        let fullPathURL = buildFullPathURL(targetPath: targetPath, relativeSearchPath: relativeSearchPath)
        return [.headerSearchPath(relativeSearchPath)] + buildSettings(from: fullPathURL, using: relativeSearchPath)
    }
    
    private static func buildFullPathURL(targetPath: String, relativeSearchPath: String) -> URL {
        let packageDirectoryURL = URL(fileURLWithPath: #file).deletingLastPathComponent()
        return packageDirectoryURL
            .appendingPathComponent(targetPath)
            .appendingPathComponent(relativeSearchPath)
            .resolvingSymlinksInPath()
    }

    private static func buildSettings(from fullPathURL: URL, using relativeSearchPath: String) -> [CSetting] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: fullPathURL, includingPropertiesForKeys: nil) else {
            return [.headerSearchPath(relativeSearchPath)]
        }
        
        return enumerator
            .compactMap { $0 as? URL }
            .reduce([.headerSearchPath(relativeSearchPath)]) { (settings, fileOrDirURL) in
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: fileOrDirURL.path, isDirectory: &isDir), isDir.boolValue,
                   let relativePath = relativePath(from: fullPathURL, toDestination: fileOrDirURL) {
                    let combinedPath = [relativeSearchPath, relativePath]
                        .joined(separator: "/")
                        .replacingOccurrences(of: "//", with: "/")
                    return settings + [.headerSearchPath(combinedPath)]
                }
                return settings
            }
    }

    private static func relativePath(from base: URL, toDestination dest: URL) -> String? {
        let destComponents = dest.pathComponents
        let baseComponents = base.pathComponents
        let commonCount = zip(destComponents, baseComponents).prefix(while: { $0.0 == $0.1 }).count
        let downwardPaths = destComponents[commonCount...]
        return downwardPaths.isEmpty ? nil : downwardPaths.joined(separator: "/")
    }
}
