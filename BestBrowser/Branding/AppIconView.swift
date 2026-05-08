import SwiftUI
import AppKit

struct AppIconView: View {
    var size: CGFloat = 128

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(
                    LinearGradient(
                        colors: [BestBrowserBrand.darkBg, BestBrowserBrand.darkCard, BestBrowserBrand.accent.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(BestBrowserBrand.primary.opacity(0.12))
                .frame(width: size * 0.74, height: size * 0.74)
                .offset(y: -size * 0.1)

            RoundedRectangle(cornerRadius: size * 0.16)
                .stroke(BestBrowserBrand.primary.opacity(0.82), lineWidth: max(1.5, size * 0.018))
                .padding(size * 0.1)

            VStack(spacing: size * 0.06) {
                HStack(spacing: size * 0.04) {
                    Circle().fill(BestBrowserBrand.error).frame(width: size * 0.055, height: size * 0.055)
                    Circle().fill(BestBrowserBrand.warning).frame(width: size * 0.055, height: size * 0.055)
                    Circle().fill(BestBrowserBrand.primary).frame(width: size * 0.055, height: size * 0.055)
                    Spacer()
                }
                .padding(.horizontal, size * 0.16)
                .padding(.top, size * 0.14)

                ShieldMark(size: size * 0.42)
                    .shadow(color: BestBrowserBrand.primary.opacity(0.28), radius: size * 0.05)

                SignalWave()
                    .stroke(BestBrowserBrand.secondary, style: StrokeStyle(lineWidth: size * 0.034, lineCap: .round))
                    .frame(width: size * 0.56, height: size * 0.16)
                    .padding(.bottom, size * 0.14)
            }
        }
        .frame(width: size, height: size)
    }
}

struct BrandGraphicView: View {
    let resourceName: String
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat? = nil

    var body: some View {
        if let image = Self.loadImage(named: resourceName) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? min(width, height) * 0.18))
        }
    }

    private static func loadImage(named name: String) -> NSImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "BrandingAssets") {
            return NSImage(contentsOf: url)
        }
        return nil
    }

    static func exists(named name: String) -> Bool {
        loadImage(named: name) != nil
    }
}

private struct ShieldMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            ShieldShape()
                .fill(
                    LinearGradient(
                        colors: [BestBrowserBrand.primary, BestBrowserBrand.accent, BestBrowserBrand.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundColor(BestBrowserBrand.fog)
        }
        .frame(width: size, height: size * 1.04)
    }
}

private struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.height * 0.28),
                      control1: CGPoint(x: rect.width * 0.68, y: rect.minY),
                      control2: CGPoint(x: rect.maxX, y: rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.58))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                      control1: CGPoint(x: rect.maxX, y: rect.height * 0.82),
                      control2: CGPoint(x: rect.width * 0.68, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.height * 0.58),
                      control1: CGPoint(x: rect.width * 0.32, y: rect.maxY),
                      control2: CGPoint(x: rect.minX, y: rect.height * 0.82))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.28))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                      control1: CGPoint(x: rect.minX, y: rect.height * 0.08),
                      control2: CGPoint(x: rect.width * 0.32, y: rect.minY))
        return path
    }
}

private struct SignalWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY + rect.height * 0.1),
                      control1: CGPoint(x: rect.width * 0.18, y: rect.maxY),
                      control2: CGPoint(x: rect.width * 0.72, y: rect.minY))
        return path
    }
}

#Preview {
    VStack(spacing: 40) {
        AppIconView(size: 128)
        AppIconView(size: 256)
    }
    .background(Color(NSColor.windowBackgroundColor))
    .padding()
}
