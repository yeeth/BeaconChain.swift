import Foundation

public struct BlockBody {
    // @todo
    let proposerSlashings: [ProposerSlashing]
    let casperSlashings: [CasperSlashing]

// @todo will be defined in 1.0
//    let custodyReseeds: [CustodyReseed]
//    let custodyChallenges: [CustodyChallenge]
//    let custodyResponses: [CustodyResponse]

    let attestations: [Attestation]
    let deposits: [Deposit]
    let exits: [Exit]
}
