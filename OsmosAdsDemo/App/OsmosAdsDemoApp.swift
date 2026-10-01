import SwiftUI
import osmos

@main
struct OsmosAdsDemoApp: App {

    init() {
        initializeOsmosSDK()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func initializeOsmosSDK() {
        do {
            try OSMOS.Builder()
                .clientId(OsmosConfiguration.clientId)
                .displayAdsHost(OsmosConfiguration.displayAdsHost)
                .productAdsHost(OsmosConfiguration.productAdsHost)
                .debug(true)
                .buildGlobalInstance()

            AppLogger.log("SDK initialized")
        } catch {
            AppLogger.error("Failed to initialize Osmos SDK: \(error.localizedDescription)")
        }
    }
}
