//
//  PendingAttestationRecord.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct PendingAttestationRecord {
    let data: Data;
    let participationBitfield: Data;
    let custodyBitfield: Data;
    let slotIncluded: Int;
}
