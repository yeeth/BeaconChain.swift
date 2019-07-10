import Foundation

extension Data {

    /// Return the exclusive-or of two byte strings.
    static func ^(left: Data, right: Data) -> Data {
        var temp = left

        for i in 0..<left.count {
            temp[i] ^= right[i % right.count]
        }

        return temp
    }
}
