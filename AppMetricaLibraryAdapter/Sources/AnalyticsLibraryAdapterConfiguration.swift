
import Foundation

// these classes MUST NOT be changed  https://nda.ya.ru/t/KhAKgSKA7HojJj

public struct AnalyticsLibraryAdapterConfig {
    public init() { }
    public var advertisingIdentifiersTrackingEnabled: Bool?
    public var locationTrackingEnabled: Bool?
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
        return config.advertisingIdentifiersTrackingEnabled ?? true
    }
    
    @objc public dynamic var locationTrackingEnabled: Bool {
        return config.locationTrackingEnabled ?? true
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
        get { config.advertisingIdentifiersTrackingEnabled ?? true }
        set { config.advertisingIdentifiersTrackingEnabled = newValue }
    }
    
    @objc public dynamic override var locationTrackingEnabled: Bool {
        get { config.locationTrackingEnabled ?? true }
        set { config.locationTrackingEnabled = newValue }
    }
    
    public dynamic override func copy(with zone: NSZone? = nil) -> Any {
        return AnalyticsLibraryAdapterConfiguration(config: config)
    }
    
    public dynamic override func mutableCopy(with zone: NSZone? = nil) -> Any {
        return MutableAnalyticsLibraryAdapterConfiguration(config: config)
    }
    
}
