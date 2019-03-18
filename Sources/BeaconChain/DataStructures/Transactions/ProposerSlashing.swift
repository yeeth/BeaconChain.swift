import Foundation

struct ProposerSlashing: Equatable {
    let proposerIndex: UInt64
    let proposal1: Proposal
    let proposal2: Proposal
}
