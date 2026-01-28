import SwiftUI
import SwiftData
import WidgetKit

#if os(macOS)
struct MacTodoHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\DailyCardV3.date, order: .reverse), SortDescriptor(\DailyCardV3.createdAt, order: .reverse)]) private var cards: [DailyCardV3]
    @State private var addingTextByCard: [UUID: String] = [:]
    @State private var targetDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var showPastDateAlert: Bool = false
    @AppStorage("allowPastContinuation") private var allowPastContinuation: Bool = false
    @State private var confettiCounter: Int = 0
    @State private var confettiSourcePosition: CGPoint = .zero
    @State private var waveRotation: Double = 0
    
    // Sheets management
    @State private var editingItem: TodoItemV3?
    @State private var showTargetPickerForItem: TodoItemV3?
    
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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
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
                        
                        Button(action: {
                            withAnimation { createTodayCard() }
                        }) {
                            Label("new_day", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DesignSystem.checkedColor)
                        .controlSize(.large)
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
                                        withAnimation {
                                            modelContext.delete(item)
                                            try? modelContext.save()
                                            WidgetCenter.shared.reloadAllTimelines()
                                        }
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
                .frame(maxWidth: 650)
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .background(DesignSystem.warmBackground) // Keep consistent background
        .overlay(
            ConfettiView(counter: $confettiCounter, burstPosition: confettiSourcePosition)
                .allowsHitTesting(false)
        )
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
        .alert("cannot_select_past_date", isPresented: $showPastDateAlert) {
            Button("ok", role: .cancel) {}
        } message: {
            Text("select_future_date_message")
        }
    }
    
    // MARK: - Logic Copied from TodoHomeView
    
    private func createTodayCard() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayCards = cards.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        
        let formatter = DateFormatter()
        formatter.dateFormat = NSLocalizedString("card_date_format", comment: "Date format for card title")
        let defaultDateTitle = formatter.string(from: today)
        
        var titleToUse: String? = nil
        let existingTitles = Set(todayCards.map { $0.customTitle ?? defaultDateTitle })
        
        if existingTitles.contains(defaultDateTitle) {
            var counter = 1
            var candidate = "\(defaultDateTitle) (\(counter))"
            while existingTitles.contains(candidate) {
                counter += 1
                candidate = "\(defaultDateTitle) (\(counter))"
            }
            titleToUse = candidate
        }
        
        let card = DailyCardV3(date: today)
        card.customTitle = titleToUse
        modelContext.insert(card)
    }
    
    private func addItem(text: String, to card: DailyCardV3) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let maxOrder = card.items.map { $0.orderIndex }.max() ?? -1
        let item = TodoItemV3(title: t, card: card)
        item.orderIndex = maxOrder + 1
        modelContext.insert(item)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Mac Specific Subviews

struct MacDayCardView: View {
    @Bindable var card: DailyCardV3
    @Binding var addingText: String
    var onAdd: (String) -> Void
    var onContinue: (TodoItemV3) -> Void
    var onEdit: (TodoItemV3) -> Void
    var onDelete: (TodoItemV3) -> Void
    var onComplete: (CGPoint) -> Void
    
    @FocusState private var isInputFocused: Bool
    
    // 日期格式化器
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
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
                
                // Mac style delete button for card
                Menu {
                    Button(role: .destructive) {
                         // Need delete card callback or use modelContext directly if passed
                         // But here we don't have modelContext easily accessible unless passed or environment
                         // Assuming card deletion is handled outside or we add it
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
                ForEach(Array(card.items.sorted { $0.orderIndex < $1.orderIndex }.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Rectangle()
                            .fill(DesignSystem.separatorColor)
                            .frame(height: 0.5)
                            .padding(.leading, 52)
                    }
                    
                    MacTodoItemView(item: item, onToggle: { point in
                 withAnimation {
                     item.isDone.toggle()
                     item.completedAt = item.isDone ? Date() : nil
                     try? item.modelContext?.save()
                     WidgetCenter.shared.reloadAllTimelines()
                     
                     if item.isDone {
                         onComplete(point)
                     }
                 }
            }, onContinue: { onContinue(item) }, onEdit: { onEdit(item) }, onDelete: { onDelete(item) })
                }
                
                if !card.items.isEmpty {
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
    }
}

struct MacTodoItemView: View {
    let item: TodoItemV3
    var onToggle: (CGPoint) -> Void
    var onContinue: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    @State private var isHovering = false
    @State private var checkboxFrame: CGRect = .zero
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                // Calculate center point in global coordinates for confetti
                let centerPoint = CGPoint(x: checkboxFrame.midX, y: checkboxFrame.midY)
                onToggle(centerPoint)
            }) {
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
                    .padding(.top, 1)
                }
            }
            
            Text(item.title)
                .font(.system(size: 16, weight: item.isDone ? .regular : .medium, design: .rounded))
                .strikethrough(item.isDone)
                .foregroundColor(item.isDone ? DesignSystem.textTertiary : DesignSystem.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 1)
                .contentShape(Rectangle())
                .onTapGesture {
                    onEdit()
                }
            
            // Hover actions for Mac
            if isHovering {
                HStack(spacing: 12) {
                    if !item.isDone {
                        Button(action: onContinue) {
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .help("continue_tomorrow")
                    }
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("delete", systemImage: "trash")
            }
        }
    }
}

extension DailyCardV3 {
    var displayTitle: String {
        if let custom = customTitle, !custom.isEmpty {
            return custom
        }
        let formatter = DateFormatter()
        let format = NSLocalizedString("card_date_format", comment: "Date format")
        // Check if localization key exists/returned self, fallback if needed
        formatter.dateFormat = format != "card_date_format" ? format : "MMM d, EEEE"
        return formatter.string(from: date)
    }
}
#endif
