import Foundation

struct DepositData: Equatable {
    let amount: UInt64
    let timestamp: UInt64
    let depositInput: DepositInput
}
