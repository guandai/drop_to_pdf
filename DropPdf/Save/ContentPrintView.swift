import Cocoa

class ContentPrintView: NSView {
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

    func skipTooBigImage(_ textStorage:  NSTextStorage, _ lineRange: NSRange, _ maxLength: Int) -> Bool {
        let safeLength = min(lineRange.length, maxLength - lineRange.location)
        let safeRange = NSRange(location: lineRange.location, length: safeLength)
        
        var lineContainsOversizedImage = false
        textStorage.enumerateAttribute(.attachment, in: safeRange, options: []) { value, _, stop in
            if let attachment = value as? NSTextAttachment,
               let image = attachment.image {
                let imageHeight = attachment.bounds.height > 0 ? attachment.bounds.height : image.size.height
                // If image is too big to fit on page
                if imageHeight > pageSize.height {
                    lineContainsOversizedImage = true
                    stop.pointee = true
                }
            }
        }
        
        return lineContainsOversizedImage
    }

    func updateglyphInPage(_ height: CGFloat, _ pageIdx: Int, _ textStorage: NSTextStorage) -> (CGFloat, Int) {
        var currentHeight = height
        var pageEndGlyphIndex = pageIdx

        while pageEndGlyphIndex < layoutManager.numberOfGlyphs {
            var lineRange = NSRange(location: 0, length: 0)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: pageEndGlyphIndex, effectiveRange: &lineRange)
            var lineContainsOversizedImage = false
            let maxLength = textStorage.length // Check for attachment in this line

            if lineRange.location >= maxLength { break }
            lineContainsOversizedImage = skipTooBigImage(textStorage, lineRange, maxLength)

            if lineContainsOversizedImage {
                // Force oversized image to go on its own page
                pageEndGlyphIndex = NSMaxRange(lineRange)
                break
            }

            if currentHeight + lineRect.height > pageSize.height { break }
            currentHeight += lineRect.height
            pageEndGlyphIndex = NSMaxRange(lineRange)
        }
        return (currentHeight, pageEndGlyphIndex)
    }
    
    func updatePagesInDocument(_ layoutManager: NSLayoutManager, _ textStorage: NSTextStorage) {
        var glyphIndex = 0
        while glyphIndex < layoutManager.numberOfGlyphs {
            var currentHeight: CGFloat = 0
            var pageEndGlyphIndex = glyphIndex
            (currentHeight, pageEndGlyphIndex) = updateglyphInPage(currentHeight, pageEndGlyphIndex, textStorage)

            if pageEndGlyphIndex == glyphIndex {
                // Prevent infinite loop: force progress
                pageEndGlyphIndex = glyphIndex + 1
            }

            let pageRange = NSRange(location: glyphIndex, length: pageEndGlyphIndex - glyphIndex)
            pageRanges.append(pageRange)
            glyphIndex = pageEndGlyphIndex
        }
    }
    
    func setup() {
        textContainer = NSTextContainer(containerSize: NSSize(width: pageSize.width, height: .greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: textContainer)
        updatePagesInDocument(layoutManager, textStorage)
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

    override var isFlipped: Bool { return true }
}
