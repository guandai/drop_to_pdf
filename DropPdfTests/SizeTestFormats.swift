import Foundation
import XCTest
import Testing
@testable import DropPdf

struct SizeTestFormats {

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
        "docx": 787834,
        "doc": 43873
    ]

    @Test func testProcess_doc() async throws {
        try await runProcessTest(for: "doc.doc")
    }
    
    @Test func testProcess_docx() async throws {
        try await runProcessTest(for: "docx.docx")
    }

    @Test func testProcess_rtf() async throws {
        try await runProcessTest(for: "rtf.rtf")
    }
    
    @Test func testProcess_jpg() async throws {
        try await runProcessTest(for: "jpg.jpg")
    }
    
    @Test func testProcess_png() async throws {
        try await runProcessTest(for: "png.png")
    }

    @Test func testProcess_txt() async throws {
        try await runProcessTest(for: "txt.txt")
    }
    
    @Test func testProcess_md() async throws {
        try await runProcessTest(for: "md.md")
    }
    
    @Test func testProcess_py() async throws {
        try await runProcessTest(for: "py.py")
    }
    
    @Test func testProcess_pdf() async throws {
        try await runProcessTest(for: "pdf.pdf")
    }

    @Test func testProcess_rtfd() async throws {
        try await runProcessTest(for: "rtfd.rtfd")
    }

    // MARK: - Shared Logic

    private func runProcessTest(for fileName: String) async throws {
        let processFile = ProcessFile()
        let appDelegate = AppDelegate()
        let fileURL = testFolder.appendingPathComponent(fileName)
        let result = await processFile.processDroppedFiles([fileURL], appDelegate)
        let success = result[fileURL] ?? false
        #expect(success, "❌ Failed to process file: \(fileName)")

        try runSizeTest(for: fileName)
    }

    private func runSizeTest(for prefix: String) throws {
        let fileManager = FileManager.default
        let outputFiles = try fileManager.contentsOfDirectory(at: testFolder, includingPropertiesForKeys: nil)
        
        Thread.sleep(forTimeInterval: 2) // 1 seconds delay
        guard let matchedFile = try getMatechFile(prefix: prefix, outputFiles: outputFiles) else {
            return
        }
        
        try ExpactSize(prefix: prefix, matchedFile: matchedFile)
        try fileManager.removeItem(at: matchedFile)
    }
    
    func getMatechFile(prefix: String, outputFiles: [URL]) throws -> URL? {
        let pdfRegex = try NSRegularExpression(pattern: "^\(prefix)_[0-9]{8}_[0-9]{6}\\.pdf$")
        guard let matchedFile = outputFiles.first(where: {
            pdfRegex.firstMatch(
                in: $0.lastPathComponent,
                range: NSRange($0.lastPathComponent.startIndex..<$0.lastPathComponent.endIndex, in: $0.lastPathComponent)
            ) != nil
        }) else {
            let availableFiles = outputFiles.map { $0.lastPathComponent }.joined(separator: ", ")
            XCTFail("❌ No generated PDF for \(prefix). Available files: [\(availableFiles)]")
            return nil
        }
        return matchedFile
    }

    func ExpactSize(prefix: String, matchedFile: URL) throws {
        let fileManager = FileManager.default
        let expectedSize = expectedSizes[prefix] ?? 0
        var actualSize: NSNumber = 0
        let maxRetries = 3

        for _ in 1...maxRetries {
            let attributes = try fileManager.attributesOfItem(atPath: matchedFile.path)
            if let size = attributes[.size] as? NSNumber {
                actualSize = size
                if actualSize.intValue > 0 {
                    break
                }
            }
            Thread.sleep(forTimeInterval: 0.5) // 0.2 seconds delay
        }
        
        #expect(actualSize.isEqual(to: expectedSize), "❌ Size mismatch for \(prefix): expecte \(expectedSize), got \(actualSize)")
    }
}
