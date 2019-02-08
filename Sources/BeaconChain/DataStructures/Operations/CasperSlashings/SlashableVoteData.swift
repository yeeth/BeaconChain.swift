import Foundation

struct SlashableVoteData {
    let custodyBit0Indices: [UInt32] // @todo should be UInt24
    let custodyBit1Indices: [UInt32] // @todo should be UInt24
    let data: AttestationData
    let aggregateSignature: Data
}
