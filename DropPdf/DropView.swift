import SwiftUI

struct DropView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var processFile: ProcessFile
    @State private var isDragging = false
    @State private var showCheckmark = false

    static let baseSize: CGFloat = 50  // ✅ Use `static let`
    static let dropAreaLength: CGFloat = 2.8 * DropView.baseSize
    static let iconLength: CGFloat = 1 * DropView.baseSize
    static let outerLength: CGFloat = 3 * DropView.baseSize
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Drop files here")
                .font(.headline)
                .foregroundColor(isDragging ? .blue : .secondary)
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


                if showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: DropView.iconLength, height: DropView.iconLength)
                        .foregroundColor(.green)
                        .opacity(showCheckmark ? 1.0 : 0.75)
                        .animation(.easeIn(duration: 0.2), value: showCheckmark)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showCheckmark = false
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
        .padding(20)
        .padding(.bottom, 30)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(getBackgroundColor())
                .shadow(radius: 10)
        )
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
                await processFile.processDroppedFiles(newFiles, appDelegate)
                DispatchQueue.main.async {
                    showCheckmark = true
                }
            }
        }

        return true
    }
}
