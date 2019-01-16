//
//  Attestation.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 15.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct AttestationData {
    let slot: uint64;
    let shard: uint64;
    let beaconBlockRoot: Data;
    let epochBoundryRoot: Data;
    let shardBlockRoot: Data;
    let latestCrosslinkRoot: Data;
    let justifiedSlot: uint64;
    let justifiedBlockRoot: Data;
}
