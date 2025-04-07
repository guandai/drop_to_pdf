import SwiftUI

struct DropView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var processFile: ProcessFile

    @State private var isDragging = false
    @State private var showMark = false
    @State private var systemName = "checkmark.circle.fill"
    @State private var systemColor: Color = .green
    @State private var showPanel = false
    @State private var progress: Double = 0.0 // Track progress

    static let baseSize: CGFloat = 80
    static let dropAreaLength: CGFloat = 2.8 * DropView.baseSize
    static let iconLength: CGFloat = 1 * DropView.baseSize
    static let outerLength: CGFloat = 3 * DropView.baseSize

    var body: some View {
        ZStack {
            VStack {
                WrapperMainBox(
                    createOneFile: $appDelegate.createOneFile,
                    dropBox: AnyView(
                        DropBox(
                            isDragging: $isDragging,
                            showMark: $showMark,
                            systemName: systemName,
                            systemColor: systemColor,
                            handleFileDrop: handleFileDrop
                        )
                    )
                )
            }
            WrapperProcessButton(showPanel: $showPanel, processedFiles: appDelegate.processResult)
            // Add the CenteredProgressView
            CenteredProgressView(progress: $progress)
                .frame(width: DropView.dropAreaLength + 20, height: DropView.dropAreaLength + 50)
        }
        .frame(width: DropView.outerLength + 10, height: DropView.outerLength + 40)
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) async -> Void {
        let dispatchGroup = DispatchGroup()
        let newFiles = await appendNewFiles(providers: providers, dispatchGroup: dispatchGroup)

        // Reset progress
        progress = 0.0
        let totalFiles = Double(newFiles.count)

        dispatchGroup.notify(queue: .main) {
            Task {
                var results: [URL: Bool] = [:]
                for (index, file) in newFiles.enumerated() {
                    let result = await appDelegate.processFile.processOneFile(url: file, appDelegate: appDelegate)
                    progress = Double(index + 1) / totalFiles // Update progress
                    results[file] = result
                }
                
                if AppDelegate.shared.createOneFile {
                    results = await AppDelegate.shared.bundleToOnePdf(newFiles)
                }

                showMark = true
                systemName = results.values.contains(false) ? "xmark.circle.fill" : "checkmark.circle.fill"
                systemColor = results.values.contains(false) ? .red : .green
            }
        }
    }

    private func appendNewFiles(providers: [NSItemProvider], dispatchGroup: DispatchGroup) async -> [URL] {
        var newFiles: [URL] = []

        return await withCheckedContinuation { continuation in
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
                continuation.resume(returning: newFiles)
            }
        }
    }
}
