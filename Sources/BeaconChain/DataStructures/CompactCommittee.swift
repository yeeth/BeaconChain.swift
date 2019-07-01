import Foundation

struct CompactCommittee {
    let pubkeys = Array(repeating: 0, count: Int(MAX_VALIDATORS_PER_COMMITTEE)) // @todo
    let compactValidators = Array(repeating: 0, count: Int(MAX_VALIDATORS_PER_COMMITTEE)) // @todo
}
