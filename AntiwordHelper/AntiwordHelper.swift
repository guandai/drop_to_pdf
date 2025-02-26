import Foundation
import os.log


@objc protocol AntiwordHelperProtocol {
    func processDocFile(inputPath: String, withReply: @escaping (Bool, String) -> Void)
}


class AntiwordHelper: NSObject, NSXPCListenerDelegate, AntiwordHelperProtocol {
    private let listener = NSXPCListener.service()

    override init() {
        super.init()
        listener.delegate = self
        log("✅ AntiwordHelper initialized")
    }

    func start() {
        log("🚀 Starting AntiwordHelper XPC service...")
        listener.resume()
    }

    // MARK: - NSXPCListenerDelegate
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        log("🔗 New XPC connection received")

        newConnection.exportedInterface = NSXPCInterface(with: AntiwordHelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()

        return true
    }

    // MARK: - AntiwordHelperProtocol
    func processDocFile(inputPath: String, withReply reply: @escaping (Bool, String) -> Void) {
        log("📂 Processing file: \(inputPath)")

        let antiwordPath = Bundle.main.bundlePath + "/Contents/MacOS/antiword"
        let task = Process()
        task.launchPath = antiwordPath
        task.arguments = [inputPath]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.terminationHandler = { process in
            let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
            let outputText = String(data: outputData, encoding: .utf8) ?? "❌ No output"

            if process.terminationStatus == 0 {
                self.log("✅ Antiword processed successfully")
                reply(true, outputText)
            } else {
                self.log("❌ Antiword failed: \(outputText)")
                reply(false, outputText)
            }
        }

        do {
            try task.run()
        } catch {
            self.log("❌ Error running antiword: \(error.localizedDescription)")
            reply(false, "❌ Error running antiword: \(error.localizedDescription)")
        }
    }

    /// **Writes debug logs to a file**
    private func log(_ message: String) {
        let logFile = "/tmp/AntiwordHelper.log"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] \(message)\n"

        if let handle = FileHandle(forWritingAtPath: logFile) {
            handle.seekToEndOfFile()
            handle.write(logMessage.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? logMessage.write(toFile: logFile, atomically: true, encoding: .utf8)
        }
    }
}

