
import Foundation

@objc(AMAAppMetricaIdentifiersKeys)
@objcMembers
final public class AppMetricaIdentifiersKeys: NSObject {
    
    public class var deviceID: String { IdentifiersCodingKeys.deviceID.rawValue }
    public class var deviceIDHash: String { IdentifiersCodingKeys.deviceIDHash.rawValue }
    public class var appMetricaUUID: String { IdentifiersCodingKeys.appMetricaUUID.rawValue }
    
}
