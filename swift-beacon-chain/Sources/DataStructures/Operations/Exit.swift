//
//  Exit.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct Exit {
    let slot: uint64;
    let validatorIndex: uint; // says 24 but whatever;
    let signature: Data;
}
