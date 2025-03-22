import Cocoa
import PDFKit


class DocxToPDF {
    func unzipDocxFile(docxURL: URL, to destinationURL: URL) throws {
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: docxURL, to: destinationURL)
    }
    
    func convertDocxToPDF(fileURL: URL) async -> Bool {
        print(">> convertDocxToPDF")

        guard getDidStart(fileURL: fileURL) else {
            print("❌ Security-scoped resource access failed: \(fileURL.path)")
            return false
        }

        return await withCheckedContinuation { continuation in
            let unzipDocxFileIns = DocxToPDF().unzipDocxFile
            let unzipURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            print(unzipURL)
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try unzipDocxFileIns(fileURL, unzipURL)

                    // Parse XMLs (non-UI work)
                    let relParser = RelationshipParser()
                    relParser.parseRels(at: unzipURL.appendingPathComponent("word/_rels/document.xml.rels"))
                    let docParser = DocxParser()
                    docParser.parseDocument(at: unzipURL.appendingPathComponent("word/document.xml"))

                    // ⚠️ Now switch to main thread for UI
                    DispatchQueue.main.async {
                        let pageSize = NSSize(width: 595, height: 842) // A4
                        let margin: CGFloat = 40
                        let blockHeight: CGFloat = 20

                        var pages: [NSView] = []
                        var currentView = NSView(frame: NSRect(origin: .zero, size: pageSize))
                        var yOffset: CGFloat = pageSize.height - margin

                        func newPage() {
                            pages.append(currentView)
                            currentView = NSView(frame: NSRect(origin: .zero, size: pageSize))
                            yOffset = pageSize.height - margin
                        }
                        

                        for block in docParser.contentBlocks {
                            switch block {
                            case .paragraph(let runs):
                                let maxWidth: CGFloat = 500
                                let textStorage = NSTextStorage()
                                let textContainer = NSTextContainer(size: NSSize(width: maxWidth, height: .greatestFiniteMagnitude))
                                let layoutManager = NSLayoutManager()

                                layoutManager.addTextContainer(textContainer)
                                textStorage.addLayoutManager(layoutManager)

                                for run in runs {
                                    let fontSize = run.fontSize ?? 14
                                    let font: NSFont
                                    if let fontName = run.fontName, let customFont = NSFont(name: fontName, size: fontSize) {
                                        font = customFont
                                    } else {
                                        font = NSFont.systemFont(ofSize: fontSize)
                                    }
                                    let attributes: [NSAttributedString.Key: Any] = [.font: font]
                                    let attributed = NSAttributedString(string: run.text, attributes: attributes)
                                    textStorage.append(attributed)
                                }

                                layoutManager.glyphRange(for: textContainer)
                                let usedRect = layoutManager.usedRect(for: textContainer)
                                let textHeight = ceil(usedRect.height)

                                if yOffset - textHeight < margin {
                                    newPage()
                                }

                                let textView = NSTextView(frame: NSRect(x: 40, y: yOffset - textHeight, width: maxWidth, height: textHeight))
                                textView.textContainer?.containerSize = NSSize(width: maxWidth, height: textHeight)
                                textView.textContainer?.widthTracksTextView = true
                                textView.isEditable = false
                                textView.isSelectable = false
                                textView.drawsBackground = false
                                textView.textStorage?.setAttributedString(textStorage)

                                currentView.addSubview(textView)
                                yOffset -= (textHeight + blockHeight)

                            case .image(let rId, let w, let h):
                                if let imageFile = relParser.imageRelMap[rId] {
                                    let imageURL = unzipURL.appendingPathComponent("word").appendingPathComponent(imageFile)
                                    if let image = NSImage(contentsOf: imageURL) {
                                        let displayWidth = w ?? image.size.width
                                        let displayHeight = h ?? image.size.height
                                        
                                        if yOffset - displayHeight < margin {
                                            newPage()
                                        }

                                        let imageView = NSImageView(frame: NSRect(x: 40, y: yOffset - displayHeight, width: displayWidth, height: displayHeight))
                                        imageView.image = image
                                        currentView.addSubview(imageView)

                                        yOffset -= (displayHeight + blockHeight)
                                    }
                                }
                            }
                        }
                        
                        
                        pages.append(currentView) // Don't forget to add the last page!

                        let pdfDocument = PDFDocument()

                        for (index, pageView) in pages.enumerated() {
                            let data = pageView.dataWithPDF(inside: pageView.bounds)
                            if let pdfDoc = PDFDocument(data: data),
                               let pdfPage = pdfDoc.page(at: 0) {
                                pdfDocument.insert(pdfPage, at: index)
                            }
                        }
                        

                        // Generate PDF
                        
                        let (_, outputPath) = SaveToPdf().getPathes(fileURL)
                        let success = pdfDocument.write(to: outputPath)
                        if !success {
                            continuation.resume(returning: false)
                            return
                        }
                        
                        fileURL.stopAccessingSecurityScopedResource()
                        continuation.resume(returning: true)
                    }

                } catch {
                    DispatchQueue.main.async {
                        print("❌ Error: \(error)")
                        continuation.resume(returning: false)
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
            }
        }
    }
}

