
import Foundation

@objc(AMAAppMetricaUUIDMigratable)
public protocol AppMetricaUUIDMigratable: NSObjectProtocol {
    func migrateAppMetricaUUID() -> String?
}
