import Foundation
import SwiftData
import CloudKit

struct DiagnosticsService {
    /// 生成详细的系统诊断报告
    static func generateReport(appGroupID: String, storeURL: URL?) -> String {
        var logs = ["\n🔍 ========== SWIFTDATA DIAGNOSTICS REPORT =========="]
        
        // 1. 基础环境信息
        logs.append("📅 Timestamp: \(Date())")
        logs.append("📦 App Group ID: \(appGroupID)")
        
        // 2. App Group 路径与权限检查
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            logs.append("✅ App Group URL Found: \(containerURL.path)")
            
            // 检查写权限
            let testFile = containerURL.appendingPathComponent("diag_write_test.tmp")
            do {
                try "test".write(to: testFile, atomically: true, encoding: .utf8)
                try FileManager.default.removeItem(at: testFile)
                logs.append("✅ Write Permission: GRANTED")
            } catch {
                logs.append("❌ Write Permission: DENIED (\(error.localizedDescription))")
            }
            
            // 3. 文件列表扫描
            logs.append("\n📂 Directory Contents:")
            do {
                let files = try FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
                if files.isEmpty {
                    logs.append("   (Empty Directory)")
                } else {
                    for file in files {
                        let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                        let name = file.lastPathComponent
                        // 标记出关键数据库文件
                        let marker = name.contains(".store") ? "💾 " : "📄 "
                        logs.append("   \(marker)\(name) (\(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)))")
                    }
                }
            } catch {
                logs.append("❌ Failed to list directory: \(error.localizedDescription)")
            }
        } else {
            logs.append("❌ App Group URL NOT FOUND! Check Entitlements.")
        }
        
        // 4. 目标 Store URL 检查
        if let storeURL = storeURL {
            logs.append("\n🎯 Target Store URL: \(storeURL.path)")
            let exists = FileManager.default.fileExists(atPath: storeURL.path)
            logs.append("   File Exists: \(exists)")
        }
        
        // 5. CloudKit 账户状态 (尝试同步检查)
        // 注意：这是异步的，在 crash 前可能无法立即获取，但值得尝试打印当前已知状态
        // 实际开发中只能提示用户自行检查，代码里无法在此处阻塞太久
        logs.append("\n☁️ CloudKit Note:")
        logs.append("   Ensure you are signed into iCloud and have iCloud Drive enabled.")
        logs.append("   Verify 'iCloud.sdy.tododuck' is checked in System Settings > iCloud > Apps Using iCloud.")
        
        logs.append("==================================================\n")
        return logs.joined(separator: "\n")
    }
}
