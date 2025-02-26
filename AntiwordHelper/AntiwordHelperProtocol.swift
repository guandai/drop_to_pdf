import Foundation

@objc protocol AntiwordHelperProtocol {
    func processDocFile(inputPath: String, outputPath: String, withReply reply: @escaping (Bool, String) -> Void)
}
