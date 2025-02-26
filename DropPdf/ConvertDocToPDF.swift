import Cocoa
import PDFKit

func convertDocToPDF(fileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            // 1️⃣ Locate `antiword` in the app bundle
            guard let docBin = Bundle.main.path(forResource: "antiword", ofType: "") else {
                print("❌ antiword not found in Resources")
                continuation.resume(returning: false)
                return
            }

            // 2️⃣ Ensure execute permissions are set
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: docBin)
                if let permissions = attributes[.posixPermissions] as? NSNumber, (permissions.uint16Value & 0o111) == 0 {
                    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: docBin)
                    print("✅ Executable permissions set for antiword")
                }
            } catch {
                print("❌ Failed to set execute permissions for antiword: \(error)")
                continuation.resume(returning: false)
                return
            }

            let task = Process()
            task.launchPath = docBin
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
                    continuation.resume(returning: false)
                    return
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

                // ✅ Move continuation.resume **outside** of `Task`
                let immutablePdfData = pdfData as Data
                Task {
                    let success = await saveToPdf(pdfContext: pdfContext, fileURL: fileURL, pdfData: immutablePdfData)
                    DispatchQueue.main.async {
                        continuation.resume(returning: success)
                    }
                }
                
            } catch {
                print("❌ Error running antiword: \(error)")
                continuation.resume(returning: false)
            }
        }
    }
}
