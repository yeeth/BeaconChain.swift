//
//  ProposerSlashing.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct ProposerSlashing {
    let proposerIndex: Int // says 24 but whatever
    let proposalData1: ProposalSignedData
    let proposalSignature1: Data
    let proposalData2: ProposalSignedData
    let proposalSignature2: Data
}
