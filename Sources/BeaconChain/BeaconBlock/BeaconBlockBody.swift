import Foundation

struct BeaconBlockBody {
    let randaoReveal: BLSSignature
    let eth1Data: Eth1Data
    let graffiti: Data
    let proposerSlashings: [ProposerSlashing]
    let attesterSlashings: [AttesterSlashing]
    let attestations: [Attestation]
    let deposits: [Deposit]
    let voluntaryExits: [VoluntaryExit]
    let transfers: [Transfer]
}
