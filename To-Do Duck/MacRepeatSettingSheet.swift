import SwiftUI
import SwiftData

struct RepeatSettingSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var rules: [RepeatRule]
    
    let item: TodoItemV3
    
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var selectedOption: QuickOptionType = .custom
    
    private var existingRule: RepeatRule? {
        if let id = item.fromRepeatRuleId {
            return rules.first { $0.id == id }
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                ruleFormView
            }
            .scrollIndicators(.automatic)
            .thinScrollbar()

            Divider()

            footerActions
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .background(DesignSystem.background)
        }
        .frame(width: 400, height: sheetHeight)
        .background(DesignSystem.background)
        .tint(DesignSystem.macAccent)
        .onAppear {
            checkInitialState()
        }
    }

    private var sheetHeight: CGFloat {
        var height: CGFloat = selectedOption == .custom ? 610 : 450
        if existingRule != nil {
            height += 50
        }
        return height
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Text(LocalizedStringKey(existingRule != nil ? "repeat_task_active" : "repeat_task_title"))
                    .font(.headline)
                    .foregroundColor(DesignSystem.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(DesignSystem.background)

            Divider()
        }
    }
    
    // MARK: - Subviews
    
    private var ruleFormView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 说明文本
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.macAccent)
                    .padding(.top, 2)
                Text(LocalizedStringKey("repeat_description"))
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(DesignSystem.macAccent.opacity(0.08))
            .cornerRadius(8)
            
            // 快捷选项 Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                quickOptionButton("day_after_tomorrow", type: .dayAfterTomorrow)
                quickOptionButton("end_of_week", type: .endOfWeek)
                quickOptionButton("end_of_month", type: .endOfMonth)
                quickOptionButton("next_month", type: .nextMonth)
                quickOptionButton("custom_date", type: .custom)
            }
            
            // 自定义日历
            if selectedOption == .custom {
                CustomCalendarView(selectedDate: $endDate, isCompact: true)
                    .padding(14)
                .background(DesignSystem.cardBackground)
                .cornerRadius(12)
                .clipped()
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                 // 显示选中的日期提示
                 HStack {
                     Text("repeat_until")
                         .foregroundColor(DesignSystem.textSecondary)
                     Spacer()
                     Text(endDate.formatted(date: .long, time: .omitted))
                         .font(.headline)
                         .foregroundColor(DesignSystem.textPrimary)
                 }
                 .padding()
                 .background(DesignSystem.macAccent.opacity(0.08))
                 .cornerRadius(12)
            }
            
        }
        .padding(24)
    }

    private var footerActions: some View {
        VStack(spacing: 12) {
            Button {
                if let rule = existingRule {
                    updateRule(rule)
                } else {
                    createRule()
                }
            } label: {
                Text(LocalizedStringKey(existingRule != nil ? "update_repeat" : "confirm_repeat"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(DesignSystem.macAccent)
            .controlSize(.large)

            if let rule = existingRule {
                Button(role: .destructive) {
                    deleteRule(rule)
                } label: {
                    Text(LocalizedStringKey("stop_repeat"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
    
    private func quickOptionButton(_ titleKey: String, type: QuickOptionType) -> some View {
        let isSelected = isOptionSelected(type)
        
        return Button {
            selectOption(type)
        } label: {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : DesignSystem.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? DesignSystem.macAccent : DesignSystem.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? DesignSystem.macAccent : DesignSystem.separatorColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Logic
    
    enum QuickOptionType {
        case dayAfterTomorrow
        case endOfWeek
        case endOfMonth
        case nextMonth
        case custom
    }
    
    private func selectOption(_ type: QuickOptionType) {
        selectedOption = type
        
        let calendar = Calendar.current
        let today = Date()
        
        switch type {
        case .dayAfterTomorrow:
            endDate = calendar.date(byAdding: .day, value: 2, to: today)!
        case .endOfWeek:
            // Use dateInterval(of: .weekOfYear) to respect the user's calendar settings (e.g. first weekday)
            if let interval = calendar.dateInterval(of: .weekOfYear, for: today) {
                // interval.end is the start of the *next* week. Subtract 1 day to get the start of the last day of the current week.
                endDate = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? today
            }
        case .endOfMonth:
            if let range = calendar.range(of: .day, in: .month, for: today),
               let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
               let endOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth) {
                endDate = endOfMonth
            }
        case .nextMonth:
             endDate = calendar.date(byAdding: .month, value: 1, to: today)!
        case .custom:
            break
        }
    }
    
    private func isOptionSelected(_ type: QuickOptionType) -> Bool {
        return selectedOption == type
    }
    
    private func createRule() {
        let rule = RepeatRule(title: item.title, startDate: Date(), endDate: endDate)
        modelContext.insert(rule)
        item.fromRepeatRuleId = rule.id
        try? modelContext.save()
        dismiss()
    }
    
    private func deleteRule(_ rule: RepeatRule) {
        modelContext.delete(rule)
        item.fromRepeatRuleId = nil
        try? modelContext.save()
        dismiss()
    }
    
    private func updateRule(_ rule: RepeatRule) {
        rule.endDate = endDate
        rule.title = item.title
        try? modelContext.save()
        dismiss()
    }
    
    private func checkInitialState() {
        guard let rule = existingRule else {
            // New rule: set default to end of week
            selectOption(.endOfWeek)
            return
        }
        
        endDate = rule.endDate
        
        // Determine selected option based on endDate
        let calendar = Calendar.current
        let today = Date()
        
        // Check explicit matches in priority order
        
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today)!
        if calendar.isDate(endDate, inSameDayAs: dayAfterTomorrow) {
            selectedOption = .dayAfterTomorrow
            return
        }
        
        if let interval = calendar.dateInterval(of: .weekOfYear, for: today) {
            let endOfWeekDate = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? today
            if calendar.isDate(endDate, inSameDayAs: endOfWeekDate) {
                selectedOption = .endOfWeek
                return
            }
        }
        
        if let range = calendar.range(of: .day, in: .month, for: today),
           let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
           let endOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth) {
            if calendar.isDate(endDate, inSameDayAs: endOfMonth) {
                selectedOption = .endOfMonth
                return
            }
        }
        
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: today)!
        if calendar.isDate(endDate, inSameDayAs: nextMonth) {
            selectedOption = .nextMonth
            return
        }
        
        selectedOption = .custom
    }
}
