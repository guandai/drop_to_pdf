import Cocoa
import PDFKit

func convertDocToPDF(fileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            // 1️⃣ Locate `antiword` in the app bundle inside Contents/MacOS
            let docBin = Bundle.main.bundlePath + "/Contents/MacOS/antiword"
            
            guard FileManager.default.fileExists(atPath: docBin) else {
                print("❌ antiword not found at \(docBin)")
                return continuation.resume(returning: false)
            }
            
            // 2️⃣ Ensure execute permissions are set
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: docBin)
                if let permissions = attributes[.posixPermissions] as? NSNumber {
                    let permissionValue = permissions.uint16Value
                    if (permissionValue & 0o111) == 0 {
                        // No execute permissions, set them
                        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: docBin)
                        print("✅ Executable permissions set for antiword")
                    }
                }
            } catch {
                print("❌ Failed to check/set permissions for antiword: \(error)")
                return continuation.resume(returning: false)
            }
            
            let task = Process()
            task.executableURL = URL(fileURLWithPath: docBin)
            task.arguments = [fileURL.path]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            do {
                // 3️⃣ Access security-scoped resource if sandboxed
                let didStart = fileURL.startAccessingSecurityScopedResource()
                defer { if didStart { fileURL.stopAccessingSecurityScopedResource() } }
                
                try task.run()
                task.waitUntilExit()
                
                let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let extractedText = String(data: outputData, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                      !extractedText.isEmpty else {
                    print("❌ Could not extract text from .doc")
                    return continuation.resume(returning: false)
                }
                
                // 4️⃣ Create PDF from extracted text
                let pdfData = NSMutableData()
                let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!
                var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
                let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil)!
                
                pdfContext.beginPage(mediaBox: &mediaBox)
                NSGraphicsContext.saveGraphicsState()
                let nsCtx = NSGraphicsContext(cgContext: pdfContext, flipped: false)
                NSGraphicsContext.current = nsCtx
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 12),
                    .paragraphStyle: {
                        let p = NSMutableParagraphStyle()
                        p.alignment = .left
                        return p
                    }()
                ]
                let textRect = CGRect(x: 20, y: 20, width: 555, height: 800)
                NSString(string: extractedText).draw(in: textRect, withAttributes: attributes)
                NSGraphicsContext.restoreGraphicsState()
                
                Task {
                    let immutablePdfData = pdfData as Data
                    let success = await saveToPdf(pdfContext: pdfContext, fileURL: fileURL, pdfData: immutablePdfData)
                    continuation.resume(returning: success)
                }
                
            } catch {
                print("❌ Error running antiword: \(error)")
                return continuation.resume(returning: false)
            }
        }
    }
}
