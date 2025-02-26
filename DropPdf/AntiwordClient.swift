import Foundation

@objc protocol AntiwordHelperProtocol {
    func processDocFile(inputPath: String, withReply: @escaping (Bool, String) -> Void)
}


import Foundation

class AntiwordClient {
    private var connection: NSXPCConnection?

    init() {
        connection = NSXPCConnection(serviceName: "com.twindai.AntiwordHelper") // Ensure this matches your XPC service name
        connection?.remoteObjectInterface = NSXPCInterface(with: AntiwordHelperProtocol.self)
        connection?.resume()
    }

    func convertDocToTxt(inputPath: String, completion: @escaping (Bool, String) -> Void) {
        guard let service = connection?.remoteObjectProxy as? AntiwordHelperProtocol else {
            completion(false, "❌ XPC Connection Failed")
            return
        }

        print(">>>>>>> processDocFile1")
        service.processDocFile(inputPath: inputPath) { (success, output) in
            print(">>>>>>> processDocFile!!2")
            DispatchQueue.main.async {
                print(">>>>>>> processDocFile!!3")
                completion(success, output) // ✅ Return extracted text
            }
        }
    }
}
