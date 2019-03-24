import Foundation

typealias Slot = UInt64
typealias Epoch = UInt64
typealias Shard = UInt64
typealias ValidatorIndex = UInt64
typealias Gwei = UInt64
typealias Bytes32 = Data // @todo needs to be 32 fixed length data
typealias BLSPubkey = Data // @todo needs to be 48 fixed length data
typealias BLSSignature = Data // @todo needs to be 96 fixed length data

typealias AttestationTarget = (ValidatorIndex, BeaconBlock)
