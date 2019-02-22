import Foundation

extension Int {

    func isPowerOfTwo() -> Bool {
        return (self > 0) && (self & (self - 1) == 0)
    }
}
