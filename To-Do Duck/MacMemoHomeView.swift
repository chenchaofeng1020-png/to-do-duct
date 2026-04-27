import SwiftUI
import SwiftData

#if os(macOS)
struct MacMemoHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemoCardV3.createdAt, order: .reverse) private var memos: [MemoCardV3]
    @State private var inputText: String = ""
    @State private var searchText: String = ""
    @State private var selectedMemo: MemoCardV3?
    @FocusState private var isInputFocused: Bool
    
    private var filteredMemos: [MemoCardV3] {
        if searchText.isEmpty {
            return memos
        } else {
            return memos.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
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
                                
                                MacMemoEditor(text: $inputText)
                                    .frame(minHeight: (isInputFocused || !inputText.isEmpty) ? 80 : 30, alignment: .top)
                                    .focused($isInputFocused)
                            }
                            .frame(height: (isInputFocused || !inputText.isEmpty) ? 150 : 50)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isInputFocused)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: inputText.isEmpty)
                            .padding(.bottom, 8)
                            
                            HStack {
                                Text("shortcut_save_memo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        withAnimation {
            let newMemo = MemoCardV3(content: trimmed)
            modelContext.insert(newMemo)
            inputText = ""
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
            
            Text(memo.content)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(DesignSystem.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled) // Allow text selection
                .lineSpacing(4)
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

struct MemoEditSheet: View {
    @Bindable var memo: MemoCardV3
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("edit_memo")
                    .font(.headline)
                Spacer()
                Button("done") {
                    dismiss()
                }
            }
            .padding()
            
            TextEditor(text: $memo.content)
                .font(.body)
                .padding()
                .background(DesignSystem.cardBackground)
                .cornerRadius(8)
                .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 500, height: 400)
        .background(DesignSystem.softBackground)
    }
}

struct MacMemoEditor: NSViewRepresentable {
    @Binding var text: String
    
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
        
        // Match standard font with rounded design
        if let descriptor = NSFont.systemFont(ofSize: 16).fontDescriptor.withDesign(.rounded) {
            textView.font = NSFont(descriptor: descriptor, size: 16)
        } else {
            textView.font = .systemFont(ofSize: 16)
        }
        
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        // Match placeholder top padding (8pt)
        textView.textContainerInset = NSSize(width: 0, height: 8)
        
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
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
        }
    }
}
#endif
