import Cocoa
import PDFKit

func convertTxtToPDF(fileURL: URL, appDelegate: AppDelegate) async -> Bool  {

    return await withCheckedContinuation { continuation in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard getDidStart(fileURL: fileURL) else {
                print("❌ Security-scoped resource access failed: \(fileURL.path)")
                continuation.resume(returning: false)
                return
            }
            
            var string = "";
            do {
                string = try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                print("❌ ERROR: Failed to read text file, Error: \(error)")
                continuation.resume(returning: false)
                return
            }
            
            Task {
                let result = await StringImgToPDF().toPdf(string: string, images:[], fileURL: fileURL);
                continuation.resume(returning: result)
                return
            }
        }
    }
}
