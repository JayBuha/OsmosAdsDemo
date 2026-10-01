import Foundation
import osmos

final class AdTrackingService {

    func fireImpression(for ad: Ad, position: Int) {
        Task {
            do {
                let osmosManager = try OSMOS.shared()
                guard let registerEvent = osmosManager.registerEvent() else {
                    AppLogger.error("RegisterEvent not available")
                    return
                }

                _ = await registerEvent.registerAdImpressionEvent(
                    cliUbid: OsmosConfiguration.cliUbid,
                    uclid: ad.uclid,
                    position: position,
                    onError: { error in
                        AppLogger.error("Impression tracking failed: \(error.localizedDescription)")
                    }
                )

                AppLogger.log("Impression fired for ad: \(ad.id)")
            } catch {
                AppLogger.error("Failed to access SDK for impression: \(error.localizedDescription)")
            }
        }
    }

    func fireClick(for ad: Ad) {
        Task {
            do {
                let osmosManager = try OSMOS.shared()
                guard let registerEvent = osmosManager.registerEvent() else {
                    AppLogger.error("RegisterEvent not available")
                    return
                }

                _ = await registerEvent.registerAdClickEvent(
                    cliUbid: OsmosConfiguration.cliUbid,
                    uclid: ad.uclid,
                    trackingParams: nil,
                    onError: { error in
                        AppLogger.error("Click tracking failed: \(error.localizedDescription)")
                    }
                )

                AppLogger.log("Click fired for ad: \(ad.id)")
            } catch {
                AppLogger.error("Failed to access SDK for click: \(error.localizedDescription)")
            }
        }
    }
}
