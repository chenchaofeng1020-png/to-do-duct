import SwiftUI

struct ProgressRing: View {
    let progress: Int
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    init(progress: Int, color: Color, size: CGFloat = 20, lineWidth: CGFloat = 2) {
        self.progress = progress
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }

    private var clampedProgress: CGFloat {
        CGFloat(min(max(progress, 0), 100)) / 100.0
    }

    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(progress == 0 ? color : color.opacity(0.35), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // 进度圆环
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: progress)

            // 中心内容
            if progress == 100 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.47, weight: .black))
                    .foregroundColor(color)
                    .transition(.scale.combined(with: .opacity))
            } else if progress > 0 {
                Text("\(progress)")
                    .font(.system(size: size * 0.34, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
                    .minimumScaleFactor(0.6)
                    .frame(width: size * 0.72)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 进度选择器（用于 ActionSheet）
struct ProgressPicker: View {
    @Binding var progress: Int
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 18) {
                Text("进度")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignSystem.textPrimary)

                GeometryReader { geo in
                    let trackWidth = geo.size.width
                    let fillWidth = max(0, min(CGFloat(progress) / 100.0 * trackWidth, trackWidth))
                    let thumbX = max(0, min(fillWidth, trackWidth))

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignSystem.surfaceContainerHighest)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.8))
                            .frame(width: fillWidth, height: 8)

                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                            .offset(x: thumbX - 10)
                    }
                    .frame(height: 20)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let raw = Int((value.location.x / trackWidth) * 100)
                                let newValue = min(max(raw, 0), 100)
                                if newValue != progress {
                                    progress = newValue
                                }
                            }
                    )
                }

                Text("\(progress)%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .frame(width: 44, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignSystem.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
