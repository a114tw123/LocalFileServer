//
//  LocalFileServerExampleView.swift
//  LocalFileServerExample
//
//  Created by ChargeON on 2024/11/1.
//

import SwiftUI
import LocalFileServer

struct LocalFileServerExampleView: View {
    @StateObject private var server = LocalFileServer() // 使用 @StateObject 管理伺服器狀態
    @State private var selectedDirectory: URL? = nil // 目前選擇的路徑
    @State private var mountPath: String = "" // 掛載路徑
    @State private var showingFileImporter = false // 控制 FileImporter 顯示
    @State private var showingMountedList = false // 控制已掛載路徑 Sheet 顯示
    @State private var showingWebView = false // 控制 WebView 顯示

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Local Web Server")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                // 啟動/關閉伺服器按鈕
                Button(action: {
                    if server.isRunning {
                        server.stopServer()
                    } else {
                        try? server.startServer()
                    }
                }) {
                    Text(server.isRunning ? "關閉伺服器" : "啟動伺服器")
                        .padding()
                        .background(server.isRunning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                // 文件選擇器按鈕和取得 Bundle 按鈕
                HStack {
                    Button("選擇目錄") {
                        showingFileImporter.toggle()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .fileImporter(
                        isPresented: $showingFileImporter,
                        allowedContentTypes: [.folder],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            selectedDirectory = urls.first
                        case .failure(let error):
                            print("Failed to select directory: \(error.localizedDescription)")
                        }
                    }

                    Button("取得 Bundle 路徑") {
                        selectedDirectory = Bundle.main.bundleURL
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // 顯示選擇的目錄路徑
                if let directory = selectedDirectory {
                    Text("已選擇的目錄: \(directory.path)")
                        .font(.subheadline)
                }

                HStack {
                    // 輸入掛載路徑
                    TextField("輸入掛載路徑（例如 /images）", text: $mountPath)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    // 掛載目錄按鈕
                    Button("掛載目錄") {
                        if let directory = selectedDirectory, !mountPath.isEmpty {
                            let pathToMount = mountPath == "/" ? "/" : mountPath
                            server.mountDirectory(directory, atPath: pathToMount)
                            mountPath = "" // 清空掛載路徑
                        }
                    }
                    .disabled(selectedDirectory == nil || mountPath.isEmpty)
                    .padding()
                    .background(selectedDirectory != nil && !mountPath.isEmpty ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                HStack {
                    // 顯示已掛載的路徑清單按鈕
                    Button("顯示已掛載的目錄") {
                        showingMountedList.toggle()
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    // 顯示 WebView 按鈕
                    Button("顯示 WebView") {
                        showingWebView.toggle()
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .sheet(isPresented: $showingMountedList) {
                MountedListView(isPresented: $showingMountedList, server: server)
            }
            .sheet(isPresented: $showingWebView) {
                WebViewPage()
            }
        }
    }
}

#Preview {
    LocalFileServerExampleView()
}

