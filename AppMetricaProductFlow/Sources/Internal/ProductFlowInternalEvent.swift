import Foundation
import AppMetricaCoreExtension

final class ProductFlowInternalEvent: NSObject, AppMetricaInternalEvent {
    let eventData: any AppMetricaEventData

    init(proto: ProductFlowEventProto, bytesTruncated: Int) {
        eventData = ProductFlowEventData(proto: proto, bytesTruncated: bytesTruncated)
    }
    
    convenience init<A: ProductFlowEventAssembling>(assembler: A, builder: A.Builder) {
        let result = assembler.assemble(builder: builder)
        self.init(proto: result.value, bytesTruncated: result.bytesTruncated)
    }

    func copy(with zone: NSZone? = nil) -> Any { return self }
}
