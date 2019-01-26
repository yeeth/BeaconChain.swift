import Foundation

public extension Int {

    public func mod(_ right: Int) -> Int {
        return Int(fmod(Double(self), Double(right)))
    }

    public static func ** (radix: Int, power: Int) -> Int {
        return Int(pow(Double(radix), Double(power)))
    }

}
