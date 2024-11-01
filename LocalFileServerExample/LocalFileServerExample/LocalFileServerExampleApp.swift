//
//  LocalFileServerExampleApp.swift
//  LocalFileServerExample
//
//  Created by ChargeON on 2024/11/1.
//

import SwiftUI

@main
struct LocalFileServerExampleApp: App {
    init() {
        checkAndCreateTestFile()
    }

    var body: some Scene {
        WindowGroup {
            LocalFileServerExampleView()
        }
    }
    
    func checkAndCreateTestFile() {
        // 獲取應用程式的 Documents 資料夾 URL
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("無法找到 Documents 資料夾")
            return
        }

        // 指定檔案名稱和檔案路徑
        let fileName = "test.txt"
        let fileURL = documentsURL.appendingPathComponent(fileName)

        // 檢查檔案是否存在
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            // 如果檔案不存在，則建立它並寫入內容
            let content = "This is a test file."
            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                print("檔案不存在，已成功建立 test.txt 文件在：\(fileURL.path)")
            } catch {
                print("建立 test.txt 文件失敗：\(error.localizedDescription)")
            }
        } else {
            print("test.txt 文件已存在於：\(fileURL.path)")
        }
    }
}
