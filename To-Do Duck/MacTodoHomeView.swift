import SwiftUI
import SwiftData
import WidgetKit

#if os(macOS)
private let macTodoConfettiCoordinateSpaceName = "MacTodoConfettiCoordinateSpace"

struct MacTodoHomeView: View {
    private let headerActionHeight: CGFloat = 42
    private let collectionBoxWidth: CGFloat = 320
    private let collectionBoxCollapsedOffset: CGFloat = 18
    private let collectionBoxAnimation: Animation = .spring(response: 0.44, dampingFraction: 0.88, blendDuration: 0.18)

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\DailyCardV3.date, order: .reverse), SortDescriptor(\DailyCardV3.createdAt, order: .reverse)]) private var cards: [DailyCardV3]
    @Query private var inboxItems: [TodoItemV3]
    @State private var addingTextByCard: [UUID: String] = [:]
    @State private var inboxInputText: String = ""
    @State private var targetDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var showPastDateAlert: Bool = false
    @AppStorage("allowPastContinuation") private var allowPastContinuation: Bool = false
    @AppStorage("macTodoCollectionBoxExpanded") private var isCollectionBoxExpanded: Bool = true
    @State private var confettiCounter: Int = 0
    @State private var confettiSourcePosition: CGPoint = .zero
    @State private var waveRotation: Double = 0

    init() {
        _inboxItems = Query(
            filter: #Predicate<TodoItemV3> { $0.card == nil },
            sort: [SortDescriptor(\TodoItemV3.orderIndex), SortDescriptor(\TodoItemV3.createdAt)]
        )
    }
    
    // Sheets management
    @State private var editingItem: TodoItemV3?
    @State private var showTargetPickerForItem: TodoItemV3?
    @State private var showRepeatSettingForItem: TodoItemV3? // 新增状态变量
    
    // Greeting Logic
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return NSLocalizedString("greeting_morning", comment: "Morning greeting")
        case 12..<18:
            return NSLocalizedString("greeting_afternoon", comment: "Afternoon greeting")
        default:
            return NSLocalizedString("greeting_evening", comment: "Evening greeting")
        }
    }

    private var inboxBadgeText: String {
        inboxItems.count > 99 ? "99+" : "\(inboxItems.count)"
    }
    
    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 20) {
                    // Header Area with Quick Actions
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("Hi")
                                HStack(spacing: 0) {
                                    Text("👋")
                                        .rotationEffect(.degrees(waveRotation), anchor: .bottomTrailing)
                                    Text(",")
                                }
                                Text(greeting + "～")
                            }
                            .font(.largeTitle)
                            .bold()
                            .task {
                                while !Task.isCancelled {
                                    // Waving sequence: 3 fast waves
                                    for _ in 0..<3 {
                                        withAnimation(.easeInOut(duration: 0.15)) { waveRotation = 15 }
                                        try? await Task.sleep(nanoseconds: 150_000_000)
                                        withAnimation(.easeInOut(duration: 0.15)) { waveRotation = -5 }
                                        try? await Task.sleep(nanoseconds: 150_000_000)
                                    }
                                    
                                    // Reset to neutral position
                                    withAnimation(.spring()) { waveRotation = 0 }
                                    
                                    // Pause for 2 seconds
                                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                                }
                            }
                            
                            Text(Date(), format: .dateTime.year().month().day().weekday(.wide))
                                .font(.headline)
                                .bold()
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 10) {
                            Button(action: {
                                withAnimation { createTodayCard() }
                            }) {
                                Label("new_day", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 18)
                                    .frame(height: headerActionHeight)
                                    .background(DesignSystem.primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                withAnimation(collectionBoxAnimation) {
                                    isCollectionBoxExpanded.toggle()
                                }
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: isCollectionBoxExpanded ? "sidebar.right" : "tray.full")
                                        .font(.system(size: 15, weight: .semibold))
                                        .frame(width: 20, height: 20)
                                        .foregroundStyle(DesignSystem.textPrimary)
                                        .padding(.horizontal, 16)
                                        .frame(height: headerActionHeight)
                                        .background(
                                            DesignSystem.surfaceContainerHigh
                                                .opacity(isCollectionBoxExpanded ? 1 : 0.82)
                                        )
                                        .clipShape(Capsule())

                                    if !inboxItems.isEmpty {
                                        Text(inboxBadgeText)
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .frame(height: 18)
                                            .background(DesignSystem.primary)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(DesignSystem.background, lineWidth: 1)
                                            )
                                            .offset(x: 8, y: -4)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .help(isCollectionBoxExpanded ? "收起收集箱" : "展开收集箱")
                        }
                    }
                    .padding(.top, 20)
                    
                    if cards.isEmpty {
                        ContentUnavailableView {
                            Label("todo_list_empty", systemImage: "moon.zzz.fill")
                        } description: {
                            Text("create_today_hint")
                        } actions: {
                            Button("create_today") {
                                withAnimation { createTodayCard() }
                            }
                        }
                        .padding(.top, 50)
                    } else {
                        // Cards List Layout for Mac (Single Column)
                        LazyVStack(spacing: 20) {
                            ForEach(cards) { card in
                                MacDayCardView(
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
                                        editingItem = item
                                    },
                                    onDelete: { item in
                                        delete(item)
                                    },
                                    onRepeat: { item in
                                        showRepeatSettingForItem = item
                                    },
                                    onComplete: { sourcePoint in
                                        confettiSourcePosition = sourcePoint
                                        confettiCounter += 1
                                    }
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: isCollectionBoxExpanded ? 650 : 760)
                
                MacCollectionBoxView(
                    items: inboxItems,
                    inputText: $inboxInputText,
                    onAdd: { text in
                        withAnimation {
                            addInboxItem(text: text)
                        }
                    },
                    onEdit: { item in
                        editingItem = item
                    },
                    onDelete: { item in
                        delete(item)
                    },
                    onComplete: { sourcePoint in
                        confettiSourcePosition = sourcePoint
                        confettiCounter += 1
                    },
                    onDropToInbox: { itemIDs in
                        TodoDropCoordinator.moveItemsToInbox(itemIDs: itemIDs, context: modelContext)
                    },
                    onDropBeforeItem: { itemIDs, destination in
                        TodoDropCoordinator.moveItemsToInbox(itemIDs: itemIDs, context: modelContext, before: destination)
                    }
                )
                .frame(width: collectionBoxWidth)
                .opacity(isCollectionBoxExpanded ? 1 : 0)
                .offset(x: isCollectionBoxExpanded ? 0 : collectionBoxCollapsedOffset)
                .scaleEffect(
                    x: isCollectionBoxExpanded ? 1 : 0.96,
                    y: isCollectionBoxExpanded ? 1 : 0.98,
                    anchor: .trailing
                )
                .frame(width: isCollectionBoxExpanded ? collectionBoxWidth : 0, alignment: .trailing)
                .clipped()
                .allowsHitTesting(isCollectionBoxExpanded)
                .accessibilityHidden(!isCollectionBoxExpanded)
            }
            .frame(maxWidth: 1040, alignment: .top)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .thinScrollbar()
            .animation(collectionBoxAnimation, value: isCollectionBoxExpanded)
        }
        .background(DesignSystem.background) // Keep consistent background
        .overlay(
            ConfettiView(counter: $confettiCounter, burstPosition: confettiSourcePosition)
                .allowsHitTesting(false)
        )
        .coordinateSpace(name: macTodoConfettiCoordinateSpaceName)
        .sheet(item: $editingItem) { item in
            TodoEditSheet(item: item)
        }
        .sheet(item: $showTargetPickerForItem) { item in
            TargetDatePickerSheet(item: item, targetDate: $targetDate) {
                let baseDate = item.card?.date ?? Calendar.current.startOfDay(for: item.createdAt)
                if !allowPastContinuation && Calendar.current.startOfDay(for: targetDate) < baseDate {
                    showPastDateAlert = true
                } else {
                    withAnimation { try? ContinuationService.continueItem(item, to: targetDate, context: modelContext) }
                    showTargetPickerForItem = nil
                }
            }
        }
        .sheet(item: $showRepeatSettingForItem) { item in
            RepeatSettingSheet(item: item)
        }
        .alert("cannot_select_past_date", isPresented: $showPastDateAlert) {
            Button("ok", role: .cancel) {}
        } message: {
            Text("select_future_date_message")
        }
    }
    
    // MARK: - Logic Copied from TodoHomeView
    
    private func createTodayCard() {
        let calendar = Calendar.current
        let targetDate = DailyCardDatePlanner.targetDate(
            latestCardDate: cards.first?.date,
            today: Date(),
            calendar: calendar
        )
        
        guard cards.first != nil else {
            let card = DailyCardV3(date: targetDate)
            modelContext.insert(card)
            checkAndAddRepeatTasks(to: card)
            try? modelContext.save()
            return
        }
        
        let existingCard = cards.first { calendar.isDate($0.date, inSameDayAs: targetDate) }
        if existingCard != nil { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = NSLocalizedString("card_date_format", comment: "Date format for card title")
        let defaultDateTitle = formatter.string(from: targetDate)
        
        var titleToUse: String? = nil
        let existingTitles = Set(cards.filter { calendar.isDate($0.date, inSameDayAs: targetDate) }.map { $0.customTitle ?? defaultDateTitle })
        
        if existingTitles.contains(defaultDateTitle) {
            var counter = 1
            var candidate = "\(defaultDateTitle) (\(counter))"
            while existingTitles.contains(candidate) {
                counter += 1
                candidate = "\(defaultDateTitle) (\(counter))"
            }
            titleToUse = candidate
        }
        
        let card = DailyCardV3(date: targetDate)
        card.customTitle = titleToUse
        modelContext.insert(card)
        
        checkAndAddRepeatTasks(to: card)
        
        try? modelContext.save()
    }
    
    private func checkAndAddRepeatTasks(to card: DailyCardV3) {
        let targetDate = card.date
        
        // 使用 FetchDescriptor 确保获取最新数据，避免 @Query 延迟
        let descriptor = FetchDescriptor<RepeatRule>()
        let rules = (try? modelContext.fetch(descriptor)) ?? []
        
        for rule in rules {
            // 检查日期范围 (比较日期部分)
            let startDate = Calendar.current.startOfDay(for: rule.startDate)
            let endDate = Calendar.current.startOfDay(for: rule.endDate)
            
            // 宽松比较：只要 targetDate 在 startDate 和 endDate 之间（含）
            // 注意：targetDate 已经是 startOfDay 处理过的
            if targetDate >= startDate && targetDate <= endDate {
                // 检查卡片中是否已存在由该规则生成的任务
                // 此时 card.items 可能还未加载完全，尝试从 context 中查询
                // 或者信任 card.items (通常 insert 后是空的)
                let alreadyExists = card.items?.contains(where: { $0.fromRepeatRuleId == rule.id }) ?? false
                
                if !alreadyExists {
                    let newItem = TodoItemV3(title: rule.title, card: card)
                    newItem.fromRepeatRuleId = rule.id
                    // 设置顺序：添加到末尾
                    let maxOrder = card.items?.map { $0.orderIndex }.max() ?? -1
                    newItem.orderIndex = maxOrder + 1
                    
                    modelContext.insert(newItem)
                }
            }
        }
    }
    
    private func addItem(text: String, to card: DailyCardV3) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let maxOrder = card.items?.map { $0.orderIndex }.max() ?? -1
        let item = TodoItemV3(title: t, card: card)
        item.orderIndex = maxOrder + 1
        modelContext.insert(item)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func addInboxItem(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let nextOrder = (inboxItems.map(\.orderIndex).max() ?? -1) + 1
        let item = TodoItemV3(title: trimmed, card: nil)
        item.orderIndex = nextOrder
        modelContext.insert(item)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func delete(_ item: TodoItemV3) {
        withAnimation {
            let sourceCard = item.card
            modelContext.delete(item)
            if let sourceCard {
                TodoDropCoordinator.normalizeCardItems(sourceCard)
            }
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

enum TodoDropCoordinator {
    static func moveItemsToCard(itemIDs: [String], to card: DailyCardV3) -> Bool {
        guard let itemToMove = firstItem(from: itemIDs, context: card.modelContext) else { return false }
        let sourceCard = itemToMove.card
        
        if sourceCard?.id == card.id {
            return false
        }
        
        itemToMove.card = card
        var destinationItems = (card.items ?? []).sorted { $0.orderIndex < $1.orderIndex }
        destinationItems.removeAll { $0.id == itemToMove.id }
        destinationItems.append(itemToMove)
        normalize(items: destinationItems)
        
        if let sourceCard, sourceCard.id != card.id {
            normalizeCardItems(sourceCard)
        }
        
        return save(context: card.modelContext)
    }
    
    static func moveItemsToCard(itemIDs: [String], before destinationItem: TodoItemV3, in card: DailyCardV3) -> Bool {
        guard let itemToMove = firstItem(from: itemIDs, context: destinationItem.modelContext) else { return false }
        guard itemToMove.id != destinationItem.id else { return false }
        
        let sourceCard = itemToMove.card
        var destinationItems = (card.items ?? []).sorted { $0.orderIndex < $1.orderIndex }
        destinationItems.removeAll { $0.id == itemToMove.id }
        
        itemToMove.card = card
        if let destinationIndex = destinationItems.firstIndex(where: { $0.id == destinationItem.id }) {
            destinationItems.insert(itemToMove, at: destinationIndex)
        } else {
            destinationItems.append(itemToMove)
        }
        normalize(items: destinationItems)
        
        if let sourceCard, sourceCard.id != card.id {
            normalizeCardItems(sourceCard)
        }
        
        return save(context: destinationItem.modelContext)
    }
    
    static func moveItemsToInbox(itemIDs: [String], context: ModelContext, before destinationItem: TodoItemV3? = nil) -> Bool {
        guard let itemToMove = firstItem(from: itemIDs, context: context) else { return false }
        guard itemToMove.id != destinationItem?.id else { return false }
        
        let sourceCard = itemToMove.card
        var inboxItems = fetchInboxItems(context: context)
        inboxItems.removeAll { $0.id == itemToMove.id }
        
        itemToMove.card = nil
        if let destinationItem, let destinationIndex = inboxItems.firstIndex(where: { $0.id == destinationItem.id }) {
            inboxItems.insert(itemToMove, at: destinationIndex)
        } else {
            inboxItems.append(itemToMove)
        }
        normalize(items: inboxItems)
        
        if let sourceCard {
            normalizeCardItems(sourceCard)
        }
        
        return save(context: context)
    }
    
    static func normalizeCardItems(_ card: DailyCardV3) {
        let orderedItems = (card.items ?? []).sorted { $0.orderIndex < $1.orderIndex }
        normalize(items: orderedItems)
    }
    
    private static func firstItem(from itemIDs: [String], context: ModelContext?) -> TodoItemV3? {
        guard
            let context,
            let itemIdString = itemIDs.first,
            let itemId = UUID(uuidString: itemIdString)
        else {
            return nil
        }
        
        let descriptor = FetchDescriptor<TodoItemV3>(predicate: #Predicate { $0.id == itemId })
        return try? context.fetch(descriptor).first
    }
    
    private static func fetchInboxItems(context: ModelContext) -> [TodoItemV3] {
        let descriptor = FetchDescriptor<TodoItemV3>(
            predicate: #Predicate { $0.card == nil },
            sortBy: [SortDescriptor(\TodoItemV3.orderIndex), SortDescriptor(\TodoItemV3.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    private static func normalize(items: [TodoItemV3]) {
        for (index, item) in items.enumerated() {
            item.orderIndex = index
        }
    }
    
    private static func save(context: ModelContext?) -> Bool {
        guard let context else { return false }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }
}

struct TodoDragHandleButton: View {
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? DesignSystem.textSecondary.opacity(0.2) : Color.clear)
                .frame(width: 28, height: 28)
            
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Circle().frame(width: 3, height: 3)
                    Circle().frame(width: 3, height: 3)
                    Circle().frame(width: 3, height: 3)
                }
                HStack(spacing: 2) {
                    Circle().frame(width: 3, height: 3)
                    Circle().frame(width: 3, height: 3)
                    Circle().frame(width: 3, height: 3)
                }
            }
            .foregroundColor(isHovering ? DesignSystem.textSecondary : DesignSystem.textTertiary)
        }
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
        .help("drag_to_reorder")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Mac Specific Subviews

struct MacCollectionBoxView: View {
    let items: [TodoItemV3]
    @Binding var inputText: String
    var onAdd: (String) -> Void
    var onEdit: (TodoItemV3) -> Void
    var onDelete: (TodoItemV3) -> Void
    var onComplete: (CGPoint) -> Void
    var onDropToInbox: ([String]) -> Bool
    var onDropBeforeItem: ([String], TodoItemV3) -> Bool
    
    @FocusState private var isInputFocused: Bool
    @State private var isDropTargeted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("收集箱", systemImage: "tray.full.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.textPrimary)
                    
                    Text("还没定好时间的事情放这里")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(DesignSystem.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 12)
                
                Text("\(items.count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignSystem.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignSystem.primary.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(DesignSystem.cardHeaderBackground)
            
            VStack(spacing: 0) {
                if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(DesignSystem.textTertiary)
                        
                        Text("把待办拖到这里暂存")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.textPrimary)
                        
                        Text("也可以直接输入一个还没安排日期的待办。")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            if index > 0 {
                                Rectangle()
                                    .fill(DesignSystem.separatorColor)
                                    .frame(height: 0.5)
                                    .padding(.leading, 52)
                            }
                            
                            MacTodoItemView(
                                item: item,
                                showsContinueAction: false,
                                showsRepeatAction: false,
                                onToggle: { point in
                                    if item.isDone {
                                        onComplete(point)
                                    }
                                },
                                onContinue: {},
                                onEdit: { onEdit(item) },
                                onDelete: { onDelete(item) },
                                onRepeat: {},
                                onDrop: { itemIDs in
                                    onDropBeforeItem(itemIDs, item)
                                }
                            )
                        }
                    }
                }
                
                Rectangle()
                    .fill(DesignSystem.separatorColor)
                    .frame(height: 0.5)
                    .padding(.leading, 52)
                
                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignSystem.textTertiary)
                        .frame(width: 24, height: 24)
                    
                    TextField("输入后回车↩︎", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(DesignSystem.textPrimary)
                        .focused($isInputFocused)
                        .onSubmit {
                            if !inputText.isEmpty {
                                onAdd(inputText)
                                inputText = ""
                                isInputFocused = true
                            }
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
                .stroke(isDropTargeted ? Color.accentColor : DesignSystem.cardBorder, lineWidth: isDropTargeted ? 2 : 0.5)
        )
        .shadow(color: DesignSystem.shadowColor.opacity(0.6), radius: 14, x: 0, y: 6)
        .dropDestination(for: String.self) { itemIDs, _ in
            onDropToInbox(itemIDs)
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDropTargeted = targeted
            }
        }
    }
}

struct MacDayCardView: View {
    @Bindable var card: DailyCardV3
    @Binding var addingText: String
    var onAdd: (String) -> Void
    var onContinue: (TodoItemV3) -> Void
    var onEdit: (TodoItemV3) -> Void
    var onDelete: (TodoItemV3) -> Void
    var onRepeat: (TodoItemV3) -> Void
    var onComplete: (CGPoint) -> Void
    
    @FocusState private var isInputFocused: Bool
    @State private var isDropTargeted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.displayTitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.textPrimary)
                }
                
                Spacer()
                
                // Mac style delete button for card
                Menu {
                    Button(role: .destructive) {
                        if let context = card.modelContext {
                            withAnimation {
                                context.delete(card)
                                try? context.save()
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    } label: {
                        Label("delete_card", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium)) // 稍微调整大小以匹配
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden) // Hide the dropdown arrow
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(DesignSystem.cardHeaderBackground)
            
            // Items List
            VStack(spacing: 0) {
                let sortedItems = (card.items ?? []).sorted { $0.orderIndex < $1.orderIndex }
                
                VStack(spacing: 0) {
                    ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            if index > 0 {
                                Rectangle()
                                    .fill(DesignSystem.separatorColor)
                                    .frame(height: 0.5)
                                    .padding(.leading, 52)
                            }
                            
                            MacTodoItemView(item: item, onToggle: { point in
                                if item.isDone {
                                    onComplete(point)
                                }
                            }, onContinue: { onContinue(item) }, onEdit: { onEdit(item) }, onDelete: { onDelete(item) }, onRepeat: { onRepeat(item) }, onDrop: { items in
                                return performMove(itemIDs: items, to: item)
                            })
                        }
                    }
                }
                
                if !(card.items?.isEmpty ?? true) {
                    Rectangle()
                        .fill(DesignSystem.separatorColor)
                        .frame(height: 0.5)
                        .padding(.leading, 52)
                }
                
                // Input Area
                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignSystem.textTertiary)
                        .frame(width: 24, height: 24)
                    
                    TextField("add_new_task", text: $addingText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(DesignSystem.textPrimary)
                        .focused($isInputFocused)
                        .onSubmit {
                            if !addingText.isEmpty {
                                onAdd(addingText)
                                addingText = ""
                                isInputFocused = true
                            }
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
        .dropDestination(for: String.self) { items, location in
            return performMoveToCard(itemIDs: items)
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDropTargeted = targeted
            }
        }
        .overlay(
            Group {
                if isDropTargeted {
                    RoundedRectangle(cornerRadius: DesignSystem.cardCorner)
                        .stroke(Color.accentColor, lineWidth: 2)
                }
            }
        )
    }
    
    // MARK: - Helper Methods
    
    private func performMoveToCard(itemIDs: [String]) -> Bool {
        withAnimation {
            TodoDropCoordinator.moveItemsToCard(itemIDs: itemIDs, to: card)
        }
    }
    

    private func performMove(itemIDs: [String], to destinationItem: TodoItemV3) -> Bool {
        withAnimation {
            TodoDropCoordinator.moveItemsToCard(itemIDs: itemIDs, before: destinationItem, in: card)
        }
    }
}

struct MacTodoItemView: View {
    let item: TodoItemV3
    var showsContinueAction: Bool = true
    var showsRepeatAction: Bool = true
    var onToggle: (CGPoint) -> Void
    var onContinue: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onRepeat: () -> Void
    var onDrop: ([String]) -> Bool
    
    @State private var isHovering = false
    @State private var isDropTargeted = false
    @State private var checkboxFrame: CGRect = .zero

    private var priorityColor: Color {
        item.priority == .none ? DesignSystem.outline : item.priority.color
    }

    private var continueButtonHelp: LocalizedStringKey {
        if item.progress > 0 && item.progress < 100 {
            return "continue_tomorrow_with_progress \(item.progress)"
        }
        return "continue_tomorrow"
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            item.progress = item.isDone ? 0 : 100
        }
        if item.isDone {
            let centerPoint = CGPoint(x: checkboxFrame.midX, y: checkboxFrame.midY)
            onToggle(centerPoint)
        }
        try? item.modelContext?.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 环形进度圈
            // 单击：直接完成/取消完成 (0 <-> 100)
            // 双击：打开编辑面板精确设置进度
            ProgressRing(progress: item.progress, color: priorityColor)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: geo.frame(in: .named(macTodoConfettiCoordinateSpaceName))) { oldVal, newVal in
                                checkboxFrame = newVal
                            }
                            .onAppear {
                                checkboxFrame = geo.frame(in: .named(macTodoConfettiCoordinateSpaceName))
                            }
                    }
                )
                .overlay {
                    Button(action: toggleCompletion) {
                        Color.clear
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

            // 任务内容区
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    // 火焰标记（延续次数）
                    if let idx = item.chainIndex, idx >= 2 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(idx)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DesignSystem.tertiaryContainer)
                        .foregroundColor(DesignSystem.tertiary)
                        .clipShape(Capsule())
                    }

                    Text(item.title)
                        .font(.system(size: 15, weight: item.isDone ? .regular : .medium, design: .rounded))
                        .strikethrough(item.isDone)
                        .foregroundColor(item.isDone ? DesignSystem.textTertiary : DesignSystem.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            onEdit()
                        }
                }


            }

            // 提示该任务是重复生成的
            if item.fromRepeatRuleId != nil {
                Image(systemName: "repeat")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.textTertiary)
                    .help("repeat_task_indicator")
            }
        }
        .overlay(alignment: .trailing) {
            if isHovering {
                HStack(spacing: 4) {
                    if showsRepeatAction {
                        TodoActionButton(
                            icon: "repeat",
                            color: item.fromRepeatRuleId != nil ? DesignSystem.primary : DesignSystem.textSecondary,
                            help: "repeat_task_setting",
                            action: onRepeat
                        )
                    }

                    if showsContinueAction {
                        TodoActionButton(
                            icon: "arrow.right.to.line",
                            color: DesignSystem.textPrimary,
                            help: continueButtonHelp,
                            action: onContinue
                        )
                    }

                    TodoActionButton(
                        icon: "square.and.pencil",
                        color: DesignSystem.textPrimary,
                        action: onEdit
                    )

                    TodoActionButton(
                        icon: "trash",
                        color: .red,
                        action: onDelete
                    )

                    TodoDragHandleButton()
                        .draggable(item.id.uuidString)
                }
                .padding(2)
                .background(DesignSystem.cardBackground)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            ZStack {
                if isHovering {
                    Color.black.opacity(0.04)
                }

                if isDropTargeted {
                    Color.accentColor.opacity(0.1)

                    VStack {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(height: 2)
                        Spacer()
                    }
                } else {
                    Color.white.opacity(0.001)
                }
            }
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .dropDestination(for: String.self) { items, location in
            onDrop(items)
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDropTargeted = targeted
            }
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("edit", systemImage: "pencil")
            }
            Button(action: onContinue) {
                Label("add_one_day", systemImage: "arrow.right.to.line")
            }
            Button(role: .destructive, action: onDelete) {
                Label("delete", systemImage: "trash")
            }
        }
    }
}

private enum MacDailyCardTitleFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        let format = NSLocalizedString("card_date_format", comment: "Date format")
        formatter.dateFormat = format != "card_date_format" ? format : "MMM d, EEEE"
        return formatter
    }()
}

extension DailyCardV3 {
    var displayTitle: String {
        if let custom = customTitle, !custom.isEmpty {
            return custom
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cardDay = calendar.startOfDay(for: date)

        if cardDay == today {
            return "今天"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today), cardDay == tomorrow {
            return "明天"
        }

        if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today), cardDay == dayAfterTomorrow {
            return "后天"
        }

        return MacDailyCardTitleFormatter.shared.string(from: date)
    }
}
#endif

struct TodoActionButton: View {
    let icon: String
    let color: Color
    let helpText: LocalizedStringKey?
    let action: () -> Void
    
    @State private var isHovering = false
    
    init(icon: String, color: Color = DesignSystem.textSecondary, help: LocalizedStringKey? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.color = color
        self.helpText = help
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? color.opacity(0.2) : Color.clear) // Increased opacity for darker header
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isHovering ? color : DesignSystem.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .if(helpText != nil) { view in
            view.help(helpText!)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
