//
//  MountedListView.swift
//  LocalFileServerExample
//
//  Created by ChargeON on 2024/11/1.
//

import SwiftUI
import LocalFileServer

struct MountedListView: View {
    @Binding var isPresented: Bool // 用于控制 Sheet 显示状态
    @ObservedObject var server: LocalFileServer

    var body: some View {
        NavigationView {
            List {
                ForEach(Array(server.mountedDirectories.keys), id: \.self) { path in
                    HStack {
                        Text("路徑: \(path)")
                        Spacer()
                        Button(action: {
                            server.unmountDirectory(path) // 移除挂载的目录
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("已掛載的目錄")
            .navigationBarItems(trailing: Button("關閉") {
                isPresented = false
            })
        }
    }
}

struct MountedListView_Previews: PreviewProvider {
    @State static var isPresented = true
    
    // 創建一個示例的 LocalFileServer 對象並添加一些掛載資料
    static var server: LocalFileServer = {
        let server = LocalFileServer()
        server.mountDirectory(URL(fileURLWithPath: "/Users/Example/Documents"), atPath: "/documents")
        server.mountDirectory(URL(fileURLWithPath: "/Users/Example/Downloads"), atPath: "/downloads")
        return server
    }()

    static var previews: some View {
        MountedListView(isPresented: $isPresented, server: server)
    }
}
