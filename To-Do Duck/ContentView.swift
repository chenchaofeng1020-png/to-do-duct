import SwiftUI
import SwiftData
import WidgetKit

// MARK: - 主入口视图
struct ContentView: View {
    var body: some View {
        MainView()
    }
}

// MARK: - iOS 端实现
struct IOSAppView: View {
    var body: some View {
        ZStack {
            DesignSystem.warmBackground.ignoresSafeArea()
            TabView {
                SimpleNavigationView { TodosView() }
                .tabItem {
                    Image(systemName: "checklist")
                    Text("待办事项")
                }
                SimpleNavigationView { MemoView() }
                .tabItem {
                    Image(systemName: "note.text")
                    Text("备忘录")
                }
                SimpleNavigationView { SettingsView() }
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
            }
            .tint(.black)
        }
    }
}

// 供 macOS 预览或其他用途的简单包装
struct SimpleNavigationView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        NavigationView { content }
    }
}

struct TodosView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyCardV3.date, order: .reverse) private var cards: [DailyCardV3]
    @State private var searchText: String = ""
    @State private var addingTextByCard: [UUID: String] = [:]
    @State private var showTargetPickerForItem: TodoItemV3?
    @State private var targetDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var showPastDateAlert: Bool = false
    @AppStorage("allowPastContinuation") private var allowPastContinuation: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                    HStack {
                        TextField("搜索…", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            createTodayCard()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("新的一天")
                            }
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(DesignSystem.neonLime)
                            .cornerRadius(18)
                        }
                    }
                    ForEach(filtered(cards)) { card in
                        DayCardView(
                            card: card,
                            addingText: Binding(
                                get: { addingTextByCard[card.id] ?? "" },
                                set: { addingTextByCard[card.id] = $0 }
                            ),
                            onAdd: { text in addItem(text: text, to: card) },
                            onContinue: { item in
                                showTargetPickerForItem = item
                                targetDate = Calendar.current.date(byAdding: .day, value: 1, to: card.date) ?? card.date
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
        }
        .navigationTitle("待办事项")
        .sheet(item: $showTargetPickerForItem) { item in
            VStack {
                DatePicker("选择目标日期", selection: $targetDate, displayedComponents: .date)
                Button("确认延续") {
                    let baseDate = item.card?.date ?? Calendar.current.startOfDay(for: item.createdAt)
                    if !allowPastContinuation && Calendar.current.startOfDay(for: targetDate) < baseDate {
                        showPastDateAlert = true
                    } else {
                        try? ContinuationService.continueItem(item, to: targetDate, context: modelContext)
                        Haptics.success()
                        showTargetPickerForItem = nil
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .presentationDetents([.height(200)])
        }
        .alert("不允许选择过去日期", isPresented: $showPastDateAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("请选择晚于该事项所在日期的目标卡片。")
        }
    }

    private func filtered(_ cards: [DailyCardV3]) -> [DailyCardV3] {
        guard !searchText.isEmpty else { return cards }
        let keyword = searchText.lowercased()
        return cards.filter { c in
            let title = DateFormatter.localizedString(from: c.date, dateStyle: .long, timeStyle: .none).lowercased()
            if title.contains(keyword) { return true }
            return c.items.contains { $0.title.lowercased().contains(keyword) }
        }
    }

    private func createTodayCard() {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyCardV3>(predicate: #Predicate { $0.date == today })
        if (try? modelContext.fetch(descriptor).first) != nil { return }
        let card = DailyCardV3(date: today)
        modelContext.insert(card)
    }

    private func addItem(text: String, to card: DailyCardV3) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let item = TodoItemV3(title: t, card: card)
        modelContext.insert(item)
        Haptics.light()
    }
}

struct DayCardView: View {
    @Environment(\.modelContext) private var modelContext
    var card: DailyCardV3
    @Binding var addingText: String
    var onAdd: (String) -> Void
    var onContinue: (TodoItemV3) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(card.date, format: .dateTime.year().month().day())
                    .font(.title3.weight(.bold))
                Spacer()
            }
            VStack(spacing: 10) {
                ForEach(card.items) { item in
                    TodoItemRow(item: item) {
                        onContinue(item)
                    }
                }
                HStack {
                    TextField("输入待办回车↩︎", text: $addingText)
                        .onSubmit {
                            let t = addingText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            onAdd(t)
                            addingText = ""
                            Haptics.light()
                        }
                }
            }
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

struct TodoItemRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: TodoItemV3
    var onContinue: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            Button {
                item.isDone.toggle()
                item.completedAt = item.isDone ? Date() : nil
            } label: {
                Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isDone ? DesignSystem.purple : .secondary)
            }
            if let idx = item.chainIndex, idx >= 2 {
                Text("\(idx)")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.purple.opacity(0.2))
                    .foregroundColor(DesignSystem.purple)
                    .cornerRadius(10)
            }
            TextField("标题", text: $item.title)
            Spacer()
            Button("继续一天", action: onContinue)
                .foregroundColor(DesignSystem.purple)
        }
    }
}

struct MemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemoCardV3.createdAt, order: .reverse) private var memos: [MemoCardV3]
    @State private var content: String = ""

    var body: some View {
        List {
            HStack {
                    TextField("输入备忘生成卡片", text: $content)
                        .onSubmit { createMemo() }
                    Button("添加") { createMemo() }
                        .buttonStyle(.borderedProminent)
                }
                ForEach(memos) { memo in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(memo.content)
                        Text(memo.createdAt, format: .dateTime.year().month().day().hour().minute())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(DesignSystem.softBackground)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .contextMenu {
                        Button(memo.pinned ? "取消置顶" : "置顶") { memo.pinned.toggle() }
                        Button(memo.archived ? "取消归档" : "归档") { memo.archived.toggle() }
                        Button("删除", role: .destructive) { modelContext.delete(memo) }
                    }
                }
            }
            .navigationTitle("备忘录")
        }
    
    private func createMemo() {
        let t = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        modelContext.insert(MemoCardV3(content: t))
        content = ""
    }
}

struct SettingsView: View {
    @AppStorage("allowPastContinuation") private var allowPastContinuation: Bool = false
    
    var body: some View {
        Form {
            Section(header: Text("数据同步")) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("iCloud 同步已关闭")
                    Spacer()
                }
                Text("当前仅支持本地存储，删除应用后数据将丢失。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("延续规则")) {
                Toggle("允许选择过去日期延续", isOn: $allowPastContinuation)
            }
        }
        .navigationTitle("设置")
    }
}
