import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct MemoHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemoCardV3.createdAt, order: .reverse) private var memos: [MemoCardV3]
    @State private var showingInputSheet = false
    
    // State for actions
    @State private var selectedMemo: MemoCardV3? // For Action Sheet
    @State private var editingMemo: MemoCardV3? // For Edit Sheet
    @State private var sharingMemo: MemoCardV3? // For Share Sheet
    @State private var showDeleteAlert = false
    @State private var memoToDelete: MemoCardV3?
    @State private var showToast = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 背景
            DesignSystem.warmBackground
                .ignoresSafeArea()
            
            if memos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(memos) { memo in
                            MemoCardView(
                                memo: memo,
                                onTap: {
                                    selectedMemo = memo
                                }
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 80) // 底部留出空间给 FAB
                }
            }
            
            // 悬浮按钮 (FAB)
            Button {
                showingInputSheet = true
                Haptics.light()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(DesignSystem.checkedColor)
                    .clipShape(Circle())
                    .shadow(color: DesignSystem.shadowColor, radius: 8, x: 0, y: 4)
            }
            .padding(24)
            
            // Toast Overlay
            if showToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("content_copied")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(24)
                    .shadow(radius: 8)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(100)
                .animation(.spring(), value: showToast)
            }
        }
        .navigationTitle(NSLocalizedString("memos", comment: "Memo Tab Title"))
        .sheet(isPresented: $showingInputSheet) {
            MemoInputSheet()
        }
        // Action Sheet
        .sheet(item: $selectedMemo) { memo in
            MemoActionSheet(
                memo: memo,
                onEdit: {
                    editingMemo = memo
                },
                onShare: {
                    sharingMemo = memo
                },
                onCopy: {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(memo.content, forType: .string)
                    #else
                    UIPasteboard.general.string = memo.content
                    #endif
                    Haptics.success()
                    withAnimation {
                        showToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showToast = false
                        }
                    }
                },
                onDelete: {
                    memoToDelete = memo
                    showDeleteAlert = true
                }
            )
        }
        // Edit Sheet
        .sheet(item: $editingMemo) { memo in
            MemoInputSheet(memoToEdit: memo)
        }
        // Share Sheet
        .sheet(item: $sharingMemo) { memo in
            MemoShareSheet(memo: memo)
        }
        // Delete Alert
        .alert("delete_memo", isPresented: $showDeleteAlert) {
            Button("delete", role: .destructive) {
                if let memo = memoToDelete {
                    deleteMemo(memo)
                }
            }
            Button("cancel", role: .cancel) {}
        } message: {
            Text("delete_memo_confirm")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.textTertiary)
            Text("no_memos_yet")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deleteMemo(_ memo: MemoCardV3) {
        withAnimation {
            modelContext.delete(memo)
        }
        Haptics.light()
        memoToDelete = nil
    }
}

struct MemoCardView: View {
    let memo: MemoCardV3
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formatDate(memo.createdAt))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(DesignSystem.textTertiary)
                
                Spacer()
                
                // 更多操作菜单
                Button {
                    onTap()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.textTertiary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
            }

            Text(memo.content)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(DesignSystem.textPrimary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(DesignSystem.cardBackground)
        .cornerRadius(16)
        .shadow(color: DesignSystem.shadowColor, radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = NSLocalizedString("yesterday", comment: "") + " HH:mm"
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
        }
        return formatter.string(from: date)
    }
}

struct MemoActionSheet: View {
    let memo: MemoCardV3
    var onEdit: () -> Void
    var onShare: () -> Void
    var onCopy: () -> Void
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Handle
            ZStack {
                Capsule()
                    .fill(DesignSystem.textSecondary.opacity(0.2))
                    .frame(width: 36, height: 4)
            }
            .padding(.top, 12)
            .padding(.horizontal, 20)
            
            // Content Preview
            Text(memo.content)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(DesignSystem.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Primary Action: Share
            Button(action: {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onShare()
                }
            }) {
                HStack(spacing: 0) {
                    // Icon
                    ZStack {
                         Circle()
                             .fill(DesignSystem.checkedColor.opacity(0.1))
                             .frame(width: 48, height: 48)
                         Image(systemName: "square.and.arrow.up")
                             .font(.system(size: 20, weight: .bold))
                             .foregroundColor(DesignSystem.checkedColor)
                    }
                    .padding(.leading, 16)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("share")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(DesignSystem.textPrimary)
                        Text("share_memo_desc") 
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignSystem.textTertiary)
                        .padding(.trailing, 20)
                }
                .frame(height: 80)
                .background(DesignSystem.cardBackground)
                .cornerRadius(20)
                .shadow(color: DesignSystem.shadowColor, radius: 10, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Secondary Actions Row
            HStack(spacing: 12) {
                 // Edit
                 Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { onEdit() }
                 }) {
                    VStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 22))
                            .foregroundColor(DesignSystem.textPrimary)
                        Text("edit")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(DesignSystem.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: DesignSystem.shadowColor, radius: 10, x: 0, y: 4)
                 }
                 .buttonStyle(ScaleButtonStyle())
                 
                 // Copy
                 Button(action: {
                    onCopy()
                    dismiss()
                 }) {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 22))
                            .foregroundColor(DesignSystem.textPrimary)
                        Text("copy")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(DesignSystem.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: DesignSystem.shadowColor, radius: 10, x: 0, y: 4)
                 }
                 .buttonStyle(ScaleButtonStyle())
                 
                 // Delete
                 Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { onDelete() }
                 }) {
                    VStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 22))
                            .foregroundColor(.red)
                        Text("delete")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(DesignSystem.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: DesignSystem.shadowColor, radius: 10, x: 0, y: 4)
                 }
                 .buttonStyle(ScaleButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(DesignSystem.softBackground)
        .presentationDetents([.height(350)])
        .presentationCornerRadius(32)
    }
}

struct MemoInputSheet: View {
    var memoToEdit: MemoCardV3?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var content: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("memo_placeholder")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(DesignSystem.textTertiary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $content)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .focused($isFocused)
                    .scrollContentBackground(.hidden) // 移除默认背景
                    .background(Color.clear)
                    .padding()
                    .frame(maxHeight: .infinity)
            }
            .background(DesignSystem.cardBackground)
            .navigationTitle(memoToEdit == nil ? "record_memo" : "edit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.textSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        saveMemo()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? DesignSystem.textTertiary : DesignSystem.checkedColor)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let memo = memoToEdit, content.isEmpty {
                    content = memo.content
                }
                
                // 延迟聚焦，保证 Sheet 动画流畅
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
        .presentationDragIndicator(.visible)
    }
    
    private func saveMemo() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        if let memo = memoToEdit {
            memo.content = trimmedContent
        } else {
            let newMemo = MemoCardV3(content: trimmedContent)
            modelContext.insert(newMemo)
        }
        
        Haptics.success()
        dismiss()
    }
}
