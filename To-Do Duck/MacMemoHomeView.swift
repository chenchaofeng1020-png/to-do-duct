#if os(macOS)
import SwiftUI
import SwiftData
import AppKit

struct MacMemoHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemoCardV3.createdAt, order: .reverse) private var memos: [MemoCardV3]
    let selectedDate: Date?
    @State private var inputText: String = ""
    @State private var inputAttributedText: NSAttributedString = MemoRichTextFactory.makeAttributedString(from: "", fontSize: 16)
    @State private var searchText: String = ""
    @State private var selectedMemo: MemoCardV3?
    @FocusState private var isInputFocused: Bool
    @StateObject private var inputEditorState = MacMemoEditorState()
    private let saveService = QuickCaptureSaveService(modelContainer: To_Do_DuckApp.sharedModelContainer)
    
    private var filteredMemos: [MemoCardV3] {
        let dateFiltered = memos.filter {
            guard let selectedDate else { return true }
            return Calendar.current.isDate($0.createdAt, inSameDayAs: selectedDate)
        }
        if searchText.isEmpty {
            return dateFiltered
        }
        return dateFiltered.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Scrollable Content
            ScrollView {
                // Header Area (Moved)
                HStack {
                    Text("memos")
                        .font(.largeTitle)
                        .bold()
                    
                    Spacer()
                    
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("search_memo_placeholder", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(DesignSystem.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignSystem.cardBorder, lineWidth: 0.5)
                    )
                    .frame(width: 280)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)
                .frame(maxWidth: 650)
                .frame(maxWidth: .infinity)
                .background(DesignSystem.background)

                LazyVStack(spacing: 20) {
                    Section {
                        if selectedDate != nil && filteredMemos.isEmpty {
                            ContentUnavailableView {
                                Label("当天没有备忘", systemImage: "square.and.pencil")
                            } description: {
                                Text((selectedDate ?? Date()).formatted(date: .complete, time: .omitted))
                            }
                            .padding(.top, 20)
                        } else {
                            ForEach(filteredMemos) { memo in
                                MacMemoCardView(memo: memo, onEdit: {
                                    selectedMemo = memo
                                }, onDelete: {
                                    withAnimation {
                                        modelContext.delete(memo)
                                    }
                                })
                                    .onTapGesture {
                                        selectedMemo = memo
                                    }
                                    .contextMenu {
                                        Button {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(memo.content, forType: .string)
                                        } label: {
                                            Label("copy", systemImage: "doc.on.doc")
                                        }
                                        
                                        Button(role: .destructive) {
                                            withAnimation {
                                                modelContext.delete(memo)
                                            }
                                        } label: {
                                            Label("delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    } header: {
                        // Sticky Input Area
                        VStack(spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                if inputText.isEmpty {
                                    Text("input_memo_placeholder")
                                        .font(.system(size: 16, design: .rounded))
                                        .foregroundColor(DesignSystem.textTertiary)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                                
                                MacMemoEditor(
                                    text: $inputText,
                                    attributedText: $inputAttributedText,
                                    editorState: inputEditorState,
                                    fontSize: 16,
                                    onFocusChange: { isInputFocused = $0 }
                                )
                                    .frame(minHeight: (isInputFocused || !inputText.isEmpty) ? 80 : 30, alignment: .top)
                                    .focused($isInputFocused)
                            }
                            .frame(height: (isInputFocused || !inputText.isEmpty) ? 150 : 50)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isInputFocused)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: inputText.isEmpty)
                            .padding(.bottom, 8)
                            
                            HStack {
                                HStack(spacing: 10) {
                                    MemoStyleToolbar(editorState: inputEditorState, fontSize: 16)
                                    Text("shortcut_save_memo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .opacity((isInputFocused || !inputText.isEmpty) ? 1 : 0)
                                
                                Spacer()
                                
                                Button(action: saveMemo) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.3) : DesignSystem.primary)
                                }
                                .buttonStyle(.plain)
                                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .keyboardShortcut(.return, modifiers: .command)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(DesignSystem.cardBackground)
                        .cornerRadius(DesignSystem.cardCorner)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.cardCorner)
                                .stroke(DesignSystem.cardBorder, lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                        // Removed extra bottom padding to reduce gap
                        .frame(maxWidth: 650)
                        .frame(maxWidth: .infinity)
                        .background(DesignSystem.background) // Mask content behind header
                        .padding(.top, 10) // Extra padding top within scroll view
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
                .frame(maxWidth: 650)
                .frame(maxWidth: .infinity)
                .thinScrollbar()
            }
        }
        .background(DesignSystem.background)
        // .navigationTitle("Memos") // Removed standard title to use custom header
        .sheet(item: $selectedMemo) { memo in
            // Reusing existing logic for editing if available, or simple edit sheet
             MemoEditSheet(memo: memo)
        }
    }
    
    private func saveMemo() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        withAnimation {
            try? saveService.saveMemo(
                text: inputText,
                richTextData: MemoRichTextCodec.encode(inputAttributedText)
            )
            inputText = ""
            inputAttributedText = MemoRichTextFactory.makeAttributedString(from: "", fontSize: 16)
            isInputFocused = true // Keep focus for rapid entry
        }
    }
}

struct MacMemoCardView: View {
    let memo: MemoCardV3
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(memo.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(DesignSystem.textTertiary)
                
                Spacer()
                
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("edit", systemImage: "pencil")
                    }
                    
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(memo.content, forType: .string)
                    } label: {
                        Label("copy", systemImage: "doc.on.doc")
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.textSecondary)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 24, height: 24)
            }
            
            if memo.hasCustomRichTextFormatting(fontSize: 14) {
                ExpandableMemoText(
                    attributedContent: memo.attributedContent(fontSize: 14),
                    allowsSelection: true
                )
            } else {
                ExpandableMemoText(
                    content: memo.content,
                    font: .system(size: 14, weight: .medium, design: .rounded),
                    lineSpacing: 4,
                    textColor: DesignSystem.onSurface,
                    allowsSelection: true
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(DesignSystem.cardBackground)
        .cornerRadius(DesignSystem.cardCorner)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cardCorner)
                .stroke(DesignSystem.cardBorder, lineWidth: 0.5)
        )
    }
}

private extension MemoCardV3 {
    func hasCustomRichTextFormatting(fontSize: CGFloat) -> Bool {
        guard let decoded = MemoRichTextCodec.decode(richTextData), decoded.length > 0 else {
            return false
        }

        let fullRange = NSRange(location: 0, length: decoded.length)
        var hasCustomFormatting = false

        decoded.enumerateAttributes(in: fullRange) { attributes, _, stop in
            if let color = attributes[.foregroundColor] as? NSColor,
               color != MemoRichTextFactory.plainTextColor {
                hasCustomFormatting = true
                stop.pointee = true
                return
            }

            if let font = attributes[.font] as? NSFont {
                let hasBold = font.fontDescriptor.symbolicTraits.contains(.bold)
                if hasBold {
                    hasCustomFormatting = true
                    stop.pointee = true
                    return
                }
            }

            if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle,
               paragraphStyle.headIndent > 0 || paragraphStyle.firstLineHeadIndent > 0 {
                hasCustomFormatting = true
                stop.pointee = true
            }
        }

        return hasCustomFormatting
    }
}

struct MemoEditSheet: View {
    @Bindable var memo: MemoCardV3
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var attributedText: NSAttributedString = MemoRichTextFactory.makeAttributedString(from: "", fontSize: 16)
    @StateObject private var editorState = MacMemoEditorState()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("edit_memo")
                    .font(.headline)
                Spacer()
                MemoStyleToolbar(editorState: editorState, fontSize: 16)
                Button("done") {
                    memo.updateRichContent(attributedText)
                    dismiss()
                }
            }
            .padding()
            
            MacMemoEditor(
                text: $text,
                attributedText: $attributedText,
                editorState: editorState,
                fontSize: 16
            )
                .padding()
                .background(DesignSystem.cardBackground)
                .cornerRadius(8)
                .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 500, height: 400)
        .background(DesignSystem.softBackground)
        .onAppear {
            text = memo.content
            attributedText = memo.attributedContent(fontSize: 16)
        }
    }
}

struct MacMemoEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var attributedText: NSAttributedString
    let editorState: MacMemoEditorState
    var fontSize: CGFloat = 16
    var onFocusChange: ((Bool) -> Void)? = nil
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        let textView = NSTextView()
        textView.autoresizingMask = [.width]
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.allowsUndo = true
        
        // Match standard font with rounded design
        textView.font = MemoRichTextFactory.baseFont(size: fontSize)
        
        textView.isRichText = true
        textView.importsGraphics = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textColor = MemoRichTextFactory.plainTextColor
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0
        // Match placeholder top padding (8pt)
        textView.textContainerInset = NSSize(width: 0, height: 8)
        textView.textStorage?.setAttributedString(attributedText)
        
        scrollView.documentView = textView
        editorState.textView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        editorState.textView = textView
        if textView.attributedString() != attributedText {
            textView.textStorage?.setAttributedString(attributedText)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacMemoEditor
        
        init(_ parent: MacMemoEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
            self.parent.attributedText = textView.attributedString()
        }

        func textDidBeginEditing(_ notification: Notification) {
            parent.onFocusChange?(true)
        }

        func textDidEndEditing(_ notification: Notification) {
            parent.onFocusChange?(false)
        }
    }
}

private struct MemoStyleToolbar: View {
    @ObservedObject var editorState: MacMemoEditorState
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: 6) {
            styleButton(systemName: "bold") {
                editorState.apply(.toggleBold, fontSize: fontSize)
            }

            Menu {
                colorButton("默认", color: MemoRichTextFactory.plainTextColor)
                colorButton("红色", color: .systemRed)
                colorButton("橙色", color: .systemOrange)
                colorButton("蓝色", color: .systemBlue)
                colorButton("绿色", color: .systemGreen)
            } label: {
                Image(systemName: "paintpalette")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignSystem.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(DesignSystem.softBackground.opacity(0.001))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)

            styleButton(systemName: "list.bullet") {
                editorState.apply(.applyList(.unordered), fontSize: fontSize)
            }

            styleButton(systemName: "list.number") {
                editorState.apply(.applyList(.ordered), fontSize: fontSize)
            }
        }
    }

    private func styleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignSystem.textSecondary)
                .frame(width: 24, height: 24)
                .background(DesignSystem.softBackground.opacity(0.001))
        }
        .buttonStyle(.plain)
    }

    private func colorButton(_ title: String, color: NSColor) -> some View {
        Button(title) {
            editorState.apply(.setColor(color), fontSize: fontSize)
        }
    }
}
#endif
