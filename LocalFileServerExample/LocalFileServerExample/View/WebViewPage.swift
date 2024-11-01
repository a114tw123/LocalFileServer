//
//  WebViewPage.swift
//  LocalFileServerExample
//
//  Created by ChargeON on 2024/11/1.
//

import SwiftUI
import WebKit

// 獨立的 WebView 頁面
struct WebViewPage: View {
    @State private var urlToTest: String = "http://localhost" // 測試 URL

    var body: some View {
        VStack {
            TextField("輸入測試 URL（例如 http://localhost:80/images/test.png）", text: $urlToTest)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            WebView(urlString: urlToTest)
                .frame(height: 300)
                .padding()

            Spacer()
        }
    }
}

// WebView 包裝結構，支援 SwiftUI
struct WebView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

#Preview {
    WebViewPage()
}
