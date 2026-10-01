# OsmosAdsDemo

A native iOS demo application built with **SwiftUI** and **MVVM** integrating the **Osmos Ads iOS SDK**. It fetches AU-based display banner ads, renders them in a scrollable feed maintaining aspect ratios, tracks impressions at 50% visibility, and handles ad clicks with URL navigation.

---

## Requirements

- **Xcode** 15.0+
- **iOS** 17.0+ (compatible down to iOS 15.0)
- **Swift** 5.9+
- **Osmos SDK**: `osmos-ios-sdk-spm` (v3.0.1) & `osmos-network-ad-core-spm` (v2.0.0)

---

## Setup & Running

1. **Open** `OsmosAdsDemo.xcodeproj` in Xcode.
2. **Resolve Packages**: Xcode automatically downloads dependencies via Swift Package Manager (**File → Packages → Resolve Package Versions**).
3. **Run**: Select an iOS Simulator (e.g. iPhone 16) and press `Cmd + R`.
4. **Run Unit Tests**: Press `Cmd + U` to execute the XCTest suite in `OsmosAdsDemoTests`.

> **Configuration**: All credentials are centralized in [`OsmosConfiguration.swift`](OsmosAdsDemo/App/OsmosConfiguration.swift):
> `clientId = 10088010`, `productAdsHost = "demo.o-s.io"`, `displayAdsHost = "demo-ba.o-s.io"`.

---

## How It Works

### 1. Ad Fetching (AU-based)
- **Init**: SDK initializes at launch in `OsmosAdsDemoApp.swift` via `OSMOS.Builder().buildGlobalInstance()`.
- **Request**: When tapping **"Load Ad"**, `OsmosService` calls `AdFetcher.fetchDisplayAdsWithAu` with:
  - `pageType: "demo_page"`
  - `adUnit: "banner_ads"`
  - `cliUbid: "10088010"`
  - `productCount: 5`
- **Parsing**: Extracts `elements.value` (Image URL), `elements.destination_url` (Landing URL), dimensions (`width`/`height`), and `uclid` tracking ID.

### 2. Banner Rendering
- Displays banners in a vertical `ScrollView` using `LazyVStack`.
- Loads images asynchronously via SwiftUI `AsyncImage`.
- Preserves native dimensions dynamically with `aspectRatio = width / height` (zero image distortion).

### 3. Impression Tracking (≥50% Visibility)
- **Detection**: `VisibilityTracker` calculates intersection between the ad card and the `ScrollView`'s active viewport using `GeometryReader`.
- **Threshold**: Fires only when `visibleHeight / totalHeight >= 0.50`.
- **Deduplication**: `AdViewModel` stores fired IDs in a `Set<String>`, guaranteeing exactly **one impression per ad**.
- **SDK Event**: Calls `registerAdImpressionEvent(cliUbid:uclid:position:)`.
- **Integrity**: Impressions are strictly blocked if an ad image fails to load.

### 4. Click Tracking & Navigation
- Tapping an ad calls `registerAdClickEvent(cliUbid:uclid:)`.
- Opens `elements.destination_url` in the browser via SwiftUI `openURL`.
- Gracefully handles missing/invalid URLs without crashing.

---

## Architecture (MVVM)

```
View (ContentView + BannerAdView)
   ↓ User Actions / Visibility Updates
ViewModel (AdViewModel)
   ↓ Business Logic
├── OsmosService (Ad Fetching & Parsing)
└── AdTrackingService (Impression & Click SDK Events)
```

| Component | Responsibility |
|---|---|
| **ContentView** | Primary screen with "Load Ad" button, status view, and scrollable feed. |
| **BannerAdView** | Banner card, aspect-ratio image loader, and live impression badge. |
| **AdViewModel** | State (`ads`, `isLoading`, `errorMessage`), request locking, and impression dedup. |
| **OsmosService** | Fetches display ads from Osmos SDK and parses JSON payload into `Ad` models. |
| **AdTrackingService** | Registers impression and click events with the Osmos SDK. |
| **VisibilityTracker** | Reusable view modifier computing viewport intersection percentage. |

---

## Error Handling & Resilience

- **Failures Handled**: Network errors, empty responses, malformed fields, and missing URLs.
- **Fallback UI**: Displays `"Ad not available"` with an interactive **"Retry"** button.
- **Image Failure**: Displays `"Image Failed to Load — Impression Blocked"` and offers an inline **"Retry Image"** button.
- **Request Guard**: Disables the load button while fetching to prevent duplicate network calls.

---

## Assumptions & Challenges

1. **AU Parameters**: The assignment PDF mentions `cliUbid = "Any"`, while the live Osmos server validates `cli_ubid = "10088010"`. We use `10088010`.
2. **SwiftUI Viewport Detection**: Standard `UIScreen.main.bounds` includes system bars. We wrapped `ScrollView` in a `GeometryReader` to measure intersection strictly against the scroll container's visible bounds.
3. **No Impression on Broken Creative**: If an ad image fails to load, visibility tracking is suppressed to ensure advertiser attribution standards.

---

## How to Test Manually

1. **Launch App**: Tap **"Load Ad"** → Status shows `"3 ads loaded"`.
2. **Impression Verification**: The top visible ads immediately show `✓ Impression Fired (≥50%)`.
3. **Scroll Test**: Scroll down → The 3rd ad enters the viewport and triggers its impression once 50% is visible.
4. **Dedup Test**: Scroll back and forth → Verify no duplicate impressions are fired.
5. **Click Test**: Tap an ad → Verify click event logs in console and destination URL opens.
6. **Error / Retry Test**: Enable Airplane Mode, tap "Load Ad" → Verify `"Ad not available"` and **"Retry"** button appear.
