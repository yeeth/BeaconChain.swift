//
//  ValidatorRecord.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 15.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct ValidatorRecord {
    let pubkey: Data;
    let withdrawalCredentials: Data;
    let randaoCommitment: Data;
    let randaoLayers: uint64;
    let activationSlot: uint64;
    let exitSlot: uint64;
    let withdrawalSlot: uint64;
    let penalizedSlot: uint64;
    let exitCount: uint64;
    let statusFlags: uint64;
    let custodyCommitment: uint64;
    let latestCustodyReseedSlot: uint64;
    let penultimateCustodyReseedSlot: uint64;
}
