//
//  BlockBody.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct BlockBody {
    // @todo
    let proposerSlashings: [ProposerSlashing]
    let casperSlashings: [CasperSlashing]

// @todo will be defined in 1.0
//    let custodyReseeds: [CustodyReseed]
//    let custodyChallenges: [CustodyChallenge]
//    let custodyResponses: [CustodyResponse]

    let attestations: [Attestation]
    let deposits: [Deposit]
    let exits: [Exit]
}
