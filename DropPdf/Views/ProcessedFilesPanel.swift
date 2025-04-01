import SwiftUI

struct ProcessedFilesPanel: View {
    let processedFiles: [Int: (URL, Bool)]
    static let resultsLength: CGFloat = 6 * DropView.baseSize
    static let historyLength: CGFloat = 4.5 * DropView.baseSize
    @Binding var isPresented: Bool
    

    var body: some View {
        VStack {
            Text("Processed Files")
                .font(.headline)
                .padding(2)

            ScrollView {
                LazyVStack {
                    // 1) Sort the dictionary keys so we have a stable order
                    ForEach(processedFiles.keys.sorted(), id: \.self) { index in
                        if let (a, b) = processedFiles[index] {
                            HStack {
                                Text(a.lastPathComponent)
                                    .font(.headline)
                                Spacer()
                                Text(b ? "Success" : "Failed")
                                    .foregroundColor(b ? .green : .red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(index % 2 == 1 ? Color.gray.opacity(0.2) : Color.clear) // Light grey for odd indices
                        }
                    }
                }
                .id(UUID())
            }
            .frame(height: ProcessedFilesPanel.historyLength + 30)
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .padding(.horizontal, 10)

            Button("CLOSE") {
                isPresented = false
            }
            .padding(.top, 0)
            .font(.system(size: 14))
            .frame(width: 80, height: 30)
            .background(Color.blue)
            .cornerRadius(6)
            .padding(.top, 0)
            .buttonStyle(.plain)
            .accessibilityIdentifier("closeButton")
            
        }
        .frame(width: ProcessedFilesPanel.resultsLength, height: ProcessedFilesPanel.resultsLength)
    }
}
