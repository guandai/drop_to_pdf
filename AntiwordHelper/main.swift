import Foundation

// MARK: - Define XPC Protocol
@objc protocol AntiwordHelperProtocol {
    func processDocFile(inputPath: String, outputPath: String, withReply reply: @escaping (Bool, String) -> Void)
}

// MARK: - XPC Service Implementation
class AntiwordHelper: NSObject, AntiwordHelperProtocol, NSXPCListenerDelegate {

    // Accept new XPC connections
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: AntiwordHelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    // Process .doc files using antiword
    func processDocFile(inputPath: String, outputPath: String, withReply reply: @escaping (Bool, String) -> Void) {
        let antiwordPath = Bundle.main.path(forResource: "antiword", ofType: "") ?? "/usr/local/bin/antiword"
        
        let task = Process()
        task.launchPath = antiwordPath
        task.arguments = [inputPath]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let outputText = String(data: outputData, encoding: .utf8) ?? ""
            
            try outputText.write(toFile: outputPath, atomically: true, encoding: .utf8)
            
            reply(true, "✅ Conversion Successful: \(outputPath)")
        } catch {
            reply(false, "❌ Error: \(error.localizedDescription)")
        }
    }
}
