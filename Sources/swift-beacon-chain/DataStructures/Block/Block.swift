//
//  Block.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct Block {
    let slot: Int;
    let parentRoot: Data;
    let stateRoot: Data;
    let randaoReveal: Data;
    let depositRoot: Data;
    let signature: Data;
    let body: BlockBody;
}
