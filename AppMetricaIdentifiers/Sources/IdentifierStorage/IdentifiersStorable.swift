
protocol IdentifiersStorable: AnyObject {
    func fetchIdentifiers() throws -> KeychainValueState<IdentifiersStorageData>
}

protocol MutableIdentifiersStorable: IdentifiersStorable {
    func saveIdentifiers(_ ids: IdentifiersStorageData) throws
}

