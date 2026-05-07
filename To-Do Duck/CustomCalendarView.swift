import SwiftUI

// MARK: - Custom Calendar View

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    var isCompact: Bool = false
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = [
        NSLocalizedString("sun", value: "SUN", comment: "Sunday abbreviation"),
        NSLocalizedString("mon", value: "MON", comment: "Monday abbreviation"),
        NSLocalizedString("tue", value: "TUE", comment: "Tuesday abbreviation"),
        NSLocalizedString("wed", value: "WED", comment: "Wednesday abbreviation"),
        NSLocalizedString("thu", value: "THU", comment: "Thursday abbreviation"),
        NSLocalizedString("fri", value: "FRI", comment: "Friday abbreviation"),
        NSLocalizedString("sat", value: "SAT", comment: "Saturday abbreviation")
    ]

    private var verticalSpacing: CGFloat {
        isCompact ? 8 : 16
    }

    private var dayGridSpacing: CGFloat {
        isCompact ? 6 : 16
    }

    private var dayCellHeight: CGFloat {
        isCompact ? 30 : 44
    }

    private var headerFontSize: CGFloat {
        isCompact ? 12 : 14
    }

    private var headerControlSpacing: CGFloat {
        isCompact ? 8 : 12
    }

    private var weekdayBottomPadding: CGFloat {
        isCompact ? 2 : 4
    }
    
    var body: some View {
        VStack(spacing: verticalSpacing) {
            // Header: Month/Year navigation
            HStack {
                Text(monthYearString(for: currentMonth))
                    .font(.system(size: headerFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.textPrimary)
                
                Spacer()
                
                HStack(spacing: headerControlSpacing) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: isCompact ? 11 : 12, weight: .bold))
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: isCompact ? 11 : 12, weight: .bold))
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, isCompact ? 2 : 4)
            
            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: dayGridSpacing) {
                // Weekday headers
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: isCompact ? 9 : 10, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.textTertiary)
                        .padding(.bottom, weekdayBottomPadding)
                }
                
                // Days
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            selectedDate: selectedDate,
                            isToday: calendar.isDateInToday(date),
                            height: dayCellHeight
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: dayCellHeight)
                    }
                }
            }
        }
        // Removed internal padding and background for better composability
        // .padding(16)
        // .background(DesignSystem.cardBackground)
        // .cornerRadius(12)
        // .shadow(color: DesignSystem.shadowColor.opacity(0.8), radius: 8, x: 0, y: 4)
        .onAppear {
            currentMonth = selectedDate
        }
        .onChange(of: selectedDate) { oldValue, newValue in
             if !calendar.isDate(newValue, equalTo: currentMonth, toGranularity: .month) {
                 currentMonth = newValue
             }
         }
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date).uppercased()
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let dateInterval = monthInterval
        let days = calendar.dateComponents([.day], from: dateInterval.start, to: dateInterval.end).day!
        
        let firstDayOfMonth = dateInterval.start
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offset = weekday - 1 // 1 is Sunday
        
        var dates: [Date?] = Array(repeating: nil, count: offset)
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDayOfMonth) {
                dates.append(date)
            }
        }
        
        return dates
    }
}

struct DayCell: View {
    let date: Date
    let selectedDate: Date
    let isToday: Bool
    var height: CGFloat = 44
    let action: () -> Void
    
    private var isSelected: Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    var body: some View {
        Button(action: action) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : (isToday ? DesignSystem.primary : DesignSystem.textPrimary))
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DesignSystem.primary)
                        } else if isToday {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignSystem.primary, lineWidth: 1.5)
                        }
                    }
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mac Sidebar Calendar View

#if os(macOS)
import SwiftData

struct MacSidebarCalendarView: View {
    @Query private var dailyCards: [DailyCardV3]
    @Query private var memoCards: [MemoCardV3]

    @Binding var selectedDate: Date?
    @State private var currentMonth: Date = Date()
    @State private var isEditingTitle = false
    @State private var titleDraft = ""
    @FocusState private var isTitleFocused: Bool
    private let calendar = Calendar.current
    private let daysOfWeek = ["一", "二", "三", "四", "五", "六", "日"]
    private let sidebarGridLineColor = DesignSystem.outlineVariant.opacity(0.18)
    private let sidebarGridLineWidth: CGFloat = 0.4
    private let sidebarDayCellHeight: CGFloat = 28
    private let sidebarWeekdayCellHeight: CGFloat = 24

    var body: some View {
        VStack(spacing: 0) {
            calendarCard
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: selectedDate) { _, newValue in
            guard let newValue else { return }
            if !calendar.isDate(newValue, equalTo: currentMonth, toGranularity: .month) {
                currentMonth = newValue
            }
        }
    }

    private var monthCells: [Date?] {
        daysInMonth()
    }

    private var calendarRows: Int {
        max((monthCells.count + 6) / 7, 1)
    }

    private var calendarCard: some View {
        ZStack(alignment: .top) {
            calendarCardBackground
            calendarGrid
        }
    }

    private var calendarCardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DesignSystem.outlineVariant.opacity(0.24), lineWidth: 1)
            )
    }

    private var calendarGrid: some View {
        VStack(spacing: 0) {
            calendarTitleBar
                .padding(.top, 12)
                .padding(.bottom, 8)

            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    sidebarWeekdayCell(day: day)
                }
            }

            ForEach(0..<calendarRows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        sidebarGridCell(row: row, column: column)
                    }
                }
            }
        }
        .frame(height: sidebarWeekdayCellHeight + sidebarDayCellHeight * CGFloat(calendarRows))
        .overlay {
            sidebarCalendarGridLines(rows: calendarRows)
        }
        .padding(.horizontal, 16)
        .padding(.top, 22)
        .padding(.bottom, 7)
    }

    @ViewBuilder
    private func sidebarGridCell(row: Int, column: Int) -> some View {
        let index = row * 7 + column

        if index < monthCells.count, let date = monthCells[index] {
            sidebarDayCell(date: date)
        } else {
            sidebarEmptyCell()
        }
    }

    private func monthSwitchButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(DesignSystem.sidebarSelectionForeground)
                .frame(width: 12, height: 14)
        }
        .buttonStyle(.plain)
    }

    private var calendarTitleBar: some View {
        HStack(spacing: 8) {
            editableCalendarTitle

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                monthSwitchButton(systemName: "chevron.left") {
                    changeMonth(by: -1)
                }

                Text(monthShortLabel)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(DesignSystem.sidebarSelectionForeground)
                    .lineLimit(1)
                    .fixedSize()

                monthSwitchButton(systemName: "chevron.right") {
                    changeMonth(by: 1)
                }
            }
            .frame(minWidth: 52, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 1)
        .frame(maxWidth: .infinity, minHeight: 23)
    }

    @ViewBuilder
    private var editableCalendarTitle: some View {
        if isEditingTitle {
            TextField("", text: $titleDraft)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(DesignSystem.sidebarSelectionForeground)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .focused($isTitleFocused)
                .onSubmit {
                    commitTitleEdit()
                }
                .onAppear {
                    isTitleFocused = true
                }
                .onChange(of: isTitleFocused) { _, isFocused in
                    if !isFocused && isEditingTitle {
                        commitTitleEdit()
                    }
                }
                .frame(maxWidth: .infinity)
        } else {
            Button(action: beginTitleEdit) {
                Text(calendarTitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(DesignSystem.sidebarSelectionForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("点击编辑月历标题")
        }
    }

    // MARK: - 日期单元格

    private func sidebarWeekdayCell(day: String) -> some View {
        Text(day)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(DesignSystem.primary.opacity(0.88))
            .frame(maxWidth: .infinity, minHeight: sidebarWeekdayCellHeight, maxHeight: sidebarWeekdayCellHeight)
    }

    @ViewBuilder
    private func sidebarDayCell(date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate(date, inSameDayAs: $0) } ?? false
        let status = dayStatus(for: date)

        Button {
            if isSelected {
                selectedDate = nil
            } else {
                selectedDate = date
            }
        } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(DesignSystem.primary.opacity(0.12))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                }

                if status != .none {
                    Image("DuckLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .shadow(color: .black.opacity(0.05), radius: 1.2, x: 0, y: 1)
                }

                if isToday && status == .none {
                    Circle()
                        .stroke(DesignSystem.primary, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }

                if status == .none {
                    Text("\(day)")
                        .font(.system(size: 11, weight: isToday || isSelected ? .bold : .medium, design: .rounded))
                        .foregroundColor(isToday || isSelected ? DesignSystem.primary : DesignSystem.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: sidebarDayCellHeight, maxHeight: sidebarDayCellHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sidebarEmptyCell() -> some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: sidebarDayCellHeight, maxHeight: sidebarDayCellHeight)
    }

    private func sidebarCalendarGridLines(rows: Int) -> some View {
        GeometryReader { proxy in
            Path { path in
                let columnWidth = proxy.size.width / 7

                for column in 1..<7 {
                    let x = columnWidth * CGFloat(column)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                }

                for row in 0..<rows {
                    let y = sidebarWeekdayCellHeight + sidebarDayCellHeight * CGFloat(row)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                }
            }
            .stroke(sidebarGridLineColor, lineWidth: sidebarGridLineWidth)
        }
    }

    // MARK: - 状态计算

    private enum DayStatus {
        case none
        case allDone
        case partialDone
        case hasPending
        case memoOnly
    }

    private func dayStatus(for date: Date) -> DayStatus {
        if let card = dailyCards.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
           let items = card.items, !items.isEmpty {
            let doneCount = items.filter { $0.isDone }.count
            if doneCount == items.count {
                return .allDone
            } else if doneCount > 0 {
                return .partialDone
            } else {
                return .hasPending
            }
        }

        let hasMemos = memoCards.contains { calendar.isDate($0.createdAt, inSameDayAs: date) }
        if hasMemos {
            return .memoOnly
        }

        return .none
    }

    private func statusColor(_ status: DayStatus) -> Color {
        switch status {
        case .allDone:     return Color(hex: "34c759")
        case .partialDone: return Color(hex: "ff9500")
        case .hasPending:  return Color(hex: "ff453a")
        case .memoOnly:    return Color(hex: "af52de")
        case .none:        return Color.clear
        }
    }

    // MARK: - 辅助方法

    private var calendarTitle: String {
        let savedTitle = UserDefaults.standard.string(forKey: titleStorageKey(for: currentMonth))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return savedTitle.isEmpty ? monthYearString(for: currentMonth) : savedTitle
    }

    private var monthShortLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return formatter.string(from: currentMonth)
    }

    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }

    private func beginTitleEdit() {
        titleDraft = calendarTitle
        isEditingTitle = true
    }

    private func commitTitleEdit() {
        let trimmedTitle = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = titleStorageKey(for: currentMonth)

        if trimmedTitle.isEmpty || trimmedTitle == monthYearString(for: currentMonth) {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set(trimmedTitle, forKey: key)
        }

        isEditingTitle = false
        isTitleFocused = false
    }

    private func titleStorageKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return "macSidebarCalendarTitle.\(year).\(month)"
    }

    private func changeMonth(by value: Int) {
        if isEditingTitle {
            commitTitleEdit()
        }

        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }

        let days = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day!
        let firstDayOfMonth = monthInterval.start
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Monday-based offset: Mon=1->0, Tue=2->1, ... Sun=7->6
        let offset = (weekday + 5) % 7

        var dates: [Date?] = Array(repeating: nil, count: offset)

        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDayOfMonth) {
                dates.append(date)
            }
        }

        // 补齐最后一行，保持网格整齐
        let trailing = (7 - (dates.count % 7)) % 7
        dates.append(contentsOf: Array(repeating: nil, count: trailing))

        return dates
    }
}

private struct SidebarCalendarTapeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notch = min(rect.width * 0.04, rect.height * 0.42)
        let left = rect.minX
        let right = rect.maxX
        let top = rect.minY
        let bottom = rect.maxY

        var path = Path()
        path.move(to: CGPoint(x: left + notch, y: top))
        path.addLine(to: CGPoint(x: right - notch, y: top))
        path.addLine(to: CGPoint(x: right - notch * 0.6, y: top + rect.height * 0.18))
        path.addLine(to: CGPoint(x: right, y: top + rect.height * 0.18))
        path.addLine(to: CGPoint(x: right - notch * 0.72, y: top + rect.height * 0.42))
        path.addLine(to: CGPoint(x: right, y: top + rect.height * 0.42))
        path.addLine(to: CGPoint(x: right - notch * 0.72, y: top + rect.height * 0.66))
        path.addLine(to: CGPoint(x: right, y: top + rect.height * 0.66))
        path.addLine(to: CGPoint(x: right - notch, y: bottom))
        path.addLine(to: CGPoint(x: left + notch, y: bottom))
        path.addLine(to: CGPoint(x: left + notch * 0.6, y: top + rect.height * 0.66))
        path.addLine(to: CGPoint(x: left, y: top + rect.height * 0.66))
        path.addLine(to: CGPoint(x: left + notch * 0.72, y: top + rect.height * 0.42))
        path.addLine(to: CGPoint(x: left, y: top + rect.height * 0.42))
        path.addLine(to: CGPoint(x: left + notch * 0.6, y: top + rect.height * 0.18))
        path.addLine(to: CGPoint(x: left, y: top + rect.height * 0.18))
        path.closeSubpath()

        return path
    }
}
#endif
