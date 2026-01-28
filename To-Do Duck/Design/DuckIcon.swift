import SwiftUI

struct DuckIcon: View {
    var size: CGFloat = 40
    
    var body: some View {
        // SVG viewBox: 0 0 60 50
        // Scale content to fit within `size` (based on width 60)
        let scale = size / 60.0
        
        ZStack {
            // 1. 简化的鸭子轮廓
            // Path: M8 20 C8 12, 16 5, 30 5 C36 5, 42 8, 42 14 C48 10, 56 14, 56 20 C56 24, 52 28, 46 28 L42 28 C42 34, 36 38, 30 38 C16 38, 8 32, 8 20 Z
            Path { path in
                path.move(to: CGPoint(x: 8 * scale, y: 20 * scale))
                path.addCurve(to: CGPoint(x: 30 * scale, y: 5 * scale),
                              control1: CGPoint(x: 8 * scale, y: 12 * scale),
                              control2: CGPoint(x: 16 * scale, y: 5 * scale))
                path.addCurve(to: CGPoint(x: 42 * scale, y: 14 * scale),
                              control1: CGPoint(x: 36 * scale, y: 5 * scale),
                              control2: CGPoint(x: 42 * scale, y: 8 * scale))
                path.addCurve(to: CGPoint(x: 56 * scale, y: 20 * scale),
                              control1: CGPoint(x: 48 * scale, y: 10 * scale),
                              control2: CGPoint(x: 56 * scale, y: 14 * scale))
                path.addCurve(to: CGPoint(x: 46 * scale, y: 28 * scale),
                              control1: CGPoint(x: 56 * scale, y: 24 * scale),
                              control2: CGPoint(x: 52 * scale, y: 28 * scale))
                path.addLine(to: CGPoint(x: 42 * scale, y: 28 * scale))
                path.addCurve(to: CGPoint(x: 30 * scale, y: 38 * scale),
                              control1: CGPoint(x: 42 * scale, y: 34 * scale),
                              control2: CGPoint(x: 36 * scale, y: 38 * scale))
                path.addCurve(to: CGPoint(x: 8 * scale, y: 20 * scale),
                              control1: CGPoint(x: 16 * scale, y: 38 * scale),
                              control2: CGPoint(x: 8 * scale, y: 32 * scale))
                path.closeSubpath()
            }
            .fill(Color(hex: "fbbf24"))
            
            // 2. 鸭子眼睛
            // circle cx="34" cy="16" r="2.5" fill="white"
            Circle()
                .fill(Color.white)
                .frame(width: 5 * scale, height: 5 * scale)
                .position(x: 34 * scale, y: 16 * scale)
            
            // circle cx="34" cy="16" r="1.5" fill="#333"
            Circle()
                .fill(Color(hex: "333333"))
                .frame(width: 3 * scale, height: 3 * scale)
                .position(x: 34 * scale, y: 16 * scale)
            
            // 3. 简化的待办标记背景
            // circle cx="20" cy="42" r="4" fill="#7f52f5" opacity="0.3"
            Circle()
                .fill(Color(hex: "7f52f5").opacity(0.3))
                .frame(width: 8 * scale, height: 8 * scale)
                .position(x: 20 * scale, y: 42 * scale)
            
            // 4. 待办标记对勾
            // path d="M16.5 42 L19 44.5 L23.5 40"
            Path { path in
                path.move(to: CGPoint(x: 16.5 * scale, y: 42 * scale))
                path.addLine(to: CGPoint(x: 19 * scale, y: 44.5 * scale))
                path.addLine(to: CGPoint(x: 23.5 * scale, y: 40 * scale))
            }
            .stroke(Color(hex: "7f52f5"), style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size * (50.0 / 60.0))
    }
}
