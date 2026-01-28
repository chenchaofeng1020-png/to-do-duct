import SwiftUI

struct ConfettiView: View {
    @Binding var counter: Int
    var burstPosition: CGPoint // 爆发中心点
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ConfettiParticleView(particle: particle)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: counter) { _, _ in
            fire()
        }
    }
    
    private func fire() {
        // 每次触发生成一批新的粒子
        for _ in 0..<50 {
            let particle = ConfettiParticle(startPoint: burstPosition)
            particles.append(particle)
        }
        
        // 清理旧粒子
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if !particles.isEmpty {
                particles.removeFirst(min(50, particles.count))
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let startX: Double
    let startY: Double
    let endX: Double
    let endY: Double
    let rotation: Double
    let scale: Double
    
    init(startPoint: CGPoint) {
        // 随机颜色
        let colors: [Color] = [
            .red, .blue, .green, .yellow, .pink, .purple, .orange,
            DesignSystem.neonLime, DesignSystem.checkedColor
        ]
        self.color = colors.randomElement() ?? .yellow
        
        // 起始位置（使用绝对坐标）
        self.startX = startPoint.x
        self.startY = startPoint.y
        
        // 随机发散方向（模拟爆炸）
        let angle = Double.random(in: 0...2 * .pi)
        let distance = Double.random(in: 100...300) // 爆发半径
        
        self.endX = startPoint.x + cos(angle) * distance
        self.endY = startPoint.y + sin(angle) * distance + 150 // 加上重力下落偏移
        
        // 随机旋转和大小
        self.rotation = Double.random(in: 0...360)
        self.scale = Double.random(in: 0.5...1.0)
    }
}

struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: 8, height: 8)
            .scaleEffect(particle.scale)
            .rotationEffect(.degrees(isAnimating ? particle.rotation + 360 : particle.rotation))
            .position(
                x: isAnimating ? particle.endX : particle.startX,
                y: isAnimating ? particle.endY : particle.startY
            )
            .opacity(isAnimating ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: Double.random(in: 0.8...1.5))) {
                    isAnimating = true
                }
            }
    }
}
