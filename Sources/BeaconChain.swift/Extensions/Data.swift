import Foundation

extension Data {

    func xor(key: Data) -> Data {
        for i in 0..<self.count {
            self[i] ^= key[i % key.count]
        }

        return self
    }

}
