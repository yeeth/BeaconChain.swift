import Foundation

extension Numeric {

    // @todo kinda ugly?
    var bytes32: Data {
        var source = self

        return Data(bytes: &source, count: 32)
    }

}
