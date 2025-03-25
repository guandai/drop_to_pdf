import Foundation
import XCTest
import Testing
@testable import DropPdf

struct DropPdfTests {

    @Test func testSimplePass() {
        #expect(true, "✅ This simple test should always pass")
    }

    @Test func testProcessFilesInFormatsFolder() async throws {
        #expect(true, "✅ This simple test should always pass")
        
        let processFile = ProcessFile()
        let appDelegate = AppDelegate()

        let fileManager = FileManager.default
        let testFolder = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestFiles/formats")

        guard fileManager.fileExists(atPath: testFolder.path) else {
           
            throw XCTSkip("❌ Test folder does not exist at: \(testFolder.path)")
        }

        let testFiles = try fileManager.contentsOfDirectory(at: testFolder, includingPropertiesForKeys: nil)
        guard !testFiles.isEmpty else {
            throw XCTSkip("❌ No test files found in \(testFolder.path)")
        }
        
        
        for file in testFiles {
            let attributes = try fileManager.attributesOfItem(atPath: file.path)
            let fileSize = attributes[.size] as? NSNumber
            print("📄 File: \(file.lastPathComponent), Size: \(fileSize?.intValue ?? 0) bytes")
        }
        
        

        let result = await processFile.processDroppedFiles(testFiles, appDelegate)

        for (url, success) in result {
            #expect(success, "❌ Failed to process file: \(url.lastPathComponent)")
        }
    }
}
