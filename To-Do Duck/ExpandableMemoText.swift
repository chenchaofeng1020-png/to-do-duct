import SwiftUI

struct ExpandableMemoText: View {
    let content: String
    let font: Font
    let lineSpacing: CGFloat
    let textColor: Color
    var maxLines: Int = 6
    var allowsSelection: Bool = false

    @State private var isExpanded = false
    @State private var availableWidth: CGFloat = 0
    @State private var fullTextHeight: CGFloat = 0
    @State private var collapsedTextHeight: CGFloat = 0

    private var shouldShowToggle: Bool {
        fullTextHeight > collapsedTextHeight + 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            visibleText
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: MemoTextWidthPreferenceKey.self, value: proxy.size.width)
                    }
                )
                .background(measurementLayer)

            if shouldShowToggle {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(LocalizedStringKey(isExpanded ? "collapse_memo_content" : "expand_memo_content"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignSystem.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .onPreferenceChange(MemoTextWidthPreferenceKey.self) { width in
            guard width > 0 else { return }
            availableWidth = width
        }
        .onChange(of: content) {
            isExpanded = false
        }
    }

    @ViewBuilder
    private var visibleText: some View {
        let text = Text(content)
            .font(font)
            .foregroundColor(textColor)
            .lineSpacing(lineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(isExpanded ? nil : maxLines)

        if allowsSelection {
            text.textSelection(.enabled)
        } else {
            text
        }
    }

    private var measurementLayer: some View {
        ZStack {
            measurementText(lineLimit: nil)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: MemoTextFullHeightPreferenceKey.self, value: proxy.size.height)
                    }
                )

            measurementText(lineLimit: maxLines)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: MemoTextCollapsedHeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
        }
        .frame(height: 0)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onPreferenceChange(MemoTextFullHeightPreferenceKey.self) { height in
            fullTextHeight = height
        }
        .onPreferenceChange(MemoTextCollapsedHeightPreferenceKey.self) { height in
            collapsedTextHeight = height
        }
    }

    private func measurementText(lineLimit: Int?) -> some View {
        Text(content)
            .font(font)
            .lineSpacing(lineSpacing)
            .lineLimit(lineLimit)
            .frame(width: availableWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .hidden()
    }
}

private struct MemoTextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct MemoTextFullHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct MemoTextCollapsedHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
