//
//  ValidatorRegistryDeltaBlock.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct ValidatorRegistryDeltaBlock {
    let lateRegistryDeltaRoot: Data;
    let validatorIndex: Int;
    let pubkey: Data;
    let slot: Int;
    let flag: Int;
}
