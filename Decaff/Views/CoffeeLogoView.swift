import SwiftUI

struct CoffeeLogoView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Steam
            Path { path in
                path.move(to: CGPoint(x: 50, y: 0))
                path.addCurve(
                    to: CGPoint(x: 50, y: 30),
                    control1: CGPoint(x: 65, y: 10),
                    control2: CGPoint(x: 35, y: 20)
                )
            }
            .stroke(Color(hex: "4A3728"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 100, height: 30)
            
            // Cup
            Path { path in
                // Cup body
                path.move(to: CGPoint(x: 20, y: 30))
                path.addLine(to: CGPoint(x: 80, y: 30))
                path.addLine(to: CGPoint(x: 70, y: 80))
                path.addLine(to: CGPoint(x: 30, y: 80))
                path.closeSubpath()
                
                // Handle
                path.move(to: CGPoint(x: 80, y: 40))
                path.addCurve(
                    to: CGPoint(x: 80, y: 60),
                    control1: CGPoint(x: 95, y: 40),
                    control2: CGPoint(x: 95, y: 60)
                )
            }
            .fill(Color(hex: "1A1A1A"))
            
            // Saucer
            Path { path in
                path.move(to: CGPoint(x: 15, y: 80))
                path.addLine(to: CGPoint(x: 85, y: 80))
                path.addLine(to: CGPoint(x: 90, y: 90))
                path.addLine(to: CGPoint(x: 10, y: 90))
                path.closeSubpath()
            }
            .fill(Color(hex: "1A1A1A"))
        }
        .frame(width: 100, height: 100)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
