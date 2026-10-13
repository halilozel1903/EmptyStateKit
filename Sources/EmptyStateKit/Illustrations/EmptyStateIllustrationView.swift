import SwiftUI

/// Draws an ``EmptyStateIllustration`` on a soft circular backdrop, in the given tint.
///
/// The view is square and fills the space it is given: set its size with `frame(width:height:)`. It is hidden from
/// VoiceOver, since the title says the same thing.
public struct EmptyStateIllustrationView: View {
    private let illustration: EmptyStateIllustration
    private let tint: Color?

    @Environment(\.colorScheme) private var colorScheme

    public init(_ illustration: EmptyStateIllustration, tint: Color? = nil) {
        self.illustration = illustration
        self.tint = tint
    }

    public var body: some View {
        if illustration != EmptyStateIllustration.none {
            GeometryReader { geometry in
                let side = min(geometry.size.width, geometry.size.height)
                ZStack {
                    Backdrop(accent: accent, isDark: isDark)
                    artwork(side: side)
                }
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)
        }
    }

    private var accent: Color { tint ?? .accentColor }
    private var isDark: Bool { colorScheme == .dark }

    /// The main fill: the tint, a little lighter at the top.
    private var fill: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(isDark ? 0.8 : 0.72), accent],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Paper and glass: white in light mode, a raised grey in dark mode.
    private var surface: Color {
        isDark ? Color(white: 0.2) : .white
    }

    /// The marks on a filled shape (the exclamation mark, the keyhole).
    private var mark: Color {
        isDark ? Color(white: 0.12) : .white
    }

    @ViewBuilder
    private func artwork(side: CGFloat) -> some View {
        switch illustration {
        case .magnifier: magnifier(side)
        case .tray: tray(side)
        case .cloudOffline: cloudOffline(side)
        case .warning: warning(side)
        case .lock: lock(side)
        case .sparkles: sparkles(side)
        case .systemImage(let name):
            Image(systemName: name)
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .foregroundStyle(fill)
                .padding(side * 0.27)
        case .none:
            EmptyView()
        }
    }

    // MARK: No results

    private func magnifier(_ side: CGFloat) -> some View {
        ZStack {
            // A page with lines of text.
            let page = UnitShape { unit in
                Path(roundedRect: unit.rect(x: 0.2, y: 0.2, width: 0.42, height: 0.52), cornerRadius: unit.length(0.05))
            }
            page.fill(surface)
            page.stroke(accent.opacity(0.28), lineWidth: side * 0.014)
            UnitShape { unit in
                var path = Path()
                for (y, width) in [(0.3, 0.27), (0.39, 0.21), (0.48, 0.25), (0.57, 0.15)] {
                    path.addRoundedRect(
                        in: unit.rect(x: 0.27, y: y, width: width, height: 0.035),
                        cornerSize: CGSize(width: unit.length(0.0175), height: unit.length(0.0175))
                    )
                }
                return path
            }
            .fill(accent.opacity(0.28))
            // The lens, its rim and handle.
            UnitShape { Path(ellipseIn: $0.circle(center: 0.58, 0.56, radius: 0.19)) }
                .fill(surface.opacity(0.55))
            UnitShape { Path(ellipseIn: $0.circle(center: 0.58, 0.56, radius: 0.19)) }
                .fill(accent.opacity(0.14))
            UnitShape { Path(ellipseIn: $0.circle(center: 0.58, 0.56, radius: 0.19)) }
                .stroke(fill, lineWidth: side * 0.055)
            UnitShape { unit in
                var path = Path()
                path.move(to: unit.point(0.725, 0.705))
                path.addLine(to: unit.point(0.83, 0.81))
                return path
            }
            .stroke(accent, style: StrokeStyle(lineWidth: side * 0.08, lineCap: .round))
            // A glint on the glass.
            UnitShape { unit in
                var path = Path()
                path.addScreenArc(center: unit.point(0.58, 0.56), radius: unit.length(0.12), from: 195, to: 245)
                return path
            }
            .stroke(Color.white.opacity(isDark ? 0.5 : 0.9), style: StrokeStyle(lineWidth: side * 0.025, lineCap: .round))
        }
    }

    // MARK: Empty inbox

    private func tray(_ side: CGFloat) -> some View {
        ZStack {
            // The outline of a letter that isn't there.
            let dashes = StrokeStyle(lineWidth: side * 0.016, lineCap: .round, lineJoin: .round, dash: [side * 0.035, side * 0.03])
            UnitShape { unit in
                Path(roundedRect: unit.rect(x: 0.32, y: 0.15, width: 0.36, height: 0.25), cornerRadius: unit.length(0.035))
            }
            .stroke(accent.opacity(0.55), style: dashes)
            UnitShape { unit in
                var path = Path()
                path.move(to: unit.point(0.34, 0.18))
                path.addLine(to: unit.point(0.5, 0.29))
                path.addLine(to: unit.point(0.66, 0.18))
                return path
            }
            .stroke(accent.opacity(0.55), style: dashes)
            // The back of the tray, then its front with the notch.
            UnitShape { unit in
                Path(roundedRect: unit.rect(x: 0.19, y: 0.45, width: 0.62, height: 0.16), cornerRadius: unit.length(0.05))
            }
            .fill(accent.opacity(isDark ? 0.45 : 0.32))
            UnitShape { unit in
                Path.roundedPolygon(
                    [
                        unit.point(0.14, 0.53), unit.point(0.37, 0.53), unit.point(0.42, 0.64),
                        unit.point(0.58, 0.64), unit.point(0.63, 0.53), unit.point(0.86, 0.53),
                        unit.point(0.86, 0.83), unit.point(0.14, 0.83),
                    ],
                    radius: unit.length(0.045)
                )
            }
            .fill(fill)
        }
    }

    // MARK: Offline

    private func cloudOffline(_ side: CGFloat) -> some View {
        let slash = UnitShape { unit in
            var path = Path()
            path.move(to: unit.point(0.25, 0.22))
            path.addLine(to: unit.point(0.79, 0.8))
            return path
        }
        return ZStack {
            ZStack {
                Rectangle()
                    .fill(fill)
                    .mask {
                        ZStack {
                            UnitShape { Path(ellipseIn: $0.circle(center: 0.35, 0.53, radius: 0.15)) }
                            UnitShape { Path(ellipseIn: $0.circle(center: 0.55, 0.43, radius: 0.2)) }
                            UnitShape { Path(ellipseIn: $0.circle(center: 0.72, 0.56, radius: 0.13)) }
                            UnitShape { unit in
                                Path(roundedRect: unit.rect(x: 0.2, y: 0.52, width: 0.65, height: 0.17), cornerRadius: unit.length(0.085))
                            }
                        }
                    }
                // Cuts a gap around the slash.
                slash
                    .stroke(Color.black, style: StrokeStyle(lineWidth: side * 0.13, lineCap: .round))
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            slash
                .stroke(accent, style: StrokeStyle(lineWidth: side * 0.055, lineCap: .round))
        }
    }

    // MARK: Error

    private func warning(_ side: CGFloat) -> some View {
        ZStack {
            UnitShape { Path(ellipseIn: $0.rect(x: 0.24, y: 0.84, width: 0.52, height: 0.05)) }
                .fill(accent.opacity(0.22))
            UnitShape { unit in
                Path.roundedPolygon(
                    [unit.point(0.5, 0.17), unit.point(0.86, 0.8), unit.point(0.14, 0.8)],
                    radius: unit.length(0.075)
                )
            }
            .fill(fill)
            UnitShape { unit in
                var path = Path(roundedRect: unit.rect(x: 0.465, y: 0.37, width: 0.07, height: 0.23), cornerRadius: unit.length(0.035))
                path.addEllipse(in: unit.circle(center: 0.5, 0.69, radius: 0.042))
                return path
            }
            .fill(mark)
        }
    }

    // MARK: No permission

    private func lock(_ side: CGFloat) -> some View {
        ZStack {
            UnitShape { unit in
                var path = Path()
                path.move(to: unit.point(0.36, 0.5))
                path.addLine(to: unit.point(0.36, 0.37))
                path.addScreenArc(center: unit.point(0.5, 0.37), radius: unit.length(0.14), from: 180, to: 360)
                path.addLine(to: unit.point(0.64, 0.5))
                return path
            }
            .stroke(accent.opacity(isDark ? 0.75 : 0.6), style: StrokeStyle(lineWidth: side * 0.075, lineCap: .round))
            UnitShape { unit in
                Path(roundedRect: unit.rect(x: 0.24, y: 0.45, width: 0.52, height: 0.39), cornerRadius: unit.length(0.09))
            }
            .fill(fill)
            UnitShape { unit in
                var path = Path(ellipseIn: unit.circle(center: 0.5, 0.6, radius: 0.055))
                path.addRoundedRect(
                    in: unit.rect(x: 0.475, y: 0.6, width: 0.05, height: 0.13),
                    cornerSize: CGSize(width: unit.length(0.025), height: unit.length(0.025))
                )
                return path
            }
            .fill(mark)
        }
    }

    // MARK: First run

    private func sparkles(_ side: CGFloat) -> some View {
        ZStack {
            UnitShape { Path.sparkle(center: $0.point(0.47, 0.54), radius: $0.length(0.3)) }
                .fill(fill)
            UnitShape { Path.sparkle(center: $0.point(0.75, 0.25), radius: $0.length(0.11)) }
                .fill(accent.opacity(0.75))
            UnitShape { Path.sparkle(center: $0.point(0.24, 0.25), radius: $0.length(0.065)) }
                .fill(accent.opacity(0.5))
            UnitShape { Path(ellipseIn: $0.circle(center: 0.78, 0.76, radius: 0.028)) }
                .fill(accent.opacity(0.5))
        }
    }
}

/// The soft disc behind every illustration, with a few dots around it.
private struct Backdrop: View {
    let accent: Color
    let isDark: Bool

    var body: some View {
        ZStack {
            UnitShape { Path(ellipseIn: $0.circle(center: 0.5, 0.5, radius: 0.46)) }
                .fill(accent.opacity(isDark ? 0.2 : 0.11))
            UnitShape { unit in
                var path = Path()
                path.addEllipse(in: unit.circle(center: 0.09, 0.36, radius: 0.022))
                path.addEllipse(in: unit.circle(center: 0.93, 0.6, radius: 0.018))
                path.addEllipse(in: unit.circle(center: 0.86, 0.15, radius: 0.013))
                path.addEllipse(in: unit.circle(center: 0.16, 0.86, radius: 0.015))
                return path
            }
            .fill(accent.opacity(0.4))
        }
    }
}
