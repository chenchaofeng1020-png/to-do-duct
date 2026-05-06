import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum DesignSystem {
    static let macAccent = Color(hex: "0c6d45")
    static let neonLime = Color(red: 0.94, green: 1.0, blue: 0.35) // 近似 #F3FF57
    static let purple = Color(red: 0.49, green: 0.42, blue: 0.95)   // 近似 #7C6BF2
    
    // MARK: - 新设计系统颜色 (Material Design 3 风格)
    // Primary
    static let primary = Color(hex: "036d42")
    static let primaryDim = Color(hex: "006039")
    static let onPrimary = Color(hex: "e7ffec")
    static let primaryContainer = Color(hex: "94edb6")
    static let onPrimaryContainer = Color(hex: "005934")
    static let primaryFixed = Color(hex: "94edb6")
    static let primaryFixedDim = Color(hex: "86dea9")
    static let onPrimaryFixed = Color(hex: "004327")
    static let onPrimaryFixedVariant = Color(hex: "00633b")
    
    // Secondary
    static let secondary = Color(hex: "34694f")
    static let secondaryDim = Color(hex: "275d43")
    static let onSecondary = Color(hex: "e6ffee")
    static let secondaryContainer = Color(hex: "b6efcd")
    static let onSecondaryContainer = Color(hex: "265b42")
    static let secondaryFixed = Color(hex: "b6efcd")
    static let secondaryFixedDim = Color(hex: "a8e1c0")
    static let onSecondaryFixed = Color(hex: "0f4830")
    static let onSecondaryFixedVariant = Color(hex: "30664b")
    
    // Tertiary
    static let tertiary = Color(hex: "596432")
    static let tertiaryDim = Color(hex: "4d5827")
    static let onTertiary = Color(hex: "f3ffc2")
    static let tertiaryContainer = Color(hex: "ebf7b7")
    static let onTertiaryContainer = Color(hex: "545f2d")
    static let tertiaryFixed = Color(hex: "ebf7b7")
    static let tertiaryFixedDim = Color(hex: "dde9aa")
    static let onTertiaryFixed = Color(hex: "424c1d")
    static let onTertiaryFixedVariant = Color(hex: "5f6937")
    
    // Surface - 支持深色模式
    #if os(macOS)
    static var surface: Color { makeDynamicColor(light: "f8faf8", dark: "1a1c1a") }
    static var surfaceDim: Color { makeDynamicColor(light: "d4dcd9", dark: "0f0f0f") }
    static var surfaceBright: Color { makeDynamicColor(light: "f8faf8", dark: "2d3432") }
    static var surfaceContainerLowest: Color { makeDynamicColor(light: "ffffff", dark: "0b0f0e") }
    static var surfaceContainerLow: Color { makeDynamicColor(light: "f1f4f2", dark: "1a1c1a") }
    static var surfaceContainer: Color { makeDynamicColor(light: "eaefec", dark: "1f2422") }
    static var surfaceContainerHigh: Color { makeDynamicColor(light: "e4e9e7", dark: "252b29") }
    static var surfaceContainerHighest: Color { makeDynamicColor(light: "dde4e1", dark: "2d3432") }
    static var surfaceVariant: Color { makeDynamicColor(light: "dde4e1", dark: "3d4542") }
    static var onSurface: Color { makeDynamicColor(light: "2d3432", dark: "e0e3e1") }
    static var onSurfaceVariant: Color { makeDynamicColor(light: "59615f", dark: "bfc9c4") }
    
    // Background - 支持深色模式
    static var background: Color { makeDynamicColor(light: "f8faf8", dark: "0b0f0e") }
    static var onBackground: Color { makeDynamicColor(light: "2d3432", dark: "e0e3e1") }
    
    private static func makeDynamicColor(light: String, dark: String) -> Color {
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            if appearance.name == .darkAqua {
                return NSColor(hex: dark)
            } else {
                return NSColor(hex: light)
            }
        }))
    }
    #else
    static var surface: Color { makeDynamicColor(light: "f8faf8", dark: "1a1c1a") }
    static var surfaceDim: Color { makeDynamicColor(light: "d4dcd9", dark: "0f0f0f") }
    static var surfaceBright: Color { makeDynamicColor(light: "f8faf8", dark: "2d3432") }
    static var surfaceContainerLowest: Color { makeDynamicColor(light: "ffffff", dark: "0b0f0e") }
    static var surfaceContainerLow: Color { makeDynamicColor(light: "f1f4f2", dark: "1a1c1a") }
    static var surfaceContainer: Color { makeDynamicColor(light: "eaefec", dark: "1f2422") }
    static var surfaceContainerHigh: Color { makeDynamicColor(light: "e4e9e7", dark: "252b29") }
    static var surfaceContainerHighest: Color { makeDynamicColor(light: "dde4e1", dark: "2d3432") }
    static var surfaceVariant: Color { makeDynamicColor(light: "dde4e1", dark: "3d4542") }
    static var onSurface: Color { makeDynamicColor(light: "2d3432", dark: "e0e3e1") }
    static var onSurfaceVariant: Color { makeDynamicColor(light: "59615f", dark: "bfc9c4") }
    
    // Background - 支持深色模式
    static var background: Color { makeDynamicColor(light: "f8faf8", dark: "0b0f0e") }
    static var onBackground: Color { makeDynamicColor(light: "2d3432", dark: "e0e3e1") }
    
    private static func makeDynamicColor(light: String, dark: String) -> Color {
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(hex: dark)
            } else {
                return UIColor(hex: light)
            }
        })
    }
    #endif
    
    // Outline
    static let outline = Color(hex: "757c7a")
    static let outlineVariant = Color(hex: "acb4b1")
    
    // Error
    static let error = Color(hex: "a83836")
    static let errorDim = Color(hex: "67040d")
    static let onError = Color(hex: "fff7f6")
    static let errorContainer = Color(hex: "fa746f")
    static let onErrorContainer = Color(hex: "6e0a12")
    
    // Inverse
    static let inverseSurface = Color(hex: "0b0f0e")
    static let inverseOnSurface = Color(hex: "9b9d9c")
    static let inversePrimary = Color(hex: "94edb6")
    
    // Surface Tint
    static let surfaceTint = Color(hex: "036d42")
    
    #if os(macOS)
    static let softBackground = Color(nsColor: .windowBackgroundColor)
    
    static var warmBackground: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            if appearance.name == .darkAqua {
                return NSColor.black
            } else {
                return NSColor(red: 242/255, green: 242/255, blue: 235/255, alpha: 1)
            }
        }))
    }
    
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static var sidebarSelectionBackground: Color { makeDynamicColor(light: "e8f5ee", dark: "173326") }
    static var sidebarSelectionForeground: Color { makeDynamicColor(light: "0c6d45", dark: "b6efcd") }
    
    static var cardHeaderBackground: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            if appearance.name == .darkAqua {
                return NSColor.white.withAlphaComponent(0.05)
            } else {
                return NSColor.black.withAlphaComponent(0.025)
            }
        }))
    }
    
    static var cardBorder: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            if appearance.name == .darkAqua {
                return NSColor.white.withAlphaComponent(0.1)
            } else {
                return NSColor.black.withAlphaComponent(0.04)
            }
        }))
    }
    
    static var separatorColor: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            if appearance.name == .darkAqua {
                return NSColor.white.withAlphaComponent(0.1)
            } else {
                return NSColor.black.withAlphaComponent(0.05)
            }
        }))
    }
    
    static var shadowColor: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            if appearance.name == .darkAqua {
                return NSColor.black.withAlphaComponent(0.3)
            } else {
                return NSColor.black.withAlphaComponent(0.05)
            }
        }))
    }
    
    #else
    static let softBackground = Color(UIColor.systemGroupedBackground)
    
    static var warmBackground: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.black
            } else {
                return UIColor(red: 242/255, green: 242/255, blue: 235/255, alpha: 1)
            }
        })
    }
    
    static let textTertiary = Color(UIColor.tertiaryLabel)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static var sidebarSelectionBackground: Color { makeDynamicColor(light: "e8f5ee", dark: "173326") }
    static var sidebarSelectionForeground: Color { makeDynamicColor(light: "0c6d45", dark: "b6efcd") }
    
    static var cardHeaderBackground: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.white.withAlphaComponent(0.05)
            } else {
                return UIColor.black.withAlphaComponent(0.025)
            }
        })
    }
    
    static var cardBorder: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.white.withAlphaComponent(0.1)
            } else {
                return UIColor.black.withAlphaComponent(0.04)
            }
        })
    }
    
    static var separatorColor: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.white.withAlphaComponent(0.1)
            } else {
                return UIColor.black.withAlphaComponent(0.05)
            }
        })
    }
    
    static var shadowColor: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.black.withAlphaComponent(0.3)
            } else {
                return UIColor.black.withAlphaComponent(0.05)
            }
        })
    }
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
    static func medium() {
        #if os(iOS)
        let gen = UIImpactFeedbackGenerator(style: .medium)
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

// MARK: - NSColor/UIColor Hex Extension
#if os(macOS)
extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        
        switch hex.count {
        case 3:
            a = 255
            r = (int >> 8) * 17
            g = (int >> 4 & 0xF) * 17
            b = (int & 0xF) * 17
        case 6:
            a = 255
            r = int >> 16
            g = int >> 8 & 0xFF
            b = int & 0xFF
        case 8:
            a = int >> 24
            r = int >> 16 & 0xFF
            g = int >> 8 & 0xFF
            b = int & 0xFF
        default:
            a = 1
            r = 1
            g = 1
            b = 0
        }
        
        let red = Double(r) / 255
        let green = Double(g) / 255
        let blue = Double(b) / 255
        let alpha = Double(a) / 255
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#else
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        
        switch hex.count {
        case 3:
            a = 255
            r = (int >> 8) * 17
            g = (int >> 4 & 0xF) * 17
            b = (int & 0xF) * 17
        case 6:
            a = 255
            r = int >> 16
            g = int >> 8 & 0xFF
            b = int & 0xFF
        case 8:
            a = int >> 24
            r = int >> 16 & 0xFF
            g = int >> 8 & 0xFF
            b = int & 0xFF
        default:
            a = 1
            r = 1
            g = 1
            b = 0
        }
        
        let red = Double(r) / 255
        let green = Double(g) / 255
        let blue = Double(b) / 255
        let alpha = Double(a) / 255
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif
