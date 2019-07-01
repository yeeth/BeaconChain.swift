import Foundation

class BLS {

    static func verify(pubkey: BLSPubkey, message: Data, signature: Data, domain: UInt64) -> Bool {
        return true
    }

    static func verify(pubkeys: [BLSPubkey], messages: [Data], signature: BLSSignature, domain: UInt64) -> Bool {
        return true
    }

    static func aggregate(pubkeys: [Data]) -> Data {
        return Data(count: 32)
    }
}
