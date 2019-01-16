//
//  ForkData.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct ForkData {
    let preForkVersion: Int;
    let postForkVersion: Int;
    let forkSlot: Int;
}
