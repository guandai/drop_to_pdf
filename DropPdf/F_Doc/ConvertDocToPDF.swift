import Cocoa
import CoreText
import PDFKit
import UniformTypeIdentifiers

class DocToPDF {
    func convertDocToPDF(fileURL: URL) async -> Bool {
        let nsOption = [
            NSAttributedString.DocumentReadingOptionKey
                .documentType: NSAttributedString.DocumentType
                .docFormat
        ]

        guard
            let docData = try? Data(
                contentsOf: URL(
                    fileURLWithPath: NameMod.toFileString(fileURL.path()),
                    isDirectory: false))
        else {
            print("❌ fail to get docData : \(fileURL.path)")
            return false
        }

        guard
            let attributed = try? NSAttributedString(
                data: docData, options: nsOption, documentAttributes: nil)
        else {
            print("❌ create NSAttributedString failed: \(fileURL.path)")
            return false
        }

        let string = attributed.string
        return await StringToPDF().stringToPdf(fileURL: fileURL, string: string)

        //        let saveToPdfIns = SaveToPdf()
        //        return await saveToPdfIns.saveContentToPdf(fileURL: fileURL, docType: .docFormat)
    }
}
