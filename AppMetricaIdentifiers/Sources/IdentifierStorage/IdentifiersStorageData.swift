
struct IdentifiersStorageData: Equatable {
    var deviceID: DeviceID?
    var deviceIDHash: DeviceIDHash?
    var appMetricaUUID: AppMetricaUUID?
    
    var withoutAppMetricaUUID: IdentifiersStorageData {
        return .init(
            deviceID: deviceID,
            deviceIDHash: deviceIDHash
        )
    }
    
    var isEmpty: Bool {
        return deviceID == nil && deviceIDHash == nil && appMetricaUUID == nil
    }
}
