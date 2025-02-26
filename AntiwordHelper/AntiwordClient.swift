import Foundation

class AntiwordClient {
    private var connection: NSXPCConnection?

    init() {
        connection = NSXPCConnection(serviceName: "com.twindai.AntiwordHelper") // Ensure this matches your XPC service name
        connection?.remoteObjectInterface = NSXPCInterface(with: AntiwordHelperProtocol.self)
        connection?.resume()
    }

    func convertDocToTxt(inputPath: String, outputPath: String, completion: @escaping (Bool, String) -> Void) {
        guard let service = connection?.remoteObjectProxy as? AntiwordHelperProtocol else {
            completion(false, "❌ XPC Connection Failed")
            return
        }

        service.processDocFile(inputPath: inputPath, outputPath: outputPath) { success, message in
            DispatchQueue.main.async {
                completion(success, message)
            }
        }
    }
}
