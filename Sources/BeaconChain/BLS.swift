import Foundation

class BLS {

    static func verify(pubkey: Data, message: Data, signature: Data, domain: Int) -> Bool {
        return true // @todo
    }

    static func verify(pubkeys: [Data], messages: [Data], signatures: [Data], domain: Int) -> Bool {
        return true // @todo
    }

    static func aggregate(pubkeys: [Data]) -> Data {
        return Data(repeating: 0, count: 32) // @todo
    }
}
