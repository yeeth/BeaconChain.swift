import Foundation

struct BeaconBlockBody: Equatable {
    let randaoReveal: Data
    let eth1Data: Eth1Data
    let proposerSlashings: [ProposerSlashing]
    let attesterSlashings: [AttesterSlashing]
    let attestations: [Attestation]
    let deposits: [Deposit]
    let voluntaryExits: [VoluntaryExit]
    let transfers: [Transfer]
}
