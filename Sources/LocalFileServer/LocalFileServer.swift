//
//  LocalFileServer.swift
//
//
//  Created by ChargeON on 2024/11/1.
//

import Foundation
import Network
import UniformTypeIdentifiers

public class LocalFileServer: ObservableObject {
    @Published public private(set) var isRunning: Bool = false // 公開只讀的伺服器狀態
    @Published public private(set) var mountedDirectories: [String: URL] = [:] // 公開掛載的目錄，僅可讀

    private var listener: NWListener?
    private let bufferSize: Int
    public init(bufferSize: Int = 1024) {
        self.bufferSize = bufferSize
    }

    public func startServer(port: UInt16 = 80) throws {
        guard !isRunning else {
            print("Server is already running")
            return
        }

        do {
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            listener?.stateUpdateHandler = { [weak self] newState in
                switch newState {
                case .ready:
                    self?.isRunning = true
                    print("Server running on port \(port)")
                case .failed(let error):
                    self?.isRunning = false
                    print("Failed to start server: \(error.localizedDescription)")
                case .cancelled:
                    self?.isRunning = false
                    print("Server stopped")
                default:
                    break
                }
            }
            listener?.newConnectionHandler = { [weak self] newConnection in
                self?.handleNewConnection(newConnection)
            }
            listener?.start(queue: DispatchQueue(label: "LocalFileServer.listener.queue", qos: .background))
        } catch {
            throw LocalFileServerError.serverStartFailed(error)
        }
    }

    public func stopServer() {
        guard isRunning else {
            print("Server is not running")
            return
        }
        listener?.cancel()
    }

    public func mountDirectory(_ directory: URL, atPath path: String) {
        mountedDirectories[path] = directory
    }

    public func unmountDirectory(_ path: String) {
        mountedDirectories.removeValue(forKey: path)
    }

    private func handleNewConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Client connected: \(connection.endpoint)")
                // 設定連接超時機制，避免空連接佔用資源
                DispatchQueue.global().asyncAfter(deadline: .now() + 60) {
                    if connection.state == .ready {
                        connection.cancel()
                    }
                }
                self?.receiveRequest(on: connection)
            case .failed(let error):
                print("Client connection failed: \(error.localizedDescription)")
            default:
                break
            }
        }
        connection.start(queue: DispatchQueue(label: "LocalFileServer.connection.queue", qos: .background))
    }

    private func receiveRequest(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: bufferSize) { [weak self] data, _, isComplete, error in
            defer { if isComplete || error != nil { connection.cancel() } } // 自动释放连接

            guard let self = self else { return }

            if let data = data, !data.isEmpty, let request = String(data: data, encoding: .utf8) {
                print("[\(Date())] Request received: \(request)")
                self.handleRequest(request, on: connection)
            } else if let error = error {
                print("Receive error: \(error.localizedDescription)")
            } else if !isComplete {
                DispatchQueue.global(qos: .background).async {
                    self.receiveRequest(on: connection) // 继续接收数据
                }
            }
        }
    }

    internal func handleRequest(_ request: String, on connection: NWConnection) {
        let requestComponents = request.split(separator: " ")
        guard requestComponents.count >= 2 else {
            Task {
                await sendResponse(status: HTTPStatus.badRequest.rawValue, headers: ["Content-Type": "text/plain"], body: Data("Bad Request".utf8), on: connection)
            }
            return
        }

        let method = requestComponents[0]
        let path = String(requestComponents[1])

        guard method == "GET" else {
            Task {
                await sendResponse(status: HTTPStatus.methodNotAllowed.rawValue, headers: ["Content-Type": "text/plain"], body: Data("Method Not Allowed".utf8), on: connection)
            }
            return
        }

        Task {
            do {
                let (headers, body, status) = try await serveFile(for: path)
                await sendResponse(status: status, headers: headers, body: body, on: connection)
            } catch {
                await sendResponse(status: HTTPStatus.internalServerError.rawValue, headers: ["Content-Type": "text/plain"], body: Data("Internal Server Error".utf8), on: connection)
            }
        }
    }

    internal func serveFile(for path: String) async throws -> (headers: [String: String], body: Data, status: String) {
        guard let fileURL = getFileURL(for: path),
              let fileData = try? Data(contentsOf: fileURL)
        else {
            return (["Content-Type": "text/plain"], Data("File not found".utf8), HTTPStatus.notFound.rawValue)
        }
        let contentType = determineContentType(for: fileURL.path)
        return (["Content-Type": contentType], fileData, HTTPStatus.ok.rawValue)
    }

    internal func getFileURL(for requestPath: String) -> URL? {
        guard let decodedPath = requestPath.removingPercentEncoding else { return nil }

        // 將請求路徑分割為組件
        var pathComponents = decodedPath.split(separator: "/")
        // 如果只有一个路径组件，并且根目录已挂载，直接返回根目录下的文件路径
        if pathComponents.count == 1, let rootDirectory = mountedDirectories["/"] {
            return rootDirectory.appendingPathComponent(String(pathComponents[0]))
        }
        // 從最長路徑開始匹配，逐步減少組件數
        while !pathComponents.isEmpty {
            // 重新組合當前要嘗試的掛載路徑
            let currentPath = "/" + pathComponents.joined(separator: "/")

            // 如果找到匹配的掛載目錄，則構建並返回完整文件 URL
            if let directory = mountedDirectories[currentPath] {
                let relativePath = decodedPath.dropFirst(currentPath.count)
                return directory.appendingPathComponent(String(relativePath))
            }

            // 移除最後一個組件，進行上一層級的路徑匹配
            pathComponents.removeLast()
        }

        // 沒有匹配的掛載路徑則返回 nil
        return nil
    }

    private func determineContentType(for path: String) -> String {
        let fileExtension = (path as NSString).pathExtension
        if let utType = UTType(filenameExtension: fileExtension), let mimeType = utType.preferredMIMEType {
            return mimeType
        } else {
            return "application/octet-stream"
        }
    }

    internal func httpResponse(status: String, headers: [String: String], body: Data) -> Data {
        var responseString = "HTTP/1.1 \(status)\r\n"
        for (header, value) in headers {
            responseString += "\(header): \(value)\r\n"
        }
        responseString += "Content-Length: \(body.count)\r\n"
        responseString += "\r\n"
        var responseData = Data(responseString.utf8)
        responseData.append(body)
        return responseData
    }

    private func sendResponse(status: String, headers: [String: String], body: Data, on connection: NWConnection) async {
        let response = httpResponse(status: status, headers: headers, body: body)
        do {
            try await connection.send(content: response)
        } catch {
            print("Send error: \(error.localizedDescription)")
        }
        connection.cancel()
    }
}
