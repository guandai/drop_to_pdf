import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate  // ✅ Use EnvironmentObject

    @State private var droppedFiles: [URL] = []

    var body: some View {
        VStack(spacing: 5) { // ✅ Reduced vertical spacing
            Text(droppedFiles.map { $0.lastPathComponent }.joined(separator: ", "))
                .foregroundColor(.gray)
                .padding(.bottom, 5) // ✅ Reduce bottom padding

            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: 160, height: 160)
                .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                    providers.first?.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                        if let data = item as? Data, let fileURL = URL(dataRepresentation: data, relativeTo: nil) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.droppedFiles.append(fileURL)
                                // ✅ Call AppDelegate via EnvironmentObject
                                appDelegate.convertTxtToPDF(txtFileURL: fileURL)
                            }
                        }
                    }
                    return true
                }
        }
        .frame(width: 250, height: 250) // Ensure content fits within 300x300 window
    }
}
