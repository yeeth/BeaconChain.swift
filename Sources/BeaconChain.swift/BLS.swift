//
//  BLS.swift
//  BeaconChain.swift
//
//  Created by Dean Eigenmann on 16.01.19.
//

import Foundation

class BLS {

    static func verify(pubkey: Data, message: Data, signature: Data, domain: UInt64) -> Bool {
        return true // @todo
    }

    static func verify(pubkeys: [Data], messages: [Data], signatures: [Data], domain: UInt64) -> Bool {
        return true // @todo
    }

}
