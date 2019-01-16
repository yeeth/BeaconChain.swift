//
//  Deposit.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct Deposit {
    let branch: Data; // not sure if good
    let index: uint64;
    let depositData: DepositData;
}
