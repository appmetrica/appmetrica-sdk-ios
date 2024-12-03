import Foundation
import AppMetricaStorageUtils


final class FileStorageJSONProvider {
    
    let fileStorage: FileStorage
    
    lazy var jsonDecoder = JSONDecoder()
    lazy var jsonEncoder = JSONEncoder()
    
    init(fileStorage: FileStorage) {
        self.fileStorage = fileStorage
    }
    
    func read<T: Decodable>(type: T.Type) throws -> T? {
        guard fileStorage.fileExists else { return nil }
        
        let data = try fileStorage.readData()
        if data.isEmpty {
            return nil
        } else {
            return try jsonDecoder.decode(type, from: data)
        }
    }
    
    func write<T: Encodable>(_ object: T) throws {
        let data = try jsonEncoder.encode(object)
        try fileStorage.write(data)
    }
    
}

extension FileStorage {
    
    var jsonProvider: FileStorageJSONProvider {
        return FileStorageJSONProvider(fileStorage: self)
    }
    
}
