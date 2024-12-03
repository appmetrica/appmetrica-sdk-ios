import UIKit

final class IdentifierForVendorGenerator: DeviceIDGenerator {
    
    func generateDeviceID() -> DeviceID? {
        let uuid = UIDevice.current.identifierForVendor?.uuidString
        return uuid.map { DeviceID(nonEmptyString: $0) }
    }
    
}
