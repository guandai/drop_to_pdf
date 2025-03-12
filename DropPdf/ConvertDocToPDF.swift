import Cocoa
import PDFKit
import CoreText

func convertDocToPDF(fileURL: URL) async -> Bool {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            guard StringToPdf().getDidStart(fileURL: fileURL) else {
                print("❌ Security-scoped resource access failed: \(fileURL.path)")
                return continuation.resume(returning: false)
            }
            
            
            let docBin = Bundle.main.bundlePath + "/Contents/MacOS/catdoc"
            guard FileManager.default.fileExists(atPath: docBin) else {
                print("❌ bin not found at \(docBin)")
                return continuation.resume(returning: false)
            }

            Task {
                let (success, string) = await RunTask().binTask(fileURL: fileURL, docBin: docBin)
                guard success, !string.isEmpty else {
                    print("❌ Could not extract text from .doc")
                    return continuation.resume(returning: false)
                }


                let result = await StringToPdf().toPdf(string: string, fileURL: fileURL);
                return continuation.resume(returning: result)
            }
        }
    }
}

class RunTask: @unchecked Sendable {
    func binTask(fileURL: URL, docBin: String) async -> (Bool, String) {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: docBin)
                task.arguments = [fileURL.path]

                let outputPipe = Pipe()
                let errorPipe = Pipe()
                task.standardOutput = outputPipe
                task.standardError = errorPipe
                
                do {
                    try task.run()
                } catch {
                    print("❌ Failed to run process: \(error), File: \(fileURL.path)")
                    continuation.resume(returning: (false, ""))
                    return
                }
           
                task.terminationHandler = { _ in
                    let (outputString, errorString) = self.getOutString(outputPipe, errorPipe)
                    if task.terminationStatus != 0 {
                        print("❌ bin failed with exit code \(task.terminationStatus), File: \(fileURL.path)")
                        continuation.resume(returning: (false, errorString))
                    } else {
                        print("✅ Process completed successfully for file: \(fileURL.path)")
                        continuation.resume(returning: (true, outputString))
                    }
                }
            }
        }
    }

    nonisolated func getOutString(_ outputPipe: Pipe, _ errorPipe: Pipe) -> (String, String) {
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let outputString = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let errorString = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return (outputString, errorString)
    }
}
