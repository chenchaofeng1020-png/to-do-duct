import SwiftUI

#if os(macOS)
import AppKit

struct MacQuickCaptureView: View {
    @ObservedObject var viewModel: MacQuickCaptureViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            targetPicker
            editor
            footer
        }
        .padding(20)
        .frame(width: 520)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DesignSystem.surfaceContainerLowest.opacity(0.96))
                .shadow(color: DesignSystem.shadowColor.opacity(0.24), radius: 18, x: 0, y: 10)
        )
        .padding(14)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("快速收集")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(DesignSystem.textPrimary)

            Spacer()

            Button(action: viewModel.close) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DesignSystem.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(DesignSystem.surfaceContainerHigh)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var targetPicker: some View {
        Picker("类型", selection: Binding(
            get: { viewModel.selectedTarget },
            set: { viewModel.selectTarget($0) }
        )) {
            ForEach(QuickCaptureTarget.allCases) { target in
                Label(target.title, systemImage: target.icon)
                    .tag(target)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                if viewModel.draftText.isEmpty {
                    Text(placeholderText)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(DesignSystem.textTertiary)
                        .padding(.horizontal, MacQuickCaptureTextEditor.contentPadding.leading)
                        .padding(.vertical, MacQuickCaptureTextEditor.contentPadding.top)
                        .allowsHitTesting(false)
                }

                MacQuickCaptureTextEditor(
                    text: $viewModel.draftText,
                    focusToken: viewModel.focusToken
                )
                    .frame(minHeight: 180)
            }
            .padding(10)
            .background(DesignSystem.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(viewModel.isShowingError ? DesignSystem.error.opacity(0.65) : DesignSystem.cardBorder, lineWidth: 1)
            )

            HStack(spacing: 10) {
                Text(viewModel.feedbackMessage ?? helperText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(viewModel.isShowingError ? DesignSystem.error : DesignSystem.textSecondary)
                    .lineLimit(1)

                Spacer()
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Toggle("连续录入", isOn: $viewModel.isContinuousModeEnabled)
                .toggleStyle(.switch)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(DesignSystem.textSecondary)
                .controlSize(.small)

            Spacer()

            Button {
                viewModel.submitAndKeepOpen()
            } label: {
                Text("保存并继续")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignSystem.primary)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(DesignSystem.primaryContainer.opacity(0.55))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSubmit)
            .opacity(viewModel.canSubmit ? 1 : 0.55)

            Button {
                viewModel.submitAndClose()
            } label: {
                Text("保存")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 36)
                    .background(DesignSystem.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSubmit)
            .opacity(viewModel.canSubmit ? 1 : 0.55)
        }
    }

    private var placeholderText: String {
        switch viewModel.selectedTarget {
        case .inbox:
            return "把待办、灵感或稍后处理的事情先丢进收集箱..."
        case .memo:
            return "随手记下一段想法、会议记录或临时笔记..."
        }
    }

    private var helperText: String {
        "⌘1 收集箱  ⌘2 备忘  ⌘↩ 保存  ⌥⌘↩ 保存并继续  Esc 关闭"
    }

}

private struct MacQuickCaptureTextEditor: NSViewRepresentable {
    static let contentPadding = EdgeInsets(top: 10, leading: 6, bottom: 10, trailing: 6)

    @Binding var text: String
    let focusToken: UUID

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.verticalScroller?.controlSize = .small

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.allowsUndo = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: Self.contentPadding.leading, height: Self.contentPadding.top)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textColor = .labelColor
        textView.insertionPointColor = NSColor(hex: "0c6d45")
        textView.font = Self.editorFont

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.lastFocusToken = focusToken

        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            textView.string = text
        }

        if textView.font != Self.editorFont {
            textView.font = Self.editorFont
        }

        if context.coordinator.lastFocusToken != focusToken {
            context.coordinator.lastFocusToken = focusToken
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    private static var editorFont: NSFont {
        if let descriptor = NSFont.systemFont(ofSize: 15).fontDescriptor.withDesign(.rounded) {
            return NSFont(descriptor: descriptor, size: 15) ?? .systemFont(ofSize: 15)
        }
        return .systemFont(ofSize: 15)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        weak var textView: NSTextView?
        var lastFocusToken: UUID?

        init(text: Binding<String>) {
            self._text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }
    }
}
#endif
