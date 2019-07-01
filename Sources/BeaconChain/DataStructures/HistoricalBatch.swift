import Foundation

struct HistoricalBatch {
    let blockRoots = Array(repeating: Data(repeating: 0, count: 32), count: Int(SLOTS_PER_HISTORICAL_ROOT))
    let stateRoots = Array(repeating: Data(repeating: 0, count: 32), count: Int(SLOTS_PER_HISTORICAL_ROOT))
}
