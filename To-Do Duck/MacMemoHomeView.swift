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
            // Header Area (Fixed)
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
                .background(Color(hex: "efefef"))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 0.5)
                )
                .frame(width: 280)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 10)
            .frame(maxWidth: 650)
            .background(DesignSystem.warmBackground)
            
            // Top Input Area (Fixed)
            VStack(spacing: 0) {
                ScrollView {
                    TextField("input_memo_placeholder", text: $inputText, axis: .vertical)
                        .font(.system(size: 16, design: .rounded))
                        .textFieldStyle(.plain)
                        .focused($isInputFocused)
                        .frame(minHeight: 80, alignment: .top)
                        .onSubmit {
                             // TextField with axis: .vertical uses Return for new line.
                             // Cmd+Enter needs to be handled via other means if needed,
                             // or we rely on the button.
                             // But actually, we can add a keyboard shortcut to the View.
                        }
                }
                .scrollIndicators(.hidden)
                .frame(height: 150) // Fixed height for the input area
                .padding(.bottom, 8)
                
                HStack {
                    Text("shortcut_save_memo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: saveMemo) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.3) : DesignSystem.checkedColor)
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
            .padding(.horizontal)
            .padding(.bottom, 20)
            .frame(maxWidth: 650)
            .frame(maxWidth: .infinity) // Center content
            .zIndex(1)
            
            // Scrollable Memo List
            ScrollView {
                LazyVStack(spacing: 20) {
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
                .padding(.horizontal)
                .padding(.bottom, 40)
                .frame(maxWidth: 650)
                .frame(maxWidth: .infinity) // Center content
            }
        }
        .background(DesignSystem.warmBackground)
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
                .frame(width: 24, height: 24)
            }
            
            Text(memo.content)
                .font(.system(size: 16, weight: .regular, design: .rounded))
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
#endif
