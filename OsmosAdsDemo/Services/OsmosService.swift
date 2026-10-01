import Foundation
import osmos

final class OsmosService {

    func fetchAds() async throws -> [Ad] {
        AppLogger.log("Loading ads")

        let osmosManager = try OSMOS.shared()
        guard let adFetcher = osmosManager.adFetcher() else {
            throw OsmosServiceError.sdkNotConfigured
        }

        var fetchError: Error?

        let response = await adFetcher.fetchDisplayAdsWithAu(
            cliUbid: OsmosConfiguration.cliUbid,
            pageType: OsmosConfiguration.pageType,
            productCount: OsmosConfiguration.productCount,
            adUnits: [OsmosConfiguration.adUnit],
            targetingParams: nil,
            onError: { error in
                fetchError = error
            }
        )

        if let fetchError {
            AppLogger.error("Ad loading failed: \(fetchError.localizedDescription)")
            throw OsmosServiceError.fetchFailed(fetchError)
        }

        guard let response else {
            throw OsmosServiceError.emptyResponse
        }

        let ads = parseAds(from: response)

        if ads.isEmpty {
            AppLogger.log("No valid ads found in response")
            throw OsmosServiceError.noValidAds
        }

        AppLogger.log("Ads loaded: \(ads.count)")

        for (index, ad) in ads.enumerated() {
            print("""
            [OsmosAdsDemo] Ad \(index + 1) of \(ads.count):
              • Image URL:       \(ad.imageURL.absoluteString)
              • Destination URL: \(ad.destinationURL?.absoluteString ?? "None")
              • Dimensions:      \(ad.width.map(String.init) ?? "?") x \(ad.height.map(String.init) ?? "?") (Aspect Ratio: \(String(format: "%.2f", ad.aspectRatio)))
              • UCLID:           \(ad.uclid)
            """)
        }

        return ads
    }

    private func parseAds(from rawResponse: [String: Any]) -> [Ad] {
        var response = rawResponse

        if let nested = rawResponse["response"] as? [String: Any] {
            if let dataString = nested["data"] as? String,
               let data = dataString.data(using: .utf8),
               let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                response = jsonDict
            } else if let dataDict = nested["data"] as? [String: Any] {
                response = dataDict
            } else {
                response = nested
            }
        } else if let jsonString = rawResponse["response"] as? String,
                  let data = jsonString.data(using: .utf8),
                  let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            response = jsonDict
        } else if let dataString = rawResponse["data"] as? String,
                  let data = dataString.data(using: .utf8),
                  let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            response = jsonDict
        }

        if JSONSerialization.isValidJSONObject(response),
           let jsonData = try? JSONSerialization.data(withJSONObject: response, options: [.prettyPrinted, .sortedKeys]),
           let prettyJSON = String(data: jsonData, encoding: .utf8) {
            print("""
            \n==================== OSMOS ADS JSON RESPONSE ====================
            \(prettyJSON)
            =================================================================\n
            """)
        }

        if let adsDict = response["ads"] as? [String: Any] {
            if let adList = adsDict[OsmosConfiguration.adUnit] as? [[String: Any]] {
                let parsed = adList.compactMap { parseAd(from: $0) }
                if !parsed.isEmpty { return parsed }
            }
            if let adList = adsDict["banner_ads"] as? [[String: Any]] {
                let parsed = adList.compactMap { parseAd(from: $0) }
                if !parsed.isEmpty { return parsed }
            }
            for (_, val) in adsDict {
                if let adList = val as? [[String: Any]] {
                    let parsed = adList.compactMap { parseAd(from: $0) }
                    if !parsed.isEmpty { return parsed }
                }
            }
        }

        if let adUnitData = response[OsmosConfiguration.adUnit] as? [[String: Any]] {
            let parsed = adUnitData.compactMap { parseAd(from: $0) }
            if !parsed.isEmpty { return parsed }
        }

        if let adList = response["banner_ads"] as? [[String: Any]] {
            let parsed = adList.compactMap { parseAd(from: $0) }
            if !parsed.isEmpty { return parsed }
        }

        if let adList = response["ads"] as? [[String: Any]] {
            let parsed = adList.compactMap { parseAd(from: $0) }
            if !parsed.isEmpty { return parsed }
        }

        return []
    }

    private func parseAd(from dict: [String: Any]) -> Ad? {
        guard let uclid = dict["uclid"] as? String, !uclid.isEmpty else {
            AppLogger.error("Ad missing uclid, skipping")
            return nil
        }

        var imageURLString: String?
        var destinationURLString: String?
        var width: Int?
        var height: Int?

        if let elementDict = dict["elements"] as? [String: Any] {
            if let value = elementDict["value"] as? String {
                imageURLString = value
            }
            if let destURL = elementDict["destination_url"] as? String, !destURL.isEmpty, destURL != "null" {
                destinationURLString = destURL
            }
            width = parseDimension(elementDict["width"])
            height = parseDimension(elementDict["height"])
        } else if let elements = dict["elements"] as? [[String: Any]] {
            for element in elements {
                if let value = element["value"] as? String, imageURLString == nil {
                    imageURLString = value
                }
                if let destURL = element["destination_url"] as? String, !destURL.isEmpty, destURL != "null" {
                    destinationURLString = destURL
                }
                if width == nil { width = parseDimension(element["width"]) }
                if height == nil { height = parseDimension(element["height"]) }
            }
        }

        if imageURLString == nil {
            imageURLString = dict["image_url"] as? String
        }

        if destinationURLString == nil || destinationURLString == "null" {
            if let redirect = dict["redirect_url"] as? String, !redirect.isEmpty, redirect != "null" {
                destinationURLString = redirect
            } else if let clickURL = dict["click_tracking_url"] as? String, !clickURL.isEmpty, clickURL != "null" {
                destinationURLString = clickURL
            } else if let dest = dict["destination_url"] as? String, !dest.isEmpty, dest != "null" {
                destinationURLString = dest
            }
        }

        guard let urlString = imageURLString, let imageURL = URL(string: urlString) else {
            AppLogger.error("Ad has invalid or missing image URL, skipping")
            return nil
        }

        let destinationURL = destinationURLString.flatMap { URL(string: $0) }

        return Ad(
            id: uclid,
            imageURL: imageURL,
            destinationURL: destinationURL,
            uclid: uclid,
            width: width,
            height: height
        )
    }

    private func parseDimension(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let s = value as? String, let i = Int(s) { return i }
        return nil
    }
}

enum OsmosServiceError: LocalizedError {
    case sdkNotConfigured
    case fetchFailed(Error)
    case emptyResponse
    case noValidAds

    var errorDescription: String? {
        switch self {
        case .sdkNotConfigured:
            return "Osmos SDK is not configured"
        case .fetchFailed(let error):
            return "Failed to fetch ads: \(error.localizedDescription)"
        case .emptyResponse:
            return "Empty response from server"
        case .noValidAds:
            return "No valid ads in response"
        }
    }
}
