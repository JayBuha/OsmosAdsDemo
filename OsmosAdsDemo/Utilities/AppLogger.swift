import Foundation

enum AppLogger {
    private static let tag = "[OsmosAdsDemo]"

    static func log(_ message: String) {
        print("\(tag) \(message)")
    }

    static func error(_ message: String) {
        print("\(tag) ERROR: \(message)")
    }
}
