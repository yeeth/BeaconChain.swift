//
//  SlashableVoteData.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct SlashableVoteData {
    let custodyBit0indices: Int
    let custodyBit1indices: Int
    let data: AttestationData
    let aggregateSignature: Data
}
