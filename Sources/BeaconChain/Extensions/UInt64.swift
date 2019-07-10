import Foundation

extension UInt64 {

    /// Return the largest integer ``x`` such that ``x**2 <= n``.
    func sqrt() -> UInt64 {
        var x = self
        var y = (x + 1) / 2

        while y < x {
            x = y
            y = (x + self / x) / 2
        }

        return x
    }

}
