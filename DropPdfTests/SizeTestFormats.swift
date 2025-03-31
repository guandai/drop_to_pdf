import Foundation
import XCTest
import Testing
@testable import DropPdf

struct SizeTestFormats {
    let testFolder: URL = {
        return URL(fileURLWithPath: NameMod.toFileString(#file))
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestFiles/formats")
    }()
    
    let expectedSizes: [String: Int] = [
        "rtfd": 93427,
        "jpg": 53253,
        "py": 24449,
        "pdf": 1154874,
        "txt": 62768,
        "rtf": 24110,
        "png": 279274,
        "md": 538557,
        "docx": 787834,
        "doc": 43873
    ]
    
    @Test func testProcess_doc() async throws {
        try await runTest(for: "doc.doc")
    }
    
    @Test func testProcess_docx() async throws {
        try await runTest(for: "docx.docx")
    }
    
    @Test func testProcess_rtf() async throws {
        try await runTest(for: "rtf.rtf")
    }
    
    @Test func testProcess_jpg() async throws {
        try await runTest(for: "jpg.jpg")
    }
    
    @Test func testProcess_png() async throws {
        try await runTest(for: "png.png")
    }
    
    @Test func testProcess_txt() async throws {
        try await runTest(for: "txt.txt")
    }
    
    @Test func testProcess_md() async throws {
        try await runTest(for: "md.md")
    }
    
    @Test func testProcess_py() async throws {
        try await runTest(for: "py.py")
    }
    
    @Test func testProcess_pdf() async throws {
        try await runTest(for: "pdf.pdf")
    }
    
    @Test func testProcess_rtfd() async throws {
        try await runTest(for: "rtfd.rtfd")
    }
        
    func runTest(for fileName: String) async throws {
        try await TestEachFiles(testFolder: testFolder, expectedSizes: expectedSizes)
            .runProcessTest(for: fileName)
    }
}
