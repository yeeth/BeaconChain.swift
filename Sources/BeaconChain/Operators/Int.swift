import Foundation

extension Int {

    static func ** (radix: Int, power: Int) -> Int {
        return Int(pow(Double(radix), Double(power)))
    }
}

