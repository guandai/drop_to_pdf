
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

class DocxToPdfImage {
    func rotateImage(_ imageData: Data, degrees: Int) -> Data? {
        guard let image = NSImage(data: imageData) else {
            print("❌ Unable to create NSImage from data")
            return nil
        }

        guard let rotatedImage = image.rotatedPreservingAspectRatio(by: CGFloat(degrees)) else {
            return nil
        }

        return rotatedImage.tiffRepresentation // Convert back to TIFF before saving
    }
    
    func extractImages(docxPath: URL) -> [Data] {
        let mediaURL = docxPath.appendingPathComponent("word/media/")
        guard let mediaFiles = try? FileManager.default.contentsOfDirectory(at: mediaURL, includingPropertiesForKeys: nil) else {
            print("❌ No images found in DOCX")
            return []
        }

        // ✅ Extract rotation metadata from document.xml.rels
        let relsPath = docxPath.appendingPathComponent("word/_rels/document.xml.rels")
        var imageRotationData = [String: Int]() // Store rotation per image file

        if let relsData = try? Data(contentsOf: relsPath), let relsString = String(data: relsData, encoding: .utf8) {
            let pattern = #"Target="media/([^"]+)"[^>]*?rotation="([^"]+)""#  // Extract rotation info
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let matches = regex?.matches(in: relsString, options: [], range: NSRange(location: 0, length: relsString.utf16.count))

            matches?.forEach { match in
                if let imageRange = Range(match.range(at: 1), in: relsString),
                   let rotationRange = Range(match.range(at: 2), in: relsString) {
                    let imageName = String(relsString[imageRange])
                    let rotation = Int(String(relsString[rotationRange])) ?? 0
                    imageRotationData[imageName] = rotation
                }
            }
        }

        return mediaFiles.map { file in
            let fileName = file.lastPathComponent

            guard let data = try? Data(contentsOf: file) else {
                print("❌ Error reading image: \(fileName). Using empty image.")
                return Data() // ✅ Fallback to an empty Data object instead of nil
            }

            let docxRotation = imageRotationData[fileName] ?? 0
            let fixedData = rotateImage(data, degrees: docxRotation) ?? data // ✅ Ensure fallback to original data

            print("🖼 Extracted Image: \(fileName) (Size: \(fixedData.count) bytes) | Rotation: \(docxRotation)°")
            return fixedData
        }
    }
    
    
    
}

// ✅ NSImage extension for rotation (macOS) while keeping original proportions
extension NSImage {
    func rotatedPreservingAspectRatio(by degrees: CGFloat) -> NSImage? {
        let radians = degrees * .pi / 180
        let imageSize = self.size
        let rotatedBounds = CGRect(origin: .zero, size: imageSize)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral

        let newSize = NSSize(width: rotatedBounds.width, height: rotatedBounds.height)
        let newImage = NSImage(size: newSize)

        newImage.lockFocus()
        let context = NSGraphicsContext.current!.cgContext

        // ✅ Move origin to center and rotate
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)

        // ✅ Draw the original image at correct size
        draw(at: NSPoint(x: -imageSize.width / 2, y: -imageSize.height / 2),
             from: NSRect(origin: .zero, size: imageSize),
             operation: .copy,
             fraction: 1.0)

        newImage.unlockFocus()
        return newImage
    }
    
    
}

// ✅ Convert CGImage to PNG Data
extension CGImage {
    func pngRepresentation() -> Data? {
        let mutableData = NSMutableData()
        if let destination = CGImageDestinationCreateWithData(mutableData, UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(destination, self, nil)
            if CGImageDestinationFinalize(destination) {
                return mutableData as Data
            }
        }
        return nil
    }
}

