import Foundation

class AntiwordHelper: NSObject, NSXPCListenerDelegate, AntiwordHelperProtocol {
    let listener = NSXPCListener.service()

    override init() {
        super.init()
        listener.delegate = self
    }

    func start() {
        listener.resume()
    }

    // MARK: - NSXPCListenerDelegate
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: AntiwordHelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    // MARK: - XPC Service Logic
    func processDocFile(inputPath: String, outputPath: String, withReply: @escaping (Bool, String) -> Void) {
        let task = Process()
        task.launchPath = "/path/to/antiword" // Update this path
        task.arguments = [inputPath]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.terminationHandler = { process in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "❌ No output"

            if process.terminationStatus == 0 {
                withReply(true, output)
            } else {
                withReply(false, "❌ Failed: \(output)")
            }
        }

        do {
            try task.run()
        } catch {
            withReply(false, "❌ Error running antiword: \(error.localizedDescription)")
        }
    }
}
