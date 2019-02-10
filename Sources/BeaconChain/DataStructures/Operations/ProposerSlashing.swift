import Foundation

struct ProposerSlashing {
    let proposerIndex: UInt64
    let proposalData1: ProposalSignedData
    let proposalSignature1: Data
    let proposalData2: ProposalSignedData
    let proposalSignature2: Data
}
