import Foundation

/// The actual message signed by validators.
public struct AttestationDataAndCustodyBit {
    public let data: AttestationData
    public let custodyBit: Bool // @todo probably not the best?
}
