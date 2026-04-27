import SwiftUI
import CloudKit

#if os(macOS)
struct MacProfileView: View {
    @AppStorage("allowPastContinuation") private var allowPastContinuation: Bool = false
    
    @StateObject private var logger = AppLogger.shared
    
    // Manually manage sync state to support fallback
    @State private var isCloudSyncEnabled: Bool = false
    
    @State private var showRestartAlert = false
    @State private var showiCloudErrorAlert = false
    @State private var icloudErrorMessage = ""
    @State private var isChecking = false
    @State private var showResetConfirmation = false
    
    // Cloud Check State
    @State private var isCheckingCloudData = false
    @State private var cloudStatusResult: String?
    
    // App Group Test State
    @State private var appGroupTestResult: String?
    @State private var cloudWriteResult: String?
    @State private var bootstrapResult: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Account Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Account")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("User", systemImage: "person.circle")
                        Divider()
                        Text("Signed in with iCloud")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(DesignSystem.cardBackground)
                    .cornerRadius(10)
                    .shadow(color: DesignSystem.shadowColor, radius: 4, x: 0, y: 2)
                }
                
                // Data Sync Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("data_sync")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    
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
                                    .controlSize(.small)
                                    .padding(.trailing, 8)
                            } else {
                                Toggle("", isOn: $isCloudSyncEnabled)
                                    .labelsHidden()
                                    .onChange(of: isCloudSyncEnabled) {
                                        let newValue = isCloudSyncEnabled
                                        
                                        // Save to BOTH locations to ensure robustness
                                        UserDefaults(suiteName: "group.sdy.tododuck")?.set(newValue, forKey: "isCloudSyncEnabled")
                                        UserDefaults.standard.set(newValue, forKey: "isCloudSyncEnabled")
                                        
                                        if newValue {
                                            checkiCloudStatus()
                                        } else {
                                            showRestartAlert = true
                                        }
                                    }
                                    .toggleStyle(.switch)
                            }
                        }
                    }
                    .padding()
                    .background(DesignSystem.cardBackground)
                    .cornerRadius(10)
                    .shadow(color: DesignSystem.shadowColor, radius: 4, x: 0, y: 2)
                    
                    // Debug features hidden for production
                    /*
                    if isCloudSyncEnabled {
                        // Diagnostic Info and Manual Reset
                        if UserDefaults.standard.bool(forKey: "syncInitializationFailed") {
                            Text("sync_init_failed_message")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                            
                            if let errorMsg = UserDefaults.standard.string(forKey: "syncInitializationError") {
                                Text(errorMsg)
                                    .font(.caption2)
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(.horizontal)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            Label("reset_local_data_button", systemImage: "arrow.clockwise.icloud")
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .padding(.horizontal)
                        
                        // Cloud Data Check Button
                        Button {
                            checkCloudData()
                        } label: {
                            if isCheckingCloudData {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Check Cloud Data", systemImage: "icloud.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .controlSize(.large)
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        if let cloudStatusResult = cloudStatusResult {
                            Text(cloudStatusResult)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // App Group Write Test Button
                        Button {
                            testAppGroupWrite()
                        } label: {
                            Label("Test App Group Access", systemImage: "internaldrive")
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        if let appGroupTestResult = appGroupTestResult {
                            Text(appGroupTestResult)
                                .font(.caption2)
                                .foregroundColor(appGroupTestResult.contains("✅") ? .green : .red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Cloud Write Test Button
                        Button {
                            testCloudWrite()
                        } label: {
                            Label("Test Cloud Write (Direct)", systemImage: "icloud.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        if let cloudWriteResult = cloudWriteResult {
                            Text(cloudWriteResult)
                                .font(.caption2)
                                .foregroundColor(cloudWriteResult.contains("✅") ? .green : .red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Bootstrap Schema Button
                        Button {
                            bootstrapSchema()
                        } label: {
                            Label("Initialize Cloud Schema", systemImage: "hammer.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        if let bootstrapResult = bootstrapResult {
                            Text(bootstrapResult)
                                .font(.caption2)
                                .foregroundColor(bootstrapResult.contains("✅") ? .green : .red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Text("reset_data_description")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Debug Info (Hidden by default, useful for troubleshooting)
                        DisclosureGroup("Advanced Debug Info") {
                            VStack(alignment: .leading, spacing: 4) {
                                Group {
                                    Text("Store Path:")
                                        .font(.caption2)
                                        .bold()
                                    Text(UserDefaults.standard.string(forKey: "debug_storePath") ?? "Unknown")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text("Cloud Enabled (App Init):")
                                        Spacer()
                                        Text(UserDefaults.standard.bool(forKey: "debug_isCloudEnabled") ? "YES" : "NO")
                                    }
                                    .font(.caption2)
                                    
                                    HStack {
                                        Text("Environment:")
                                        Spacer()
                                        Text("Development") // Usually Xcode builds are Dev
                                            .foregroundColor(.orange)
                                    }
                                    .font(.caption2)
                                    
                                    Text("Note: Development builds cannot sync with App Store (Production) builds.")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .padding(.top, 4)
                                }
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    */
                }
                
                // Preferences Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("preferences")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("allow_past_continuation")
                            Spacer()
                            Toggle("", isOn: $allowPastContinuation)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.cardBackground)
                    .cornerRadius(10)
                    .shadow(color: DesignSystem.shadowColor, radius: 4, x: 0, y: 2)
                }
                
                // App Info Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("app_info")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    
                    HStack {
                        Text("version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(DesignSystem.cardBackground)
                    .cornerRadius(10)
                    .shadow(color: DesignSystem.shadowColor, radius: 4, x: 0, y: 2)
                }
                
                // Debug Logs Section - Hidden for production
                /*
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Debug Logs")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Clear") {
                            logger.clear()
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                    }
                    .padding(.leading, 4)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(logger.logs, id: \.timestamp) { log in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(log.level.icon)
                                        .font(.system(size: 12))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(log.message)
                                            .font(.caption)
                                            .textSelection(.enabled)
                                        Text("\(log.timestamp.formatted(date: .omitted, time: .standard))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(8)
                                .background(log.level.color.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 400)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: DesignSystem.shadowColor, radius: 4, x: 0, y: 2)
                }
                */
            }
            .padding()
            .frame(maxWidth: 600) // Limit width for better look
            .frame(maxWidth: .infinity, alignment: .center) // Center horizontally
            .padding(.horizontal)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(DesignSystem.background)
        .navigationTitle("Profile")
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
        .confirmationDialog("reset_local_data_confirmation_title", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("reset_confirm", role: .destructive) {
                resetLocalData()
            }
            Button("cancel", role: .cancel) {}
        } message: {
            Text("reset_local_data_confirmation_message")
        }
        .onAppear {
            // Load sync state from Standard Defaults only to avoid App Group crashes
            // let groupDefaults = UserDefaults(suiteName: "group.sdy.tododuck")
            // let groupSync = groupDefaults?.bool(forKey: "isCloudSyncEnabled") ?? false
            let standardSync = UserDefaults.standard.bool(forKey: "isCloudSyncEnabled")
            isCloudSyncEnabled = standardSync // || groupSync
        }
    }
    
    private func checkiCloudStatus() {
        isChecking = true
        
        Task {
            do {
                let status = try await CKContainer(identifier: "iCloud.sdy.tododuck").accountStatus()
                await MainActor.run {
                    isChecking = false
                    
                    switch status {
                    case .available:
                        print("✅ iCloud Validated")
                        icloudErrorMessage = ""
                        showiCloudErrorAlert = false
                    case .noAccount:
                        icloudErrorMessage = "No iCloud account found. Please sign in to iCloud in System Settings."
                        showiCloudErrorAlert = true
                        isCloudSyncEnabled = false
                    case .restricted:
                        icloudErrorMessage = "iCloud access is restricted on this device."
                        showiCloudErrorAlert = true
                        isCloudSyncEnabled = false
                    case .couldNotDetermine:
                        icloudErrorMessage = "Could not determine iCloud status. Please try again later."
                        showiCloudErrorAlert = true
                        isCloudSyncEnabled = false
                    case .temporarilyUnavailable:
                        icloudErrorMessage = "iCloud is temporarily unavailable. Please try again later."
                        showiCloudErrorAlert = true
                        isCloudSyncEnabled = false
                    @unknown default:
                        icloudErrorMessage = "Unknown iCloud status."
                        showiCloudErrorAlert = true
                        isCloudSyncEnabled = false
                    }
                }
            } catch {
                await MainActor.run {
                    isChecking = false
                    icloudErrorMessage = "iCloud check failed: \(error.localizedDescription)"
                    showiCloudErrorAlert = true
                    isCloudSyncEnabled = false
                }
            }
        }
    }
    
    private func resetLocalData() {
        // Warning: This is a destructive operation
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.sdy.tododuck") {
            let rootSharedStoreV7URL = containerURL.appendingPathComponent("TodoDuckShared_v7.store")
            cleanupFiles(at: rootSharedStoreV7URL)
            let rootSharedStoreV5URL = containerURL.appendingPathComponent("TodoDuckShared_v5.store")
            cleanupFiles(at: rootSharedStoreV5URL)
            let rootSharedStoreURL = containerURL.appendingPathComponent("TodoDuckShared.store")
            cleanupFiles(at: rootSharedStoreURL)

            // 1. Clean up old manual paths
            let oldStoreURL = containerURL.appendingPathComponent("To-Do-Duck.sqlite")
            cleanupFiles(at: oldStoreURL)
            
            // 2. Clean up new SwiftData managed paths
            // SwiftData with groupContainer typically uses Library/Application Support/Shared.store
            // We should try to clean up the directory to be safe
            let appSupportURL = containerURL.appendingPathComponent("Library/Application Support")
            
            // Delete specific stores first
            let newStoreURL = appSupportURL.appendingPathComponent("Shared.store")
            cleanupFiles(at: newStoreURL)
            let defaultStoreURL = appSupportURL.appendingPathComponent("default.store")
            cleanupFiles(at: defaultStoreURL)
            let sharedStoreURL = appSupportURL.appendingPathComponent("TodoDuckShared.store")
            cleanupFiles(at: sharedStoreURL)
            let sharedStoreV5URL = appSupportURL.appendingPathComponent("TodoDuckShared_v5.store")
            cleanupFiles(at: sharedStoreV5URL)
            let sharedStoreV7URL = appSupportURL.appendingPathComponent("TodoDuckShared_v7.store")
            cleanupFiles(at: sharedStoreV7URL)
            let sandboxStoreURL = appSupportURL.appendingPathComponent("TodoDuck_Sandbox.store")
            cleanupFiles(at: sandboxStoreURL)
            let sandboxStoreV5URL = appSupportURL.appendingPathComponent("TodoDuck_Sandbox_v5.store")
            cleanupFiles(at: sandboxStoreV5URL)
            
            // 3. Clean up App Group paths (CRITICAL for Widget Sync)
            if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.sdy.tododuck") {
                let groupAppSupportURL = groupURL.appendingPathComponent("Library/Application Support")
                let groupSharedStoreURL = groupAppSupportURL.appendingPathComponent("TodoDuckShared.store")
                cleanupFiles(at: groupSharedStoreURL)
                let groupSharedStoreV5URL = groupAppSupportURL.appendingPathComponent("TodoDuckShared_v5.store")
                cleanupFiles(at: groupSharedStoreV5URL)
                let groupSharedStoreV7URL = groupAppSupportURL.appendingPathComponent("TodoDuckShared_v7.store")
                cleanupFiles(at: groupSharedStoreV7URL)
                let groupDefaultStoreURL = groupAppSupportURL.appendingPathComponent("default.store")
                cleanupFiles(at: groupDefaultStoreURL)
                
                // Clean extra files in Group Container
                do {
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: groupAppSupportURL.path) {
                        let contents = try fileManager.contentsOfDirectory(at: groupAppSupportURL, includingPropertiesForKeys: nil)
                        for fileURL in contents {
                            if fileURL.pathExtension == "store" || fileURL.pathExtension == "sqlite" || fileURL.pathExtension == "sqlite-wal" || fileURL.pathExtension == "sqlite-shm" {
                                try? fileManager.removeItem(at: fileURL)
                                print("✅ Deleted Group file: \(fileURL.lastPathComponent)")
                            }
                        }
                    }
                } catch {
                    print("⚠️ Error scanning Group App Support: \(error)")
                }
                
                do {
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: groupAppSupportURL.path) {
                        let contents = try fileManager.contentsOfDirectory(at: groupAppSupportURL, includingPropertiesForKeys: nil)
                        for fileURL in contents {
                            let name = fileURL.lastPathComponent.lowercased()
                            if name.contains("cloudkit") {
                                try? fileManager.removeItem(at: fileURL)
                                print("✅ Deleted Group CloudKit file: \(fileURL.lastPathComponent)")
                            }
                        }
                    }
                } catch {
                    print("⚠️ Error scanning Group App Support: \(error)")
                }
            }
            
            // Try to clean up .sqlite files in the root of App Support as well (just in case)
            do {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: appSupportURL.path) {
                    let contents = try fileManager.contentsOfDirectory(at: appSupportURL, includingPropertiesForKeys: nil)
                    for fileURL in contents {
                        if fileURL.pathExtension == "store" || fileURL.pathExtension == "sqlite" || fileURL.pathExtension == "sqlite-wal" || fileURL.pathExtension == "sqlite-shm" {
                            try? fileManager.removeItem(at: fileURL)
                            print("✅ Deleted extra file: \(fileURL.lastPathComponent)")
                        }
                    }
                }
            } catch {
                print("⚠️ Error scanning App Support: \(error)")
            }
            
            do {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: appSupportURL.path) {
                    let contents = try fileManager.contentsOfDirectory(at: appSupportURL, includingPropertiesForKeys: nil)
                    for fileURL in contents {
                        let name = fileURL.lastPathComponent.lowercased()
                        if name.contains("cloudkit") {
                            try? fileManager.removeItem(at: fileURL)
                            print("✅ Deleted CloudKit file: \(fileURL.lastPathComponent)")
                        }
                    }
                }
            } catch {
                print("⚠️ Error scanning App Support: \(error)")
            }
            
            // Clear flags
            UserDefaults.standard.set(false, forKey: "syncInitializationFailed")
            UserDefaults.standard.removeObject(forKey: "syncInitializationError")
            UserDefaults.standard.removeObject(forKey: "debug_storePath")
            
            // Prompt restart
            showRestartAlert = true
        }
    }
    
    private func checkCloudData() {
        isCheckingCloudData = true
        cloudStatusResult = "Checking..."
        
        let container = CKContainer(identifier: "iCloud.sdy.tododuck")
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                self.isCheckingCloudData = false
                
                if let error = error {
                    self.cloudStatusResult = "❌ Error: \(error.localizedDescription)"
                    return
                }
                
                switch status {
                case .available:
                    self.cloudStatusResult = "✅ CloudKit Available & Account Ready"
                    // 尝试初始化 Schema
                    self.performSchemaInitialization()
                case .noAccount:
                    self.cloudStatusResult = "⚠️ No iCloud Account"
                case .restricted:
                    self.cloudStatusResult = "⚠️ iCloud Restricted"
                case .couldNotDetermine:
                    self.cloudStatusResult = "⚠️ Could Not Determine Status"
                case .temporarilyUnavailable:
                    self.cloudStatusResult = "⚠️ iCloud Temporarily Unavailable"
                @unknown default:
                    self.cloudStatusResult = "⚠️ Unknown Status"
                }
            }
        }
    }
    
    // Helper to trigger Schema initialization
    private func performSchemaInitialization() {
        // SwiftData 初始化时会自动尝试创建 Schema
        // 这里只是为了界面反馈，提示用户如果后台没有表，可以通过这个操作触发
    }
    
    private func testCloudWrite() {
        cloudWriteResult = "ℹ️ Use SwiftData to sync changes."
        // 不再建议直接使用 CloudKit 写入，因为我们使用 SwiftData
        // 这里的逻辑主要是为了确认代码不再被禁用
    }
    
    private func bootstrapSchema() {
        bootstrapResult = "✅ Schema initialization is handled by SwiftData automatically."
        // 提示用户：只要启动 App 且 cloudKitDatabase: .automatic 生效，SwiftData 就会尝试初始化 Schema
        // 这一步由 AppDelegate 在启动时的 ModelContainer 初始化中完成
    }
    
    private func testAppGroupWrite() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.sdy.tododuck") else {
            appGroupTestResult = "❌ Failed to get App Group container URL."
            return
        }
        
        let testFileURL = containerURL.appendingPathComponent("test_write.txt")
        let testContent = "Write test at \(Date())"
        
        do {
            try testContent.write(to: testFileURL, atomically: true, encoding: .utf8)
            // Try reading it back
            let readContent = try String(contentsOf: testFileURL, encoding: .utf8)
            if readContent == testContent {
                appGroupTestResult = "✅ App Group Write/Read Success!\nPath: \(containerURL.path)"
                // Clean up
                try FileManager.default.removeItem(at: testFileURL)
            } else {
                appGroupTestResult = "❌ Write succeeded but read content mismatch."
            }
        } catch {
            appGroupTestResult = "❌ Write Failed: \(error.localizedDescription)"
        }
    }
    
    private func cleanupFiles(at url: URL) {
        let fileManager = FileManager.default
        let path = url.path
        
        do {
            if fileManager.fileExists(atPath: path) {
                try fileManager.removeItem(at: url)
            }
            
            let shmPath = path + "-shm"
            if fileManager.fileExists(atPath: shmPath) {
                try fileManager.removeItem(atPath: shmPath)
            }
            
            let walPath = path + "-wal"
            if fileManager.fileExists(atPath: walPath) {
                try fileManager.removeItem(atPath: walPath)
            }
            print("✅ Successfully cleaned up files at \(url.lastPathComponent)")
        } catch {
            print("❌ Failed to clean up files at \(url.lastPathComponent): \(error)")
        }
    }
}
#endif
