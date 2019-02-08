import Foundation

struct BeaconBlockBody {
    let proposerSlashings: [ProposerSlashing]
    let casperSlashings: [CasperSlashing]
    let attestations: [Attestation]

//    @todo will be defined in 1.0
//    let custodyReseeds: [CustodyReseed]
//    let custodyChallenges: [CustodyChallenge]
//    let custodyResponses: [CustodyResponse]

    let deposits: [Deposit]
    let exits: [Exit]
}
