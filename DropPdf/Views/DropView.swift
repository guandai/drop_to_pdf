import SwiftUI

struct DropView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var processFile: ProcessFile
    @State private var isDragging = false
    @State private var showMark = false
    @State private var systemName = "checkmark.circle.fill"
    @State private var systemColor: Color = .green
    @State private var showPanel = false

    static let baseSize: CGFloat = 80  // ✅ Use `static let`
    static let dropAreaLength: CGFloat = 2.8 * DropView.baseSize
    static let iconLength: CGFloat = 1 * DropView.baseSize
    static let outerLength: CGFloat = 3 * DropView.baseSize
    static let resultsLength: CGFloat = 6 * DropView.baseSize
    static let historyLength: CGFloat = 4.5 * DropView.baseSize
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Drop files here")
                    .font(.headline)
                    .foregroundColor(isDragging ? .blue : .secondary)

                Button(action: {
                    showPanel = true
                }) {
                    Image(systemName: "info.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle()) // No extra styling
            }
            .padding(.top, 10)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isDragging ? Color.blue : Color.gray.opacity(0.5), lineWidth: 3)
                    )
                    .shadow(color: isDragging ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3), radius: 10, x: 0, y: 5)
                    .frame(width: DropView.dropAreaLength, height: DropView.dropAreaLength)


                if showMark {
                    Image(systemName: systemName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: DropView.iconLength, height: DropView.iconLength)
                        .foregroundColor(systemColor)
                        .opacity(showMark ? 1.0 : 0.75)
                        .animation(.easeIn(duration: 0.2), value: showMark)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showMark = false
                                }
                            }
                        }
                } else {
                    VStack {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: DropView.baseSize, height: DropView.baseSize)
                            .foregroundColor(isDragging ? .blue : .gray)

                        Text("Drag & Drop")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            .onDrop(of: ["public.file-url"], isTargeted: $isDragging) { providers in
                handleDrop(providers)
            }
        }
        .frame(width: DropView.outerLength, height: DropView.outerLength)
        .padding(10)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(getBackgroundColor())
                .shadow(radius: 10)
        )
        .sheet(isPresented: $showPanel) {
            ProcessedFilesPanel(processedFiles: appDelegate.processResult, isPresented: $showPanel)
        }
    }

    /// Determines the correct background color for iOS and macOS
    private func getBackgroundColor() -> Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #endif
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        let dispatchGroup = DispatchGroup()
        var newFiles: [URL] = []

        for provider in providers {
            dispatchGroup.enter()
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                defer { dispatchGroup.leave() }

                guard let data = item as? Data, let fileURL = URL(dataRepresentation: data, relativeTo: nil) else { return }

                DispatchQueue.main.async {
                    newFiles.append(fileURL)
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            appDelegate.droppedFiles.append(contentsOf: newFiles)
            Task {
                let result = await processFile.processDroppedFiles(newFiles, appDelegate)
                DispatchQueue.main.async {
                    showMark = true
                    systemName = result.values.contains(false) ?  "xmark.circle.fill" : "checkmark.circle.fill";
                    systemColor = result.values.contains(false) ?  .red : .green;
                    
                }
            }
        }

        return true
    }
}


struct ProcessedFilesPanel: View {
    let processedFiles: [Int: (URL, Bool)]
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text("Processed Files")
                .font(.headline)
                .padding(5)

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
            .frame(height: DropView.historyLength)
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
            
        }
        .frame(width: DropView.resultsLength, height: DropView.resultsLength)
    }
}
