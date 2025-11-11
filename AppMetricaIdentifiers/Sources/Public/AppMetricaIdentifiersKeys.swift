
import Foundation

// If the data storage format and location change, you must notify https://nda.ya.ru/t/94XNTaaf7LkVFu
@objc(AMAAppMetricaIdentifiersKeys)
@objcMembers
final public class AppMetricaIdentifiersKeys: NSObject {
    
    public class var deviceID: String { IdentifiersCodingKeys.deviceID.rawValue }
    public class var deviceIDHash: String { IdentifiersCodingKeys.deviceIDHash.rawValue }
    public class var appMetricaUUID: String { IdentifiersCodingKeys.appMetricaUUID.rawValue }
    
}
