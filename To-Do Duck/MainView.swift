import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import WidgetKit
#if os(macOS)
import AppKit
#endif

struct MainView: View {
    @Environment(\.scenePhase) private var scenePhase

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
        .accentColor(DesignSystem.primary) // 使用主题色
        #else
        MacAppView()
        #endif
    }
}

struct TodoEditSheet: View {
    @Bindable var item: TodoItemV3
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var editingTitle: String = ""
    @State private var editingProgress: Int = 0
    @State private var editingPriority: TodoPriority = .none

    private var priorityColor: Color {
        editingPriority == .none ? DesignSystem.outline : editingPriority.color
    }

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

            // 任务内容输入框 - 带背景卡片，无滚动条
            VStack(alignment: .leading, spacing: 6) {
                Text("任务内容")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(DesignSystem.textSecondary)

                TodoEditTitleEditor(text: $editingTitle, isFocused: $isFocused)
                    .frame(minHeight: 60, maxHeight: 100)
                    .padding(.horizontal, -4)
            }
            .padding(12)
            .background(DesignSystem.surfaceContainerLowest)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignSystem.outlineVariant.opacity(0.5), lineWidth: 1)
            )

            // 优先级和进度 - 合并到一个卡片
            VStack(alignment: .leading, spacing: 16) {
                // 优先级选择
                HStack(spacing: 12) {
                    Text("优先级")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(DesignSystem.textSecondary)
                        .frame(width: 50, alignment: .leading)

                    HStack(spacing: 6) {
                        ForEach(TodoPriority.allCases, id: \.self) { priority in
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    editingPriority = priority
                                }
                            }) {
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(priority == .none ? DesignSystem.outline : priority.color)
                                        .frame(width: 6, height: 6)

                                    Text(priority.label)
                                        .font(.system(size: 12, weight: editingPriority == priority ? .semibold : .medium, design: .rounded))
                                        .foregroundColor(editingPriority == priority ? DesignSystem.textPrimary : DesignSystem.textSecondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(editingPriority == priority ? (priority == .none ? DesignSystem.outline.opacity(0.15) : priority.color.opacity(0.15)) : DesignSystem.surfaceContainerHighest)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()
                    .background(DesignSystem.separatorColor)

                // 进度调节
                HStack(spacing: 12) {
                    Text("进度")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(DesignSystem.textSecondary)
                        .frame(width: 50, alignment: .leading)

                    CompactProgressSliderInline(progress: $editingProgress, color: priorityColor)
                }
            }
            .padding(12)
            .background(DesignSystem.surfaceContainerLowest)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignSystem.outlineVariant.opacity(0.5), lineWidth: 1)
            )

            Spacer()
        }
        .padding(20)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
        .onAppear {
            editingTitle = item.title
            editingProgress = item.progress
            editingPriority = item.priority
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .presentationDetents([.height(340)])
        .presentationCornerRadius(24)
    }

    private func saveAndDismiss() {
        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            item.title = trimmed
        }
        item.priority = editingPriority
        item.progress = editingProgress
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

private struct TodoEditTitleEditor: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        #if os(macOS)
        MacTodoEditTitleTextView(text: $text, isFocused: isFocused)
        #else
        TextEditor(text: $text)
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .focused(isFocused)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        #endif
    }
}

#if os(macOS)
private struct MacTodoEditTitleTextView: NSViewRepresentable {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.verticalScroller = nil

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.allowsUndo = true
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = NSSize(width: 0, height: 2)
        textView.textColor = .labelColor
        textView.insertionPointColor = NSColor(hex: "0c6d45")
        textView.font = Self.editorFont
        textView.string = text

        scrollView.documentView = textView
        context.coordinator.textView = textView

        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
            isFocused.wrappedValue = true
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        scrollView.hasVerticalScroller = false
        scrollView.verticalScroller = nil

        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            textView.string = text
        }

        if textView.font != Self.editorFont {
            textView.font = Self.editorFont
        }

        DispatchQueue.main.async {
            if isFocused.wrappedValue {
                textView.window?.makeFirstResponder(textView)
            } else if textView.window?.firstResponder === textView {
                textView.window?.makeFirstResponder(nil)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    private static var editorFont: NSFont {
        if let descriptor = NSFont.systemFont(ofSize: 16).fontDescriptor.withDesign(.rounded) {
            return NSFont(descriptor: descriptor, size: 16) ?? .systemFont(ofSize: 16)
        }
        return .systemFont(ofSize: 16)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        weak var textView: NSTextView?

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

// MARK: - 紧凑进度滑轨（用于编辑面板）
struct CompactProgressSlider: View {
    @Binding var progress: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            GeometryReader { geo in
                let trackWidth = geo.size.width
                let fillWidth = max(0, min(CGFloat(progress) / 100.0 * trackWidth, trackWidth))
                let thumbX = max(0, min(fillWidth, trackWidth))

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignSystem.surfaceContainerHighest)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: fillWidth, height: 6)

                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        .offset(x: thumbX - 8)
                }
                .frame(height: 16)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let raw = Int((value.location.x / trackWidth) * 100)
                            let newValue = min(max(raw, 0), 100)
                            if newValue != progress {
                                progress = newValue
                            }
                        }
                )
            }
            .frame(height: 16)

            Text("\(progress)%")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(12)
        .background(DesignSystem.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - 内联进度滑轨（用于编辑面板，无背景）
struct CompactProgressSliderInline: View {
    @Binding var progress: Int
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            GeometryReader { geo in
                let trackWidth = geo.size.width
                let fillWidth = max(0, min(CGFloat(progress) / 100.0 * trackWidth, trackWidth))
                let thumbX = max(0, min(fillWidth, trackWidth))

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignSystem.surfaceContainerHighest)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: fillWidth, height: 6)

                    Circle()
                        .fill(.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        .offset(x: thumbX - 7)
                }
                .frame(height: 14)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let raw = Int((value.location.x / trackWidth) * 100)
                            let newValue = min(max(raw, 0), 100)
                            if newValue != progress {
                                progress = newValue
                            }
                        }
                )
            }
            .frame(height: 14)

            Text("\(progress)%")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

struct TodoActionSheet: View {
    let item: TodoItemV3
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onContinue: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var draftProgress: Int = 0

    // 获取明天的日期信息
    private var tomorrowInfo: (day: String, month: String) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        return (dayFormatter.string(from: tomorrow), monthFormatter.string(from: tomorrow))
    }

    private var priorityColor: Color {
        item.priority == .none ? DesignSystem.outline : item.priority.color
    }

    private var continueButtonTitle: String {
        let addOneDay = NSLocalizedString("add_one_day", comment: "")
        if draftProgress > 0 && draftProgress < 100 {
            if Locale.preferredLanguages.first?.hasPrefix("zh") == true {
                return "\(addOneDay) · 已做 \(draftProgress)%"
            } else {
                return "\(addOneDay) · \(draftProgress)% done"
            }
        }
        return addOneDay
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
                        try? modelContext.save()
                        WidgetCenter.shared.reloadAllTimelines()
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(priority == .none ? DesignSystem.outline : priority.color, lineWidth: 2)
                                    .frame(width: 32, height: 32)

                                if item.priority == priority {
                                    Circle()
                                        .fill(priority == .none ? DesignSystem.outline : priority.color)
                                        .frame(width: 20, height: 20)
                                }
                            }

                            Text(priority.label)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(item.priority == priority ? (priority == .none ? DesignSystem.outline : priority.color) : DesignSystem.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                             RoundedRectangle(cornerRadius: 12)
                                .fill(item.priority == priority ? (priority == .none ? DesignSystem.outline.opacity(0.1) : priority.color.opacity(0.1)) : Color.clear)
                        )
                    }
                }
            }
            .padding(12)
            .background(DesignSystem.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // 进度选择
            ProgressPicker(progress: $draftProgress, color: priorityColor)
                .padding(.horizontal, 4)
                .onChange(of: draftProgress) { _, newValue in
                    item.progress = newValue
                }

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
                            .foregroundColor(DesignSystem.onError)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(DesignSystem.error)

                        Text(tomorrowInfo.day)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(DesignSystem.onSurface)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DesignSystem.surfaceContainerLowest)
                    }
                    .frame(width: 48, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(DesignSystem.outlineVariant, lineWidth: 1)
                    )
                    .padding(.leading, 16)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(continueButtonTitle)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(DesignSystem.onSurface)
                        Text("or_select_other_date")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(DesignSystem.onSurfaceVariant)
                    }
                    .padding(.leading, 16)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignSystem.outline)
                        .padding(.trailing, 20)
                }
                .frame(height: 80)
                .background(DesignSystem.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(DesignSystem.onSurface)
                        Text("edit")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.onSurface)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(DesignSystem.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                        Image(systemName: "trash.fill")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundColor(DesignSystem.error)
                        Text("delete")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.error)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(DesignSystem.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: DesignSystem.shadowColor, radius: 10, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(DesignSystem.softBackground)
        .presentationDetents([.height(460)])
        .presentationCornerRadius(32)
        .onAppear {
            draftProgress = item.progress
        }
        .onDisappear {
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

struct TodoHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: [SortDescriptor(\DailyCardV3.date, order: .reverse), SortDescriptor(\DailyCardV3.createdAt, order: .reverse)]) private var observedCards: [DailyCardV3]
    @Query(sort: [SortDescriptor(\TodoItemV3.createdAt), SortDescriptor(\TodoItemV3.orderIndex)]) private var observedItems: [TodoItemV3]
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
    @State private var isRefreshing: Bool = false // 下拉刷新状态
    @State private var showGhostButton: Bool = true // 控制幽灵按钮显示
    @State private var cards: [DailyCardV3] = []
    @State private var loadedCardCount: Int = 0
    @State private var hasMoreCards: Bool = true
    @State private var isLoadingMoreCards: Bool = false
    @State private var lastAutoRefreshAt: Date = .distantPast
    @State private var lastWidgetReloadAt: Date = .distantPast

    private let cardPageSize = 6
    private let autoRefreshMinimumInterval: TimeInterval = 2
    private let widgetReloadMinimumInterval: TimeInterval = 1

    // iPhone 首页用了分页缓存，需要监听底层 SwiftData/CloudKit 变化后主动重载，
    // 否则跨设备同步后的卡片和进度会停留在旧快照。
    private var syncVersion: Int {
        var hasher = Hasher()

        for card in observedCards {
            hasher.combine(card.id)
            hasher.combine(card.date)
            hasher.combine(card.customTitle ?? "")
            hasher.combine(card.items?.count ?? 0)
        }

        for item in observedItems {
            hasher.combine(item.id)
            hasher.combine(item.card?.id.uuidString ?? "inbox")
            hasher.combine(item.title)
            hasher.combine(item.orderIndex)
            hasher.combine(item.progress)
            hasher.combine(item.isDone)
            hasher.combine(item.completedAt?.timeIntervalSinceReferenceDate ?? -1)
        }

        return hasher.finalize()
    }
    
    // 问候语标题
    private var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Hi👋,早上好～"
        case 12..<14:
            return "Hi👋,中午好～"
        case 14..<18:
            return "Hi👋,下午好～"
        case 18..<23:
            return "Hi👋,晚上好～"
        default:
            return "Hi👋,夜深了～"
        }
    }
    
    // 当前日期字符串
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    // 幽灵按钮 - 开启新的一天
                    Button {
                        withAnimation { createTodayCard() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("开启新的一天")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(DesignSystem.primary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(DesignSystem.surfaceContainerLow)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(DesignSystem.primary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 16)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onChange(of: proxy.frame(in: .global).minY) { _, newValue in
                                    // 当按钮滚动到屏幕外（y < 150）时隐藏，回到视野（y >= 150）时显示
                                    if newValue < 150 && showGhostButton {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showGhostButton = false
                                        }
                                    } else if newValue >= 150 && !showGhostButton {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showGhostButton = true
                                        }
                                    }
                                }
                        }
                    )
                    .opacity(showGhostButton ? 1 : 0)
                    
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
                            onDeleteCard: {
                                reloadCards(reset: true)
                            },
                            onComplete: { sourcePoint in
                                confettiSourcePosition = sourcePoint
                                confettiCounter += 1
                                Haptics.success()
                            },
                            onDropToCard: { itemIDs in
                                TodoDropCoordinator.moveItemsToCard(itemIDs: itemIDs, to: card)
                            }
                        )
                    }

                    if isLoadingMoreCards {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("加载更多中…")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    } else if hasMoreCards && !cards.isEmpty {
                        Text("继续上滑查看更早的待办")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .onAppear {
                                loadMoreCardsIfNeeded()
                            }
                    }
                    
                    // 空状态提示
                    if cards.isEmpty {
                        VStack(spacing: 20) {
                            Spacer().frame(height: 60)
                            
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 64, weight: .light))
                                .foregroundColor(DesignSystem.outline)
                            
                            Text("todo_list_empty")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(DesignSystem.onSurfaceVariant)
                            
                            Button {
                                withAnimation { createTodayCard() }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("create_today")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(DesignSystem.onPrimary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(DesignSystem.primary)
                                .clipShape(Capsule())
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(
                DesignSystem.background
                    .ignoresSafeArea()
            )
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(greetingTitle)

            .refreshable {
                await refreshData()
            }
            
            // 悬浮按钮 - 新的一天（仅在幽灵按钮隐藏时显示）
            if !showGhostButton {
                Button {
                    withAnimation { createTodayCard() }
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
                .transition(.scale.combined(with: .opacity))
            }
        }
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
                    try? modelContext.save()
                    reloadCards(reset: true)
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
            } else if cards.isEmpty {
                reloadCards(reset: true)
            }
            triggerAutomaticRefreshIfNeeded(force: true)
        }
        .onChange(of: syncVersion) { _, _ in
            reloadCards(reset: true)
            reloadWidgetTimelineIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            triggerAutomaticRefreshIfNeeded()
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
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        reloadCards(reset: true)
    }

    private func createTodayCard() {
        let calendar = Calendar.current
        let targetDate = DailyCardDatePlanner.targetDate(
            latestCardDate: observedCards.first?.date,
            today: Date(),
            calendar: calendar
        )

        if observedCards.contains(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = NSLocalizedString("card_date_format", comment: "Date format for card title")
        let defaultDateTitle = formatter.string(from: targetDate)
        
        var titleToUse: String? = nil
        let existingTitles = Set(
            observedCards
                .filter { calendar.isDate($0.date, inSameDayAs: targetDate) }
                .map { $0.customTitle ?? defaultDateTitle }
        )

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
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        reloadCards(reset: true)
    }

    private func addItem(text: String, to card: DailyCardV3) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        
        // 计算当前最大的 orderIndex
        let maxOrder = card.items?.map { $0.orderIndex }.max() ?? -1
        
        let item = TodoItemV3(title: t, card: card)
        item.orderIndex = maxOrder + 1
        modelContext.insert(item)
        Haptics.light()
        
        // 强制保存以确保 Widget 能读到最新数据
        try? modelContext.save()
        
        // 刷新 Widget
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func refreshData(showRefreshIndicator: Bool = true) async {
        if showRefreshIndicator {
            isRefreshing = true
        }
        try? await Task.sleep(nanoseconds: 500_000_000)
        reloadCards(reset: true)
        if showRefreshIndicator {
            isRefreshing = false
        }
    }

    private func triggerAutomaticRefreshIfNeeded(force: Bool = false) {
        guard !isRefreshing else { return }

        let now = Date()
        guard force || now.timeIntervalSince(lastAutoRefreshAt) >= autoRefreshMinimumInterval else {
            return
        }

        lastAutoRefreshAt = now

        Task {
            await refreshData(showRefreshIndicator: false)
        }
    }

    private func reloadWidgetTimelineIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastWidgetReloadAt) >= widgetReloadMinimumInterval else {
            return
        }

        lastWidgetReloadAt = now
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func reloadCards(reset: Bool) {
        guard !isLoadingMoreCards else { return }
        if reset {
            loadedCardCount = 0
            hasMoreCards = true
            cards = []
        }
        loadMoreCardsIfNeeded()
    }

    private func loadMoreCardsIfNeeded() {
        guard hasMoreCards, !isLoadingMoreCards else { return }

        isLoadingMoreCards = true
        defer { isLoadingMoreCards = false }

        var descriptor = FetchDescriptor<DailyCardV3>(
            sortBy: [
                SortDescriptor(\DailyCardV3.date, order: .reverse),
                SortDescriptor(\DailyCardV3.createdAt, order: .reverse)
            ]
        )
        descriptor.fetchOffset = loadedCardCount
        descriptor.fetchLimit = cardPageSize

        do {
            let fetchedCards = try modelContext.fetch(descriptor)
            if loadedCardCount == 0 {
                cards = fetchedCards
            } else {
                cards.append(contentsOf: fetchedCards)
            }
            loadedCardCount += fetchedCards.count
            hasMoreCards = fetchedCards.count == cardPageSize
        } catch {
            print("Failed to load cards: \(error)")
            hasMoreCards = false
        }
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
    
    // 计算属性：获取明日日期
    private var tomorrowDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    // 计算属性：获取下周一日期
    private var nextMondayDate: Date {
        let today = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        var daysToAdd = 0
        if weekday == 2 { // Today is Monday
            daysToAdd = 7
        } else {
            daysToAdd = (9 - weekday) % 7
            if daysToAdd == 0 { daysToAdd = 7 }
        }
        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
    }
    
    // 格式化日期显示
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    
    // 格式化星期显示
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // 周几
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Text("add_one_day")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.textPrimary)
                
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.textTertiary.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Actions
                    HStack(spacing: 12) {
                        QuickDateButton(
                            title: NSLocalizedString("tomorrow", comment: "Tomorrow"),
                            date: formatDate(tomorrowDate),
                            weekday: formatWeekday(tomorrowDate),
                            icon: "sun.max.fill",
                            color: .orange,
                            isSelected: Calendar.current.isDate(targetDate, inSameDayAs: tomorrowDate)
                        ) {
                            withAnimation {
                                targetDate = tomorrowDate
                            }
                        }
                        
                        QuickDateButton(
                            title: NSLocalizedString("next_monday", comment: "Next Monday"),
                            date: formatDate(nextMondayDate),
                            weekday: formatWeekday(nextMondayDate),
                            icon: "briefcase.fill",
                            color: DesignSystem.macAccent,
                            isSelected: Calendar.current.isDate(targetDate, inSameDayAs: nextMondayDate)
                        ) {
                            withAnimation {
                                targetDate = nextMondayDate
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Calendar Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("or_select_other_date")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.textSecondary)
                            .padding(.horizontal, 4)
                        
                        CustomCalendarView(selectedDate: $targetDate)
                            .padding(16)
                            .background(DesignSystem.cardBackground)
                            .cornerRadius(16)
                            .shadow(color: DesignSystem.shadowColor.opacity(0.5), radius: 8, x: 0, y: 2)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 100) // Space for bottom button
            }
            
            // Bottom Button Container
            VStack {
                Button(action: {
                    onConfirm()
                }) {
                    HStack {
                        Text("confirm_continuation")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(DesignSystem.primary)
                    .cornerRadius(27)
                    .shadow(color: DesignSystem.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16) // Safe area handled by sheet usually, but adding some padding
            .background(
                Rectangle()
                    #if os(iOS)
                    .fill(.regularMaterial)
                    #else
                    .fill(Color.clear)
                    #endif
                    .ignoresSafeArea()
            )
        }
        #if os(macOS)
        .frame(width: 400, height: 600)
        #endif
        .background(DesignSystem.softBackground)
        .presentationDetents([.fraction(0.7), .large])
        .presentationCornerRadius(24)
    }
}

// 辅助视图：快捷日期按钮
struct QuickDateButton: View {
    let title: String
    let date: String
    let weekday: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                        Text(title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(isSelected ? .white : color)
                    .opacity(isSelected ? 1 : 0.8)
                    
                    Spacer()
                    
                    Text(date)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : DesignSystem.textPrimary)
                    
                    Text(weekday)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : DesignSystem.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .frame(height: 100)
            .background(
                ZStack {
                    if isSelected {
                        color
                    } else {
                        DesignSystem.cardBackground
                    }
                }
            )
            .cornerRadius(16)
            .shadow(color: isSelected ? color.opacity(0.3) : DesignSystem.shadowColor.opacity(0.5), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : color.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
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
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20, weight: .bold))
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
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20, weight: .semibold))
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

#if os(iOS)
private enum TodoDropCoordinator {
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
#endif

struct DayCardViewNew: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var card: DailyCardV3
    @Binding var addingText: String
    var onAdd: (String) -> Void
    var onContinue: (TodoItemV3) -> Void
    var onEdit: (TodoItemV3) -> Void
    var onDeleteCard: () -> Void
    var onComplete: (CGPoint) -> Void
    var onDropToCard: ([String]) -> Bool
    @FocusState private var addingFieldFocused: Bool
    
    @State private var showActionMenu = false
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var draggingItem: TodoItemV3?
    @State private var isDropTargeted = false
    
    private static let cardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }()
    
    private static let cardWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    // 排序后的待办事项
    private var sortedItems: [TodoItemV3] {
        card.items?.sorted { $0.orderIndex < $1.orderIndex } ?? []
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(card.date)
    }

    private var relativeDayTitle: String? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cardDay = calendar.startOfDay(for: card.date)

        if cardDay == today {
            return "今天"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today), cardDay == tomorrow {
            return "明天"
        }

        if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today), cardDay == dayAfterTomorrow {
            return "后天"
        }

        return nil
    }
    
    private var displayTitle: String {
        if let title = card.customTitle, !title.isEmpty {
            return title
        }
        return relativeDayTitle ?? Self.cardDateFormatter.string(from: card.date)
    }

    private func handleDropToCard(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let itemID = object as? NSString else { return }

            DispatchQueue.main.async {
                withAnimation {
                    _ = onDropToCard([String(itemID)])
                }
            }
        }

        return true
    }
    
    var body: some View {
        let items = sortedItems
        let totalCount = items.count
        let completedCount = items.filter { $0.isDone }.count

        VStack(alignment: .leading, spacing: 0) {
            // 卡片头部 - 新设计：标题 + 日期 + 计数标签
            HStack(alignment: .center) {
                // 左侧：标题和日期
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(displayTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.textPrimary)
                    
                    if isToday {
                        Text(Self.cardWeekdayFormatter.string(from: card.date))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.textSecondary)
                    } else {
                        Text(Self.cardWeekdayFormatter.string(from: card.date))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                }
                
                Spacer()
                
                // 右侧：待办计数标签
                if totalCount > 0 {
                    Text("\(completedCount)/\(totalCount)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignSystem.onSurfaceVariant)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DesignSystem.surfaceContainerHigh)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
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
                    onDeleteCard()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要删除这张卡片及其所有待办事项吗？此操作不可恢复。")
            }
            
            // 待办列表 - 新设计：药丸形状任务项
            VStack(spacing: 12) {
                ForEach(items) { item in
                    TodoItemRowNew(item: item, onContinue: {
                        onContinue(item)
                    }, onEdit: {
                        onEdit(item)
                    }, onComplete: { point in
                        onComplete(point)
                    })
                    .padding(.horizontal, 16)
                    .onDrag {
                        self.draggingItem = item
                        return NSItemProvider(object: item.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: TodoDropDelegate(item: item, items: items, draggingItem: draggingItem, onFinish: { draggingItem = nil }))
                }
                
                // 输入框区域 - 使用浅色背景区分
                HStack(spacing: 14) {
                    // 虚线圆圈表示可添加
                    ZStack {
                        Circle()
                            .stroke(DesignSystem.outlineVariant.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DesignSystem.outlineVariant)
                    }
                    
                    TextField(NSLocalizedString("add_new_task", comment: "Add new task placeholder"), text: $addingText)
                        .focused($addingFieldFocused)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(DesignSystem.onSurface)
                        .onSubmit {
                            let t = addingText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            onAdd(t)
                            addingText = ""
                            addingFieldFocused = true
                            Haptics.light()
                        }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DesignSystem.surfaceContainerHigh.opacity(0.5))
                )
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .background(DesignSystem.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isDropTargeted ? DesignSystem.primary : Color.clear, lineWidth: 2)
        )
        .onDrop(of: [.text], isTargeted: $isDropTargeted, perform: handleDropToCard)
    }
}

struct TodoItemRowNew: View {
    private enum SwipeInteractionAxis {
        case undecided
        case horizontal
        case vertical
    }

    @Environment(\.modelContext) private var modelContext
    @Bindable var item: TodoItemV3
    var onContinue: () -> Void
    var onEdit: () -> Void
    var onComplete: (CGPoint) -> Void
    @State private var ringFrame: CGRect = .zero
    @State private var isHovered = false
    @State private var swipeOffset: CGFloat = 0
    @State private var restingSwipeOffset: CGFloat = 0
    @State private var swipeInteractionAxis: SwipeInteractionAxis = .undecided

    private let swipeActionWidth: CGFloat = 64
    private let swipeActionSpacing: CGFloat = 10

    private var totalSwipeActionWidth: CGFloat {
        (swipeActionWidth * 2) + swipeActionSpacing
    }

    private var priorityColor: Color {
        item.priority == .none ? DesignSystem.outline : item.priority.color
    }

    private var isSwipeActionsOpen: Bool {
        restingSwipeOffset < 0
    }

    private var isSwipeActionsVisible: Bool {
        isSwipeActionsOpen || swipeOffset < -4
    }

    private func updateSwipeInteractionAxis(for value: DragGesture.Value) {
        guard swipeInteractionAxis == .undecided else { return }

        let horizontalTranslation = value.translation.width
        let verticalTranslation = value.translation.height
        let horizontalDistance = abs(horizontalTranslation)
        let verticalDistance = abs(verticalTranslation)

        if isSwipeActionsOpen {
            if horizontalDistance > 10, horizontalDistance > verticalDistance * 1.2 {
                swipeInteractionAxis = .horizontal
            } else if verticalDistance > 8 {
                swipeInteractionAxis = .vertical
            }
            return
        }

        if horizontalTranslation < -14, horizontalDistance > verticalDistance * 1.6 {
            swipeInteractionAxis = .horizontal
        } else if verticalDistance > 8 {
            swipeInteractionAxis = .vertical
        }
    }

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            item.progress = item.isDone ? 0 : 100
        }
        if item.isDone {
            let centerPoint = CGPoint(x: ringFrame.midX, y: ringFrame.midY)
            onComplete(centerPoint)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func closeSwipeActions() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
            swipeOffset = 0
            restingSwipeOffset = 0
        }
    }

    private func openSwipeActions() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
            swipeOffset = -totalSwipeActionWidth
            restingSwipeOffset = -totalSwipeActionWidth
        }
    }

    private func deleteItem() {
        closeSwipeActions()
        withAnimation {
            modelContext.delete(item)
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if isSwipeActionsVisible {
                HStack(spacing: swipeActionSpacing) {
                    Button {
                        Haptics.light()
                        closeSwipeActions()
                        onEdit()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: swipeActionWidth)
                        .frame(maxHeight: .infinity)
                        .background(DesignSystem.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        deleteItem()
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: swipeActionWidth)
                        .frame(maxHeight: .infinity)
                        .background(DesignSystem.error)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity)
                .padding(.leading, 32)
            }

            HStack(spacing: 10) {
                // 环形进度圈
                // 轻点：直接完成/取消 (0 <-> 100)
                // 长按：打开编辑面板精确设置进度
                ProgressRing(progress: item.progress, color: priorityColor)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    ringFrame = geo.frame(in: .global)
                                }
                                .onChange(of: geo.frame(in: .global)) { _, newValue in
                                    ringFrame = newValue
                                }
                        }
                    )
                    .overlay {
                        Button(action: toggleCompletion) {
                            Color.clear
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .onLongPressGesture {
                            Haptics.medium()
                            onEdit()
                        }
                    }

                // 任务内容
                VStack(alignment: .leading, spacing: 4) {
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
                            .font(.system(size: 14, weight: item.isDone ? .regular : .medium, design: .rounded))
                            .strikethrough(item.isDone)
                            .foregroundColor(item.isDone ? DesignSystem.textTertiary : DesignSystem.onSurface)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                }

                Spacer()

                // 悬停时显示编辑按钮
                if isHovered {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(DesignSystem.surfaceContainerHighest)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DesignSystem.surfaceContainerLowest)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(DesignSystem.outlineVariant.opacity(0.15), lineWidth: 0.5)
                    )
            )
            .contentShape(Rectangle())
            .offset(x: swipeOffset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 22, coordinateSpace: .local)
                    .onChanged { value in
                        updateSwipeInteractionAxis(for: value)

                        guard swipeInteractionAxis == .horizontal else { return }

                        let proposedOffset = restingSwipeOffset + value.translation.width
                        swipeOffset = min(0, max(-totalSwipeActionWidth, proposedOffset))
                    }
                    .onEnded { value in
                        defer { swipeInteractionAxis = .undecided }

                        guard swipeInteractionAxis == .horizontal else {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                                swipeOffset = restingSwipeOffset
                            }
                            return
                        }

                        let proposedOffset = restingSwipeOffset + value.translation.width
                        let shouldOpen = proposedOffset < -(totalSwipeActionWidth * 0.45)

                        if shouldOpen {
                            openSwipeActions()
                        } else {
                            closeSwipeActions()
                        }
                    }
            )
            .onTapGesture {
                if isSwipeActionsOpen {
                    closeSwipeActions()
                } else {
                    onEdit()
                }
            }
            .onLongPressGesture {
                Haptics.light()
                onEdit()
            }
        }
    }
}
