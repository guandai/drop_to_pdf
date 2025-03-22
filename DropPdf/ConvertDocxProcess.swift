import Cocoa
import PDFKit


class DocxToPDF {
    let pageSize = NSSize(width: 595, height: 842) // A4
    let margin: CGFloat = 40
    let blockHeight: CGFloat = 20

    var pages: [NSView] = []
    var currentView = NSView()
    var yOffset: CGFloat = 0
    
    func unzipDocxFile(docxURL: URL, to destinationURL: URL) throws {
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: docxURL, to: destinationURL)
    }
    
    func initPage() {
        self.pages = []
        createView()
    }

    func newPage() {
        self.pages.append(self.currentView)
        createView()
    }
    
    func createView() {
        self.currentView = NSView(frame: NSRect(origin: .zero, size: self.pageSize))
        self.yOffset = self.pageSize.height - self.margin
    }
    
    func processImage(unzipURL: URL, rId: String, w: CGFloat?, h:CGFloat?) {
        let relParser = RelationshipParser()
        relParser.parseRels(at: unzipURL.appendingPathComponent("word/_rels/document.xml.rels"))
        if let imageFile = relParser.imageRelMap[rId] {
            let imageURL = unzipURL.appendingPathComponent("word").appendingPathComponent(imageFile)
            if let image = NSImage(contentsOf: imageURL) {
                let displayWidth = w ?? image.size.width
                let displayHeight = h ?? image.size.height
                
                if self.yOffset - displayHeight < self.margin {
                    self.newPage()
                }

                let imageView = NSImageView(frame: NSRect(x: 40, y: self.yOffset - displayHeight, width: displayWidth, height: displayHeight))
                imageView.image = image
                self.currentView.addSubview(imageView)

                self.yOffset -= (displayHeight + self.blockHeight)
            }
        }
    }
    
    func processText(_ runs: [StyledText]) {
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

        if self.yOffset - textHeight < self.margin {
            self.newPage()
        }

        let textView = NSTextView(frame: NSRect(x: 40, y: self.yOffset - textHeight, width: maxWidth, height: textHeight))
        textView.textContainer?.containerSize = NSSize(width: maxWidth, height: textHeight)
        textView.textContainer?.widthTracksTextView = true
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.textStorage?.setAttributedString(textStorage)

        self.currentView.addSubview(textView)
        self.yOffset -= (textHeight + self.blockHeight)
    }
    
    
    func parseData(unzipURL: URL) {
        // parse data
        let docParser = DocxParser()
        docParser.parseDocument(at: unzipURL.appendingPathComponent("word/document.xml"))
        for block in docParser.contentBlocks {
            switch block {
            case .paragraph(let runs):
                self.processText(runs)
            case .image(let rId, let w, let h):
                self.processImage(unzipURL: unzipURL, rId: rId, w: w , h: h)
            }
        }
    }
    
    func insertPages() -> PDFDocument {
        self.pages.append(self.currentView) // Don't forget to add the last page!
        let pdfDocument = PDFDocument()
        for (index, pageView) in self.pages.enumerated() {
            let data = pageView.dataWithPDF(inside: pageView.bounds)
            if let pdfDoc = PDFDocument(data: data),
               let pdfPage = pdfDoc.page(at: 0) {
                pdfDocument.insert(pdfPage, at: index)
            }
        }
        return pdfDocument
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
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try unzipDocxFileIns(fileURL, unzipURL)

                    DispatchQueue.main.async {
                        self.initPage()
                        
                        // parse data
                        let docParser = DocxParser()
                        docParser.parseDocument(at: unzipURL.appendingPathComponent("word/document.xml"))
                        for block in docParser.contentBlocks {
                            switch block {
                            case .paragraph(let runs):
                                self.processText(runs)
                            case .image(let rId, let w, let h):
                                self.processImage(unzipURL: unzipURL, rId: rId, w: w , h: h)
                            }
                        }
                        
                        // insert pages
                        let doc = self.insertPages()
                        
                        // Generate PDF
                        let (_, outputPath) = SaveToPdf().getPathes(fileURL)
                        if doc.write(to: outputPath) {
//                            fileURL.stopAccessingSecurityScopedResource()
                            continuation.resume(returning:  true)
                            return
                        }
                        
                        // close folder
                        fileURL.stopAccessingSecurityScopedResource()
                        continuation.resume(returning: false)
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

