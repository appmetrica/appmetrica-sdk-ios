import Foundation
import AppMetricaCoreExtension
import AppMetricaSynchronization

final class ProductFlowEventData: NSObject, NSCopying, AppMetricaEventData {
    let name: String? = nil
    let type: UInt = ProductFlowConstants.eventType
    let bytesTruncated: UInt
    
    private let proto: ProductFlowEventProto
    private let dataLocker = UnfairLocker<Data?>(value: nil)

    init(proto: ProductFlowEventProto, bytesTruncated: Int) {
        self.proto = proto
        self.bytesTruncated = UInt(bytesTruncated)
    }

    var data: Data? {
        dataLocker.updateAndReturn { cached in
            if let value = cached { return value }
            let result = try? proto.serializedData()
            cached = result
            return result
        }
    }

    func copy(with zone: NSZone? = nil) -> Any { self }
}
