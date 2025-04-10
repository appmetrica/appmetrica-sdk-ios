
import Foundation

struct LibraryAdapterConfig {
    init() { }
    var advIdentifiersTrackingEnabled: Bool = true
}

@objc(AMALibraryAdapterConfiguration)
public class LibraryAdapterConfiguration: NSObject, NSCopying, NSMutableCopying {
    
    var config: LibraryAdapterConfig = .init()
    
    public required override init() {
        super.init()
    }
    
    required init(config: LibraryAdapterConfig) {
        self.config = config
        super.init()
    }
    
    @objc
    public var advIdentifiersTrackingEnabled: Bool {
        return config.advIdentifiersTrackingEnabled
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        return MutableLibraryAdapterConfiguration(config: config)
    }
}

@objc(AMAMutableLibraryAdapterConfiguration)
public class MutableLibraryAdapterConfiguration: LibraryAdapterConfiguration {
    
    @objc
    public override var advIdentifiersTrackingEnabled: Bool {
        get { config.advIdentifiersTrackingEnabled }
        set { config.advIdentifiersTrackingEnabled = newValue }
    }
    
    public override func copy(with zone: NSZone? = nil) -> Any {
        return LibraryAdapterConfiguration(config: config)
    }
    
    public override func mutableCopy(with zone: NSZone? = nil) -> Any {
        return MutableLibraryAdapterConfiguration(config: config)
    }
    
}
