import Foundation

extension Array {

    func shuffle(seed: Data) -> Array {
        let randBytes = 3
        let randMax = (Int(2)**Int(randBytes * 8)) - 1

        assert(self.count < randMax)

        var output = self
        var source = seed

        var index = 0
        while index < self.count - 1 {
            source = BeaconChain.hash(data: source)

            for i in stride(from: 0, through: 32 - 32.mod(randBytes), by: randBytes) {
                let remaining = self.count - index
                if remaining == 1 {
                    break
                }

                let sampleFromSource = source.subdata(in: Range(i...(i + randBytes))).withUnsafeBytes {
                    (ptr: UnsafePointer<Int>) -> Int in
                    return ptr.pointee
                }

                let sampleMax = randMax - randMax.mod(remaining)

                if sampleFromSource < sampleMax {
                    let replacementPosition = sampleFromSource.mod(remaining) + index
                    (output[index], output[replacementPosition]) = (output[replacementPosition], output[index])
                    index += 1
                }
            }
        }

        return output
    }
}
