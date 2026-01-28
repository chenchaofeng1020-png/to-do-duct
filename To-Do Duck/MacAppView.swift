import SwiftUI

#if os(macOS)
struct MacAppView: View {
    @State private var selectedTab: MacTab? = .todo
    
    enum MacTab: String, CaseIterable, Identifiable {
        case todo
        case memo
        case profile
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .todo: return "checklist" // 使用 Localizable key
            case .memo: return "memos"
            case .profile: return "profile_title"
            }
        }
        
        var icon: String {
            switch self {
            case .todo: return "checklist"
            case .memo: return "square.and.pencil"
            case .profile: return "person"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(MacTab.allCases) { tab in
                    NavigationLink(value: tab) {
                        Label(LocalizedStringKey(tab.title), systemImage: tab.icon)
                            .foregroundStyle(DesignSystem.textPrimary)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
            // .toolbar(removing: .title) // Removed for compatibility with macOS < 15.0
        } detail: {
            if let selectedTab {
                switch selectedTab {
                case .todo:
                    MacTodoHomeView()
                case .memo:
                    MacMemoHomeView()
                case .profile:
                    MacProfileView()
                }
            } else {
                Text("Select an item")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    MacAppView()
}
#endif
