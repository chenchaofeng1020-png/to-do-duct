import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit

// MARK: - Share Sheet View
struct MemoShareSheet: View {
    let memo: MemoCardV3
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStyle: ShareStyle = .minimal
    @State private var generatedImage: UIImage?
    @State private var isSharing = false
    @State private var isProcessing = false // Loading state for actions
    @State private var imageSaver = ImageSaver() // Helper for saving images
    
    // Standard size for rendering and preview base
    private let cardWidth: CGFloat = 375
    private let cardHeight: CGFloat = 550 // Slightly taller for better content fit
    
    enum ShareStyle: String, CaseIterable, Identifiable {
        case minimal, paper, dark
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .minimal: return NSLocalizedString("style_minimal", comment: "")
            case .paper: return NSLocalizedString("style_paper", comment: "")
            case .dark: return NSLocalizedString("style_dark", comment: "")
            }
        }
        
        var icon: String {
            switch self {
            case .minimal: return "square"
            case .paper: return "doc.text"
            case .dark: return "moon.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Preview Area (Swipeable)
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width - 40 // Reduced padding
                    let availableHeight = geometry.size.height - 24 // Slightly increased padding to prevent clipping
                    
                    let widthScale = availableWidth / cardWidth
                    let heightScale = availableHeight / cardHeight
                    let scale = min(widthScale, heightScale, 1.0)
                    
                    TabView(selection: $selectedStyle) {
                        ForEach(ShareStyle.allCases) { style in
                            ZStack {
                                Color.clear // Hit area
                                
                                templateView(for: style)
                                    .frame(width: cardWidth, height: cardHeight)
                                    .clipShape(RoundedRectangle(cornerRadius: 16)) // Ensure clipping
                                    .shadow(color: DesignSystem.shadowColor, radius: 8, x: 0, y: 4) // Add shadow
                                    .scaleEffect(scale)
                                    .frame(width: cardWidth * scale, height: cardHeight * scale)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(style)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .frame(maxHeight: .infinity) // Take available vertical space
                
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(ShareStyle.allCases) { style in
                        Circle()
                            .fill(selectedStyle == style ? DesignSystem.checkedColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(selectedStyle == style ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: selectedStyle)
                    }
                }
                .padding(.vertical, 8)
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button {
                        performAction(save: true)
                    } label: {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .tint(DesignSystem.checkedColor)
                            } else {
                                Label("save_image", systemImage: "square.and.arrow.down")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DesignSystem.checkedColor.opacity(0.1))
                        .foregroundColor(DesignSystem.checkedColor)
                        .cornerRadius(16)
                    }
                    .disabled(isProcessing)
                    
                    Button {
                        performAction(save: false)
                    } label: {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Label("share_via", systemImage: "square.and.arrow.up")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DesignSystem.checkedColor)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("share_memo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.fraction(0.8)]) // Slightly smaller than full screen
        .presentationDragIndicator(.visible)
    }
    
    @MainActor
    private func renderImage() -> UIImage {
        let renderer = ImageRenderer(content: 
            templateView(for: selectedStyle)
                .frame(width: cardWidth, height: cardHeight)
        )
        renderer.scale = 3.0 // High resolution for sharing
        return renderer.uiImage ?? UIImage()
    }
    
    private func performAction(save: Bool) {
        isProcessing = true
        
        // Use Task to allow UI to update (show spinner) before heavy rendering
        Task {
            // Slight delay to ensure run loop cycles and spinner appears
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            
            let image = renderImage()
            
            if save {
                do {
                    try await imageSaver.saveImage(image)
                    Haptics.success()
                    isProcessing = false
                } catch {
                    print("Save error: \(error.localizedDescription)")
                    isProcessing = false
                }
            } else {
                showShareSheet(image: image)
                isProcessing = false
            }
        }
    }
    
    private func showShareSheet(image: UIImage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        // Find the top-most view controller to present from
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        topVC.present(activityVC, animated: true)
    }
    
    @ViewBuilder
    private func templateView(for style: ShareStyle) -> some View {
        Group {
            switch style {
            case .minimal:
                MemoShareTemplateMinimal(memo: memo)
            case .paper:
                MemoShareTemplatePaper(memo: memo)
            case .dark:
                MemoShareTemplateDark(memo: memo)
            }
        }
        .background(Color.white) // Default background base
        .drawingGroup() // Flatten for rendering performance
    }
}

// MARK: - Templates

struct MemoShareTemplateMinimal: View {
    let memo: MemoCardV3
    
    var body: some View {
        ZStack {
            Color.white
            
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 48))
                    .foregroundColor(Color.black.opacity(0.08))
                    .padding(.top, 10)
                
                Text(memo.content)
                    .font(.system(size: 26, weight: .medium, design: .serif))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(10)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 40)
                
                Divider()
                    .overlay(Color.black.opacity(0.1))
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("To-Do Duck")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        Text(formatDate(memo.createdAt))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    DuckIcon(size: 40) // Product logo
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MemoShareTemplatePaper: View {
    let memo: MemoCardV3
    
    var body: some View {
        ZStack {
            Color(red: 0.99, green: 0.97, blue: 0.94) // Warm paper
            
            // Lines pattern
            GeometryReader { geo in
                VStack(spacing: 0) {
                    ForEach(0..<Int(geo.size.height / 32) + 1, id: \.self) { _ in
                        Divider()
                            .background(Color.blue.opacity(0.1))
                            .frame(height: 32, alignment: .bottom)
                    }
                }
                .padding(.top, 80)
            }
            
            VStack(alignment: .leading) {
                Text(memo.content)
                    .font(.system(size: 24, weight: .regular, design: .rounded))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                    .lineSpacing(10.5) // Tuned to match lines roughly
                    .padding(.top, 78) // Align with first line
                    .padding(.horizontal, 36)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Text("— To-Do Duck")
                        .font(.custom("Zapfino", size: 14))
                        .foregroundColor(.gray)
                        .padding(32)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MemoShareTemplateDark: View {
    let memo: MemoCardV3
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Decorative elements
            GeometryReader { geo in
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .position(x: 0, y: 0)
                
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .position(x: geo.size.width, y: geo.size.height)
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                Text(memo.content)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .purple.opacity(0.5), radius: 15, x: 0, y: 0)
                    .padding(.horizontal, 30)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("To-Do Duck")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(2)
                    
                    Text(formatDate(memo.createdAt))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 50)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Helper for date formatting
private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

// MARK: - Image Saver Helper
class ImageSaver: NSObject {
    private var continuation: CheckedContinuation<Void, Error>?
    
    func saveImage(_ image: UIImage) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
        }
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume()
        }
        continuation = nil
    }
}
#else
import AppKit

struct MemoShareSheet: View {
    let memo: MemoCardV3
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Share Memo")
                .font(.title2)
                .bold()
            
            Text(memo.content)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            HStack {
                Button("Copy Content") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(memo.content, forType: .string)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
#endif
