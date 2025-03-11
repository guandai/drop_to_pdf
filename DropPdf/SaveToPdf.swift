import Cocoa
import PDFKit
import UniformTypeIdentifiers

func saveToPdf(pdfContext: CGContext, fileURL: URL, pdfData: Data) async -> Bool {
    return await withCheckedContinuation { continuation in

        pdfContext.endPage()
        pdfContext.closePDF()

        // 🔹 Generate timestamped name
        let originalName = fileURL.deletingPathExtension().lastPathComponent
        let newName = NameMod.getTimeName(name: originalName)  // e.g. "photo_20250311_1430.pdf"

        do {
            // 🔹 Default save location (same directory as original file)
            var finalPath = fileURL.deletingLastPathComponent().appendingPathComponent(newName)

            if PermissionsManager().isAppSandboxed() {
                Task { @MainActor in  // ✅ Ensure this runs on the main thread
                    let savePanel = NSSavePanel()
                    savePanel.title = "Save PDF File"
                    savePanel.allowedContentTypes = [UTType.pdf]  // ✅ Updated from deprecated allowedFileTypes
                    savePanel.nameFieldStringValue = newName

                    // ✅ Run on main thread
                    let response = savePanel.runModal()
                    if response == .OK, let selectedURL = savePanel.url {
                        finalPath = selectedURL
                    } else {
                        print("❌ User canceled save operation")
                        continuation.resume(returning: false)
                        return
                    }

                    do {
                        try pdfData.write(to: finalPath, options: .atomic)
                        print("✅ Successfully saved PDF to: \(finalPath.path)")
                        continuation.resume(returning: true)
                    } catch {
                        print("❌ ERROR: Failed to save PDF, Error: \(error)")
                        continuation.resume(returning: false)
                    }
                }
                return  // ✅ Prevents function from continuing execution before user interaction completes
            }

            // 🚀 Save normally if not sandboxed
            try pdfData.write(to: finalPath, options: .atomic)
            print("✅ Successfully saved PDF to: \(finalPath.path)")
            continuation.resume(returning: true)

        } catch {
            print("❌ ERROR: Failed to save PDF, Error: \(error)")
            continuation.resume(returning: false)
        }
    }
}
