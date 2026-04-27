import WidgetKit
import SwiftUI
import SwiftData

struct SimpleEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
    let totalCount: Int
    let topTasks: [WidgetTask] // 更新为 WidgetTask 数组
    let duckStatus: DuckStatus
}

// 简化的任务模型，仅用于 Widget 显示
struct WidgetTask: Identifiable {
    let id: UUID
    let title: String
    let isDone: Bool
    let priorityRawValue: Int
}

enum DuckStatus: String {
    case working // 加油鸭
    case happy   // 很棒鸭
    case chill   // 下班鸭
    case sleep   // 休息鸭
}

struct Provider: TimelineProvider {
    @MainActor
    static let sharedModelContainer: ModelContainer? = {
        let schema = Schema([
            DailyCardV3.self,
            TodoItemV3.self,
            MemoCardV3.self,
            RepeatRule.self,
        ])
        
        let groupDefaults = UserDefaults(suiteName: "group.sdy.tododuck")
        let groupSync = groupDefaults?.bool(forKey: "isCloudSyncEnabled") ?? false
        let standardSync = UserDefaults.standard.bool(forKey: "isCloudSyncEnabled")
        let isCloudSyncEnabled = groupSync || standardSync
        let cloudKitMode: ModelConfiguration.CloudKitDatabase = isCloudSyncEnabled ? .automatic : .none

        // 使用显式 URL 初始化，与主 App 保持一致
        let appGroupID = "group.sdy.tododuck"
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        let storeURL = containerURL.appendingPathComponent("TodoDuckShared_v9.store")

        let config = ModelConfiguration(
            url: storeURL,
            allowsSave: false, // Widget 仅读取
            cloudKitDatabase: cloudKitMode
        )
        
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print("Widget ModelContainer init failed: \(error)")

            do {
                let fallbackConfig = ModelConfiguration(
                    url: storeURL,
                    allowsSave: false,
                    cloudKitDatabase: .none
                )
                return try ModelContainer(for: schema, configurations: fallbackConfig)
            } catch {
                print("Widget fallback ModelContainer init failed: \(error)")
                return nil
            }
        }
    }()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), completedCount: 2, totalCount: 5, topTasks: [
            WidgetTask(id: UUID(), title: "背单词", isDone: false, priorityRawValue: 2),
            WidgetTask(id: UUID(), title: "健身", isDone: false, priorityRawValue: 1),
            WidgetTask(id: UUID(), title: "写周报", isDone: true, priorityRawValue: 0)
        ], duckStatus: .working)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task { @MainActor in
            let entry = fetchTodayData()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task { @MainActor in
            let entry = fetchTodayData()
            
            // 设置刷新策略：
            // 1. 每次进入前台（由系统控制）
            // 2. 每天凌晨刷新（更新日期）
            // 3. 15分钟后尝试刷新（保持数据不过于陈旧）
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    // MARK: - Data Fetching
    @MainActor
    private func fetchTodayData() -> SimpleEntry {
        guard let container = Provider.sharedModelContainer else {
            // 如果容器加载失败，返回空状态
            return SimpleEntry(date: Date(), completedCount: 0, totalCount: 0, topTasks: [], duckStatus: .sleep)
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyCardV3>(
            sortBy: [
                SortDescriptor(\DailyCardV3.date, order: .reverse),
                SortDescriptor(\DailyCardV3.createdAt, order: .reverse)
            ]
        )
        
        do {
            let cards = try container.mainContext.fetch(descriptor)
            if let todayCard = cards.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                let items = todayCard.items ?? []
                let total = items.count
                let completed = items.filter { $0.isDone }.count
                
                // 获取所有任务，进行排序：
                // 1. 未完成在前，已完成在后
                // 2. 其次按优先级降序
                // 3. 最后按创建时间（这里用 orderIndex 或默认顺序）
                let allTasks = items.sorted { task1, task2 in
                    if task1.isDone != task2.isDone {
                        return !task1.isDone // 未完成在前 (false < true)
                    }
                    return task1.priorityRawValue > task2.priorityRawValue // 优先级高的在前
                }
                
                // 转换为 WidgetTask，取前 6 个（适配大号组件的最大显示数）
                let widgetTasks = allTasks.prefix(6).map { item in
                    WidgetTask(
                        id: item.id,
                        title: item.title,
                        isDone: item.isDone,
                        priorityRawValue: item.priorityRawValue
                    )
                }
                
                // 确定鸭子状态
                let status: DuckStatus
                if total == 0 {
                    status = .sleep
                } else if completed == total {
                    status = .chill
                } else if Double(completed) / Double(total) > 0.6 {
                    status = .happy
                } else {
                    status = .working
                }
                
                return SimpleEntry(date: Date(), completedCount: completed, totalCount: total, topTasks: Array(widgetTasks), duckStatus: status)
            }
        } catch {
            print("Widget fetch error: \(error)")
        }
        
        // 默认空状态
        return SimpleEntry(date: Date(), completedCount: 0, totalCount: 0, topTasks: [], duckStatus: .sleep)
    }
}
