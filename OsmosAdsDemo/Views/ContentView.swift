import SwiftUI

struct ContentView: View {
    @State private var viewModel = AdViewModel()
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Button {
                    viewModel.loadAds()
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Load Ad")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Load advertisements")
                .padding(.horizontal)

                AdStatusView(
                    statusText: viewModel.statusText,
                    showRetry: viewModel.showRetry,
                    onRetry: { viewModel.loadAds() }
                )
                .padding(.horizontal)

                if viewModel.ads.isEmpty && !viewModel.isLoading {
                    Spacer()
                } else {
                    GeometryReader { scrollProxy in
                        let viewport = scrollProxy.frame(in: .global)
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.ads) { ad in
                                    BannerAdView(
                                        ad: ad,
                                        isImpressionFired: viewModel.isImpressionFired(for: ad),
                                        viewport: viewport
                                    ) { visibleRatio in
                                        viewModel.onVisibilityChanged(for: ad, ratio: visibleRatio)
                                    } onTap: {
                                        if let url = viewModel.handleClick(for: ad) {
                                            openURL(url)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .navigationTitle("Osmos Ads Demo")
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("-autoLoadAds") {
                    viewModel.loadAds()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
