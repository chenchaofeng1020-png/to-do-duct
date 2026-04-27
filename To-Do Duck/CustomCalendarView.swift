import SwiftUI

// MARK: - Custom Calendar View

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
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
    
    var body: some View {
        VStack(spacing: 16) {
            // Header: Month/Year navigation
            HStack {
                Text(monthYearString(for: currentMonth))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.textPrimary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            
            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16) {
                // Weekday headers
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.textTertiary)
                        .padding(.bottom, 4)
                }
                
                // Days
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(date: date, selectedDate: selectedDate, isToday: calendar.isDateInToday(date)) {
                            selectedDate = date
                        }
                    } else {
                        Text("") // Empty placeholder for offset
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
                .aspectRatio(0.6, contentMode: .fill)
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
