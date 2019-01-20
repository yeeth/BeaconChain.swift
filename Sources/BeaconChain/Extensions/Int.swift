import Foundation

extension Int {

    func mod(_ right: Int) -> Int {
        return Int(fmod(Double(self), Double(right)))
    }
}
