import Foundation

protocol ProductFlowEventAssembling<Builder> {
    associatedtype Builder
    func assemble(builder: Builder) -> AssemblyResult
}

struct TruncatedData<T> {
    var value: T
    var bytesTruncated: Int
}

typealias AssemblyResult = TruncatedData<ProductFlowEventProto>
