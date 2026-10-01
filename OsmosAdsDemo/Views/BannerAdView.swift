import SwiftUI

struct BannerAdView: View {
    let ad: Ad
    var isImpressionFired: Bool = false
    var viewport: CGRect = .zero
    let onVisibilityChanged: (CGFloat) -> Void
    let onTap: () -> Void

    @State private var isImageLoaded = false
    @State private var isImageFailed = false
    @State private var retryID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Spacer()

                if isImageFailed {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("Image Failed to Load — Impression Blocked")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                    .transition(.opacity)
                } else if isImpressionFired {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("Impression Fired (≥50%)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                    .transition(.opacity)
                }
            }

            AsyncImage(url: ad.imageURL) { phase in
                switch phase {
                case .success(let image):
                    Button(action: onTap) {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(ad.aspectRatio, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        isImageLoaded = true
                        isImageFailed = false
                    }

                case .failure:
                    failurePlaceholder
                        .onAppear {
                            isImageLoaded = false
                            isImageFailed = true
                        }

                case .empty:
                    ZStack {
                        Color(.systemGray6)
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(ad.aspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                @unknown default:
                    failurePlaceholder
                }
            }
            .id(retryID)
        }
        .animation(.easeInOut(duration: 0.25), value: isImpressionFired)
        .animation(.easeInOut(duration: 0.25), value: isImageFailed)
        .accessibilityLabel("Banner advertisement")
        .accessibilityHint("Double tap to open advertisement")
        .trackVisibility(
            in: viewport,
            isActive: isImageLoaded && !isImageFailed
        ) { visibleRatio in
            onVisibilityChanged(visibleRatio)
        }
    }

    @ViewBuilder
    private var failurePlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Image failed to load")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                isImageFailed = false
                isImageLoaded = false
                retryID = UUID()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry Image")
                }
                .font(.caption.weight(.medium))
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(ad.aspectRatio, contentMode: .fit)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
