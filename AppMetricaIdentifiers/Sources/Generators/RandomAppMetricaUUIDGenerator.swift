import Foundation

final class RandomAppMetricaUUIDGenerator: AppMetricaUUIDGenerator {
    
    func generateAppMetricaUUID() -> AppMetricaUUID {
        var uuid: uuid_t = (0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0)
        uuid_generate(&uuid)
        
        var result = ""
        withUnsafeMutableBytes(of: &uuid) { buffer in
            for i in 0...15 {
                let byte = buffer.load(fromByteOffset: i, as: UInt8.self)
                result += String(format: "%02x", byte)
            }
        }
        
        return .init(nonEmptyString: result)
    }
    
}

