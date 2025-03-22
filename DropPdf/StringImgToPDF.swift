import Cocoa
import PDFKit

extension PDFDocument {
    /// Converts `PDFDocument` to `Data` while preserving images
    func toData() -> Data? {
        return self.dataRepresentation()
    }
}

class StringImgToPDF {
    func getDidStart (fileURL: URL) -> Bool {
        return true;
    }

    @Sendable static func drawString (_ string: String, inRect rect: CGRect) {
        // Draw text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .paragraphStyle: paragraphStyle
        ]
        string.draw(in: rect, withAttributes: attributes)
    }

    func toPdf(string: String, images: [Data], fileURL: URL) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                print(">>> StringImgToPDF toPdf")
                let pdfDocument = PDFDocument()
                var pdfBounds = CGRect(x: 0, y: 0, width: 472, height: 0)

                // Create an image representation of the PDF page
//                let pdfImage = NSImage(size: pdfBounds.size)
//                pdfImage.lockFocus()

                // Create drawing context
//                let context = NSGraphicsContext.current!.cgContext
//                context.setFillColor(NSColor.white.cgColor)

                let textHeight: CGFloat = 20 // Initial height for the text
//                var imageY: CGFloat = textHeight + 20 // Start below the text

                // Calculate the width for the text drawing
                let textRect = CGRect(x: 20, y: 20, width: 472 - 40, height: CGFloat.greatestFiniteMagnitude)
                let textSize = (string as NSString).boundingRect(with: textRect.size, options: .usesLineFragmentOrigin, attributes: [.font: NSFont.systemFont(ofSize: 14)])
                pdfBounds.size.height += textSize.height + 40
                
                // Draw the string
                StringImgToPDF.drawString(string, inRect: textRect)
                
                // ✅ Correctly Convert Each Data Object to NSImage
//                for imageData in images {
//                    guard let image = NSImage(data: imageData), image.size.width > 0, image.size.height > 0 else {
//                        print("⚠️ Warning: Invalid image data, skipping.")
//                        continue
//                    }
//                    let maxWidth: CGFloat = 472 - 40 // Max width for the image
//                    let maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude // Max height for the image
//                    let imgAspectRatio = image.size.width / image.size.height
//                    var imgWidth = image.size.width
//                    var imgHeight = image.size.height
//
//                    // Adjust dimensions to fit within the PDF bounds
//                    if imgWidth > maxWidth {
//                        imgHeight = imgWidth > 0 ? (maxWidth / imgWidth) * imgHeight : imgHeight
//                        imgWidth = maxWidth
//                    }
//                    if imgHeight + imageY > maxHeight {
//                        imgHeight = maxHeight - imageY                     }
//
//                    let imgRect = CGRect(x: 20, y: imageY, width: imgWidth, height: imgHeight)
//                    image.draw(in: imgRect)
//                    imageY += imgHeight + 20 // Update Y position for the next image
//                    pdfBounds.size.height += imgHeight + 20 // Adjust pdfBounds height
//                }

//                pdfImage.unlockFocus()

                // Update pdfBounds size
//                pdfImage.size = pdfBounds.size

                // Convert NSImage to PDFPage
//                if let pdfPage = PDFPage(image: pdfImage) {
//                    pdfDocument.insert(pdfPage, at: 0)
//                }

                guard let pdfData = pdfDocument.dataRepresentation() else {
                    print("❌ ERROR: Failed to convert PDFDocument to Data")
                    continuation.resume(returning: false)
                    return
                }

                Task {
                    let success = await SaveToPdf().saveToPdf(fileURL: fileURL, pdfData: pdfData)
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
