import SwiftUI
import SwiftData
import CloudKit

#if os(iOS)
struct ProfileView: View {
    @AppStorage("allowPastContinuation") private var allowPastContinuation: Bool = false
    @AppStorage("isCloudSyncEnabled", store: UserDefaults(suiteName: "group.sdy.tododuck")) private var isCloudSyncEnabled: Bool = false
    
    @State private var showRestartAlert = false
    @State private var showiCloudErrorAlert = false
    @State private var icloudErrorMessage = ""
    @State private var isChecking = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景 - 使用与待办页面一致的背景色
                DesignSystem.background
                    .ignoresSafeArea()
                
                List {
                    Section(header: sectionHeader("data_sync")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "icloud.fill")
                                    .foregroundColor(isCloudSyncEnabled ? DesignSystem.primary : DesignSystem.outline)
                                    .font(.system(size: 20))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("icloud_sync")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(DesignSystem.onSurface)
                                    Text("icloud_sync_desc")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundColor(DesignSystem.textSecondary)
                                }
                                
                                Spacer()
                                
                                if isChecking {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                } else {
                                    Toggle("", isOn: $isCloudSyncEnabled)
                                        .labelsHidden()
                                        .tint(DesignSystem.primary)
                                        .onChange(of: isCloudSyncEnabled) {
                                            let newValue = isCloudSyncEnabled
                                            if newValue {
                                                checkiCloudStatus()
                                            } else {
                                                showRestartAlert = true
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(DesignSystem.surfaceContainerLowest)
                    
                    Section(header: sectionHeader("preferences")) {
                        Toggle("allow_past_continuation", isOn: $allowPastContinuation)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(DesignSystem.onSurface)
                            .tint(DesignSystem.primary)
                    }
                    .listRowBackground(DesignSystem.surfaceContainerLowest)
                    
                    Section(header: sectionHeader("about")) {
                        HStack {
                            Text("version")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(DesignSystem.onSurface)
                            Spacer()
                            Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                    }
                    .listRowBackground(DesignSystem.surfaceContainerLowest)
                }
                .navigationTitle("profile_title")
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .alert(NSLocalizedString("restart_required_title", comment: ""), isPresented: $showRestartAlert) {
                    Button(NSLocalizedString("ok", comment: ""), role: .cancel) {}
                } message: {
                    Text(NSLocalizedString("restart_required_message", comment: ""))
                }
                .alert(NSLocalizedString("icloud_check_failed_title", comment: ""), isPresented: $showiCloudErrorAlert) {
                    Button(NSLocalizedString("ok", comment: ""), role: .cancel) {
                        isCloudSyncEnabled = false
                    }
                } message: {
                    Text(icloudErrorMessage)
                }
            }
        }
    }

    private func sectionHeader(_ titleKey: LocalizedStringKey) -> some View {
        Text(titleKey)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(DesignSystem.textSecondary)
            .textCase(nil)
    }
    
    private func checkiCloudStatus() {
        isChecking = true
        
        Task {
            do {
                let status = try await CKContainer.default().accountStatus()
                await MainActor.run {
                    isChecking = false
                    
                    switch status {
                    case .available:
                        showRestartAlert = true
                    case .noAccount:
                        icloudErrorMessage = NSLocalizedString("icloud_not_logged_in", comment: "")
                        showiCloudErrorAlert = true
                    case .restricted:
                        icloudErrorMessage = "iCloud access is restricted on this device."
                        showiCloudErrorAlert = true
                    case .couldNotDetermine:
                        icloudErrorMessage = NSLocalizedString("network_error", comment: "")
                        showiCloudErrorAlert = true
                    case .temporarilyUnavailable:
                        icloudErrorMessage = "iCloud is temporarily unavailable."
                        showiCloudErrorAlert = true
                    @unknown default:
                        showRestartAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isChecking = false
                    icloudErrorMessage = NSLocalizedString("network_error", comment: "") + "\n(\(error.localizedDescription))"
                    showiCloudErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
#endif
