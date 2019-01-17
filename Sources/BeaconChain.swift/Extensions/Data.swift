import Foundation

extension Data {

    func xor(key: Data) -> Data {
        var temp = self;

        for i in 0..<self.count {
            temp[i] ^= key[i % key.count]
        }

        return temp
    }

}
