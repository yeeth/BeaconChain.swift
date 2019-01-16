//
//  ProposalSignedData.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct ProposalSignedData {
    let slot: uint64;
    let shard: uint64;
    let blockRoot: Data;
}
