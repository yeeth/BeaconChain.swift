import Foundation

struct BeaconBlockBody: Equatable {
    let randaoReveal: BLSSignature
    let eth1Data: Eth1Data
    let graffiti: Bytes32
    let proposerSlashings: [ProposerSlashing]
    let attesterSlashings: [AttesterSlashing]
    let attestations: [Attestation]
    let deposits: [Deposit]
    let voluntaryExits: [VoluntaryExit]
    let transfers: [Transfer]
}
