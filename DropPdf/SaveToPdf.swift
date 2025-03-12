import Cocoa
import PDFKit
import UniformTypeIdentifiers

func saveToPdf(fileURL: URL, pdfData: Data) async -> Bool {
    return await withCheckedContinuation { continuation in

        let originalName = fileURL.deletingPathExtension().lastPathComponent
        let newName = NameMod.getTimeName(name: originalName)  // e.g. "photo_20250311_1430.pdf"

        do {
            let path = fileURL.deletingLastPathComponent()
            let finalPath = path.appendingPathComponent(newName)

            if PermissionsManager().isAppSandboxed() && !PermissionsManager.shared.isFolderGranted(path) {
                Task { @MainActor in
                    PermissionsManager.shared.requestAccess(path.path())
                    do {
                        try pdfData.write(to: finalPath, options: .atomic)
                        print("✅ PDF saved to: \(finalPath.path)")
                        openFolder(finalPath.deletingLastPathComponent()) // Open the folder
                        return
                    } catch {
                        print("❌ ERROR: Failed to save PDF, Error: \(error)")
                    }
                }
                return
            }

            // 🚀 Save normally if not sandboxed
            try pdfData.write(to: finalPath, options: .atomic)
            print("✅ Successfully saved PDF to: \(finalPath.path)")
            openFolder(finalPath.deletingLastPathComponent()) // Open the folder
            continuation.resume(returning: true)
            return

        } catch {
            print("❌ ERROR: Failed to save PDF, Error: \(error)")
            continuation.resume(returning: false)
            return
        }
    }
}

func openFolder(_ folderURL: URL) {
    NSWorkspace.shared.open(folderURL)
}

