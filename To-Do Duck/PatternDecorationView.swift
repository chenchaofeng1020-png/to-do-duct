import SwiftUI

struct PatternDecorationView: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 抽象条纹装饰 - 现代感与动感
            HStack(spacing: 16) {
                // 条纹 1
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.neonLime.opacity(0.25))
                    .frame(width: 8, height: 160)
                    .offset(y: 20)
                
                // 条纹 2
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.checkedColor.opacity(0.15))
                    .frame(width: 8, height: 220)
                
                // 条纹 3
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.textSecondary.opacity(0.08))
                    .frame(width: 8, height: 180)
                    .offset(y: -30)
                
                // 条纹 4
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.purple.opacity(0.1))
                    .frame(width: 8, height: 140)
                    .offset(y: 10)
            }
            .rotationEffect(.degrees(30))
            .offset(x: 40, y: -60)
            
            // 底部叠加一点点圆点阵列增加层次
            HStack(spacing: 8) {
                ForEach(0..<4) { _ in
                    Circle()
                        .fill(DesignSystem.textSecondary.opacity(0.06))
                        .frame(width: 4, height: 4)
                }
            }
            .offset(x: -40, y: 30)
        }
        .allowsHitTesting(false) // 确保不阻挡交互
        .ignoresSafeArea()
    }
}
