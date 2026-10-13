import CoreGraphics
import SwiftUI
import Testing
@testable import EmptyStateKit

@Suite("Illustration geometry")
struct GeometryTests {
    @Test("the unit square is the largest centred square")
    func unitSquare() {
        let wide = UnitSquare(CGRect(x: 0, y: 0, width: 200, height: 100))
        #expect(wide.side == 100)
        #expect(wide.origin == CGPoint(x: 50, y: 0))
        #expect(wide.point(1, 1) == CGPoint(x: 150, y: 100))
        #expect(wide.length(0.25) == 25)

        let tall = UnitSquare(CGRect(x: 10, y: 10, width: 80, height: 120))
        #expect(tall.side == 80)
        #expect(tall.point(0, 0) == CGPoint(x: 10, y: 30))
        #expect(tall.circle(center: 0.5, 0.5, radius: 0.25) == CGRect(x: 30, y: 50, width: 40, height: 40))
    }

    @Test("a rounded polygon stays inside its corners")
    func roundedPolygon() {
        let points = [CGPoint(x: 50, y: 0), CGPoint(x: 100, y: 100), CGPoint(x: 0, y: 100)]
        let bounds = Path.roundedPolygon(points, radius: 10).boundingRect
        #expect(bounds.minX >= 0)
        #expect(bounds.maxX <= 100)
        #expect(bounds.minY >= 0)
        #expect(bounds.maxY <= 100)
        #expect(bounds.width > 80)
        #expect(Path.roundedPolygon(Array(points.prefix(2)), radius: 10).isEmpty)
    }

    @Test("a sparkle reaches its radius in each direction")
    func sparkle() {
        let bounds = Path.sparkle(center: CGPoint(x: 50, y: 50), radius: 40).boundingRect
        #expect(abs(bounds.minX - 10) < 0.001)
        #expect(abs(bounds.maxX - 90) < 0.001)
        #expect(abs(bounds.minY - 10) < 0.001)
        #expect(abs(bounds.maxY - 90) < 0.001)
    }

    @Test("screen arcs run clockwise on screen from the start angle")
    func screenArc() {
        var path = Path()
        path.addScreenArc(center: .zero, radius: 10, from: 180, to: 360)
        let bounds = path.boundingRect
        // From the left point over the top (negative y on screen) to the right point.
        #expect(abs(bounds.minX + 10) < 0.001)
        #expect(abs(bounds.maxX - 10) < 0.001)
        // The polyline's points straddle the top, so the top is within a fraction of the radius.
        #expect(abs(bounds.minY + 10) < 0.1)
        #expect(bounds.maxY < 0.001)
    }
}
