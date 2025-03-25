import Foundation
import XCTest
import Testing
@testable import DropPdf

struct DropPdfTests {

    let testFolder: URL = {
        return URL(fileURLWithPath: #file)
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
        "docx": 730514,
        "doc": 43873
    ]

    @Test func testSimplePass() {
        #expect(true, "✅ This simple test should always pass")
    }

    @Test func testProcess_docx() async throws {
        try await runProcessTest(for: "docx.docx")
    }

    @Test func testSize_docx() throws {
        try runSizeTest(for: "docx")
    }

    @Test func testProcess_rtf() async throws {
        try await runProcessTest(for: "rtf.rtf")
    }

    @Test func testSize_rtf() throws {
        try runSizeTest(for: "rtf")
    }

    @Test func testProcess_txt() async throws {
        try await runProcessTest(for: "txt.txt")
    }

    @Test func testSize_txt() throws {
        try runSizeTest(for: "txt")
    }

    @Test func testProcess_png() async throws {
        try await runProcessTest(for: "png.png")
    }

    @Test func testSize_png() throws {
        try runSizeTest(for: "png")
    }

    @Test func testProcess_jpg() async throws {
        try await runProcessTest(for: "jpg.jpg")
    }

    @Test func testSize_jpg() throws {
        try runSizeTest(for: "jpg")
    }

    @Test func testProcess_rtfd() async throws {
        try await runProcessTest(for: "rtfd.rtfd")
    }

    @Test func testSize_rtfd() throws {
        try runSizeTest(for: "rtfd")
    }

    @Test func testProcess_md() async throws {
        try await runProcessTest(for: "md.md")
    }

    @Test func testSize_md() throws {
        try runSizeTest(for: "md")
    }

    @Test func testProcess_pdf() async throws {
        try await runProcessTest(for: "pdf.pdf")
    }

    @Test func testSize_pdf() throws {
        try runSizeTest(for: "pdf")
    }

    @Test func testProcess_py() async throws {
        try await runProcessTest(for: "py.py")
    }

    @Test func testSize_py() throws {
        try runSizeTest(for: "py")
    }

    @Test func testProcess_doc() async throws {
        try await runProcessTest(for: "doc.doc")
    }

    @Test func testSize_doc() throws {
        try runSizeTest(for: "doc")
    }

    // MARK: - Shared Logic

    private func runProcessTest(for fileName: String) async throws {
        let processFile = ProcessFile()
        let appDelegate = AppDelegate()
        let fileURL = testFolder.appendingPathComponent(fileName)
        let result = await processFile.processDroppedFiles([fileURL], appDelegate)
        let success = result[fileURL] ?? false
        #expect(success, "❌ Failed to process file: \(fileName)")
    }

    private func runSizeTest(for prefix: String) throws {
        let fileManager = FileManager.default
        let outputFiles = try fileManager.contentsOfDirectory(at: testFolder, includingPropertiesForKeys: nil)
        let pdfRegex = try NSRegularExpression(pattern: "^\(prefix)_[0-9]{8}_[0-9]{6}\\.pdf$")

        guard let matchedFile = outputFiles.first(where: {
            pdfRegex.firstMatch(in: $0.lastPathComponent, range: NSRange($0.lastPathComponent.startIndex..<$0.lastPathComponent.endIndex, in: $0.lastPathComponent)) != nil
        }) else {
            throw XCTSkip("❌ No generated PDF for \(prefix)")
        }

        let attributes = try fileManager.attributesOfItem(atPath: matchedFile.path)
        let fileSize = attributes[.size] as? NSNumber ?? 0
        let expectedSize = expectedSizes[prefix] ?? 0
        #expect(fileSize.isEqual(to: expectedSize), "❌ Size mismatch for \(prefix): expected \(expectedSize), got \(fileSize)")
    }
}
