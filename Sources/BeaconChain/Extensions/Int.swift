import Foundation

extension Int {

    func isPowerOfTwo() -> Bool {
        if self == 0 {
            return false
        }

        return 2 ** Int(log2(Double(self))) == self
    }
}
