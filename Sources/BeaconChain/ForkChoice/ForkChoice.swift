import Foundation

protocol ForkChoice {

    func execute(store: Store, startState: BeaconState, startBlock: BeaconBlock) -> BeaconBlock

}
