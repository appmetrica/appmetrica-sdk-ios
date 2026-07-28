
import Foundation

// these classes MUST NOT be changed  https://nda.ya.ru/t/KhAKgSKA7HojJj

public struct AnalyticsLibraryAdapterConfig {
    public init() { }
    public var advertisingIdentifiersTrackingEnabled: Bool?
    public var locationTrackingEnabled: Bool?
    public var customHosts: [String]?
}

@objc(AMAAnalyticsLibraryAdapterConfiguration)
public class AnalyticsLibraryAdapterConfiguration: NSObject, NSCopying, NSMutableCopying {
    
    var config: AnalyticsLibraryAdapterConfig = .init()
    
    public required override init() {
        super.init()
    }
    
    required init(config: AnalyticsLibraryAdapterConfig) {
        self.config = config
        super.init()
    }
    
    @objc public dynamic var advertisingIdentifiersTrackingEnabled: Bool {
        return config.advertisingIdentifiersTrackingEnabled ?? false
    }

    @objc public dynamic var locationTrackingEnabled: Bool {
        return config.locationTrackingEnabled ?? false
    }

    @objc public dynamic var customHosts: [String]? {
        return config.customHosts
    }

    public dynamic func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public dynamic func mutableCopy(with zone: NSZone? = nil) -> Any {
        return MutableAnalyticsLibraryAdapterConfiguration(config: config)
    }
}

@objc(AMAMutableAnalyticsLibraryAdapterConfiguration)
final public class MutableAnalyticsLibraryAdapterConfiguration: AnalyticsLibraryAdapterConfiguration {

    @objc public dynamic override var advertisingIdentifiersTrackingEnabled: Bool {
        get { config.advertisingIdentifiersTrackingEnabled ?? false }
        set { config.advertisingIdentifiersTrackingEnabled = newValue }
    }
    
    @objc public dynamic override var locationTrackingEnabled: Bool {
        get { config.locationTrackingEnabled ?? false }
        set { config.locationTrackingEnabled = newValue }
    }

    @objc public dynamic override var customHosts: [String]? {
        get { config.customHosts }
        set { config.customHosts = newValue }
    }
    
    public dynamic override func copy(with zone: NSZone? = nil) -> Any {
        return AnalyticsLibraryAdapterConfiguration(config: config)
    }
    
    public dynamic override func mutableCopy(with zone: NSZone? = nil) -> Any {
        return MutableAnalyticsLibraryAdapterConfiguration(config: config)
    }
    
}
