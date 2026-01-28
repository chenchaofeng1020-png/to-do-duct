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
                DesignSystem.creamBackground
                    .ignoresSafeArea()
                
                List {
                    Section(header: Text("data_sync")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "icloud.fill")
                                    .foregroundColor(isCloudSyncEnabled ? .blue : .gray)
                                    .font(.system(size: 22))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("icloud_sync")
                                        .font(.headline)
                                    Text("icloud_sync_desc")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if isChecking {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                } else {
                                    Toggle("", isOn: $isCloudSyncEnabled)
                                        .labelsHidden()
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
                            
                            // 显示当前实际状态提示
                            // 移除静态的"重启生效"提示，避免误导用户
                            // 状态切换时已通过 Alert 提示重启

                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(DesignSystem.cardBackground)
                    
                    Section(header: Text("preferences")) {
                        Toggle("allow_past_continuation", isOn: $allowPastContinuation)
                    }
                    .listRowBackground(DesignSystem.cardBackground)
                    
                    Section(header: Text("about")) {
                        HStack {
                            Text("version")
                            Spacer()
                            Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                                .foregroundColor(.secondary)
                        }
                    }
                    .listRowBackground(DesignSystem.cardBackground)
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
    
    private func checkiCloudStatus() {
        isChecking = true
        
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                isChecking = false
                
                if let error = error {
                    icloudErrorMessage = NSLocalizedString("network_error", comment: "") + "\n(\(error.localizedDescription))"
                    showiCloudErrorAlert = true
                    return
                }
                
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
        }
    }
}

#Preview {
    ProfileView()
}
#endif
