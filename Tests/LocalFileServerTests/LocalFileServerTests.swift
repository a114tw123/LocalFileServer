import XCTest
import Network
@testable import LocalFileServer

final class LocalFileServerTests: XCTestCase {
    var server: LocalFileServer!
    
    override func setUp() {
        super.setUp()
        server = LocalFileServer(bufferSize: 1024)
    }

    override func tearDown() {
        server.stopServer()
        server = nil
        super.tearDown()
    }
    
    // 測試伺服器的啟動和停止
    func testServerStartAndStop() async throws {
        XCTAssertFalse(server.isRunning, "Server should not be running before start")

        try server.startServer(port: 8080)
        
        // 等待伺服器啟動
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 秒的延遲
        XCTAssertTrue(server.isRunning, "Server should be running after start")
        
        server.stopServer()
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 秒的延遲
        XCTAssertFalse(server.isRunning, "Server should not be running after stop")
    }
    // 測試目錄掛載與解掛
    func testMountAndUnmountDirectory() {
        let testURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TestDirectory")

        server.mountDirectory(testURL, atPath: "/test")
        XCTAssertEqual(server.mountedDirectories["/test"], testURL, "Directory should be mounted at /test")
        
        server.unmountDirectory("/test")
        XCTAssertNil(server.mountedDirectories["/test"], "Directory should be unmounted from /test")
    }
    
    // 測試檔案路徑的 URL 解析
    func testGetFileURL() {
        let testDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TestDirectory")
        server.mountDirectory(testDirectoryURL, atPath: "/test")
        
        let expectedURL = testDirectoryURL.appendingPathComponent("file.txt")
        let fileURL = server.getFileURL(for: "/test/file.txt")
        
        XCTAssertEqual(fileURL, expectedURL, "File URL should be correctly resolved for mounted path")
    }
    
    // 測試 HTTP 回應生成
    func testHttpResponse() {
        let status = "200 OK"
        let headers = ["Content-Type": "text/plain"]
        let body = Data("Hello, World!".utf8)
        
        let response = server.httpResponse(status: status, headers: headers, body: body)
        let responseString = String(data: response, encoding: .utf8)!
        
        XCTAssertTrue(responseString.contains("HTTP/1.1 200 OK"), "Response should contain correct status")
        XCTAssertTrue(responseString.contains("Content-Type: text/plain"), "Response should contain correct headers")
        XCTAssertTrue(responseString.contains("Hello, World!"), "Response should contain the body content")
    }
}
