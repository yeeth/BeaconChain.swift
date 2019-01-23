import Foundation

func ^(left: Data, right: Data) -> Data {
    var temp = left

    for i in 0..<left.count {
        temp[i] ^= right[i % right.count]
    }

    return temp
}

func <(left: Data, right: Data) -> Bool {
    for i in 0...left.count {
        if left[i] > right[i] {
            return false
        }
    }

    return true
}
