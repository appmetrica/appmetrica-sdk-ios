import AppMetricaPlatform

final class IdentifierForVendorGenerator: DeviceIDGenerator {
    
    func generateDeviceID() -> DeviceID? {
        let uuid = PlatformDescription.identifierForVendor()
        return uuid.map { DeviceID(nonEmptyString: $0) }
    }
    
}
