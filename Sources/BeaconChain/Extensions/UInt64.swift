import Foundation

extension UInt64 {

    func sqrt() -> UInt64 {
        assert(n >= 0)

        var x = n
        var y = (x + 1) / 2

        while y < x {
            x = y
            y = (x + n / x) / 2
        }

        return x
    }

}
