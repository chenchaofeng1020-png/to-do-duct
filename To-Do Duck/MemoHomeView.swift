import SwiftUI
import SwiftData
import WidgetKit
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
    @State private var isRefreshing: Bool = false // 下拉刷新状态
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // 背景 - 使用与待办页面一致的背景色
            DesignSystem.background
                .ignoresSafeArea()
            
            if memos.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
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
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 80) // 底部留出空间给 FAB
                }
                .refreshable {
                    await refreshData()
                }
            }
            
            // 悬浮按钮 (FAB) - 使用与待办页面一致的样式
            Button {
                showingInputSheet = true
                Haptics.light()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(DesignSystem.primary)
                    .clipShape(Circle())
                    .shadow(color: DesignSystem.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
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
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            
            Image(systemName: "square.and.pencil")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(DesignSystem.outline)
            
            Text("no_memos_yet")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(DesignSystem.onSurfaceVariant)
            
            Button {
                showingInputSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("create_memo")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(DesignSystem.onPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(DesignSystem.primary)
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 8)
            
            Spacer()
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

    private func refreshData() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        isRefreshing = false
    }
}

struct MemoCardView: View {
    let memo: MemoCardV3
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formatDate(memo.createdAt))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(DesignSystem.textSecondary)
                
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

            ExpandableMemoText(
                content: memo.content,
                font: .system(size: 14, weight: .medium, design: .rounded),
                lineSpacing: 4,
                textColor: DesignSystem.onSurface
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DesignSystem.surfaceContainerLowest)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(DesignSystem.outlineVariant.opacity(0.2), lineWidth: 0.5)
                )
        )
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
                             .fill(DesignSystem.primary.opacity(0.1))
                             .frame(width: 48, height: 48)
                         Image(systemName: "square.and.arrow.up")
                             .font(.system(size: 20, weight: .bold))
                             .foregroundColor(DesignSystem.primary)
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
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 22, weight: .bold))
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
                        Image(systemName: "trash.fill")
                            .font(.system(size: 21, weight: .semibold))
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
                // Placeholder text
                if content.isEmpty {
                    Text("memo_placeholder")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(DesignSystem.textTertiary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .allowsHitTesting(false)
                }
                
                // TextField
                TextField("", text: $content, axis: .vertical)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .focused($isFocused)
                    .textFieldStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .lineSpacing(4)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .onSubmit { }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
