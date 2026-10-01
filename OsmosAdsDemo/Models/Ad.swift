import Foundation

struct Ad: Identifiable {
    let id: String
    let imageURL: URL
    let destinationURL: URL?
    let uclid: String
    let width: Int?
    let height: Int?

    var aspectRatio: CGFloat {
        guard let w = width, let h = height, w > 0, h > 0 else {
            return 16.0 / 9.0
        }
        return CGFloat(w) / CGFloat(h)
    }
}
