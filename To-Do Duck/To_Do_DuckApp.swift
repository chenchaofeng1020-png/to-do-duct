//
//  To_Do_DuckApp.swift
//  To-Do Duck
//
//  Created by 朝峰 chen on 2026/1/8.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct To_Do_DuckApp: App {

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

extension To_Do_DuckApp {
    static var sharedModelContainer: ModelContainer = {
        print("🚀 Starting To-Do Duck App...")
        
        let groupDefaults = UserDefaults(suiteName: "group.sdy.tododuck")
        let groupSync = groupDefaults?.bool(forKey: "isCloudSyncEnabled") ?? false
        let standardSync = UserDefaults.standard.bool(forKey: "isCloudSyncEnabled")
        let isCloudSyncEnabled = groupSync || standardSync
        
        print("☁️ Cloud Sync Preference: \(isCloudSyncEnabled ? "Enabled" : "Disabled") (Group: \(groupSync), Std: \(standardSync))")
        
        let schema = Schema([
            DailyCardV3.self,
            TodoItemV3.self,
            MemoCardV3.self,
            RepeatRule.self,
        ])
        
        print("📦 Schema created")
        
        let appGroupID = "group.sdy.tododuck"
        let storeURL: URL
        
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            print("🔍 App Group URL Found: \(containerURL.path)")
            storeURL = containerURL.appendingPathComponent("TodoDuckShared_v9.store")
        } else {
            print("⚠️ App Group disabled or not found. Using Sandbox Documents Directory.")
            storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("TodoDuckLocal_v9.store")
        }
        
        UserDefaults.standard.set(storeURL.path, forKey: "debug_storePath")
        UserDefaults.standard.set(isCloudSyncEnabled, forKey: "debug_isCloudEnabled")
        
        func makeConfig(cloudKitDatabase: ModelConfiguration.CloudKitDatabase) -> ModelConfiguration {
            ModelConfiguration(
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: cloudKitDatabase
            )
        }
        
        do {
            let cloudKitMode: ModelConfiguration.CloudKitDatabase = isCloudSyncEnabled ? .automatic : .none
            print("☁️ Cloud Sync Mode: \(isCloudSyncEnabled ? "Enabled" : "Disabled")")
            let container = try ModelContainer(for: schema, configurations: makeConfig(cloudKitDatabase: cloudKitMode))
            print("✅ Successfully initialized with App Group + CloudKit Mode: \(isCloudSyncEnabled ? "Enabled" : "Disabled")")
            return container
        } catch {
            print("❌ SwiftData Initialization Failure: \(error)")
            print("⚠️ Falling back to local-only mode...")
            
            do {
                let container = try ModelContainer(for: schema, configurations: makeConfig(cloudKitDatabase: .none))
                print("✅ Successfully initialized in local-only mode.")
                return container
            } catch {
                print("🧨 Critical Failure: \(error)")
                let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: memoryConfig)
                } catch {
                    print("❌ Failed to create in-memory container: \(error)")
                    fatalError("Failed to create even in-memory container: \(error)")
                }
            }
        }
    }()
}
