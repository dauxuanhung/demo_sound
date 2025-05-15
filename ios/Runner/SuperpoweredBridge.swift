import Foundation

@objc class SuperpoweredBridge: NSObject {
    @objc static func detectBpm(from path: String) -> Float {
        return detectBpmFromFile(path)
    }
}
