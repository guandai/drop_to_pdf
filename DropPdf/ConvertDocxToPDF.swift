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
                                for run in runs {
                                    let maxWidth: CGFloat = 500
                                    print(run.fontSize)
                                    let fontSize = run.fontSize ?? 14
                                    let font: NSFont
                                    if let fontName = run.fontName, let customFont = NSFont(name: fontName, size: fontSize) {
                                        font = customFont
                                    } else {
                                        font = NSFont.systemFont(ofSize: fontSize)
                                    }
                                    
//                                    let font = NSFont.systemFont(ofSize: fontSize)
                                    let attributes: [NSAttributedString.Key: Any] = [.font: font]

                                    let boundingRect = (run.text as NSString).boundingRect(
                                        with: NSSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
                                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                                        attributes: attributes
                                    )
                                    let textHeight = ceil(boundingRect.height)

                                    if yOffset - textHeight < margin {
                                        newPage()
                                    }

                                    let label = NSTextField(labelWithString: run.text)
                                    label.font = font
                                    label.lineBreakMode = .byWordWrapping
                                    label.maximumNumberOfLines = 0
                                    label.frame = NSRect(x: 40, y: yOffset - textHeight, width: maxWidth, height: textHeight)
                                    currentView.addSubview(label)

                                    yOffset -= (textHeight + 10)
                                }
                                

                            case .image(let rId):
                                let maxWidth: CGFloat = 500
                                let maxHeight: CGFloat = 600

                                
                                if let imageFile = relParser.imageRelMap[rId] {
                                    let imageURL = unzipURL.appendingPathComponent("word").appendingPathComponent(imageFile)
                                    if let image = NSImage(contentsOf: imageURL) {
//                                        let imageHeight: CGFloat = 150
                                        let originalSize = image.size
                                        let widthScale = maxWidth / originalSize.width
                                        let heightScale = maxHeight / originalSize.height
                                        let scaleFactor = min(widthScale, heightScale, 1.0) // Never upscale

                                        let displayWidth = originalSize.width * scaleFactor
                                        let displayHeight = originalSize.height * scaleFactor
                                        
                                        if yOffset - displayHeight < margin {
                                            newPage()
                                        }

                                        let imageView = NSImageView(frame: NSRect(x: 40, y: yOffset - displayHeight, width: displayWidth, height: displayHeight))
                                        imageView.image = image
                                        currentView.addSubview(imageView)

                                        yOffset -= (displayHeight + 10)
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


class RelationshipParser: NSObject, XMLParserDelegate {
    var imageRelMap = [String: String]()
    
    func parseRels(at url: URL) {
        let parser = XMLParser(contentsOf: url)
        parser?.delegate = self
        parser?.parse()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "Relationship",
           let id = attributeDict["Id"],
           let target = attributeDict["Target"],
           let type = attributeDict["Type"],
           type.contains("/image") {
            imageRelMap[id] = target // e.g. rId5 -> media/image1.png
        }
    }
}

struct StyledText {
    let text: String
    let fontSize: CGFloat?
    let fontName: String?  // 👈 NEW
}

enum DocxContentBlock {
    case paragraph([StyledText])
    case image(String)
}


class DocxParser: NSObject, XMLParserDelegate {
    var contentBlocks: [DocxContentBlock] = []
    private var currentElement = ""
    private var currentParagraph: [StyledText] = []
    private var currentFontSize: CGFloat?
    private var currentText: String = ""
    private var insideRunProperties = false
    private var currentFontName: String? = nil
    

    func parseDocument(at xmlURL: URL) {
        let parser = XMLParser(contentsOf: xmlURL)
        parser?.delegate = self
        parser?.parse()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

        currentElement = elementName

        if elementName == "w:rFonts", insideRunProperties,
           let fontName = attributeDict["w:ascii"] {
            currentFontName = fontName
        }
        
        if elementName == "w:r" {
            currentFontSize = nil // reset for this run
        }

        if elementName == "w:rPr" {
            insideRunProperties = true
        }

        if elementName == "w:sz", insideRunProperties,
           let val = attributeDict["w:val"], let halfPoints = Double(val) {
            currentFontSize = CGFloat(halfPoints) / 2.0
        }

        if elementName == "w:t" {
            currentText = ""
        }

        if elementName == "w:p" {
            currentParagraph = []
        }

        if elementName == "a:blip", let rId = attributeDict["r:embed"] {
            contentBlocks.append(.image(rId))
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "w:t" {
            currentText += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

        if elementName == "w:rPr" {
            insideRunProperties = false
        }

        if elementName == "w:t", !currentText.isEmpty {
            let styled = StyledText(
                text: currentText.trimmingCharacters(in: .whitespacesAndNewlines),
                fontSize: currentFontSize,
                fontName: currentFontName
            )
            currentParagraph.append(styled)
            currentText = ""
        }

        if elementName == "w:p", !currentParagraph.isEmpty {
            contentBlocks.append(.paragraph(currentParagraph))
            currentParagraph = []
        }

        if elementName == "w:r" {
            currentFontSize = nil
            currentFontName = nil
        }
        
    }
}

