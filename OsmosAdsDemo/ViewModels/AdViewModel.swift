import Foundation

@MainActor
@Observable
final class AdViewModel {

    var ads: [Ad] = []
    var isLoading = false
    var errorMessage: String?

    var statusText: String {
        if isLoading { return "Loading ads..." }
        if let error = errorMessage { return error }
        if !ads.isEmpty { return "\(ads.count) ads loaded" }
        return "Tap Load Ad to fetch advertisements."
    }

    var showRetry: Bool {
        errorMessage != nil && !isLoading
    }

    private let osmosService = OsmosService()
    private let trackingService = AdTrackingService()

    private(set) var impressionsFired: Set<String> = []

    func isImpressionFired(for ad: Ad) -> Bool {
        impressionsFired.contains(ad.id)
    }

    func loadAds() {
        guard !isLoading else {
            AppLogger.log("Load request ignored — already loading")
            return
        }

        isLoading = true
        errorMessage = nil
        ads = []
        impressionsFired = []

        Task {
            do {
                let fetchedAds = try await osmosService.fetchAds()
                self.ads = fetchedAds
            } catch {
                AppLogger.error("Ad loading failed: \(error.localizedDescription)")
                self.errorMessage = "Ad not available"
            }
            self.isLoading = false
        }
    }

    func onVisibilityChanged(for ad: Ad, ratio: CGFloat) {
        guard ratio >= 0.50 else { return }
        guard !impressionsFired.contains(ad.id) else { return }

        impressionsFired.insert(ad.id)

        let position = (ads.firstIndex(where: { $0.id == ad.id }) ?? 0) + 1
        trackingService.fireImpression(for: ad, position: position)
    }

    func handleClick(for ad: Ad) -> URL? {
        trackingService.fireClick(for: ad)

        guard let url = ad.destinationURL else {
            AppLogger.error("Ad has no destination URL")
            return nil
        }

        return url
    }
}
