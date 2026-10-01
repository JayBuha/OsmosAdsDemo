import XCTest
@testable import OsmosAdsDemo

final class AdViewModelTests: XCTestCase {

    @MainActor
    func testImpressionFiresAt50Percent() {
        let viewModel = AdViewModel()
        let ad = makeTestAd(id: "test-1")
        viewModel.ads = [ad]

        viewModel.onVisibilityChanged(for: ad, ratio: 0.50)
        XCTAssertTrue(viewModel.isImpressionFired(for: ad))
    }

    @MainActor
    func testImpressionDoesNotFireBelow50Percent() {
        let viewModel = AdViewModel()
        let ad = makeTestAd(id: "test-2")
        viewModel.ads = [ad]

        viewModel.onVisibilityChanged(for: ad, ratio: 0.30)
        XCTAssertFalse(viewModel.isImpressionFired(for: ad))

        viewModel.onVisibilityChanged(for: ad, ratio: 0.49)
        XCTAssertFalse(viewModel.isImpressionFired(for: ad))
    }

    @MainActor
    func testImpressionDoesNotFireTwice() {
        let viewModel = AdViewModel()
        let ad = makeTestAd(id: "test-3")
        viewModel.ads = [ad]

        viewModel.onVisibilityChanged(for: ad, ratio: 0.50)
        XCTAssertTrue(viewModel.isImpressionFired(for: ad))

        viewModel.onVisibilityChanged(for: ad, ratio: 0.80)
        viewModel.onVisibilityChanged(for: ad, ratio: 1.00)
        viewModel.onVisibilityChanged(for: ad, ratio: 0.50)
        XCTAssertEqual(viewModel.impressionsFired.count, 1)
    }

    @MainActor
    func testDuplicateLoadPrevented() {
        let viewModel = AdViewModel()
        viewModel.loadAds()
        XCTAssertTrue(viewModel.isLoading)
    }

    func testAdModelCreation() {
        let ad = Ad(
            id: "test-id",
            imageURL: URL(string: "https://example.com/image.jpg")!,
            destinationURL: URL(string: "https://example.com"),
            uclid: "test-uclid",
            width: 320,
            height: 250
        )

        XCTAssertEqual(ad.id, "test-id")
        XCTAssertEqual(ad.aspectRatio, 320.0 / 250.0)
    }

    func testAdModelDefaultAspectRatio() {
        let ad = Ad(
            id: "test-id-2",
            imageURL: URL(string: "https://example.com/image.jpg")!,
            destinationURL: nil,
            uclid: "test-uclid-2",
            width: nil,
            height: nil
        )

        XCTAssertEqual(ad.aspectRatio, 16.0 / 9.0)
    }

    @MainActor
    func testClickWithNoDestinationURL() {
        let viewModel = AdViewModel()
        let ad = Ad(
            id: "no-dest",
            imageURL: URL(string: "https://example.com/image.jpg")!,
            destinationURL: nil,
            uclid: "no-dest-uclid",
            width: nil,
            height: nil
        )

        let url = viewModel.handleClick(for: ad)
        XCTAssertNil(url)
    }

    @MainActor
    func testClickWithValidDestinationURL() {
        let viewModel = AdViewModel()
        let dest = URL(string: "https://example.com/product")!
        let ad = Ad(
            id: "valid-dest",
            imageURL: URL(string: "https://example.com/image.jpg")!,
            destinationURL: dest,
            uclid: "valid-dest-uclid",
            width: nil,
            height: nil
        )

        let url = viewModel.handleClick(for: ad)
        XCTAssertEqual(url, dest)
    }

    private func makeTestAd(id: String) -> Ad {
        Ad(
            id: id,
            imageURL: URL(string: "https://example.com/ad.jpg")!,
            destinationURL: URL(string: "https://example.com")!,
            uclid: id,
            width: 320,
            height: 250
        )
    }
}
