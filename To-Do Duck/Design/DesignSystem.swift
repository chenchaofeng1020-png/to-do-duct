import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum DesignSystem {
    static let neonLime = Color(red: 0.94, green: 1.0, blue: 0.35) // 近似 #F3FF57
    static let purple = Color(red: 0.49, green: 0.42, blue: 0.95)   // 近似 #7C6BF2
    
    #if os(macOS)
    static let softBackground = Color(nsColor: .windowBackgroundColor)
    static let warmBackground = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        return appearance.name == .darkAqua ? NSColor.black : NSColor(red: 242/255, green: 242/255, blue: 235/255, alpha: 1)
    }))
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    
    static let cardHeaderBackground = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        return appearance.name == .darkAqua ? NSColor.white.withAlphaComponent(0.05) : NSColor.black.withAlphaComponent(0.025)
    }))
    
    static let cardBorder = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        return appearance.name == .darkAqua ? NSColor.white.withAlphaComponent(0.1) : NSColor.black.withAlphaComponent(0.04)
    }))
    
    static let separatorColor = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        return appearance.name == .darkAqua ? NSColor.white.withAlphaComponent(0.1) : NSColor.black.withAlphaComponent(0.05)
    }))
    
    static let shadowColor = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        return appearance.name == .darkAqua ? NSColor.black.withAlphaComponent(0.3) : NSColor.black.withAlphaComponent(0.05)
    }))
    
    #else
    static let softBackground = Color(UIColor.systemGroupedBackground)
    static let warmBackground = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor(red: 242/255, green: 242/255, blue: 235/255, alpha: 1)
    })
    static let textTertiary = Color(UIColor.tertiaryLabel)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    
    static let cardHeaderBackground = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.05) : UIColor.black.withAlphaComponent(0.025)
    })
    
    static let cardBorder = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.1) : UIColor.black.withAlphaComponent(0.04)
    })
    
    static let separatorColor = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.1) : UIColor.black.withAlphaComponent(0.05)
    })
    
    static let shadowColor = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor.black.withAlphaComponent(0.3) : UIColor.black.withAlphaComponent(0.05)
    })
    #endif
    
    static let creamBackground = Color(red: 242/255, green: 242/255, blue: 235/255) // Keep for reference if needed
    
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    static let checkedColor = Color(red: 0.35, green: 0.78, blue: 0.55) // 清新绿色
    
    static let cardCorner: CGFloat = 24
    static let pillCorner: CGFloat = 12
    static let shadowRadius: CGFloat = 12
}

enum Haptics {
    static func success() {
        #if os(iOS)
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        #endif
    }
    static func light() {
        #if os(iOS)
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        #endif
    }
}

// MARK: - Color Extension
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
