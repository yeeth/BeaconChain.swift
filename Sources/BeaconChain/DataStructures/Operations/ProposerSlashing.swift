import Foundation

struct ProposerSlashing {
    let proposerIndex: Int // says 24 but whatever
    let proposalData1: ProposalSignedData
    let proposalSignature1: Data
    let proposalData2: ProposalSignedData
    let proposalSignature2: Data
}
