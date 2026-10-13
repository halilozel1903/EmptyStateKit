import SwiftUI

/// The largest square centred in a rectangle, addressed with unit coordinates: (0, 0) is its top-left corner and
/// (1, 1) its bottom-right. Every illustration is drawn in this space, so it scales to any size.
struct UnitSquare {
    let origin: CGPoint
    let side: CGFloat

    init(_ rect: CGRect) {
        side = min(rect.width, rect.height)
        origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
    }

    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * side, y: origin.y + y * side)
    }

    func rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        CGRect(x: origin.x + x * side, y: origin.y + y * side, width: width * side, height: height * side)
    }

    func circle(center x: CGFloat, _ y: CGFloat, radius: CGFloat) -> CGRect {
        rect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
    }

    func length(_ value: CGFloat) -> CGFloat {
        value * side
    }
}

/// A shape drawn in a ``UnitSquare``.
struct UnitShape: Shape {
    let build: @Sendable (UnitSquare) -> Path

    init(_ build: @escaping @Sendable (UnitSquare) -> Path) {
        self.build = build
    }

    func path(in rect: CGRect) -> Path {
        build(UnitSquare(rect))
    }
}

extension Path {
    /// A closed polygon whose corners are rounded with `radius`, convex and concave alike.
    static func roundedPolygon(_ points: [CGPoint], radius: CGFloat) -> Path {
        var path = Path()
        guard points.count > 2 else { return path }
        let last = points[points.count - 1]
        let first = points[0]
        path.move(to: CGPoint(x: (last.x + first.x) / 2, y: (last.y + first.y) / 2))
        for index in points.indices {
            let corner = points[index]
            let next = points[(index + 1) % points.count]
            path.addArc(tangent1End: corner, tangent2End: next, radius: radius)
        }
        path.closeSubpath()
        return path
    }

    /// Adds an arc as a polyline, with angles in degrees measured clockwise on screen from the positive x axis
    /// (0 is right, 90 is down, 270 is up). Drawn point by point, so the direction never depends on the
    /// coordinate system's orientation.
    mutating func addScreenArc(center: CGPoint, radius: CGFloat, from start: Double, to end: Double, connect: Bool = true) {
        let steps = max(8, Int(abs(end - start) / 4))
        for step in 0...steps {
            let angle = (start + (end - start) * Double(step) / Double(steps)) * .pi / 180
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if step == 0, !connect || isEmpty {
                move(to: point)
            } else {
                addLine(to: point)
            }
        }
    }

    /// A four-pointed sparkle centred on `center`, `radius` from the centre to each point.
    static func sparkle(center: CGPoint, radius: CGFloat, pinch: CGFloat = 0.14) -> Path {
        let inner = radius * pinch
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addQuadCurve(to: CGPoint(x: center.x + radius, y: center.y), control: CGPoint(x: center.x + inner, y: center.y - inner))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + radius), control: CGPoint(x: center.x + inner, y: center.y + inner))
        path.addQuadCurve(to: CGPoint(x: center.x - radius, y: center.y), control: CGPoint(x: center.x - inner, y: center.y + inner))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - radius), control: CGPoint(x: center.x - inner, y: center.y - inner))
        path.closeSubpath()
        return path
    }
}
