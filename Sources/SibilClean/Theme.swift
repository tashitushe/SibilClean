import SwiftUI

enum Theme {
    static let accent = Color(hex: 0x3450E6)
    static let coral = Color(hex: 0xE0653F)
    static let teal = Color(hex: 0x0E9488)
    static let okDot = Color(hex: 0x1FAE7B)

    static let blobA = Color(hex: 0x4F6BFF)
    static let blobB = Color(hex: 0x17C3B2)
    static let blobC = Color(hex: 0xFF8A65)

    static let textPrimary = Color(hex: 0x12172B)
    static let textMuted = Color(hex: 0x525C74)
    static let textFaint = Color(hex: 0x7E88A3)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Soft blurred color blobs echoing the farnoud.net background, sitting
/// behind the Liquid Glass surfaces.
struct BackdropBlobs: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.blobA.opacity(0.35))
                .frame(width: 420, height: 420)
                .blur(radius: 120)
                .offset(x: -160, y: -220)

            Circle()
                .fill(Theme.blobB.opacity(0.30))
                .frame(width: 380, height: 380)
                .blur(radius: 130)
                .offset(x: 200, y: 120)

            Circle()
                .fill(Theme.blobC.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 120)
                .offset(x: -120, y: 260)
        }
    }
}
