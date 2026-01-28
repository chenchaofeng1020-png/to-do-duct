import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import WidgetKit

struct MainView: View {
    var body: some View {
        #if os(iOS)
        TabView {
            // 待办 Tab
            NavigationView {
                TodoHomeView()
            }
            .tabItem {
                Image(systemName: "checklist")
            }
            .onOpenURL { url in
                // 处理 Widget 跳转链接
                print("Opened from Widget: \(url)")
            }
            
            // 备忘 Tab
            NavigationView {
                MemoHomeView()
            }
            .tabItem {
                Image(systemName: "square.and.pencil")
            }
            
            // 我的 Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                }
        }
        .accentColor(DesignSystem.checkedColor) // 使用主题色
        #else
        MacAppView()
        #endif
    }
}

struct TodoEditSheet: View {
    @Bindable var item: TodoItemV3
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var editingTitle: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 自定义 Header
            HStack {
                Text("edit_todo")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignSystem.textPrimary)
                Spacer()
                Button("done") {
                    saveAndDismiss()
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .padding(.bottom, 4)
            
            TextField("enter_todo_content", text: $editingTitle, axis: .vertical)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .focused($isFocused)
                .padding()
                .background(DesignSystem.cardBackground)
                .cornerRadius(12)
                .submitLabel(.done)
                .onSubmit {
                    saveAndDismiss()
                }
            
            Spacer()
        }
        .padding(20)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
        .onAppear {
            editingTitle = item.title
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .presentationDetents([.height(200)])
        .presentationCornerRadius(24)
    }
    
    private func saveAndDismiss() {
        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            item.title = trimmed
        }
        dismiss()
    }
}

struct TodoActionSheet: View {
    let item: TodoItemV3
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    // 获取明天的日期信息
    private var tomorrowInfo: (day: String, month: String) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        return (dayFormatter.string(from: tomorrow), monthFormatter.string(from: tomorrow))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 顶部栏：装饰条
            ZStack {
                Capsule()
                    .fill(DesignSystem.textSecondary.opacity(0.2))
                    .frame(width: 36, height: 4)
            }
            .padding(.top, 12)
            .padding(.horizontal, 20)
            
            // 标题预览
            Text(item.title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(DesignSystem.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 优先级选择
            HStack(spacing: 12) {
                ForEach(TodoPriority.allCases, id: \.self) { priority in
                    Button(action: {
                        withAnimation {
                            item.priority = priority
                        }
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(priority == .none ? DesignSystem.textTertiary : priority.color, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                                
                                if item.priority == priority {
                                    Circle()
                                        .fill(priority == .none ? DesignSystem.textTertiary : priority.color)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            
                            Text(priority.label)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(item.priority == priority ? (priority == .none ? DesignSystem.textTertiary : priority.color) : DesignSystem.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                             RoundedRectangle(cornerRadius: 12)
                                .fill(item.priority == priority ? (priority == .none ? DesignSystem.textTertiary.opacity(0.1) : priority.color.opacity(0.1)) : Color.clear)
                        )
                    }
                }
            }
            .padding(12)
            .background(DesignSystem.cardBackground)
            .cornerRadius(20)
            .shadow(color: DesignSystem.shadowColor, radius: 10, x: 0, y: 4)
            
            // 加一天按钮（主要操作，突出显示）
            Button(action: {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onContinue()
                }
            }) {
                HStack(spacing: 0) {
                    // 日历图标部分
                    VStack(spacing: 0) {
                        Text(tomorrowInfo.month.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.8))
                        
                        Text(tomorrowInfo.day)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(DesignSystem.textPrimary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DesignSystem.cardBackground)
                    }
                    .frame(width: 48, height: 52)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DesignSystem.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: DesignSystem.shadowColor, radius: 2, x: 0, y: 1)
                    .padding(.leading, 16)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("add_one_day")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(DesignSystem.textPrimary)
                        Text("or_select_other_date")
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
            
            // 次要操作行：编辑和删除
            HStack(spacing: 16) {
                // 编辑按钮
                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onEdit()
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(DesignSystem.textPrimary)
                        Text("edit")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(DesignSystem.cardBackground)
                    .cornerRadius(20)
                    .shadow(color: DesignSystem.shadowColor, radius: 10, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // 删除按钮
                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onDelete()
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 22))
                            .foregroundColor(.red)
                        Text("delete")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
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
        .presentationDetents([.height(400)])
        .presentationCornerRadius(32)
    }
}

struct TodoHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\DailyCardV3.date, order: .reverse), SortDescriptor(\DailyCardV3.createdAt, order: .reverse)]) private var cards: [DailyCardV3]
    @State private var addingTextByCard: [UUID: String] = [:]
    @State private var showTargetPickerForItem: TodoItemV3?
    @State private var editingItem: TodoItemV3? // 控制编辑状态
    @State private var menuForItem: TodoItemV3? // 新增：控制菜单显示
    @State private var targetDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var showPastDateAlert: Bool = false
    @AppStorage("allowPastContinuation") private var allowPastContinuation: Bool = false
    @State private var confettiCounter: Int = 0 // 控制撒花效果
    @State private var confettiSourcePosition: CGPoint = .zero // 撒花爆发点
    @State private var showMenu: Bool = false
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                HeaderBar()
                HStack {
                    FloatingNewDayButton { withAnimation { createTodayCard() } }
                    Spacer()
                }
                ForEach(cards) { card in
                        DayCardViewNew(
                            card: card,
                            addingText: Binding(
                                get: { addingTextByCard[card.id] ?? "" },
                                set: { addingTextByCard[card.id] = $0 }
                            ),
                            onAdd: { text in withAnimation { addItem(text: text, to: card) } },
                            onContinue: { item in
                                showTargetPickerForItem = item
                                targetDate = Calendar.current.date(byAdding: .day, value: 1, to: card.date) ?? card.date
                            },
                            onEdit: { item in
                                menuForItem = item // 点击触发菜单
                            },
                            onComplete: { sourcePoint in
                                confettiSourcePosition = sourcePoint
                                confettiCounter += 1
                                Haptics.success()
                            }
                        )
                    }
                    
                    // 空状态提示
                    if cards.isEmpty {
                        VStack(spacing: 16) {
                            Spacer().frame(height: 40)
                            Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.textTertiary.opacity(0.5))
                        Text("todo_list_empty")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.textSecondary)
                        Button("create_today") {
                            withAnimation { createTodayCard() }
                        }
                            .buttonStyle(.borderedProminent)
                            .tint(DesignSystem.checkedColor)
                            .controlSize(.large)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(
                ZStack(alignment: .topTrailing) {
                    DesignSystem.warmBackground
                        .ignoresSafeArea()
                        .onTapGesture {
                            #if os(iOS)
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            #endif
                        }
                    
                    // 替换为浅色花纹装饰
                    PatternDecorationView()
                        .offset(x: 20, y: -20)
                        .ignoresSafeArea()
                }
            )
            .scrollDismissesKeyboard(.interactively)
            #if os(iOS)
            .navigationBarHidden(true)
            #else
            .navigationTitle("To-Do Duck")
            #endif
        .overlay(
                // 撒花层 - 移至最上层 Overlay
                ConfettiView(counter: $confettiCounter, burstPosition: confettiSourcePosition)
                    .background(Color.clear) // 显式设置背景透明
                    .ignoresSafeArea()
                    .allowsHitTesting(false) // 确保不阻挡点击
            )
        
        .sheet(item: $editingItem) { item in
            TodoEditSheet(item: item)
        }
        .sheet(item: $menuForItem) { item in
            TodoActionSheet(item: item, onEdit: {
                editingItem = item
            }, onDelete: {
                withAnimation {
                    modelContext.delete(item)
                }
                // 强制保存并刷新 Widget
                try? modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            }, onContinue: {
                showTargetPickerForItem = item
                if let cardDate = item.card?.date {
                    targetDate = Calendar.current.date(byAdding: .day, value: 1, to: cardDate) ?? Date()
                } else {
                    targetDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                }
            })
        }
        .sheet(item: $showTargetPickerForItem) { item in
            TargetDatePickerSheet(item: item, targetDate: $targetDate) {
                let baseDate = item.card?.date ?? Calendar.current.startOfDay(for: item.createdAt)
                if !allowPastContinuation && Calendar.current.startOfDay(for: targetDate) < baseDate {
                    showPastDateAlert = true
                } else {
                    withAnimation { try? ContinuationService.continueItem(item, to: targetDate, context: modelContext) }
                    Haptics.success()
                    showTargetPickerForItem = nil
                }
            }
        }
        .alert(NSLocalizedString("cannot_select_past_date", comment: "Alert title for past date selection"), isPresented: $showPastDateAlert) {
            Button(NSLocalizedString("ok", comment: "OK button"), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("select_future_date_message", comment: "Alert message for past date selection"))
        }
        .sheet(isPresented: $showMenu) {
            NavigationView {
                SettingsView()
            }
        }
        .onAppear {
            if !hasLaunchedBefore {
                createInitialCard()
                hasLaunchedBefore = true
            }
        }
    }

    private func createInitialCard() {
        let today = Calendar.current.startOfDay(for: Date())
        let card = DailyCardV3(date: today)
        modelContext.insert(card)
        
        let welcomeItem = TodoItemV3(title: NSLocalizedString("welcome_message", comment: "Welcome message"), card: card)
        welcomeItem.orderIndex = 0
        modelContext.insert(welcomeItem)
        
        let swipeItem = TodoItemV3(title: NSLocalizedString("tap_to_view_details", comment: "Tap to view details"), card: card)
        swipeItem.orderIndex = 1
        modelContext.insert(swipeItem)
    }

    private func createTodayCard() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 筛选出今天的卡片
        let todayCards = cards.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        
        // 准备日期格式化器，用于生成默认标题和比对
        let formatter = DateFormatter()
        formatter.dateFormat = NSLocalizedString("card_date_format", comment: "Date format for card title")
        let defaultDateTitle = formatter.string(from: today)
        
        var titleToUse: String? = nil
        
        // 获取今天所有卡片的显示标题
        let existingTitles = Set(todayCards.map { $0.customTitle ?? defaultDateTitle })
        
        // 检查默认标题是否已被占用
        if existingTitles.contains(defaultDateTitle) {
            // 需要加序号
            var counter = 1
            var candidate = "\(defaultDateTitle) (\(counter))"
            while existingTitles.contains(candidate) {
                counter += 1
                candidate = "\(defaultDateTitle) (\(counter))"
            }
            titleToUse = candidate
        } else {
            // 默认标题未被占用，使用默认（nil）
            titleToUse = nil
        }
        
        let card = DailyCardV3(date: today)
        card.customTitle = titleToUse
        modelContext.insert(card)
    }

    private func addItem(text: String, to card: DailyCardV3) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        
        // 计算当前最大的 orderIndex
        let maxOrder = card.items.map { $0.orderIndex }.max() ?? -1
        
        let item = TodoItemV3(title: t, card: card)
        item.orderIndex = maxOrder + 1
        modelContext.insert(item)
        Haptics.light()
        
        // 强制保存以确保 Widget 能读到最新数据
        try? modelContext.save()
        
        // 刷新 Widget
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct HeaderBar: View {
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = NSLocalizedString("date_format", comment: "Date format string")
        formatter.locale = Locale.current
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                // App Logo
                DuckIcon(size: 34)
                
                Text("To-Do Duck")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.textPrimary)
            }
            Text(dateString)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 16)
    }
}

struct CardTitleEditSheet: View {
    @Bindable var card: DailyCardV3
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var editingTitle: String = ""
    
    // 辅助计算属性：默认标题
    private var defaultTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = NSLocalizedString("card_date_format", comment: "Date format for card title")
        formatter.locale = Locale.current
        return formatter.string(from: card.date)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 自定义 Header
            HStack {
                Text("edit_title")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignSystem.textPrimary)
                Spacer()
                Button("done") {
                    saveAndDismiss()
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .padding(.bottom, 4)
            
            TextField("enter_card_title", text: $editingTitle)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .focused($isFocused)
                .padding()
                .background(DesignSystem.cardBackground)
                .cornerRadius(12)
                .submitLabel(.done)
                .onSubmit {
                    saveAndDismiss()
                }
            
            Text("empty_for_date")
                .font(.caption)
                .foregroundColor(DesignSystem.textTertiary)
            
            Spacer()
        }
        .padding(20)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
        .onAppear {
            // 初始化编辑文本：如果有自定义标题则使用，否则使用默认日期标题
            if let custom = card.customTitle, !custom.isEmpty {
                editingTitle = custom
            } else {
                editingTitle = defaultTitle
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .presentationDetents([.height(250)])
        .presentationCornerRadius(24)
    }
    
    private func saveAndDismiss() {
        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        card.customTitle = trimmed.isEmpty ? nil : trimmed
        dismiss()
    }
}

struct TodoDropDelegate: DropDelegate {
    let item: TodoItemV3
    let items: [TodoItemV3]
    let draggingItem: TodoItemV3?
    var onFinish: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        onFinish()
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggingItem = draggingItem else { return }
        
        // 如果拖拽的是自己，或者不同卡片之间的拖拽（目前仅支持同卡片排序），则忽略
        // 注意：这里我们假设 items 属于同一个卡片。如果支持跨卡片拖拽，逻辑会更复杂。
        // 目前 items 是从 DayCardViewNew 传入的，属于同一个 card。
        // 还需要检查 draggingItem 是否在 items 中（防止跨卡片拖拽时的崩溃）
        guard draggingItem != item,
              items.contains(draggingItem),
              let fromIndex = items.firstIndex(of: draggingItem),
              let toIndex = items.firstIndex(of: item)
        else { return }
        
        if fromIndex != toIndex {
            withAnimation {
                // 模拟移动：创建一个可变副本进行操作
                // 注意：实际上我们需要直接修改 Model 的 orderIndex 来触发更新
                var mutableItems = items
                let movedItem = mutableItems.remove(at: fromIndex)
                mutableItems.insert(movedItem, at: toIndex)
                
                // 重新分配 orderIndex
                for (index, todo) in mutableItems.enumerated() {
                    todo.orderIndex = index
                }
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

struct TargetDatePickerSheet: View {
    let item: TodoItemV3
    @Binding var targetDate: Date
    var onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with Cancel Button
            ZStack(alignment: .center) {
                Capsule()
                    .fill(DesignSystem.textSecondary.opacity(0.2))
                    .frame(width: 36, height: 4)
                
                HStack {
                    Spacer()
                    Button("cancel") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(DesignSystem.textSecondary)
                    .buttonStyle(.plain) // Ensure it looks clickable on Mac
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 20)
            
            Text("add_one_day")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.textPrimary)
            
            // 快捷选项
            HStack(spacing: 12) {
                Button(action: {
                    targetDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                }) {
                    Text("tomorrow")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(DesignSystem.textPrimary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignSystem.cardBorder, lineWidth: 1)
                        )
                }
                
                Button(action: {
                    // 下周一
                    let today = Date()
                    let calendar = Calendar.current
                    // 找到下个周一
                    // 1 = Sunday, 2 = Monday, ...
                    let weekday = calendar.component(.weekday, from: today)
                    var daysToAdd = 0
                    if weekday == 2 { // Today is Monday
                        daysToAdd = 7
                    } else {
                        // weekday: 1(Sun), 3(Tue), 4(Wed), 5(Thu), 6(Fri), 7(Sat)
                        // target: 2(Mon)
                        // if Sun(1) -> +1 -> Mon(2)
                        // if Tue(3) -> +6 -> Mon(2+7=9)
                        daysToAdd = (9 - weekday) % 7
                        if daysToAdd == 0 { daysToAdd = 7 }
                    }
                    
                    targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
                }) {
                    Text("next_monday")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(DesignSystem.textPrimary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignSystem.cardBorder, lineWidth: 1)
                        )
                }
            }
            
            DatePicker("", selection: $targetDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                .padding(.horizontal)

            Button(action: {
                onConfirm()
            }) {
                Text("confirm_continuation")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DesignSystem.checkedColor)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .background(DesignSystem.softBackground)
        .presentationDetents([.height(520)])
        .presentationCornerRadius(32)
    }
}

struct CardActionSheet: View {
    var onEdit: () -> Void
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            // 装饰性顶部横条
            Capsule()
                .fill(DesignSystem.textSecondary.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            Button(action: {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onEdit()
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.warmBackground)
                            .frame(width: 44, height: 44)
                        Image(systemName: "pencil")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(DesignSystem.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("edit_title")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(DesignSystem.textPrimary)
                        Text("enter_card_title")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignSystem.textTertiary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(DesignSystem.cardBackground)
                .cornerRadius(20)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button(action: {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onDelete()
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.08))
                            .frame(width: 44, height: 44)
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("delete_card", comment: "Delete card button"))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.red)
                        Text(NSLocalizedString("irreversible_action", comment: "Irreversible action warning"))
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(DesignSystem.cardBackground)
                .cornerRadius(20)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(DesignSystem.softBackground)
        .presentationDetents([.height(260)])
        .presentationCornerRadius(32)
    }
}

// 简单的按压缩放按钮样式
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct FloatingNewDayButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                .font(.system(size: 15, weight: .bold))
                Text("新的一天")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(DesignSystem.checkedColor)
            .clipShape(Capsule())
            .shadow(color: DesignSystem.checkedColor.opacity(0.3), radius: 12, x: 0, y: 6)
        }
    }
}

struct DayCardViewNew: View {
    @Environment(\.modelContext) private var modelContext
    var card: DailyCardV3
    @Binding var addingText: String
    var onAdd: (String) -> Void
    var onContinue: (TodoItemV3) -> Void
    var onEdit: (TodoItemV3) -> Void // 新增参数
    var onComplete: (CGPoint) -> Void // 新增完成回调，携带坐标
    @FocusState private var addingFieldFocused: Bool
    
    @State private var showActionMenu = false
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var draggingItem: TodoItemV3? // 追踪当前拖拽的项
    
    // 日期格式化器
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter
    }
    
    // 排序后的待办事项
    private var sortedItems: [TodoItemV3] {
        card.items.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 卡片头部日期
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let title = card.customTitle, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.textPrimary)
                    } else {
                        Text(dateFormatter.string(from: card.date))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.textPrimary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading) // 确保占满整行
            .background(DesignSystem.cardHeaderBackground)
            .contentShape(Rectangle()) // 确保整个区域可点击
            .onTapGesture {
                showActionMenu = true
            }
            .sheet(isPresented: $showActionMenu) {
                CardActionSheet(onEdit: {
                    showEditSheet = true
                }, onDelete: {
                    showDeleteAlert = true
                })
            }
            .sheet(isPresented: $showEditSheet) {
                CardTitleEditSheet(card: card)
            }
            .alert("删除卡片", isPresented: $showDeleteAlert) {
                Button("删除", role: .destructive) {
                    withAnimation {
                        modelContext.delete(card)
                    }
                    try? modelContext.save()
                    WidgetCenter.shared.reloadAllTimelines()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要删除这张卡片及其所有待办事项吗？此操作不可恢复。")
            }
            
            // 待办列表
            VStack(spacing: 0) {
                let items = sortedItems
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Rectangle()
                            .fill(DesignSystem.separatorColor)
                            .frame(height: 0.5)
                            .padding(.leading, 52) // 对齐文字
                    }
                    
                    TodoItemRowNew(item: item, onContinue: {
                        onContinue(item)
                    }, onEdit: {
                        onEdit(item)
                    }, onComplete: { point in
                        onComplete(point)
                    })
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.01)) // 增加背景以支持拖拽
                    .onDrag {
                        self.draggingItem = item
                        return NSItemProvider(object: item.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: TodoDropDelegate(item: item, items: items, draggingItem: draggingItem, onFinish: { draggingItem = nil }))
                }
                
                if !card.items.isEmpty {
                    Rectangle()
                        .fill(DesignSystem.separatorColor)
                        .frame(height: 0.5)
                        .padding(.leading, 52)
                }
                
                // 输入框区域
                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignSystem.textTertiary)
                        .frame(width: 24, height: 24)
                    
                    TextField(NSLocalizedString("add_new_task", comment: "Add new task placeholder"), text: $addingText)
                        .focused($addingFieldFocused)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(DesignSystem.textPrimary)
                        .onSubmit {
                            let t = addingText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            onAdd(t)
                            addingText = ""
                            addingFieldFocused = true
                            Haptics.light()
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(DesignSystem.cardBackground)
        .cornerRadius(DesignSystem.cardCorner)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cardCorner)
                .stroke(DesignSystem.cardBorder, lineWidth: 0.5)
        )
        // .shadow(color: DesignSystem.shadowColor, radius: DesignSystem.shadowRadius, x: 0, y: 8)
    }
}

struct TodoItemRowNew: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: TodoItemV3
    var onContinue: () -> Void
    var onEdit: () -> Void // 新增回调
    var onComplete: (CGPoint) -> Void // 新增完成回调
    @State private var checkboxFrame: CGRect = .zero // 存储复选框位置
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    item.isDone.toggle()
                    item.completedAt = item.isDone ? Date() : nil
                }
                if item.isDone {
                    // 使用存储的中心点作为爆发点
                    let centerPoint = CGPoint(x: checkboxFrame.midX, y: checkboxFrame.midY)
                    onComplete(centerPoint)
                }
                
                // 强制保存以确保 Widget 能读到最新数据
                try? modelContext.save()
                
                // 刷新 Widget
                WidgetCenter.shared.reloadAllTimelines()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(item.priority == .none ? (item.isDone ? DesignSystem.checkedColor : DesignSystem.textTertiary) : item.priority.color, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if item.isDone {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.priority == .none ? DesignSystem.checkedColor : item.priority.color)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    } else if item.priority != .none {
                         RoundedRectangle(cornerRadius: 6)
                            .fill(item.priority.color.opacity(0.1))
                            .frame(width: 22, height: 22)
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: geo.frame(in: .global)) { oldVal, newVal in
                                checkboxFrame = newVal
                            }
                            .onAppear {
                                checkboxFrame = geo.frame(in: .global)
                            }
                    }
                )
            }
            .buttonStyle(.plain)
            // .padding(.top, 3) // 移除顶部内边距，让复选框自然顶对齐
            
            if let idx = item.chainIndex {
                if idx >= 2 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(idx)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.top, 1) // 微调对齐
                }
            }
            
            Text(item.title)
                .font(.system(size: 16, weight: item.isDone ? .regular : .medium, design: .rounded))
                .strikethrough(item.isDone)
                .foregroundColor(item.isDone ? DesignSystem.textTertiary : DesignSystem.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 1) // 微调对齐，使其与复选框视觉居中
                .contentShape(Rectangle()) // 扩大点击区域
                .onTapGesture {
                    onEdit()
                }
            
            Spacer()
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation { modelContext.delete(item) }
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}
