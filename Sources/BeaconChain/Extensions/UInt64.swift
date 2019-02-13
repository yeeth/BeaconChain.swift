import Foundation

extension UInt64 {

    func sqrt() -> UInt64 {
        assert(self >= 0)

        var x = self
        var y = (x + 1) / 2

        while y < x {
            x = y
            y = (x + self / x) / 2
        }

        return x
    }

}
