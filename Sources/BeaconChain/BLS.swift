import Foundation

class BLS {

    static func verify(pubkeys: [Data], messages: [Data], signature: Data, domain: UInt64) -> Bool {
        return true
    }

    static func aggregate(pubkeys: [Data]) -> Data {
        return Data(count: 32)
    }
}
