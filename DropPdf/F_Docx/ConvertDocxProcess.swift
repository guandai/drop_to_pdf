import Cocoa
import PDFKit


class ConvertDocxProcess {
    private var getPages: () -> [NSView]
    private var setPages: ([NSView]) -> Void
    private var getCurrentView: () -> NSView
    private var setCurrentView: (NSView) -> Void
    private var getYOffset: () -> CGFloat
    private var setYOffset: (CGFloat) -> Void
    private let margin: CGFloat = 40
    private let pageSize: NSSize = NSSize(width: 595, height: 842)
    let blockHeight: CGFloat = 20

    init(pages: @escaping () -> [NSView], setPages: @escaping ([NSView]) -> Void,
         currentView: @escaping () -> NSView, setCurrentView: @escaping (NSView) -> Void,
         yOffset: @escaping () -> CGFloat, setYOffset: @escaping (CGFloat) -> Void) {
        getPages = pages
        self.setPages = setPages
        getCurrentView = currentView
        self.setCurrentView = setCurrentView
        getYOffset = yOffset
        self.setYOffset = setYOffset
    }
    
    func unzipDocxFile(docxURL: URL, to destinationURL: URL) throws {
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: docxURL, to: destinationURL)
    }
    
    func newPage() {
        let current = getCurrentView()
        if !current.subviews.isEmpty {
            var pages = getPages()
            pages.append(current)
            setPages(pages)
        }
        createView()
    }
    
    func createView() {
        let current = getCurrentView()
        if !current.subviews.isEmpty {
            var pages = getPages()
            pages.append(current)
            setPages(pages)
        }
        setCurrentView(NSView(frame: NSRect(origin: .zero, size: pageSize)))
        setYOffset(self.pageSize.height - margin)
    }
    
    func initPage() {
        setPages([])
        Task { @MainActor in
            createView()
        }
    }
    
    func processImage(unzipURL: URL, rId: String, w: CGFloat?, h:CGFloat?) {
        let relParser = RelationshipParser()
        relParser.parseRels(at: unzipURL.appendingPathComponent("word/_rels/document.xml.rels"))
        if let imageFile = relParser.imageRelMap[rId] {
            let imageURL = unzipURL.appendingPathComponent("word").appendingPathComponent(imageFile)
            if let image = NSImage(contentsOf: imageURL) {
                let displayWidth = w ?? image.size.width
                let displayHeight = h ?? image.size.height
                
                if getYOffset() - displayHeight < margin {
                    newPage()
                }

                let imageView = NSImageView(frame: NSRect(x: 40, y: getYOffset() - displayHeight, width: displayWidth, height: displayHeight))
                imageView.image = image
                getCurrentView().addSubview(imageView)

                setYOffset(getYOffset() - (displayHeight + blockHeight))
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

        if getYOffset() - textHeight < margin {
            newPage()
        }

        let textView = NSTextView(frame: NSRect(x: 40, y: getYOffset() - textHeight, width: maxWidth, height: textHeight))
        textView.textContainer?.containerSize = NSSize(width: maxWidth, height: textHeight)
        textView.textContainer?.widthTracksTextView = true
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.textStorage?.setAttributedString(textStorage)

        getCurrentView().addSubview(textView)
        setYOffset(getYOffset() - (textHeight + blockHeight))
    }
    
    
    func parseData(unzipURL: URL) {
        // parse data
        let docParser = DocxParser()
        docParser.parseDocument(at: unzipURL.appendingPathComponent("word/document.xml"))
        for block in docParser.contentBlocks {
            switch block {
            case .paragraph(let runs):
                processText(runs)
            case .image(let rId, let w, let h):
                processImage(unzipURL: unzipURL, rId: rId, w: w , h: h)
            }
        }
    }
    
    func insertPages() async -> PDFDocument {
        let pdfDocument = PDFDocument()

        await MainActor.run {
            let current = getCurrentView()
            if !current.subviews.isEmpty {
                var pages = getPages()
                pages.append(current)
                setPages(pages)
            }

            let pages = getPages().filter { !$0.subviews.isEmpty }
            for (index, pageView) in pages.enumerated() {
                let data = pageView.dataWithPDF(inside: pageView.bounds)
                if let pdfDoc = PDFDocument(data: data),
                   let pdfPage = pdfDoc.page(at: 0) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
        }

        return pdfDocument
    }
}
