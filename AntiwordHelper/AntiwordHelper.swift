import Foundation

@objc protocol AntiwordHelperProtocol {
    func processDocFile(inputPath: String, withReply: @escaping (Bool, String) -> Void)
}

class AntiwordHelper: NSObject, NSXPCListenerDelegate, AntiwordHelperProtocol {
    private let listener = NSXPCListener.service()

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

    // MARK: - AntiwordHelperProtocol
    func processDocFile(inputPath: String, withReply reply: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Locate `antiword` binary
            guard let antiwordPath = Bundle.main.path(forResource: "antiword", ofType: "") else {
                reply(false, "❌ antiword binary not found in bundle")
                return
            }

            // Ensure execute permissions
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: antiwordPath)
                if let permissions = attributes[.posixPermissions] as? NSNumber, (permissions.uint16Value & 0o111) == 0 {
                    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: antiwordPath)
                    print(true, "✅ Set executable permissions for antiword")
                }
            } catch {
                reply(false, "❌ Failed to set execute permissions for antiword: \(error.localizedDescription)")
                return
            }

            // Run `antiword`
            let task = Process()
            task.launchPath = antiwordPath
            task.arguments = [inputPath]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                let outputText = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "❌ No output"

                reply(true, outputText)  // ✅ Return the extracted text
            } catch {
                reply(false, "❌ Error running antiword: \(error.localizedDescription)")
            }
        }
    }
}
