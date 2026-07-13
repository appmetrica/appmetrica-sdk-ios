import Foundation
import Testing
@testable import AppMetricaProductFlow

struct ProductFlowStatusObjCTests {

    @Test func testRoundTrip_allCases() {
        let cases: [(ProductFlowStatusObjC, ProductFlowStatus)] = [
            (.success, .success),
            (.declined, .declined),
            (.pending, .pending),
            (.cancelled, .cancelled),
            (.expired, .expired),
            (.fail, .fail),
        ]

        for (objc, swift) in cases {
            #expect(objc.swiftValue == swift)
            #expect(ProductFlowStatusObjC(from: swift) == objc)
        }
    }

    @Test func testRawValues_arePinned() {
        #expect(ProductFlowStatusObjC.success.rawValue == 0)
        #expect(ProductFlowStatusObjC.declined.rawValue == 1)
        #expect(ProductFlowStatusObjC.pending.rawValue == 2)
        #expect(ProductFlowStatusObjC.cancelled.rawValue == 3)
        #expect(ProductFlowStatusObjC.expired.rawValue == 4)
        #expect(ProductFlowStatusObjC.fail.rawValue == 5)
    }
}
