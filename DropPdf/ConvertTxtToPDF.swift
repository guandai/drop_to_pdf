import Cocoa
import PDFKit

func convertTxtToPDF(fileURL: URL, appDelegate: AppDelegate) async -> Bool  {

    return await withCheckedContinuation { continuation in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard StringToPdf().getDidStart(fileURL: fileURL) else {
                print("❌ Security-scoped resource access failed: \(fileURL.path)")
                return continuation.resume(returning: false)
            }
            
            var string = "";
            do {
                string = try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                print("❌ ERROR: Failed to read text file, Error: \(error)")
                continuation.resume(returning: false)
            }
            
            Task {
                let result = await StringToPdf().toPdf(string: string, fileURL: fileURL);
                return continuation.resume(returning: result)
            }
        }
    }
}
