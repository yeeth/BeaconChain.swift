import Foundation

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ** : PowerPrecedence

extension UInt64 {

    static func ** (radix: UInt64, power: UInt64) -> UInt64 {
        return UInt64(pow(Double(radix), Double(power)))
    }
}

