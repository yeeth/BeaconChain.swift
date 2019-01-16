import Foundation

struct SlashableVoteData {
    let custodyBit0indices: [Int]
    let custodyBit1indices: [Int]
    let data: AttestationData
    let aggregateSignature: [Data]
}
