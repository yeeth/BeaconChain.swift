//
//  DepositInput.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct DepositInput {
    let pubkey: Data;
    let withdrawalCredentials: Data;
    let randaoCommitment: Data;
    let custodyCommitment: Data;
    let proofOfPossession: Data;
}
