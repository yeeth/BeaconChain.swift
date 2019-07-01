import Foundation

struct Deposit: Equatable {
    let branch: [Data]
    let index: UInt64
    let depositData: DepositData
}
