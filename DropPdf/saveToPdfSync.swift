import Cocoa
import PDFKit
import UniformTypeIdentifiers

func saveToPdfSync(fileURL: URL, pdfData: Data) -> Bool {
    do {
        let originalName = fileURL.deletingPathExtension().lastPathComponent
        let newName = NameMod.getTimeName(name: originalName)  // e.g. "photo_20250311_1430.pdf"
        var finalPath = fileURL.deletingLastPathComponent().appendingPathComponent(newName)

        if PermissionsManager().isAppSandboxed() {
            var userSelectedPath: URL? = nil
            DispatchQueue.main.sync {  // ✅ Run on main thread
                let savePanel = NSSavePanel()
                savePanel.title = "Save PDF File"
                savePanel.allowedContentTypes = [UTType.pdf]  
                savePanel.nameFieldStringValue = newName

                if savePanel.runModal() == .OK {
                    userSelectedPath = savePanel.url
                }
            }

            guard let selectedURL = userSelectedPath else {
                print("❌ User canceled save operation")
                return false
            }
            finalPath = selectedURL
        }

        try pdfData.write(to: finalPath, options: .atomic)
        print("✅ Successfully saved PDF to: \(finalPath.path)")
        return true

    } catch {
        print("❌ ERROR: Failed to save PDF, Error: \(error)")
        return false
    }
}
