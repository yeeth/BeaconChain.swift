import Foundation

protocol BlockTransitions {

    static func transition(state: inout BeaconState, block: BeaconBlock);
}
