import Cocoa
import PDFKit

class ConvertDocxProcess {
    private var getPages: () -> [NSView]
    private var setPages: ([NSView]) -> Void
    private var getCurrentView: () -> NSView
    private var setCurrentView: (NSView) -> Void
    private var getYOffset: () -> CGFloat
    private var setYOffset: (CGFloat) -> Void
    private let margin: CGFloat = 60
    private let pageSize: NSSize = NSSize(width: 595, height: 842)
    let blockHeight: CGFloat = 20

    init(
        pages: @escaping () -> [NSView], setPages: @escaping ([NSView]) -> Void,
        currentView: @escaping () -> NSView,
        setCurrentView: @escaping (NSView) -> Void,
        yOffset: @escaping () -> CGFloat,
        setYOffset: @escaping (CGFloat) -> Void
    ) {
        getPages = pages
        self.setPages = setPages
        getCurrentView = currentView
        self.setCurrentView = setCurrentView
        getYOffset = yOffset
        self.setYOffset = setYOffset
    }

    func unzipDocxFile(docxURL: URL, to destinationURL: URL) throws {
        try FileManager.default.createDirectory(
            at: destinationURL, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: docxURL, to: destinationURL)
    }

    func setFirstPage() {
        let current = getCurrentView()
        if !current.subviews.isEmpty {
            var pages = getPages()
            pages.append(current)
            setPages(pages)
        }
    }
    func newPage() {
        setFirstPage()
        createView()
    }

    func createView() {
        setCurrentView(NSView(frame: NSRect(origin: .zero, size: pageSize)))
        setYOffset(self.pageSize.height - margin)
    }

    func initPage() {
        setPages([])
        Task { @MainActor in
            createView()
        }
    }

    func processImage(unzipURL: URL, rId: String, w: CGFloat?, h: CGFloat?) {
        let relParser = RelationshipParser()
        relParser.parseRels(
            at: unzipURL.appendingPathComponent("word/_rels/document.xml.rels"))
        if let imageFile = relParser.imageRelMap[rId] {
            let imageURL = unzipURL.appendingPathComponent("word")
                .appendingPathComponent(imageFile)
            if let image = NSImage(contentsOf: imageURL) {
                let displayWidth = w ?? image.size.width
                let displayHeight = h ?? image.size.height

                if getYOffset() - displayHeight < margin {
                    newPage()
                }

                let imageView = NSImageView(
                    frame: NSRect(
                        x: 40, y: getYOffset() - displayHeight,
                        width: displayWidth, height: displayHeight))
                imageView.image = image
                getCurrentView().addSubview(imageView)

                setYOffset(getYOffset() - (displayHeight + blockHeight))
            }
        }
    }

    func storageAppendText(styledTexts: [StyledText], textStorage: NSTextStorage ) {
        for styledText in styledTexts {
            let fontSize = styledText.fontSize ?? 14
            let font: NSFont
            if let fontName = styledText.fontName,
                let customFont = NSFont(name: fontName, size: fontSize)
            {
                font = customFont
            } else {
                font = NSFont.systemFont(ofSize: fontSize)
            }
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let attributed = NSAttributedString(
                string: styledText.text, attributes: attributes)
            textStorage.append(attributed)
        }
    }
    
    func getLayout(texts: [StyledText], textStorage: NSTextStorage, textContainer: NSTextContainer) -> NSLayoutManager {
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        storageAppendText(styledTexts: texts, textStorage: textStorage)
        layoutManager.glyphRange(for: textContainer)
        return layoutManager
    }

    func processText(_ texts: [StyledText]) {
        let maxWidth: CGFloat = 500
        let textStorage = NSTextStorage()
        let textContainer = NSTextContainer(size: NSSize(width: maxWidth, height: .greatestFiniteMagnitude))
        let layoutManager = getLayout(texts: texts, textStorage: textStorage, textContainer: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        let textHeight = ceil(usedRect.height)

        if getYOffset() - textHeight < margin { newPage() }
        getCurrentView().addSubview(getTextView(textHeight: textHeight, maxWidth: maxWidth, textStorage: textStorage))
        setYOffset(getYOffset() - (textHeight + blockHeight))
    }

    func getTextView(textHeight: CGFloat, maxWidth: CGFloat, textStorage: NSTextStorage) -> NSTextView {
        let textView = NSTextView(
            frame: NSRect(
                x: 40, y: getYOffset() - textHeight, width: maxWidth,
                height: textHeight))
        textView.textContainer?.containerSize = NSSize(
            width: maxWidth, height: textHeight)
        textView.textContainer?.widthTracksTextView = true
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.textStorage?.setAttributedString(textStorage)

        textView.wantsLayer = true
        textView.layer?.borderWidth = 5
        textView.layer?.borderColor = NSColor.red.cgColor
        return textView
    }

    func parseData(_ unzipURL: URL, docxProcess: ConvertDocxProcess) {
        let docParser = DocxParser()
        docParser
            .parseDocument(
                at: unzipURL.appendingPathComponent("word/document.xml")
            )
        for block in docParser.contentBlocks {
            switch block {
            case .paragraph(let styledTexts):
                docxProcess.processText(styledTexts)
            case .image(let rId, let w, let h):
                docxProcess
                    .processImage(unzipURL: unzipURL, rId: rId, w: w, h: h)
            case .pageBreak:
                newPage()  // or equivalent logic to create a new page
            }
        }
    }

    func insertPages() async -> PDFDocument {
        let pdfDocument = PDFDocument()

        await MainActor.run {
            setFirstPage()

            let pages = getPages().filter { !$0.subviews.isEmpty }
            for (index, pageView) in pages.enumerated() {
                let data = pageView.dataWithPDF(inside: pageView.bounds)
                if let pdfDoc = PDFDocument(data: data),
                    let pdfPage = pdfDoc.page(at: 0)
                {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
            print("📄 Total pages to insert: \(pages.count)")
        }

        return pdfDocument
    }
}
