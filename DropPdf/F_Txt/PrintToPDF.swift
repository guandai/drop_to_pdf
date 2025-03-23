import Cocoa

class PrintToPDF {
    func exportTextToPDF(text: String, to fileURL: URL) -> Bool {
        let printView = TextPrintView(frame: NSRect(x: 0, y: 0, width: 595, height: 842), text: text)
        let printInfo = NSPrintInfo()
        UserDefaults.standard.set(true, forKey: "NSPrintSpoolerLogToConsole")
        
        printInfo.horizontalPagination = .automatic
        printInfo.verticalPagination = .automatic
        printInfo.paperSize = NSSize(width: 595, height: 842)
        printInfo.topMargin = 20
        printInfo.bottomMargin = 20
        printInfo.leftMargin = 20
        printInfo.rightMargin = 20
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = false
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey(rawValue: NSPrintInfo.AttributeKey.jobSavingURL.rawValue)] = fileURL

        let operation = NSPrintOperation(view: printView, printInfo: printInfo)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false

        let result = operation.run()
        print(result ? "✅ PDF saved" : "❌ PDF generation failed")
        return result
    }
}




class TextPrintView: NSView {
    let textStorage: NSTextStorage
    let layoutManager = NSLayoutManager()
    var textContainer: NSTextContainer!
    var pageRanges: [NSRange] = []
    let pageSize: NSRect

    init(frame: NSRect, attributedText: NSAttributedString) {
        self.pageSize = frame
        self.textStorage = NSTextStorage(attributedString: attributedText)
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        textContainer = NSTextContainer(containerSize: NSSize(width: pageSize.width, height: .greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        layoutManager.ensureLayout(for: textContainer)

        var glyphIndex = 0
        while glyphIndex < layoutManager.numberOfGlyphs {
            let startIndex = glyphIndex
            var currentHeight: CGFloat = 0

            while glyphIndex < layoutManager.numberOfGlyphs {
                var lineRange = NSRange(location: 0, length: 0)
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange)
                if currentHeight + lineRect.height > pageSize.height { break }
                currentHeight += lineRect.height
                glyphIndex = NSMaxRange(lineRange)
            }

            let pageRange = NSRange(location: startIndex, length: glyphIndex - startIndex)
            pageRanges.append(pageRange)
        }
    }

    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        range.pointee = NSMakeRange(1, pageRanges.count)
        return true
    }

    override func rectForPage(_ page: Int) -> NSRect {
        return pageSize
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let pageNumber = NSPrintOperation.current?.currentPage ?? 1
        let pageIndex = pageNumber - 1
        guard pageIndex >= 0 && pageIndex < pageRanges.count else { return }

        let glyphRange = pageRanges[pageIndex]
        let usedRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

        context.saveGState()
        context.translateBy(x: 0, y: -usedRect.origin.y)
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: .zero)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: .zero)
        context.restoreGState()
    }

    override var isFlipped: Bool { true }
}





class TextPrintView: NSView {
    let textStorage: NSTextStorage
    let layoutManager = NSLayoutManager()
    var textContainer: NSTextContainer!
    var pageRanges: [NSRange] = []
    let pageSize: NSRect

    init(frame: NSRect, text: String) {
        self.pageSize = frame
        self.textStorage = NSTextStorage(string: text)
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        textContainer = NSTextContainer(containerSize: NSSize(width: pageSize.width, height: .greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        layoutManager.ensureLayout(for: textContainer)

        var glyphIndex = 0
        
        while glyphIndex < layoutManager.numberOfGlyphs {
            let startIndex = glyphIndex
            var currentHeight: CGFloat = 0

            while glyphIndex < layoutManager.numberOfGlyphs {
                var lineRange = NSRange(location: 0, length: 0)
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange)

                if currentHeight + lineRect.height > pageSize.height {
                    break
                }

                currentHeight += lineRect.height
                glyphIndex = NSMaxRange(lineRange)
            }

            let pageRange = NSRange(location: startIndex, length: glyphIndex - startIndex)
            pageRanges.append(pageRange)
        }
    }

    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        range.pointee = NSMakeRange(1, pageRanges.count)
        return true
    }

    override func rectForPage(_ page: Int) -> NSRect {
        return pageSize
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let pageNumber = NSPrintOperation.current?.currentPage ?? 1
        let pageIndex = pageNumber - 1
        guard pageIndex >= 0 && pageIndex < pageRanges.count else { return }

        let glyphRange = pageRanges[pageIndex]

        // Find Y-offset for current page
        let usedRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        context.saveGState()
        context.translateBy(x: 0, y: -usedRect.origin.y)

        layoutManager.drawBackground(forGlyphRange: glyphRange, at: .zero)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: .zero)
        context.restoreGState()
    }

    override var isFlipped: Bool { return true }
}
