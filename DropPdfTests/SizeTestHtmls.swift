import Foundation
import XCTest
import Testing
@testable import DropPdf

struct SizeTestHtmls {
    let testFolder: URL = {
        return URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestFiles/htmls")
    }()

    let expectedSizes: [String: Int] = [
        "htmTest": 24113,
        "standalone": 13969,
        "wiki": 616557
    ]

    @Test func testProcess_standalone() async throws {
        try await runTest(for: "standalone.html")
    }
    
    @Test func testProcess_wiki() async throws {
        try await runTest(for: "wiki.html")
    }

    @Test func testProcess_htmTest() async throws {
        try await runTest(for: "htmTest.html")
    }
    
    func runTest(for fileName: String) async throws {
        try await TestEachFiles(testFolder: testFolder, expectedSizes: expectedSizes)
            .runProcessTest(for: fileName)
    }
}



