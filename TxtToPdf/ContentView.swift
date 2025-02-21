import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate  // ✅ Use EnvironmentObject

    @State private var droppedFiles: [URL] = []

    var body: some View {
        VStack {
            Text("📂 Drag a TXT File Here")
                .font(.title)
                .padding()

            Text(droppedFiles.map { $0.lastPathComponent }.joined(separator: ", "))
                .foregroundColor(.gray)
                .padding()

            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: 300, height: 200)
                .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                    providers.first?.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                        if let data = item as? Data, let fileURL = URL(dataRepresentation: data, relativeTo: nil) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.droppedFiles.append(fileURL)

                                print("📂 DEBUG: Dropped file: \(fileURL.path)")

                                // ✅ Call AppDelegate via EnvironmentObject
                                appDelegate.convertTxtToPDF(txtFileURL: fileURL)
                            }
                        }
                    }
                    return true
                }
        }
        .frame(width: 400, height: 300)
    }
}
