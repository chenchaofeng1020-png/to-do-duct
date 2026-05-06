import SwiftUI

#if os(macOS)
struct MacAppView: View {
    @State private var selectedTab: MacTab? = .todo
    @State private var hoveredTab: MacTab?
    
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
            VStack(alignment: .leading, spacing: 6) {
                ForEach(MacTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 22)

                            Text(LocalizedStringKey(tab.title))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))

                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(foregroundColor(for: tab))
                        .padding(.horizontal, 18)
                        .frame(height: 40)
                        .background(backgroundColor(for: tab))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        hoveredTab = isHovering ? tab : (hoveredTab == tab ? nil : hoveredTab)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        .tint(DesignSystem.macAccent)
        .accentColor(DesignSystem.macAccent)
    }

    private func foregroundColor(for tab: MacTab) -> Color {
        selectedTab == tab ? DesignSystem.sidebarSelectionForeground : DesignSystem.textPrimary
    }

    private func backgroundColor(for tab: MacTab) -> Color {
        if selectedTab == tab {
            return DesignSystem.sidebarSelectionBackground
        }

        if hoveredTab == tab {
            return DesignSystem.surfaceContainerLow
        }

        return .clear
    }
}

#Preview {
    MacAppView()
}
#endif
