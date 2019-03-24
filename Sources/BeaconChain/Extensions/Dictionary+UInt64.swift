import Foundation

extension Dictionary where Key == UInt64 {

    mutating func append(_ element: Value) {
        self[UInt64(count + 1)] = element
    }
}