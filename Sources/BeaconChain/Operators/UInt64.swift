import Foundation

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ** : PowerPrecedence
func ** (radix: UInt64, power: UInt64) -> UInt64 {
    return UInt64(pow(Double(radix), Double(power)))
}
