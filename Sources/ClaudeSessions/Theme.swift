import SwiftUI

enum Theme {
    static let panelBg = Color(hex: "#1E1E1E").opacity(0.95)
    static let panelStroke = Color.white.opacity(0.1)

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#EBEBF5").opacity(0.73)
    static let textTertiary = Color(hex: "#EBEBF5").opacity(0.5)

    static let claudeOrange = Color(hex: "#FFB299")
    static let claudeOrangeBg = Color(hex: "#CC785C").opacity(0.2)
    static let claudeOrangeStroke = Color(hex: "#CC785C")

    static let green = Color(hex: "#30D158")
    static let greenBg = Color(hex: "#30D158").opacity(0.2)

    static let blue = Color(hex: "#64D2FF")
    static let blueBg = Color(hex: "#64D2FF").opacity(0.15)
    static let blueText = Color(hex: "#9FE2FF")

    static let purple = Color(hex: "#BF5AF2")
    static let idleGray = Color(hex: "#48484A")

    static let dividerStrong = Color.white.opacity(0.07)
    static let dividerSoft = Color.white.opacity(0.04)

    static let panelWidth: CGFloat = 360
    static let cornerRadius: CGFloat = 12
}

extension Color {
    init(hex: String) {
        let raw = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch raw.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
