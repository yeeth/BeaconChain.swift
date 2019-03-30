import Foundation

struct Deposit: Equatable {
    let proof: [Data]
    let index: UInt64
    let depositData: DepositData
}
