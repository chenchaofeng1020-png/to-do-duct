import SwiftUI

struct IconPreviewView: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("App Icon Preview")
                    .font(.title)
                    .bold()
                
                // iOS 风格预览 (Squircle 由系统裁切)
                VStack {
                    Text("iOS Home Screen (Simulation)")
                        .font(.headline)
                    
                    DuckIcon(size: 180)
                        .padding(40) // 内边距作为背景区域
                        .background(
                            LinearGradient(colors: [Color(hex: "F9F9F9"), Color(hex: "F0F0F0")],
                                         startPoint: .top,
                                         endPoint: .bottom)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous)) // iOS 风格圆角
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                
                // macOS 风格预览 (圆角矩形 + 阴影)
                VStack {
                    Text("macOS Dock (Simulation)")
                        .font(.headline)
                    
                    DuckIcon(size: 160)
                        .padding(35)
                        .background(
                            LinearGradient(colors: [Color(hex: "F9F9F9"), Color(hex: "EFEFEF")],
                                         startPoint: .top,
                                         endPoint: .bottom)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 45, style: .continuous)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 45, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                
                Text("Take a screenshot to use as icon")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    IconPreviewView()
}
