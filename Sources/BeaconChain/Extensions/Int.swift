import Foundation

extension Int {

    func mod(_ right: Int) -> Int {
        return Int(fmod(Double(self), Double(right)))
    }
}

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ** : PowerPrecedence
func ** (radix: Int, power: Int) -> Int {
    return Int(pow(Double(radix), Double(power)))
}
