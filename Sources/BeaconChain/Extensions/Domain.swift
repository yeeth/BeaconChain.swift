import Foundation

extension Domain {

    /// Return the domain for the `DomainType` and `Version`.
    ///
    /// - Parameters
    ///     - type: The domain type.
    ///     - fork: The fork version.
    init(type: DomainType, fork: Version) {
        self.init(UInt64(type.rawValue + fork))
    }
}
