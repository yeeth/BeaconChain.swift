import Foundation

// @todo this will be in a seperate library

class BLS {

    static func verify(pubkey: Data, hash: Hash, signature: Data, domain: Domain) -> Bool {
        return false
    }

    static func verify(pubkeys: [Data], hashes: [Hash], signature: Data, domain: Domain) -> Bool {
        return false
    }

    static func aggregate(pubkeys: [Data]) -> Data {
        fatalError("not yet implemented")
    }
}
