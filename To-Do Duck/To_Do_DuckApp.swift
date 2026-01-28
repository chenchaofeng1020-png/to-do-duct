//
//  To_Do_DuckApp.swift
//  To-Do Duck
//
//  Created by 朝峰 chen on 2026/1/8.
//

import SwiftUI
import SwiftData
import CloudKit // Ensure this is imported for CKError handling

@main
struct To_Do_DuckApp: App {


    static var sharedModelContainer: ModelContainer = {
        print("🚀 Starting To-Do Duck App...")
        
        // 读取用户云同步设置（默认关闭）
        // 优先使用 App Group，如果不可用（如 macOS App Group 配置问题），降级使用标准 UserDefaults
        let groupDefaults = UserDefaults(suiteName: "group.sdy.tododuck")
        
        let groupSync = groupDefaults?.bool(forKey: "isCloudSyncEnabled") ?? false
        let standardSync = UserDefaults.standard.bool(forKey: "isCloudSyncEnabled")
        
        // 只要任一处开启，即视为开启
        // ✅ 已修复：entitlements 配置完整，默认关闭云同步
        let isCloudSyncEnabled = groupSync || standardSync
        
        // Use .automatic to let SwiftData infer the container from entitlements
        // This avoids mismatches between hardcoded strings and the entitlements file
        let cloudKitMode: ModelConfiguration.CloudKitDatabase = isCloudSyncEnabled ? .automatic : .none
        print("☁️ Cloud Sync Preference: \(isCloudSyncEnabled ? "Enabled" : "Disabled") (Group: \(groupSync), Std: \(standardSync))")
        
        // Force rebuild trigger: CloudKit Sync Restored
        let schema = Schema([
            DailyCardV3.self,
            TodoItemV3.self,
            MemoCardV3.self,
        ])
        print("📦 Schema created")

        // 1. 尝试 App Group 存储 (标准路径)
        print("1️⃣ Attempting App Group Storage (Managed by SwiftData)...")
        
        let appGroupID = "group.sdy.tododuck"
        let storeURL: URL
        
        // 🚨 极端调试模式：强制禁用 App Group，只使用沙盒 Documents
        // 如果这样能启动，说明 App Group 权限坏了
        let forceSandbox = false
        
        if !forceSandbox, let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            print("🔍 App Group URL Found: \(containerURL.path)")
            // 🆕 升级到 v9 以确保使用全新的数据库文件，避免历史文件损坏的影响
            storeURL = containerURL.appendingPathComponent("TodoDuckShared_v9.store")
        } else {
            print("⚠️ App Group disabled or not found. Using Sandbox Documents Directory.")
            storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("TodoDuckLocal_v9.store")
        }
        
        // 🚨 强制清理：已注释，恢复数据持久化
        // try? FileManager.default.removeItem(at: storeURL)
        // try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
        // try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
        
        UserDefaults.standard.set(storeURL.path, forKey: "debug_storePath")
        UserDefaults.standard.set(isCloudSyncEnabled, forKey: "debug_isCloudEnabled")
        UserDefaults.standard.set(false, forKey: "syncInitializationFailed")
        UserDefaults.standard.removeObject(forKey: "syncInitializationError")
        
        func describe(_ error: Error) -> String {
            var msg = "SwiftData 初始化失败\n"
            msg += "Error: \(error.localizedDescription)\n"
            
            let nsError = error as NSError
            msg += "Domain: \(nsError.domain)\nCode: \(nsError.code)\n"
            
            if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                msg += "Underlying: \(underlying.localizedDescription)\n"
                msg += "Underlying Domain: \(underlying.domain)\nUnderlying Code: \(underlying.code)\n"
            }
            
            if let ckError = error as? CKError {
                msg += "CKError Code: \(ckError.code.rawValue)\n"
            }
            
            return msg
        }
        
        func makeConfig(cloudKitDatabase: ModelConfiguration.CloudKitDatabase) -> ModelConfiguration {
            ModelConfiguration(
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: cloudKitDatabase
            )
        }
        
        do {
            print("☁️ Cloud Sync Mode: \(isCloudSyncEnabled ? "Enabled" : "Disabled")")
            let container = try ModelContainer(for: schema, configurations: makeConfig(cloudKitDatabase: cloudKitMode))
            print("✅ Successfully initialized with App Group + CloudKit Mode: \(isCloudSyncEnabled ? "Enabled" : "Disabled")")
            return container
        } catch {
            let errorMsg = describe(error)
            let nsError = error as NSError
            print("❌ SwiftData Initialization Failure (preferred mode): \(error)")
            print("❌ Detailed NSError: \(nsError)")
            print("❌ UserInfo: \(nsError.userInfo)")
            
            // Generate detailed diagnostics report
            let report = DiagnosticsService.generateReport(appGroupID: "group.sdy.tododuck", storeURL: storeURL)
            print(report) // Print to console for copy-paste
            
            UserDefaults.standard.set(true, forKey: "syncInitializationFailed")
            UserDefaults.standard.set("\(errorMsg)\n\nUserInfo: \(nsError.userInfo)\n\n\(report)", forKey: "syncInitializationError")
            
            if isCloudSyncEnabled {
                do {
                    UserDefaults.standard.set(false, forKey: "debug_isCloudEnabled")
                    print("⚠️ CloudKit-enabled store failed. Retrying with local-only configuration...")
                    let container = try ModelContainer(for: schema, configurations: makeConfig(cloudKitDatabase: .none))
                    print("✅ Successfully initialized in local-only mode after CloudKit failure.")
                    return container
                } catch {
                    // 如果连降级都失败，说明是数据文件本身坏了（比如 schema 不匹配）
                    // 此时唯一的办法是清空本地数据，强行复活
                    print("🧨 Critical Failure: Local fallback also failed. Attempting nuclear reset...")
                    
                    // 核弹级重置：删除所有本地数据文件
                    let fileManager = FileManager.default
                    if let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.sdy.tododuck") {
                         try? fileManager.removeItem(at: appGroupURL.appendingPathComponent("TodoDuckShared_v7.store"))
                         try? fileManager.removeItem(at: appGroupURL.appendingPathComponent("TodoDuckShared_v7.store-shm"))
                         try? fileManager.removeItem(at: appGroupURL.appendingPathComponent("TodoDuckShared_v7.store-wal"))
                    }
                    
                    // 最后再试一次纯净启动
                    let freshContainer = try! ModelContainer(for: schema, configurations: makeConfig(cloudKitDatabase: .none))
                    return freshContainer
                }
            } else {
                // 最后一道防线：内存模式
                // 即使所有文件存储都失败，也要让 App 启动起来，显示错误 UI
                print("🧨 Critical Failure: Persistent store failed. Falling back to In-Memory store.")
                let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: memoryConfig)
                } catch {
                     fatalError("Failed to create even in-memory container: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            MainView()
        }
        .windowStyle(.hiddenTitleBar)
        .modelContainer(To_Do_DuckApp.sharedModelContainer)
        #else
        WindowGroup {
            MainView()
        }
        .modelContainer(To_Do_DuckApp.sharedModelContainer)
        #endif
    }
}
