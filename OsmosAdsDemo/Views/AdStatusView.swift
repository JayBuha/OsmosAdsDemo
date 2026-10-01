import SwiftUI

struct AdStatusView: View {
    let statusText: String
    let showRetry: Bool
    let onRetry: () -> Void

    var body: some View {
        HStack {
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(showRetry ? .red : .secondary)

            Spacer()

            if showRetry {
                Button("Retry", action: onRetry)
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Retry loading advertisements")
            }
        }
    }
}
