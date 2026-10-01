import SwiftUI

struct VisibilityTracker: ViewModifier {
    let viewport: CGRect
    var isTrackingActive: Bool = true
    let onVisibilityChanged: (CGFloat) -> Void

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            checkVisibility(geometry: geometry)
                        }
                        .onChange(of: geometry.frame(in: .global)) {
                            checkVisibility(geometry: geometry)
                        }
                        .onChange(of: viewport) {
                            checkVisibility(geometry: geometry)
                        }
                        .onChange(of: isTrackingActive) {
                            checkVisibility(geometry: geometry)
                        }
                }
            )
    }

    private func checkVisibility(geometry: GeometryProxy) {
        guard isTrackingActive else { return }

        let viewFrame = geometry.frame(in: .global)
        guard viewFrame.width > 0, viewFrame.height > 0 else { return }

        let activeViewport: CGRect
        if viewport.width > 0 && viewport.height > 0 {
            activeViewport = viewport
        } else {
            activeViewport = UIScreen.main.bounds
        }

        let intersection = viewFrame.intersection(activeViewport)
        guard !intersection.isNull else {
            onVisibilityChanged(0)
            return
        }

        let visibleHeight = max(0, intersection.height)
        let ratio = visibleHeight / viewFrame.height
        let clampedRatio = min(max(ratio, 0), 1)

        onVisibilityChanged(clampedRatio)
    }
}

extension View {
    func trackVisibility(
        in viewport: CGRect = .zero,
        isActive: Bool = true,
        onVisibilityChanged: @escaping (CGFloat) -> Void
    ) -> some View {
        modifier(VisibilityTracker(viewport: viewport, isTrackingActive: isActive, onVisibilityChanged: onVisibilityChanged))
    }
}
