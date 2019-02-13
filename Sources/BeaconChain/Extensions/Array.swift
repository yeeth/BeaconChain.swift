import Foundation

extension Array {

    func split(count: Int) -> [[Element]] {
        let length = self.count

        return (0..<count).map {
            Array(self[(length * $0 / count) ..< (length * ($0 + 1) / count)])
        }
    }

}
