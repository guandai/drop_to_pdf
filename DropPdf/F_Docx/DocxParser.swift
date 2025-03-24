import Cocoa
import PDFKit

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
    case pageBreak
    case image(String)
    case image(rId: String, width: CGFloat?, height: CGFloat?)
}


class DocxParser: NSObject, XMLParserDelegate {
    var contentBlocks: [DocxContentBlock] = []
    private var currentElement = ""
    private var currentParagraph: [StyledText] = []
    private var currentFontSize: CGFloat?
    private var currentText: String = ""
    private var insideRunProperties = false
    private var currentFontName: String? = nil
    
    private var currentImageId: String?
    private var currentImageSize: (width: CGFloat, height: CGFloat)?

    func parseDocument(at xmlURL: URL) {
        let parser = XMLParser(contentsOf: xmlURL)
        parser?.delegate = self
        parser?.parse()
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "w:t" {
            currentText += string
        }
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        currentElement = elementName
        if elementName == "w:rFonts", insideRunProperties,
           let fontName = attributeDict["w:ascii"] {
            currentFontName = fontName
        }
 
        if elementName == "w:r" {
            currentFontSize = nil
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
        
        if elementName == "w:br", let type = attributeDict["w:type"], type == "page" {
            contentBlocks.append(.pageBreak)
        }

        if elementName == "wp:extent" {
            if let widthEMU = attributeDict["cx"], let heightEMU = attributeDict["cy"],
               let w = Double(widthEMU), let h = Double(heightEMU) {
                // Convert EMUs to points: 1pt = 12700 EMU
                let widthPt = CGFloat(w / 12700)
                let heightPt = CGFloat(h / 12700)
                currentImageSize = (width: widthPt, height: heightPt)
            }
        }

        if elementName == "a:blip", let rId = attributeDict["r:embed"] {
            currentImageId = rId
        }
    }


    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "w:rPr" {
            insideRunProperties = false
        }
        if elementName == "w:t", !currentText.isEmpty {
            let styled = StyledText(
                text: currentText
                    .trimmingCharacters(in: .whitespacesAndNewlines),
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
        if elementName == "w:drawing", let rId = currentImageId {
            contentBlocks
                .append(
                    .image(
                        rId: rId,
                        width: currentImageSize?.width,
                        height: currentImageSize?.height
                    )
                )
            currentImageId = nil
            currentImageSize = nil
        }
    }
}
