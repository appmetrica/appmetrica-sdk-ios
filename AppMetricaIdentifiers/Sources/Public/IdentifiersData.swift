
public struct Identifiers: Equatable, Hashable {
    public var deviceID: DeviceID?
    public var deviceHashID: DeviceIDHash?
    public var appMetricaUUID: AppMetricaUUID
    
    public init(deviceID: DeviceID? = nil, deviceHashID: DeviceIDHash? = nil, appMetricaUUID: AppMetricaUUID) {
        self.deviceID = deviceID
        self.deviceHashID = deviceHashID
        self.appMetricaUUID = appMetricaUUID
    }
    
    public var isValid: Bool {
        return deviceID != nil
    }
}
